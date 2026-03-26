**# CAPITULO 5: VI en SECCION CRUZADA

clear all 

*ssc install bcuse // una sola vez
*ssc instal overid

bcuse wage2, clear 
describe

gen expersq = exper*exper

**# MCO

* MCO estándar
regress lwage exper expersq educ
* MCO con errores estándar robustos a heterocedasticidad
regress lwage exper expersq educ, vce(robust)

**# 2SLS (VI)

*  2SLS homocedástico (matriz clásica): educ endógena, instrumentada con motheduc fatheduc 
ivregress 2sls lwage exper expersq (educ = meduc feduc)
* 2SLS con matriz robusta a heterocedasticidad (White-IV): educ endógena, instrumentada con motheduc fatheduc 
ivregress 2sls lwage exper expersq (educ = meduc feduc),  vce(robust)
 
 * 2SLS con matriz robusta agrupada (solo caso de panel/clusters naturales)
 * (por ejemplo, cluster por firma o región)
 * ivregress 2sls lwage exper expersq (educ = meduc feduc), vce(cluster id)
 

 **# HAUSMAN
  
 * Hausman directo: MCO vs 2SLS
 
 * 1) Estimar MCO
regress lwage exper expersq educ, robust
 * 2) Estimar IV/2SLS
ivregress 2sls lwage exper expersq (educ = meduc feduc),  vce(robust)
 * 3) Test de endogeneidad (Hausman)
 estat endogenous
 
 /*  estat endogenous contrasta MCO vs. IV/2SLS para las variables instrumentadas. El resultado clave es el p-valor:
 p-valor grande ⇒ no se rechaza exogeneidad de educ: MCO podría ser suficiente.
 p-valor pequeño ⇒ evidencia de endogeneidad: preferir IV/2SLS.
 */
 
** HAUSMAN "MANUAL"

* OLS
regress lwage exper expersq educ
estimates store ols
* 2SLS
ivregress 2sls lwage exper expersq (educ = meduc feduc)
estimates store iv
* Hausman
hausman iv ols, sigmamore
* hausman iv ols, sigmamore constant
  

** CONCLUIMOS QUE NECESITAMOS IV/2SLS
 
**# Relevancia IV
 
* Diagnósticos de primera etapa (relevancia de instrumentos)
ivregress 2sls lwage exper expersq (educ = meduc feduc),  vce(robust) first
estat firststage

 *-------------------------------------------------------
* F de primera etapa "a mano" (sólo instrumentos excluidos)
 *--------------------------------------------------------
reg educ exper expersq meduc feduc
test meduc feduc
* Versión robusta tipo White:
reg educ exper expersq meduc feduc, robust
test meduc feduc
 
* Mucho mas completo:
ivreg2  lwage exper expersq (educ = meduc feduc),  robust first
*ivreg2  lwage exper expersq (educ = meduc feduc),  cluster(id) first

/*
Weak	identification	test	(Cragg-Donald Wald F statistic):	64.607
			                 (Kleibergen-Paap rk Wald F statistic):	70.135
*/

/*
Los instrumentos son claramente relevantes: F de primera etapa ≈ 70, muy por
 encima de los valores críticos de Staiger–Stock y Stock–Yogo.
 
 El modelo está identificado (test de under-ID) y no presenta problemas de
 identificación débil según Cragg–Donald, KP y las tablas de Stock–Yogo.
 
 La inferencia sobre β2 es robusta incluso si uno se preocupa por weak IV, dado que
 los tests AR y Stock–Wright rechazan con fuerza H0 : β2 = 0.
 
 */
 
 **# Validez IV
 
**  Tests de sobreidentificación: Sargan y Hansen.

* 3.1 Sargan (asumiendo homocedasticidad)
ivregress 2sls lwage exper expersq (educ = meduc feduc)
estat overid // Sargan chi2(L-K)
 
* 3.2 Hansen-J robusto a heterocedasticidad
ivregress 2sls lwage exper expersq (educ = meduc feduc), vce(robust)
estat overid // Hansen-J chi2(L-K)
 
/* El test de Hansen no detecta problemas de sobreidentificación, lo que respalda la
 validez conjunta de los instrumentos usados. */
 
* 3.3 Hansen-J robusto a heterocedasticidad y cluster id
*ivregress 2sls lwage exper expersq (educ = meduc feduc), vce(cluster id)
*estat overid // Hansen-J robusto con clustering
 
 * Repetimos lo mismo pero usando ivreg2
 
** SARGAN (asumiendo homocedasticidad)
ivreg2 lwage exper expersq (educ = meduc feduc)
overid
 
** HANSEN robusto a heterocedasticidad
ivreg2 lwage exper expersq (educ = meduc feduc), robust
overid

** HANSEN robusto a heterocedasticidad y cluster id
*ivreg2 lwage exper expersq (educ = meduc feduc), cluster(id)
*overid


**# GMM2S 
 
******************* EXTRA: GMM ******************************
ivreg2 lwage exper expersq (educ = meduc feduc)
ivreg2 lwage exper expersq (educ = meduc feduc), gmm2s 
   
/* logicamente, que si asumimos homocedasticidad, no hay ganancia de eficiencia en la estimacion por 2SLS que por GMM en dos etapas*/
 
ivreg2 lwage exper expersq (educ = meduc feduc), robust
ivreg2 lwage exper expersq (educ = meduc feduc), robust gmm2s 

/* pero permitiendo heterocedasticidad, vemos que el gmm en dos etapas nos da desvios estandar levemente distintos de usar la opcion 2SLS. 
    Estos sd son un poquito mas pequeños. 
*/

*ivreg2 lwage exper expersq (educ = meduc feduc), cluster(id) gmm2s 

** si queremos usar esta version de estimacion y evaluar los instrumentos (no cambiara nada, solamente los desvios estandar recien vistos): 
 
ivreg2 lwage exper expersq (educ = meduc feduc), robust gmm2s first

 
 *********************************************************
 
 **# Pruebas de hipotesis
 
 ***************************************************************
 *********************** PRUEBAS DE HIPOTESIS ******************
 ***************************************************************
 
  
 * ============================================================
 * 1. Pruebas sobre un solo parámetro
 * ============================================================
 
 ivreg2 lwage exper expersq (educ = meduc feduc), robust
 *  H0: beta_educ = 0.145 (retorno del 14.5% por año)
 *  El comando test usa la matriz de varianzas 2SLS (robusta si vce(robust))
 
 test educ = 0.08
 *  El output reporta el estadístico chi2 y el F equivalente.
 *  Para N grande, el test t asociado es asintóticamente N(0,1).
 
 
 * ============================================================
 * 2. Prueba sobre una combinación lineal:
 *    retorno marginal de la experiencia en 10 años
 *    theta = beta_exper + 20*beta_expersq
 * ============================================================
 
 ivreg2 lwage exper expersq (educ = meduc feduc), robust
 * 2.1 Estimación e intervalo de confianza para theta
 lincom exper + 20*expersq
 
 * 2.2 Test de H0: theta = 0 <=> beta_exper + 20*beta_expersq = 0
 test exper + 20*expersq = 0

 * ============================================================
 * 3. Test Wald conjunto de exclusión:
 *    H0: beta_exper = 0 y beta_expersq = 0
 * ============================================================
 
 ivreg2 lwage exper expersq (educ = meduc feduc), robust
 test exper expersq
 
 * Esto implementa:
 * H0: beta_2 = 0, beta_3 = 0
 * usando la matriz de varianzas de 2SLS.
 * Stata muestra el chi2 (Wald) con Q=2 g.l. y el F aproximado F(2, N-K).
 * ============================================================
 
 
 * 4. Esquema de test LM (score) para exclusión de experiencia 
 *  (implementación manual siguiendo la construcción teórica)
 * ============================================================
 
 * 4.1 Modelo restringido (sin exper ni expersq), estimado por 2SLS
 ivregress 2sls lwage (educ = meduc feduc), vce(robust)
 predict u_tilde, resid // residuos restringidos \tilde{u_i}
 
 * 4.2 Primeras etapas para educ, exper y expersq sobre el conjunto de instrumentos z
*  z_i = (1, exper_i, expersq_i, motheduc_i, fatheduc_i, huseduc_i)

 regress educ exper expersq meduc feduc
 predict educ_hat, xb

 regress exper exper expersq meduc feduc
 predict exper_hat, xb
 
 regress expersq exper expersq meduc feduc
 predict expersq_hat, xb
 
 * 4.3 Regresión auxiliar del LM:
 * \tilde{u_i} = alpha_0 + alpha_1*educ_hat + alpha_2*exper_hat + alpha_3*expersq_hat + eta_i
 
 regress u_tilde educ_hat exper_hat expersq_hat
 
 * Si se desea seguir la teoría al pie de la letra,
 * se puede usar una regresión sin constante:
 * regress u_tilde educ_hat exper_hat expersq_hat, noconstant
 
 * 4.4 Cálculo del estadístico LM:
 * LM = N * R_u^2 (R^2 de la regresión auxiliar; típicamente no centrado)
 
 display "LM = " _N * e(r2)
 
 * Bajo H0: beta_2 = beta_3 = 0, LM ~ chi2(2) de manera asintótica.
 * Se rechaza H0 si LM > chi2(2, 1-alpha).
 
 * ============================================================
 * Comentario final:
 * En la práctica, para estas restricciones de exclusión,
 * el test de Wald/F vía 'test exper expersq' después de ivregress 2sls
 * es mucho más sencillo y asintóticamente equivalente al F_2SLS y al LM.
 * ============================================================
 

 regress u_tilde educ_hat exper_hat expersq_hat, noconstant
 display "LM = " _N * e(r2)

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
