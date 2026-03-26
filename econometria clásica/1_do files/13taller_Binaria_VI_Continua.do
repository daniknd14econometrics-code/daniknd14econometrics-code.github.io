*** Capitulo 15 ***

/****************************************************************************************
TALLER VI-PROBIT con endogena continua (Wooldridge 15.7.2) — Ejemplo 15.3 (MROZ)

  1) Ver densidad/normalidad del endógeno (y2) y del residuo v2.
  2) VI-PROBIT por Control Function (Rivers–Vuong): Procedimiento 15.1.
     - 1ra etapa OLS: y2 sobre z=(z1,z2) -> vhat2
     - 2da etapa probit: y1 sobre (z1,y2,vhat2)
     - Test de exogeneidad: H0: coef(vhat2)=0
     - Relevancia del instrumento: 1ra etapa (t/F/Wald del bloque excluido)
     - Sobreidentificación (si L2>1): agregar (L2-1) instrumentos excluidos a 2da etapa
       y testear significancia conjunta (con bootstrap para p-valor).
  3) Bootstrap:
     - SE correctos para coeficientes re-escalados de 2da etapa (regresor generado).
     - APE CF por 2 vías:
         (i) recuperar coeficientes estructurales (15.45) y luego APE
         (ii) APE alternativo promediando sobre v2 (usando coeficientes re-escalados)
  4) Comparar APEs:
     - Probit exógeno (sin endogeneidad)
     - LPM-IV (2SLS)  -> APE = coeficiente
     - CF-IVProbit APE (vía (i) y vía (ii)) con SE bootstrap
     - IVPROBIT por MV condicional (Stata: ivprobit, ml) + APE via margins
  5) Tabla comparativa final de APE y EE.

Base y modelo: webuse mroz (inlf como y1; nwifeinc como endógeno y2; instrumento principal huseduc)
Controles z1: educ exper expersq age kidslt6 kidsge6 (+ constante)
****************************************************************************************/

clear all
set more off
set seed 12345

*===============================*
* 1) Datos (Ejemplo 15.3: MROZ)
*===============================*
cap noi webuse mroz, clear

* Variable dependiente binaria
*   y1 = inlf
* Endógena continua
*   y2 = nwifeinc
* Exógenas incluidas (z1)
*   educ exper expersq age kidslt6 kidsge6
* Instrumento excluido principal (z2)
*   huseduc
* Instrumentos adicionales (para sobreidentificación, z2 ampliado)
*   motheduc fatheduc (solo para mostrar el test de sobreidentificación CF)

describe inlf nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc motheduc fatheduc
summarize inlf nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc motheduc fatheduc



**# Probit

*===========================================================*
* 2) Benchmark: PROBIT exógeno + APE.
*    Decision: usar errores usuales, confiando en la distribucion del probit (normal) o usar errores robustos, entendiendo al probit como una aproximacion a la distribucion verdadera
*===========================================================*
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6, vce(robust)
*  APE promedio (margins usa método delta)
margins, dydx(*) post
estimates store  ape_probit_exo

* Comentario interpretativo
* --------------------------
* El coeficiente de nwifeinc es negativo y significativo al 5%.
* El APE promedio para nwifeinc ≈ -0.0036 indica que un aumento unitario
* en el ingreso no salarial del hogar reduce la probabilidad de participación
* laboral femenina en torno a 0.36 puntos porcentuales, manteniendo todo lo demás constante.
* Este valor servirá de punto de referencia frente a los modelos con endogeneidad.


**# MPL-IV 

*===========================================================*
* 3) Benchmark: LPM-IV (2SLS) + relevancia +  validez (si tenemos mas de 1 instrumento)
*===========================================================*
* Just-identified (z2 = huseduc)

ivregress 2sls inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), vce(robust)
estimates store mpl_iv   // guarda coeficientes para comparar
* recordar que APE en MPL = coeficiente


* Relevancia del instrumento (1ra etapa)
estat firststage

* Overidentified en LPM-IV (z2 = huseduc motheduc fatheduc) — solo para contrastar
ivregress 2sls inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), vce(robust)
* Relevancia (1ra etapa) 
estat firststage
* validez (sobreidentificación)
estat overid


* Comentario MPL-IV:
* - El coeficiente IV de nwifeinc es negativo y significativo al 5% tanto en el caso justo identificado
*   (-0.0119; p=0.043) como con 3 instrumentos (-0.0116; p=0.045). En MPL este coeficiente = APE.
* - Relevancia: la 1ra etapa muestra instrumentos fuertes: F(1,745)=47.9 (p<0.001) con huseduc solo,
*   y F(3,743)=16.67 (p<0.001) con huseduc+motheduc+fatheduc (también razonable).
* - Sobreidentificación (solo en el modelo con 3 IVs): no se rechaza la validez conjunta de IVs
*   (p=0.783). 

/* 
INTERPRETACIÓN de estat overid (test de sobreidentificación)

- Qué testea:
  En un modelo sobreidentificado (más IVs excluidos que variables endógenas), estat overid contrasta
  la hipótesis nula H0 de que TODOS los instrumentos excluidos son válidos:
  (i) son exógenos (no correlacionan con el error estructural) y 
  (ii) están correctamente excluidos de la ecuación estructural (no tienen efecto directo sobre y más allá de su efecto vía la endógena).

- Cómo lo hace (intuición):
  El test verifica si, luego de 2SLS, los residuos "quedan ortogonales" a los instrumentos. 
  Si los IVs son válidos, entonces los momentos E[z' u] = 0 deberían cumplirse (aprox.) en la muestra.

- Cómo leer un p-valor alto (ej. p=0.783):
  "No rechazamos" H0 => no encontramos evidencia estadística de que las restricciones adicionales
  (los instrumentos extra) sean inconsistentes con el modelo. Esto sugiere que, en conjunto, los IVs
  no muestran señales claras de invalidez.

- OJO: no es una "prueba absoluta" de exogeneidad:
  No rechazar NO significa "demostrar" que los instrumentos son exógenos. Solo significa que no hay
  evidencia suficiente en los datos para decir que son inválidos. La validez final sigue dependiendo
  del argumento económico/teórico (exclusión) y del contexto.

- Por qué podría no rechazar aunque algún IV sea malo:
  (a) Poder estadístico limitado: el test puede ser poco sensible en algunas muestras o con ruido.
  (b) Compensación: si un IV está correlacionado positivamente con el error y otro negativamente,
      el test (que es global) puede no detectar bien cuál falla, o incluso no rechazar si el "promedio"
      de correlaciones queda cerca de cero.

Conclusión práctica:
  Un p-valor alto es "buena señal" (no hay evidencia contra validez conjunta), pero NO reemplaza
  justificar la exclusión/exogeneidad con argumentos sustantivos sobre huseduc/motheduc/fatheduc.
  
** considerar tambien que en este contexto lineal, estan "habilitadas" todas las otras pruebas que podrian hacerse, en particular puede haber alguna prueba que evalua si la endogena es, en realidad, exogena.
  
*/





**# Probit-IV: por CF caso justo


*===========================================================*
* 4) VI-PROBIT por Control Function (CF): Procedimiento 15.1
*     Caso JUST identificado: IV excluido = huseduc
*===========================================================*

*---------------------------------------------------------------*
* 4.0) 1ra etapa +  prueba de relevancia del instrumento huseduc
*---------------------------------------------------------------*
regress nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc, vce(robust)
predict double vhat_cf_j, resid
test huseduc   // relevancia (Wald robust)
* Relevancia: la 1ra etapa muestra instrumentos fuertes: F(1,745)=47.9 (p<0.001) con huseduc solo

*  Chequeo "visual" de normalidad del residuo v2
histogram vhat_cf_j, normal fraction title("v^2: hist + normal")
kdensity vhat_cf_j, normal title("v^2: kdensity + normal")
qnorm vhat_cf_j, title("v^2: Q-Q normal")
pnorm vhat_cf_j, title("v^2: P-P normal")
sktest vhat_cf_j
swilk  vhat_cf_j
* No parece que se pueda aproximar como normal... pero bueno, le damos para adelante igual. "Econometria verdad": el supuesto para CF acerca de normalidad le queda fuerte. 

*-------------------------------*
* 4.0) 2da etapa + prueba de exogeneidad para la variable supuestamente endogena
*-------------------------------*
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 vhat_cf_j, vce(robust)
test vhat_cf_j // exogeneidad: H0 gamma=0 (OJO: SE o p-value "oficial" => usar bootstrap)

*-------------------------------*
* 4.1) Bootstrap correcto (coeficientes de segunda etapa + APEs por 2 vías)
*      - Vía A: APEs con coef re-escalados y xb_full (incluye vhat)  [tipo 15.47]
*      - Vía B: recuperar b1 (15.45) y APEs con xb_struct (sin vhat)

*Aclaración pedagógica: en este ejemplo MROZ, salvo inlf (dependiente binaria), no estás usando regresores categóricos "tipo factor"; por eso no hay urgencia con i. acá. 
*Regla general para tu aplicación real: binaria/categórica como X → APE por cambio discreto (y preferiblemente escribirlas como i.var).
* en ese caso, habria que re-adaptar el programa siguiente, el cual asume que todas las X son continuas. 


*-------------------------------*
cap program drop cf15_just
program define cf15_just, rclass
    version 16.0
    tempvar vhat xb_full xb_nores xb_struct

    * (a) 1ra etapa: forma reducida (OLS) y obtengo residuo vhat
	* como luego voy a aplicar bootstraping, no es necesario a priori usar vce(robust/cluster), pero como voy a correr alguna prueba basado en la primera etapa, pongo vce(robust).
    quietly regress nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc, vce(robust)
    quietly predict double `vhat', resid
	* para futura prueba de relevancia del instrumento:
	return scalar pi_huseduc = _b[huseduc]

    * obtendo tau2^2 = Var(v2). Usamos MSE de la 1ra etapa como estimador práctico de esta varianza
	* e(rss)/e(df_r) o e(rmse)^2
    scalar tau2sq = e(rmse)^2

    * (b) 2da etapa probit con vhat (CF)
	* como luego voy a aplicar bootstraping, no es necesario a priori usar vce(robust/cluster).
    quietly probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 `vhat'

	    * Coeficientes re-escalados (2da etapa)
    scalar br_nwifeinc = _b[nwifeinc]
    scalar br_educ     = _b[educ]
    scalar br_exper    = _b[exper]
    scalar br_expersq  = _b[expersq]
    scalar br_age      = _b[age]
    scalar br_kidslt6  = _b[kidslt6]
    scalar br_kidsge6  = _b[kidsge6]
    scalar br_vhat     = _b[`vhat']
	
    return scalar br_nwifeinc = br_nwifeinc
    return scalar br_educ     = br_educ 
    return scalar br_exper    = br_exper 
    return scalar br_expersq  = br_expersq 
    return scalar br_age      = br_age 
    return scalar br_kidslt6  = br_kidslt6
    return scalar br_kidsge6  = br_kidsge6
    return scalar br_vhat     = br_vhat 

    * Índice completo xb_full = z1*delta_r + alpha_r*y2 + gamma_r*vhat
    quietly predict double `xb_full', xb

    * ===== VÍA A (tipo 15.47): APE_j = br_j * mean( phi(xb_full) ) =====
	* Notar que xb_full utiliza todos los coeficientes, es decir, la expresion de la segunda etapa (15.43)
    *quietly summarize normalden(`xb_full'), meanonly
    *scalar meanpdf_full = r(mean)
	tempvar pdf_full pdf_struct
	* densidad normal estándar: phi(x) = exp(-x^2/2)/sqrt(2*pi)
	quietly gen double `pdf_full' = exp(-0.5*(`xb_full')^2) / sqrt(2*_pi)
	quietly summarize `pdf_full', meanonly
	scalar meanpdf_full = r(mean)

    * con lo anterior obtenemos a (15.47)=meanpdf_full
	* ahora podemos obtener los APE para cada variable:
    return scalar apev_nwifeinc = _b[nwifeinc] * meanpdf_full
    return scalar apev_educ     = _b[educ]     * meanpdf_full
    return scalar apev_exper    = _b[exper]    * meanpdf_full
    return scalar apev_expersq  = _b[expersq]  * meanpdf_full
    return scalar apev_age      = _b[age]      * meanpdf_full
    return scalar apev_kidslt6  = _b[kidslt6]  * meanpdf_full
    return scalar apev_kidsge6  = _b[kidsge6]  * meanpdf_full

    * ===== VÍA B (15.45): primero recuperar coef estructurales b1 =====
    scalar scale = 1/sqrt(1 + (_b[`vhat']^2)*tau2sq)
	
	
	* Coef estructurales (definir COMO SCALARS para poder usarlos dentro del programa)
	scalar bs_nwifeinc = _b[nwifeinc] * scale
	scalar bs_educ     = _b[educ]     * scale
	scalar bs_exper    = _b[exper]    * scale
	scalar bs_expersq  = _b[expersq]  * scale
	scalar bs_age      = _b[age]      * scale
	scalar bs_kidslt6  = _b[kidslt6]  * scale
	scalar bs_kidsge6  = _b[kidsge6]  * scale

	* y ahora sí: devolverlos
	return scalar bs_nwifeinc = bs_nwifeinc
	return scalar bs_educ     = bs_educ
	return scalar bs_exper    = bs_exper
	return scalar bs_expersq  = bs_expersq
	return scalar bs_age      = bs_age
	return scalar bs_kidslt6  = bs_kidslt6
	return scalar bs_kidsge6  = bs_kidsge6

	
	* APEs estructurales: APE_j = b1_j * mean( phi(xb_struct) )
    * Notar que ahora necesitamos evaluar la funcion en F(z1*delta + alpha*y2) 
	* --> es decir, debemos sacar el termino del error v2 de esta F(.) ---> xb_nores = xb_full - gamma_r1*vhat = z1*delta_r1 + alpha_r1*y2
	
    quietly gen double `xb_nores'  = `xb_full' - _b[`vhat']*`vhat'
	
	* Ahora que tenemos xb_nores, podemos usar el factor de escala y recuperar los coeficientes estructurales:
    
	quietly gen double `xb_struct' = scale*`xb_nores'
    
	* Finalmente, usamos F(z1*delta_1 + alpha_1*y2) y los APE los obtenemos promediando su derivada f(.) multiplicando por el coeficiente estructural correspondiente
    *quietly summarize normalden(`xb_struct'), meanonly
    *scalar meanpdf_struct = r(mean)
	
	quietly gen double `pdf_struct' = exp(-0.5*(`xb_struct')^2) / sqrt(2*_pi)
	quietly summarize `pdf_struct', meanonly
	scalar meanpdf_struct = r(mean)

    * APEs estructurales: APE_j = b1_j * mean( phi(xb_struct) )
    return scalar apes_nwifeinc = bs_nwifeinc * meanpdf_struct
    return scalar apes_educ     = bs_educ     * meanpdf_struct
    return scalar apes_exper    = bs_exper    * meanpdf_struct
    return scalar apes_expersq  = bs_expersq  * meanpdf_struct
    return scalar apes_age      = bs_age      * meanpdf_struct
    return scalar apes_kidslt6  = bs_kidslt6  * meanpdf_struct
    return scalar apes_kidsge6  = bs_kidsge6  * meanpdf_struct

    * útil para reportar
    return scalar scale = scale
end


**# Bootstrap para todo

*============================================================*
* (1) Un SOLO bootstrap que devuelva TODO junto
*============================================================*
bootstrap ///
    pi_huseduc=r(pi_huseduc) ///
    br_nwifeinc=r(br_nwifeinc) br_educ=r(br_educ) br_exper=r(br_exper) br_expersq=r(br_expersq) br_age=r(br_age) br_kidslt6=r(br_kidslt6) br_kidsge6=r(br_kidsge6) br_vhat=r(br_vhat) ///
    apev_nwifeinc=r(apev_nwifeinc) apev_educ=r(apev_educ) apev_exper=r(apev_exper) apev_expersq=r(apev_expersq) apev_age=r(apev_age) apev_kidslt6=r(apev_kidslt6) apev_kidsge6=r(apev_kidsge6) ///
    bs_nwifeinc=r(bs_nwifeinc) bs_educ=r(bs_educ) bs_exper=r(bs_exper) bs_expersq=r(bs_expersq) bs_age=r(bs_age) bs_kidslt6=r(bs_kidslt6) bs_kidsge6=r(bs_kidsge6) ///
    apes_nwifeinc=r(apes_nwifeinc) apes_educ=r(apes_educ) apes_exper=r(apes_exper) apes_expersq=r(apes_expersq) apes_age=r(apes_age) apes_kidslt6=r(apes_kidslt6) apes_kidsge6=r(apes_kidsge6) ///
    scale=r(scale), ///
    reps(500) seed(12345) nodots: cf15_just

** en panel agregar "cluster(id)" como opcion en el bootstrap.

	
**************** para tabla futura en esttab apes_* ****************

* --- venís de: bootstrap ... : cf15_just
estimates store bs_cf_just

matrix B = e(b)
matrix V = e(V)
scalar N0 = e(N)

* Queremos guardar APE (método S) como coeficientes "limpios"
local apes_list  "apes_nwifeinc apes_educ apes_exper apes_expersq apes_age apes_kidslt6 apes_kidsge6"
local clean_list "nwifeinc educ exper expersq age kidslt6 kidsge6"
local K : word count `apes_list'

matrix b_cf = J(1, `K', .)
matrix V_cf = J(`K', `K', .)

forvalues i = 1/`K' {
    local nm_i : word `i' of `apes_list'
    local ciB  = colnumb(B, "`nm_i'")
    local ciV  = colnumb(V, "`nm_i'")
    if (`ciB'==0 | `ciV'==0) continue
	
    matrix b_cf[1,`i'] = B[1,`ciB']

    forvalues j = 1/`K' {
        local nm_j : word `j' of `apes_list'
        local cjV  = colnumb(V, "`nm_j'")
        if (`cjV'==0) continue
        matrix V_cf[`i',`j'] = V[`ciV',`cjV']
    }
}

matrix colnames b_cf = `clean_list'
matrix colnames V_cf = `clean_list'
matrix rownames V_cf = `clean_list'

* ---- posteamos como e() "de verdad" (para poder estimates store)
capture program drop _post_bv
program define _post_bv, eclass
    args bmat vmat nobs
    ereturn post `bmat' `vmat', obs(`nobs')
    ereturn local cmd "cf_manual_apes"
end

_post_bv b_cf V_cf `=N0'
estimates store cf_just_apes

estimates restore cf_just_apes
ereturn list


* volver a resultados del bootstrap para seguir usando B y V originales
estimates restore bs_cf_just


**************** para tabla futura en esttab apev_*  ****************

* ============================================================*
* Guardar APE (método alternativo) como estimación para esttab
* ============================================================*

* Asegurate de estar parado en el resultado del bootstrap
estimates restore bs_cf_just

matrix B = e(b)
matrix V = e(V)
scalar N0 = e(N)

local apev_list  "apev_nwifeinc apev_educ apev_exper apev_expersq apev_age apev_kidslt6 apev_kidsge6"
local clean_list "nwifeinc educ exper expersq age kidslt6 kidsge6"
local K : word count `apev_list'

matrix b_cf = J(1, `K', .)
matrix V_cf = J(`K', `K', .)

forvalues i = 1/`K' {
    local nm_i : word `i' of `apev_list'
    local ciB  = colnumb(B, "`nm_i'")
    local ciV  = colnumb(V, "`nm_i'")
    if (`ciB'==0 | `ciV'==0) continue
    matrix b_cf[1,`i'] = B[1,`ciB']

    forvalues j = 1/`K' {
        local nm_j : word `j' of `apev_list'
        local cjV  = colnumb(V, "`nm_j'")
        if (`cjV'==0) continue
        matrix V_cf[`i',`j'] = V[`ciV',`cjV']
    }
}

matrix colnames b_cf = `clean_list'
matrix colnames V_cf = `clean_list'
matrix rownames V_cf = `clean_list'

* _post_bv ya lo definiste antes
_post_bv b_cf V_cf `=N0'
estimates store cf_just_apev


estimates restore cf_just_apev
ereturn list


* volver a resultados del bootstrap para seguir usando B y V originales
estimates restore bs_cf_just


**# Prueba de relevancia del instrumento 

*-----------------------------*
* Relevancia (1ra etapa): H0 pi_huseduc = 0
* Con 1 instrumento: F = z^2
*-----------------------------*
scalar pi_hat  = B[1,"pi_huseduc"]
scalar se_pi   = sqrt(V["pi_huseduc","pi_huseduc"])
scalar z_pi    = pi_hat/se_pi
scalar p_pi    = 2*(1-normal(abs(z_pi)))
scalar F_pi    = z_pi^2

di as result "Relevancia (bootstrap):  pi=" pi_hat "  se=" se_pi "  z=" z_pi "  p=" p_pi "  (F=z^2)=" F_pi

**# Prueba de exogeneidad de nwifeinc

*-----------------------------*
* Exogeneidad CF: H0 gamma = 0  (gamma = coef del residuo vhat)
*-----------------------------*
scalar g_hat   = B[1,"br_vhat"]
scalar se_g    = sqrt(V["br_vhat","br_vhat"])
scalar z_g     = g_hat/se_g
scalar p_g     = 2*(1-normal(abs(z_g)))

di as result "Exogeneidad CF (bootstrap): gamma=" g_hat "  se=" se_g "  z=" z_g "  p=" p_g



******************************** CF manual: caso sobreidentificado **************************	
	
**# Probit-IV: por CF caso sobreidentificado

cap program drop cf15_sob
program define cf15_sob, rclass
    version 16.0
    tempvar vhat xb_full xb_nores xb_struct pdf_full pdf_struct
    tempvar xb p pdf gres g1 g2

    *====================*
    * (a) 1ra etapa (OLS)
    *====================*
    quietly regress nwifeinc educ exper expersq age kidslt6 kidsge6  huseduc motheduc fatheduc, vce(robust)
    quietly predict double `vhat', resid

    return scalar pi_huseduc  = _b[huseduc]
    return scalar pi_motheduc = _b[motheduc]
    return scalar pi_fatheduc = _b[fatheduc]

    scalar tau2sq = e(rmse)^2

    *====================*
    * (b) 2da etapa (CF probit)
    *====================*
    quietly probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 `vhat'

    return scalar br_nwifeinc = _b[nwifeinc]
    return scalar br_educ     = _b[educ]
    return scalar br_exper    = _b[exper]
    return scalar br_expersq  = _b[expersq]
    return scalar br_age      = _b[age]
    return scalar br_kidslt6  = _b[kidslt6]
    return scalar br_kidsge6  = _b[kidsge6]
    return scalar br_vhat     = _b[`vhat']

    quietly predict double `xb_full', xb

    *====================*
    * Vía A (APE con xb_full)
    *====================*
    quietly gen double `pdf_full' = exp(-0.5*(`xb_full')^2) / sqrt(2*_pi)
    quietly summarize `pdf_full', meanonly
    scalar meanpdf_full = r(mean)

    return scalar apev_nwifeinc = _b[nwifeinc] * meanpdf_full
    return scalar apev_educ     = _b[educ]     * meanpdf_full
    return scalar apev_exper    = _b[exper]    * meanpdf_full
    return scalar apev_expersq  = _b[expersq]  * meanpdf_full
    return scalar apev_age      = _b[age]      * meanpdf_full
    return scalar apev_kidslt6  = _b[kidslt6]  * meanpdf_full
    return scalar apev_kidsge6  = _b[kidsge6]  * meanpdf_full

    *====================*
    * Vía B (escala + APE estructural)
    *====================*
    scalar scale = 1/sqrt(1 + (_b[`vhat']^2)*tau2sq)
    return scalar scale = scale

    scalar bs_nwifeinc = _b[nwifeinc] * scale
    scalar bs_educ     = _b[educ]     * scale
    scalar bs_exper    = _b[exper]    * scale
    scalar bs_expersq  = _b[expersq]  * scale
    scalar bs_age      = _b[age]      * scale
    scalar bs_kidslt6  = _b[kidslt6]  * scale
    scalar bs_kidsge6  = _b[kidsge6]  * scale

    return scalar bs_nwifeinc = bs_nwifeinc
    return scalar bs_educ     = bs_educ
    return scalar bs_exper    = bs_exper
    return scalar bs_expersq  = bs_expersq
    return scalar bs_age      = bs_age
    return scalar bs_kidslt6  = bs_kidslt6
    return scalar bs_kidsge6  = bs_kidsge6

    quietly gen double `xb_nores'  = `xb_full' - _b[`vhat']*`vhat'
    quietly gen double `xb_struct' = scale*`xb_nores'

    quietly gen double `pdf_struct' = exp(-0.5*(`xb_struct')^2) / sqrt(2*_pi)
    quietly summarize `pdf_struct', meanonly
    scalar meanpdf_struct = r(mean)

    return scalar apes_nwifeinc = bs_nwifeinc * meanpdf_struct
    return scalar apes_educ     = bs_educ     * meanpdf_struct
    return scalar apes_exper    = bs_exper    * meanpdf_struct
    return scalar apes_expersq  = bs_expersq  * meanpdf_struct
    return scalar apes_age      = bs_age      * meanpdf_struct
    return scalar apes_kidslt6  = bs_kidslt6  * meanpdf_struct
    return scalar apes_kidsge6  = bs_kidsge6  * meanpdf_struct
	
	* ===== "OVERID" Wooldridge (instrumentos extra) =====
* Modelo auxiliar: agrego SOLO los instrumentos extra (no el base)
    *     Extras: motheduc y fatheduc
	*     observar que podriamos usar cualquier combinacion de 2 tomadas de 3 instruementos no triviales para esta prueba, elegimos ahora motheduc y fatheduc
    * como la siguiente regresion la uso para luego aplicar un test, uso vce(robust)
quietly probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 `vhat'  motheduc fatheduc, vce(robust)
quietly test motheduc fatheduc

return scalar J_wald  = r(chi2)
return scalar df_wald = r(df)
return scalar p_wald  = r(p)

end



	
**# Bootstrap para todo

*===============================================================*
* (1) Un solo bootstrap PERO cambiar el program
*==============================================================*

*Estadístico observado: scalar J0 = r(J_overid)

* Bootstrap guardando réplicas
bootstrap ///
    pi_huseduc=r(pi_huseduc) pi_motheduc=r(pi_motheduc) pi_fatheduc=r(pi_fatheduc) ///
    br_nwifeinc=r(br_nwifeinc) br_educ=r(br_educ) br_exper=r(br_exper) br_expersq=r(br_expersq) ///
    br_age=r(br_age) br_kidslt6=r(br_kidslt6) br_kidsge6=r(br_kidsge6) br_vhat=r(br_vhat) ///
    apev_nwifeinc=r(apev_nwifeinc) apev_educ=r(apev_educ) apev_exper=r(apev_exper) apev_expersq=r(apev_expersq) ///
    apev_age=r(apev_age) apev_kidslt6=r(apev_kidslt6) apev_kidsge6=r(apev_kidsge6) ///
    bs_nwifeinc=r(bs_nwifeinc) bs_educ=r(bs_educ) bs_exper=r(bs_exper) bs_expersq=r(bs_expersq) ///
    bs_age=r(bs_age) bs_kidslt6=r(bs_kidslt6) bs_kidsge6=r(bs_kidsge6) ///
    apes_nwifeinc=r(apes_nwifeinc) apes_educ=r(apes_educ) apes_exper=r(apes_exper) apes_expersq=r(apes_expersq) ///
    apes_age=r(apes_age) apes_kidslt6=r(apes_kidslt6) apes_kidsge6=r(apes_kidsge6) ///
    scale=r(scale) ///
	J_wald=r(J_wald) df_wald=r(df_wald) p_wald=r(p_wald), ///
	reps(500) seed(12345) nodots saving(bs_cf_overid, replace): cf15_sob

	
** en panel agregar "cluster(id)" como opcion en el bootstrap.

	
**************** para tabla futura en esttab apes_* ****************

* --- venís de: bootstrap ... : cf15_sob
estimates store bs_cf_sob

matrix B = e(b)
matrix V = e(V)
scalar N0 = e(N)

* Queremos guardar APE (método S) como coeficientes "limpios"
local apes_list  "apes_nwifeinc apes_educ apes_exper apes_expersq apes_age apes_kidslt6 apes_kidsge6"
local clean_list "nwifeinc educ exper expersq age kidslt6 kidsge6"
local K : word count `apes_list'

matrix b_cf = J(1, `K', .)
matrix V_cf = J(`K', `K', .)

forvalues i = 1/`K' {
    local nm_i : word `i' of `apes_list'
    local ciB  = colnumb(B, "`nm_i'")
    local ciV  = colnumb(V, "`nm_i'")
    if (`ciB'==0 | `ciV'==0) continue
	
    matrix b_cf[1,`i'] = B[1,`ciB']

    forvalues j = 1/`K' {
        local nm_j : word `j' of `apes_list'
        local cjV  = colnumb(V, "`nm_j'")
        if (`cjV'==0) continue
        matrix V_cf[`i',`j'] = V[`ciV',`cjV']
    }
}

matrix colnames b_cf = `clean_list'
matrix colnames V_cf = `clean_list'
matrix rownames V_cf = `clean_list'

* ---- posteamos como e() "de verdad" (para poder estimates store)
capture program drop _post_bv
program define _post_bv, eclass
    args bmat vmat nobs
    ereturn post `bmat' `vmat', obs(`nobs')
    ereturn local cmd "cf_manual_apes"
end

_post_bv b_cf V_cf `=N0'
estimates store cf_sob_apes

estimates restore cf_sob_apes
ereturn list


* volver a resultados del bootstrap para seguir usando B y V originales
estimates restore bs_cf_sob


**************** para tabla futura en esttab apes_*  ****************

* ============================================================*
* Guardar APEV (método V) como estimación para esttab
* ============================================================*

* Asegurate de estar parado en el resultado del bootstrap
estimates restore bs_cf_sob

matrix B = e(b)
matrix V = e(V)
scalar N0 = e(N)

local apev_list  "apev_nwifeinc apev_educ apev_exper apev_expersq apev_age apev_kidslt6 apev_kidsge6"
local clean_list "nwifeinc educ exper expersq age kidslt6 kidsge6"
local K : word count `apev_list'

matrix b_cf = J(1, `K', .)
matrix V_cf = J(`K', `K', .)

forvalues i = 1/`K' {
    local nm_i : word `i' of `apev_list'
    local ciB  = colnumb(B, "`nm_i'")
    local ciV  = colnumb(V, "`nm_i'")
    if (`ciB'==0 | `ciV'==0) continue
    matrix b_cf[1,`i'] = B[1,`ciB']

    forvalues j = 1/`K' {
        local nm_j : word `j' of `apev_list'
        local cjV  = colnumb(V, "`nm_j'")
        if (`cjV'==0) continue
        matrix V_cf[`i',`j'] = V[`ciV',`cjV']
    }
}

matrix colnames b_cf = `clean_list'
matrix colnames V_cf = `clean_list'
matrix rownames V_cf = `clean_list'

* _post_bv ya lo definiste antes
_post_bv b_cf V_cf `=N0'
estimates store cf_sob_apev


estimates restore cf_sob_apev
ereturn list


* volver a resultados del bootstrap para seguir usando B y V originales
estimates restore bs_cf_sob

	
	
	
	
	
**# Prueba de sobreidentificacion de instrumentos

* J observado (Wald~chi2 del probit auxiliar dentro del programa)
scalar J0  = B[1,"J_wald"]
scalar df0 = B[1,"df_wald"]
* p-valor asintótico (por si querés mostrarlo también)
scalar p_asym = B[1,"p_wald"]

preserve
use bs_cf_overid, clear
drop if missing(J_wald)
count
scalar R = r(N)
count if J_wald >= scalar(J0)
scalar Rge = r(N)

* p-value bootstrap (con corrección +1 para no dar 0 exacto)
scalar p_boot = (Rge + 1)/(R + 1)
di as result "Overid (Wald) : J0=" %9.4f scalar(J0) "  df=" %2.0f scalar(df0) ///
             "  p_asym=" %6.4f scalar(p_asym) "  p_boot=" %6.4f scalar(p_boot)
restore


**# Prueba de relevancia de los instrumentos

*-----------------------------*
* Relevancia (1ra etapa): H0 pi_huseduc = pi_fatheduc = pi_motheduc =0
* Con 3 instrumentos: 
*-----------------------------*
matrix bpi = (B[1,"pi_huseduc"] \ B[1,"pi_motheduc"] \ B[1,"pi_fatheduc"])
matrix Vpi = V["pi_huseduc" "pi_motheduc" "pi_fatheduc", "pi_huseduc" "pi_motheduc" "pi_fatheduc"]

matrix W = bpi' * invsym(Vpi) * bpi
scalar chi2_rel = W[1,1]
scalar p_rel    = chi2tail(3, chi2_rel)

di as result "Relevancia conjunta (bootstrap-Wald): chi2(3)=" chi2_rel "  p=" p_rel

**# Prueba de exogeneidad de nwifeinc

*-----------------------------*
* Exogeneidad CF: H0 gamma = 0  (gamma = coef del residuo vhat)
*-----------------------------*

scalar g_hat = B[1,"br_vhat"]
scalar se_g  = sqrt(V["br_vhat","br_vhat"])
scalar z_g   = g_hat/se_g
scalar p_g   = 2*(1-normal(abs(z_g)))

di as result "Exogeneidad CF (bootstrap): gamma=" g_hat "  se=" se_g "  z=" z_g "  p=" p_g


**# Interpretacion respecto de pruebas

/****************************************************************************************
TESTS (con SE bootstrap) — Interpretación para reporte

Contexto: Probit-IV por Control Function (CF) con 1 endógena (nwifeinc) y 3 instrumentos
excluidos (huseduc, motheduc, fatheduc). Se reportan 3 diagnósticos:

(1) OVERIDENTIFICATION (sobreidentificación) — versión Wald de Wooldridge
    - Qué testea:
      Con CF, el modelo estructural correcto incluye vhat (= residuo de 1ra etapa) para
      capturar la parte endógena de nwifeinc. Si los instrumentos extra son válidos,
      entonces NO deben tener efecto directo sobre inlf una vez que ya controlás por:
      nwifeinc + controles + vhat. Por eso se estima un probit auxiliar agregando SOLO
      los instrumentos extra y se testea:
          H0: coef(motheduc)=coef(fatheduc)=0   (df = #instrumentos extra)
      Interpretación:
      * p alto => no hay evidencia contra la validez/exclusión de los instrumentos extra.
      * p bajo => al menos uno de los instrumentos extra parece entrar "directamente"
        en la ecuación estructural (violación de exogeneidad/exclusión).

    - Tus números:
        J0 = 0.4441, df = 2
        p_asym = 0.8009
        p_boot = 0.8375
      Lectura:
        No se rechaza H0. Los datos NO contradicen la validez conjunta de los instrumentos
        extra; tanto el p asintótico como el bootstrap son muy altos.

(2) RELEVANCIA (1ra etapa) — Wald conjunto con SE bootstrap
    - Qué testea:
      Si los instrumentos excluidos realmente "mueven" a la endógena nwifeinc.
      Se testea:
          H0: pi_huseduc = pi_motheduc = pi_fatheduc = 0
      Interpretación:
      * Rechazar H0 => instrumentos relevantes (buena señal).
      * No rechazar H0 => instrumentos débiles/irrelevantes (CF-IV inestable).

    - Tus números:
        chi2(3) = 47.70
        p = 2.47e-10
      Lectura:
        Rechazo fuerte de H0. En conjunto, los instrumentos son claramente relevantes.

(3) EXOGENEIDAD de nwifeinc (CF) — significancia de gamma (coef de vhat)
    - Qué testea:
      En CF, el término vhat entra en la segunda etapa como corrector de endogeneidad.
      Se testea:
          H0: gamma = 0   (gamma = coef de vhat en el probit CF)
      Interpretación:
      * Rechazar H0 => evidencia de endogeneidad (el corrector importa).
      * No rechazar H0 => no hay evidencia estadística fuerte de endogeneidad bajo CF.

    - Tus números:
        gamma = 0.02559
        se_boot = 0.02153
        z = 1.188
        p = 0.2347
      Lectura:
        No se rechaza H0. No aparece evidencia fuerte de endogeneidad de nwifeinc con este
        set de instrumentos y esta especificación (ojo: "no rechazar" no prueba exogeneidad,
        solo que no hay señal estadística clara en la muestra).

Resumen conjunto:
- Relevancia: muy bien (instrumentos fuertes en 1ra etapa).
- Sobreidentificación: no hay señales de invalidez de los instrumentos extra.
- Exogeneidad: CF no detecta endogeneidad fuerte (gamma no significativo).
****************************************************************************************/





****************************************************************************************************************
******************* Modelo estilo CF pero diferente: basado en paper de Newey (1987) ***************************
******************* tiene un comando directo en Stata... pero no todo es tan directo  **************************
****************************************************************************************************************

**# Probit-IV: CF (Newey) con comando ivprobit

/* ACERCA DE COMANDO IVPROBIT. PROS Y CONTRAS.

1) ¿Qué hace realmente ivprobit y quién está detrás?

ivprobit por defecto estima por máxima verosimilitud (ML). La opcion es "mle".
Si pedís , "twostep", Stata implementa el two-step eficiente de Newey (1987). 
En la parte de "mecánica", ese enfoque usa la lógica tipo residual control function (CF), 
y el manual muestra explícitamente el paso tipo Rivers–Vuong (1988) como parte del procedimiento de dos pasos (y Newey como el estimador eficiente final). 
En resumen: "ivprobit, twostep" es muy cercano a tu control function, pero con VCE correcto (asintótico) "de fábrica", en vez de depender de que se corrija a mano por bootstrap.

2) "¿Los coeficientes de segunda etapa ya vienen corregidos por bootstrap?"
No. Los coeficientes son los estimadores puntuales del método elegido (ML o Newey two-step).
 Lo que cambia con bootstrap es la matriz de varianzas (SE, tests, CI), no el punto estimado. --> se piden con vce(bootstrap) pero no es lo mismo que corregir por bootstrap los APEs.

3) "¿Cómo pedimos APE con ivprobit? ¿Vienen por bootstrap?"
Cómo pedir APE: depende de si pedimos la estimacion del modelo MV o TwoStep.
En MV, modelo bivariado estimado conjuntamente por MV, se pide con margins, igual que en probit/logit: margins, dydx(x1 x2 endogvar) predict(pr) 
PERO solamente estan habilitados para la opcion por Maxima Verosimilitud. 
El resultado es un efecto con interpretación tipo ASF (estructural) que "toma en serio" la endogeneidad vía el residual. 
¿Vienen bootstrap? No: margins por defecto usa delta method. 

Pero para el caso de two-step los APE deberan construirse manualmente y luego eventualmente aplicar bootstrap a estos APE.
En este sentido, no me parece que haya ganancia en usar este comando directo si, al usarlo con twostep se deben calcular los APE y sus errores estandar como hicimos hoy con CF.
 

4) Prueba de exogeneidad (endogeneidad del regresor instrumentado)
Esta es la más fácil con ivprobit:
ivprobit, twostep (o ivprobit, mle) ya te imprime el "Wald test of exogeneity":

5) Prueba de relevancia (fuerza de instrumentos)

tenés: opcion ", first" para mostrar la(s) primera(s) etapa(s). Pero no te deja guardar objetos de la primera etapa.
para un test formal de relevancia, lo estándar es correr vos la primera etapa y testear que los excluidos entren fuerte:


6) Prueba de sobreidentificación (overid)
El comando no aporta un test para esto.

*/

ivprobit inlf educ exper expersq age kidslt6 kidsge6  (nwifeinc = huseduc motheduc fatheduc), twostep first 

* APEs bajo ivprobit: debemos calcularlas manualmente y obtener sus errores estandar por bootstrap


********************************************************************************
* 1) Programa
*    - 1ra etapa OLS: guarda pi_* para futura prueba de relevancia en este contexto ivprobit two-step
*    - ivprobit twostep: calcula APEs (todas continuas) con mean(phi(xb))
*    - overid (Wooldridge-style): probit auxiliar + test instrumentos extra
********************************************************************************
capture program drop ivp_ape
program define ivp_ape, rclass
    version 16.0
    tempvar vhat xb pdf

    *---------------------------------------------*
    * (a) 1ra etapa (OLS): auxiliar para Relevancia
    *---------------------------------------------*
    quietly regress nwifeinc educ exper expersq age kidslt6 kidsge6  huseduc motheduc fatheduc, vce(robust)
    quietly predict double `vhat', resid

	quietly test huseduc motheduc fatheduc
	return scalar F_rel  = r(F)
	return scalar df1_rel = r(df)
	return scalar df2_rel = r(df_r)

    *-----------------------------*
    * (b) ivprobit (two-step)
    *-----------------------------*
    quietly ivprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), twostep

	* (opcional) test de exogeneidad integrado de ivprobit
	return scalar chi2_exog = e(chi2_exog)
	return scalar df_exog   = 1

	
    quietly predict double `xb', xb
    quietly gen double `pdf' = normalden(`xb')
    quietly summarize `pdf', meanonly
    scalar meanpdf = r(mean)

    return scalar ape_nwifeinc = _b[nwifeinc] * meanpdf
    return scalar ape_educ     = _b[educ]     * meanpdf
    return scalar ape_exper    = _b[exper]    * meanpdf
    return scalar ape_expersq  = _b[expersq]  * meanpdf
    return scalar ape_age      = _b[age]      * meanpdf
    return scalar ape_kidslt6  = _b[kidslt6]  * meanpdf
    return scalar ape_kidsge6  = _b[kidsge6]  * meanpdf

    *-----------------------------*
    * (c) OVERID (Wooldridge):
    *     Probit auxiliar: agrego SOLO instrumentos extra (motheduc, fatheduc)
    *     y testeo H0: motheduc = fatheduc = 0
    *-----------------------------*
    quietly probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6   `vhat' motheduc fatheduc, vce(robust)
    quietly test motheduc fatheduc

    return scalar J_wald  = r(chi2)
    return scalar df_wald = r(df)


end


**# Bootstrap + pruebas

********************************************************************************
* 2) Bootstrap guardando réplicas: surgen de IVPROBIT 
********************************************************************************
bootstrap ///
    ape_nwifeinc=r(ape_nwifeinc) ape_educ=r(ape_educ) ape_exper=r(ape_exper) ape_expersq=r(ape_expersq) ///
    ape_age=r(ape_age) ape_kidslt6=r(ape_kidslt6) ape_kidsge6=r(ape_kidsge6) ///
    F_rel=r(F_rel) df1_rel=r(df1_rel) df2_rel=r(df2_rel) ///
    chi2_exog=r(chi2_exog) df_exog=r(df_exog) ///
    J_wald=r(J_wald) df_wald=r(df_wald), ///
    reps(500) seed(12345) nodots saving(bs_ivp_ts_overid, replace): ivp_ape

** en panel agregar "cluster(id)" como opcion en el bootstrap.

	
**************** para tabla futura en esttab apes_* ****************

* --- venís de: bootstrap ... :  ivp_ape
estimates store bs_ivprobit_sob

matrix B = e(b)
matrix V = e(V)
scalar N0 = e(N)

* Queremos guardar APE  como coeficientes "limpios"
local ape_list  "ape_nwifeinc ape_educ ape_exper ape_expersq ape_age ape_kidslt6 ape_kidsge6"
local clean_list "nwifeinc educ exper expersq age kidslt6 kidsge6"
local K : word count `ape_list'

matrix b_cf = J(1, `K', .)
matrix V_cf = J(`K', `K', .)

forvalues i = 1/`K' {
    local nm_i : word `i' of `ape_list'
    local ciB  = colnumb(B, "`nm_i'")
    local ciV  = colnumb(V, "`nm_i'")
    if (`ciB'==0 | `ciV'==0) continue
	
    matrix b_cf[1,`i'] = B[1,`ciB']

    forvalues j = 1/`K' {
        local nm_j : word `j' of `ape_list'
        local cjV  = colnumb(V, "`nm_j'")
        if (`cjV'==0) continue
        matrix V_cf[`i',`j'] = V[`ciV',`cjV']
    }
}

matrix colnames b_cf = `clean_list'
matrix colnames V_cf = `clean_list'
matrix rownames V_cf = `clean_list'

* ---- posteamos como e() "de verdad" (para poder estimates store)
capture program drop _post_bv
program define _post_bv, eclass
    args bmat vmat nobs
    ereturn post `bmat' `vmat', obs(`nobs')
    ereturn local cmd "ivprobit_ape"
end

_post_bv b_cf V_cf `=N0'
estimates store ivprobit_sob_ape

estimates restore ivprobit_sob_ape
ereturn list


* volver a resultados del bootstrap para seguir usando B y V originales
estimates restore bs_ivprobit_sob


********************************************************************************
* 3) Sobreidentificación:  (NO surgen de ivprobit)
********************************************************************************
scalar J0  = B[1,"J_wald"]
scalar df0 = B[1,"df_wald"]
scalar p_asym = chi2tail(df0, J0)


display as result "Overid (Wald): J0=" %9.4f scalar(J0) "  df=" %2.0f scalar(df0) ///
             "  p_asym=" %6.4f scalar(p_asym) "  


********************************************************************************
* 4) Relevancia (1ra etapa): 
********************************************************************************
scalar F0   = B[1,"F_rel"]
scalar df10 = B[1,"df1_rel"]
scalar df20 = B[1,"df2_rel"]
scalar p_asym_rel = Ftail(df10, df20, F0)


display as result "Relevancia (1ra etapa): F0=" %9.4f scalar(F0) "  df1=" %2.0f scalar(df10) ///
             "  df2=" %4.0f scalar(df20) "  p_asym=" %6.4f scalar(p_asym_rel) 
             

********************************************************************************
* 5) Exogeneidad directa de IVPROBIT: 
********************************************************************************
scalar chi0 = B[1,"chi2_exog"]
scalar dfchi0 = B[1,"df_exog"]
scalar p_asym_exog = chi2tail(dfchi0, chi0)

display as result "Exogeneidad (ivprobit): chi2_0=" %9.4f scalar(chi0) "  df=" %2.0f scalar(dfchi0) ///
             "  p_asym=" %6.4f scalar(p_asym_exog) " 


/* resumen comando "ivprobit, twostep":

La idea es usar el comando ivprobit siempre que se pueda.
Coeficientes: obtenemos coeficientes que supuestamente tienen los errores estandar "consistentes bajo los supuestos del modelo" o "asintóticamente válidos". Ver manual. 
APEs: no nos quedo otra que calcularlos con un programa creado y para sus errores estandar debimos usar bootstrap. (Debilidad de usar el comando con la opcion twostep).
Exogeneidad: no vale la pena pedir una prueba de exogeneidad basada en CF si ya hay una que surge directa del comando ivprobit. Es decir, usamos la prueba directa.
Relevancia: la tenemos que construir haciendo una primera etapa aparte, si bien ivprobit, twostep first nos da la salida de la primera etapa, no nos deja guardar estos resultados.
Por eso, si querés una prueba conjunta (F o Wald) y/o guardar resultados, tenés que correr la misma primera etapa por fuera con regress + test. 
Igual comparten estructura en estas primeras etapas. Por lo que es casi como si el comando ivprobit nos diera este estadistico.
Sobreidentificación: se tuvo que hacer aparte y no se puede usar nada del comando ivprobit. No existe un test integrado de sobreidentificación para ivprobit como en IV lineal; 
por ello implementamos un test auxiliar de exclusión (control-function), estimando un probit auxiliar e imponiendo la nula de que los instrumentos "extra" no entran directamente en la ecuación estructural.
*/




**# Probit-IV: CF (comando cfprobit)


****************************************************************************************************************
**************************          Modelo estilo CF: con un comando directo       *****************************
****************************************************************************************************************

** Estimaciones
/* Errores estandar de los coeficientes: Aunque el procedimiento conceptual es "dos pasos", Stata no usa la varianza ingenua de "dos pasos". 
	La documentación oficial del comando cfprobti remarca que esa VCE sería incorrecta y que cfprobit calcula los EE como si estimaras por GMM
	incorporando también las ecuaciones de primera etapa (referencia a Newey 1984). Por lo tanto, no hay necesidad de aplicar bootstrap a estos errores estandar de los coeficientes.
	Los podemos usar asi.
	De todas formas, tambien se pueden pedir errores estandar de los coeficientes por bootstrap si asi lo quisieramos, por ejemplo,
	para comparacion mas cercana a nuestro enfoque CF manual, pero solamente para los errores estandar de los coeficientes, no para los del APE como veremos.
	
	Si creemos que estamos en presencia de heterocedasticidad o de correlacion serial, siempre podemos pedir la matriz tipo sandwich, pero los errores estandar que son base del calculo
	de esta matriz de varianza robusta seran los correctos.
	
	APEs: con este comando podemos obtener los APE de forma directa con margins. Los errores estandar de estos APE son calculados por el metodo delta.
	      no nos dara errores estandar bootstrap para los APE. 

    Pruebas
	Exogeneidad: Postestimación trae estat endogenous, que testea (Wald) que los coeficientes de las control functions 
	            (y sus interacciones, si hay) sean cero. Eso es exactamente "test CF" bien hecho y ya integrado.
	Relevancia: cfprobit puede mostrar las primeras etapas con first, pero el comando está pensado como CF/GMM para la ecuación principal;
	           no te entrega "un paquete" tipo estat firststage/Stock–Yogo, etc. (al menos, no aparece como postestimación estándar en su manual).
    Sobreidentificación: En CF, lo típico es tratarlo como diagnóstico y tu Wald en probit auxiliar con instrumentos extra es una opción "Wooldridge-style"
	                    (pero seguirá siendo "aparte"; no esperes que cfprobit te lo dé listo). En el manual de cfprobit no aparece estat overid.
*/

** Coeficientes de segunda etapa + APE

* coeficientes con errores estandar correctos tras las dos etapas. Pero asumiendo homocedasticidad.
cfprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc)
* efectos parciales promedio con metodo delta, en base a los errores estandar anteriores que son correctos bajo homocedasticidad.
margins, dydx(*)  

* coeficientes con errores estandar correctos tras las dos etapas. Inferencia valida ante heterocedasticidad.      (vce(cluster id) para paneles por correlacion serial)
cfprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), vce(robust) 
* efectos parciales promedio con metodo delta, en base a los errores estandar anteriores que son correctos bajo heterocedasticidad.
margins, dydx(*)   

* coeficientes con errores estandar correctos tras las dos etapas. Inferencia valida ante heterocedasticidad al usar bootstraping.
cfprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), vce(bootstrap, reps(500)  seed(12345) nodots)
* efectos parciales promedio con metodo delta, en base a errores estandar anteriores que son correctos bajo heterocedasticidad.
margins, dydx(*)   


** elijo este modelo:
cfprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), vce(robust) 
margins, dydx(*) post
estimates store cfprobit_sob_ape

** prueba de exogeneidad (sale directo del comando)
cfprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc motheduc fatheduc), vce(robust)  
estat endogenous   // conjunta
estat endogenous nwifeinc   // si querés focalizar

* Fijar muestra efectiva del modelo: util para las dos pruebas que no salen directo del comando (relevancia y sobreidentificacion)
capture drop esamp
gen byte esamp = e(sample)


** relevancia (no sale directo) 
regress nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc motheduc fatheduc  if esamp, vce(robust)
test huseduc motheduc fatheduc

** sobreidentificacion stilo Wooldridge/CF (no sale directo)
*    - Tomo huseduc como instrumento "base"
*    - Testeo instrumentos extra: motheduc fatheduc
regress nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc motheduc fatheduc  if esamp, vce(robust)
predict double vhat if esamp, resid

* probit auxiliar con CF + instrumentos extra
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 vhat motheduc fatheduc if esamp, vce(robust)
test motheduc fatheduc



********************************************************************************************************
********************** COMANDO QUE HACE ESTIMACION CONJUNTA BIVARIADA DIRECTO **************************
********************************************************************************************************
	
**# Probit-IV: bivariado por MV condicional
	
*===========================================================*
* 6) IV PROBIT Bivariado por MV condicional 
*===========================================================*
* (esto implementa el enfoque tipo 15.48–15.50)
ivprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc fatheduc motheduc), ml vce(robust)

/* En la distribucion conjunta se estiman, ademas de todos los coeficientes del modelo, los parametros "rho" que es la correlacion entre u1 y v2
   y el desvio estandar de los residuos de la ecuacion de la variable endogena.
*/

matrix B = e(b)
matrix list B

scalar rho   = tanh(_b[/athrho2_1])
scalar sd_v2 = exp(_b[/lnsigma2])
scalar var_v2    = sd_v2^2   // o: exp(2*_b[/lnsigma2])

di "rho1 = corr(u1,v2)  = " %9.4f rho
di "sd(v2) = desvio estandar de los residuos de la ecuacion de la endogena  = " %9.4f sd_v2
di "var(v2) = varianza de los residuos de la ecuacion de la endogena  = " %9.4f var_v2 

nlcom ///
    (rho:   tanh(_b[/athrho2_1])) ///
    (sd_v2: exp(_b[/lnsigma2])) ///
    (v2:    exp(2*_b[/lnsigma2]))

	** observamos que rho no es significativo.
	** complementar con la prueba de exogeneidad que justamente prueba (H0: rho=0):  

* APE: aca debemos usar adicionalmente la opcion predict(pr). Obtenemos los error estandar de los APE por metodo delta.
margins, dydx(*) predict(pr) post
estimates store ivprobitML_sob_ape
 
* Prueba de exogeneidad 
ivprobit inlf educ exper expersq age kidslt6 kidsge6 (nwifeinc = huseduc fatheduc motheduc), ml vce(robust)
display as txt "Wald exogeneity test (H0: corr=0):  chi2 = " ///
    %9.3f e(chi2_exog) "   p = " %6.4f e(p_exog)

* Prueba Relevancia (no surge directo del comando)
quietly reg nwifeinc educ exper expersq age kidslt6 kidsge6 ///
    huseduc fatheduc motheduc if e(sample), vce(robust)
test huseduc fatheduc motheduc   // H0: instrumentos excluidos no explican nwifeinc


* Prueba sobreidentificacion (estilo wooldridge CF): no surge directo del comando
*    - Tomo huseduc como instrumento "base"
*    - Testeo instrumentos extra: motheduc fatheduc
regress nwifeinc educ exper expersq age kidslt6 kidsge6 huseduc motheduc fatheduc  if e(sample), vce(robust)
cap drop vhat
predict double vhat if esamp, resid
* probit auxiliar con CF + instrumentos extra
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 vhat motheduc fatheduc if e(sample), vce(robust)
test motheduc fatheduc









********************************************************************************************************
********************** TABLA COMPARATIVA FINAL **************************
********************************************************************************************************


**# TABLA COMPARATIVA FINAL

*  chequear que estén todas
estimates dir

esttab ///
    mpl_iv ///
    ape_probit_exo ///
    cf_just_apev cf_just_apes ///
    cf_sob_apev  cf_sob_apes ///
    ivprobit_sob_ape ///
    cfprobit_sob_ape ///
	ivprobitML_sob_ape ///
    , ///
    se label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MPL-IV" "Probit" ///
            "CF just-ID (V)" "CF just-ID (S)" ///
            "CF sobre-ID (V)" "CF sobre-ID (S)" ///
            "ivprobit twostep" "cfprobit" "ivprobit mle bivar.") ///
    stats(N, fmt(%9.0g) labels("N")) ///
    compress nogaps

	** aunque el test de exogeneidad siempre nos dio el mismo resultado: no hay evidencia de endogeneidad
	** es incomodo que el coeficiente del APE del probit exogeno sea 3 veces mas pequeño que el APE considerando VI (o el coeficiente del mpl-iv).
	** quitemos un poco de ruido, saquemos las dos columnas con instrumentos justo-identificados
	
esttab ///
    mpl_iv ///
    ape_probit_exo ///
    cf_sob_apev  cf_sob_apes ///
    ivprobit_sob_ape ///
    cfprobit_sob_ape ///
	ivprobitML_sob_ape ///
    , ///
    se label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MPL-IV" "Probit" ///
            "CF sobre-ID (V)" "CF sobre-ID (S)" ///
            "ivprobit twostep" "cfprobit" "ivprobit mle bivar.") ///
    stats(N, fmt(%9.0g) labels("N")) ///
    compress nogaps


	
*============================================================*
* TABLA COMPARATIVA (APEs / coef) – salida LaTeX con esttab
*============================================================*



* Tabla en LaTeX (booktabs, SE debajo, N al pie)
esttab ///
    mpl_iv ///
    ape_probit_exo ///
    cf_sob_apev  cf_sob_apes ///
    ivprobit_sob_ape ///
    cfprobit_sob_ape ///
	ivprobitML_sob_ape ///
    using "tabla_ap_es.tex", replace ///
    se label booktabs ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MPL-IV" "Probit" ///
            "CF sobre-ID (V)" "CF sobre-ID (S)" ///
            "ivprobit twostep" "cfprobit" "ivprobit mle bivar.") ///
    stats(N, fmt(%9.0g) labels("Observaciones")) ///
    compress nogaps

*============================================================*
* (opcional) versión en Word/RTF
*============================================================*
esttab ///
    mpl_iv ///
    ape_probit_exo ///
    cf_sob_apev  cf_sob_apes ///
    ivprobit_sob_ape ///
    cfprobit_sob_ape ///
	ivprobitML_sob_ape ///
    using "tabla_ap_es.rtf", replace ///
    se label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MPL-IV" "Probit" ///
            "CF sobre-ID (V)" "CF sobre-ID (S)" ///
            "ivprobit twostep" "cfprobit" "ivprobit mle bivar.") ///
    stats(N, fmt(%9.0g) labels("Observaciones")) ///
    compress nogaps

	
	