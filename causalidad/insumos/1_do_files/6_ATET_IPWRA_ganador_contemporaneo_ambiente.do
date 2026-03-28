/*------------------------------------------------------------------------------
ATET_IPWRA_ganador_IGNORE_S1_directo.do
Autor: Daniel + ChatGPT
Fecha: 2026-02-22

OBJETIVO
- Correr DIRECTAMENTE el ganador: MODO = IGNORE_ORG y SPEC = S1.
- Sin selector, sin loops de specs, sin programas.
- Respetar el diseño: misma muestra + mismas reglas de soporte/overlap y tratamiento de pesos.
- Estimar ATET con teffects ipwra (multivaluado: 1vs0, 2vs0, 3vs0), y luego graficar:
  (i) overlap (densidades de p_t), (ii) soporte (osample), (iii) histogramas de pesos,
  (iv) loveplot (|SMD| raw vs weighted).

NOTA CLAVE (CAP vs DROP)
- Si tu diseño usa DROP (recorte de muestra por pesos extremos), eso SÍ se replica en teffects ipwra
  porque es un recorte de la muestra ANTES de estimar.
- Si tu diseño usa CAP (winsorizar pesos), NO se puede imponer dentro de teffects ipwra:
  teffects usa pesos internos (derivados del mlogit) sin “capear”.
  En ese caso, CAP solo se usa para DIAGNÓSTICOS/GRÁFICOS (para ver qué pasa si capearas).
------------------------------------------------------------------------------*/

version 19.0
clear all
set more off

*==============================================================================
* 0) RUTAS (editá estas 2 líneas y listo)
*==============================================================================
clear all
set more off

*-------------------------------
* 0) Rutas (tu esquema)
*-------------------------------
global seteo "C:\Users\Equipo\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"
local username = c(username)
if "`username'" == "Equipo" {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"
}
else if "`username'" == "dmendez" {
    global seteo "C:\Users\dmendez\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"
}
else {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"
}

use "$seteo\3. Estrategia empirica\3. Modelos\panel_innovacion_ipi_8.dta", clear




* crear carpetas (mkdir NO crea carpetas intermedias)
cap mkdir "$seteo\3. Estrategia empirica\3. Modelos\5Resultado-innovacion - estrategia causal\Medio Ambiente\output\winner_only\contemporaneo"
local outdir "$seteo\3. Estrategia empirica\3. Modelos\5Resultado-innovacion - estrategia causal\Medio Ambiente\output\winner_only\contemporaneo"
cap mkdir "`outdir'"


* Opcional: log
cap log close _all
log using "`outdir'\ATET_IGNORE_S1.log", replace


* chequeo explícito (didáctico): si falla, cortamos acá con un mensaje claro
if _rc {
    di as error "No pude crear la carpeta de salida: `outdir'"
    exit 603
}

* Opcional: log
cap log close _all
log using "`outdir'\ATET_IGNORE_S1.log", replace

*==============================================================================
* 1) CARGA + ESTRUCTURA DE PANEL (igual que tu pipeline)
*==============================================================================

* Si tu base no es panel o no tiene delta(3), podés comentar xtset.
isid correlativo anio
xtset correlativo anio, delta(3)

*==============================================================================
* 2) MUESTRA CENTRAL + OUTCOME (entre innovadores con outcome observado)
*    (igual que tu lógica: NO definimos Y para no innovadores)
*==============================================================================
keep if b1_9==1

cap drop Y_cond
gen byte Y_cond = inlist(resul_mejora_ambiente,1,2) if !missing(resul_mejora_ambiente)
drop if missing(Y_cond)

label var Y_cond "Y (cond): mejora amb media/alta entre innovadores"

*==============================================================================
* 3) TRATAMIENTO GANADOR: IGNORE_ORG (estado prod/proc)
*==============================================================================
cap drop D_pp_ignore
gen byte D_pp_ignore = .
replace D_pp_ignore = 0 if innova_producto==0 & innova_proceso==0
replace D_pp_ignore = 1 if innova_producto==1 & innova_proceso==0
replace D_pp_ignore = 2 if innova_producto==0 & innova_proceso==1
replace D_pp_ignore = 3 if innova_producto==1 & innova_proceso==1

label define Dpp 0 "No prod/proc" 1 "Solo producto" 2 "Solo proceso" 3 "Ambas", replace
label values D_pp_ignore Dpp
label var D_pp_ignore "D: prod/proc/ambas (IGNORE_ORG)"

keep if inlist(D_pp_ignore,0,1,2,3)

*==============================================================================
* 4) ORG CONTROLS (los usabas en IGNORE_ORG) + transformaciones usadas en diseño
*==============================================================================
cap drop org1 org_miss
gen byte org1 = (innova_organiz_comerc==1) if !missing(innova_organiz_comerc)
replace org1 = 0 if missing(org1)
gen byte org_miss = missing(innova_organiz_comerc)

label var org1     "Org/comerc=1 (missing->0)"
label var org_miss "Org/comerc missing"

* Cuadráticos e interacciones (se crean explícitos; inclusión depende de la ecuación)
capture confirm numeric variable ln_tpo_mean
if !_rc {
    cap drop ln_tpo_sq
    gen double ln_tpo_sq = ln_tpo_mean^2
}
capture confirm numeric variable edad
if !_rc {
    cap drop edad_sq
    gen double edad_sq = edad^2
}

capture confirm numeric variable indice_redes
if !_rc {
    capture confirm numeric variable exp_dummy
    if !_rc {
        cap drop redesXexp
        gen double redesXexp = indice_redes*exp_dummy
    }
    capture confirm numeric variable ln_tpo_mean
    if !_rc {
        cap drop redesXsize
        gen double redesXsize = indice_redes*ln_tpo_mean
    }
}


* --- Dummies por ola (anio) ---
global FE_WAVE_VARS ""
capture confirm numeric variable anio
if !_rc {
    capture drop wave_*
    quietly tab anio, gen(wave_)
    quietly ds wave_*, has(type numeric)
    global FE_WAVE_VARS `r(varlist)'
}



* --- Dummies macro-sector (macro_sector) ---
gen byte macro_sector = 3   // 1=Manufacturing, 2=Services, 3=Other/missing

* TU definición:
replace macro_sector = 1 if inlist(industry_id, 6)
replace macro_sector = 2 if inlist(industry_id, 2,3,4,5,7,8,11)
replace macro_sector = 3 if missing(industry_id) | inlist(industry_id, 1,9,10)

label define macro_sector 1 "Manufacturing" 2 "Services" 3 "Other/missing", replace
label values macro_sector macro_sector

drop if macro_sector==3

tab anio macro_sector if b1_9==1

capture confirm numeric variable macro_sector
if _rc {
    di as error "Falta macro_sector en tu base. Crealo como en tu pipeline, o ajustá la FE."
    exit 459
}

*==============================================================================
* 5) COVARIABLES DEL GANADOR (IGNORE + S1)
*    Tratamiento (mlogit) = BASEVARS_CORE + interacciones + FE sector 
*    Outcome (logit)      = BASEVARS_CORE + cuadrados + interacciones + FE sector + org controls
*
* NOTA: Para alinear muestra con teffects, dropeamos missings de la UNIÓN de variables
*       de ambas ecuaciones (tratamiento y outcome).
*==============================================================================
drop if missing(edad, capital_extranjero, share_prof_tecn, exp_dummy, ln_tpo_mean, indice_redes, ///
               redesXexp, redesXsize, org1, org_miss, macro_sector, ln_tpo_sq, edad_sq)

*==============================================================================
* 6) PARÁMETROS DE DISEÑO (mismos defaults del do-file original)
*==============================================================================
scalar P0_FLOOR        = 1e-8
scalar P0_TREAT_FLOOR  = 1e-8
scalar W_CEIL          = 1e6
scalar PS_TRIM_ON      = 1        // 1=on, 0=off
scalar PS0_LOW         = 0.05
scalar PS0_HIGH        = 0.95
local  W_TRIM_STYLE    "OFF"      // "CAP" o "DROP" o "OFF"
scalar W_CAP_Q         = .      // cuantil para CAP/DROP (solo controles) o poner CAP "." para desactivar




*==============================================================================
* 7) (A) RECORTE DE MUESTRA ALINEADO AL DISEÑO + ESTIMACIÓN IPWRA
*==============================================================================
quietly mlogit D_pp_ignore ///
    edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
    redesXexp redesXsize ///
    i.macro_sector, ///
    baseoutcome(0) nolog

cap drop p0 p1 p2 p3
predict double p0, outcome(0)
predict double p1, outcome(1)
predict double p2, outcome(2)
predict double p3, outcome(3)

tempvar use_final w1 w2 w3
gen byte `use_final' = 1

* (i) floors sobre p0 (control y tratados)
replace `use_final' = 0 if missing(p0)
replace `use_final' = 0 if (D_pp_ignore==0  & p0<=P0_FLOOR)
replace `use_final' = 0 if (inlist(D_pp_ignore,1,2,3) & p0<=P0_TREAT_FLOOR)

* (ii) PS trimming sobre p0 (si está activo)
if (PS_TRIM_ON==1) {
    replace `use_final' = 0 if (p0<PS0_LOW | p0>PS0_HIGH)
}

* (iii) wceil sobre controles, exigiendo pesos razonables para CADA t (1..3)
gen double `w1' = .
gen double `w2' = .
gen double `w3' = .
replace `w1' = (p1/p0) if D_pp_ignore==0 & `use_final'==1
replace `w2' = (p2/p0) if D_pp_ignore==0 & `use_final'==1
replace `w3' = (p3/p0) if D_pp_ignore==0 & `use_final'==1

replace `use_final' = 0 if D_pp_ignore==0 & `use_final'==1 & (missing(`w1') | `w1'<=0 | `w1'>W_CEIL)
replace `use_final' = 0 if D_pp_ignore==0 & `use_final'==1 & (missing(`w2') | `w2'<=0 | `w2'>W_CEIL)
replace `use_final' = 0 if D_pp_ignore==0 & `use_final'==1 & (missing(`w3') | `w3'<=0 | `w3'>W_CEIL)

* (iv) trimming por cuantil (solo si W_TRIM_STYLE=="DROP") -> replicable en teffects
if (upper("`W_TRIM_STYLE'")=="DROP") {

    local pct = 100*W_CAP_Q

    * calculamos wcap_t en controles (sobre la muestra ya "usable")
    quietly count if D_pp_ignore==0 & `use_final'==1
    if (r(N)>0) {

        quietly centile `w1' if D_pp_ignore==0 & `use_final'==1, centile(`pct')
        local wcap1 = r(c_1)
        quietly centile `w2' if D_pp_ignore==0 & `use_final'==1, centile(`pct')
        local wcap2 = r(c_1)
        quietly centile `w3' if D_pp_ignore==0 & `use_final'==1, centile(`pct')
        local wcap3 = r(c_1)

        if (`wcap1'<. & `wcap1'>0) replace `use_final' = 0 if D_pp_ignore==0 & `use_final'==1 & `w1' > `wcap1'
        if (`wcap2'<. & `wcap2'>0) replace `use_final' = 0 if D_pp_ignore==0 & `use_final'==1 & `w2' > `wcap2'
        if (`wcap3'<. & `wcap3'>0) replace `use_final' = 0 if D_pp_ignore==0 & `use_final'==1 & `w3' > `wcap3'
    }
}

keep if `use_final'==1
drop `use_final' `w1' `w2' `w3'

* ---- Estimación IPWRA (ganador IGNORE+S1): ATET "diagonales" ----
*   Para tratamiento multivaluado, queremos:
*     ATET_1 = E[Y(1)-Y(0) | D=1], ATET_2 = E[Y(2)-Y(0) | D=2], ATET_3 = E[Y(3)-Y(0) | D=3]
*   Para forzar eso sin ambigüedades, corremos 3 veces con tlevel(t) y extraemos SOLO el contraste t vs 0.

tempname __b __V
capture drop os_t1 os_t2 os_t3

forvalues t = 1/3 {

    local __osname = "os_t`t'"

    teffects ipwra ///
        (Y_cond ///
            edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
            ln_tpo_sq edad_sq redesXexp redesXsize ///
            org1 org_miss ///
            i.macro_sector, ///
            logit) ///
        (D_pp_ignore ///
            edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
            redesXexp redesXsize ///
            i.macro_sector, ///
            mlogit), ///
        atet control(0) tlevel(`t') vce(cluster correlativo) osample(`__osname') pstolerance(`=P0_FLOOR')

    estimates store ATET_IGNORE_S1_t`t'
	tebalance summarize
    matrix `__b' = e(b)
    matrix `__V' = e(V)

    local __cn : colfullnames `__b'
    local __target ""

    * Stata suele nombrar el contraste como ATET:r#vs0 (multi) o ATET:#vs0 (algunas salidas)
    foreach __nm of local __cn {
        if (strpos("`__nm'","ATET:r`t'vs0")>0) local __target "`__nm'"
    }
    if ("`__target'"=="") {
        foreach __nm of local __cn {
            if (strpos("`__nm'","ATET:`t'vs0")>0) local __target "`__nm'"
        }
    }
    if ("`__target'"=="") {
        di as error "No encontre el ATET relevante (t=`t' vs 0) en e(b). Colnames: `__cn'"
        exit 459
    }

    scalar ATET`t' = el(`__b', 1, colnumb(`__b', "`__target'"))
    scalar SE`t'   = sqrt(el(`__V', colnumb(`__V', "`__target'"), colnumb(`__V', "`__target'")))

    local ATET_STR`t' : display %9.5f ATET`t'
    local SE_STR`t'   : display %9.5f SE`t'
}

* Mantener el "estimation set" principal como t=1, para no cambiar tu flujo aguas abajo.
*estimates restore ATET_IGNORE_S1_t1
*estimates store ATET_IGNORE_S1
*tebalance summarize

di as text "--------------------------------------------"
di as text "Soporte por tlevel (os_t#): 1 = fuera de soporte/overlap"
forvalues t=1/3 {
    di as text "t=`t' (os_t`t'):"
    tab os_t`t' if inlist(D_pp_ignore,0,`t'), missing
}
di as text "--------------------------------------------"

di as text "ATET relevantes (diagonales, control=0):"
di as text "  ATET_1 = E[Y(1)-Y(0) | D=1] = `ATET_STR1'   (SE=`SE_STR1')"
di as text "  ATET_2 = E[Y(2)-Y(0) | D=2] = `ATET_STR2'   (SE=`SE_STR2')"
di as text "  ATET_3 = E[Y(3)-Y(0) | D=3] = `ATET_STR3'   (SE=`SE_STR3')"



*=============================================================================
*  tablas resumen- estadisticas descriptivas
*============================================================================

* recordemos que tenemos activo ya los siguientes filtros:
* keep if b1_9==1  (solo firmas que hicieron actividades de innovacion)
* drop if macro_sector==3    (solo firmas de manufactura o de servicios)
* keep if `use_final'==1    (reglas de soporte sobre p0 aplicadas)

describe  Y_cond D_pp_ignore edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
			            ln_tpo_sq edad_sq redesXexp redesXsize ///
						macro_sector ///
				       org1 org_miss 
					   
mdesc Y_cond D_pp_ignore edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
			            ln_tpo_sq edad_sq redesXexp redesXsize ///
						macro_sector ///
					   org1 org_miss 
					   
summarize  Y_cond i.D_pp_ignore edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
			            ln_tpo_sq edad_sq redesXexp redesXsize ///
						i.macro_sector ///
				  org1 org_miss 
	
				  
*==============================================================================
* 8) DIAGNÓSTICOS CON PESOS (OVERLAP / HIST / LOVELOT)
*==============================================================================

/*------------------------------------------------------------------------------
NOTA SOBRE ALINEACIÓN DE DIAGNÓSTICOS (SMD/LOVE PLOT/OVERLAP) EN ESTA SECCIÓN 8

En esta sección construimos diagnósticos (overlap, histogramas de pesos y loveplot) usando
predicciones p0..pt y pesos "manuales" w_raw = p_t/p0 (para controles), junto con filtros
de soporte/overlap (pisos sobre p0 + PS trimming).

   - NO se excluyen las observaciones que "teffects ipwra" marca como fuera de soporte.
   - En ese caso, los SMD/loveplot tienden a replicar mejor las métricas del do-file anterior del
     selector automático (etapa de diseño), porque ese pipeline de diseño calcula balance
     sobre la muestra recortada por reglas de diseño, pero no necesariamente sobre la
     "muestra efectiva" final usada por "teffects ipwra" (que puede excluir observaciones adicionales).
	 
	- en particular, en "teffects ipwra" se excluyen las observaciones con os_t#==1 para cada contraste t vs 0. 
    - Es decir, el comando "teffects ipwra" puede hacer modificaciones extras en terminos de MUESTRA EFECTIVA (soporte/overlap) utilizada para estimar el ATET.
    - por otro lado, cuando usamos "teffects ipwra" los pesos pueden NO coincidir exactamente con los del diseño manual impuesto por mi:
    - Aunque guardamos una muestra previa usando trimming sobre p0 + pisos, "teffects ipwra" vuelve a
     estimar internamente su modelo de tratamiento y construye SUS propios pesos IPW internos.
   - Por eso, los SMD calculados "a mano" con w_raw = p_t/p0 (a partir de nuestro mlogit) pueden diferir levemente de los SMD internos de teffects.

Regla segura si se quiere replicar EXACTAMENTE el balance reportado por "teffects ipwra":
   - Usar el comando "tebalance summarize" inmediatamente después de cada "teffects ipwra", 
     y basar los SMD/diagnósticos en esos resultados, ya que reflejan la misma muestra efectiva
	 y los mismos pesos internos que utiliza "teffects".

En resumen:
- sin teffects ipwra, y bajo nuestra muestra con nuestras reglas de diseño -> smd que replican las métricas del selector (diseño).
- con teffects ipwra y tebalance summarize, y bajo nuestra muestra con nuestra reglas de diseño -> smd que replican lo que hace internamente teffects ipwra
------------------------------------------------------------------------------*/

set scheme s2mono

*--------------------------------------------
* Construir pesos de controles para comparar t vs 0
*--------------------------------------------
forvalues t=1/3 {

    tempvar use_t w_raw w_cap w_norm w_plot w_plot_d w_raw_nf w_norm_nf w_plot_nf
    gen byte   `use_t' = inlist(D_pp_ignore,0,`t')

    gen double `w_raw' = .
    replace `w_raw' = (p`t'/p0) if D_pp_ignore==0 & `use_t'==1

    * Filtros de diagnóstico (overlap + PS trim + soporte)
    replace `use_t' = 0 if missing(p0)
    replace `use_t' = 0 if (D_pp_ignore==0   & p0<=P0_FLOOR)
    replace `use_t' = 0 if (D_pp_ignore==`t' & p0<=P0_TREAT_FLOOR)

    if (PS_TRIM_ON==1) {
        replace `use_t' = 0 if (`use_t'==1) & (p0<PS0_LOW | p0>PS0_HIGH)
    }

    * wceil (solo controles) + sanity checks
    replace `use_t' = 0 if D_pp_ignore==0 & (`w_raw'<=0 | `w_raw'>W_CEIL | missing(`w_raw'))

    *-----------------------------------------------------------
    * (0) Definir peso "de diseño" para gráficos: w_cap
    *     (igual a w_raw; y si hay CAP/DROP por cuantiles, aplicarlo acá)
    *-----------------------------------------------------------
    gen double `w_cap' = `w_raw'

    quietly count if D_pp_ignore==0 & `use_t'==1
    if (r(N)>0 & W_CAP_Q<.) {
        local pct = 100*W_CAP_Q
        quietly centile `w_cap' if D_pp_ignore==0 & `use_t'==1, centile(`pct')
        local wcap = r(c_1)

        if (`wcap'<. & `wcap'>0) {
            if (upper("`W_TRIM_STYLE'")=="CAP") {
                replace `w_cap' = `wcap' if D_pp_ignore==0 & `use_t'==1 & `w_cap' > `wcap'
            }
            else if (upper("`W_TRIM_STYLE'")=="DROP") {
                replace `use_t' = 0 if D_pp_ignore==0 & `use_t'==1 & `w_cap' > `wcap'
                replace `w_cap' = . if D_pp_ignore==0 & `use_t'==0
            }
        }
    }

    *-----------------------------------------------------------
    * (1) Normalizar pesos PARA GRÁFICOS: mean(w_cap|D=0,usados)=1
    *-----------------------------------------------------------
    quietly summarize `w_cap' if D_pp_ignore==0 & `use_t'==1, meanonly
    gen double `w_norm' = .
    if (r(N)>0 & r(mean)>0 & r(mean)<.) {
        replace `w_norm' = `w_cap'/r(mean) if D_pp_ignore==0 & `use_t'==1
    }
    else {
        * fallback seguro (evita dividir por missing)
        replace `w_norm' = `w_cap' if D_pp_ignore==0 & `use_t'==1
    }

    gen double `w_plot' = .
    replace `w_plot' = `w_norm' if D_pp_ignore==0 & `use_t'==1

    *--------------------------------------------
    * (A) OVERLAP SIN PESOS (densidades de p_t)
    *--------------------------------------------
    twoway ///
        (kdensity p`t' if D_pp_ignore==0   & `use_t'==1, lpattern(solid)) ///
        (kdensity p`t' if D_pp_ignore==`t' & `use_t'==1, lpattern(dash)), ///
        legend(order(1 "Controles (0)" 2 "Tratados (`t')")) ///
        title("Overlap: Pr(D=`t')") ///
        xtitle("Probabilidad predicha") ytitle("Densidad")
    graph export "`outdir'\overlap_manual_t`t'.png", replace

    *--------------------------------------------
    * (B) OVERLAP "EFECTIVO" (controles ponderados)  [escala invariante]
    *--------------------------------------------
    twoway ///
        (kdensity p`t' [aw=`w_plot'] if D_pp_ignore==0   & `use_t'==1, lpattern(solid)) ///
        (kdensity p`t'              if D_pp_ignore==`t' & `use_t'==1, lpattern(dash)), ///
        legend(order(1 "Controles ponderados" 2 "Tratados (`t')")) ///
        title("Overlap ponderado: Pr(D=`t')") ///
        xtitle("Probabilidad predicha") ytitle("Densidad")
    graph export "`outdir'\overlap_weighted_manual_t`t'.png", replace

    *--------------------------------------------
    * (C) HISTOGRAMA DE PESOS (NORMALIZADOS) en muestra de diseño
    *--------------------------------------------
    histogram `w_plot' if D_pp_ignore==0 & `use_t'==1, percent ///
        title("Pesos IPW (controles) | t=`t'") ///
        subtitle("Normalizados: mean=1 en controles usados") ///
        xtitle("w_norm") ytitle("%")
    graph export "`outdir'\weights_norm_design_manual_t`t'.png", replace

    *--------------------------------------------
    * (C2) Pesos (NORMALIZADOS) sin reglas de diseño (solo p0 válido)
    *   (si no lo querés realmente "sin reglas", borrá este bloque y listo)
    *--------------------------------------------
    gen double `w_raw_nf' = (p`t'/p0) if D_pp_ignore==0 & !missing(p0) & p0>0
    quietly summarize `w_raw_nf' if D_pp_ignore==0 & !missing(`w_raw_nf'), meanonly
    gen double `w_norm_nf' = .
    if (r(N)>0 & r(mean)>0 & r(mean)<.) {
        replace `w_norm_nf' = `w_raw_nf'/r(mean) if D_pp_ignore==0 & !missing(`w_raw_nf')
    }
    gen double `w_plot_nf' = `w_norm_nf'
    histogram `w_plot_nf' if D_pp_ignore==0 & !missing(`w_plot_nf'), percent ///
        title("Pesos IPW (controles) | t=`t'") ///
        subtitle("Sin reglas de diseño (solo p0 válido); normalizados a mean=1") ///
        xtitle("w_norm") ytitle("%")
    graph export "`outdir'\weights_norm_nofilters_manual_t`t'.png", replace

    *--------------------------------------------
    * (D) Histograma adicional "de diseño" con info de CAP/DROP (sin pisar w_plot)
    *--------------------------------------------
    quietly count if D_pp_ignore==0 & `use_t'==1
    if (r(N)>0 & W_CAP_Q<.) {
        gen double `w_plot_d' = `w_cap' if D_pp_ignore==0 & `use_t'==1
        histogram `w_plot_d' if D_pp_ignore==0 & `use_t'==1, percent ///
            title("Pesos de diseño | t=`t'") ///
            subtitle("trim=`W_TRIM_STYLE' q=`W_CAP_Q' (y normalización aplicada en (C))") ///
            xtitle("w_cap (pre-norm)") ytitle("%")
        graph export "`outdir'\weights_design_wcapdrop_manual_t`t'.png", replace
    }
	
	
    *--------------------------------------------
    * (E) LOVE PLOT: |SMD| raw vs weighted (t vs 0)
    *     (balance sobre covariables del mlogit del tratamiento)
    *--------------------------------------------
    tempfile smd_t`t'
    tempname h
    postfile `h' str40 varname double smd_raw double smd_w using `smd_t`t'', replace

    * Dummies para macro_sector (para el balance): manufactura = 1, comparamos con dummy(s) de las otras categorías
    cap drop ms1 ms2 
    gen byte ms1 = (macro_sector==1) if !missing(macro_sector)
	gen byte ms2 = (macro_sector==2) if !missing(macro_sector)

    foreach x in edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes redesXexp redesXsize ms2 {

        * Saltar variables completamente missing (o no creadas)
        capture confirm variable `x'
        if (_rc) continue

        * Medias/varianzas RAW
        quietly summarize `x' if D_pp_ignore==`t' & `use_t'==1
        local mt = r(mean)
        local vt = r(Var)

        quietly summarize `x' if D_pp_ignore==0 & `use_t'==1
        local m0 = r(mean)
        local v0 = r(Var)

        local den = sqrt((`vt' + `v0')/2)
        local smd_raw = .
        if (`den'>0 & `den'<.) local smd_raw = (`mt' - `m0')/`den'

        * Medias/varianzas ponderadas (controles con w_raw)
        quietly summarize `x' if D_pp_ignore==`t' & `use_t'==1
        local mtw = r(mean)
        local vtw = r(Var)

        quietly summarize `x' [aw=`w_raw'] if D_pp_ignore==0 & `use_t'==1
        local m0w = r(mean)
        local v0w = r(Var)

        local denw = sqrt((`vtw' + `v0w')/2)
        local smd_w = .
        if (`denw'>0 & `denw'<.) local smd_w = (`mtw' - `m0w')/`denw'

        post `h' ("`x'") (`smd_raw') (`smd_w')
    }

    postclose `h'

    preserve
        use `smd_t`t'', clear
        gen abs_raw = abs(smd_raw)
        gen abs_w   = abs(smd_w)

        * Nos quedamos con los que existan (si macro_sector tiene solo 2 categorías, ms3..ms5 quedarán missing)
        drop if missing(abs_raw) & missing(abs_w)

        gsort -abs_w
        gen rank = _n

        * Loveplot estilo "puntos en línea" (raw vs weighted)
        * IMPORTANTE: graph display NO acepta ylab()/ylabel(). Para mostrar nombres en el eje Y,
        *             asignamos un value label a rank y luego usamos ylabel(, valuelabel) en twoway.
        cap label drop varlbl_rank
        local N = _N
        label define varlbl_rank 1 "`=varname[1]'", replace
        if (`N'>1) {
            forvalues i=2/`N' {
                local nm = varname[`i']
                label define varlbl_rank `i' "`nm'", add
            }
        }
        label values rank varlbl_rank

        twoway ///
            (scatter rank abs_raw, msymbol(Oh)) ///
            (scatter rank abs_w,   msymbol(Sh)), ///
            yscale(reverse) ///
            ylabel(1(1)`N', valuelabel angle(0) nogrid) ///
            ytitle("") ///
            legend(order(1 "|SMD| raw" 2 "|SMD| weighted")) ///
            xline(0.10, lpattern(dash)) ///
            xtitle("|SMD|") ///
            title("Loveplot (t=`t' vs 0)")
		
		 twoway ///
            (scatter rank abs_w,   msymbol(Sh)), ///
            yscale(reverse) ///
            ylabel(1(1)`N', valuelabel angle(0) nogrid) ///
            ytitle("") ///
            legend(order(1 "|SMD| weighted")) ///
            xline(0.10, lpattern(dash))  xline(0.20, lpattern(dash)) ///
			xscale(range(0 0.30)) xlabel(0(0.05)0.30) ///
            xtitle("|SMD|") ///
            title("Loveplot (t=`t' vs 0)")
			
        graph export "`outdir'\loveplot_t`t'.png", replace

		export excel using "`outdir'\smd_table_t`t'.xlsx", replace firstrow(variables)
    restore

	    * Limpieza mínima
    drop `use_t' `w_raw'
}

log close _all
di as result "Listo. Outputs en: `outdir'"





***************************************************************
*==============================================================================
* 8B) DIAGNÓSTICOS ALINEADOS A TEEFFECTS (para paper)
*     - SMD de teffects: se obtienen de tebalance summarize (r(table))
*     - Loveplot: se arma desde esos SMD (1 fila por variable, por t)
*     - Densidades: restringidas a (0 vs t) para que NO aparezcan 4 tratamientos
*==============================================================================

local DO_TEF_DIAG 1
if (`DO_TEF_DIAG'==1) {

    * Asegurar dummies si las querés en BALVARS
    cap drop ms1 ms2
    gen byte ms1 = (macro_sector==1) if !missing(macro_sector)
    gen byte ms2 = (macro_sector==2) if !missing(macro_sector)

    * Lista de covariables para balance (las que querés reportar/graficar)
    local BALVARS edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes redesXexp redesXsize ms2

    forvalues t=1/3 {

        quietly estimates restore ATET_IGNORE_S1_t`t'

        *============================================================
        * (1) SMD/Vr desde tebalance summarize -> Excel plano + Loveplot
        *============================================================
        quietly tebalance summarize `BALVARS'
        matrix TB = r(table)

        preserve
            clear
            svmat double TB, names(tb)

            * TB viene apilada en 3 bloques (t=1,2,3) uno debajo del otro
            local nvars : word count `BALVARS'
            gen int comp = ceil(_n/`nvars')                 // 1..3
            gen int pos  = mod(_n-1,`nvars') + 1            // 1..nvars
            gen str40 varname = ""
            forvalues j=1/`nvars' {
                local vv : word `j' of `BALVARS'
                replace varname = "`vv'" if pos==`j'
            }

            keep if comp==`t'
            drop comp pos

            * Orden típico: sd_raw, sd_w, vr_raw, vr_w
            rename tb1 sd_raw
            rename tb2 sd_w
            capture rename tb3 vr_raw
            capture rename tb4 vr_w

            gen abs_sd_w = abs(sd_w)
            gsort -abs_sd_w
            gen rank = _n

            * Loveplot (teffects) |SMD| weighted
            cap label drop varlbl_rank_tef
            local N = _N
            label define varlbl_rank_tef 1 "`=varname[1]'", replace
            if (`N'>1) {
                forvalues k=2/`N' {
                    local nm = varname[`k']
                    label define varlbl_rank_tef `k' "`nm'", add
                }
            }
            label values rank varlbl_rank_tef

            twoway ///
                (scatter rank abs_sd_w, msymbol(Sh)), ///
                yscale(reverse) ///
                ylabel(1(1)`N', valuelabel angle(0) nogrid) ///
                ytitle("") ///
                legend(order(1 "|SMD| weighted (teffects)")) ///
                xline(0.10, lpattern(dash)) xline(0.20, lpattern(dash)) ///
                xscale(range(0 0.30)) xlabel(0(0.05)0.30) ///
                xtitle("|SMD|") ///
                title("Loveplot teffects (t=`t' vs 0)")

            graph export "`outdir'\loveplot_teffects_t`t'.png", replace
            export excel using "`outdir'\smd_teffects_t`t'.xlsx", replace firstrow(variables)
        restore

        *============================================================
        * (2) Densidades (teffects) SOLO para (0 vs t)
        *     Recomendación: usar variables continuas (no dummies).
        *============================================================
        /*
		foreach x in ln_tpo_mean indice_redes share_prof_tecn edad redesXsize {

            capture confirm variable `x'
            if _rc continue

            preserve
                keep if inlist(D_pp_ignore,0,`t')
                quietly estimates restore ATET_IGNORE_S1_t`t'
                tebalance density `x', bwidth(*1.3) ///
                    title("Balance plot: `x' (t=`t' vs 0)")
                graph export "`outdir'\density_teffects_`x'_t`t'.png", replace
            restore
        }
		*/
				* --- Soporte teffects (0 vs t) ---
		preserve
		keep if inlist(D_pp_ignore,0,`t')
		gen byte out_support = (os_t`t'==1)
		tab out_support D_pp_ignore, row
		graph bar (mean) out_support, over(D_pp_ignore) ///
			title("Fuera de soporte (teffects): t=`t' vs 0") ///
			ytitle("Proporción")
		graph export "`outdir'\support_teffects_t`t'.png", replace
		restore

    }
}



****************************************************************************

**# SECTORES


					   
				  
*============================================================
* IPWRA por macro_sector y diferencias (DIAGONALES) - point estimates
*============================================================

local D   D_pp_ignore
local Y   Y_cond

local XTR0 "edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean  indice_redes                   redesXexp redesXsize"
local XY0  "edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean  indice_redes ln_tpo_sq edad_sq redesXexp redesXsize org1 org_miss"

local P0_FLOOR        = 1e-8
local P0_TREAT_FLOOR  = 1e-8
local W_CEIL          = 1e6
local PS_TRIM_ON = 1
local PS0_LOW    = 0.05
local PS0_HIGH   = 0.95
local WTRIM      "OFF" // o DROP
local W_CAP_Q    = . // o 0.99 por ejemplo.

tempname a1m a2m a3m a1s a2s a3s
scalar `a1m' = .
scalar `a2m' = .
scalar `a3m' = .
scalar `a1s' = .
scalar `a2s' = .
scalar `a3s' = .

foreach s in 1 2 {

    preserve
        keep if macro_sector==`s'
        keep if inlist(`D',0,1,2,3)
        drop if missing(`Y')

        * dropear missings en unión de covariables  (NO en una sola línea con llaves)
        foreach x of local XTR0 {
            drop if missing(`x')
        }
        foreach x of local XY0 {
            drop if missing(`x')
        }

        quietly mlogit `D' `XTR0', baseoutcome(0) nolog
        cap drop p0 p1 p2 p3
        predict double p0, outcome(0)
        predict double p1, outcome(1)
        predict double p2, outcome(2)
        predict double p3, outcome(3)

        tempvar use_final w1 w2 w3
        gen byte `use_final' = 1

        replace `use_final' = 0 if missing(p0)
        replace `use_final' = 0 if (`D'==0            & p0<=`P0_FLOOR')
        replace `use_final' = 0 if (inlist(`D',1,2,3) & p0<=`P0_TREAT_FLOOR')

        if (`PS_TRIM_ON'==1) {
            replace `use_final' = 0 if (p0<`PS0_LOW' | p0>`PS0_HIGH')
        }

        gen double `w1' = .
        gen double `w2' = .
        gen double `w3' = .
        replace `w1' = (p1/p0) if `D'==0 & `use_final'==1
        replace `w2' = (p2/p0) if `D'==0 & `use_final'==1
        replace `w3' = (p3/p0) if `D'==0 & `use_final'==1

        replace `use_final' = 0 if `D'==0 & `use_final'==1 & (missing(`w1') | `w1'<=0 | `w1'>`W_CEIL')
        replace `use_final' = 0 if `D'==0 & `use_final'==1 & (missing(`w2') | `w2'<=0 | `w2'>`W_CEIL')
        replace `use_final' = 0 if `D'==0 & `use_final'==1 & (missing(`w3') | `w3'<=0 | `w3'>`W_CEIL')

        if (upper("`WTRIM'")=="DROP") {
            local pct = 100*`W_CAP_Q'
            quietly count if `D'==0 & `use_final'==1
            if (r(N)>0) {
                quietly centile `w1' if `D'==0 & `use_final'==1, centile(`pct')
                local wcap1 = r(c_1)
                quietly centile `w2' if `D'==0 & `use_final'==1, centile(`pct')
                local wcap2 = r(c_1)
                quietly centile `w3' if `D'==0 & `use_final'==1, centile(`pct')
                local wcap3 = r(c_1)

                if (`wcap1'<. & `wcap1'>0) replace `use_final' = 0 if `D'==0 & `use_final'==1 & `w1' > `wcap1'
                if (`wcap2'<. & `wcap2'>0) replace `use_final' = 0 if `D'==0 & `use_final'==1 & `w2' > `wcap2'
                if (`wcap3'<. & `wcap3'>0) replace `use_final' = 0 if `D'==0 & `use_final'==1 & `w3' > `wcap3'
            }
        }

        keep if `use_final'==1
		
			* tablas descriptivas en misma muestra que las estimaciones por sectores
		summarize  Y_cond i.D_pp_ignore edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
												ln_tpo_sq edad_sq redesXexp redesXsize ///
										  org1 org_miss if `s'==1
		summarize  Y_cond i.D_pp_ignore edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ///
												ln_tpo_sq edad_sq redesXexp redesXsize ///
										  org1 org_miss if `s'==2
        drop `use_final' `w1' `w2' `w3'

        tempname b V
        forvalues t=1/3 {

            quietly count if `D'==`t'
            local Nt = r(N)
            quietly count if `D'==0
            local N0 = r(N)
            if (`Nt'==0 | `N0'==0) continue
		
        *osample(`__osname') pstolerance(`=P0_FLOOR') vce(cluster correlativo)
        teffects ipwra ///
                (`Y' `XY0', logit) ///
                (`D' `XTR0', mlogit), ///
                atet control(0) tlevel(`t') 

            if (_rc==0 & e(converged)==1) {
                matrix `b' = e(b)
                matrix `V' = e(V)
				local cn : colfullnames `b'

				* Lista de columnas ATET (en orden k=1,2,3)
				local atetcols ""
				foreach nm of local cn {
					if (substr("`nm'",1,5)=="ATET:") local atetcols "`atetcols' `nm'"
				}
				* Columna diagonal: k=t  (t-ésimo ATET)
				local diagcol : word `t' of `atetcols'

				scalar __atet = el(`b', 1, colnumb(`b', "`diagcol'"))

                if (`s'==1 & `t'==1) scalar `a1m' = __atet
                if (`s'==1 & `t'==2) scalar `a2m' = __atet
                if (`s'==1 & `t'==3) scalar `a3m' = __atet
                if (`s'==2 & `t'==1) scalar `a1s' = __atet
                if (`s'==2 & `t'==2) scalar `a2s' = __atet
                if (`s'==2 & `t'==3) scalar `a3s' = __atet
            }
        }

    restore
}

di as text "ATET1 diff (M-S) = " %9.5f (`a1m' - `a1s')
di as text "ATET2 diff (M-S) = " %9.5f (`a2m' - `a2s')
di as text "ATET3 diff (M-S) = " %9.5f (`a3m' - `a3s')

di as text "ATET1 Manuf = " %9.5f `a1m' " | Serv = " %9.5f `a1s' " | Diff(M-S) = " %9.5f (`a1m'-`a1s')
di as text "ATET2 Manuf = " %9.5f `a2m' " | Serv = " %9.5f `a2s' " | Diff(M-S) = " %9.5f (`a2m'-`a2s')
di as text "ATET3 Manuf = " %9.5f `a3m' " | Serv = " %9.5f `a3s' " | Diff(M-S) = " %9.5f (`a3m'-`a3s')




*********************************************************************************
*====================================================================
* (A) DISEÑO FIJO (UNA SOLA VEZ): construir y guardar base recortada
*====================================================================

* Requiere que ya existan:
*   - macro_sector (1=manuf, 2=serv)
*   - D_pp_ignore (0/1/2/3)
*   - Y_cond
*   - covariables en XTR0 y XY0 (incluye ln_tpo_sq, edad_sq, redesXexp, redesXsize, etc.)

local D   D_pp_ignore
local Y   Y_cond

* Listas (las tuyas)
local XTR0 "edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes                   redesXexp redesXsize"
local XY0  "edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes ln_tpo_sq edad_sq redesXexp redesXsize org1 org_miss"

* Umbrales (los tuyos)
local P0_FLOOR        = 1e-8
local P0_TREAT_FLOOR  = 1e-8
local W_CEIL          = 1e6
local PS_TRIM_ON = 1
local PS0_LOW    = 0.05
local PS0_HIGH   = 0.95
local WTRIM      "OFF" // o DROP
local W_CAP_Q    = . // o 0.99 por ejemplo.

* ID de observación para "marcar" qué filas entran en la muestra fija
gen long __obsid = _n
gen byte __keep_design = 0

tempfile __keepids

foreach s in 1 2 {

    preserve
        keep if macro_sector==`s'
        keep if inlist(`D',0,1,2,3)
        drop if missing(`Y')

        * Drop missings en unión de covariables
        foreach x of local XTR0 {
            drop if missing(`x')
        }
        foreach x of local XY0 {
            drop if missing(`x')
        }

        * mlogit para p0..p3 (solo para definir muestra)
        quietly mlogit `D' `XTR0', baseoutcome(0) nolog

        capture drop p0 p1 p2 p3
        quietly predict double p0, outcome(0)
        quietly predict double p1, outcome(1)
        quietly predict double p2, outcome(2)
        quietly predict double p3, outcome(3)

        tempvar use_final w1 w2 w3
        gen byte `use_final' = 1

        * Floors sobre p0
        replace `use_final' = 0 if missing(p0)
        replace `use_final' = 0 if (`D'==0            & p0<=`P0_FLOOR')
        replace `use_final' = 0 if (inlist(`D',1,2,3) & p0<=`P0_TREAT_FLOOR')

        * PS-trim sobre p0
        if (`PS_TRIM_ON'==1) {
            replace `use_final' = 0 if (p0<`PS0_LOW' | p0>`PS0_HIGH')
        }

        * wceil en controles para cada t
        gen double `w1' = .
        gen double `w2' = .
        gen double `w3' = .
        replace `w1' = (p1/p0) if `D'==0 & `use_final'==1
        replace `w2' = (p2/p0) if `D'==0 & `use_final'==1
        replace `w3' = (p3/p0) if `D'==0 & `use_final'==1

        replace `use_final' = 0 if `D'==0 & `use_final'==1 & (missing(`w1') | `w1'<=0 | `w1'>`W_CEIL')
        replace `use_final' = 0 if `D'==0 & `use_final'==1 & (missing(`w2') | `w2'<=0 | `w2'>`W_CEIL')
        replace `use_final' = 0 if `D'==0 & `use_final'==1 & (missing(`w3') | `w3'<=0 | `w3'>`W_CEIL')

        * DROP por cuantil (solo controles) si corresponde
        if (upper("`WTRIM'")=="DROP") {
            local pct = 100*`W_CAP_Q'
            quietly count if `D'==0 & `use_final'==1
            if (r(N)>0) {
                quietly centile `w1' if `D'==0 & `use_final'==1, centile(`pct')
                local wcap1 = r(c_1)
                quietly centile `w2' if `D'==0 & `use_final'==1, centile(`pct')
                local wcap2 = r(c_1)
                quietly centile `w3' if `D'==0 & `use_final'==1, centile(`pct')
                local wcap3 = r(c_1)

                if (`wcap1'<. & `wcap1'>0) replace `use_final' = 0 if `D'==0 & `use_final'==1 & `w1' > `wcap1'
                if (`wcap2'<. & `wcap2'>0) replace `use_final' = 0 if `D'==0 & `use_final'==1 & `w2' > `wcap2'
                if (`wcap3'<. & `wcap3'>0) replace `use_final' = 0 if `D'==0 & `use_final'==1 & `w3' > `wcap3'
            }
        }

        keep if `use_final'==1
        keep __obsid
        save `__keepids', replace
    restore

    * Marcar en la base completa
	merge 1:1 __obsid using `__keepids', keep(master match)
	replace __keep_design = 1 if _merge==3
	drop _merge
}

* Quedarse SOLO con la muestra fija
keep if __keep_design==1
drop __keep_design __obsid

* Guardar base fija para bootstrap (tempfile o a disco)
*tempfile BOOTBASE_FIXED
*save `BOOTBASE_FIXED', replace
* Si querés guardarla en disco:
save "BOOTBASE_FIXED.dta", replace




*====================================================================
* (B) PROGRAMA LIMPIO: SOLO teffects (sectores 1/2) + diagonales + diffs
*     (asume que la base YA está recortada por el diseño fijo)
*====================================================================


cap program drop ipwra_diff_manu_serv
program define ipwra_diff_manu_serv, rclass
    version 19.0
    syntax , DVAR(name) YVAR(name) XTR(string asis) XY(string asis) SECTOR(name) ///
        [VCETYPE(string) CLUSTERVAR(name) MINCELL(integer 30) MAXITER(integer 55)]

    * Defaults
    if ("`vcetype'"=="")    local vcetype "robust"
    if ("`clustervar'"=="") local clustervar "correlativo"
    if ("`mincell'"=="")    local mincell = 30
    if ("`maxiter'"=="")    local maxiter = 55

    * Normalizar strings + retokenize
    local xtr : subinstr local xtr `"""' "", all
    local xy  : subinstr local xy  `"""' "", all
    local xtr : list retokenize xtr
    local xy  : list retokenize xy

    * Remover i.macro_sector si viniera
    local xtr0 : subinstr local xtr "i.macro_sector" "", all
    local xy0  : subinstr local xy  "i.macro_sector" "", all
    local xtr0 : list retokenize xtr0
    local xy0  : list retokenize xy0

    * VCE option
    local vceopt "vce(`vcetype')"
    if (lower("`vcetype'")=="cluster") local vceopt "vce(cluster `clustervar')"

    * Salidas
    tempname a1m a2m a3m a1s a2s a3s b
    scalar `a1m' = .
    scalar `a2m' = .
    scalar `a3m' = .
    scalar `a1s' = .
    scalar `a2s' = .
    scalar `a3s' = .

    foreach s in 1 2 {

        preserve
            keep if `sector'==`s'
            keep if inlist(`dvar',0,1,2,3)
            drop if missing(`yvar')

            forvalues t=1/3 {

                quietly count if `dvar'==`t'
                local Nt = r(N)
                quietly count if `dvar'==0
                local N0 = r(N)

                * Fail fast
                if (`Nt' < `mincell' | `N0' < `mincell') continue

                quietly capture teffects ipwra ///
                    (`yvar' `xy0', logit) ///
                    (`dvar' `xtr0', mlogit), ///
                    atet control(0) tlevel(`t') `vceopt' iterate(`maxiter')

                if (_rc==0 & e(converged)==1) {

                    matrix `b' = e(b)
                    local cn : colfullnames `b'

                    * ======= TU LÓGICA ORIGINAL (sin inventar) =======
                    local atetcols ""
                    foreach nm of local cn {
                        if (substr("`nm'",1,5)=="ATET:") local atetcols "`atetcols' `nm'"
                    }

                    local diagcol : word `t' of `atetcols'

                    * Airbag: si por algún motivo no existe la palabra t, caer al 1ro
                    if ("`diagcol'"=="") local diagcol : word 1 of `atetcols'
                    if ("`diagcol'"=="") continue

                    local j = colnumb(`b', "`diagcol'")
                    if (`j'<=0) continue

                    scalar __atet = el(`b', 1, `j')
                    * ================================================

                    if (`s'==1 & `t'==1) scalar `a1m' = __atet
                    if (`s'==1 & `t'==2) scalar `a2m' = __atet
                    if (`s'==1 & `t'==3) scalar `a3m' = __atet
                    if (`s'==2 & `t'==1) scalar `a1s' = __atet
                    if (`s'==2 & `t'==2) scalar `a2s' = __atet
                    if (`s'==2 & `t'==3) scalar `a3s' = __atet
                }
            }
        restore
    }

    local ok = 1
    if (missing(`a1m') | missing(`a2m') | missing(`a3m') | ///
        missing(`a1s') | missing(`a2s') | missing(`a3s')) local ok = 0

    return scalar ok    = `ok'
    return scalar a1m   = `a1m'
    return scalar a2m   = `a2m'
    return scalar a3m   = `a3m'
    return scalar a1s   = `a1s'
    return scalar a2s   = `a2s'
    return scalar a3s   = `a3s'
    return scalar diff1 = (`a1m' - `a1s')
    return scalar diff2 = (`a2m' - `a2s')
    return scalar diff3 = (`a3m' - `a3s')
end





***************************

log using "`outdir'\ATET_IGNORE_S1_SECTORDIFF_BOOT.log", replace


ereturn list

ereturn clear
estimates clear

* una vez
use "BOOTBASE_FIXED.dta", clear
ipwra_diff_manu_serv, dvar(D_pp_ignore) yvar(Y_cond) sector(macro_sector) ///
    xtr("`XTR0'") xy("`XY0'") ///
    vcetype(robust)

return list
* chequeo rápido
di as txt "ok = " %9.0g r(ok) " | diff1=" %9.4f r(diff1) " diff2=" %9.4f r(diff2) " diff3=" %9.4f r(diff3)

/*
* bootstrap: una prueba rapida de 4 reps
use "BOOTBASE_FIXED.dta", clear
set seed 12345
xtset, clear

bootstrap r(diff1) r(diff2) r(diff3), reps(4)  cluster(correlativo)  strata(macro_sector) : ///
    ipwra_diff_manu_serv, dvar(D_pp_ignore) yvar(Y_cond) sector(macro_sector) ///
        xtr("`XTR0'") xy("`XY0'") vcetype(robust)

* opcional: ver tabla guardada en e(b), e(V) del bootstrap
ereturn list
*/


********************* metodo de bootstrap acelerado: parallel ************************
		
*------------------------------------------------------------
* 0) Recomendación práctica: guardá BOOTBASE_FIXED a disco
*------------------------------------------------------------
use "BOOTBASE_FIXED.dta", clear

xtset, clear
set seed 12345

*------------------------------------------------------------
* 1) Instalar parallel (si hace falta)
*------------------------------------------------------------
cap which parallel
if _rc {
    net install parallel, from(https://raw.github.com/gvegayon/parallel/master/) replace
    * alternativa :
	* ssc install parallel, replace
}

*------------------------------------------------------------
* 2) Setear clusters (en tu máquina 8-core: 8)
*------------------------------------------------------------
set processors 1
parallel setclusters 8, force

*------------------------------------------------------------
* 3) Smoke test (pocas reps) para confirmar que corre
*  Para la estimacion real poner aprox 600 reps para obtener aprox 500 replicas sin fallas; hay un % de fallas de aprox. 18%!.
*  O incluso poner 900 para obtener aprox unas 750 reps sin fallas. 
*------------------------------------------------------------
parallel bs, ///
    expression( diff1 = r(diff1) diff2 = r(diff2) diff3 = r(diff3) ) ///
    reps(1000)  cluster(correlativo) strata(macro_sector) : ///
    ipwra_diff_manu_serv, dvar(D_pp_ignore) yvar(Y_cond) sector(macro_sector) ///
        xtr("`XTR0'") xy("`XY0'") vcetype(robust) 

log close
		
parallel clean, all

*Semillas y reproducibilidad
*	seeds(numlist) o randtype(current|datetime|random.org) para manejar cómo se generan semillas por hijo.
*	deterministicoutput reduce output "variable" (timers, seeds, etc.) para que logs sean comparables.

************************ alternativa: metodo de bootstrap acelerado *****************

/*
* Parámetros
local Rtotal 750
local B      10
local Rblock = `Rtotal'/`B'

* Correr bloques (saltando los que ya existan = restart real)
forvalues b = 1/`B' {

    local f = "bs_block`b'.dta"
    cap confirm file "`f'"
    if (_rc==0) {
        di as txt "Block `b' ya existe -> lo salteo (`f')"
        continue
    }

    use "BOOTBASE_FIXED.dta", clear
    set seed = 123000 + `b'   // semilla distinta por bloque (reproducible)

    quietly bootstrap r(diff1) r(diff2) r(diff3), ///
        reps(`Rblock') ///
        saving("`f'", replace) : ///
        ipwra_diff_manu_serv, dvar(D_pp_ignore) yvar(Y_cond) sector(macro_sector) ///
            xtr("`XTR0'") xy("`XY0'") vcetype(robust)

    di as txt "OK bloque `b' guardado en `f'"
}

* Combinar bloques
use "bs_block1.dta", clear
forvalues b=2/`B' {
    append using "bs_block`b'.dta"
}

* Reporte final desde el dataset de réplicas:
bstat diff1 diff2 diff3

*/





/*
"¿De dónde sale el N del bootstrap si Manuf y Serv tienen distintos tamaños?"
En bootstrap por clusters, Stata hace esto:
Define la población bootstrap como el conjunto de clusters (correlativo), o clusters dentro de estratos si usás strata().
En cada réplica, selecciona clusters con reemplazo hasta "llenar" el mismo número de clusters que el original (o el mismo por estrato si hay estratos).
Luego arma la base réplica concatenando todas las observaciones de los clusters seleccionados (y si un cluster se selecciona dos veces, sus observaciones aparecen dos veces; por eso necesitás idcluster() si tu data es panel).

Por eso el "Number of obs" que te muestra bootstrap:
No es el N original por sector.
Puede ser mayor o menor que el original.
Tiende a ser mayor si muchos clusters tienen más de una observación y algunos se repiten.

En tu output viste "Number of obs = 4,457" cuando tu muestra "real" andaba por ~2,4k + ~2,0k (tras trimming). Eso es consistente con cluster bootstrap + repeticiones + (muy importante) que el bootstrap corre sobre la muestra antes de tu trimming interno, y tu programa vuelve a recortar adentro. Stata reporta el "Number of obs" del comando bootstrap para el "Observed"/réplicas con la muestra bootstrap construida; no necesariamente coincide con el N final tras tus keep if use_final==1 dentro del programa.

Si querés que el bootstrap sea más "fiel" a tus tamaños sectoriales:
strata(macro_sector) ayuda porque fuerza a que el número de clusters remuestreados dentro de cada sector sea el mismo que en el original (por estrato).
Pero igual el número de observaciones va a fluctuar, porque hay heterogeneidad en tamaño del cluster (firmas con más olas del panel) y repeticiones.

*/


