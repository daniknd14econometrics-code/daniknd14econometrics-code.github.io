/*------------------------------------------------------------------------------
3ATET_IPWRA_design_balance_selector_tebalance_v19.do
Autor: Daniel + ChatGPT
Fecha: 2026-02-17

OBJETIVO (versión “operativa” y sin episodios; con GLOBALS como preferís):

(1) MUESTRA:
    - Trabajar SOLO dentro de b1_9==1 (empresas con actividad de innovación).
    - Outcome (Y_cond): mejora ambiental (1 si resul_mejora_ambiente in {1,2})
      definido SOLO entre innovadores.
      -> NO se convierte a 0 para no innovadores; fuera de b1_9==1 el outcome no está definido.

(2) TRATAMIENTO (estado, NO episodios):
    D_pp = 0: No prod/proc
           1: Solo producto
           2: Solo proceso
           3: Ambas
    (NO por episodios: por diseño te deja celdas minúsculas y rompe el solapamiento.)

(3) DOS MODOS respecto a “innovación organizacional/comercial” (innova_organiz_comerc):
    MODO 1) IGNORE_ORG:
        - NO se excluye org al definir D_pp (se usa toda la muestra de innovadores).
        - Opcional: controlar por org con auxiliares org1 y org_miss.
    MODO 2) STRICT_AVOID_ORG:
        - Excluir observaciones con org==1 y también con org missing.
        - (Más “limpio” si tu objetivo es aislar prod/proc sin contaminar por org,
           pero reduce MUCHO la muestra y puede romper mlogit/overlap.)

(4) DISEÑO “A CIEGAS” (SIN mirar el ATET):
    - Se comparan pocas especificaciones candidatas (sets de X) con métricas de balance/solapamiento:
        max|SMD|, mean|SMD|, max|log(var ratio)|, ESS0, N1, N0, concentración de pesos (p95/p99/max).
    - Se elige una especificación “ganadora” por modo usando SOLO esas métricas.
    - Recién después (si RUN_ATET=1) se corre teffects ipwra y se exportan gráficos de overlap/pesos.

NOTA CLAVE SOBRE org1 y org_miss (cuando INCLUDE_ORG_CONTROLS=1 en IGNORE_ORG):
    - org1: dummy (org==1), rellenando missing como 0 para no perder muestra.
    - org_miss: dummy de missing en org (separa “0 real” de “no observado”).
    - En IPWRA podés usar covariables distintas en el modelo de tratamiento y el de outcome.
      Por defecto acá, si incluís org controls, podés elegir:
        ORG_IN_YMODEL=1 -> org1 y org_miss van también al outcome model.
        ORG_IN_YMODEL=0 -> org1 y org_miss SOLO van al tratamiento model.
      (No hay “una verdad única”: 1 suele estabilizar; 0 es más conservador si temés bad controls.)

IMPORTANTE:
    - Si cambiás locals a globals, NO uses "=" en globals numéricos.
      Correcto:  global RUN_ATET 1
      Incorrecto: global RUN_ATET = 1   (eso guarda el string "= 1" y rompe ifs).
------------------------------------------------------------------------------*/

version 19.0
clear all
set more off

*========================
* 0) Rutas (GLOBAL)
*========================
global seteo "C:\Users\Equipo\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"

local username = c(username)
if "`username'"=="Equipo" {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"
}
else if "`username'"=="dmendez" {
    global seteo "C:\Users\dmendez\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\"
}

* Carpeta de salida
global outdir "${seteo}3. Estrategia empirica\3. Modelos\5Resultado-innovacion - estrategia causal\Medio Ambiente\_outputs_ipwra"
cap mkdir "${outdir}"


*========================
* 1) Parámetros (GLOBAL) 
*========================
* 1=usar lags (L1_) cuando existan; 0=usar contemporáneos
global USE_LAGS 0

* En modo IGNORE_ORG: ¿agregar org1 + org_miss como covariables?
* esto es para lidiar con que se dejo de relevar a la innovacion en organizacion desde 2018 incluido. 
global INCLUDE_ORG_CONTROLS 0

* Si INCLUDE_ORG_CONTROLS=1: ¿org entra también en el outcome model?
* 1 = sí (treatment Y outcome), 0 = solo treatment model
global ORG_IN_YMODEL 0

* ¿Correr ATET + gráficos al final con la spec ganadora?
global RUN_ATET 1

* Umbrales prácticos para warnings (no son “reglas”)
global MIN_N_USED 300
global MIN_N1     30
global MIN_N0     50


********************* probabilidad de ser control (p0) ***************************************************

* Lo siguiente hace que puedan borrarse controles por piso en la probabilidad de ser control (p0) para los controles (D=0).
* tambien es para evitar explosiones numéricas por p0 aproximadamente 0, recordar que w_raw=pt/p0
* esto es replicable con teffects si se define una muestra donde se hace esto justo antes de aplicar el comando mencionado.
global P0_FLOOR   1e-8 // poner 0 para desactivar

* Para ATET, el solapamiento crítico es que p0(X)>0 también entre tratados (evita “tratados sin contrafactual”).
* entonces, lo siguiente hace que puedan borrarse tratatos por piso en la probabilidad de ser control (p0) para los tratados (D=t) con t=1,2,3.
* esto es replicable con teffects si se define una muestra donde se hace esto justo antes de aplicar el comando mencionado.
global P0_TREAT_FLOOR 1e-8  // poner 0 para desactivar

* Trimming explícito sobre p0 (probabilidad de ser control) si querés una regla tipo e(X)€[a,b]
* 0=off (default); 1=on
* Aca la idea es aplicar un trimming sobre la p0, y no es un piso, si no que es un trimming (por ejemplo, el 1% mas bajo y el 1% mas alto). Se aplica tanto para los controles como para los tratados. 
* esto es replicable con teffects si se define una muestra donde se hace esto justo antes de aplicar el comando mencionado.
global PS_TRIM     1
global PS0_LOW     0.05
global PS0_HIGH    0.95

********************* pesos w_raw = pt/p0 ***************************************************

* Techo duro/corte duro de seguridad que aplicamos sobre los pesos "raw": w=pt/p0 sobre los controles (D=0)
* esto es replicable con teffects si se define una muestra donde se hace esto justo antes de aplicar el comando mencionado.
global W_CEIL     1e6

* Trimming aplicado sobre los pesos w (raw) sobre los controles (D=0). (w = p_t/p0): CAP (winsoriza) o DROP (elimina).
* si se elige CAP, lo que hace es que los valores de w mayores al percentil w_cap, se reemplazan por el valor correspondiente al percentil fijado, solo para los controles (D=0).
* esto puede ser util, pero hay que tener presente que el comando teffects no hace esto, y no se puede replicar con teffects.
* en tanto que la opcion DROP elimina directamente las w mayores a w_cap. Esto si es replicable con teffects si eliminamos antes de correr el comando mencionado. 
* para desactivar: poner "OFF" en W_TRIM_STYLE junto con "." en "W_CAP_Q".
global W_TRIM_STYLE OFF
* Cuantil para cap/drop (p.ej. 0.99 o 0.995; poner "." para desactivar)
global W_CAP_Q    .


**********************************************************************************

* Parsing de tebalance: 1=estricto (no usa fallback silencioso), 0=usa fallback con warning
global STRICT_TEB_PARSE 1

* Debug: imprimir colnames/validaciones de tebalance una sola vez
global DEBUG_TEB   1
global TEB_PRINTED 1

* Control de ejecución (por defecto: proxy IPW (TEW) ON; en tanto que la version mas exigente y no precisamente necesaria (TEB) en OFF).
global RUN_TEW 1
global RUN_TEB 0
* Mostrar tablas en consola (sin abrir .dta) al final del bloque 7
global SHOW_LONG_TABLES 1


* Tolerancia de balance para selector (tebalance): max|SMD| <= SMD_TOL
global SMD_TOL    0.10

*========================
* 2) Base y panel (delta 3)
*========================
use "${seteo}3. Estrategia empirica\3. Modelos\panel_innovacion_ipi_8.dta", clear

isid correlativo anio
xtset correlativo anio, delta(3)

*========================
* 2.4) Control de especificación de covariables (switches)
*========================
* Objetivo: poder prender/apagar, SIN tocar el “motor” del selector:
*   - Cuadráticos (tamaño, edad)
*   - Interacciones (redes×expor, redes×tamaño)
*   - FE por ola (anio) y FE por sector (industry_id)
*
* Nota: NO usamos c./i. (factor vars) porque este pipeline trabaja con listas
* de nombres de variables existentes + checks numéricos (confirm numeric).
* La forma “limpia” acá es crear variables explícitas (numéricas) y luego
* decidir si entran o no en cada ecuación.

* ----- Qué entra en el MLOGIT del tratamiento (D) -----
 

* si use LAG 0
global TR_USE_SIZE_SQ      0 
global TR_USE_AGE_SQ       0  
global TR_USE_INT_RXEXP    1  
global TR_USE_INT_RXSIZE   1  
global TR_USE_FE_WAVE      0   // si se activa se rompe en el modo estrico. en tanto que, si bien contemporaneo no rompe, las dummies de ola te empeoran mucho las metricas de diseño.
global TR_USE_FE_SECTOR    1	   

* ----- Qué entra en el modelo de outcome (Y) -----
global Y_USE_SIZE_SQ       1 
global Y_USE_AGE_SQ        1
global Y_USE_INT_RXEXP     1 
global Y_USE_INT_RXSIZE    1
global Y_USE_FE_WAVE       0  // si se activa se rompe en el modo estrico. en tanto que, si bien contemporaneo no rompe, las dummies de ola te empeoran mucho las metricas de diseño.
global Y_USE_FE_SECTOR     1 


* si use LAG 1
/*
* ----- Qué entra en el MLOGIT del tratamiento (D) -----
global TR_USE_SIZE_SQ      0  
global TR_USE_AGE_SQ       0  
global TR_USE_INT_RXEXP    1   
global TR_USE_INT_RXSIZE   1   
global TR_USE_FE_WAVE      0   // en lag, se rompe si se activa en ambos modos.
global TR_USE_FE_SECTOR    1   
* ----- Qué entra en el modelo de outcome (Y) -----
global Y_USE_SIZE_SQ       1  // en lag, se rompe el modo estricto.  
global Y_USE_AGE_SQ        1
global Y_USE_INT_RXEXP     1  // en lag, se rompe el modo estricto.  (podria dejarla activada si solo nos basamos en el modo "ignoro", siempre que no empeore metricas)
global Y_USE_INT_RXSIZE    1
global Y_USE_FE_WAVE       0  // en lag, se rompe si se activa en ambos modos.
global Y_USE_FE_SECTOR     1  
*/


* Límite de categorías para sector FE (evita romper mlogit por separación)
global MAX_SECTOR_FE 16

* Debug de armado de listas (1 imprime listas finales; 0 silencioso)
global DEBUG_XSETS 1


*========================
* 2.5) Transformaciones y FE (creación de variables explícitas)
*========================
* --- Cuadráticos ---
capture confirm numeric variable ln_tpo_mean
if !_rc {
    capture drop ln_tpo_sq
    gen double ln_tpo_sq = ln_tpo_mean^2
}
capture confirm numeric variable edad
if !_rc {
    capture drop edad_sq
    gen double edad_sq = edad^2
}

* --- Interacciones ---
capture confirm numeric variable indice_redes
if !_rc {
    capture confirm numeric variable exp_dummy
    if !_rc {
        capture drop redesXexp
        gen double redesXexp = indice_redes*exp_dummy
    }
    capture confirm numeric variable ln_tpo_mean
    if !_rc {
        capture drop redesXsize
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

* --- Dummies sectoriales (industry_id) ---
* WARNING: si hay demasiadas categorías, el mlogit puede fallar por separación/colinealidad.
/*
global FE_SECTOR_VARS ""
capture confirm numeric variable industry_id
if !_rc {
    quietly levelsof industry_id, local(_levs_ind)
    local _K : word count `_levs_ind'
    if (`_K'<=${MAX_SECTOR_FE}) {
        capture drop ind_*
        quietly tab industry_id, gen(ind_)
        quietly ds ind_*, has(type numeric)
        global FE_SECTOR_VARS `r(varlist)'
    }
    else {
        di as error "industry_id tiene `_K' categorías (>${MAX_SECTOR_FE}). Omito dummies sectoriales. (Sugerencia: agrupar sectores.)"
    }
}

*/
* --- Dummies macro-sector (macro_sector) ---
gen byte macro_sector = 3   // 1=Manufacturing, 2=Services, 3=Other/missing

* TU definición:
replace macro_sector = 1 if inlist(industry_id, 6)
replace macro_sector = 2 if inlist(industry_id, 2,3,4,5,7,8,11)
replace macro_sector = 3 if missing(industry_id) | inlist(industry_id, 1,9,10)

label define macro_sector 1 "Manufacturing" 2 "Services" 3 "Other/missing", replace
label values macro_sector macro_sector

drop if macro_sector==3

*/
global FE_SECTOR_VARS ""
capture confirm numeric variable macro_sector
if !_rc {
    quietly levelsof macro_sector, local(_levs_ind)
    local _K : word count `_levs_ind'
    if (`_K'<=${MAX_SECTOR_FE}) {
        capture drop mc_*
        quietly tab macro_sector, gen(mc_)
        quietly ds mc_*, has(type numeric)
        global FE_SECTOR_VARS `r(varlist)'
    }
    else {
        di as error "macro_sector tiene `_K' categorías (>${MAX_SECTOR_FE})."
    }
}

tab anio macro_sector if b1_9==1


* --- Construir listas “listas para enchufar” en tratamiento/outcome ---
* (Estas son SOLO listas de nombres. La selección L1_ vs contemporánea la hace build_xlist.)
global EXTRA_TREAT   ""
global EXTRA_OUTCOME ""

if (${TR_USE_SIZE_SQ}==1)    global EXTRA_TREAT   "${EXTRA_TREAT} ln_tpo_sq"
if (${TR_USE_AGE_SQ}==1)     global EXTRA_TREAT   "${EXTRA_TREAT} edad_sq"
if (${TR_USE_INT_RXEXP}==1)  global EXTRA_TREAT   "${EXTRA_TREAT} redesXexp"
if (${TR_USE_INT_RXSIZE}==1) global EXTRA_TREAT   "${EXTRA_TREAT} redesXsize"

if (${Y_USE_SIZE_SQ}==1)     global EXTRA_OUTCOME "${EXTRA_OUTCOME} ln_tpo_sq"
if (${Y_USE_AGE_SQ}==1)      global EXTRA_OUTCOME "${EXTRA_OUTCOME} edad_sq"
if (${Y_USE_INT_RXEXP}==1)   global EXTRA_OUTCOME "${EXTRA_OUTCOME} redesXexp"
if (${Y_USE_INT_RXSIZE}==1)  global EXTRA_OUTCOME "${EXTRA_OUTCOME} redesXsize"

* FE listas por ecuación (se agregan “tal cual”, siempre contemporáneas)
global FE_TREAT_VARS   ""
global FE_OUTCOME_VARS ""

if (${TR_USE_FE_WAVE}==1)    global FE_TREAT_VARS   "${FE_TREAT_VARS} ${FE_WAVE_VARS}"
if (${TR_USE_FE_SECTOR}==1)  global FE_TREAT_VARS   "${FE_TREAT_VARS} ${FE_SECTOR_VARS}"

if (${Y_USE_FE_WAVE}==1)     global FE_OUTCOME_VARS "${FE_OUTCOME_VARS} ${FE_WAVE_VARS}"
if (${Y_USE_FE_SECTOR}==1)   global FE_OUTCOME_VARS "${FE_OUTCOME_VARS} ${FE_SECTOR_VARS}"

* Limpieza de espacios
local __tmp1 "${EXTRA_TREAT}"
local __tmp1 : list retokenize __tmp1
global EXTRA_TREAT "`__tmp1'"
local __tmp2 "${EXTRA_OUTCOME}"
local __tmp2 : list retokenize __tmp2
global EXTRA_OUTCOME "`__tmp2'"
local __tmp3 "${FE_TREAT_VARS}"
local __tmp3 : list retokenize __tmp3
global FE_TREAT_VARS "`__tmp3'"
local __tmp4 "${FE_OUTCOME_VARS}"
local __tmp4 : list retokenize __tmp4
global FE_OUTCOME_VARS "`__tmp4'"

if (${DEBUG_XSETS}==1) {
    di as text "---- X switches ----"
    di as text "EXTRA_TREAT   = |${EXTRA_TREAT}|"
    di as text "EXTRA_OUTCOME = |${EXTRA_OUTCOME}|"
    di as text "FE_TREAT_VARS = |${FE_TREAT_VARS}|"
    di as text "FE_OUTCOME_VARS = |${FE_OUTCOME_VARS}|"
}

*========================
* 5) Covariables candidatas (GLOBAL) + L1_ (si USE_LAGS=1)
*========================
* Base (mínimo) — ajustá nombres a tu base
global BASEVARS_CORE edad capital_extranjero share_prof_tecn exp_dummy ln_tpo_mean indice_redes
* BASEVARS (tratamiento) = core + FE según switches
global BASEVARS ${BASEVARS_CORE} ${FE_TREAT_VARS} ${EXTRA_TREAT}
* Opcionales (agregás 1 por vez) — ajustá a tu gusto
global ADD1 // indice_redes
global ADD2  // indice_obstaculos // ojo, no usar si el GLOBAL USE LAG esta en 0.
global ADD3  apoyo_publico  
global ADD4  grupo_economico 

* "exporta_mean" puede ser sustituto de "exp_dummy"
* "share_stem" puede ser sustituto de "share_prof_tecn"
* "ln_ing_ventas_mean" puede ser sustituo de "ln_tpo_mean"
*  "indice_obstaculos" solo usar rezagado

*========================
* 5.b) Covariables del modelo de outcome (GLOBAL)
*========================
* Por defecto, el outcome model usa las mismas X que el treatment model (Xbase de la spec).
* Si querés cambiar eso sin romper el flujo:
*   - YMODEL_SAME_AS_TREAT = 1  -> X_y = Xbase  (+ Y_EXTRAVARS)
*   - YMODEL_SAME_AS_TREAT = 0  -> X_y se arma con Y_BASEVARS + Y_ADDVARS (+ Y_EXTRAVARS)

global YMODEL_SAME_AS_TREAT 0
* Y_BASEVARS (outcome) = core + FE según switches (si YMODEL_SAME_AS_TREAT==0)
global Y_BASEVARS ${BASEVARS_CORE} ${FE_OUTCOME_VARS} ${EXTRA_OUTCOME}
global Y_ADDVARS   org1 org_miss // con lag quitar a "org_miss"
global Y_EXTRAVARS // ln_inten_invpo_mean // ojo, no usar si el GLOBAL USE LAG esta en 0.



*========================
* 3) Restricción central: innovadores + outcome observado
*========================
keep if b1_9==1
*keep if macro_sector==1

cap drop Y_cond
gen byte Y_cond = inlist(resul_mejora_ambiente,1,2) if !missing(resul_mejora_ambiente)
drop if missing(Y_cond)

label var Y_cond "Y (cond): mejora amb media/alta entre innovadores"

di as text "--------------------------------------------"
di as text "Diagnóstico (muestra b1_9==1 con Y_cond observado)"
tab Y_cond, missing
di as text "--------------------------------------------"

*========================
* 4) Tratamiento prod/proc (estado) + organización (auxiliares)
*========================

* Tratamiento base (ignora org en definición)
cap drop D_pp_ignore
gen byte D_pp_ignore = .
replace D_pp_ignore = 0 if innova_producto==0 & innova_proceso==0
replace D_pp_ignore = 1 if innova_producto==1 & innova_proceso==0
replace D_pp_ignore = 2 if innova_producto==0 & innova_proceso==1
replace D_pp_ignore = 3 if innova_producto==1 & innova_proceso==1

label define Dpp 0 "No prod/proc" 1 "Solo producto" 2 "Solo proceso" 3 "Ambas", replace
label values D_pp_ignore Dpp
label var D_pp_ignore "D (estado): prod/proc/ambas (ignora org)"

* Auxiliares de org (para controles)
cap drop org1 org_miss
gen byte org1 = (innova_organiz_comerc==1) if !missing(innova_organiz_comerc)
replace org1 = 0 if missing(org1)
gen byte org_miss = missing(innova_organiz_comerc)

label var org1     "Org/comerc=1 (missing->0)"
label var org_miss "Org/comerc missing"

* Modo estricto: excluir org==1 y org missing
cap drop D_pp_strict
gen byte D_pp_strict = D_pp_ignore
replace D_pp_strict = . if innova_organiz_comerc==1
replace D_pp_strict = . if missing(innova_organiz_comerc)
label values D_pp_strict Dpp
label var D_pp_strict "D (estado): prod/proc/ambas (excluye org1 y org_miss)"

di as text "Distribución D_pp_ignore:"
tab D_pp_ignore, missing
di as text "Distribución D_pp_strict (incluye missings por exclusión):"
tab D_pp_strict, missing


* Por las dudas: fuerza delimitador "normal"
#delimit cr

if $USE_LAGS == 1 {

    * Crear L1_ para TODAS las covariables "laggeables" (no incluye FE dummies)
    local Xlist ${BASEVARS_CORE} ${ADD1} ${ADD2} ${ADD3} ${ADD4} ${Y_ADDVARS} ${Y_EXTRAVARS} ${EXTRA_TREAT} ${EXTRA_OUTCOME}
    local Xlist : list uniq Xlist

    foreach v of local Xlist {
        * Solo si existe y es numérica
        capture confirm numeric variable `v'
        if !_rc {
            capture drop L1_`v'
            gen double L1_`v' = L1.`v'
        }
    }
}


* (b) Helper: construir lista X usando L1_ cuando existe, si no usar contemporánea
*========================
* FIX ROBUSTO: build_xlist
*========================
cap program drop build_xlist
program define build_xlist, rclass
    version 19.0
    syntax , BASE(string asis) [ADD(string asis)]

    * 1) Normalizar whitespace Unicode -> espacio (incluye NBSP, tabs, CR/LF, etc.)
    local base_clean = ustrregexra("`base'", "[[:space:]]+", " ")
    local add_clean  = ustrregexra("`add'",  "[[:space:]]+", " ")

    local base_clean = itrim(trim("`base_clean'"))
    local add_clean  = itrim(trim("`add_clean'"))

    if ("`base_clean'"=="") {
        di as error "build_xlist: BASE() vacío (no hay covariables base)."
        return local xlist ""
        return local skipped ""
        exit 198
    }

    * 2) Retokenizar como listas
    local basevars : list retokenize base_clean
    local addvars  : list retokenize add_clean

    * 3) Elegir L1_ si existe y tiene algún non-missing; si no, contemporánea.
    local x ""
    local skipped ""

    foreach v of local basevars {
        local chosen ""

        * Solo numéricas
        capture confirm numeric variable `v'
        if (_rc) {
            local skipped "`skipped' `v'(non_numeric_or_missing_var)"
            continue
        }

        if ($USE_LAGS==1) {
            capture confirm numeric variable L1_`v'
            if (!_rc) {
                quietly count if !missing(L1_`v')
                if (r(N)>0) local chosen "L1_`v'"
            }
        }

        if ("`chosen'"=="") {
            quietly count if !missing(`v')
            if (r(N)>0) local chosen "`v'"
        }

        if ("`chosen'"!="") local x "`x' `chosen'"
        else local skipped "`skipped' `v'(all_missing_in_sample)"
    }

    foreach v of local addvars {
        if ("`v'"=="") continue
        local chosen ""

        capture confirm numeric variable `v'
        if (_rc) {
            local skipped "`skipped' `v'(non_numeric_or_missing_var)"
            continue
        }

        if ($USE_LAGS==1) {
            capture confirm numeric variable L1_`v'
            if (!_rc) {
                quietly count if !missing(L1_`v')
                if (r(N)>0) local chosen "L1_`v'"
            }
        }

        if ("`chosen'"=="") {
            quietly count if !missing(`v')
            if (r(N)>0) local chosen "`v'"
        }

        if ("`chosen'"!="") local x "`x' `chosen'"
        else local skipped "`skipped' `v'(all_missing_in_sample)"
    }

    local x : list retokenize x

    if ("`x'"=="") {
        di as error "build_xlist: NO quedó ninguna covariable usable (todas inexistentes/no numéricas/todo missing)."
        di as error "BASE limpio: |`base_clean'|"
        di as error "ADD  limpio: |`add_clean'|"
        di as error "SKIPPED: `skipped'"
        return local xlist ""
        return local skipped "`skipped'"
        exit 498
    }

    return local xlist "`x'"
    return local skipped "`skipped'"
end

macro list BASEVARS
di as result "BASEVARS=|${BASEVARS}|"

*========================
*========================
* 5.c) Construir specs candidatas (X del tratamiento)
*========================
* Nota: estas specs SOLO afectan el mlogit del tratamiento + métricas de balance.
* El outcome model se arma aparte (YMODEL_* + Y_* + EXTRA_OUTCOME).

if (${DEBUG_XSETS}==1) {
    di as text "BASEVARS (treat) = |${BASEVARS}|"
    di as text "EXTRA_TREAT      = |${EXTRA_TREAT}|"
    di as text "FE_TREAT_VARS    = |${FE_TREAT_VARS}|"
}

quietly build_xlist, base(${BASEVARS}) add("")
global X_S1 "`r(xlist)'"

quietly build_xlist, base(${BASEVARS}) add(${ADD1})
global X_S2 "`r(xlist)'"

quietly build_xlist, base(${BASEVARS}) add(${ADD1} ${ADD2})
global X_S3 "`r(xlist)'"

quietly build_xlist, base(${BASEVARS}) add(${ADD1} ${ADD2} ${ADD3})
global X_S4 "`r(xlist)'"

quietly build_xlist, base(${BASEVARS}) add(${ADD1} ${ADD2} ${ADD3} ${ADD4})
global X_S5 "`r(xlist)'"

di as text "--------------------------------------------"
di as text "Specs candidatas (treatment X):"
di as text "S1: ${X_S1}"
di as text "S2: ${X_S2}"
di as text "S3: ${X_S3}"
di as text "S4: ${X_S4}"
di as text "S5: ${X_S5}"
di as text "USE_LAGS = ${USE_LAGS}"
di as text "INCLUDE_ORG_CONTROLS = ${INCLUDE_ORG_CONTROLS} | ORG_IN_YMODEL = ${ORG_IN_YMODEL}"
di as text "--------------------------------------------"


tempfile base_data
save `base_data', replace

*========================
* 6) Programa: evalúa diseño (mlogit) y métricas por tlevel
*========================
cap program drop eval_design
program define eval_design
    version 19.0
    syntax , HANDLE(name) DVAR(name) XLIST(string asis) MODE(string) SPEC(string)

    *--- Guardar dataset original (para dejar todo como estaba al salir)
    tempfile __orig __work
    quietly save `__orig', replace

    *--- Trabajar en una copia (sin preserve)
    keep if inlist(`dvar',0,1,2,3)

    * --- sanitizar xlist: sacar comillas y normalizar espacios ---
    local xvars `"`xlist'"'
    local xvars : subinstr local xvars `"""' "", all
    local xvars = ustrregexra("`xvars'", "[[:space:]]+", " ")
    local xvars = itrim(trim("`xvars'"))

    * --- limpiar covariables 100% missing / inexistentes ---
    local xkeep ""
    foreach x of local xvars {
        capture confirm variable `x'
        if (_rc) continue

        quietly count if !missing(`x')
        if (r(N)>0) local xkeep "`xkeep' `x'"
        else di as error "Mode=`mode' Spec=`spec': covariable `x' es TODO missing -> la saco."
    }

    local xkeep : list retokenize xkeep
    if ("`xkeep'"=="") {
        di as error "Mode=`mode' Spec=`spec': X quedó vacío (no hay covariables con datos) -> salteo."
        use `__orig', clear
        exit
    }

    * Listwise deletion sobre X usable
    egen byte __missX = rowmiss(`xkeep')
    drop if __missX>0
    drop __missX

    quietly count
    local N_used = r(N)
    if (`N_used' < ${MIN_N_USED}) {
        di as error "Muy poca muestra para Mode=`mode' Spec=`spec' (N=`N_used'). Salteo."
        use `__orig', clear
        exit
    }

    local xvars "`xkeep'"

    * Estimar mlogit del tratamiento
    quietly capture mlogit `dvar' `xvars', baseoutcome(0) nolog
    if (_rc) {
        di as error "FALLÓ mlogit para Mode=`mode' Spec=`spec' (separación/colinealidad/celdas vacías)."
        use `__orig', clear
        exit
    }

    tempvar p0 p1 p2 p3
    quietly predict double `p0', outcome(0)
    quietly predict double `p1', outcome(1)
    quietly predict double `p2', outcome(2)
    quietly predict double `p3', outcome(3)

    * Guardar dataset de trabajo (ya con p0..p3)
    quietly save `__work', replace
	
	* check
    * (debug desactivado)
    * summ `p0' if `dvar'==0, detail
    * summ `p`t'' if `dvar'==0, detail
    * summ `w' if `dvar'==0, detail
    * di as result "N0=`N0'  sumw=`sumw'  sumw2=`sumw2'  ESS0=`ESS0'"
    * Loop por comparación (t vs 0) sin preserve
    forvalues t = 1/3 {
        use `__work', clear
        keep if inlist(`dvar',0,`t')

        tempvar w w2 bad_w
        gen double `w' = .
        replace `w' = 1 if `dvar'==`t'
        replace `w' = (`p`t''/`p0') if `dvar'==0

        gen byte `bad_w' = (`dvar'==0 & (`p0'<=${P0_FLOOR} | missing(`w') | `w'>${W_CEIL}))
        drop if `bad_w'==1

        quietly count if `dvar'==`t'
        local N1 = r(N)
        quietly count if `dvar'==0
        local N0 = r(N)

        * ESS0
        quietly summarize `w' if `dvar'==0, meanonly
        local sumw = r(sum)
        gen double `w2' = `w'^2 if `dvar'==0
        quietly summarize `w2' if `dvar'==0, meanonly
        local sumw2 = r(sum)
        local ESS0 = .
        if (`sumw2' > 0 & `sumw2' < .) local ESS0 = (`sumw'^2)/`sumw2'

        * Concentración de pesos
        quietly summarize `w' if `dvar'==0, detail
        local w_p95 = r(p95)
        local w_p99 = r(p99)
        local w_max = r(max)

        * Balance
        local maxSMD = 0
        local sumAbs = 0
        local k = 0
        local maxLogVR = 0

        foreach x of local xvars {
            quietly summarize `x' if `dvar'==`t'
            local mt = r(mean)
            local vt = r(Var)

            quietly summarize `x' [aw=`w'] if `dvar'==0
            local mc = r(mean)
            local vc = r(Var)

            local sdpool = .
            if (`vt' < . & `vc' < .) local sdpool = sqrt((`vt' + `vc')/2)

            if (`sdpool' > 0 & `sdpool' < .) {
                local smd = (`mt' - `mc')/`sdpool'
                local abssmd = abs(`smd')
                if (`abssmd' > `maxSMD') local maxSMD = `abssmd'
                local sumAbs = `sumAbs' + `abssmd'
                local ++k

                if (`vt' > 0 & `vc' > 0 & `vt' < . & `vc' < .) {
                    local logvr = abs(log(`vc'/`vt'))
                    if (`logvr' > `maxLogVR') local maxLogVR = `logvr'
                }
            }
        }

        local meanSMD = .
        if (`k' > 0) local meanSMD = `sumAbs'/`k'
		
		
        post `handle' ("`mode'") ("`spec'") (`t') (`N1') (`N0') (`ESS0') ///
            (`maxSMD') (`meanSMD') (`maxLogVR') (`w_p95') (`w_p99') (`w_max') (`N_used') 
    }

    * Volver a como estaba el dataset original
    use `__orig', clear
end




*========================
* 6B) Programa: evalúa diseño con pesos ATET tipo teffects (comparables con ipwra)
*     Idea: para cada comparación (t vs 0), los pesos de controles son w = p_t/p_0
*     (y los tratados t tienen peso 1). Esto replica la lógica de ATET por IPW
*     que usa teffects; además, normalizamos w en controles para que mean(w|D=0)=1
*     cuando computamos percentiles/max de pesos (comparabilidad entre specs).
*========================
cap program drop eval_design_tew
program define eval_design_tew
    version 19.0
    syntax , HANDLE(name) DVAR(name) XLIST(string asis) MODE(string) SPEC(string)

    *--- Guardar dataset original (para dejar todo como estaba al salir)
    tempfile __orig __work
    quietly save `__orig', replace

    *--- Trabajar en una copia (sin preserve)
    keep if inlist(`dvar',0,1,2,3)

    * --- sanitizar xlist: sacar comillas y normalizar espacios ---
    local xvars `"`xlist'"'
    local xvars : subinstr local xvars `"""' "", all
    local xvars = ustrregexra("`xvars'", "[[:space:]]+", " ")
    local xvars = itrim(trim("`xvars'"))

    * --- limpiar covariables 100% missing / inexistentes ---
    local xkeep ""
    foreach x of local xvars {
        capture confirm variable `x'
        if (_rc) continue

        quietly count if !missing(`x')
        if (r(N)>0) local xkeep "`xkeep' `x'"
        else di as error "Mode=`mode' Spec=`spec': covariable `x' es TODO missing -> la saco."
    }

    local xkeep : list retokenize xkeep
    if ("`xkeep'"=="") {
        di as error "Mode=`mode' Spec=`spec': X quedó vacío (no hay covariables con datos) -> salteo."
        use `__orig', clear
        exit
    }

    * Listwise deletion sobre X usable (alineado con teffects)
    egen byte __missX = rowmiss(`xkeep')
    drop if __missX>0
    drop __missX

    quietly count
    local N_used = r(N)
    if (`N_used' < ${MIN_N_USED}) {
        di as error "Muy poca muestra para Mode=`mode' Spec=`spec' (N=`N_used'). Salteo."
        use `__orig', clear
        exit
    }

    local xvars "`xkeep'"

    * Estimar mlogit del tratamiento (mismo diseño que la corrida final multivaluada)
    quietly capture mlogit `dvar' `xvars', baseoutcome(0) nolog
    if (_rc) {
        di as error "FALLÓ mlogit para Mode=`mode' Spec=`spec' (separación/colinealidad/celdas vacías)."
        use `__orig', clear
        exit
    }

    tempvar p0 p1 p2 p3
    quietly predict double `p0', outcome(0)
    quietly predict double `p1', outcome(1)
    quietly predict double `p2', outcome(2)
    quietly predict double `p3', outcome(3)

    * Guardar dataset de trabajo (ya con p0..p3)
    quietly save `__work', replace

    local WTRIM = upper("${W_TRIM_STYLE}")
    local do_ps_trim = ${PS_TRIM}
    local ps_low  = ${PS0_LOW}
    local ps_high = ${PS0_HIGH}

    * Loop por comparación (t vs 0)
    forvalues t = 1/3 {
        use `__work', clear
        keep if inlist(`dvar',0,`t')

        * Tamaños antes de recortes (para reportar shares)
        quietly count if `dvar'==`t'
        local N1_init = r(N)
        quietly count if `dvar'==0
        local N0_init = r(N)

        tempvar w_raw w w2 flag_p0_ctrl flag_p0_tr flag_ps flag_wceil

        * Reglas explícitas de overlap (p0=Pr(D=0|X))
        gen byte `flag_p0_ctrl' = (`p0'<=${P0_FLOOR} | missing(`p0')) if `dvar'==0
        gen byte `flag_p0_tr'   = (`p0'<=${P0_TREAT_FLOOR} | missing(`p0')) if `dvar'==`t'

        gen byte `flag_ps' = 0
        if (`do_ps_trim'==1) {
            replace `flag_ps' = (`p0'<`ps_low' | `p0'>`ps_high') if inlist(`dvar',0,`t')
        }

        quietly count if `dvar'==0 & `flag_p0_ctrl'==1
        local drop_p0_ctrl = r(N)
        quietly count if `dvar'==`t' & `flag_p0_tr'==1
        local drop_p0_tr   = r(N)
        quietly count if `flag_ps'==1
        local drop_ps_all  = r(N)

        drop if (`dvar'==0 & `flag_p0_ctrl'==1) | (`dvar'==`t' & `flag_p0_tr'==1) | (`flag_ps'==1)

        * Pesos tipo ATET(t vs 0):
        *   tratados (D=t): 1
        *   controles (D=0): p_t / p_0
        gen double `w_raw' = .
        replace `w_raw' = 1 if `dvar'==`t'
        replace `w_raw' = (`p`t''/`p0') if `dvar'==0

        * Corte duro de seguridad (explosión numérica / indefinido)
        gen byte `flag_wceil' = (`dvar'==0 & (missing(`w_raw') | `w_raw'<=0 | `w_raw'>${W_CEIL}))
        quietly count if `flag_wceil'==1
        local drop_wceil = r(N)
        drop if `flag_wceil'==1

        * --- Trimming por cuantiles (controles): CAP (winsorizar) o DROP (eliminar) ---
        local w_cap = .
        local share_trim = .
        quietly count if `dvar'==0
        local N0_for_trim = r(N)

        if (`N0_for_trim' > 0 & ${W_CAP_Q} < .) {
            local pct = 100*${W_CAP_Q}
            quietly centile `w_raw' if `dvar'==0, centile(`pct')
            local w_cap = r(c_1)

            if (`w_cap' < . & `w_cap' > 0) {
                quietly count if `dvar'==0 & `w_raw' > `w_cap'
                local n_trim = r(N)
                local share_trim = `n_trim'/`N0_for_trim'

                if ("`WTRIM'"=="CAP") {
                    replace `w_raw' = `w_cap' if `dvar'==0 & `w_raw' > `w_cap'
                }
                else if ("`WTRIM'"=="DROP") {
                    drop if `dvar'==0 & `w_raw' > `w_cap'
                }
            }
        }

        * Normalizar solo controles para reportar percentiles/máximo comparables:
        * mean(w|D=0)=1  (SMD/VR/ESS son invariantes a escala, pero p99/max no)
        gen double `w' = `w_raw'
        quietly summarize `w' if `dvar'==0, meanonly
        local mw0 = r(mean)
        if (`mw0' > 0 & `mw0' < .) {
            replace `w' = `w_raw'/`mw0' if `dvar'==0
        }

        quietly count if `dvar'==`t'
        local N1 = r(N)
        quietly count if `dvar'==0
        local N0 = r(N)

        * ESS0 (solo controles; invariante a escala)
        quietly summarize `w' if `dvar'==0, meanonly
        local sumw = r(sum)

        gen double `w2' = `w'^2 if `dvar'==0
        quietly summarize `w2' if `dvar'==0, meanonly
        local sumw2 = r(sum)

        local ESS0 = .
        if (`sumw2' > 0 & `sumw2' < .) local ESS0 = (`sumw'^2)/`sumw2'

        * Concentración de pesos (controles; ya normalizados)
        quietly summarize `w' if `dvar'==0, detail
        local w_p95 = r(p95)
        local w_p99 = r(p99)
        local w_max = r(max)

        * Overlap (rangos de p0)
        quietly summarize `p0' if `dvar'==`t', detail
        local p0_t_min = r(min)
        local p0_t_max = r(max)
        quietly summarize `p0' if `dvar'==0, detail
        local p0_0_min = r(min)
        local p0_0_max = r(max)

        * Balance: SMD y ratio de varianzas (en log abs)
        local maxSMD = 0
        local sumAbs = 0
        local k = 0
        local maxLogVR = 0
		
		local maxAbsVar ""
		local maxLogVRVar ""

		foreach x of local xvars {
			quietly summarize `x' if `dvar'==`t'
			local mt = r(mean)
			local vt = r(Var)

			quietly summarize `x' [iw=`w'] if `dvar'==0
			local mc = r(mean)
			local vc = r(Var)

			local sdpool = .
			if (`vt' < . & `vc' < .) local sdpool = sqrt((`vt' + `vc')/2)

			if (`sdpool' > 0 & `sdpool' < .) {
				local smd    = (`mt' - `mc')/`sdpool'
				local abssmd = abs(`smd')

				if (`abssmd' > `maxSMD') {
					local maxSMD    = `abssmd'
					local maxAbsVar "`x'"
				}

				local sumAbs = `sumAbs' + `abssmd'
				local ++k

				if (`vt' > 0 & `vc' > 0 & `vt' < . & `vc' < .) {
					local logvr = abs(log(`vc'/`vt'))
					if (`logvr' > `maxLogVR') {
						local maxLogVR    = `logvr'
						local maxLogVRVar "`x'"
					}
				}
			}
		}

        local meanSMD = .
        if (`k' > 0) local meanSMD = `sumAbs'/`k'

		local col_wsd "`maxAbsVar'"
        local col_wvr "`maxLogVRVar'"
		
        local share_drop_p0_ctrl = cond(`N0_init'>0, `drop_p0_ctrl'/`N0_init', .)
        local share_drop_p0_tr   = cond(`N1_init'>0, `drop_p0_tr'/`N1_init', .)
        local share_drop_ps      = cond((`N0_init'+`N1_init')>0, `drop_ps_all'/(`N0_init'+`N1_init'), .)
        local share_drop_wceil   = cond((`N0_init'+`N1_init')>0, `drop_wceil'/(`N0_init'+`N1_init'), .)

        post `handle' ("`mode'") ("`spec'") (`t') ///
            (`N1') (`N0') (`ESS0') ///
            (`maxSMD') (`meanSMD') (`maxLogVR') ///
            (`w_p95') (`w_p99') (`w_max') (`N_used') ///
            (`w_cap') (`share_trim') (`share_drop_p0_ctrl') (`share_drop_p0_tr') (`share_drop_ps') (`share_drop_wceil') ///
            (`p0_t_min') (`p0_t_max') (`p0_0_min') (`p0_0_max')  ("`col_wsd'") ("`col_wvr'")
    }

    * Volver a como estaba el dataset original
    use `__orig', clear
end


*----------------------------
*----------------------------
* 4) Evaluación "benchmark" (MULTINOMIAL) para balance del diseño IPWRA
*
* IDEA (alineada con el manual .tex):
*   - Como D es multi-valued (0,1,2,3), el modelo correcto de propensión es MULTINOMIAL (mlogit).
*   - Estimamos una sola vez p_j(X)=Pr(D=j|X) con baseoutcome(0) usando X del treatment model (XTR).
*   - Para cada contraste t vs 0 (t=1,2,3), armamos pesos ATET en controles:
*         w0_i = p_t(X_i) / p_0(X_i)     si D_i=0
*         w1_i = 1                      si D_i=t
*     (Luego normalizamos w0 para que E[w0|D=0]=1; esto NO cambia SMD ni el ATET tipo Hájek.)
*   - Calculamos métricas de balance sobre el set UNION(XTR, XY) para reflejar el diseño IPWRA,
*
*----------------------------

capture program drop eval_design_teb
program define eval_design_teb
    version 19.0
    syntax , HANDLE(name) DVAR(name) XTR(string asis) XY(string asis) MODE(string) SPEC(string)

    tempfile __orig __work
    quietly save `__orig', replace

    keep if inlist(`dvar',0,1,2,3)

    *----------------------------
    * 4.1) Sanitizar listas + filtrar covariables "vacías"
    *----------------------------
    local xtrvars `"`xtr'"'
    local xyvars  `"`xy'"'

    local xtrvars : subinstr local xtrvars `"""' "" , all
    local xyvars  : subinstr local xyvars  `"""' "" , all

    local xtrvars = ustrregexra("`xtrvars'", "[[:space:]]+", " ")
    local xyvars  = ustrregexra("`xyvars'",  "[[:space:]]+", " ")
    local xtrvars = itrim(trim("`xtrvars'"))
    local xyvars  = itrim(trim("`xyvars'"))

    local xtr_keep ""
    foreach x of local xtrvars {
        capture confirm variable `x'
        if (_rc) continue
        quietly count if !missing(`x')
        if (r(N)>0) local xtr_keep "`xtr_keep' `x'"
        else di as error "Mode=`mode' Spec=`spec': covariable (XTR) `x' es TODO missing -> la saco."
    }

    local xy_keep ""
    foreach x of local xyvars {
        capture confirm variable `x'
        if (_rc) continue
        quietly count if !missing(`x')
        if (r(N)>0) local xy_keep "`xy_keep' `x'"
        else di as error "Mode=`mode' Spec=`spec': covariable (XY) `x' es TODO missing -> la saco."
    }

    local xtr_keep : list retokenize xtr_keep
    local xy_keep  : list retokenize xy_keep

    if ("`xtr_keep'"=="") {
        di as error "Mode=`mode' Spec=`spec': XTR quedó vacío -> salteo benchmark."
        forvalues t=1/3 {
            quietly count if `dvar'==`t'
            local N1 = r(N)
            quietly count if `dvar'==0
            local N0 = r(N)
            post `handle' ("`mode'") ("`spec'") (`t') (`N1') (`N0') (.) (.) (.) (.) (.) (.) (.) ///
                (`N1'+`N0') (.) (.) (.) (.) (.) (.) (.) (0) ("") ("")
        }
        use `__orig', clear
        exit
    }

    * UNION(XTR,XY) para balance (IPWRA permite X distintos en TM y YM)
    local x_all "`xtr_keep' `xy_keep'"
    local x_all : list uniq x_all

    * Listwise deletion en X_all (alineado con lo que haría teffects en práctica)
	* Primera diferencia importante con el programa anterior: impone una muestra mas exigente porque si hay variables solo en el modelo para Y que tienen mucho missing, elimina estas observaciones.
	* Luego el modelo multinomial para el tratamiento lo estima sobre esta muestra resultante, mas exigente.
	
    egen byte __missX = rowmiss(`x_all')
    drop if __missX>0
    drop __missX

    quietly count
    local N_used0 = r(N)
    if (`N_used0' < ${MIN_N_USED}) {
        di as error "Muy poca muestra para Mode=`mode' Spec=`spec' (N=`N_used0'). Salteo benchmark."
        forvalues t=1/3 {
            quietly count if `dvar'==`t'
            local N1 = r(N)
            quietly count if `dvar'==0
            local N0 = r(N)
            post `handle' ("`mode'") ("`spec'") (`t') (`N1') (`N0') (.) (.) (.) (.) (.) (.) (.) ///
                (`N1'+`N0') (.) (.) (.) (.) (.) (.) (.) (0) ("") ("")
        }
        use `__orig', clear
        exit
    }

    *----------------------------
    * 4.2) Propensiones MULTINOMIALES (mlogit) – tratamiento model
    *----------------------------
    quietly capture mlogit `dvar' `xtr_keep', baseoutcome(0) nolog
    if (_rc) {
        di as error "Mode=`mode' Spec=`spec': FALLÓ mlogit (multinomial) del tratamiento."
        forvalues t=1/3 {
            quietly count if `dvar'==`t'
            local N1 = r(N)
            quietly count if `dvar'==0
            local N0 = r(N)
            post `handle' ("`mode'") ("`spec'") (`t') (`N1') (`N0') (.) (.) (.) (.) (.) (.) (.) ///
                (`N1'+`N0') (.) (.) (.) (.) (.) (.) (.) (0) ("") ("")
        }
        use `__orig', clear
        exit
    }

    tempvar p0 p1 p2 p3
    quietly predict double `p0', outcome(0)
    quietly predict double `p1', outcome(1)
    quietly predict double `p2', outcome(2)
    quietly predict double `p3', outcome(3)

    quietly save `__work', replace

    local WTRIM = upper("${W_TRIM_STYLE}")
    local do_ps_trim = ${PS_TRIM}
    local ps_low  = ${PS0_LOW}
    local ps_high = ${PS0_HIGH}

    *----------------------------
    * 4.3) Para cada t vs 0: pesos ATET + métricas (ESS0/pesos/overlap)
    *----------------------------
    forvalues t=1/3 {
        use `__work', clear
        keep if inlist(`dvar',0,`t')

        quietly count if `dvar'==`t'
        local N1_init = r(N)
        quietly count if `dvar'==0
        local N0_init = r(N)
        local N_all_init = `N1_init' + `N0_init'

        tempvar w_raw w w2 bad_ctrl bad_tr bad_ps bad_wceil
        gen byte `bad_ctrl' = (`dvar'==0 & (`p0'<=${P0_FLOOR} | missing(`p0')))
        gen byte `bad_tr'   = (`dvar'==`t' & (`p0'<=${P0_TREAT_FLOOR} | missing(`p0')))

        gen byte `bad_ps' = 0
        if (`do_ps_trim'==1) {
            replace `bad_ps' = (`p0'<`ps_low' | `p0'>`ps_high') if inlist(`dvar',0,`t')
        }

        drop if `bad_ctrl' | `bad_tr' | `bad_ps'

        gen double `w_raw' = .
        replace `w_raw' = 1 if `dvar'==`t'
        replace `w_raw' = (`p`t''/`p0') if `dvar'==0

        gen byte `bad_wceil' = (`dvar'==0 & (missing(`w_raw') | `w_raw'<=0 | `w_raw'>${W_CEIL}))
        drop if `bad_wceil'

        * Trimming por cuantil (solo controles)
        local w_cap = .
        quietly count if `dvar'==0
        local N0_for_trim = r(N)

        if (`N0_for_trim' > 0 & ${W_CAP_Q} < .) {
            local pct = 100*${W_CAP_Q}
            quietly centile `w_raw' if `dvar'==0, centile(`pct')
            local w_cap = r(c_1)

            if (`w_cap' < . & `w_cap' > 0) {
                if ("`WTRIM'"=="CAP") {
                    replace `w_raw' = `w_cap' if `dvar'==0 & `w_raw' > `w_cap'
                }
                else if ("`WTRIM'"=="DROP") {
                    drop if `dvar'==0 & `w_raw' > `w_cap'
                }
            }
        }

        * Normalizar controles a media 1 (no cambia SMD/ATET tipo Hájek). Sirve para comparar pesos de diferentes especificaciones.
        gen double `w' = `w_raw'
        quietly summarize `w' if `dvar'==0, meanonly
        local mw0 = r(mean)
        if (`mw0'>0 & `mw0'<.) replace `w' = `w_raw'/`mw0' if `dvar'==0

        quietly count if `dvar'==`t'
        local N1 = r(N)
        quietly count if `dvar'==0 & `w' < .
        local N0 = r(N)
        local N_used = `N1' + `N0'

        * Share "excluida" por overlap/trimming (sustituye osample())
        local share_os_all = .
        local share_os_1 = .
        local share_os_0 = .
        if (`N_all_init'>0) local share_os_all = 1 - (`N_used'/`N_all_init')
        if (`N1_init'>0)   local share_os_1   = 1 - (`N1'/`N1_init')
        if (`N0_init'>0)   local share_os_0   = 1 - (`N0'/`N0_init')

        * Estadísticos de pesos en controles
        quietly summarize `w' if `dvar'==0, detail
        local w_p95 = r(p95)
        local w_p99 = r(p99)
        local w_max = r(max)

        * ESS0 en controles: (sum w)^2 / sum(w^2)
        quietly summarize `w' if `dvar'==0, meanonly
        local sumw = r(sum)
        gen double `w2' = `w'^2 if `dvar'==0
        quietly summarize `w2' if `dvar'==0, meanonly
        local sumw2 = r(sum)

        local ESS0 = .
        if (`sumw2'>0 & `sumw2'<.) local ESS0 = (`sumw'^2)/`sumw2'

        * Overlap: rango de p0 en tratados y controles (post-filtros)
        quietly summarize `p0' if `dvar'==`t', detail
        local p0_t_min = r(min)
        local p0_t_max = r(max)

        quietly summarize `p0' if `dvar'==0, detail
        local p0_0_min = r(min)
        local p0_0_max = r(max)

        *----------------------------
        * 4.4) Balance: SMD + max|log(VR)| sobre UNION(XTR,XY)
        *----------------------------
		* 2SEGUNDA DIFERENCIA respecto al progrma anterior: ahora el balance lo ejecuta tambien para las covariables que pudieran formar parte solo del modelo para Y. 
		* esto podria hacer que se castigue una especificacion por una variable en modelo Y que tenga pesimo SMD, pero si no forma parte del modelo de tratamiento, lo castiga igual. 
		* (Discutible decision!).
		
        local xbal "`x_all'"

        local k=0
        local sumAbs=0
        local maxAbs=-1
        local maxAbsVar ""
        local maxLogVR=-1
        local maxLogVRVar ""
        local has_vr=0

        foreach x of local xbal {
            capture confirm variable `x'
            if (_rc) continue

            quietly summarize `x' if `dvar'==`t'
            local m1=r(mean)
            local v1=r(Var)

            * Controles: media ponderada
            quietly summarize `x' [iw=`w'] if `dvar'==0
            local m0=r(mean)

            * Controles: varianza ponderada (alineada con tebalance)
            *   v0 = sum_i w_i (x_i - xbar_w)^2 / (sum_i w_i - 1)
            tempvar __dev __wdev
            quietly gen double `__dev'  = (`x' - `m0')^2 if `dvar'==0 & `w' < . & !missing(`x')
            quietly gen double `__wdev' = `w' * `__dev'  if `dvar'==0 & `w' < . & !missing(`x')

            quietly summarize `w' if `dvar'==0 & `w' < .
            local sumw = r(sum)

            quietly summarize `__wdev' if `dvar'==0 & !missing(`__wdev')
            local sumwdev = r(sum)

            local v0 = .
            if (`sumw' > 1) local v0 = `sumwdev' / (`sumw' - 1)

            quietly drop `__dev' `__wdev'

            local denom = sqrt((`v1'+`v0')/2)
            if (`denom'>0 & `denom'<.) {
                local smd = (`m1' - `m0')/`denom'
                local a = abs(`smd')
                local k = `k' + 1
                local sumAbs = `sumAbs' + `a'
                if (`a' > `maxAbs') {
                    local maxAbs = `a'
                    local maxAbsVar "`x'"
                }
            }

            if (`v0'>0 & `v1'>0 & `v0'<. & `v1'<.) {
                local lv = abs(log(`v1'/`v0'))   // equivalente a abs(log(VR))
                if (`lv' > `maxLogVR') {
                    local maxLogVR = `lv'
                    local maxLogVRVar "`x'"
                }
                local has_vr = 1
            }
        }

        local maxSMD_w = .
        local meanSMD_w = .
        local maxLogVarRatio_w = .
        local parse_ok = 0

        if (`k' > 0) {
            local maxSMD_w  = `maxAbs'
            local meanSMD_w = `sumAbs'/`k'
            local parse_ok  = 1
        }
        if (`has_vr'==1) local maxLogVarRatio_w = `maxLogVR'
        local col_wsd "`maxAbsVar'"
        local col_wvr "`maxLogVRVar'"

        post `handle' ("`mode'") ("`spec'") (`t') (`N1') (`N0') (`ESS0') ///
            (`maxSMD_w') (`meanSMD_w') (`maxLogVarRatio_w') ///
            (`w_p95') (`w_p99') (`w_max') (`N_used') ///
            (`p0_t_min') (`p0_t_max') (`p0_0_min') (`p0_0_max') ///
            (`share_os_all') (`share_os_1') (`share_os_0') (`parse_ok') ("`col_wsd'") ("`col_wvr'")
    }

    use `__orig', clear
end



*========================
*========================
* 7) Ejecutar selector (2 bloques: IPW-proxy + benchmark tebalance)
*========================

tempfile design_long_ipw design_long_teb winners merged_rank
tempname H_ipw H_teb

* --- Bloque A: IPW-proxy  ---
postfile `H_ipw' str20 mode str10 spec int t ///
    double N1 N0 ESS0 maxSMD meanSMD maxLogVarRatio ///
           w_p95 w_p99 w_max N_used ///
           w_cap share_trim share_drop_p0_ctrl share_drop_p0_tr share_drop_ps share_drop_wceil ///
           p0_t_min p0_t_max p0_0_min p0_0_max ///
		   str32 col_wsd str32 col_wvr ///
    using `design_long_ipw', replace

* --- Bloque B: mas exigente ---
postfile `H_teb' str20 mode str10 spec int t ///
    double N1 N0 ESS0 maxSMD_w meanSMD_w maxLogVarRatio_w ///
           w_p95 w_p99 w_max N_used ///
           p0_t_min p0_t_max p0_0_min p0_0_max ///
           share_os_all share_os_1 share_os_0 parse_ok ///
    str32 col_wsd str32 col_wvr ///
    using `design_long_teb', replace

* -----------------------
* MODO 1: IGNORE_ORG
* -----------------------
preserve
    di as text "=== MODO: IGNORE_ORG ==="

    * Outcome y tratamiento ya fueron construidos arriba.
    capture confirm variable Y_cond
    if (_rc) {
        di as error "Falta Y_cond. Revisá el BLOQUE 3 (construcción del outcome)."
        exit 111
    }
    capture confirm variable D_pp_ignore
    if (_rc) {
        di as error "Falta D_pp_ignore. Revisá el BLOQUE 4 (construcción del tratamiento)."
        exit 111
    }

    drop if missing(Y_cond)

    local specs "S1 S2 S3 S4 S5"
    foreach spec of local specs {

        local Xbase "${X_`spec'}"

        * En IGNORE_ORG: opcionalmente agregamos org1 y org_miss como covariables
        local Xtr "`Xbase'"
        local Xy  "`Xbase'"

        if $INCLUDE_ORG_CONTROLS==1 {
            local Xtr "`Xbase' org1 org_miss"
            if $ORG_IN_YMODEL==1 {
            local Xy "`Xbase' org1 org_miss"
        }
        }

        if (${RUN_TEW}==1) {
            quietly eval_design_tew, handle(`H_ipw') dvar(D_pp_ignore) ///
                xlist("`Xtr'") mode("IGNORE_ORG") spec("`spec'")
        }

        if (${RUN_TEB}==1) {
            quietly eval_design_teb, handle(`H_teb') dvar(D_pp_ignore) ///
                xtr("`Xtr'") xy("`Xy'") mode("IGNORE_ORG") spec("`spec'")
        }
    }
restore


* -----------------------
* MODO 2: STRICT_AVOID_ORG
* -----------------------
preserve
    di as text "=== MODO: STRICT_AVOID_ORG ==="

    capture confirm variable Y_cond
    if (_rc) {
        di as error "Falta Y_cond. Revisá el BLOQUE 3 (construcción del outcome)."
        exit 111
    }
    capture confirm variable D_pp_strict
    if (_rc) {
        di as error "Falta D_pp_strict. Revisá el BLOQUE 4 (construcción del tratamiento estricto)."
        exit 111
    }

    drop if missing(Y_cond)
    drop if missing(D_pp_strict)

    local specs "S1 S2 S3 S4 S5"
    foreach spec of local specs {

        local Xbase "${X_`spec'}"

        * En STRICT se excluye org==1 y org missing; no metemos org1/org_miss como controles.
        if (${RUN_TEW}==1) {
            quietly eval_design_tew, handle(`H_ipw') dvar(D_pp_strict) ///
                xlist("`Xbase'") mode("STRICT_AVOID_ORG") spec("`spec'")
        }

        if (${RUN_TEB}==1) {
            quietly eval_design_teb, handle(`H_teb') dvar(D_pp_strict) ///
                xtr("`Xbase'") xy("`Xbase'") mode("STRICT_AVOID_ORG") spec("`spec'")
        }
    }
restore

postclose `H_ipw'
postclose `H_teb'

*========================
*========================
* 7.1) Exportar tablas largas (controlado por RUN_TEW / RUN_TEB)
*========================
if (${RUN_TEW}==1) {
    use `design_long_ipw', clear
    save "${outdir}\design_balance_long_ipw.dta", replace

    if (${SHOW_LONG_TABLES}==1) {
        di as text " "
        di as text "----- DESIGN (TEW / IPW-proxy) : primeras filas -----"
        list mode spec t N1 N0 ESS0 maxSMD meanSMD maxLogVarRatio w_p99 w_max if _n<=16, noobs
    }
}
else {
    di as text "RUN_TEW=0 -> no se exporta design_balance_long_ipw.dta (proxy IPW apagado)."
}

if (${RUN_TEB}==1) {
    use `design_long_teb', clear
    save "${outdir}\design_balance_long_teb.dta", replace

    if (${SHOW_LONG_TABLES}==1) {
        di as text " "
        di as text "----- DESIGN (TEB) : primeras filas -----"
        list mode spec t N1 N0 ESS0 maxSMD_w meanSMD_w maxLogVarRatio_w w_p99 w_max share_os_all parse_ok if _n<=16, noobs
    }
}
else {
    di as error "RUN_TEB=0 -> OJO: sin benchmark no hay ranking principal."
}


*========================
* 7.2) Agregar resumen por (mode,spec)
*     + preparar dataset base para ranking según RUN_TEB / RUN_TEW
*========================
tempfile ipw_agg teb_agg rank_base ipw_worst teb_worst

*-------------------------
* A) TEW (IPW-proxy) agregado
*-------------------------
if (${RUN_TEW}==1) {

    * (A1) rescatar col_wsd/col_wvr desde la fila peor (maxSMD) por (mode,spec)
    use `design_long_ipw', clear
    bys mode spec: egen __mx = max(maxSMD)
    keep if maxSMD==__mx
    bys mode spec: keep if _n==1
    keep mode spec col_wsd col_wvr
    save `ipw_worst', replace

    * (A2) colapsar métricas (por spec)
    use `design_long_ipw', clear
    collapse (min) minN1=N1 minN0=N0 minESS0=ESS0 minN_used=N_used ///
             (max) maxSMD=maxSMD meanSMD=meanSMD maxLogVarRatio=maxLogVarRatio ///
                   w_p95=w_p95 w_p99=w_p99 w_max=w_max ///
             , by(mode spec)

    merge 1:1 mode spec using `ipw_worst', nogen
    save `ipw_agg', replace
}

*-------------------------
* B) TEB (benchmark multinomial) agregado
*-------------------------
if (${RUN_TEB}==1) {

    * (B1) rescatar col_wsd/col_wvr desde la fila peor (maxSMD_w) por (mode,spec)
    use `design_long_teb', clear
    bys mode spec: egen __mx = max(maxSMD_w)
    keep if maxSMD_w==__mx
    bys mode spec: keep if _n==1
    keep mode spec col_wsd col_wvr
    save `teb_worst', replace

    * (B2) colapsar métricas (por spec)
    use `design_long_teb', clear
    collapse (min) minN1=N1 minN0=N0 minESS0=ESS0 minN_used=N_used min_parse_ok=parse_ok ///
             (max) maxSMD_w=maxSMD_w meanSMD_w=meanSMD_w maxLogVarRatio_w=maxLogVarRatio_w ///
                   w_p95=w_p95 w_p99=w_p99 w_max=w_max ///
                   share_os_all=share_os_all share_os_1=share_os_1 share_os_0=share_os_0 ///
             , by(mode spec)

    merge 1:1 mode spec using `teb_worst', nogen
    save `teb_agg', replace
}

*-------------------------
* C) Elegir fuente para ranking (TEW si está; si no, TEB)
*-------------------------

local RANKSRC ""
if (${RUN_TEW}==1) local RANKSRC "TEW"
else if (${RUN_TEB}==1) local RANKSRC "TEB"
else {
    di as error "RUN_TEB=0 y RUN_TEW=0: no hay nada para rankear."
    exit 498
}

if ("`RANKSRC'"=="TEB") {
    use `teb_agg', clear
    gen str3 rank_src = "TEB"
}
else {
    * Tomamos ipw_agg y lo adaptamos a los nombres "_w" que suele esperar el ranking
    use `ipw_agg', clear
    gen str3 rank_src = "TEW"

    * Crear las variables con nombres compatibles con el ranking de TEB
    gen double maxSMD_w         = maxSMD
    gen double meanSMD_w        = meanSMD
    gen double maxLogVarRatio_w = maxLogVarRatio

    gen double share_os_all = .
    gen double share_os_1   = .
    gen double share_os_0   = .

    gen double min_parse_ok = 1
}

* Chequeo: si quedó vacío, frenar con mensaje claro (evita r(2000) más abajo)
quietly count
if (r(N)==0) {
    di as error "Dataset base de ranking (`RANKSRC') quedó vacío. Revisar por qué no se posteó nada."
    exit 2000
}

save `rank_base', replace

*========================
* 7.4) Ranking y ganadores finales por modo (adaptativo TEW/TEB)
*     Fuente de ranking:
*       - si ${RUN_TEB}==1 => rank_base fue construido desde TEB (tebalance)
*       - si ${RUN_TEB}==0 => rank_base fue construido desde TEW (proxy IPW)
*     Cascada:
*       (0) soporte mínimo + parse_ok
*       (1) maxSMD_w <= 0.20
*       (2) var ratio en niveles entre [0.5, 2]  <=> VRsym <= 2, donde VRsym = exp(abs(maxLogVarRatio_w))
*       (3) entre los que pasan (1)&(2): mayor ESS0, luego pesos menos extremos; si existe share_os_all (solo TEB), menor share_os_all
*       (4) fallback cuando NO pasa VR: minimizar absLogVR, luego ESS0, luego pesos
*========================

use `rank_base', clear

* Etiqueta de fuente (solo para imprimir)
* Etiqueta de fuente (solo para imprimir)
local RANKSRC "TEB"
if (${RUN_TEW}==1) local RANKSRC "TEW"
if (${RUN_TEB}==1 & ${RUN_TEW}==1) local RANKSRC "TEW (preferido; TEB también activo)"

* Overlap existe solo si viene de TEB (pero en TEW lo generamos como missing para no romper)
local HAS_OVERLAP = 0
capture confirm variable share_os_all
if (!_rc) local HAS_OVERLAP = 1

local SMD_TOL_RANK 0.20
local VR_TOL_LEVEL 2

* Auxiliares (robustos a missings)
gen double absLogVR = abs(maxLogVarRatio_w)
gen double VRsym    = exp(absLogVR)

gen byte okSupport = (min_parse_ok>=1) ///
    & (minN1>=${MIN_N1}) & (minN0>=${MIN_N0}) ///
    & (minESS0>0) & !missing(minESS0)

gen byte okSMD = (maxSMD_w <= `SMD_TOL_RANK') if !missing(maxSMD_w)
replace okSMD = 0 if missing(okSMD)

gen byte okVar = (VRsym <= `VR_TOL_LEVEL') if !missing(VRsym)
replace okVar = 0 if missing(okVar)

gen int rank_group = .
replace rank_group = 1 if okSupport & okSMD & okVar
replace rank_group = 2 if okSupport & okSMD & !okVar
replace rank_group = 3 if okSupport & !okSMD
replace rank_group = 4 if !okSupport

* Keys para orden (menor es mejor en gsort)
gen double key1 = .
gen double key2 = .
gen double key3 = .

* Grupo 1: ESS0 alto, pesos moderados
replace key1 = -minESS0 if rank_group==1
replace key2 =  w_p99   if rank_group==1
replace key3 =  w_max   if rank_group==1

* Grupo 2: minimizar violación VR, luego ESS0 alto, luego pesos moderados
replace key1 =  absLogVR if rank_group==2
replace key2 = -minESS0  if rank_group==2
replace key3 =  w_p99    if rank_group==2

* Grupo 3: minimizar maxSMD, luego meanSMD, luego ESS0 alto
replace key1 =  maxSMD_w  if rank_group==3
replace key2 =  meanSMD_w if rank_group==3
replace key3 = -minESS0   if rank_group==3

* Grupo 4: al fondo
replace key1 = 1e12 if rank_group==4
replace key2 = 1e12 if rank_group==4
replace key3 = 1e12 if rank_group==4

* Overlap: si no existe o es missing, queda neutro (=0)
gen double overlap_sort = 0
if (`HAS_OVERLAP'==1) replace overlap_sort = share_os_all if !missing(share_os_all)

* Ranking final dentro de modo
gsort mode rank_group key1 key2 key3 overlap_sort

by mode: gen rank = _n

* Guardar ganadores (uno por modo)
preserve
    keep if rank==1
    keep mode spec rank rank_group okSupport okSMD okVar ///
         minN1 minN0 minESS0 min_parse_ok ///
         maxSMD_w meanSMD_w maxLogVarRatio_w absLogVR VRsym ///
         w_p95 w_p99 w_max ///
         share_os_all share_os_1 share_os_0 ///
         col_wsd col_wvr
    save `winners', replace
restore

di as text " "
di as result "Ganadores finales por modo (fuente de ranking = `RANKSRC')"
use `winners', clear
order mode spec rank_group minN1 minN0 minESS0 maxSMD_w meanSMD_w VRsym w_p99 w_max share_os_all
list mode spec rank_group minN1 minN0 minESS0 maxSMD_w meanSMD_w VRsym w_p99 w_max share_os_all, sepby(mode) noobs


* 8) (Opcional) Correr ATET con la spec ganadora + gráficos overlap/pesos
*========================

log using "C:\Users\Equipo\OneDrive\Desktop\proyecto\4Medio ambiente- innovacion\3. Estrategia empirica\3. Modelos\5Resultado-innovacion - estrategia causal\Medio Ambiente\_outputs_ipwra\ATET.log", replace



if (${RUN_ATET}==1) {

    * Volver a la muestra base
    use `base_data', clear
	tab anio macro_sector if b1_9==1

    * Abrir ganadoras
    preserve
        use `winners', clear
        levelsof mode, local(modes)
    restore

    foreach mm of local modes {

        * Tomar la primera spec de ese modo
        preserve
            use `winners', clear
            keep if mode=="`mm'"
            keep in 1
            local best_spec "`=spec[1]'"
        restore

        di as text " "
        di as text "============================================"
        di as text "MODO = `mm'  |  Spec ganadora = `best_spec'"
        di as text "============================================"

        * Definir Dvar según modo
        local Dvar ""
        if ("`mm'"=="IGNORE_ORG")        local Dvar "D_pp_ignore"
        if ("`mm'"=="STRICT_AVOID_ORG") local Dvar "D_pp_strict"

        * Definir Xbase según spec
        local Xbase ""
        if ("`best_spec'"=="S1") local Xbase "${X_S1}"
        if ("`best_spec'"=="S2") local Xbase "${X_S2}"
        if ("`best_spec'"=="S3") local Xbase "${X_S3}"
        if ("`best_spec'"=="S4") local Xbase "${X_S4}"
        if ("`best_spec'"=="S5") local Xbase "${X_S5}"

        * Treatment-X y Outcome-X (pueden diferir si ORG_IN_YMODEL=0)
        local X_tr "`Xbase'"

        * Extras de tratamiento se incluyen vía BASEVARS (ver switches TR_* arriba)

        * Outcome-X: por defecto igual al treatment; opcionalmente custom (ver globals YMODEL_*)
        local X_y ""
        if (${YMODEL_SAME_AS_TREAT}==1) {
            local X_y "`Xbase'"
        }
        else {
            if ("${Y_ADDVARS}"=="") {
                quietly build_xlist, base(${Y_BASEVARS}) add("")
            }
            else {
                quietly build_xlist, base(${Y_BASEVARS}) add(${Y_ADDVARS})
            }
            local X_y "`r(xlist)'"
        }

        * Extras para el outcome (en niveles; build_xlist elige L1_ si corresponde)
        * Robusto: si por alguna razón ninguna extra es usable, no rompas todo el do-file.
        if ("${Y_EXTRAVARS}"!="") {
            capture quietly build_xlist, base(${Y_EXTRAVARS}) add("")
            if (!_rc) local X_y "`X_y' `r(xlist)'"
        }

        * Extras opcionales (cuadráticos/interacciones) para outcome
        if ("${EXTRA_OUTCOME}"!="") {
            capture quietly build_xlist, base(${EXTRA_OUTCOME}) add("")
            if (!_rc) local X_y "`X_y' `r(xlist)'"
        }

        if ("`mm'"=="IGNORE_ORG" & ${INCLUDE_ORG_CONTROLS}==1) {
            local X_tr "`X_tr' org1 org_miss"
            if (${ORG_IN_YMODEL}==1) local X_y "`X_y' org1 org_miss"
        }

* Deduplicar por si hay solapes (evita "variable ... appears more than once")
local X_tr : list uniq X_tr
local X_tr : list retokenize X_tr
local X_y  : list uniq X_y
local X_y  : list retokenize X_y

        preserve
            * Muestra correspondiente
            keep if inlist(`Dvar',0,1,2,3)

            * Drop por missings en variables usadas (alineado con teffects)
            foreach x of local X_tr {
                drop if missing(`x')
            }
            foreach x of local X_y {
                drop if missing(`x')
            }
            drop if missing(Y_cond)

            * ATET (multivaluado: reporta 1vs0, 2vs0, 3vs0)
            *------------------------------------------------------------
            * (A) Alinear teffects con el diseño: recorte por soporte/overlap
            *   - Aclaracion 1) NO se usan pesos normalizados (Hájek) dentro de teffects ipwra. (No se puede)
            *   - Aclaraicon 2) Tampoco se puede "capear" (winsorizar) pesos manteniendo observaciones en teffects ipwra:
            *     los pesos son internos al estimador. Lo replicable es el RECORTE DE MUESTRA (usar opcion DROP en lugar de CAP).
            *   - Lo que SÍ se implementa para alinear el IPWRA al diseño:
			*				Implementa: p0 floors + PS-trim sobre p0 (si se activa en diseño) + wceil (controles) +
            *                 (si W_TRIM_STYLE==DROP) trimming por cuantil (controles).
            *------------------------------------------------------------
            quietly mlogit `Dvar' `X_tr', baseoutcome(0) nolog
            cap drop p0 p1 p2 p3
            predict double p0, outcome(0)
            predict double p1, outcome(1)
            predict double p2, outcome(2)
            predict double p3, outcome(3)

            local WTRIM = upper("${W_TRIM_STYLE}")
            local do_ps_trim = ${PS_TRIM}
            local ps_low  = ${PS0_LOW}
            local ps_high = ${PS0_HIGH}

            tempvar __use_final __w1 __w2 __w3
            gen byte `__use_final' = 1

            * Floors (p0) + PS trim (sobre p0) para todos
            replace `__use_final' = 0 if missing(p0)
            replace `__use_final' = 0 if (`Dvar'==0 & p0<=${P0_FLOOR})
            replace `__use_final' = 0 if (inlist(`Dvar',1,2,3) & p0<=${P0_TREAT_FLOOR})

            if (`do_ps_trim'==1) {
                replace `__use_final' = 0 if (p0<`ps_low' | p0>`ps_high')
            }

            * wceil en controles: exigir pesos razonables para CADA t (consistente con un solo multinomial)
            gen double `__w1' = . 
            gen double `__w2' = .
            gen double `__w3' = .
            replace `__w1' = (p1/p0) if `Dvar'==0 & `__use_final'==1
            replace `__w2' = (p2/p0) if `Dvar'==0 & `__use_final'==1
            replace `__w3' = (p3/p0) if `Dvar'==0 & `__use_final'==1

            replace `__use_final' = 0 if `Dvar'==0 & `__use_final'==1 & (missing(`__w1') | `__w1'<=0 | `__w1'>${W_CEIL})
            replace `__use_final' = 0 if `Dvar'==0 & `__use_final'==1 & (missing(`__w2') | `__w2'<=0 | `__w2'>${W_CEIL})
            replace `__use_final' = 0 if `Dvar'==0 & `__use_final'==1 & (missing(`__w3') | `__w3'<=0 | `__w3'>${W_CEIL})

            * Trimming por cuantil (solo controles) si el diseño está en modo DROP
            if ("`WTRIM'"=="DROP") {
                if (${W_CAP_Q} < .) {
                    local pct = 100*${W_CAP_Q}

                    quietly count if `Dvar'==0 & `__use_final'==1
                    if (r(N)>0) {
                        local wcap1 = .
                        local wcap2 = .
                        local wcap3 = .

                        quietly centile `__w1' if `Dvar'==0 & `__use_final'==1, centile(`pct')
                        local wcap1 = r(c_1)
                        quietly centile `__w2' if `Dvar'==0 & `__use_final'==1, centile(`pct')
                        local wcap2 = r(c_1)
                        quietly centile `__w3' if `Dvar'==0 & `__use_final'==1, centile(`pct')
                        local wcap3 = r(c_1)

                        if (`wcap1' < . & `wcap1' > 0) replace `__use_final' = 0 if `Dvar'==0 & `__use_final'==1 & `__w1' > `wcap1'
                        if (`wcap2' < . & `wcap2' > 0) replace `__use_final' = 0 if `Dvar'==0 & `__use_final'==1 & `__w2' > `wcap2'
                        if (`wcap3' < . & `wcap3' > 0) replace `__use_final' = 0 if `Dvar'==0 & `__use_final'==1 & `__w3' > `wcap3'
                    }
                }
            }

            keep if `__use_final'==1
            drop `__use_final' `__w1' `__w2' `__w3'

            *============================================================
            * ATET multivaluado (correcto):
            *   ATET_k = E[ Y(k) - Y(0) | D = k ],  k=1,2,3
            * Nota: con tratamiento multivaluado, `teffects ... , atet' reporta varios
            *       contrastes dentro del mismo grupo tratado. Para obtener los 3 ATET
            *       "naturales", corremos 3 veces fijando tlevel(k) y extraemos SOLO r#vs0.
            *============================================================
            tempname __b __V
            capture drop os_`mm' os_`mm'_t2 os_`mm'_t3
            forvalues t = 1/3 {
                local __osname = cond(`t'==1, "os_`mm'", "os_`mm'_t`t'")
            
            * pstolerance(${P0_FLOOR})
			teffects ipwra (Y_cond `X_y', logit) (`Dvar' `X_tr', mlogit), ///
                    atet control(0) tlevel(`t') vce(cluster correlativo) osample(`__osname') 
            
                estimates store ATET_`mm'_`best_spec'_t`t'
				tebalance summarize
				
                matrix `__b' = e(b)
                matrix `__V' = e(V)
                local __cn : colfullnames `__b'
                local __target ""
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
            
            * Mantener comportamiento "como antes" (tlevel default suele ser 1):
            * - el estimation set ATET_`mm'_`best_spec' queda asociado a t=1
            * - tebalance summarize se ejecuta sobre t=1 (para no cambiar el output existente)
            *estimates restore ATET_`mm'_`best_spec'_t1
            *estimates store ATET_`mm'_`best_spec'
            *tebalance summarize
            
            di as text "ATET relevantes (multivaluado, control=0):"
            di as text "  ATET_1 = E[Y(1)-Y(0) | D=1] = `ATET_STR1'   (SE=`SE_STR1')"
            di as text "  ATET_2 = E[Y(2)-Y(0) | D=2] = `ATET_STR2'   (SE=`SE_STR2')"
            di as text "  ATET_3 = E[Y(3)-Y(0) | D=3] = `ATET_STR3'   (SE=`SE_STR3')"


            *---- Overlap: densidad de pscore por tlevel ----
            quietly mlogit `Dvar' `X_tr', baseoutcome(0) nolog
            cap drop p0 p1 p2 p3
            predict double p0, outcome(0)
            predict double p1, outcome(1)
            predict double p2, outcome(2)
            predict double p3, outcome(3)

            set scheme s2mono

            local WTRIM = upper("${W_TRIM_STYLE}")
            local do_ps_trim = ${PS_TRIM}
            local ps_low  = ${PS0_LOW}
            local ps_high = ${PS0_HIGH}

            forvalues t=1/3 {

                *--------------------------------------------
                * Muestra y pesos EXACTAMENTE como en el ranking
                *   (p0 floors + (opcional) PS trimming + wceil + (CAP/DROP) + normalización)
                *--------------------------------------------
                tempvar __use __w_raw __w __bad_ctrl __bad_tr __bad_ps __bad_wceil
                gen byte `__use' = inlist(`Dvar',0,`t')

                gen byte `__bad_ctrl' = (`Dvar'==0   & (`__use'==1) & (p0<=${P0_FLOOR}       | missing(p0)))
                gen byte `__bad_tr'   = (`Dvar'==`t' & (`__use'==1) & (p0<=${P0_TREAT_FLOOR} | missing(p0)))

                gen byte `__bad_ps' = 0
                if (`do_ps_trim'==1) {
                    replace `__bad_ps' = (p0<`ps_low' | p0>`ps_high') if `__use'==1
                }

                replace `__use' = 0 if `__bad_ctrl' | `__bad_tr' | `__bad_ps'

                gen double `__w_raw' = .
                replace `__w_raw' = 1           if `Dvar'==`t' & `__use'==1
                replace `__w_raw' = (p`t'/p0)   if `Dvar'==0   & `__use'==1

                gen byte `__bad_wceil' = (`Dvar'==0 & `__use'==1 & (missing(`__w_raw') | `__w_raw'<=0 | `__w_raw'>${W_CEIL}))
                replace `__use' = 0 if `__bad_wceil'

                * Trimming por cuantil (solo controles, sobre la muestra "usada")
                local w_cap = .
                quietly count if `Dvar'==0 & `__use'==1
                local N0_for_trim = r(N)

                if (`N0_for_trim' > 0 & ${W_CAP_Q} < .) {
                    local pct = 100*${W_CAP_Q}
                    quietly centile `__w_raw' if `Dvar'==0 & `__use'==1, centile(`pct')
                    local w_cap = r(c_1)

                    if (`w_cap' < . & `w_cap' > 0) {
                        if ("`WTRIM'"=="CAP") {
                            replace `__w_raw' = `w_cap' if `Dvar'==0 & `__use'==1 & `__w_raw' > `w_cap'
                        }
                        else if ("`WTRIM'"=="DROP") {
                            replace `__use' = 0 if `Dvar'==0 & `__use'==1 & `__w_raw' > `w_cap'
                        }
                    }
                }

                * Normalizar controles a media 1 (Hájek): w = w_raw / mean(w_raw|D=0,usados)
                gen double `__w' = `__w_raw'
                quietly summarize `__w' if `Dvar'==0 & `__use'==1, meanonly
                local mw0 = r(mean)
                if (`mw0'>0 & `mw0'<.) replace `__w' = `__w_raw'/`mw0' if `Dvar'==0 & `__use'==1
                replace `__w' = . if `__use'==0

                *----------------------------
                * Overlap (densidad) y pesos (hist), usando la misma muestra "usada"
                *----------------------------
                twoway ///
                    (kdensity p`t' if `Dvar'==0   & `__use'==1, lpattern(solid)) ///
                    (kdensity p`t' if `Dvar'==`t' & `__use'==1, lpattern(dash)), ///
                    legend(order(1 "Controles (0)" 2 "Tratados (`t')")) ///
                    title("Overlap: Pr(D=`t') | Controles sin ponderar") ///
					subtitle("ATET=`ATET_STR`t'' (SE=`SE_STR`t'') | Mode=`mm' Spec=`best_spec'") ///
                    xtitle("Probabilidad predicha") ytitle("Densidad")

                graph export "${outdir}\overlap_`mm'_`best_spec'_t`t'.png", replace

                histogram `__w' if `Dvar'==0 & `__use'==1 & !missing(`__w'), percent ///
                    title("Pesos t=`t' | Mode=`mm' Spec=`best_spec'") ///
					subtitle("ATET=`ATET_STR`t'' | trim=`WTRIM' q=${W_CAP_Q}") ///
                    xtitle("peso w (normalizado)") ytitle("%")

                graph export "${outdir}\weights_`mm'_`best_spec'_t`t'.png", replace

                drop `__use' `__w_raw' `__w' `__bad_ctrl' `__bad_tr' `__bad_ps' `__bad_wceil'
            }
        restore
    }

}

di as text "Listo. Resultados en: ${outdir}"

log close

** vemos resultados como:
*"note:	mc_2 omitted because of collinearity.
*note:	wave_1 omitted because of collinearity.
*note:	wave_2 omitted because of collinearity.
*note:	wave_8 omitted because of collinearity.
*note:	mc_2 omitted because of collinearity.
*note:	org_miss omitted because of collinearity.
** esto tiene todo el sentido del mundo:
** mc_2 y mc_1 son las dos categorias de macro_sector, o se pone una o la otra.
** wave_1 es la ola 2000: no hay datos bajo nuestras condiciones en esta submuestra.
** wave_2 es la ola 2003: no hay datos bajo nuestras condiciones en esta submuestra.
** wave_8 es la ola 2021: es la ola que stata toma por defecto como categoria de referencia. 
** org_miss, por como fue construida, es como una dummy temporal, asi que es colineal perfecta si estimamos junto con dummies temporales (olas).
** lo importante es que estas salidas son confiables, no hay ningun mensaje acerca de problemas de identificacion. 




** comparacion usando teffects ipwra con el global DROP vs CAP.

*============================================================
* NOTA CLAVE: "CAP" (capear/truncar pesos) en DISEÑO vs. en `teffects ipwra`
*============================================================
* En el selector de diseño construimos pesos IPW a partir de p-hats (mlogit)
* y aplicamos CAP para evitar pesos extremos:
*     w_cap = min(w_raw, w_cap_threshold)
* (y luego, típicamente, normalizamos/reescalamos para que lo visual y lo
* numérico cuenten la misma historia).
* Por eso, los cuadros de balance (SMD/VR) y los histogramas del DISEÑO
* corresponden a PESOS CAPPEADOS. O SI ELEGIMOS DROP, OBSERVACIOENS CON ESOS PESOS SE ELIMINAN. 
*
* IMPORTANTE:
* `teffects ipwra` NO acepta pesos IPW "externos" (cappeados por nosotros).
* El estimador re-estima internamente el modelo de tratamiento y usa los
* pesos implícitos que surgen de sus propios p-hats, SIN aplicar nuestro CAP.
*
* Implicación:
* Aunque el DISEÑO quede muy balanceado con CAP, el ATET que reporta `teffects ipwra`
* puede estar calculado con pesos más extremos (porque no están truncados),
* y por eso puede cambiar N efectiva, SE y hasta el punto estimado.
*
* Para ALINEAR DISEÑO y ESTIMACIÓN:
*     Restringir la muestra ANTES de `teffects` usando reglas sobre p-hats/soporte
*       (trimming por percentiles o bounds tipo p in [p_low, p_high]), lo cual limita
*       cuán grandes pueden volverse los pesos que `teffects` genera internamente.
* Esto lo hicimos! solo que hay algo que no se puede lograr dejar igual y es precisamente el "capeado". Todo lo demas si: se define la muestra resultante de aplicar cambios (trimming, missing, etc). 
* si se usa la opcion DROP, ahi si replica exacto porque esa opcion se suma a las otras y se usa esa muestra resultante.

*============================================================
* DIAGNÓSTICO DE BALANCE: DROP vs CAP (capear/truncar pesos IPW)
*============================================================
* Contexto:
* - "DROP": alineación por eliminación (se pierden obs) -> N=4,448; clusters=2,667
* - "CAP" : truncamiento/capeo de pesos (se retienen obs) -> N=4,457; clusters=2,670
* Ojo: NO es la misma muestra, así que los números no son comparables 1-a-1 en sentido estricto.
*
* Regla práctica de evaluación:
* - SMD (standardized difference): mirar |SMD_Weighted|. Umbral típico: <0.10 (muy bien), 0.10–0.20 (ok).
*   El signo NO importa para balance (importa el valor absoluto).
* - VR (variance ratio): ideal ~1. Umbral típico: entre 0.80 y 1.25.
*
* (1) Resultado con DROP (pesos "limpios" vía eliminación de obs)
* - SMD_Weighted: en general baja, pero quedan variables con |SMD_Weighted| ~0.145–0.153,
*   especialmente:
*     • indice_redes  (≈0.145–0.152 según tratamiento)
*     • redesXsize    (≈0.145–0.150)
*     • (y algo menor) redesXexp (≈0.082–0.095)
*   => Balance "aceptable", pero con varios covariates cerca/por encima de 0.10.
* - VR_Weighted: aquí aparece el problema más claro:
*     • indice_redes  llega a ≈1.295 (Solo prod / Solo proc) y ≈1.407 (Ambas)  -> fuera de 1.25
*     • redesXsize    ≈1.243–1.384                                      -> fuera de 1.25
*     • redesXexp     ≈1.221–1.308                                      -> borderline/alto
*   => DROP mejora medias (SMD), pero deja diferencias de dispersión importantes (VR) en redes/interacciones.
*
* (2) Resultado con CAP (pesos truncados)
* - SMD_Weighted: mejora clara en las variables conflictivas:
*     • indice_redes pasa a |SMD_Weighted| ≈0.069–0.078
*     • redesXsize   pasa a |SMD_Weighted| ≈0.079–0.090
*     • redesXexp    pasa a |SMD_Weighted| ≈0.029–0.042
*   => En general, |SMD_Weighted| queda <0.10 en todas las variables reportadas.
* - VR_Weighted: mejora MUY marcada (y es la gran diferencia vs DROP):
*   todos los VR_Weighted quedan dentro de [0.80, 1.25] y más cerca de 1.
*   En particular, redes/interacciones quedan aprox en 0.83–0.96 (según tratamiento).
*   => CAP controla no solo diferencias en medias sino también en varianzas.
*
* Conclusión del balance (dentro del DISEÑO):
* - CAP luce "mejor" que DROP: baja más los |SMD_Weighted| problemáticos y corrige VR_Weighted que en DROP quedan fuera de rango.
* - Los principales "culpables" del desbalance residual en DROP son indice_redes y las interacciones (redesXexp, redesXsize).
*
* ACLARACIÓN CRÍTICA (para no mezclar diseño con estimación):
* - Este diagnóstico de SMD/VR corresponde a los PESOS que vos construís en el DISEÑO (y que podés CAPEAR).
* - `teffects ipwra` NO usa tus pesos IPW externos: re-estima internamente el modelo de tratamiento y usa
*   sus pesos implícitos SIN aplicar tu CAP.
* - Por eso: aunque CAP mejore el balance del DISEÑO, el ATET de `teffects ipwra` puede estar calculado con
*   pesos más extremos (no truncados), y entonces puede diferir en coeficientes/SE/N efectiva.
*
* Implicación operativa:
* - Si el objetivo es que el CAP rija también la estimación del efecto: hay que (i) imponer trimming/bounds
*   en p-hats/soporte antes de `teffects` (para acotar el peso implícito), o (ii) implementar IPWRA manual
*   con pesos propios (cap + renormalización) y bootstrap de SE.
*============================================================



.
*============================================================


