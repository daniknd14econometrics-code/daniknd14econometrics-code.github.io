/*------------------------------------------------------------------------------
Taller: Propensity Score Matching (PSM) en Stata
Datos: hh_98.dta (microcrédito). 

Idea general:
      PSM:
   - Estimar propensity score (probit/logit)
   - Imponer soporte común (common, trim)
   - Chequear balance en observables sobre el soporte común
   - Probar varios algoritmos: NN(1), NN(2), NN(8), radius (2 calipers), kernel (3 kernels x 2 bandwidths)
   - Reportar ATE y ATET
   - Bootstrap que re-hace los 3 pasos (pscore + soporte + matching)

Requisitos:
- Si no tenés psmatch2: ssc install psmatch2, replace
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

	
**# Lectura previa PSM

	
*==============================================================================
*  PROPENSITY SCORE MATCHING (PSM)
*==============================================================================

/*------------------------------------------------------------------------------
  Propensity score e implementación

- El propensity score es p(X)=Pr(D=1|X). Se estima con logit o probit.
- psmatch2 estima p(X) internamente; por defecto usa probit, y con opción logit usa logit.
- Soporte común en psmatch2:
    common  -> elimina tratados fuera del rango [min,max] de controles en pscore.
    trim(#) -> elimina #% de tratados donde la densidad de controles es más baja.
- por defecto, la tecnica de emparejamiento de psmatch2 es el vecino mas cercano (NN(1)).

Ver help psmatch2 para detalles.

- sobre los errores estandar sobre el ATET:

By default psmatch2 calculates approximate standard errors on the treatment effects assuming 
a) independent observations, 
b) fixed weights, 
c) homoskedasticity of the outcome variable within the treated and within the control groups and 
d) that the variance of the outcome does not depend on the propensity score:
1/N1*Var(Y  DM=1) + Sum(w_i^2; i in DM=0)/(N1)^2*Var(Y  DM=0)
where N1 is the number of matched treated, 
      DM=1 denotes the matched treated, 
	  DM=0 the matched controls and 
	  w_i is the weight given to control i. 
psmatch2 stores the estimate of the standard error of the ATT in r(seatt) or with more than one outcome variable, in r(seatt_varname).
With nearest neighbor matching on the X's (mahal()), then analytical standard errors as in Abadie and Imbens (2006) are calculated when M>0 is passed using option ai(M), where M is the number of neighbors that are used to calculate the conditional variance (formula (14) in Abadie and Imbens, 2006).

------------------------------------------------------------------------------*/

*---------------------------
* B0) Instalar psmatch2 si hace falta
*---------------------------
* ssc install psmatch2, replace

*---------------------------
* B1) Estimar propensity score (probit vs logit) y mirar overlap (didáctico)
*---------------------------
probit $D $X
predict p_probit, pr

logit $D $X
predict p_logit, pr

* Overlap visual simple (histogramas por grupo)
twoway ///
 (hist p_probit if $D==1, percent width(.02) ///
     fcolor(navy%35) lcolor(navy) lwidth(medthick)) ///
 (hist p_probit if $D==0, percent width(.02) ///
     fcolor(maroon%35) lcolor(maroon) lwidth(medthick)), ///
 legend(order(1 "Tratados" 2 "Controles")) ///
 title("Overlap en pscore (probit)") name(hprobit, replace)

 
**# PSM: NN(1) y common-trim
 
*---------------------------
* B2a) Soporte común en psmatch2: common 
*---------------------------
* ---------------------------------------------------------------------------
*  psmatch2: ATET vs ATE, y por qué aparecen "." en S.E.
*
* 1) ¿Qué estima psmatch2 por defecto?
*    - El parámetro "central" por defecto es el ATT (≡ ATET).
*    - Si agregás la opción ate, le estás diciendo:
*         "además de ATET, calculame también ATE (y típicamente reportame ATU, U=untreated)".
*      Por eso en la salida aparecen tres líneas: ATT, ATU y ATE.
*      (En puntos, ya te los muestra "en la misma salida".)
*
* 2) ¿Por qué hay valores vacíos y puntos (.) en errores estándar / t-stat?
*    - En general, psmatch2 reporta S.E. "naive" para ATET y deja vacío (.) para
*      ATU y ATE en esa tabla: no los está calculando allí (no es cero, es missing).
*    - Además, el propio output advierte:
*        "S.E. does not take into account that the propensity score is estimated."
*      Es decir, incluso el S.E. que aparece para ATET es "naive":
*      trata el pscore como si fuera fijo (condicional en el pscore estimado).
*
* 3) Buenas prácticas de inferencia
*    - Si querés S.E. coherentes (para ATET y/o ATE), lo estándar es bootstrap del
*      procedimiento completo (pscore + soporte común + matching) en cada réplica.
*    Eso lo hacemos mas abajo.

* psmatch en la primera etapa (ps), estima un probit o logit sin asumir heterocedasticidad ni correlacion serial (es decir, homocedastico).

* ---------------------------------------------------------------------------

psmatch2 $D $X, out($Y) common ate

* Guardar resultados INMEDIATO (antes de psgraph o cualquier otro comando)
scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)

* (SE) Por ahora los dejamos vacíos a propósito (preferimos bootstrap más abajo)
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .

* Conteos en soporte común (psmatch2 crea _support cuando usás common/trim)
quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)

* No lo posteamos a la tabla final para evitar duplicar NN(1),
* porque esa misma especificación se agrega más abajo en la sección comparativa.

* Display usando scalars (no r())
di as result "ATET (ATT) = " %9.6f ATET_psm "   |   ATE = " %9.6f ATE_psm

* Gráfico (puede pisar r(), pero ya guardamos)
psgraph, scheme(s2color) name(segundo, replace)


*---------------------------
* B2b) Soporte común: trim
*---------------------------
psmatch2 $D $X, out($Y) trim(10) ate

scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)

scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .

quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)

post `_posth' ("PSM (psmatch2)") ("trim(10)") ("NN(1)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)

di as result "ATET (ATT) = " %9.6f ATET_psm "   |   ATE = " %9.6f ATE_psm

psgraph, scheme(s2color) name(tercero, replace)


**# Balance de observables

*---------------------------
* B3) Balance en observables (siempre sobre el soporte común que elegiste)
*---------------------------
* Re-ejecutamos una especificación (quietly) y corremos pstest.

qui psmatch2 $D $X, out($Y) common
pstest, both

/*------------------------------------------------------------------------------
LECTURA DE SALIDAS pstest, both (después de psmatch2)

La clave es leer: 
(i) qué mejoró con el matching, 
(ii) qué empeoró, y 
(iii) si el balance global quedó aceptable.

1) ¿Qué muestra `pstest, both`?

Para cada covariable aparecen dos filas:
- U (Unmatched): antes del matching.
- M (Matched): después del matching (usando pesos/pareos que dejó `psmatch2`).

Columnas:
- Mean Treated / Mean Control: medias en tratados y controles (U o M).
- %bias: diferencia estandarizada en % (standardized mean difference × 100).
  Regla práctica: |%bias| < 10 suele ser "ok"; |%bias| < 5 es "muy bueno".
- %reduct bias: % de reducción del sesgo estandarizado por el matching.
  Si es negativo (ej. -172%), el sesgo empeoró.
- t-test / p>t: test de igualdad de medias. OJO: en matching suele pesar más el %bias que el p-valor (con N grande, o con pesos, podés "significar" por nada).
- V(T)/V(C): ratio de varianzas (tratados/controles). El output marca con * cuando el ratio queda fuera de rangos "aceptables" (es una alerta de diferencias
  en dispersión/distribución, no solo medias).

2) Caso 1: `psmatch2 ..., common`  + `pstest, both`

LO BUENO (mejoras claras):
- educhead: %bias pasa de -34.6 (muy mal) a -0.4 (excelente). Reducción ~99%.
- lnland:   %bias pasa de -46.4 a -0.2 (excelente).
- pcirr:    %bias pasa de 10.3 a 0.6 (muy bien).
- oil:      %bias pasa de 12.9 a 0.9 (muy bien).
En general, el matching está "alineando" bien los X entre tratados y controles.

LO MALO (empeora o queda flojo):
- sexhead: antes era -5.2 (bastante ok) y después queda en +14.1 con p=0.032.
  Esto es un empeoramiento fuerte; por eso aparece %reduct bias = -172.7.
- vaccess: queda en 9.6 (no dramático, pero no perfecto).
- egg:     queda en 10.1 (borderline).
- Ratios de varianza: aparecen * en algunas variables (ej. agehead, wheat, egg),
  indicando posibles diferencias en dispersión (no solo en medias).

DIAGNÓSTICOS GLOBALES (bloque final):
- Ps R2 cae de 0.057 a 0.007 y p>chi2 pasa a 0.364: después del matching, X casi no "explica" D (buena señal).
- MeanBias baja de 12.1 a 4.7 y MedBias de 7.7 a 2.9: avance global muy bueno.
- B = 20.2 (umbral 25): bien.
- R = 0.93 (rango aceptable [0.5, 2]): bien.

CONCLUSIÓN (common):
Balance global bastante bueno, pero queda un problema puntual con sexhead (y algo menor con egg).

*/

qui psmatch2 $D $X, out($Y) trim(10)
pstest, both

/*----------------------------------------------------------------------

3) Caso 2: `psmatch2 ..., trim(10)`  + `pstest, both`

GLOBAL:
- MeanBias 4.9 (vs 4.7) y MedBias 1.7 (mejor que 2.9): globalmente sigue bien.
- B = 21.8 y R = 0.95: bien.
- %Var baja de 33 a 22: mejora (menos covariables con varianzas "fuera de rango").

PERO persisten/peoran dos puntos:
- sexhead: queda alto (15.5) y significativo (p=0.029). Trim no lo arregla.
- egg:     queda 14.7 y ahora significativo (p=0.015). Peor que en common.

CONCLUSIÓN (trim(10)):
Mejora algún aspecto global (MedBias y var ratios), pero deja peor egg y no corrige sexhead.

4) Qué hacer con esto (didáctico/práctico)

- No obsesionarse con el p-valor; mirar principalmente el %bias.
- El mensaje es: "casi todo quedó bien, pero 1–2 covariables siguen problemáticas".

Soluciones típicas (para un taller):
a) Probar otro algoritmo (radius/caliper o kernel). NN(1) a veces deja desbalance
   en dummies si la región de overlap es "rara".
b) Reespecificar el propensity score (agregar no linealidades/interacciones):
   ej. agehead^2, educhead×lnland, etc. En PSM es normal iterar:
   especifico pscore → chequeo balance → ajusto especificación → repito.
------------------------------------------------------------------------------*/

**# PSM: otros emparejamientos


*==============================================================================
* B4) Algoritmos de emparejamiento (PSM)
*==============================================================================

/*------------------------------------------------------------------------------
Vecino más cercano:
- neighbor(1): 1-NN (default; el utilizado hasta ahora en este taller)
- neighbor(2): 2-NN
- neighbor(8): k-NN con k=8

Radial:
- radius caliper(c): usa TODOS los controles con |pscore_t - pscore_c| <= c

Kernel:
- kernel k(epan|gauss|biweight|uniform|tricube) bwidth(h)
  Epanechnikov (epan) es el default en kernel matching.
  
NOTA: deberiamos hacer el test de balance de observables en cada caso. Pero ya mostramos como hacerlo y como leer la salida. 
ahora se trata de mostrar otros emparejamientos.
------------------------------------------------------------------------------*/

*---------------------------
* B4.1 Nearest neighbor: 1, 2, 8
*---------------------------
psmatch2 $D $X, out($Y) common neighbor(1) ate

scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .
quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)

post `_posth' ("PSM (psmatch2)") ("common") ("NN(1)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)

di as result "NN(1)+common: ATET=" %9.6f ATET_psm "   |   ATE = " %9.6f ATE_psm



psmatch2 $D $X, out($Y) common neighbor(2) ate

scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .
quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)

post `_posth' ("PSM (psmatch2)") ("common") ("NN(2)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)

display as result "NN(2)+common: ATET=" %9.6f ATET_psm " | ATE=" %9.6f ATE_psm




psmatch2 $D $X, out($Y) common neighbor(8) ate

scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .
quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)


post `_posth' ("PSM (psmatch2)") ("common") ("NN(8)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)

display as result "NN(8)+common: ATET=" %9.6f ATET_psm " | ATE=" %9.6f ATE_psm



*---------------------------
* B4.2 Radial matching: dos calipers
*---------------------------
psmatch2 $D $X, out($Y) common radius caliper(0.002) ate
scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .
quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)
post `_posth' ("PSM (psmatch2)") ("common") ("Radius(0.002)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)
display as result "Radius(0.002)+common: ATET=" %9.6f ATET_psm " | ATE=" %9.6f ATE_psm


psmatch2 $D $X, out($Y) common radius caliper(0.01) ate
scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .
quietly count if _support==1 & $D==1
scalar N1_psm = r(N)
quietly count if _support==1 & $D==0
scalar N0_psm = r(N)
post `_posth' ("PSM (psmatch2)") ("common") ("Radius(0.01)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)
display as result "Radius(0.01)+common: ATET=" %9.6f ATET_psm " | ATE=" %9.6f ATE_psm

*---------------------------
* B4.3 Kernel matching: mostraremos 3 kernel (K(.)) y 2 bandwidths (h) diferentes como ejemplos
*---------------------------
* Kernels: epan (default), normal, uniform
* Bandwidths: 0.03 y 0.06 (0.06 es un default común en psmatch2)
foreach K in epan normal uniform {
    foreach H in 0.03 0.06 {
        psmatch2 $D $X, out($Y) common kernel k(`K') bwidth(`H') ate
		scalar ATE_psm  = r(ate)
		scalar ATET_psm = r(att)
		scalar SE_ATE_psm  = .
		scalar SE_ATET_psm = .
		quietly count if _support==1 & $D==1
		scalar N1_psm = r(N)
		quietly count if _support==1 & $D==0
		scalar N0_psm = r(N)
		 post `_posth' ("PSM (psmatch2)") ("common") ("Kernel(`K') h=`H'") ///
         (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)
         display as result "Kernel(`K'), h=`H'+common: ATET=" %9.6f  ATET_psm " | ATE=" %9.6f  ATE_psm

    }
}

**# PSM: SE bootstrap
 
*==============================================================================
* B5) Bootstrap "correcto" para psmatch2 (pscore + soporte + matching)
*==============================================================================

/*------------------------------------------------------------------------------
Idea:
- Al envolver psmatch2 dentro de bootstrap, cada réplica re-estima el pscore,
  re-aplica common/trim y re-hace el matching.
- Para ATE/ATET en psmatch2, pedimos la opción ate para que existan r(ate) y r(att).
- vamos a mostrar con dos ejemplos. Pero, en una rutina seria, deberiamos probar con varios casos, y a todos pasarlos por bootstrap y luego elegir el mejor bajo un criterio inteligente.
------------------------------------------------------------------------------*/

set seed 20260211

*---------------------------
* B5.1) Kernel epan, bwidth(0.06), common
*---------------------------

* (i) Corré 1 vez para dejar _support y contar N1/N0 (y como chequeo rápido)
qui psmatch2 $D $X, out($Y) common kernel k(epan) bwidth(0.06) ate
scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
* Por ahora, dejás SE en missing:
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .

qui count if _support==1 & $D==1
scalar N1_psm = r(N)
qui count if _support==1 & $D==0
scalar N0_psm = r(N)

* (ii) Bootstrap: nombrá las stats para poder usar _b[atet], _se[atet], etc.
bootstrap atet=r(att) ate=r(ate), reps(200) seed(20260211) nodots: ///
    psmatch2 $D $X, out($Y) common kernel k(epan) bwidth(0.06) ate

* 3) Guardar puntos y SE desde el resultado del bootstrap
scalar ATET_psm     = _b[atet]
scalar ATE_psm      = _b[ate]
scalar SE_ATET_psm  = _se[atet]
scalar SE_ATE_psm   = _se[ate]

* 4) Post a la tabla comparativa (igual que venías haciendo)
post `_posth' ("PSM (psmatch2)") ("common") ("Kernel(epan); h=0.06 (boots)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)

display as result "Kernel(epan); h=0.06+common (BOOT): ATET=" %9.6f ATET_psm ///
    " (SE=" %9.6f SE_ATET_psm ") | ATE=" %9.6f ATE_psm " (SE=" %9.6f SE_ATE_psm ")"

	
*---------------------------
* B5.2) NN(8), trim(10)
*---------------------------

qui psmatch2 $D $X, out($Y) trim(10) neighbor(8) ate
scalar ATE_psm  = r(ate)
scalar ATET_psm = r(att)
* Por ahora, dejás SE en missing:
scalar SE_ATE_psm  = .
scalar SE_ATET_psm = .

qui count if _support==1 & $D==1
scalar N1_psm = r(N)
qui count if _support==1 & $D==0
scalar N0_psm = r(N)


bootstrap atet=r(att) ate=r(ate), reps(200) seed(20260211) nodots: ///
    psmatch2 $D $X, out($Y) trim(10) neighbor(8) ate

scalar ATET_psm     = _b[atet]
scalar ATE_psm      = _b[ate]
scalar SE_ATET_psm  = _se[atet]
scalar SE_ATE_psm   = _se[ate]

post `_posth' ("PSM (psmatch2)") ("trim(10)") ("NN(8) (boots)") ///
    (ATE_psm) (ATET_psm) (SE_ATE_psm) (SE_ATET_psm) (N1_psm) (N0_psm)

display as result "NN(8)+trim(10) (BOOT): ATET=" %9.6f ATET_psm ///
    " (SE=" %9.6f SE_ATET_psm ") | ATE=" %9.6f ATE_psm " (SE=" %9.6f SE_ATE_psm ")"



**# PSM: con teffects 
	
*==============================================================================
* B6) ATE y ATET con teffects psmatch (alternativa oficial)
*==============================================================================

/*------------------------------------------------------------------------------
"teffects psmatch" estima ATE (default) o ATET.
Ejemplo (probit):
    teffects psmatch (Y) (D X, probit), ate
    teffects psmatch (Y) (D X, probit), atet
	
Guardar resultados teffects (usa SE que contemplan la estimación del pscore)
-Extraemos el primer coeficiente y su SE desde e(b) y e(V).
-Nota: hacemos dos corridas separadas: ate y atet.	
 
"teffects psmatch": Esto es propensity score matching. 
-Por diseño se implementa como matching por vecino más cercano (NN) sobre el propensity score.
-Podés elegir cuántos vecinos (nneighbor(#)), si con o sin reemplazo (osample()/atet etc.), calipers (caliper(#)), y algunas variantes de soporte.
-Pero no te ofrece kernel matching ni radius matching "tipo psmatch2" en el sentido clásico (aunque el caliper hace algo parecido a "restringir" emparejamientos).

Lo que teffects NO te da como opciones nativas dentro de su matching:
-Kernel matching (Epanechnikov, Gaussian, etc.) como lo hacés con psmatch2.
-Radius matching en el sentido de "usar todos los controles dentro de un radio y ponderar" (aunque con caliper() y nneighbor() podés aproximar algunas cosas, no es lo mismo)

* ---------------------------------------------------------------------------
*  SE en teffects psmatch: ¿son naive? ¿vienen por bootstrap?
*
* 1) NO son bootstrap por defecto.
*    - teffects psmatch reporta errores estándar asintóticos calculados por Stata
*      (linearization / M-estimation, tipo "sandwich").
*    - Por eso ya aparecen z/t y p-values sin que uno haga bootstrap.
*
* 2) NO son "naive" en el sentido de psmatch2.
*    - En psmatch2 suele aparecer la advertencia:
*        "S.E. does not take into account that the propensity score is estimated."
*      (es decir, trata el pscore como si fuera fijo).
*    - En cambio, en teffects psmatch la inferencia está planteada para el
*      estimador implementado y, en principio, incorpora la primera etapa
*      (que el propensity score fue estimado).
*
* 3) Matching tiene matices teóricos (Abadie–Imbens, etc.).
*    - En NN matching la varianza puede depender de detalles del matching:
*      # vecinos, con/sin reemplazo, dimensión de X, etc.
*    - teffects tiene estimadores con teoría propia; suele funcionar bien,
*      pero bootstrap puede usarse como chequeo de robustez (sobre todo con
*      muestras chicas, soporte frágil, o para IC por percentiles).
*
* 4) Si hay estructura de panel / clustering:
*    - Si existe correlación intra-cluster (misma firma/persona/aldea, etc.),
*      los SE por defecto pueden ser incorrectos si no ajustás.
*    - En teffects podés pedir SE clusterizados con:
*         vce(cluster id)
*    - Si querés bootstrap cluster, se hace explícitamente, por ejemplo:
*         bootstrap, cluster(id): teffects ...
*
* Regla práctica del taller:
* - psmatch2: SE en pantalla = "naive"; lo serio es bootstrap re-haciendo
*   pscore + soporte + matching.
* - teffects psmatch: SE ya vienen "bien armados" por Stata (no bootstrap);
*   si hay clustering/panel, usar vce(cluster ...).
* ---------------------------------------------------------------------------


------------------------------------------------------------------------------*/


* ATE
teffects psmatch ($Y) ($D $X, probit), ate vce(robust)
matrix b = e(b)
matrix V = e(V)
scalar ATE_te = b[1,1]
scalar SE_ATE_te = sqrt(V[1,1])
quietly count if e(sample) & $D==1
scalar N1_te = r(N)
quietly count if e(sample) & $D==0
scalar N0_te = r(N)
post `_posth' ("teffects") ("psmatch") ("ATE, nn(1)") (ATE_te) (.) (SE_ATE_te) (.) (N1_te) (N0_te)

* ATET
teffects psmatch ($Y) ($D $X, probit), atet vce(robust)
matrix b = e(b)
matrix _V = e(V)
scalar ATET_te = b[1,1]
scalar SE_ATET_te = sqrt(_V[1,1])
quietly count if e(sample) & $D==1
scalar N1_te = r(N)
quietly count if e(sample) & $D==0
scalar N0_te = r(N)
post `_posth' ("teffects") ("psmatch") ("ATET, nn(1)") (.) (ATET_te) (.) (SE_ATET_te) (N1_te) (N0_te)

**# Balance de observables con teffects


* Balance de observables usando teffects
tebalance summarize
tebalance density


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

* Export simple para llevar a Excel / LaTeX
export delimited using "tabla_resultados_psm.csv", replace

* (Opcional) generar un .tex con una tabla simple (sin depender de paquetes extra)
tempname _fh
file open `_fh' using "tabla_resultados_psm.tex", write replace
file write `_fh' "\begin{table}[!htbp]\centering" _n
file write `_fh' "\caption{Comparacion de estimadores (PSM)}" _n
file write `_fh' "\label{tab:match_psm_comparacion}" _n
file write `_fh' "\small" _n
file write `_fh' "\begin{tabular}{lllrrrrrr}" _n
file write `_fh' "\toprule" _n
file write `_fh' "Metodo & Soporte & Algoritmo & ATE & ATET & SE(ATE) & SE(ATET) & N1 & N0 \\" _n
file write `_fh' "\midrule" _n

forvalues i=1/`=_N' {
    local m  = method[`i']
    local s  = support[`i']
    local a  = algorithm[`i']
    local ate_s  = cond(missing(ate[`i']),  "", string(ate[`i'],  "%9.6f"))
    local atet_s = cond(missing(atet[`i']), "", string(atet[`i'], "%9.6f"))
    local seate_s  = cond(missing(se_ate[`i']),  "", string(se_ate[`i'],  "%9.6f"))
    local seatet_s = cond(missing(se_atet[`i']), "", string(se_atet[`i'], "%9.6f"))
    local n1 = string(N1[`i'])
    local n0 = string(N0[`i'])

    file write `_fh' "`m' & `s' & `a' & `ate_s' & `atet_s' & `seate_s' & `seatet_s' & `n1' & `n0' \\\\" _n
}

file write `_fh' "\bottomrule" _n
file write `_fh' "\end{tabular}" _n
file write `_fh' "\end{table}" _n
file close `_fh'

di as text "Se exportaron:"
di as result " - tabla_resultados_psm.csv"
di as result " - tabla_resultados_psm.tex"


/*------------------------------------------------------------------------------
Notas finales para el taller:
1) Interpretación en log:
   Si Y = ln(1+exptot), una diferencia de 0.11 son ~11% en primera aproximación,
   pero la conversión exacta sería exp(0.11)-1 ≈ 11.6%.

2) Qué mirar para "robustez":
   - Que ATE/ATET no cambien drásticamente entre métodos razonables.
   - Que el balance (pstest/tebalance) mejore post-matching.
   - Que el soporte común no deje afuera una parte grande de los tratados.

3) Taller avanzado (próximo):
   - Elegir automáticamente (método, caliper/bandwidth, k) minimizando MSE.
   - O elegir por validación cruzada (predictive performance de Y o balance).
------------------------------------------------------------------------------*/
