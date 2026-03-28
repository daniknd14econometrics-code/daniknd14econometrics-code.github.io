**# Capitulo 11
	
	
	
/********************************************************************/
/*  SECCION 11.1 CAPITULO WOOLDRIDGE (AVANZADO)                                         */
/********************************************************************/
/********************************************************************/

* especificar el modelo a estimar
* generar los instrumentos necesarios: ver formula 11.4.
* generar la estructura de matriz de varianza del error compuesto v_i del estimador RE
* Luego, estimar por gmm-3sls utilizando la estructura anterior. (no coincide con el del capitulo 8 teorico)
* Como es una unica ecuacion, pero es un panel, para verlo como sistema, se necesita estimar la misma ecuacion para cada periodo: T=8.
* Tendremos que especificar todo identico para los 8 años (8 ecuaciones)

** dos desafios grandes cuando pasamos a stata: por un lado decirle que tome cada periodo como una ecuacion, aunque no es lo mas delicado. 
                                             ** por otro lado, lo mas dificil es recuperar esa estructura RE e imponerla en el gmm. 
											 ** parece que el costo de estimar la version "gmm-3sls con estructura RE" para un panel puede ser costoso. 
                                             ** Nos queda como algo teorico, didactico, mostrando su equivalencia.

											 
**# IASW: implementar una version de GMM-3SLS = RE

											 
/********************************************************************/
/*  GMM (Wooldridge/IASW 11.4) imponiendo estructura RE en W         */
/*  - NO balancea el panel                                           */
/*  - Momentos por i: g_i = Z_i' v_i  => K+M momentos (no T*(K+M))   */
/*  - "Imponer RE" = fijar W = [E(Z_i' Omega_RE Z_i)]^{-1}           */
/********************************************************************/

clear all
bcuse wagepan, clear
tab year
/********************************************************************/
/*  0) LOCALS (EDITÁ ACÁ)                                            */
/********************************************************************/
preserve
local id   nr
local time year

local y    lwage
local X    educ exper expersq union married black
local W    exper expersq union married     // solo las que varían en t

/* switches */
local use_cluster 0   // 1 = vce(cluster id), 0 = vce(unadjusted)

/* VCE según switch (esto NO impone RE; solo cambia inferencia) */
local VCE "vce(unadjusted)"
if `use_cluster' local VCE "vce(cluster `id')"

/********************************************************************/
/*  1) DECLARAR PANEL                                                */
/********************************************************************/
xtset `id' `time'
sort `id' `time'

/********************************************************************/
/*  2) ESTIMAR RE PARA OBTENER sigma_u^2 y sigma_e^2 (Omega_RE)      */
/********************************************************************/
xtreg `y' `X', re
scalar su2 = e(sigma_u)^2   // Var(c_i)   (efecto individual)
scalar se2 = e(sigma_e)^2   // Var(u_it)  (idiosincrático)

/********************************************************************/
/*  3) INSTRUMENTOS (11.4) EN FORMATO LONG                           */
/*     - x_bar: medias temporales de TODOS los X                      */
/*     - w_dm : demean SOLO para W (w_it - w_bar)                     */
/********************************************************************/
foreach v of local X {
    capture drop `v'_bar
    bys `id': egen `v'_bar = mean(`v')
}

foreach w of local W {
    capture drop `w'_dm
    gen `w'_dm = `w' - `w'_bar
}

/* lista de columnas z_it = [1, X_bar, W_dm] en long (para construir W_RE) */
local Zlong "one"
capture drop one
gen one = 1

foreach v of local X {
    local Zlong "`Zlong' `v'_bar"
}
foreach w of local W {
    local Zlong "`Zlong' `w'_dm"
}

/********************************************************************/
/*  4) CONSTRUIR W_RE = inv( (1/N) sum_i Z_i' Omega_RE,i Z_i )       */
/*     - esto es lo que realmente "impone RE" en GMM                  */
/*     - soporta panel NO balanceado (Omega_RE,i usa Ti de cada i)    */
/********************************************************************/
mata:
    su2 = st_numscalar("su2")
    se2 = st_numscalar("se2")

    Z   = st_data(., tokens(st_local("Zlong")))
    idv = st_data(., st_local("id"))

    p    = panelsetup(idv, 1)
    Npan = rows(p)
    L    = cols(Z)

    S = J(L, L, 0)

    for (i=1; i<=Npan; i++) {
        a  = p[i,1]
        b  = p[i,2]
        Ti = b - a + 1

        Zi = Z[|a,1 \ b,L|] 

        Omega = se2*I(Ti) + su2*J(Ti,Ti,1)

        S = S + Zi' * Omega * Zi
    }

    S = S / Npan

    st_matrix("W_RE", invsym(S))
end

matlist W_RE

/********************************************************************/
/*  5) AHORA PASAMOS A WIDE SOLO PARA ESCRIBIR LOS MOMENTOS g_i      */
/*     (gmm trabaja a nivel "observación"; acá 1 obs = 1 individuo)   */
/********************************************************************/
egen t = group(`time')
quietly levelsof t, local(tlist)
local T : word count `tlist'
di ">> Tmax en la muestra (para reshape) = `T'"

/* Nos quedamos con lo necesario antes de reshape */
keep `id' t `y' `X' ///
     one ///
     *_bar ///
     exper_dm expersq_dm union_dm married_dm

reshape wide `y' `X' exper_dm expersq_dm union_dm married_dm, i(`id') j(t)

/********************************************************************/
/*  6) ARMAR MOMENTOS (K+M) EXACTOS DE (11.4)                         */
/*     - Momento "constante": sum_t v_it = 0                          */
/*     - Para cada x_bar: x_bar * sum_t v_it = 0                      */
/*     - Para cada w: sum_t (w_dm_it * v_it) = 0                      */
/********************************************************************/
local Rsum ""
forvalues tt=1/`T' {
    // indicador obs en t para evitar propagación de missing
    local obs = "(!missing(`y'`tt'))"

    // residuo en t
    local rt = "(`y'`tt' - {b0} - {b_educ}*educ`tt' - {b_exper}*exper`tt' - {b_expersq}*expersq`tt' - {b_union}*union`tt' - {b_married}*married`tt' - {b_black}*black`tt')"

    // sumar solo si obs
    if "`Rsum'"=="" local Rsum "cond(`obs', `rt', 0)"
    else            local Rsum "`Rsum' + cond(`obs', `rt', 0)"
}

/* Momentos within: sum_t w_dm_t * v_t */
local M_exper    ""
local M_expersq  ""
local M_union    ""
local M_married  ""

forvalues tt=1/`T' {
    local obs = "(!missing(`y'`tt'))"
    local rt  = "(`y'`tt' - {b0} - {b_educ}*educ`tt' - {b_exper}*exper`tt' - {b_expersq}*expersq`tt' - {b_union}*union`tt' - {b_married}*married`tt' - {b_black}*black`tt')"

    // cada término: cond(obs & !missing(w_dm_t), w_dm_t*rt, 0)
    local te = "cond(`obs' & !missing(exper_dm`tt'),   exper_dm`tt'*(`rt'),   0)"
    local ts = "cond(`obs' & !missing(expersq_dm`tt'), expersq_dm`tt'*(`rt'), 0)"
    local tu = "cond(`obs' & !missing(union_dm`tt'),   union_dm`tt'*(`rt'),   0)"
    local tm = "cond(`obs' & !missing(married_dm`tt'), married_dm`tt'*(`rt'), 0)"

    if "`M_exper'"==""   local M_exper   "`te'"
    else                 local M_exper   "`M_exper' + `te'"

    if "`M_expersq'"=="" local M_expersq "`ts'"
    else                 local M_expersq "`M_expersq' + `ts'"

    if "`M_union'"==""   local M_union   "`tu'"
    else                 local M_union   "`M_union' + `tu'"

    if "`M_married'"=="" local M_married "`tm'"
    else                 local M_married "`M_married' + `tm'"
}

/********************************************************************/
/*  7) ESTIMAR GMM CON W_RE FIJA (onestep)                            */
/*     - esto implementa "ponderación RE"                             */
/********************************************************************/
gmm ///
    (m0:        `Rsum') ///
    (m_educ:    educ_bar    * (`Rsum')) ///
    (m_experB:  exper_bar   * (`Rsum')) ///
    (m_expersqB:expersq_bar * (`Rsum')) ///
    (m_unionB:  union_bar   * (`Rsum')) ///
    (m_marB:    married_bar * (`Rsum')) ///
    (m_blackB:  black_bar   * (`Rsum')) ///
    (m_experW:  `M_exper') ///
    (m_expersqW:`M_expersq') ///
    (m_unionW:  `M_union') ///
    (m_marW:    `M_married'), ///
    onestep winitial(W_RE) ///
    `VCE' ///
    title("GMM (11.4) con ponderación RE fijada (W_RE)")
estimates store gmm_3sls_RE
estat overid

gmm ///
    (m0:        `Rsum') ///
    (m_educ:    educ_bar    * (`Rsum')) ///
    (m_experB:  exper_bar   * (`Rsum')) ///
    (m_expersqB:expersq_bar * (`Rsum')) ///
    (m_unionB:  union_bar   * (`Rsum')) ///
    (m_marB:    married_bar * (`Rsum')) ///
    (m_blackB:  black_bar   * (`Rsum')) ///
    (m_experW:  `M_exper') ///
    (m_expersqW:`M_expersq') ///
    (m_unionW:  `M_union') ///
    (m_marW:    `M_married'), ///
     winitial(unadjusted, independent) wmatrix(cluster nr) twostep vce(cluster nr)   ///
    title("GMM (11.4) con ponderación flexible + estructura var-cov robusta")
estimates store gmm_panel_re_flexible
estat overid

restore

xtset nr year
xtreg lwage  educ exper expersq union married black, re
estimates store re_xtreg

* Tabla básica en pantalla
esttab gmm_3sls_RE re_xtreg gmm_panel_re_flexible, ///
    se b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N, labels("N obs.")) ///
    title("GMM–3SLS-RE vs RE vs GMM–3SLS-FLEXIBLE") ///
    nonote
 

/* ----------------------------------------------------------------------
CONCLUSION 

La idea NO es "mejorar" RE, sino mostrar la equivalencia teórica:
RE puede verse como un caso particular de GMM–3SLS con estructura RE (Wooldridge 11.1 / IASW).

Para que "GMM–3SLS = RE" pase numéricamente, se necesitan DOS cosas a la vez:

(1) Instrumentos reducidos (ec. 11.4):
    - Para TODOS los regresores en X: sus medias temporales por individuo  x_bar = mean_t(x_it)
    - Para los regresores que varían en t y en i, (W): la parte within     w_dm  = w_it - w_bar
    (En total: K + M instrumentos, con M sobreidentificaciones.)

(2) Ponderación/varianza tipo RE en el criterio GMM:
    - La estructura de varianza-covarianza dentro de i debe ser RE:
        Omega_RE,i = se2*I_Ti + su2*J_Ti
    - En Stata esto NO se impone con vce().     (vce() solo cambia la INFERENCIA.)
    - La estructura RE se impone con la MATRIZ DE PONDERACIÓN del GMM:
        winitial()/wmatrix() (o winitial(W_RE) si la construís como "user weight").

Moraleja práctica:
hacer esto "a mano" en Stata es muy costoso y nadie lo usa para estimar RE;
se hace solo para demostrar la equivalencia. Pero.... es util aclarar lo siguiente:
Si se sospecha que no se sostiene el supuesto RE.3 del libro, es decir, no se sostiene la homocedasticidad y la no correlacion serial,
entonces, si es por un tema solamente de INFERENCIA: aplicamos "xtreg (...), re vce(cluster id)" y listo, es el camino directo y mas facil. 
pero si además de inferencia, nos preocupa la EFICIENCIA del estimador, podemos aplicar un estimador gmm 
reinterpretando a cada periodo como una ecuacion, tal como hicimos recien, pero NO con la estructura de varianzas RE,
sino con otra estructura flexible generica, por ejemplo con W robust, con eso atacamos el tema de la eficiencia
cuando no se cumple RE.3, y por ultimo, agregando "vce(cluster id)", atacamos adicionalmente el tema de la inferencia.
 
 -------------------------------------------------------------------- */

**# IASW: implementar una version de GMM-3SLS = FE


************************************ Parte B) FE = gmm_3sls_FE **************************************

/*Si usamos la misma estructura RE, pero cambiamos los instrumentos a unos generados con otra transformacion,
 la de Helmert, podemos eliminar los c_i, y en ese caso, si replicamos lo mismo que antes, 
 el gmm_3sls_FE nos coindice con FE.
*/

/********************************************************************/
/*  FE = GMM con Helmert + ponderación RE (IASW Thm 4.1, versión que
    coincide con xtreg, fe en los betas)                             */
/*  - Panel balanceado                                                */
/********************************************************************/

clear all
bcuse wagepan, clear
preserve

local id   nr
local time year
local y    lwage

* FE: solo variables que varían en t
local Xtv  exper expersq union married

/* inferencia (no afecta W) */
local use_cluster 0
local VCE "vce(unadjusted)"
if `use_cluster' local VCE "vce(cluster `id')"

xtset `id' `time'
sort `id' `time'

/*** 1) Recuperar varianzas RE para Ω_RE (solo para construir la ponderación) ***/
xtreg `y' educ `Xtv' black, re
scalar su2 = e(sigma_u)^2
scalar se2 = e(sigma_e)^2

/*** 2) Pasar a WIDE (1 obs = 1 individuo) ***/
egen t = group(`time')
quietly levelsof t, local(tlist)
local T : word count `tlist'

keep `id' t `y' `Xtv'
reshape wide `y' `Xtv', i(`id') j(t)
scalar Tmax = `T'

/*** 3) Crear listas wide para Mata ***/
local ywide ""
forvalues tt=1/`T' {
    local ywide "`ywide' `y'`tt'"
}
foreach x of local Xtv {
    local `x'wide ""
    forvalues tt=1/`T' {
        local `x'wide "``x'wide' `x'`tt'"
    }
}

/*** 4) Helmert (FOD) y transformación de y y Xtv ***/
mata:
    T   = st_numscalar("Tmax")
    su2 = st_numscalar("su2")
    se2 = st_numscalar("se2")

    // L = (T-1)xT, forward orthogonal deviations, filas ortonormales y L*1=0
    L = J(T-1, T, 0)
    for (t=1; t<=T-1; t++) {
        a = sqrt((T-t)/(T-t+1))
        L[t,t] = a
        for (s=t+1; s<=T; s++) L[t,s] = -a/(T-t)
    }

    // Ω_RE en niveles y su versión en Helmert: Ω_H = L Ω L'
    Omega  = se2*I(T) + su2*J(T,T,1)
    OmegaH = L*Omega*L'

    // Transformar y: YH = Y * L'
    Y  = st_data(., tokens(st_local("ywide")))          // N x T
    YH = Y * L'                                         // N x (T-1)

    // guardar yH1..yH(T-1)
    for (h=1; h<=T-1; h++) {
        vn = sprintf("yH%g", h)
        st_addvar("double", vn)
        st_store(., vn, YH[,h])
    }

    // Transformar cada Xtv y guardar xH#
    xlist = tokens(st_local("Xtv"))
    for (j=1; j<=cols(xlist); j++) {
        xname = xlist[j]
        Xw    = st_data(., tokens(st_local(xname+"wide")))   // N x T
        XH    = Xw * L'                                      // N x (T-1)
        for (h=1; h<=T-1; h++) {
            vn = sprintf("%sH%g", xname, h)
            st_addvar("double", vn)
            st_store(., vn, XH[,h])
        }
    }

    // Construir W_H para los K momentos compactos: S = (1/N) Σ XHi' Ω_H XHi
    K = cols(xlist)
    N = rows(Y)

    // armar XH_all: N x ((T-1)*K) en orden [x1H1..xKH1, x1H2..xKH2, ...]
    XH_all = J(N, (T-1)*K, .)
    for (h=1; h<=T-1; h++) {
        for (j=1; j<=K; j++) {
            xname = xlist[j]
            vn = sprintf("%sH%g", xname, h)
            XH_all[., (h-1)*K + j] = st_data(., vn)
        }
    }

    S = J(K, K, 0)
    for (i=1; i<=N; i++) {
        XHi = J(T-1, K, 0)
        for (h=1; h<=T-1; h++) {
            XHi[h,.] = XH_all[i, ((h-1)*K+1)..(h*K)]
        }
        S = S + XHi' * OmegaH * XHi
    }
    S = S / N

    st_matrix("W_H", invsym(S))
end

matlist W_H

/*** 5) Armar momentos FE compactos: Σ_h xH_h * (yH_h - β'xH_h) = 0 ***/
local Klist `Xtv'
local Hmax = `T' - 1

local M_exper   ""
local M_expersq ""
local M_union   ""
local M_married ""

forvalues h=1/`Hmax' {
    local rH "(yH`h' - {b_exper}*experH`h' - {b_expersq}*expersqH`h' - {b_union}*unionH`h' - {b_married}*marriedH`h')"

    local te "experH`h'*(`rH')"
    local ts "expersqH`h'*(`rH')"
    local tu "unionH`h'*(`rH')"
    local tm "marriedH`h'*(`rH')"

    if "`M_exper'"==""   local M_exper   "`te'"
    else                 local M_exper   "`M_exper' + `te'"

    if "`M_expersq'"=="" local M_expersq "`ts'"
    else                 local M_expersq "`M_expersq' + `ts'"

    if "`M_union'"==""   local M_union   "`tu'"
    else                 local M_union   "`M_union' + `tu'"

    if "`M_married'"=="" local M_married "`tm'"
    else                 local M_married "`M_married' + `tm'"
}

/*** 6) GMM one-step con ponderación basada en Ω_RE (en Helmert) ***/
gmm ///
    (m_exper:   `M_exper') ///
    (m_expersq: `M_expersq') ///
    (m_union:   `M_union') ///
    (m_married: `M_married'), ///
    onestep winitial(W_H) ///
    `VCE' ///
    title("FE = GMM (Helmert) con ponderación Ω_RE")

estimates store gmm_FE_helm_RE

/*** 7) Comparar con FE estándar ***/
restore
xtset `id' `time'
xtreg `y' `Xtv', fe
estimates store fe_xtreg

 *============================================================
* Convertir stripes b_exper:_cons etc -> exper expersq union married
* (para que esttab alinee bien)
*============================================================
capture program drop _gmm_make_singleeq
program define _gmm_make_singleeq, eclass
    tempname b V b2 V2
    matrix `b' = e(b)
    matrix `V' = e(V)

    local peqs "b_exper b_expersq b_union b_married"
    local pnam "exper expersq union married"

    matrix `b2' = J(1,4,.)
    matrix `V2' = J(4,4,.)

    forvalues i=1/4 {
        local eqi : word `i' of `peqs'
        matrix `b2'[1,`i'] = `b'[1,"`eqi':_cons"]

        forvalues j=1/4 {
            local eqj : word `j' of `peqs'
            matrix `V2'[`i',`j'] = `V'["`eqi':_cons","`eqj':_cons"]
        }
    }

    matrix colnames `b2' = `pnam'
    matrix rownames `V2' = `pnam'
    matrix colnames `V2' = `pnam'

    * Postear como si fuera un modelo "normal"
    ereturn post `b2' `V2', obs(`e(N)')
    ereturn local cmd "gmm_FE_helm_RE_clean"
end

estimates restore gmm_FE_helm_RE
_gmm_make_singleeq
estimates store gmm_FE_helm_RE_clean

* Ahora sí: tabla alineada
esttab gmm_FE_helm_RE_clean fe_xtreg, ///
    se b(%9.4f) se(%9.4f) ///
    order(exper expersq union married) ///
    stats(N, labels("N")) nonote

	
	
	
********************************************************************************
 
**# Especificacion de Chamberlain (historia completa)


***********************************************************************************
********************* 11.2 Chamberlain ********************************************
************************************************************************************
clear all
set more off

****************************************************
* CHAMBERLAIN (1982) - FULL HISTORY + GMM (airfare)
* y_it = c + sum_s x_is' λ_s + x_it' β + r_it
* instrumentos: historia completa (sin redundancias) + constante

** para que esta estrategia funcione bien necesito dos cosas en la practica:
	** N >> KT
	** La variabilidad within (para cada i) debe ser suficiente para lograr la identificacion. De lo contrario, poca variacion de mis instrumentos.
	** Si estas dos condiciones no se cumplen, gmm iterara muchisimo, y posiblemente no converja nunca.
    ** de todas formas, se deja el codigo.
****************************************************

use airfare.dta, clear


*----------------------------*
* 0) Declarar panel
*----------------------------*
isid id year, sort
xtset id year

*----------------------------*
* 1) Definir y y x (x TIEMPO-VARIANTES preferible, pero acá incluimos ldist también)
*----------------------------*
local y     lfare
local xvars ldist lpassen bmktshr

* índice de tiempo 1..T (robusto y sirve si fuera desbalanceado)
capture drop __tindex
egen int __tindex = group(year), label
levelsof __tindex, local(TS)
local T : word count `TS'
local K : word count `xvars'

* N (rutas)
egen __tag = tag(id)
count if __tag
local N = r(N)
drop __tag

di "N = `N'   T = `T'   K = `K'   TK = " (`T'*`K') "   p = " (1+`T'*`K'+`K')

*----------------------------*
* 2) Construir historia completa h_x_s = x_{i,s} replicado a todas las filas de i
*----------------------------*
local HIST ""
foreach x of local xvars {
    foreach s of local TS {
        local hx = "h_`x'_t`s'"
        capture drop `hx'
        bysort id: egen double `hx' = max(cond(__tindex==`s', `x', .))
        local HIST "`HIST' `hx'"
    }
}

* diagnóstico de huecos en historia (si fuera desbalanceado)
capture drop miss_hist
egen miss_hist = rowmiss(`HIST')
summ miss_hist

*----------------------------*
* 2.1) Quitar redundancias (colinealidad perfecta) en la historia
*----------------------------*
preserve
bysort id (__tindex): keep if _n==1
qui _rmcoll `HIST'
local HIST_keep `r(varlist)'
restore

di "Historia retenida (sin redundancias): " wordcount("`HIST_keep'")

* constante explícita (por si querés verla en instrumentos)
capture drop zconst
gen byte zconst = 1

*----------------------------*
* 3) Componente común: c + sum_s x_is' λ_s  (solo historia retenida)
*----------------------------*
local COMMON "{c}"
foreach x of local xvars {
    foreach s of local TS {
        local hx = "h_`x'_t`s'"
        local in : list hx in HIST_keep
        if "`in'" != "" {
            local COMMON "`COMMON' + {lam_`x'_t`s'}*`hx'"
        }
    }
}

*----------------------------*
* 4) Sistema: una ecuación por período (mismos parámetros y mismos instrumentos)
*     Usamos dummies d_s para "seleccionar" el período dentro de gmm
*----------------------------*
foreach s of local TS {
    capture drop d`s'
    gen byte d`s' = (__tindex==`s')
}

local EQS ""
foreach s of local TS {
    local oneeq "(eq`s': d`s' * ( `y' - ( `COMMON'"
    foreach x of local xvars {
        local oneeq "`oneeq' + {b_`x'}*`x'"
    }
    local oneeq "`oneeq' )) )"
    local EQS "`EQS' `oneeq'"
}

*----------------------------*
* 5) Instrumentos = historia completa (sin redundancias) + constante
*----------------------------*
local Z "`HIST_keep'"


*----------------------------*
* 6) Start values por OLS (misma RHS expandida) -> ayuda a gmm
*----------------------------*
quietly regress `y' `HIST_keep' `xvars', vce(cluster id)

matrix b_ols = e(b)

local pnames "c"
foreach hx of local HIST_keep {
    local stem = substr("`hx'",3,.)          // quita "h_"
    local pnames "`pnames' lam_`stem'"
}
foreach x of local xvars {
    local pnames "`pnames' b_`x'"
}

local P = wordcount("`pnames'")
tempname bstart
matrix `bstart' = J(1, `P', 0)
matrix colnames `bstart' = `pnames'

* (1) constante = columna 1 (porque pnames empieza con "c")
matrix `bstart'[1,1] = el(b_ols,1,colnumb(b_ols,"_cons"))

* (2) lambdas: en el MISMO orden de HIST_keep
local col = 2
foreach hx of local HIST_keep {
    local j = colnumb(b_ols,"`hx'")
    if (`j'>0) matrix `bstart'[1,`col'] = el(b_ols,1,`j')
    local ++col
}

* (3) betas: en el MISMO orden de xvars
foreach x of local xvars {
    local j = colnumb(b_ols,"`x'")
    if (`j'>0) matrix `bstart'[1,`col'] = el(b_ols,1,`j')
    local ++col
}


*----------------------------*
* 7) GMM: onestep (arranque) + twostep (W óptima) con cluster por ruta
*----------------------------*
gmm `EQS', ///
    instruments(`Z') ///
    winitial(identity) onestep ///
    vce(cluster id) ///
    from(`bstart') ///
    technique(nr) /// technique(bfgs) ///
    iterate(200) 

matrix b1 = e(b)

gmm `EQS', ///
    instruments(`Z') ///
    winitial(identity) ///
    twostep ///
    wmatrix(cluster id) ///
    vce(cluster id) ///
    from(b1) ///
    technique(nr) /// technique(bfgs) ///
    iterate(200) 
   
estat overid






