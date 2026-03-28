/*------------------------------------------------------------------------------
Taller adicional (PSM) — Selector automático (versión definitiva)
Autor: Daniel + ChatGPT

IDEA CENTRAL (alineada con tu selector de matching exacto):
- Separar "DISEÑO" (matching/weighting + diagnóstico) de "ANÁLISIS" (efecto).
- En DISEÑO NO se usa Y para rankear: NO se calcula ATE/ATET para cada candidato.
- Elegimos entre candidatos usando:
    (i) Balance: max|SMD| y mean|SMD| (y ratios de varianza estilo Rubin),
    (ii) Soporte/precisión-proxy: share de tratados retenidos (N1/TOT1) y ESS de controles.
- Recién después, para el método ganador, estimamos ATE y ATET + SE por defecto y bootstrap.
- Opcional: gráficos SOLO para el ganador.

Requisitos:
- psmatch2 (SSC):   ssc install psmatch2
- (opcional) kmatch (SSC): ssc install kmatch
- Stata 13+ (usa strings largos y postfile)

Notas metodológicas (para orientar umbrales):
- Balance: reglas comunes usan max|SMD| <= 0.10 (estricto) o <= 0.25 (Rubin 2001 / Stuart 2010).
- Var ratios: Rubin sugiere rangos [0.5, 2] (equivale a max(max(VR,1/VR)) <= 2).
- Caliper “típico”: 0.2 * SD del logit(PS); acá implementamos calipers como múltiplos de SD de logit(PS)
  y usamos psmatch2, odds (distancia en log-odds) para que los calipers tengan esa interpretación.

------------------------------------------------------------------------------*/



version 16.0

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

version 16.0
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


global X   ///
    sexhead ///
    vaccess ///
    agehead ///
    educhead ///
    lnland ///
    pcirr 
*
* Si no definís Xbal, por defecto usamos X:
capture confirm global Xbal
if _rc {
    global Xbal "$X"
}

*========================================================
* 2) Tuning: grilla de candidatos + umbrales de selección
*========================================================
* Soporte: elegí UNA de estas, o probá ambas (se evalúan como candidatos separados).
* global SUPPORT_LIST "common"
* global SUPPORT_LIST "trim(10)"
global SUPPORT_LIST "common"

* Distancia: odds=match en log-odds(PS). Recomendado si querés caliper en SD del logit(PS).
global USE_ODDS 1

* Ties (psmatch2): teffects siempre usa ties; con psmatch2 es opción.
global USE_TIES 1

* Vecinos
global K_LIST "1 2 3 4 5"

* Caliper/Radius como múltiplos de SD(logit(PS))
* (valores “usuales”: 0.10–0.30; el “clásico” es 0.20)
global CAL_MULT "0.10 0.20 0.30 0.40"

* Kernel: tipos y banda (múltiplos de SD(logit(PS)))
global KERNEL_LIST "normal epan biweight uniform"
global H_MULT      "0.20 0.40 0.60 0.80 1.00"

* Umbrales de balance (ajustables)
global SMD_THR 0.10      // probá 0.10 para mas estricto, o 0.20 o 0.25 si te deja sin candidatos “pass”
global VR_THR  2         // implica VR en [0.5,2]

* Retención mínima de tratados (opcional)
global ENFORCE_TREAT_SHARE 1
global MIN_TREAT_SHARE     0.80

* (opcional) Rubin PS-diagnostics (B<25 y R en [0.5,2]) — por defecto NO se usa para pasar/fallar
global USE_RUBIN_PS 0
global RUBIN_B_THR  25
global RUBIN_R_THR  2

* Gráficos (solo ganador)
global DO_GRAPHS 1

* Bootstrap (solo ganador)
global BOOT_REPS 400
global BOOT_SEED 12345

*========================
* 3) Helpers
*========================

*--- 3.1 Util: ESS para controles con pesos (w) ---
capture program drop _ess_controls
program define _ess_controls, rclass
    syntax varname [if]
    quietly {
        tempname sw sw2
        tempvar w w2

        gen double `w' = `varlist' `if'
        replace `w' = 0 if missing(`w')
        summ `w' `if', meanonly
        scalar `sw' = r(sum)

        gen double `w2' = `w'^2 `if'
        summ `w2' `if', meanonly
        scalar `sw2' = r(sum)

        if (`sw2'==0) {
            return scalar ess0 = 0
        }
        else {
            return scalar ess0 = (`sw'^2)/`sw2'
        }
    }
end

*--- 3.2 Balance: max|SMD|, mean|SMD|, max var-ratio sym, mean |ln(VR)| + Rubin B/R del PS ---
capture program drop _eval_balance_psm
program define _eval_balance_psm, rclass
    * Requiere:
    *   - variable de tratamiento: $D (0/1)
    *   - variable w_att (peso usado para controles; para tratados = 1)
    *   - variable matched (1 si entra a comparación)
    *   - variable lps (logit(PS) con clamp)
    *
    syntax, WATT(varname) MATCHED(varname) LPS(varname)

    quietly {
        local xlist "$Xbal"
        tempname maxsmd meansmd maxvr meanlnvr Bps Rps
        scalar `maxsmd'  = 0
        scalar `meansmd' = 0
        scalar `maxvr'   = 1
        scalar `meanlnvr'= 0

        local vmaxsmd ""
        local vmaxvr  ""

        local count = 0

        foreach x of varlist `xlist' {
            * Tratados
            capture noisily summ `x' if `matched'==1 & $D==1
            if _rc continue
            local m1 = r(mean)
            local s1 = r(sd)

            * Controles (ponderados por matching)
            capture noisily summ `x' if `matched'==1 & $D==0 [aw=`watt']
            if _rc continue
            local m0 = r(mean)
            local s0 = r(sd)

            * pooled SD
            local sp = sqrt((`s1'^2 + `s0'^2)/2)
            if (`sp'<=0 | missing(`sp')) continue

            local smd = (`m1' - `m0')/`sp'
            local asmd = abs(`smd')

            scalar `meansmd' = `meansmd' + `asmd'
            local ++count

            if (`asmd' > `maxsmd') {
                scalar `maxsmd' = `asmd'
                local vmaxsmd "`x'"
            }

            * variance ratio (simetrizado)
            local vr = 1
            if (`s0'>0 & `s1'>=0) {
                local vr = (`s1'^2)/(`s0'^2)
                if (`vr'<=0 | missing(`vr')) local vr = 1
            }
            local vrsym = max(`vr', 1/`vr')
            scalar `meanlnvr' = `meanlnvr' + abs(ln(`vr'))

            if (`vrsym' > `maxvr') {
                scalar `maxvr' = `vrsym'
                local vmaxvr "`x'"
            }
        }

        if (`count'>0) {
            scalar `meansmd'  = `meansmd'/`count'
            scalar `meanlnvr' = `meanlnvr'/`count'
        }
        else {
            scalar `meansmd'  = .
            scalar `meanlnvr' = .
        }

        * Rubin's B y R (sobre el índice/linear predictor: lps = logit(PS))
        * B_ps en porcentaje de SD (como se reporta usualmente)
        capture noisily summ `lps' if `matched'==1 & $D==1
        local m1p = r(mean)
        local s1p = r(sd)
        capture noisily summ `lps' if `matched'==1 & $D==0 [aw=`watt']
        local m0p = r(mean)
        local s0p = r(sd)
        local spp = sqrt((`s1p'^2 + `s0p'^2)/2)
        if (`spp'>0 & !missing(`spp')) {
            scalar `Bps' = 100*abs(`m1p' - `m0p')/`spp'
        }
        else scalar `Bps' = .

        if (`s0p'>0 & `s1p'>=0) {
            local rp = (`s1p'^2)/(`s0p'^2)
            scalar `Rps' = max(`rp', 1/`rp')
        }
        else scalar `Rps' = .

        return scalar maxsmd   = `maxsmd'
        return scalar meansmd  = `meansmd'
        return scalar maxvr    = `maxvr'
        return scalar meanlnvr = `meanlnvr'
        return scalar B_ps     = `Bps'
        return scalar R_ps     = `Rps'
        return local var_maxsmd "`vmaxsmd'"
        return local var_maxvr  "`vmaxvr'"
    }
end

*--- 3.3 Ejecuta un candidato (DISEÑO): psmatch2 sin outcome, y devuelve métricas ---
capture program drop _eval_candidate
program define _eval_candidate, rclass
    syntax, METHOD(string) SUPPORT(string) OPTS(string) ///
           [K(integer 0) CAL(real 0) BW(real 0) KERNEL(string)]

    quietly {
        * limpiar residuos de psmatch2 de corridas previas
        capture drop _pscore _weight _id _n1 _n2 _n3 _n4 _n5 _nn _support

        * psmatch2 SIN outcome: solo para generar _weight y _support
        capture confirm variable ps_hat
        if _rc {
            return scalar ok = 0
            exit
        }

        capture noisily psmatch2 $D, pscore(ps_hat) `opts'
        if _rc {
            return scalar ok = 0
            exit
        }

        * si _support no existe, asumimos todo soporte
        capture confirm variable _support
        if _rc gen byte _support = 1

        * weights para balance: tratados peso 1; controles peso _weight
        tempvar w_att matched
        gen double `w_att' = 0
        replace `w_att' = 1       if $D==1 & _support==1
        replace `w_att' = _weight if $D==0 & _support==1
        replace `w_att' = 0 if missing(`w_att')

        gen byte `matched' = 0
        replace `matched' = 1 if $D==1 & _support==1
        replace `matched' = 1 if $D==0 & _support==1 & `w_att'>0

        * conteos
        count if `matched'==1 & $D==1
        local N1 = r(N)
        count if `matched'==1 & $D==0 & `w_att'>0
        local N0 = r(N)

        * ESS de controles
        _ess_controls `w_att' if `matched'==1 & $D==0
        local ess0 = r(ess0)

        * balance
        _eval_balance_psm, watt(`w_att') matched(`matched') lps(lps)
        local maxsmd   = r(maxsmd)
        local meansmd  = r(meansmd)
        local maxvr    = r(maxvr)
        local meanlnvr = r(meanlnvr)
        local B_ps     = r(B_ps)
        local R_ps     = r(R_ps)
        local vmsmd    = r(var_maxsmd)
        local vmvr     = r(var_maxvr)

        return scalar ok       = 1
        return scalar N1       = `N1'
        return scalar N0       = `N0'
        return scalar ess0     = `ess0'
        return scalar maxsmd   = `maxsmd'
        return scalar meansmd  = `meansmd'
        return scalar maxvr    = `maxvr'
        return scalar meanlnvr = `meanlnvr'
        return scalar B_ps     = `B_ps'
        return scalar R_ps     = `R_ps'
        return local  var_maxsmd "`vmsmd'"
        return local  var_maxvr  "`vmvr'"
    }
end

*========================
* 4) Preparación: definir muestra usable + estimar PS base (para SD del logit)
*========================
tempvar touse
gen byte `touse' = 1
foreach v of varlist $D $X {
    replace `touse' = 0 if missing(`v')
}

quietly count if `touse'==1 & $D==1
scalar TOT1 = r(N)
quietly count if `touse'==1 & $D==0
scalar TOT0 = r(N)

if (TOT1==0 | TOT0==0) {
    di as error "No hay observaciones suficientes en tratados o controles (en touse)."
    error 2000
}

* Estimación base del PS (logit) SOLO para construir lps y su SD
capture drop ps_hat ps_hat_c lps
quietly logit $D $X if `touse'==1
gen byte ps_sample = e(sample)
replace `touse' = (`touse'==1 & ps_sample==1)
quietly count if `touse'==1 & $D==1
scalar TOT1 = r(N)
quietly count if `touse'==1 & $D==0
scalar TOT0 = r(N)
if (TOT1==0 | TOT0==0) {
    di as error "No hay observaciones suficientes en tratados o controles en e(sample) del PS."
    error 2000
}
predict double lps if e(sample), xb
gen double ps_hat = invlogit(lps) if e(sample)
gen double ps_hat_c = min(max(ps_hat, 1e-6), 1-1e-6) if e(sample)
quietly summ lps if e(sample)
scalar SD_LPS = r(sd)

if (SD_LPS<=0 | missing(SD_LPS)) {
    quietly count if e(sample)
    di as error "SD_LPS no válida. Revisá la estimación del PS. N(e(sample))=" r(N)
    error 2000
}

*========================
* 5) DISEÑO: Evaluar candidatos y armar tabla de diagnóstico
*========================
tempfile base results
save `base', replace

tempname posth
postfile `posth' ///
    str8   method ///
    str60  support ///
    str160 spec ///
    str200 opts ///
    double k cal bw ///
    str12  kernel ///
    double maxsmd meansmd maxvr meanlnvr ///
    double B_ps R_ps ///
    str32  var_maxsmd ///
    str32  var_maxvr ///
    double N1 N0 ess0 share1 ///
    using `results', replace

*------------------------
* 5.1 Construir distancia y flags globales
*------------------------
local distopt ""
if ($USE_ODDS==1) local distopt "odds"

local tiesopt ""
if ($USE_TIES==1) local tiesopt "ties"

*------------------------
* 5.2 Loop por soporte
*------------------------
foreach supp in $SUPPORT_LIST {

    * 5.2.1 Nearest Neighbor: k=1..5 (sin caliper)
    foreach kk in $K_LIST {
        preserve
            use `base', clear
            keep if `touse'==1

            * psmatch2 usa la variable _pscore si estima PS internamente.
            * Acá forzamos usar nuestro PS (ps_hat) ya estimado, para mantener escala estable.
            local opts "`supp' `distopt' `tiesopt' neighbor(`kk')"

            quietly _eval_candidate, method("NN") support("`supp'") opts("`opts'") k(`kk')

            if (r(ok)==1) {
                local share1 = r(N1)/TOT1
                post `posth' ///
                    ("NN") ("`supp'") ///
                    ("k=`kk' + `supp'") ///
                    ("`opts'") ///
                    (`kk') (.) (.) ("") ///
                    (r(maxsmd)) (r(meansmd)) (r(maxvr)) (r(meanlnvr)) ///
                    (r(B_ps)) (r(R_ps)) ///
                    ("`r(var_maxsmd)'") ("`r(var_maxvr)'") ///
                    (r(N1)) (r(N0)) (r(ess0)) (`share1')
            }
        restore
    }

    * 5.2.2 NN + Caliper (k=1): calipers como múltiplos de SD_LPS
    foreach cm in $CAL_MULT {
        local cal = `cm'*SD_LPS
        preserve
            use `base', clear
            keep if `touse'==1
            local opts "`supp' `distopt' `tiesopt' neighbor(1) caliper(`cal')"
            quietly _eval_candidate, method("CAL") support("`supp'") opts("`opts'") k(1) cal(`cal')

            if (r(ok)==1) {
                local share1 = r(N1)/TOT1
                post `posth' ///
                    ("CAL") ("`supp'") ///
                    ("k=1 cal=`cm'*SD(LPS) + `supp'") ///
                    ("`opts'") ///
                    (1) (`cal') (.) ("") ///
                    (r(maxsmd)) (r(meansmd)) (r(maxvr)) (r(meanlnvr)) ///
                    (r(B_ps)) (r(R_ps)) ///
                    ("`r(var_maxsmd)'") ("`r(var_maxvr)'") ///
                    (r(N1)) (r(N0)) (r(ess0)) (`share1')
            }
        restore
    }

    * 5.2.3 Radius: calipers como múltiplos de SD_LPS
    foreach cm in $CAL_MULT {
        local cal = `cm'*SD_LPS
        preserve
            use `base', clear
            keep if `touse'==1
            local opts "`supp' `distopt' `tiesopt' radius caliper(`cal')"
            quietly _eval_candidate, method("RAD") support("`supp'") opts("`opts'") cal(`cal')

            if (r(ok)==1) {
                local share1 = r(N1)/TOT1
                post `posth' ///
                    ("RAD") ("`supp'") ///
                    ("radius cal=`cm'*SD(LPS) + `supp'") ///
                    ("`opts'") ///
                    (.) (`cal') (.) ("") ///
                    (r(maxsmd)) (r(meansmd)) (r(maxvr)) (r(meanlnvr)) ///
                    (r(B_ps)) (r(R_ps)) ///
                    ("`r(var_maxsmd)'") ("`r(var_maxvr)'") ///
                    (r(N1)) (r(N0)) (r(ess0)) (`share1')
            }
        restore
    }

    * 5.2.4 Kernel: tipos x bandas
    foreach kt in $KERNEL_LIST {
        foreach hm in $H_MULT {
            local bw = `hm'*SD_LPS
            preserve
                use `base', clear
                keep if `touse'==1
                local opts "`supp' `distopt' `tiesopt' kernel kerneltype(`kt') bwidth(`bw')"
                quietly _eval_candidate, method("KER") support("`supp'") opts("`opts'") bw(`bw') kernel("`kt'")

                if (r(ok)==1) {
                    local share1 = r(N1)/TOT1
                    post `posth' ///
                        ("KER") ("`supp'") ///
                        ("kernel=`kt' bw=`hm'*SD(LPS) + `supp'") ///
                        ("`opts'") ///
                        (.) (.) (`bw') ("`kt'") ///
                        (r(maxsmd)) (r(meansmd)) (r(maxvr)) (r(meanlnvr)) ///
                        (r(B_ps)) (r(R_ps)) ///
                        ("`r(var_maxsmd)'") ("`r(var_maxvr)'") ///
                        (r(N1)) (r(N0)) (r(ess0)) (`share1')
                }
            restore
        }
    }
}

postclose `posth'

use `results', clear
order method support spec opts k cal bw kernel maxsmd meansmd maxvr meanlnvr B_ps R_ps var_maxsmd var_maxvr N1 N0 ess0 share1
sort maxsmd

*========================
* 6) Selección del ganador (DISEÑO)
*========================

gen byte pass = (maxsmd <= $SMD_THR) & (maxvr <= $VR_THR)

if ($ENFORCE_TREAT_SHARE==1) {
    replace pass = pass & (share1 >= $MIN_TREAT_SHARE)
}

if ($USE_RUBIN_PS==1) {
    replace pass = pass & (B_ps <= $RUBIN_B_THR) & (R_ps <= $RUBIN_R_THR)
}

quietly count if pass==1
local n_pass = r(N)

if (`n_pass'>0) {
    * Entre los que pasan: priorizar retención + ESS (varianza) y luego balance (sesgo)
    gsort -pass -share1 -ess0 maxsmd meansmd maxvr meanlnvr
}
else {
    * Si nadie pasa: mejor balance primero, y después retención/ESS
    gsort maxsmd maxvr meanlnvr -share1 -ess0 meansmd
}

di as text "------------------------------------------------------------"
di as text "TOP 15/(N=33) candidatos (ordenados por regla de selección):"
local top = min(15, _N)
if (`top'>0) {
    list method support spec maxsmd meansmd maxvr B_ps R_ps N1 N0 ess0 share1 var_maxsmd var_maxvr in 1/`top', noobs abbrev(24)
}
else {
    di as error "No se pudo evaluar ningún candidato (lista vacía). Revisá errores previos (psmatch2)."
}

* Guardar ganador
local WIN_method  = method[1]
local WIN_support = support[1]
local WIN_spec    = spec[1]
local WIN_opts    = opts[1]
local WIN_k       = k[1]
local WIN_cal     = cal[1]
local WIN_bw      = bw[1]
local WIN_kernel  = kernel[1]

di as result "------------------------------------------------------------"
di as result "GANADOR (DISEÑO): `WIN_method' | `WIN_spec'"
di as text   "Opciones: `WIN_opts'"

*========================
* 7) ANÁLISIS: estimar ATE y ATET SOLO para el ganador (+ SE default + bootstrap)
*========================
use `base', clear
keep if `touse'==1

* Re-generar ps_hat / lps en la muestra final (consistencia)
capture drop ps_hat ps_hat_c lps
quietly logit $D $X
predict double lps if e(sample), xb
gen double ps_hat = invlogit(lps) if e(sample)
gen double ps_hat_c = min(max(ps_hat, 1e-6), 1-1e-6) if e(sample)
*------------------------
* 7.1 Funciones bootstrap
*------------------------

* --- 7.1a Bootstrap para psmatch2 (kernel/radius): devuelve tau ---
capture program drop _boot_psmatch2
program define _boot_psmatch2, rclass
    syntax, STAT(string) OPTS(string)

    quietly {
        * re-estimar PS en cada remuestreo
        capture drop ps_hat ps_hat_c
        capture noisily logit $D $X
        if _rc {
            return scalar tau = .
            exit
        }
        predict double ps_hat if e(sample), pr
        gen double ps_hat_c = min(max(ps_hat, 1e-6), 1-1e-6)

        local st = lower("`stat'")
        if ("`st'"=="atet") {
            capture noisily psmatch2 $D, out($Y) pscore(ps_hat) `opts'
            if _rc {
                return scalar tau = .
                exit
            }
            return scalar tau = r(att)
        }
        else if ("`st'"=="ate") {
            capture noisily psmatch2 $D, out($Y) pscore(ps_hat) `opts' ate
            if _rc {
                return scalar tau = .
                exit
            }
            return scalar tau = r(ate)
        }
        else {
            return scalar tau = .
        }
    }
end

* --- 7.1b Bootstrap para teffects psmatch (NN/CAL): devuelve tau (1 coef) ---
capture program drop _boot_teffects_ps
program define _boot_teffects_ps, rclass
    syntax, STAT(string) [K(integer 1) CAL(real 0)]

    quietly {
        local st = lower("`stat'")
        local statopt ""
        if ("`st'"=="atet") local statopt "atet"
        if ("`st'"=="ate")  local statopt "ate"

        local calopt ""
        if (`cal'>0) local calopt "caliper(`cal')"

        * osample() evita que el comando falle por falta de matches dentro del caliper
        capture noisily teffects psmatch ($Y) ($D $X), `statopt' tmodel(logit) nneighbor(`k') `calopt' osample(_os)
        if _rc {
            return scalar tau = .
            exit
        }
        matrix b = e(b)
        return scalar tau = b[1,1]
    }
end

*------------------------
* 7.2 Estimación final (winner)
*------------------------

tempname ATE ATET SE_ATE_def SE_ATET_def SE_ATE_boot SE_ATET_boot
scalar `ATE' = .
scalar `ATET' = .
scalar `SE_ATE_def' = .
scalar `SE_ATET_def' = .
scalar `SE_ATE_boot' = .
scalar `SE_ATET_boot' = .

* 7.2a Si ganador es NN o CAL: usar teffects psmatch como estimador final (SE Abadie–Imbens)
if inlist("`WIN_method'","NN","CAL") {

    local calopt ""
    if ("`WIN_method'"=="CAL" & `WIN_cal'<.) local calopt "caliper(`WIN_cal')"


    * ATE (default)
    capture noisily teffects psmatch ($Y) ($D $X), ate tmodel(logit) nneighbor(`WIN_k') `calopt' osample(_os_ate)
    if _rc==0 {
        matrix b = e(b)
        matrix V = e(V)
        scalar `ATE' = b[1,1]
        scalar `SE_ATE_def' = sqrt(V[1,1])
    }

    * ATET (default)
    capture noisily teffects psmatch ($Y) ($D $X), atet tmodel(logit) nneighbor(`WIN_k') `calopt' osample(_os_atet)
    if _rc==0 {
        matrix b = e(b)
        matrix V = e(V)
        scalar `ATET' = b[1,1]
        scalar `SE_ATET_def' = sqrt(V[1,1])
    }

    * Bootstrap ATE
    set seed $BOOT_SEED
    quietly bootstrap tau=r(tau), reps($BOOT_REPS) reject(missing(r(tau))): ///
        _boot_teffects_ps, stat(ate) k(`WIN_k') cal(`WIN_cal')
    scalar `SE_ATE_boot' = _se[tau]

    * Bootstrap ATET
    set seed $BOOT_SEED
    quietly bootstrap tau=r(tau), reps($BOOT_REPS) reject(missing(r(tau))): ///
        _boot_teffects_ps, stat(atet) k(`WIN_k') cal(`WIN_cal')
    scalar `SE_ATET_boot' = _se[tau]
}

* 7.2b Si ganador es RAD o KER: usar psmatch2 (default SE “naive” + bootstrap)
if inlist("`WIN_method'","RAD","KER") {

    * ATET (psmatch2)
    capture noisily psmatch2 $D, out($Y) pscore(ps_hat) `WIN_opts'
    if _rc==0 {
                scalar `ATET' = r(att)

        * SE default reportado por psmatch2 (naive: NO ajusta por estimación del PS)
        capture scalar `SE_ATET_def' = r(seatt)

        * Si por alguna razón no vino (muy raro), fallback: SE naive por var(Y1)/N1 + var_w(Y0)/ESS0
        if (missing(`SE_ATET_def')) {
        tempvar w_att matched
        capture confirm variable _support
        if _rc gen byte _support = 1
        gen double `w_att' = 0
        replace `w_att' = 1       if $D==1 & _support==1
        replace `w_att' = _weight if $D==0 & _support==1
        replace `w_att' = 0 if missing(`w_att')

        gen byte `matched' = 0
        replace `matched' = 1 if $D==1 & _support==1
        replace `matched' = 1 if $D==0 & _support==1 & `w_att'>0

        quietly count if `matched'==1 & $D==1
        local N1 = r(N)

        quietly summ $Y if `matched'==1 & $D==1
        local s1 = r(sd)

        quietly summ $Y if `matched'==1 & $D==0 [aw=`w_att']
        local s0 = r(sd)

        _ess_controls `w_att' if `matched'==1 & $D==0
        local ess0 = r(ess0)

        if (`N1'>0 & `ess0'>0) scalar `SE_ATET_def' = sqrt((`s1'^2)/`N1' + (`s0'^2)/`ess0')
        }
    }

    * ATE (psmatch2)
    capture noisily psmatch2 $D, out($Y) pscore(ps_hat) `WIN_opts' ate
    if _rc==0 {
        scalar `ATE' = r(ate)
        capture scalar `SE_ATE_def' = r(seate)
        * Nota: psmatch2 suele NO reportar SE para ATE (queda missing).
    }

    * Bootstrap ATET
    set seed $BOOT_SEED
    quietly bootstrap tau=r(tau), reps($BOOT_REPS) reject(missing(r(tau))): ///
        _boot_psmatch2, stat(atet) opts("`WIN_opts'")
    scalar `SE_ATET_boot' = _se[tau]

    * Bootstrap ATE
    set seed $BOOT_SEED
    quietly bootstrap tau=r(tau), reps($BOOT_REPS) reject(missing(r(tau))): ///
        _boot_psmatch2, stat(ate) opts("`WIN_opts'")
    scalar `SE_ATE_boot' = _se[tau]
}

di as text "------------------------------------------------------------"
di as text "RESULTADO FINAL (ganador):"
di as result "Metodo: `WIN_method' | `WIN_spec'"
di as text   "ATE  = " %9.4f `ATE'  " | SE_def = " %9.4f `SE_ATE_def'  " | SE_boot = " %9.4f `SE_ATE_boot'
di as text   "ATET = " %9.4f `ATET' " | SE_def = " %9.4f `SE_ATET_def' " | SE_boot = " %9.4f `SE_ATET_boot'
di as text "------------------------------------------------------------"

*========================
* 8) Gráficos (solo ganador, opcional)
*========================
if ($DO_GRAPHS==1) {
    * PS overlap (en logit scale)
    twoway (kdensity lps if $D==1, lpattern(solid)) ///
           (kdensity lps if $D==0, lpattern(dash)), ///
           legend(order(1 "Tratados" 2 "Controles")) ///
           title("Overlap: logit(PS)") name(overlap_ps, replace)

    * Love plot (pstest) — requiere psmatch2 y haber corrido psmatch2 para crear _weight
    capture noisily psmatch2 $D, pscore(ps_hat) `WIN_opts' 
    capture noisily pstest $Xbal, both graph name(loveplot, replace)
}

* Fin


/*------------------------------------------------------------------------------
INTERPRETACIÓN DE LA TABLA DE DIAGNÓSTICO Y DEL RESULTADO FINAL (PSM selector)
-------------------------------------------------------------------------------

(1) ¿Qué es la tabla "TOP candidatos" y cómo se lee?
La tabla lista (en orden de prioridad) las especificaciones candidatas de PSM que
se evaluaron en la etapa de DISEÑO. Cada fila es un "candidato" (NN, Caliper,
Radius o Kernel) combinado con una regla de soporte (acá: common) y opciones
específicas (k, caliper, kerneltype, bandwidth, etc.).

Importante: en esta tabla NO estamos "eligiendo por outcome". La selección se
basa en calidad del emparejamiento/ponderación (balance y precisión-proxy), no
en el tamaño del efecto.

Columnas clave:

- method / spec:
    method indica la familia (NN, CAL, RAD, KER) y spec resume la configuración.
    Ejemplo ganador: "KER | kernel=biweight bw=0.40*SD(LPS) + common".

- maxsmd y meansmd:
    Balance de covariables (Standardized Mean Differences en valor absoluto).
    maxsmd = el peor desbalance entre todas las covariables evaluadas (la "más
    problemática"). meansmd = promedio del desbalance.

    Regla típica: max|SMD| <= 0.10 se considera balance "estricto/bueno".
    En este run, el candidato ganador tiene maxsmd ≈ 0.081, o sea cumple holgado.

- maxvr (y meanlnvr):
    Diagnóstico de ratios de varianza (Rubin style). maxvr reporta el peor ratio
    simetrizado (max(VR, 1/VR)) entre covariables; por ejemplo maxvr=1.32 implica
    que la peor relación de varianzas está a ~32% de 1.
    Umbral usual: VR dentro de [0.5, 2] (equivalente a maxvr <= 2).

- B_ps y R_ps:
    Diagnósticos de Rubin para el "índice" del PS (acá: lps = logit(PS)).
    B_ps mide la diferencia de medias del logit(PS) en % de la SD pooled.
    R_ps es el ratio de varianzas del logit(PS) (simetrizado).
    Umbrales clásicos: B<25 y R dentro de [0.5,2]. En este run, el ganador cumple
    (B≈10.8, R≈1.10), por lo que hay buen overlap en el PS.

- N1, N0, share1, ess0:
    Soporte y precisión-proxy.
    N1 = tratados retenidos (en soporte); share1 = N1 / TOT1 (proporción retenida).
    ess0 = Effective Sample Size de controles tras ponderar por weights de matching.
    A igualdad de balance, más share1 y más ess0 suele implicar menor varianza.

(2) ¿Quién ganó y por qué?
El algoritmo aplica primero umbrales mínimos (pass):
- maxsmd <= $SMD_THR (0.10)
- maxvr  <= $VR_THR  (2)
- share1 >= $MIN_TREAT_SHARE (0.80)  [porque ENFORCE_TREAT_SHARE=1]
(y opcionalmente Rubin B/R si USE_RUBIN_PS=1; acá está en 0).

Como hubo candidatos que "pasan", se prioriza:
(1) retención de tratados (share1 alto),
(2) ESS de controles (ess0 alto),
(3) balance (maxsmd, luego meansmd, etc.).

Con esos criterios, el ganador fue:
GANADOR (DISEÑO): KER | kernel=biweight bw=0.40*SD(LPS) + common
Opciones: common odds ties kernel kerneltype(biweight) bwidth(0.2357609)

Interpretación:
- Se usó soporte común (common support).
- Se ponderaron controles con kernel biweight usando bandwidth = 0.40 * SD(logit(PS)).
- El balance es bueno (maxsmd ~ 0.081) y además retiene prácticamente todos los
  tratados (share1 ~ 0.998) con ESS alto en controles (~451), lo cual es una buena
  combinación sesgo-varianza.

Nota práctica:
Vas a ver que algunos NN (por ejemplo k=5) tienen maxsmd extremadamente bajo.
Pero sacrifican ess0 frente a kernel/radius. El selector está deliberadamente
diseñado para que, entre métodos que ya "balancean bien", el desempate favorezca
precisión (share1/ess0) para no pagar varianza innecesaria.

(3) Resultado final (ANÁLISIS) usando SOLO el ganador
Una vez elegido el método por DISEÑO, recién ahí se estima el efecto (ANÁLISIS):

Método final: Kernel biweight (bw=0.40*SD(LPS)) con common support.

Efectos estimados:
- ATET = 0.1099
- ATE  = 0.0773

Errores estándar:
- Para ATET, psmatch2 reporta SE "naive" (no ajusta por estimación del PS), y además
  se computa SE por bootstrap:
    ATET SE_def  = 0.0324   (naive)
    ATET SE_boot = 0.0272   (bootstrap)

- Para ATE, psmatch2 típicamente NO reporta SE (queda missing), por eso el informe
  relevante es el bootstrap:
    ATE  SE_def  = .        (no disponible en psmatch2)
    ATE  SE_boot = 0.0271

Lectura sustantiva (en este ejemplo):
Con el método seleccionado, el efecto sobre el outcome (lexptot) es positivo,
y el ATET es mayor que el ATE. En términos de precisión, el bootstrap sugiere
errores estándar del orden de 0.027, y el ATET está claramente distinto de cero.

(4) ¿Qué haría como "siguiente paso" si esto fuera un trabajo aplicado?
Si este fuera el pipeline real de un paper, yo usaría el ganador como "estimador
principal", pero haría cuatro cosas adicionales, en este orden:

A. Fijar el DISEÑO como pre-regla
Dejar documentado (y sin tocar) el conjunto de covariables $X, la regla de soporte,
y el algoritmo de selección (umbrales + desempate). La idea es que el método no
se elija mirando Y. El selector ya hace esto, así que el paso es: "congelarlo".

B. Reporte de balance del ganador (en el paper)
- Tabla de SMD antes/después (o al menos max|SMD| y mean|SMD|) y variable "peor".
- Gráfico de overlap del PS (en logit scale) y un love plot (pstest, both graph).
En tu corrida ya se ve que el balance mejora mucho (MeanBias baja fuerte) y B/R
pasan a valores aceptables.

C. Inferencia principal (no depender del SE naive)
Para kernel/radius, usaría como principal el SE bootstrap (idealmente con 1,000+
reps en el paper, y semilla fija). En aplicaciones más serias: bootstrap cluster
si corresponde (por ejemplo, clusters por localidad, empresa, escuela, etc.).

D. Robustez mínima "razonable"
Sin hacer un festival de especificaciones, sino cosas estándar:
- Repetir el análisis con 1–2 candidatos cercanos del top (por ejemplo RAD cal=0.20,
  o KER uniform bw=0.20) para ver estabilidad del signo/magnitud.
- Comparar con IPW (teffects ipw / aipw) como chequeo.
- Sensibilidad a ocultos (Rosenbaum bounds) si aplica y si te interesa argumento.

En resumen: el ganador es un Kernel biweight con bandwidth intermedio y soporte
común; equilibra bien el trade-off sesgo-varianza (balance bueno, altísima retención
de tratados, ESS alto). El resultado final a reportar debería ser el efecto con
SE bootstrap (porque el SE "naive" de psmatch2 no ajusta por estimación del PS).
------------------------------------------------------------------------------*/

