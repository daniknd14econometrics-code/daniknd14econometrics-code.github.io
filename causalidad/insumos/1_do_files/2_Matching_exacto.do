/*------------------------------------------------------------------------------
Taller: Matching exacto en Stata
Datos: hh_98.dta (microcrédito). 

Idea general:
1) Arrancar con "matching exacto" (por celdas/estratos) para fijar intuición:
   - Elección de X
   - Soporte común (overlap) en matching exacto
   - Fórmulas y cálculo de ATE y ATET
   - Formulas y calculo de los respectivos SE estandar
   - Bootstrap para SE correctos
   - Uso de CEM en Matching exacto: solo es valido ATET

Requisitos:
- Si no tenes cem: ssc install cem, replace.
------------------------------------------------------------------------------*/


**# Directorio de trabajo comun

clear all      
set more off
global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"

local username = c(username)
display "`username'"

local username = c(username)

if "`username'" == "Equipo" {
     global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"
}
else if "`username'" == "dmendez" {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"
}
else {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"
}


*---------------------------
* 0) Directorio y datos
*---------------------------

use "$seteo\Directorio común bases\hh_98.dta", clear 
set more off

**# Base: preparacion

*---------------------------
* 1) Variables del taller
*---------------------------
describe

* D=Tratamiento: dfmfd = 1 si hay participante mujer en microcrédito
* Y=Outcome: exptot (gasto p/c total). Usamos log(1+exptot).
gen lexptot = ln(1+exptot)
gen lnland  = ln(1+hhland/100)

global Y lexptot
global D dfmfd

* Set de covariables (pre-tratamiento)
global X    ///
    sexhead ///
    agehead ///
    educhead ///
    lnland ///
    vaccess ///
    pcirr ///
    rice ///
    wheat ///
    milk ///
    oil ///
    egg

summ $Y $D $X

*---------------------------
* 1.5) Registro de resultados (para tabla comparativa al final)
*---------------------------
* La idea: ir guardando (método, soporte, algoritmo, ATE, ATET, Ns) en un archivo temporal.
* Luego imprimimos una tabla comparativa al final del do-file.
tempfile _results_match
tempname  _posth

postfile `_posth' ///
    str28 method ///
    str18 support ///
    str26 algorithm ///
    double ate ///
    double atet ///
    double se_ate ///
    double se_atet ///
    int N1 ///
    int N0 ///
    using "`_results_match'", replace


/*------------------------------------------------------------------------------
2) Concepto: ATE y ATET (definiciones poblacionales)

ATE  = E[ Y(1) - Y(0) ].
ATET = E[ Y(1) - Y(0) | D=1 ].

Bajo unconfoundedness (Y(0),Y(1)) _||_ D | X y overlap, se puede usar matching:
ATE  = E_X[ E(Y|D=1,X) - E(Y|D=0,X) ].
ATET = E_{X|D=1}[ E(Y|D=1,X) - E(Y|D=0,X) ].
------------------------------------------------------------------------------*/

**# Matching exacto: SE estandar

*==============================================================================
* PARTE A. MATCHING EXACTO (por celdas/estratos)
*==============================================================================

/*------------------------------------------------------------------------------
3) ¿Qué es matching exacto?

Definís "celdas" por valores exactos de X (o por X discretizada).
Dentro de cada celda s:
   diff(s) = mean(Y|D=1,s) - mean(Y|D=0,s)

Soporte común (exact matching):
   conservar SOLO celdas con tratados y controles: N1(s)>0 y N0(s)>0.

Estimadores (en la muestra en soporte común):
ATE_exact  = Σ_s [ N(s)/N ] * diff(s)
ATET_exact = Σ_s [ N1(s)/N1 ] * diff(s)

Nota práctica:
- Con X continuas (edad, tierra, precios), exact matching “puro” genera
  demasiadas celdas vacías. En taller conviene:
  (i) elegir pocas X, y/o (ii) discretizar (“coarsening”) continuas.
------------------------------------------------------------------------------*/

*---------------------------
* A1) Elegir X para exact matching (versión didáctica)
*---------------------------
* Para evitar explosión de celdas, usamos un subconjunto y discretizamos algunas X.
* (Podés cambiar estos cortes; el punto del taller es mostrar el mecanismo.)

** variables que son cuasi continuas:

summ agehead 
* Edad: bins amplios
recode agehead ///
    (min/25 = 1 "18-25") ///
    (26/35  = 2 "26-35") ///
    (36/45  = 3 "36-45") ///
    (46/55  = 4 "46-55") ///
    (56/65  = 5 "56-65") ///
    (66/75  = 6 "66-75") ///
    (76/max = 7 "76+") , gen(agebin)

sum educhead
* Educación: 0, 1-4, 5-8, 9+
recode educhead ///
    (0 = 0 "0") ///
    (1/4 = 1 "1-4") ///
    (5/8 = 2 "5-8") ///
    (9/max = 3 "9+") , gen(edubin)

** variables continuas puras:
sum lnland
sum pcirr
* Tierra (log) y riego: cuartiles
xtile landbin  = lnland, nq(4)
xtile pcirrbin = pcirr,  nq(4)

* Strata exactos (celdas)
summ sexhead vaccess agebin edubin landbin pcirrbin
egen stratum_exact = group(sexhead vaccess agebin edubin landbin pcirrbin), label

*---------------------------
* A2) Soporte común en exact matching
*---------------------------
bys stratum_exact: egen N1 = total($D==1)
bys stratum_exact: egen N0 = total($D==0)
gen support_exact = (N1>0 & N0>0)

br N1 N0 support_exact


tab support_exact $D, col
* Interpretación: en exact matching “soporte común” = celdas con ambos grupos.


*---------------------------
* A3) Cálculo de ATE y ATET (exact matching)
*---------------------------
preserve
    keep if support_exact==1

    * Crear variables auxiliares (collapse no acepta cond() dentro)
    gen double y1_tmp = $Y if $D==1
    gen double y0_tmp = $Y if $D==0

    * Resumir por celda (estrato)
    collapse ///
        (count) Ncell = $Y ///
        (sum)   N1cell = $D ///
        (mean)  y1 = y1_tmp ///
        (mean)  y0 = y0_tmp ///
        (sd)    sd1 = y1_tmp ///
        (sd)    sd0 = y0_tmp ///
        , by(stratum_exact)

    gen N0cell = Ncell - N1cell
    gen diff   = y1 - y0

    quietly summarize Ncell, meanonly
    scalar Ntot = r(sum)

    quietly summarize N1cell, meanonly
    scalar N1tot = r(sum)

    scalar N0tot = Ntot - N1tot

    * Pesos para ATE y ATET
    gen w_ate  = Ncell/Ntot
    gen w_atet = N1cell/N1tot

    * ATE y ATET (puntos)
    gen contrib_ate  = w_ate  * diff
    gen contrib_atet = w_atet * diff

    quietly summarize contrib_ate, meanonly
    scalar ATE_exact = r(sum)

    quietly summarize contrib_atet, meanonly
    scalar ATET_exact = r(sum)

    *------------------------------------------------------------
    * SE "estándar" (analíticos) por estratos (plug-in)
    * Var(diff_s) ≈ s^2_{1s}/N1_s + s^2_{0s}/N0_s
    * Var(ATE)  ≈ Σ_s w_s^2  Var(diff_s)
    * Var(ATET) ≈ Σ_s w1_s^2 Var(diff_s)
    *------------------------------------------------------------
    replace sd1 = 0 if missing(sd1) & N1cell==1
    replace sd0 = 0 if missing(sd0) & N0cell==1

    gen var_diff = (sd1^2)/N1cell + (sd0^2)/N0cell

    gen var_contrib_ate  = (w_ate^2)  * var_diff
    gen var_contrib_atet = (w_atet^2) * var_diff

    quietly summarize var_contrib_ate, meanonly
    scalar se_ate_exact_ana  = sqrt(r(sum))

    quietly summarize var_contrib_atet, meanonly
    scalar se_atet_exact_ana = sqrt(r(sum))

    display as text "----------------------------------------"
    display as text "Exact matching (con discretización):"
    display as result "ATE_exact  = " %9.6f ATE_exact  "    (SE analítico = " %9.6f se_ate_exact_ana  ")"
    display as result "ATET_exact = " %9.6f ATET_exact "    (SE analítico = " %9.6f se_atet_exact_ana ")"
    display as text "----------------------------------------"
restore

* Guardar Ns "limpios" (del soporte común en la muestra original) para la tabla
scalar N1_exact = N1tot
scalar N0_exact = N0tot

* Guardar en tabla comparativa: SE analíticos (estratos)
post `_posth' ("Exact manual (SE ana)") ("overlap celdas") ("estratos discretos") ///
    (ATE_exact) (ATET_exact) (se_ate_exact_ana) (se_atet_exact_ana) (N1_exact) (N0_exact)

**# Matching exacto: bootstrap para SE
	
*---------------------------
* A4) Bootstrap para SE en exact matching
*---------------------------
* Idea: replicar el matching manual dentro de un program, para que bootstrap
* re-haga (i) coarsening (bins), (ii) soporte común, (iii) matching/estratos.
capture program drop exactmatch_est
program define exactmatch_est, rclass
    tempvar agebin edubin landbin pcirrbin stratum_exact N1 N0 support_exact
    tempvar y1_tmp y0_tmp

    recode agehead (min/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5) (66/75=6) (76/max=7), gen(`agebin')
    recode educhead (0=0) (1/4=1) (5/8=2) (9/max=3), gen(`edubin')
    xtile `landbin'  = lnland, nq(4)
    xtile `pcirrbin' = pcirr,  nq(4)
    egen `stratum_exact' = group(sexhead vaccess `agebin' `edubin' `landbin' `pcirrbin')

    bys `stratum_exact': egen `N1' = total($D==1)
    bys `stratum_exact': egen `N0' = total($D==0)
    gen `support_exact' = (`N1'>0 & `N0'>0)

    preserve
        keep if `support_exact'==1

        gen double `y1_tmp' = $Y if $D==1
        gen double `y0_tmp' = $Y if $D==0

        collapse (count) Ncell = $Y ///
                 (sum)   N1cell = $D ///
                 (mean)  y1 = `y1_tmp' ///
                 (mean)  y0 = `y0_tmp' ///
                 , by(`stratum_exact')

        gen diff = y1 - y0

        quietly summarize Ncell, meanonly
        local Ntot = r(sum)

        quietly summarize N1cell, meanonly
        local N1tot = r(sum)

        gen w_ate  = Ncell/`Ntot'
        gen w_atet = N1cell/`N1tot'

        gen contrib_ate  = w_ate  * diff
        gen contrib_atet = w_atet * diff

        quietly summarize contrib_ate, meanonly
        return scalar ate  = r(sum)

        quietly summarize contrib_atet, meanonly
        return scalar atet = r(sum)
    restore
end

* Bootstrap (sube reps si querés más precisión; baja reps si querés rapidez)
bootstrap r(ate) r(atet) if !missing($Y, $D, sexhead, vaccess, agehead, educhead, lnland, pcirr), reps(300) seed(12345): exactmatch_est
matrix se = e(se)
scalar se_ate_exact_boot  = se[1,1]
scalar se_atet_exact_boot = se[1,2]

display as text "----------------------------------------"
display as text "Bootstrap SE (exact matching):"
display as result "SE_boot(ATE)  = " %9.6f se_ate_exact_boot
display as result "SE_boot(ATET) = " %9.6f se_atet_exact_boot
display as text "----------------------------------------"

* Guardar en tabla comparativa: SE bootstrap
post `_posth' ("Exact manual (SE boot)") ("overlap celdas") ("estratos discretos") ///
    (ATE_exact) (ATET_exact) (se_ate_exact_boot) (se_atet_exact_boot) (N1_exact) (N0_exact)

* ---------------------------------------------------------------------------
* Nota (varianza estándar vs bootstrap) – Matching exacto
*
* 1) SE "estándar" (analíticos) por estratos:
*    - Trata estratos y soporte común como fijos.
*    - Usa Var(diff_s) ≈ s^2_{1s}/N1_s + s^2_{0s}/N0_s, y agrega con pesos^2.
*    - Es muy didáctico y suele ser razonable si bins/celdas están "dados".
*
* 2) Contras del SE analítico:
*    - No captura la incertidumbre de la discretización por cuantiles (xtile),
*      ni el hecho de que el soporte común (celdas con N1>0 y N0>0) depende
*      de la muestra.
*    - Puede ser frágil si hay celdas pequeñas.
*
* 3) En un trabajo serio, el bootstrap del procedimiento completo suele ser
*    preferible (re-hace bins + soporte común + cálculo de ATE/ATET).
*
* 4) Si tenés panel/correlación intra-unidad (id), usá cluster bootstrap:
*      bootstrap r(ate) r(atet), reps(500) seed(12345) cluster(id) idcluster(_cid): ///
*          exactmatch_est
*    (cluster(id) re-muestrea unidades completas, preservando dependencia dentro de id)
* ---------------------------------------------------------------------------


* ---------------------------------------------------------------------------
* Nota importante (Exact matching + Bootstrap)
*
* - NO es necesario (ni recomendable) calcular/guardar N0tot dentro del program
*   exactmatch_est si tu objetivo es obtener SE bootstrap para ATE/ATET.
*   En bootstrap, el program se ejecuta muchas veces y cualquier scalar global
*   (Ntot, N1tot, N0tot, etc.) se pisa en cada réplica, lo cual puede confundir.
*
* - La lógica correcta es separar roles:
*
*   (A) Bloque A3 MANUAL (una sola vez, sobre la muestra original):
*       1) Calculás Ntot, N1tot y N0tot (= Ntot - N1tot).
*       2) Guardás Ns "limpios" para reportar en la tabla:
*            scalar N1_exact = N1tot
*            scalar N0_exact = N0tot
*       Estos Ns corresponden al soporte común del matching exacto en la muestra
*       original, y son los que deben ir a la tabla comparativa.
*
*   (B) Program exactmatch_est (solo para bootstrap):
*       - Su único objetivo es devolver r(ate) y r(atet) en cada réplica:
*            return scalar ate  = ...
*            return scalar atet = ...
*       - NO debe guardar N1_exact/N0_exact (porque variarían por réplica).
*       - N0tot adentro del program es opcional y, si no se usa, se omite.
*
* - Recomendación de prolijidad:
*   dentro del program, usar locals para Ntot y N1tot (no scalars globales),
*   para evitar "pisadas" del entorno durante el bootstrap.
* ---------------------------------------------------------------------------


**# Matching exacto: CEM 

*==============================================================================
* PARTE A.2 Coarsened Exact Matching (CEM) como alternativa “lista”
*==============================================================================
/*------------------------------------------------------------------------------
CEM (Iacus–King–Porro / Blackwell et al.) es una forma práctica de hacer “exact matching”
sobre una versión coarsened de X, y automáticamente:
(i) restringe a soporte común (cem_matched==1),
(ii) crea estratos (cem_strata),
(iii) genera pesos (cem_weights) para estimar (usualmente) el efecto en tratados (ATET/SATT).


* ---------------------------------------------------------------------------
* ¿Qué hace CEM (Coarsened Exact Matching) y por qué lo incluimos?
*
* CEM sí "te hace el matching", pero NO en el sentido de devolverte ATE/ATET automáticamente con algo tipo:  cem ... , ate
* Lo que hace CEM es construir una muestra emparejada (y pesos) con una regla muy específica:
*   (i) coarsen (discretizás X),
*   (ii) exact matching sobre esas celdas/estratos,
*   (iii) te devuelve un esquema de pesos tal que el análisis posterior (diferencia de medias o regresión ponderada) sea el estimador.
*
* Qué hace CEM, exactamente:
* 1) Definís (o dejás que el comando defina) una discretización de X:
*    edad en bins, educación en bins, etc. A esto CEM le llama "coarsening".
* 2) Con esas variables coarsened, hace exact matching por celdas-estratos:
*    una unidad tratada es "comparable" solo con controles en la misma celda.
* 3) Elimina (o marca como no matched) observaciones en celdas sin el otro grupo.
*    Eso implementa el "soporte común" en CEM.
* 4) Devuelve dos objetos clave:
*    - cem_matched: indicador de si la observación quedó dentro del soporte común.
*    - cem_weights: pesos para que, al comparar resultados (dif. de medias o regresión ponderada), 
*      el balance entre tratados y controles dentro de las celdas sea el que CEM define: (spoiler: ATET)
*
* En otras palabras: CEM NO es un "estimador final" por sí solo; 
* es un procedimiento de pre-procesamiento + reponderación. 
* El efecto se estima después usando cem_weights (por ejemplo con reg ponderada).
*
* Diferencias respecto a matching exacto "manual" (con X discretizada):
* - Conceptualmente, el matching exacto manual anterior ya es "coarsened exact matching".
*   La diferencia práctica está en:
*   (A) Qué pesos usa para re-equilibrar dentro de celdas:
*       * Manual: agregás celdas con pesos Ns/N (ATE) o N1s/N1 (ATET), típico estimador por estratos ("estratificación").
*       * CEM: además de definir estos estratos, 
*         define cem_weights para re-equilibrar la contribución de controles vs tratados DENTRO de cada estrato.
*         Esto importa cuando hay asimetrías fuertes en tamaños de celda.
*   (B) Diagnóstico y control del nivel de coarsening:
*       * Más coarsening (cajas más anchas)  => más superposicion (menos pérdida muestral) pero más "diferencias residuales" dentro de celda.
*       * Menos coarsening (bins más finos) => más balance exacto, pero más pérdida por soporte común.
*       CEM está diseñado para que este trade-off sea transparente y controlable.
*
* --------------------------------------------------------------------------------*

* ---------------------------------------------------------------------------
* EXTENSIÓN IMPORTANTE (para entender "asimetrías dentro de celda" y ATE vs ATET)
*
* 1) ¿Qué "asimetrías dentro de celdas" corrige CEM?
*
*    Pensá un estrato/celda s donde hay MUCHOS controles y POCOS tratados.
*    Si vos hacés algo "a pelo" (por ejemplo, tomar todos los controles tal cual)
*    y luego agregás celdas, esa celda podría quedar dominada por la masa de controles,
*    y el "control global" resultante no representaría bien a los tratados.
*
*    CEM corrige esto generando PESOS (principalmente para controles) de manera que,
*    DENTRO de cada celda s, la "masa ponderada" de controles replique la de tratados.
*    Esa es la idea de "re-equilibrar" dentro de estrato.
*
*    Notación por estrato s:
*      N1_s = # tratados en s
*      N0_s = # controles en s
*
*    Esquema típico (intuición estándar):
*      - Para tratados:   w_i = 1
*      - Para controles:  w_i = N1_s / N0_s   (para i en s con D=0)
*
*    Entonces, la suma de pesos por estrato cumple:
*      W1_s = sum_{i in s, D=1} w_i = N1_s
*      W0_s = sum_{i in s, D=0} w_i = N0_s * (N1_s/N0_s) = N1_s
*
*    O sea: W0_s = W1_s por construcción.
*    Esto es EXACTAMENTE "ponderar por asimetrías dentro de la celda".
*
*
* 2) ¿Por qué eso está alineado con ATET y no con ATE?
*
*    Porque al forzar W0_s = W1_s, estás construyendo un grupo control ponderado
*    que tiene la MISMA composición en X que el grupo tratado (en el soporte común).
*    Es decir: estás armando el contrafactual "para los tratados":
*      ¿qué le habría pasado a los tratados si hubieran sido controles?
*    Eso es ATET.
*
*    En cambio, ATE apunta al efecto promedio en TODA la población (tratados+controles).
*    Para ATE, la distribución objetivo de X no es "la de los tratados", sino la
*    distribución poblacional. Eso requiere un objetivo de ponderación distinto:
*    (en general) reponderar para representar la población total, no para "control → tratado".
*
*
* 3) Entonces, ¿CEM "no sirve" para ATE?
*
*    Sirve, pero NO "gratis" con los pesos por defecto (cem_weights) ni con el
*    agregador que construiste. Hay tres caminos conceptualmente correctos:
*
*    (A) Lo más estándar en talleres y papers con CEM:
*        Usar CEM para ATET (SATT) y decirlo explícitamente:
*          reg Y D [iw=cem_weights] if cem_matched==1
*
*    (B) Si querés ATE poblacional:
*        Necesitás definir una distribución objetivo poblacional y un esquema
*        de pesos que haga que tratados y controles representen esa población.
*        Eso ya es otra capa (no es el default de CEM) y conviene explicitarlo
*        como extensión/avance, no mezclarlo con la versión estándar.
* ---------------------------------------------------------------------------



------------------------------------------------------------------------------*/

capture which cem
if _rc {
    di as error "No tenés instalado -cem-. Si querés usarlo:  ssc install cem, replace"
}
else 

    * (Opcional) fijar semilla por reproducibilidad cuando cem usa auto-coarsening
     set seed 12345
	 
* Por prolijidad: si ya existieran de una corrida anterior
capture drop cem_matched cem_weights cem_strata

* CEM sobre covariables discretizadas (coarsened): distintas reglas de discretizacion
cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(sturges)
cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(fd)
cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(scott) 
cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(ss)

* cem esta usando diferentes algoritmos internos para discretizar las X.

* ---------------------------------------------------------------------------
* CEM y variables continuas "originales": ¿discretiza?
*
* Sí discretiza. Si le pasás continuas (agehead, lnland, pcirr, etc.) sin
* cutpoints explícitos, cem construye internamente cortes (bins) para cada
* continua, arma estratos con el cruce de esos bins + las covariables
* categóricas, y hace exact matching a nivel de estrato.
*
* Esto NO elimina arbitrariedad: la reemplaza por una regla default.
* En Stata-cem, si no ponés nada entre paréntesis, usa el default de autocuts(),
* cuyo valor por defecto es Sturges (autocuts(sturges)).
* Podés cambiarlo, por ejemplo:
*   cem x1 x2 x3, tr(D) autocuts(fd)
* y también podés sobre-escribir por variable:
*   cem agehead(#6) educhead(scott) lnland(fd) pcirr(sturges), tr(D)
* donde:
*   - (numlist) fija cortes manuales
*   - (sturges|fd|scott|ss) elige algoritmo automático para ESA variable
*   - (#k) pide k bins de igual ancho
*   - (#0) no coarsen esa variable
*
* Por eso "dejo las originales y que cem haga todo" es válido como demo, pero
* conceptualmente NO es "sin discretizar": es "discretizar con defaults".
*
* ¿Qué es el L1 que reporta CEM?
* Es una medida de desbalance basada en la distribución de tratados y controles
* en el espacio coarsened (los estratos/celdas). La forma típica es:
*
*   L1 = (1/2) * sum_{s in S} | p1(s) - p0(s) |,
*
* donde p1(s) es la proporción (masa) de tratados en el estrato s y p0(s) la
* proporción (masa) de controles en ese mismo estrato (antes/después según el
* reporte).
*Interpretación práctica: L1=0: balance perfecto (misma distribución de X coarsened entre tratados y controles).
* L1 más alto: más desbalance (distribuciones más distintas). Está acotado entre 0 y 1.

* Tip: para VER los cortes usados por cem, usar:
*   cem ..., tr(D) showbreaks 
* (o showcutpoints, según versión/comando)
* ---------------------------------------------------------------------------

/* -----------------------CEM: lectura de analisis y eleccion --------------------------------------

Observar que usamos las variables continuas originales de la base.
con: cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(fd)
** la opcion fd es el que nos dio un valor del L1 multivariado menor usando estas X originales. 
** sin contar la opcion ss, que es un mundo "ideal" porque L1=0, pero el soporte es muy muy reducido: trade off sesgo-varianza.
** comparando fd con scott: scott nos da un valor de L1 multivariado muy similar fd, comparemos el soporte comun:
** en fd       156 + 201 = 357  ---> 357/1129  = 32%.
** en scott    157 + 192 = 349  ---> 349/1129  = 31%.

Por lo que nos quedamos con el que se basa en la medida de fd.
La alternativa es usar la opcion sturges si queremos un soporte mayor (42%) (esto es algo deseable) pero a costa de un mayor (L1=0.56). (tension sesgo-varianza)
(en el proximo taller, implementamos una mejor manera de elegir: en base a criterios que permiten discernir mejor esta tension entre sesgo-varianza.)

A todo esto, no perder de vista que nuestra discretizacion manual de hoy nos daba un soporte comun de 65%, el mas grande de todos estos. 
Pero su L1 no es comparable porque esas X son discretizadas manualmente, no ingresan continuas al metodo cem, ya ingresan discretizadas, con lo cual, no son las mismas X y sus L1 no son comparables.

Multivariate L1 distance  (fd): .47951907 es una distancia multivariada.
Compara la distribución conjunta (sobre todas las celdas/estratos) entre tratados y controles.

Muy importante: no compares L1 entre corridas con coarsenings (X) distintos como si fueran directamente "mejor/peor". 
Si coarseneás más grueso, por construcción es más fácil que baje el L1 (porque estás mirando una grilla más burda). 
El L1 tiene sentido "dentro" de una especificación de coarsening (mismas X) y como herramienta para ver el trade-off.

Univariate imbalance (por variable): es la misma idea, pero mirando la distribución marginal de cada covariable.
*/


* ---------------------------------------------------------------------------


*------------------------------------------------------------
* 1) ATET "a mano" por estratos CEM, USANDO cem_weights
*    (NO reportamos ATE porque con cem_weights el foco es ATET/SATT)
*------------------------------------------------------------

capture drop cem_matched cem_weights cem_strata
cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(fd)

preserve
    keep if cem_matched==1

    * Pesos CEM
    gen double w = cem_weights

    * Variables auxiliares por grupo
    gen double y1_tmp = $Y if $D==1
    gen double y0_tmp = $Y if $D==0

    * Sumas ponderadas por estrato
    gen double w1  = w if $D==1
    gen double w0  = w if $D==0
    gen double wy1 = w*y1_tmp
    gen double wy0 = w*y0_tmp

    collapse ///
        (count) Ncell = $Y ///
        (sum)   N1cell = $D ///
        (sum)   W1  = w1 ///
        (sum)   W0  = w0 ///
        (sum)   WY1 = wy1 ///
        (sum)   WY0 = wy0 ///
        , by(cem_strata)

    gen N0cell = Ncell - N1cell

    * Medias ponderadas dentro de estrato (tratado y control)
    gen y1 = WY1/W1
    gen y0 = WY0/W0
    gen diff = y1 - y0

    * Totales (conteos) para reportar N1/N0 en la tabla (no ponderados)
    quietly summarize Ncell, meanonly
    scalar Ntot_cem = r(sum)
    quietly summarize N1cell, meanonly
    scalar N1tot_cem = r(sum)
    scalar N0tot_cem = Ntot_cem - N1tot_cem

    * Agregación ATET: ponderar por masa ponderada de tratados en cada estrato
    quietly summarize W1, meanonly
    scalar W1tot_cem = r(sum)

    gen w_atet = W1/W1tot_cem
    gen contrib_atet = w_atet * diff

    quietly summarize contrib_atet, meanonly
    scalar ATET_cem = r(sum)
restore

di as text "----------------------------------------"
di as text "CEM (con pesos cem_weights):"
di as result "ATET_cem = " %9.6f ATET_cem
di as text "----------------------------------------"

*------------------------------------------------------------
* 2) Chequeo rápido: regresión ponderada (coef(D) = ATET)
*    (SE robusto: útil como chequeo; el SE "principal" lo damos por bootstrap)
*------------------------------------------------------------
quietly reg $Y $D [iweight=cem_weights] if cem_matched==1, vce(robust)
di as text "Regresion ponderada, SE robusto: coef(D) = " %9.6f _b[$D] "  SE = " %9.6f _se[$D]

**# Matching exacto: CEM con Bootstrap

*------------------------------------------------------------
* 3) Bootstrap para SE de ATET (re-hace CEM + soporte + estimación)
*------------------------------------------------------------
capture drop cem_matched cem_weights cem_strata
cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(fd)

capture program drop cem_est
program define cem_est, rclass
    tempvar y1t y0t w w1 w0 wy1 wy0

    capture drop cem_matched cem_weights cem_strata
    cem sexhead vaccess agehead educhead lnland pcirr, tr($D) autocuts(fd)

    preserve
        keep if cem_matched==1

        gen double `w' = cem_weights
        gen double `y1t' = $Y if $D==1
        gen double `y0t' = $Y if $D==0

        gen double `w1'  = `w' if $D==1
        gen double `w0'  = `w' if $D==0
        gen double `wy1' = `w'*`y1t'
        gen double `wy0' = `w'*`y0t'

        collapse ///
            (sum) W1  = `w1' ///
            (sum) W0  = `w0' ///
            (sum) WY1 = `wy1' ///
            (sum) WY0 = `wy0' ///
            , by(cem_strata)

        gen y1 = WY1/W1
        gen y0 = WY0/W0
        gen diff = y1 - y0

        quietly summarize W1, meanonly
        local W1tot = r(sum)

        gen w_atet = W1/`W1tot'
        gen c_atet = w_atet * diff

        quietly summarize c_atet, meanonly
        return scalar atet = r(sum)
    restore
end

bootstrap r(atet)       if !missing($Y, $D, sexhead, vaccess, agehead, educhead, lnland, pcirr), reps(300) seed(12345): cem_est
matrix se = e(se)
scalar se_atet_cem_boot = se[1,1]

di as text "----------------------------------------"
di as text "Bootstrap SE (CEM ATET):"
di as result "SE_boot(ATET) = " %9.6f se_atet_cem_boot
di as text "----------------------------------------"

* Guardar en tabla comparativa:
* - ATE y SE_ATE quedan missing (.), porque con cem_weights reportamos ATET.
post `_posth' ("CEM (ATET) (SE boot)") ("cem_matched") ("estratos CEM (fd) + w") ///
    (.) (ATET_cem) (.) (se_atet_cem_boot) (N1tot_cem) (N0tot_cem)

* Nota panel/cluster (si aplica):
* bootstrap r(atet), reps(500) seed(12345) cluster(id) idcluster(_cid): cem_est
	

**# Tabla comparativa
	
*==============================================================================
* C) Tabla comparativa final (todos los métodos del taller)
*==============================================================================
postclose `_posth'

use "`_results_match'", clear
order method support algorithm ate atet se_ate se_atet N1 N0
sort method support algorithm

format ate atet se_ate se_atet %9.6f

di as text "=================================================================="
di as text "Tabla comparativa (puntos estimados; SE en teffects, y en bootstrap si los agregas)"
di as text "=================================================================="
list, noobs sepby(method support)
 
*============================================================
* (Opcional pero recomendado) IC 95% + strings LaTeX-safe
*============================================================

* 1) IC normal-based 95% (solo donde hay estimación + SE)
local z = invnormal(0.975)

gen double ci_ate_lo  = . 
gen double ci_ate_hi  = .
gen double ci_atet_lo = .
gen double ci_atet_hi = .

replace ci_ate_lo  = ate  - `z'*se_ate   if !missing(ate,  se_ate)
replace ci_ate_hi  = ate  + `z'*se_ate   if !missing(ate,  se_ate)
replace ci_atet_lo = atet - `z'*se_atet  if !missing(atet, se_atet)
replace ci_atet_hi = atet + `z'*se_atet  if !missing(atet, se_atet)

format ci_ate_lo ci_ate_hi ci_atet_lo ci_atet_hi %9.6f

* 2) IC como texto compacto para tabla (queda una sola columna por IC)
gen str40 ci_ate  = ""
gen str40 ci_atet = ""
replace ci_ate  = "[" + string(ci_ate_lo,"%9.6f")  + ", " + string(ci_ate_hi,"%9.6f")  + "]" if !missing(ci_ate_lo,ci_ate_hi)
replace ci_atet = "[" + string(ci_atet_lo,"%9.6f") + ", " + string(ci_atet_hi,"%9.6f") + "]" if !missing(ci_atet_lo,ci_atet_hi)

* 3) Versiones "LaTeX-safe" de strings (evita que LaTeX rompa)
gen strL method_tex    = method
gen strL support_tex   = support
gen strL algorithm_tex = algorithm

foreach v in method_tex support_tex algorithm_tex {
    replace `v' = subinstr(`v', "\", "\\textbackslash{}", .)
    replace `v' = subinstr(`v', "&", "\&", .)
    replace `v' = subinstr(`v', "%", "\%", .)
    replace `v' = subinstr(`v', "_", "\_", .)
    replace `v' = subinstr(`v', "#", "\#", .)
}

* Export simple para llevar a Excel / LaTeX
export delimited using "tabla_resultados_matching.csv", replace


* (Opcional) generar un .tex con una tabla simple (sin depender de paquetes extra)
tempname _fh
file open `_fh' using "tabla_resultados_matching.tex", write replace
file write `_fh' "\begin{table}[!htbp]\centering" _n
file write `_fh' "\caption{Comparacion de estimadores (matching exacto)}" _n
file write `_fh' "\label{tab:matching_comparacion}" _n
file write `_fh' "\small" _n
file write `_fh' "\begin{tabular}{lllrrrrrrrr}" _n
file write `_fh' "\toprule" _n
file write `_fh' "Metodo & Soporte & Algoritmo & ATE & ATET & SE(ATE) & SE(ATET) & IC95(ATE) & IC95(ATET) & N1 & N0 \\" _n
file write `_fh' "\midrule" _n

forvalues i=1/`=_N' {
    local m  = method[`i']
    local s  = support[`i']
    local a  = algorithm[`i']
    local ate_s  = cond(missing(ate[`i']),  "", string(ate[`i'],  "%9.6f"))
    local atet_s = cond(missing(atet[`i']), "", string(atet[`i'], "%9.6f"))
    local seate_s  = cond(missing(se_ate[`i']),  "", string(se_ate[`i'],  "%9.6f"))
    local seatet_s = cond(missing(se_atet[`i']), "", string(se_atet[`i'], "%9.6f"))
	local ciate_s  = ci_ate[`i']
    local ciatet_s = ci_atet[`i']
    local n1 = string(N1[`i'])
    local n0 = string(N0[`i'])

    file write `_fh' "`m' & `s' & `a' & `ate_s' & `atet_s' & `seate_s' & `seatet_s' & `ciate_s' & `ciatet_s' & `n1' & `n0' \\\\" _n
}

file write `_fh' "\bottomrule" _n
file write `_fh' "\end{tabular}" _n
file write `_fh' "\end{table}" _n
file close `_fh'

di as text "Se exportaron:"
di as result " - tabla_resultados_matching.csv"
di as result " - tabla_resultados_matching.tex"
