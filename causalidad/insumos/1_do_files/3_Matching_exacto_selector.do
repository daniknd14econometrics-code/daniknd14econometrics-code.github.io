/*------------------------------------------------------------------------------
Taller adicional 3 (versión definitiva): Selector automático para Matching Exacto / CEM
Autor: (Daniel + ChatGPT)

IDEA CENTRAL (alineada con guías de diseño):
- Separar "DISEÑO" (matching/weighting) de "ANÁLISIS" (estimación del efecto).
- En DISEÑO, NO usamos el outcome para rankear (ni ATET ni SE_boot).  → evita optimizar hacia resultados.
- Elegimos entre candidatos usando:
    (i) Balance (SMD + L1),
    (ii) Soporte/precisión-proxy (ESS de controles, N1 retenidos).
- Recién después, para el método ganador, estimamos ATET y su SE.

Notas:
- max|SMD| <= 0.10 es una regla común; puede ser exigente cuando tomás el máximo sobre muchas covariables.
  Si priorizás soporte (más N/ESS) podés relajar a 0.15 o 0.20, explicitando el trade-off.
- CEM: el efecto se estima usando cem_weights; si queda desbalance residual dentro de bins, podés hacer
  ajuste por modelo con esos pesos (opcional y transparente).

Requisitos:
- Dataset hh_98.dta en el working directory (o ajustar ruta).
- Paquete CEM instalado: ssc install cem

Sobre tus decisiones concretas:

1) max|SMD| ≤ 0.10 como default está perfecto, con comentario de que 0.20 prioriza soporte. En el PDF está tal cual la interpretación: 0.10 puede ser exigente cuando tomás el "máximo" sobre muchas covariables, y relajar a 0.20 puede cambiar el ganador porque entra más soporte. 

2) No linealidades (cuadráticos, interacciones): sí las recomiendo como diagnóstico de balance (no como "meterlas en el outcome sí o sí"). La motivación también está en el PDF: podés balancear medias pero no balancear partes relevantes de la distribución; por eso mirar transformaciones ayuda. Yo te lo dejo como toggle ON/OFF.

3) L1: sí, la mantendría. Es un resumen multivariado natural en esquemas tipo CEM/estratos y te refleja composición por estratos. Yo la calculo tanto para CEM como para exact matching (en el espacio de estratos).

4) "Core covariables" con umbral más estricto: conceptualmente es muy defendible (Stuart lo menciona: priorizar covariables pronósticas), pero exige que vos definas cuáles son "core". Para no romper tu idea de automatización, lo dejé implementado como toggle (USE_CORE) pero apagado por defecto.

CORRECCIÓN CLAVE (pedido por el usuario):
- Si USE_CORE==1, TODO el trabajo (DISEÑO + EVALUACIÓN de balance) se hace SOLO con Xcore.
  → En ese caso max|SMD| se calcula solo sobre Xcore (y, si ADD_SQ==1, solo sobre sus no-linealidades).
  → Por construcción, maxsmd == maxcore.
- Si USE_CORE==0, TODO el trabajo se hace con Xbal (y no-linealidades si ADD_SQ==1).

----------------------------------------------------------------------*/


**# Directorio de trabajo comun

clear all
set more off
set trace off
set rmsg off

global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres"

local username = c(username)
display "`username'"

local username = c(username)

if "`username'" == "Equipo" {
     global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres"
}
else if "`username'" == "dmendez" {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres"
}
else {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres"
}


*---------------------------
* 0) Directorio y datos
*---------------------------

use "$seteo\Directorio común bases\hh_98.dta", clear 
set more off
set trace off
set rmsg off


*========================
* 1) Variables del taller
*========================

describe 

gen lexptot = ln(1+exptot)
gen lnland  = ln(1+hhland/100)

global Y lexptot
global D dfmfd

* --- Covariables completas (modo Xbal) ---
global Xbal ///
    sexhead ///
    vaccess ///
    agehead ///
    educhead ///
    lnland ///
    pcirr ///
    rice ///
    wheat ///
    milk ///
    oil ///
    egg

summarize $Xbal

* --- Core set ---
global Xcore sexhead vaccess agehead educhead lnland pcirr

* Toggle: si USE_CORE==1, TODO el trabajo usa Xcore (diseño + balance). Default: 0.
global USE_CORE 1

* Set base efectivo (según modo) para:
*   - Construir estratos/bins en DISEÑO (Exact y CEM)
*   - Evaluar balance en DISEÑO
global Xbase ""
if ($USE_CORE==1) global Xbase $Xcore
else             global Xbase $Xbal

* Variables efectivamente usadas para CEM/Exact en DISEÑO
global Xmatch $Xbase

* --- Variables extra (solo relevantes cuando USE_CORE==0 / modo Xbal) ---
global Xextra_match rice wheat milk oil egg

* --- Continuas: dependen del set elegido (sirven para cuadrados y para Exact bins) ---
global Xcont_core agehead educhead lnland pcirr
global Xcont_xbal  agehead educhead lnland pcirr rice wheat milk oil egg
global Xcont ""
if ($USE_CORE==1) global Xcont $Xcont_core
else             global Xcont $Xcont_xbal

* --- Binning de variables extra en EXACT (modo Xbal): un poco más grueso que las core ---
* S1: core (lnland/pcirr) usa 4 bins → extra usa 3
* S2: core (lnland/pcirr) usa 3 bins → extra usa 2
global EXTRA_NQ_S1 3
global EXTRA_NQ_S2 2


*========================
* 2) Parámetros del selector (DISEÑO)
*========================
* Umbral principal para max|SMD|
global SMD_THR 0.10

* Umbral alternativo (solo para mostrar sensibilidad, NO para seleccionar por defecto)
global SMD_THR_RELAX 0.20

* Si USE_CORE=1:
global SMD_THR_CORE  0.10
global SMD_THR_OTHER 0.20


* Transformaciones para balance (cuadráticos / interacciones): OFF por defecto
* global ADD_SQ 0 = medida desactivada.
global ADD_SQ 0

* --- Ajuste automático de umbrales cuando el set de balance incluye no-linealidades ---
* Regla práctica: con cuadrados/interacciones el max|SMD| como hard rule se vuelve más exigente.
if ($ADD_SQ==1) {
    global SMD_THR 0.20
    global SMD_THR_RELAX 0.30
}

* (Opcional) Love plot SMD del ganador: ON por defecto
global PLOT_WINNER 1


*========================
* 3) Muestra base (completa) para comparar candidatos de forma justa
*========================
* OJO: si dejás missings, el balance puede ser incomparable entre candidatos.
*      Acá usamos complete-case en Y, D y en el set efectivo (Xbase),
*      que coincide con el universo de DISEÑO + BALANCE del modo elegido.

foreach v of global Xbase {
    drop if missing(`v')
}
drop if missing($Y, $D)

* Guardar base limpia
tempfile base
save `base', replace


*========================
* 4) (Opcional) Expandir set de balance con no-linealidades
*========================
use `base', clear

local Xextra ""
global Xsq ""

if ($ADD_SQ==1) {
    foreach v of global Xcont {
        capture drop `v'_sq
        gen double `v'_sq = `v'^2
        local Xextra "`Xextra' `v'_sq"
        global Xsq $Xsq `v'_sq
    }
}

* Set final de evaluación de balance (según modo):
* - Core mode: Xeval = Xcore (+ cuadrados si ADD_SQ==1)
* - Xbal mode: Xeval = Xbal  (+ cuadrados si ADD_SQ==1)
global Xeval $Xbase `Xextra'
global Xother ""
if ($USE_CORE==0) {
    * Variables no-core (solo informativo): Xeval \ Xcore
    local tmp : list global Xeval - global Xcore
    global Xother `tmp'
}



save `base', replace


*========================
* 5) Helpers: SMD, ESS, L1
*========================
capture program drop _smd_one
program define _smd_one, rclass
    * SMD con pesos ATT para controles; tratados peso=1.
    syntax varname, WVAR(name) IFCOND(string)

    tempname m1 s1 m0 s0 sp
    quietly summarize `varlist' if `ifcond' & $D==1
    scalar `m1' = r(mean)
    scalar `s1' = r(sd)
    if (missing(`s1')) scalar `s1' = 0

    quietly summarize `varlist' [aw=`wvar'] if `ifcond' & $D==0
    scalar `m0' = r(mean)
    scalar `s0' = r(sd)
    if (missing(`s0')) scalar `s0' = 0

    scalar `sp' = sqrt((`s1'^2 + `s0'^2)/2)
    if (missing(`sp') | `sp'==0) return scalar smd = 0
    else return scalar smd = (`m1' - `m0')/`sp'
end


capture program drop _ess_controls
program define _ess_controls, rclass
    * ESS de controles con pesos w: (sum w)^2 / sum(w^2)
    syntax, WVAR(name) IFCOND(string)

    tempname sw sw2
    quietly summarize `wvar' if `ifcond' & $D==0, meanonly
    scalar `sw' = r(sum)

    tempvar w2
    gen double `w2' = (`wvar')^2 if `ifcond' & $D==0
    quietly summarize `w2' if `ifcond' & $D==0, meanonly
    scalar `sw2' = r(sum)
    drop `w2'

    if (`sw2'==0) return scalar ess0 = .
    else return scalar ess0 = (`sw'^2)/`sw2'
end


capture program drop eval_balance
program define eval_balance, rclass
    * Calcula: max|SMD| y mean|SMD| sobre Xeval (Xcore si USE_CORE==1, Xbal si USE_CORE==0).
    * Además: max|SMD| sobre el subconjunto core y, si aplica, sobre el subconjunto no-core.
    * Nota: por pedido del usuario, NO calcula VR ni KS.
    syntax, MATCHED(name) WATT(name)

    local ifc "`matched'==1"

    tempname maxa meana maxcore maxother
    scalar `maxa'     = 0
    scalar `meana'    = 0
    scalar `maxcore'  = 0
    scalar `maxother' = .

    local var_maxa    ""
    local var_maxcore ""
    local var_maxother ""

    local k = 0

    * --- Máximo y promedio absoluto en el set evaluado (Xeval) ---
    foreach x of global Xeval {
        quietly _smd_one `x', wvar(`watt') ifcond("`ifc'")
        scalar smd = r(smd)
        scalar abs_smd = abs(smd)

        scalar `meana' = `meana' + abs_smd
        if (abs_smd > `maxa') {
            scalar `maxa' = abs_smd
            local var_maxa "`x'"
        }
        local ++k
    }
    if (`k'>0) scalar `meana' = `meana'/`k'

    * --- Core set (siempre, para poder aplicar umbrales diferenciales) ---
    foreach x of global Xcore {
        quietly _smd_one `x', wvar(`watt') ifcond("`ifc'")
        scalar abs_smd = abs(r(smd))
        if (abs_smd > `maxcore') {
            scalar `maxcore' = abs_smd
            local var_maxcore "`x'"
        }
    }

    * --- No-core (solo si existe Xother) ---
    if ("$Xother"!="") {
        scalar `maxother' = 0
        foreach x of global Xother {
            quietly _smd_one `x', wvar(`watt') ifcond("`ifc'")
            scalar abs_smd = abs(r(smd))
            if (abs_smd > `maxother') {
                scalar `maxother' = abs_smd
                local var_maxother "`x'"
            }
        }
    }

    return scalar maxsmd   = `maxa'
    return scalar meansmd  = `meana'
    return scalar maxcore  = `maxcore'
    return scalar maxother = `maxother'

    return local var_maxsmd   "`var_maxa'"
    return local var_maxcore  "`var_maxcore'"
    return local var_maxother "`var_maxother'"

    quietly _ess_controls, wvar(`watt') ifcond("`ifc'")
    return scalar ess0 = r(ess0)
end

*========================
* 6) Métodos candidatos: Exact (S1/S2) y CEM (autocuts)
*========================

* --- Helper: construir estratos para Exact (S1/S2) respetando USE_CORE y ADD_SQ ---
capture program drop make_stratum_exact
program define make_stratum_exact
    syntax, SCHEME(string) STRATUM(name)

    tempvar agebin edubin landbin pcirrbin

    if ("`scheme'"=="S1") {
        recode agehead (min/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5) (66/75=6) (76/max=7), gen(`agebin')
        recode educhead (0=0) (1/4=1) (5/8=2) (9/max=3), gen(`edubin')
        xtile `landbin'  = lnland, nq(4)
        xtile `pcirrbin' = pcirr,  nq(4)
    }
    else if ("`scheme'"=="S2") {
        recode agehead (min/35=1) (36/50=2) (51/65=3) (66/max=4), gen(`agebin')
        recode educhead (0/2=0) (3/6=1) (7/max=2), gen(`edubin')
        xtile `landbin'  = lnland, nq(3)
        xtile `pcirrbin' = pcirr,  nq(3)
    }
    else {
        di as error "scheme inválido. Usá S1 o S2."
        exit 198
    }

    * Base del grupo (core siempre presente)
    local groupvars "sexhead vaccess `agebin' `edubin' `landbin' `pcirrbin'"

    * Extra vars solo si USE_CORE==0 (modo Xbal): discretización un poco más gruesa
    if ($USE_CORE==0) {
        foreach v of global Xextra_match {
            tempvar b_`v'
            if ("`scheme'"=="S1") xtile `b_`v'' = `v', nq($EXTRA_NQ_S1)
            else                     xtile `b_`v'' = `v', nq($EXTRA_NQ_S2)
            local groupvars "`groupvars' `b_`v''"
        }
    }

    * Cuadráticos (bins de cuadrados) si ADD_SQ==1
    if ($ADD_SQ==1) {
        * Asegurar que existan los cuadrados para Xcont
        foreach v of global Xcont {
            capture confirm variable `v'_sq
            if (_rc) gen double `v'_sq = `v'^2
        }

        tempvar age2bin edu2bin land2bin pcirr2bin
        if ("`scheme'"=="S1") {
            xtile `age2bin'   = agehead_sq,   nq(7)
            xtile `edu2bin'   = educhead_sq,  nq(4)
            xtile `land2bin'  = lnland_sq,    nq(4)
            xtile `pcirr2bin' = pcirr_sq,     nq(4)
        }
        else {
            xtile `age2bin'   = agehead_sq,   nq(4)
            xtile `edu2bin'   = educhead_sq,  nq(3)
            xtile `land2bin'  = lnland_sq,    nq(3)
            xtile `pcirr2bin' = pcirr_sq,     nq(3)
        }
        local groupvars "`groupvars' `age2bin' `edu2bin' `land2bin' `pcirr2bin'"

        if ($USE_CORE==0) {
            foreach v of global Xextra_match {
                tempvar b2_`v'
                if ("`scheme'"=="S1") xtile `b2_`v'' = `v'_sq, nq($EXTRA_NQ_S1)
                else                     xtile `b2_`v'' = `v'_sq, nq($EXTRA_NQ_S2)
                local groupvars "`groupvars' `b2_`v''"
            }
        }
    }

    egen `stratum' = group(`groupvars'), label
end


capture program drop exact_atet
program define exact_atet, rclass
    * ATET por Exact Matching (estratos), respetando USE_CORE y ADD_SQ.
    syntax, SCHEME(string)

    tempvar stratum N1 N0 support y1_tmp y0_tmp

    quietly make_stratum_exact, scheme(`scheme') stratum(`stratum')

    bys `stratum': egen `N1' = total($D==1)
    bys `stratum': egen `N0' = total($D==0)
    gen byte `support' = (`N1'>0 & `N0'>0)

    preserve
        keep if `support'==1

        gen double `y1_tmp' = $Y if $D==1
        gen double `y0_tmp' = $Y if $D==0

        collapse ///
            (sum)  N1cell = $D ///
            (mean) y1 = `y1_tmp' ///
            (mean) y0 = `y0_tmp' ///
            , by(`stratum')

        gen diff = y1 - y0

        quietly summarize N1cell, meanonly
        scalar N1tot = r(sum)

        gen double w_atet = N1cell/N1tot
        gen double c_atet = w_atet*diff
        quietly summarize c_atet, meanonly
        return scalar atet = r(sum)
    restore
end


capture program drop exact_atet_boot
program define exact_atet_boot, rclass
    syntax, SCHEME(string)
    quietly exact_atet, scheme(`scheme')
    return scalar atet = r(atet)
end


* >>>>> ATE (en el soporte común / estratos con ambos grupos) <<<<<
capture program drop exact_ate
program define exact_ate, rclass
    * ATE por Exact Matching (estratos), respetando USE_CORE y ADD_SQ.
    syntax, SCHEME(string)

    tempvar stratum N1 N0 support y1_tmp y0_tmp

    quietly make_stratum_exact, scheme(`scheme') stratum(`stratum')

    bys `stratum': egen `N1' = total($D==1)
    bys `stratum': egen `N0' = total($D==0)
    gen byte `support' = (`N1'>0 & `N0'>0)

    preserve
        keep if `support'==1

        gen double `y1_tmp' = $Y if $D==1
        gen double `y0_tmp' = $Y if $D==0

        collapse ///
            (sum)   N1cell = $D ///
            (count) Ncell  = $D ///
            (mean)  y1 = `y1_tmp' ///
            (mean)  y0 = `y0_tmp' ///
            , by(`stratum')

        gen double diff = y1 - y0

        quietly summarize Ncell, meanonly
        scalar Ntot = r(sum)

        gen double w_ate = Ncell/Ntot
        gen double c_ate = w_ate*diff
        quietly summarize c_ate, meanonly
        return scalar ate = r(sum)
    restore
end


capture program drop exact_ate_boot
program define exact_ate_boot, rclass
    syntax, SCHEME(string)
    quietly exact_ate, scheme(`scheme')
    return scalar ate = r(ate)
end


* --- CEM: requiere paquete ---
capture which cem
if (_rc) {
    di as error "No encuentro el comando cem. Instalalo con: ssc install cem"
    exit 499
}


*========================
* 7) Evaluación de candidatos (DISEÑO): balance + soporte
*========================
use `base', clear

tempfile results
tempname ph

postfile `ph' str8 method str12 spec ///
    double maxsmd double meansmd double maxcore double maxother ///
    str20 var_maxsmd str20 var_maxcore str20 var_maxother ///
    double L1 double L1_cem double ess0 int N1 int N0 using "`results'", replace


*-------- 7.1 Exact candidates --------
foreach sc in S1 S2 {

    * Recargar base limpia en cada candidato (evita preserve anidado y arrastres).
    use `base', clear

    * Construir estratos y pesos ATT (controles ponderados por N1cell/N0cell dentro de estrato)
    tempvar stratum N1cell N0cell matched w_att

    quietly make_stratum_exact, scheme(`sc') stratum(`stratum')

    bys `stratum': egen `N1cell' = total($D==1)
    bys `stratum': egen `N0cell' = total($D==0)
    gen byte `matched' = (`N1cell'>0 & `N0cell'>0)

    * Pesos ATT: tratados peso=1, controles peso=N1cell/N0cell dentro de estrato
    gen double `w_att' = 1
    replace `w_att' = `N1cell'/`N0cell' if $D==0 & `matched'==1

    quietly count if `matched'==1 & $D==1
    scalar N1 = r(N)
    quietly count if `matched'==1 & $D==0
    scalar N0 = r(N)

    * Si no hay soporte común, posteamos missings y seguimos
    if (N1==0 | N0==0) {
        scalar maxsmd  = .
        scalar meansmd = .
        scalar maxcore = .
        scalar maxother = .
        scalar ess0    = .
        scalar L1      = .
        local vmaxsmd   ""
        local vmaxcore  ""
        local vmaxother ""
        post `ph' ("Exact") ("`sc'") (maxsmd) (meansmd) (maxcore) (maxother) ("`vmaxsmd'") ("`vmaxcore'") ("`vmaxother'") (L1) (.) (ess0) (N1) (N0)
        continue
    }

    quietly eval_balance, matched(`matched') watt(`w_att')
    scalar maxsmd  = r(maxsmd)
    scalar meansmd = r(meansmd)
    scalar maxcore = r(maxcore)
    scalar ess0    = r(ess0)
    scalar maxother = r(maxother)
    local vmaxsmd   "`r(var_maxsmd)'"
    local vmaxcore  "`r(var_maxcore)'"
    local vmaxother "`r(var_maxother)'"

    * L1 (manual) entre distribuciones de estratos en tratados vs controles (en soporte)
    keep if `matched'==1
    tempvar n1 n0 p1 p0 abs
    bys `stratum': egen `n1' = total($D==1)
    bys `stratum': egen `n0' = total($D==0)
    bys `stratum': keep if _n==1

    quietly summarize `n1', meanonly
    scalar N1t = r(sum)
    quietly summarize `n0', meanonly
    scalar N0t = r(sum)

    if (N1t==0 | N0t==0 | missing(N1t) | missing(N0t)) {
        scalar L1 = .
    }
    else {
        gen double `p1'  = `n1'/N1t
        gen double `p0'  = `n0'/N0t
        gen double `abs' = abs(`p1' - `p0')
        quietly summarize `abs', meanonly
        scalar L1 = 0.5*r(sum)
    }

    post `ph' ("Exact") ("`sc'") (maxsmd) (meansmd) (maxcore) (maxother) ("`vmaxsmd'") ("`vmaxcore'") ("`vmaxother'") (L1) (.) (ess0) (N1) (N0)
}


*-------- 7.2 CEM candidates --------
foreach ac in sturges fd scott ss {

    use `base', clear

    capture drop cem_matched cem_weights cem_strata

    local cemvars "$Xmatch"
    if ($ADD_SQ==1) local cemvars "`cemvars' $Xsq"

    cem `cemvars', tr($D) autocuts(`ac')

    * Capturar L1 del comando CEM inmediatamente
    scalar L1_cem = .
    capture scalar L1_cem = r(L1)
    if _rc capture scalar L1_cem = r(l1)

    gen byte   matched = (cem_matched==1)
    gen double w_att   = cem_weights

    quietly count if matched==1 & $D==1
    scalar N1 = r(N)
    quietly count if matched==1 & $D==0
    scalar N0 = r(N)

    * Si no hay soporte común, posteamos missings y seguimos
    if (N1==0 | N0==0) {
        scalar maxsmd  = .
        scalar meansmd = .
        scalar maxcore = .
        scalar ess0    = .
        scalar L1      = .
        scalar maxother = .
        local vmaxsmd   ""
        local vmaxcore  ""
        local vmaxother ""
        post `ph' ("CEM") ("`ac'") (maxsmd) (meansmd) (maxcore) (maxother) ("`vmaxsmd'") ("`vmaxcore'") ("`vmaxother'") (L1) (L1_cem) (ess0) (N1) (N0)
        continue
    }

    quietly eval_balance, matched(matched) watt(w_att)
    scalar maxsmd   = r(maxsmd)
    scalar meansmd  = r(meansmd)
    scalar maxcore  = r(maxcore)
    scalar ess0     = r(ess0)
    scalar maxother = r(maxother)
    local vmaxsmd   "`r(var_maxsmd)'"
    local vmaxcore  "`r(var_maxcore)'"
    local vmaxother "`r(var_maxother)'"

    * L1 manual en el espacio de estratos de CEM (por composición de strata)
    keep if matched==1
    tempvar n1 n0 p1 p0 abs
    bys cem_strata: egen `n1' = total($D==1)
    bys cem_strata: egen `n0' = total($D==0)
    bys cem_strata: keep if _n==1

    quietly summarize `n1', meanonly
    scalar N1t = r(sum)
    quietly summarize `n0', meanonly
    scalar N0t = r(sum)

    if (N1t==0 | N0t==0 | missing(N1t) | missing(N0t)) {
        scalar L1 = .
    }
    else {
        gen double `p1'  = `n1'/N1t
        gen double `p0'  = `n0'/N0t
        gen double `abs' = abs(`p1' - `p0')
        quietly summarize `abs', meanonly
        scalar L1 = 0.5*r(sum)
    }

    post `ph' ("CEM") ("`ac'") (maxsmd) (meansmd) (maxcore) (maxother) ("`vmaxsmd'") ("`vmaxcore'") ("`vmaxother'") (L1) (L1_cem) (ess0) (N1) (N0)
}


*========================
* 7.3) Cerrar postfile y cargar tabla de resultados
*========================
postclose `ph'

* (Muy recomendado) borrar scalars homónimos para evitar confusiones
capture scalar drop maxsmd meansmd maxcore maxother L1 L1_cem ess0 N1 N0

use "`results'", clear
describe
list, sep(0)


*=================================
* 8) Selección automática (DISEÑO)
*=================================

gen byte pass_smd = (maxsmd <= $SMD_THR)

gen byte pass_core = 1
if ($USE_CORE==1) {
    * En core mode, como maxsmd==maxcore por construcción, esto termina siendo:
    * pass_core = (maxsmd <= SMD_THR_CORE)
    replace pass_core = (maxcore <= $SMD_THR_CORE) & (maxsmd <= $SMD_THR_OTHER)
}

gen byte pass = pass_smd & pass_core

quietly count if pass==1
if (r(N)>0) {
    gsort -pass -ess0 -N1 maxsmd meansmd L1
}
else {
    di as text "Nota: ningún candidato pasó los umbrales hard (SMD/core)."
    di as text "Se rankea por menor max|SMD| y luego mayor ESS0/N1."
    gsort maxsmd -ess0 -N1 meansmd L1
}

di as text "==============================="
di as text "Ranking (mejor arriba):"
local top = min(_N, 10)
if (`top'==0) {
    di as error "No hay candidatos en la tabla de resultados (revisá que el loop haya corrido)."
    exit 498
}
else {
    list method spec pass maxsmd var_maxsmd maxcore var_maxcore maxother var_maxother meansmd L1 L1_cem ess0 N1 N0 in 1/`top', noobs
}
di as text "==============================="

* --- Sensibilidad rápida (informativa): umbral relajado SMD ---
gen byte pass_relax = (maxsmd <= $SMD_THR_RELAX)
preserve
    gsort -pass_relax -ess0 -N1 maxsmd
    di as text "Si usaras max|SMD| <= $SMD_THR_RELAX, el top sería:"
    list method spec pass_relax maxsmd var_maxsmd maxcore var_maxcore maxother var_maxother meansmd L1 L1_cem ess0 N1 N0 in 1/1, noobs
restore

* --- Frontera no-dominada (min maxsmd, max ess0) ---
gen byte dominated = 0
forvalues i=1/`=_N' {
    quietly count if (maxsmd <= maxsmd[`i'] & ess0 >= ess0[`i']) ///
        & (maxsmd < maxsmd[`i'] | ess0 > ess0[`i'])
    if (r(N)>0) replace dominated = 1 in `i'
}
di as text "Frontera no-dominada (dominated==0):"
list method spec pass maxsmd var_maxsmd maxcore var_maxcore maxother var_maxother meansmd L1 L1_cem ess0 N1 N0 if dominated==0, noobs

* Guardar ganador
local WIN_METHOD = method[1]
local WIN_SPEC   = spec[1]

di as result "==============================="
di as result "GANADOR (DISEÑO): `WIN_METHOD' / `WIN_SPEC'"
di as result "Balance: max|SMD|=" %6.4f maxsmd[1] " (en " var_maxsmd[1] ")  " ///
    "max|SMD|_core=" %6.4f maxcore[1] " (en " var_maxcore[1] ")  " ///
    "max|SMD|_no-core=" %6.4f maxother[1] " (en " var_maxother[1] ")  " ///
    "mean|SMD|=" %6.4f meansmd[1] "  L1=" %6.4f L1[1]
di as result "Soporte: ESS0=" %8.2f ess0[1] "  N1=" N1[1] "  N0=" N0[1]
di as result "==============================="


*========================
* 9) ANÁLISIS (outcome): estimar ATET y SE solo para el ganador
*========================
use `base', clear

if ("`WIN_METHOD'"=="Exact") {

    di as text "ANÁLISIS: Estimando ATET y ATE (solo para NO-CEM) para Exact / `WIN_SPEC' ..."

    * --- ATET ---
    quietly exact_atet, scheme(`WIN_SPEC')
    scalar ATET = r(atet)

    local REPS_FINAL = 700
    local SEED_FINAL = 20260

    * --- ATE (en soporte común) ---
    quietly exact_ate, scheme(`WIN_SPEC')
    scalar ATE = r(ate)

    * ====== Un solo bootstrap para (ATET, ATE) ======
    capture program drop exact_both_boot
    program define exact_both_boot, rclass
        syntax, SCHEME(string)

        quietly exact_atet, scheme(`scheme')
        return scalar atet = r(atet)

        quietly exact_ate, scheme(`scheme')
        return scalar ate  = r(ate)
    end

    bootstrap r(atet) r(ate), reps(`REPS_FINAL') seed(`SEED_FINAL'): ///
        exact_both_boot, scheme(`WIN_SPEC')

    matrix V = e(V)
    scalar SE_ATET = sqrt(V[1,1])
    scalar SE_ATE  = sqrt(V[2,2])
    * ===============================================

    di as result "RESULTADO FINAL (Exact / `WIN_SPEC'): " ///
        "ATET=" %9.4f ATET "  SE_boot(ATET)=" %9.4f SE_ATET ///
        "   |   ATE=" %9.4f ATE "  SE_boot(ATE)=" %9.4f SE_ATE
}

else if ("`WIN_METHOD'"=="CEM") {

    di as text "ANÁLISIS: Estimando ATET para CEM / `WIN_SPEC' (con cem_weights) ..."

    capture drop cem_matched cem_weights cem_strata

    local cemvars "$Xmatch"
    if ($ADD_SQ==1) local cemvars "`cemvars' $Xsq"

    cem `cemvars', tr($D) autocuts(`WIN_SPEC')

    reg $Y $D [aw=cem_weights] if cem_matched==1, vce(robust)
    scalar ATET = _b[$D]
    scalar SE_ATET = _se[$D]

    di as result "RESULTADO FINAL (CEM / `WIN_SPEC'): ATET=" %9.4f ATET "  SE_robust=" %9.4f SE_ATET

}
else {
    di as error "Método ganador no reconocido: `WIN_METHOD'"
    exit 498
}


*========================
* 10) (Opcional) Love plot de SMD para el ganador
*========================
if ($PLOT_WINNER==1) {

    di as text "Generando Love plot básico (SMD por covariable) para el ganador..."

    preserve
        * Volver a la base original (la tabla 'results' no tiene las covariables).
        use `base', clear

        tempfile smdout
        tempname ph2
        postfile `ph2' str20 var double smd using "`smdout'", replace

        if ("`WIN_METHOD'"=="Exact") {

            * Construir estratos exactamente como en DISEÑO (respeta USE_CORE y ADD_SQ)
            tempvar stratum N1cell N0cell matched w_att
            quietly make_stratum_exact, scheme(`WIN_SPEC') stratum(`stratum')

            bys `stratum': egen `N1cell' = total($D==1)
            bys `stratum': egen `N0cell' = total($D==0)
            gen byte `matched' = (`N1cell'>0 & `N0cell'>0)

            gen double `w_att' = 1
            replace `w_att' = `N1cell'/`N0cell' if $D==0 & `matched'==1

            foreach x of global Xeval {
                quietly _smd_one `x', wvar(`w_att') ifcond("`matched'==1")
                post `ph2' ("`x'") (r(smd))
            }
        }

        if ("`WIN_METHOD'"=="CEM") {
            capture drop cem_matched cem_weights cem_strata

            local cemvars "$Xmatch"
            if ($ADD_SQ==1) local cemvars "`cemvars' $Xsq"

            cem `cemvars', tr($D) autocuts(`WIN_SPEC')
            gen byte matched = (cem_matched==1)
            gen double w_att = cem_weights

            foreach x of global Xeval {
                quietly _smd_one `x', wvar(w_att) ifcond("matched==1")
                post `ph2' ("`x'") (r(smd))
            }
        }

        postclose `ph2'
        use "`smdout'", clear
        gen abs_smd = abs(smd)
        gsort -abs_smd

        gen ord = _n

        twoway ///
            (scatter abs_smd ord, mlabel(var) mlabsize(small)) ///
            , yline($SMD_THR) ///
              ytitle("|SMD|") ///
              xtitle("Covariables (ordenadas por |SMD|)") ///
              title("Love plot (ganador): |SMD| por covariable") ///
              legend(off)
    restore
}

* Mas adelante agregar esta métrica: Variance ratio (VR) para continuas (ideal cerca de 1; regla práctica 0.5–2)."
