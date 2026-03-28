*** Capitulo 15 ***
/**********************************************************************
TALLER (Wooldridge 15.8.1–15.8.2): lfp.dta
- Probit agrupado (pooled) con EE cluster(id)
- RE-probit: xtprobit, re con EE cluster(id)
- CRE-probit "agrupado": pooled probit + promedios individuales (Mundlak)
- Pruebas:
    (i)  Mundlak / "ci correlacionado con xit": test kidsbar=lhincbar=0
    (ii) Completitud dinámica: agregar rezagos (L1,L2) y test conjunto
    (iii) Exogeneidad estricta (diagnóstico): agregar adelantados (F1) y test conjunto
- Reportar siempre: Var(c_i) y s = sqrt(1+Var(c_i)) cuando corresponda (RE y CRE-RE)
- Tabla final: APEs comparables (3 modelos: Pooled, RE, CRE-pooled)
**********************************************************************/
 
version 17.0
clear all
set more off


*========================
* 0) Conseguir y cargar LFP
*========================
capture which frause
if _rc {
    di as txt "Instalando frause (datasets de Wooldridge)..."
    ssc install frause, replace
}

* Cargar la base
capture noisily frause lfp, clear
if _rc {
    di as error "No pude cargar lfp con frause."
    di as error "Plan B: probá (si tenés internet):"
    di as error "  net install frause, from(""https://fmwww.bc.edu/repec/bocode/f"") replace"
    di as error "y luego: frause lfp, clear"
    exit 601
}


describe
summ lfp black educ age	agesq kids hinc	


**# Declaro panel

*========================
* 1) Panel: id y year
sort id period
xtset id period

**# Probit agrupado

*========================
* 3) MODELO 1: PROBIT AGRUPADO (pooled) + EE cluster(id)
*    (omite c_i)
*========================
probit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5, ///
    vce(cluster id)
estimates store POOLED

* APEs (kids, lhinc, educ, black, age, agesq)
margins, dydx(kids lhinc educ i.black age agesq) post
estimates store APE_probit_pooled



**# Prueba de completitud dinamica (diagnóstico)

*======================================================================
* PRUEBA DE "COMPLETITUD DINÁMICA" (Wooldridge 15.64)
*
* Idea:
* 1) Estimar el probit pooled y obtener p_hat_it = F(x_it * b_hat)
* 2) Construir u_hat_it = y_it - p_hat_it
* 3) Estimar, para t = 2,...,T, el "modelo artificial":
*       P(y_it=1 | x_it, u_hat_i,t-1) = F(x_it*b + gamma1*u_hat_i,t-1)
* 4) Testear H0: gamma1 = 0 (un grado de libertad)
*
* Nota práctica:
* - Para LR/LM hay que usar exactamente la misma submuestra (t>=2) en
*   restringido y no restringido. Con vce(cluster) LR no es recomendable.
* - En la práctica (como dice Wooldridge), alcanza con mirar el z/t de gamma1
*   (Wald). Aquí lo hago con "test uhat_l1".
*======================================================================

* (A) Predicción del pooled probit (Modelo 1)
probit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5, vce(cluster id)
estimates store POOLED_nocs


estimates restore POOLED_nocs

capture drop phat_pooled uhat_pooled uhat_l1
predict double phat_pooled, pr
gen double uhat_pooled = lfp - phat_pooled

* (B) Rezago del residuo: uhat_{i,t-1}
*     Requiere xtset id period (ya lo hiciste).
gen double uhat_l1 = L1.uhat_pooled

* (C) Modelo artificial, SOLO t>=2 (porque uhat_l1 no existe en t=1)
probit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5 ///
    uhat_l1 ///
    if period>=2
estimates store POOLED_DYNTEST

* (D) Test 1 gdl: H0: gamma1 = 0
test uhat_l1
scalar p_dyn = r(p)

/*La intuición es directa:
  si existe dependencia dinámica omitida (o un efecto no observado persistente) que induce correlación serial en los residuos, 
  entonces uhat_l1 contiene información adicional sobre y_it más allá de x_it, y el coeficiente gamma1 tenderá a ser distinto de 0.
*/

di as txt "Completitud dinámica (Wooldridge 15.64): H0 gamma1=0"
di as txt "p-value = " %9.4f p_dyn


*======================================================================
* INTERPRETACIÓN DEL TEST DE COMPLETITUD DINÁMICA (Wooldridge 15.64)
*
* (1) Qué testea realmente:
*     Este NO es un test de "si faltan rezagos de x" en el índice.
*     Tampoco es un test estándar de endogeneidad tipo IV.
*     Es un diagnóstico específico: si el probit pooled está "dinámicamente completo".
*
*     La condición de completitud dinámica (15.63) dice, en esencia, que:
*       dado x_it, ni el pasado de y_it ni el historial de x_it aportan información adicional
*       para explicar y_it.
*     Bajo esa condición, el "residuo" u_it = y_it - F(x_it b) se comporta como una
*     diferencia de martingala (no hay correlación serial relevante) y por eso
*     la inferencia usual que trata observaciones en el tiempo como "no correlacionadas"
*     puede ser válida (varianzas ingenuas).
*
* (2) Cómo se implementa el test:
*     - Primero se estima el probit pooled y se calcula p_hat_it = F(x_it b_hat).
*     - Luego se aproxima el residuo poblacional u_it por:
*           uhat_it = y_it - p_hat_it.
*     - Después se estima el "modelo artificial" (t=2,...,T):
*           P(y_it=1 | x_it, uhat_i,t-1) = F( x_it*b + gamma1*uhat_i,t-1 )
*       y se testea H0: gamma1 = 0 (un grado de libertad).
*
*     La intuición:
*       Si hay dependencia dinámica omitida (p.ej. estado previo de participación)
*       o un componente persistente no observado (tipo c_i), entonces los residuos
*       van a estar correlacionados en el tiempo. En ese caso, uhat_i,t-1 contiene
*       información extra sobre y_it, y gamma1 tiende a ser distinto de 0.
*
* (3) Qué significa el resultado que obtuvimos (p-value = 0.0000):
*     Rechazamos H0: gamma1=0. Es decir:
*       uhat_i,t-1 "predice" y_it aun controlando por x_it.
*     Esto es evidencia muy fuerte de que (15.63) NO se cumple en estos datos:
*       hay persistencia/serialidad importante (puede estar inducida por heterogeneidad persistente c_i
*       y/o por verdadera dinámica en la decisión).
*
* (4) Por qué el coeficiente de uhat_l1 es enorme y el Pseudo R2 sube muchísimo:
*     uhat_i,t-1 = y_i,t-1 - p_hat_i,t-1.
*     Como y_i,t-1 es 0/1, uhat_i,t-1 queda muy ligado a y_i,t-1.
*     En participación laboral suele haber mucha persistencia (costos fijos,
*     preferencias, shocks persistentes, etc.), así que no sorprende que el test
*     rechace "por goleada".
*     IMPORTANTE: el tamaño del coeficiente de uhat_l1 NO se interpreta como un
*     "efecto estructural"; es un dispositivo para testear gamma1=0.
*
* (5) Nota sobre colinealidad y la dummy per5 omitida:
*     Al estimar el modelo artificial con la submuestra period>=2, las dummies de
*     período cumplen per2+per3+per4+per5=1. Con constante, una dummy sobra y Stata
*     omite una (acá omitió per5). No es un problema.
*
* (6) Relación con APEs y con 15.7.1:
*     Rechazar completitud dinámica NO implica automáticamente que los APEs pooled
*     sean "inconsistentes" como objeto reducido. Son cosas distintas:
*       - 15.7.1 discute casos donde, aun omitiendo heterogeneidad independiente,
*         el probit pooled puede identificar correctamente una probabilidad reducida
*         (integrada) y, por ende, APEs de esa probabilidad.
*       - El test 15.64 ataca la presencia de correlación serial/persistencia que hace
*         inválida la inferencia "iid en el tiempo" (varianzas ingenuas).
*     En práctica, como aquí usamos vce(cluster id) en el pooled, la inferencia ya está
*     robustecida contra correlación intra-mujer; el test se interpreta como evidencia
*     de dinámica/persistencia fuerte y como advertencia contra usar varianza ingenua.
*
* por lo tanto, hacemos bien en usar vce(cluster id).

*======================================================================




**# Prueba de exogeneidad estricta (diagnostico)


*========================
* 7) (Diagnóstico) EXOGENEIDAD ESTRICTA vía adelantados
*    Agregar F1 de kids y lhinc y test conjunto.
*========================
capture drop F1_kids F1_lhinc
gen double F1_kids  = F1.kids
gen double F1_lhinc = F1.lhinc

probit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5 ///
    F1_kids F1_lhinc, ///
    vce(cluster id)
estimates store POOL_LEADS

test F1_kids  F1_lhinc
scalar p_strict = r(p)

di as txt "Exogeneidad estricta (diagnóstico) (H0: adelantados = 0): p = " %9.4f p_strict

*===============================================================================
* (ii) OJO con cómo interpretar "rechazo" en la prueba de adelantados (leads)
*===============================================================================
* Este test es un diagnóstico:
* si x_{i,t+1} (un adelantado) ayuda a predecir y_{it} una vez que controlás por x_{it},
* eso sugiere que la hipótesis de EXOGENEIDAD ESTRICTA (en sentido fuerte) (15.65) no es creíble.
*
* Exogeneidad estricta aquí significa, a grandes rasgos:
*   - nada de feedback de y_it hacia x_it (ni inmediato ni anticipado),
*   - y ausencia de correlación entre x_it y shocks no observados relevantes para y_it,
*     en todos los períodos (pasado/presente/futuro).
*
*       POOLED:
*       Como no controlás heterogeneidad persistente c_i, el "rechazo" puede venir
*       simplemente de que x_{i,t+1} está correlacionado con c_i y c_i afecta y_{it}.
*       O sea: el lead test en pooled mezcla "endogeneidad" con "heterogeneidad omitida".

*===============================================================================
* (iii) Interpretación concreta de los resultados 
*===============================================================================
* - POOLED + leads:
*     Rechazo fuerte y con ambos adelantados (kids y lhinc)  -> señal clara de que
*     "exogeneidad estricta" NO es un supuesto cómodo en el pooled.
*

  

**# Probit CRE agrupado

*========================
*  MODELO: CRE "AGRUPADO" (Mundlak)
*    pooled probit + kidsbar + lhincbar + EE cluster(id)
*    Test Mundlak: H0 kidsbar=lhincbar=0
*========================

* Promedios individuales: diagnostico
xtset id period

xtsum lhinc kids

by id: egen sd_lhinc = sd(lhinc)
by id: egen sd_kids  = sd(kids)

summ sd_lhinc, detail
count if sd_lhinc==0

summ sd_kids, detail
count if sd_kids==0


capture confirm variable lhincbar
if _rc {
    bys id: egen double lhincbar = mean(lhinc)
    label var lhincbar "mean_i(lhinc)"
}


capture confirm variable kidsbar
if _rc {
    bys id: egen double kidsbar = mean(kids)
    label var kidsbar "mean_i(kids)"
}


corr lhinc lhincbar
corr kids  kidsbar
** kids practicamente no varia en el tiempo... por eso la correlacion entre kids y kidsbar es casi 1.
** la usamos igual, aunque numericamente puede dar problemas por colinealidad



probit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5 ///
    kidsbar lhincbar, ///
    vce(cluster id)
estimates store CRE_POOL


**# Prueba para c_i a la Mundlak

** prueba de: "ci correlacionado con xit"
* test conjunto (Hausman/Mundlak-type)
test kidsbar lhincbar 
scalar p_mundlak = r(p)

di as txt "Test Mundlak (H0: kidsbar=lhincbar=0): p-value = " %9.4f p_mundlak


* APEs bajo CRE pooled (para los x_it originales)
margins, dydx(kids lhinc educ black age agesq) post
estimates store APE_CRE_pooled


**# Prueba de exogeneidad estricta (diagnostico)


*========================
* 7) (Diagnóstico) EXOGENEIDAD ESTRICTA vía adelantados
*    Agregar F1 de kids y lhinc y test conjunto.
*========================
capture drop F1_kids F1_lhinc
gen double F1_kids  = F1.kids
gen double F1_lhinc = F1.lhinc

probit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5 ///
	kidsbar lhincbar ///
    F1_kids F1_lhinc, ///
    vce(cluster id)
estimates store POOL_LEADS_cre

test F1_kids  F1_lhinc
scalar p_strict = r(p)

di as txt "Exogeneidad estricta (diagnóstico) (H0: adelantados = 0): p = " %9.4f p_strict

*===============================================================================
* (ii) OJO con cómo interpretar "rechazo" en la prueba de adelantados (leads)
*===============================================================================
* Este test es un diagnóstico:
* si x_{i,t+1} (un adelantado) ayuda a predecir y_{it} una vez que controlás por x_{it},
* eso sugiere que la hipótesis de EXOGENEIDAD ESTRICTA (en sentido fuerte) (15.65) no es creíble.
*
* Exogeneidad estricta aquí significa, a grandes rasgos:
*   - nada de feedback de y_it hacia x_it (ni inmediato ni anticipado),
*   - y ausencia de correlación entre x_it y shocks no observados relevantes para y_it,
*     en todos los períodos (pasado/presente/futuro).
*
* Matiz clave según el modelo:
*   (1) POOLED:
*       Como no controlás heterogeneidad persistente c_i, el "rechazo" puede venir
*       simplemente de que x_{i,t+1} está correlacionado con c_i y c_i afecta y_{it}.
*       O sea: el lead test en pooled mezcla "endogeneidad" con "heterogeneidad omitida".
*
*   (2) CRE (Mundlak / CRE en pooled):
*       Al incluir promedios por individuo (xbar_i), ese canal se reduce.
*       Si AUN ASÍ un lead sale significativo (p.ej., F1_kids) y el test conjunto rechaza,
*       sugiere algo más estructural: esa variable no parece estrictamente exógena
*       (o, como mínimo, hay feedback/dinámica/anticipación que la especificación no captura).
*        
*===============================================================================
* (iii) Interpretación concreta de los resultados 
*===============================================================================
* - POOLED + leads:
*     Rechazo fuerte y con ambos adelantados (kids y lhinc)  -> señal clara de que
*     "exogeneidad estricta" NO es un supuesto cómodo en el pooled.
*
* - CRE + leads:
*     El rechazo lo empuja casi todo F1_kids (porque F1_lhinc no es significativo) -> lectura
*     natural: kids es el problema, probablemente por anticipación (embarazo/planes),
*     feedback de participación sobre decisiones familiares, o dinámica omitida fuerte.
  
  
   


**# RE-Probit 


*========================
* 4) MODELO 2: RE-PROBIT (xtprobit, re) + EE cluster(id)
*    Reportar Var(c_i) y s
*========================

xtprobit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5, ///
    re vce(cluster id)
	
* en Stata el "u" es el "c" de la notacion de Wooldridge.
scalar sigma_c_RE = e(sigma_u)
scalar var_c_RE   = sigma_c_RE^2
scalar s_RE       = sqrt(1 + var_c_RE)

di as txt "RE-PROBIT: sigma_c = " %9.4f sigma_c_RE ///
          " ; Var(c_i)= " %9.4f var_c_RE ///
          " ; s = sqrt(1+Var)= " %9.4f s_RE
		  
scalar invs = 1/sqrt(1 + e(sigma_u)^2)
display as txt "Inverso de s = " %9.4f invs
* o alternativamente mas directo:
display  sqrt(1 - e(rho))

* APEs bajo RE
margins, dydx(kids lhinc educ black age agesq) post


** vemos que aparecen muchos "." en las estimaciones, esto no es una buena señal.
** muchas veces esto es por colinealidad y en relacion con los metodos numericos usados.

/* CLAVE:
intpoints() no es un "detalle"; en RE-probit es literalmente la precisión con la que Stata aproxima la integral del efecto aleatorio. 
Con pocos puntos, la integral queda mal aproximada → el máximo de la verosimilitud puede moverse, la Hessiana puede quedar rara, aparecen "not concave" y hasta SE en ".".
En xtprobit, re, la probabilidad marginal requiere integrar sobre ci. Stata usa cuadratura Gauss-Hermite (adaptativa) para aproximar esa integral, y intpoints(K) es cuántos puntos de cuadratura usa.
Más puntos → más precisión, pero más tiempo.
por defecto: intpoints(12), podemos usar un valor mayor, este parametro va desde 4 hasta 195.

Tu propio resumen muestra ρ muy alto en algunos corridas y/o σ_u grande (en tu RE-Probit te dio σ_u≈4.36, ρ≈0.95). 
Cuando el efecto aleatorio es grande, la integral es más "difícil" → necesitás más puntos para que la aproximación sea estable.

Entonces: ¿qué valor "dejar"?
La regla práctica en estos modelos no es "K=12 siempre", sino:
Subí K hasta que (i) el log-likelihood y (ii) los parámetros/APE de interés se estabilicen.

**		resumen de probar con diferentes valores de intpoints:
** intpoints(4) da un invs=0.3297; coeficientes estimados y todas las iteraciones concavas
** kids	-.0335007   .0023838   -14.05   0.000	.0381728   -.0288287
** lhinc	-.0179985   .0032375    -5.56   0.000	-.0243439   -.0116531
** intpoints(5) da un invs=0.2344; ALGUNOS COEFICIENTES NO ESTIMADOS "." y algunas iteraciones no concavas
** kids	-.0119159   .0028237    -4.22	0.000	-.0174503   -.0063815
** lhinc   -.0050691   .0012012	-4.22	0.000    -.0074235   -.0027147
** intpoints(6) da un invs=0.2448; ALGUNOS COEFICIENTES NO ESTIMADOS "." y algunas iteraciones no concavas
** kids	-.0672019    .001441   -46.64	0.000	-.0700262   -.0643776
** lhinc   -.0257066   .0005512	46.64	0.000    -.0267869   -.0246262
** intpoints(7) da un invs=0.5446; coeficientes estimados y todas las iteraciones concavas 
** kids	-.0798141   .0044253   -18.04	0.000	-.0884876   -.0711405
** 	lhinc   -.0416653   .0053078	-7.85	0.000    -.0520685   -.0312622
** intpoints(8) da un invs=0.2398; ALGUNOS COEFICIENTES NO ESTIMADOS "." y algunas iteraciones no concavas
** kids	-.0553157   .0009393   -58.89	0.000	-.0571567   -.0534747
**	lhinc   -.0229948   .0003905	58.89	0.000    -.0237602   -.0222295
** intpoints(9) da un invs=0.3464; coeficientes estimados y todas las iteraciones concavas.
** kids   -.0511741   .0027679   -18.49	0.000    -.0565991   -.0457492
** lhinc   -.0270246   .0037821	7.15   0.000    -.0344374   -.0196119
** intpoints(10) da un invs= 0.2384; ALGUNOS COEFICIENTES NO ESTIMADOS "." y algunas iteraciones no concavas
**kids   -.0513013   .0007978   -64.31   0.000    -.0528649   -.0497377
** lhinc   -.0204675   .0003183   -64.31   0.000    -.0210913   -.0198437
** intpoints(11) da un invs= 0.2909; coeficientes estimados mas alla de  algunas iteraciones no concavas
** kids   -.0465458    .005557    -8.38	0.000    -.0574374   -.0356543
** lhinc   -.0192931   .0043387	4.45   0.000    -.0277967   -.0107895
** intpoints(12) da un invs=0.2152; ALGUNOS COEFICIENTES NO ESTIMADOS "."  y algunas iteraciones no concavas
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids	-.0463283     .01552    -2.99	0.003	-.0767469   -.0159098
** lhinc   -.0155674   .0021025	-7.40	0.000    -.0196881   -.0114466    
** intpoints(16) da un invs=0.2669; coeficientes estimados y todas las iteraciones concavas.
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids	-.0513761   .0028621   -17.95	0.000	-.0569858   -.0457663
**	lhinc   -.0210107    .003724	-5.64	0.000    -.0283097   -.0137117
** intpoints(20) da un invs=0.2669; coeficientes estimados mas alla de  algunas iteraciones no concavas
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids   -.0515619   .0060734    -8.49	0.000    -.0634655   -.0396582
** lhinc   -.0202845   .0045581	4.45   0.000    -.0292183   -.0113507
** intpoints(25) da un invs= 0.2494; coeficientes estimados y todas las iteraciones concavas.
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids	-.0513915   .0037449	13.72   0.000	-.0587313	.0440517
** lhinc	-.0189945   .0038696	-4.91   0.000	-.0265787	-.0114103
** intpoints(50) da un invs=  0.2413; coeficientes estimados y todas las iteraciones concavas.
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids   -.0517527   .0052908    -9.78	0.000    -.0621225   -.0413829
** lhinc   -.0184971   .0041467	4.46   0.000    -.0266246   -.0103697
** intpoints(75) da un invs= 0.2430; coeficientes estimados y todas las iteraciones concavas.
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids	-.0516734   .0050572	10.22   0.000	-.0615853	.0417615
** lhinc	-.0186312   .0041267	-4.51   0.000	-.0267194	-.010543 
** intpoints(99) da un invs=0.2429; coeficientes estimados y todas las iteraciones concavas.
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids	-.051696   .0050854	10.17   0.000	-.0616632	.0417288
** lhinc	-.0186313   .0041312	-4.51   0.000	-.0267283	-.0105344
** intpoints(190) da un invs= 0.2430; coeficientes estimados y todas las iteraciones concavas.
**			dy/dx	std.	err.	z	P>z     [95%	conf.	interval]
** kids	.0516946   .0050842   -10.17   0.000	.0616595   -.0417297
** lhinc	-.0186341   .0041314    -4.51   0.000	-.0267314   -.0105367
** intpoints(195) da un invs= 0.2430; coeficientes estimados y todas las iteraciones concavas.
** kids	-.0516946   .0050842   -10.17	0.000	-.0616595   -.0417298
** lhinc   -.0186341   .0041314	-4.51	0.000    -.0267314   -.0105367

Lectura:

Para K chicos (4–12) tenés saltos grandes en invs=1/s y APEs, y a veces "." en los SE o "not concave" en las iteraciones.
Desde K≈16 ya estás bastante cerca.
Desde K≈25 en adelante, tus APE de kids y lhinc se estabilizan muchísimo (y el invs=1/s se te mueve poco).
Entre 50, 75, 99, 190, 195 prácticamente no cambia nada relevante (salvo ruido numérico mínimo).

Recomendación:
Para reportar resultados finales (paper/tabla): intpoints(50)
Es el punto donde ya estás en zona "estable" y te evita sorpresas.
Si querés algo más liviano pero aún confiable: intpoints(25) o intpoints(30)
En tu resumen, desde ahí ya se ve convergencia fuerte.

*/

xtprobit lfp ///
    kids lhinc educ i.black age agesq ///
    per2 per3 per4 per5, ///
    re vce(cluster id) intpoints(40) 
estimates store RE

** ahora la salida ya no tiene ".", esto lo hace mas confiable.

* en Stata el "u" es el "c" de la notacion de Wooldridge.
scalar sigma_c_RE = e(sigma_u)
scalar var_c_RE   = sigma_c_RE^2
scalar s_RE       = sqrt(1 + var_c_RE)

di as txt "RE-PROBIT: sigma_c = " %9.4f sigma_c_RE ///
          " ; Var(c_i)= " %9.4f var_c_RE ///
          " ; s = sqrt(1+Var)= " %9.4f s_RE
		  
scalar invs = 1/sqrt(1 + e(sigma_u)^2)
display as txt "Inverso de s = " %9.4f invs
* o alternativamente mas directo:
display  sqrt(1 - e(rho))

* APEs bajo RE
margins, dydx(kids lhinc educ black age agesq) post
estimates store APE_RE_probit





  
**# RE-Probit-CRE 

*-----------------------------------------------------------
* Chamberlain-Mundlak en RE-PROBIT:
*incluir promedios temporales de regresores que varían en el tiempo.
*Esta especificación permite correlación entre heterogeneidad y x_it vía \bar{x}_i.
*
*-----------------------------------------------------------
* Versión "MLE" tipo RE (normalidad del efecto no observado + promedios)

xtprobit lfp ///
    kids lhinc educ i.black age agesq ///
	kidsbar lhincbar ///
    per2 per3 per4 per5, ///
    re vce(cluster id)  intpoints(40)
estimates store CRE_RE



** prueba de: "ci correlacionado con xit"
* test conjunto (Hausman/Mundlak-type)
test kidsbar lhincbar 
scalar p_mundlak = r(p)

di as txt "Test Mundlak (H0: kidsbar=lhincbar=0): p-value = " %9.4f p_mundlak



* en Stata el "u" es el "a" de la notacion de Wooldridge.
scalar sigma_a_CRE = e(sigma_u)
scalar var_a_CRE   = sigma_a_CRE^2
scalar s_CRE       = sqrt(1 + var_a_CRE)

di as txt "RE-PROBIT: sigma_a = " %9.4f sigma_a_CRE ///
          " ; Var(a_i)= " %9.4f var_a_CRE ///
          " ; s = sqrt(1+Var)= " %9.4f s_CRE

scalar invs = 1/sqrt(1 + e(sigma_u)^2)
display as txt "Inverso de s = " %9.4f invs
* o alternativamente mas directo:
display  sqrt(1 - e(rho))

** advertencia: dio diferente del 1/s=0.38 que esta en la tabla de Wooldridge

* APEs bajo CRE
margins, dydx(kids lhinc educ black age agesq) post
estimates store APE_CRE_probit

 ** Wooldridge multiplica por 1/s solo para comparar coeficientes del RE-probit (escala condicional) con los del pooled probit (escala marginal). Es una comparación pedagógica, no un paso requerido.
 ** el problema no es ese, porque uno puede dejar los APE reportados directos como salen, en la escala condicional lo cual esta bien, si el objetivo no es comparar con lo otro.
 ** el problema es que a mi me da un valor de 1/s diferente del de Wooldridge. Me da 0.22 y a el le da 0.38. De hecho, uno podria hacer una version reescalada usando el 0.22, tampoco llegara a -0.040, estara en -0.036 aprox.
 ** el efecto de kids.
 

 
 
**# FE-Logit
  
*-----------------------------------------------------------
*  Logit FE (CMLE): elimina c_i condicionando en n_i
*
*- Solo usa individuos con variación en lfp (0 < n_i < T)- Las variables constantes en el tiempo se omiten automáticamente (educ black age agesq)
*-----------------------------------------------------------
xtset id period
xtlogit lfp kids lhinc per2 per3 per4 per5, fe 
* Alternativa equivalente (conditional logit):
clogit lfp kids lhinc per2 per3 per4 per5, group(id) vce(cluster id)
* Nota: los coeficientes son efectos sobre log-odds; Stata no puede entregar APEs "estructurales" sin supuestos adicionales sobre c_i.  
  
  

  
**# Un poco de teoria

/**********************************************************************
INTERPRETACIÓN DE RESULTADOS (hasta acá)

DATOS
- Panel fuertemente balanceado: 5,663 mujeres (id) por 5 períodos (period=1..5).
- lfp es binaria (=1 participa en la fuerza laboral).
- "kids" y "lhinc" varían en el tiempo; mientras que "educ", "age", "agesq", "black" son (en esencia) de período 1
  (por eso su variación es principalmente "entre individuos", no "dentro de individuo").

 ** antes de interpretar, hagamos un repaso teorico:
 
 /**************************************************************************************************
INTERPRETACIÓN: ¿LOS APE DEL PROBIT AGRUPADO SON "CONSISTENTES" O NO?

En la subseccion 15.7.1 (heterogeneidad omitida "independiente"), Wooldridge muestra que el probit agrupado sin c_i puede
    entregar APEs consistentes (para el objeto correcto). La clave es que esto es cierto SOLO bajo supuestos fuertes
	(independencia entre c_i y las covariables x_it).
De hecho, el enfoque CRE existe para relajar en parte exactamente esa independencia.

-----------------------------------------------------------------------------------------------
1) Qué dice 15.7.1 y CUÁNDO el pooled APE es consistente

En 15.7.1 el escenario es "neglected heterogeneity" pero con un supuesto CENTRAL:

    - c _||_ x  (independencia, no solo covarianza cero)
    - normalidad (para que al integrar c el modelo siga siendo un probit con reescalamiento)

Bajo esos supuestos, aun si el probit agrupado estimado "sin c" no identifica el parámetro estructural b (porque
queda reescalado por un factor s), el punto importante es que:

    - La probabilidad reducida P(y=1|x) es el promedio (integración) de la probabilidad estructural
      sobre la distribución de c, y resulta ser un probit con índice reescalado.
    - El APE definido como "promedio (sobre c) del efecto parcial estructural" coincide con el efecto
      parcial de esa probabilidad reducida.

En castellano: si c es realmente independiente de x, podés ignorar c y aun así obtener APEs consistentes
(para el APE que promedia la heterogeneidad). O sea: el pooled probit puede estar "mal" en coeficientes
estructurales, pero "bien" para APEs promedio sobre c, gracias al reescalamiento.

IMPORTANTE: esto NO es una afirmación universal ("siempre funciona"), sino condicional al supuesto c _||_ x.

-----------------------------------------------------------------------------------------------
2) Por qué aparece la advertencia de "puede sesgar"

Cuando pasamos a panel, en la practica, el tema central es que ya NO se quiere asumir a priori que la heterogeneidad
individual de cada mujer c_i sea independiente de los regresores x_it.

La independencia relevante es más exigente aún en términos conceptuales:
    - No solo c_i independiente de x_it en un período,
    - sino independiente de la historia completa {x_it} 
	(intuición: que las mujeres con distinta c_i (propensión permanente a participar en este caso) no estén sistemáticamente asociadas a distintos niveles de kids, lhinc, etc.)

Si esa independencia falla, entonces:
    - El probit agrupado "mezcla" variación dentro de mujer (within) y entre mujeres (between),
    - y al omitir c_i puede atribuir a x_it diferencias que en realidad son diferencias persistentes entre mujeres
      (capturadas por c_i). En ese caso, los APE del probit agrupado dejan de ser consistentes para el APE estructural promediado.

Por eso, la advertencia "puede sesgar" NO contradice 15.7.1: simplemente está diciendo que el supuesto
que hacía funcionar la consistencia en 15.7.1 (c _||_ x) ya no es creíble.

-----------------------------------------------------------------------------------------------
3) Qué aporta CRE (Mundlak/Chamberlain) y por qué es una "prueba" relevante

El enfoque CRE (Mundlak/Chamberlain) modela la dependencia entre c_i y x_it usando los promedios individuales
xbar_i (en esta base: kidsbar, lhincbar). La lógica:

    - Si c_i está correlacionado con x_it, esa correlación suele manifestarse como relación entre c_i y el nivel promedio
      histórico de x_it (xbar_i).
    - Entonces, al incluir xbar_i en el probit "agrupado", se capta esa parte sistemática de la heterogeneidad correlacionada.
    - El test conjunto de coeficientes de xbar_i igual a cero es el test tipo Mundlak/Hausman:
          H0: coef(xbar)=0  (consistente con independencia: c_i no correlacionado con x_it)
          H1: coef(xbar)≠0  (evidencia de correlación: RE clásico/pooled bajo independencia es dudoso)

En los resultados, el test Mundlak (kidsbar=lhincbar=0) rechaza muy fuerte (p≈0.000).
Interpretación: hay evidencia de que la independencia c_i _||_ x_it no es compatible con los datos.

Entonces:
    - El resultado "benigno" de 15.7.1 (pooled APE consistente) deja de aplicar en la práctica, porque su supuesto clave (de independencia) falla.
    - Justamente por eso CRE es relevante: apunta a un modelo donde permitís esa correlación sistemática.

-----------------------------------------------------------------------------------------------
4) Cómo leer los APE de los tres modelos (POOLED, RE, CRE-pooled) sin mezclar objetivos

A partir de la teoría, los tres APE no están "compitiendo" por el mismo supuesto:

(1) Pooled probit (sin c_i):
    - Sus APE pueden interpretarse como consistentes SOLO si c_i es independiente de x_it (el caso "15.7.1").
    - Si el test Mundlak sugiere correlación, entonces no hay garantía de consistencia y puede haber sesgo.

(2) RE probit (xtprobit, re):
    - Modela c_i como aleatorio gaussiano y, en su versión estándar, mantiene la independencia respecto de x_it.
    - Si esa independencia falla, RE puede ser inconsistente como descripción estructural (o para APEs estructurales promedio).
	- por lo tanto, si no podemos sostener que c _||_ x , estos APEs tambien estaran sesgados. 
	- solo bajo c _||_ x, estos APEs seran consistentes, y ademas, necesitan el supuesto de "indepencia condicional" (15.67) que es un supuesto extra. 
	- podria ser mas eficiente quiza, pero bajo c _||_ x y bajo (15.67).

(3) CRE "agrupado" (pooled probit + xbar_i):
    - CLAVE: permite correlación entre c_i y x_it a través de xbar_i.
    - Por eso, cuando el test Mundlak rechaza, CRE es el camino natural para ajustar la especificación y producir APEs
      coherentes con un mundo donde c_i y x_it no son independientes.

-----------------------------------------------------------------------------------------------
5) Sobre "reporte de varianza y factor de escala s"

En modelos con heterogeneidad aleatoria (RE, y también CRE-RE si se estima con xtprobit re + xbar),
Stata reporta sigma_u (desvío estándar del efecto aleatorio). Es común reportar:

    Var(c_i) = sigma_u^2
    s = sqrt(1 + Var(c_i))

Interpretación pedagógica (conectada con 15.7.1): s actúa como factor de escala que "aplasta" el índice del probit
cuando integrás heterogeneidad normal. Esto ayuda a entender por qué en escenarios benignos el pooled identifica un
reescalamiento. Pero si c_i está correlacionado con x_it, ese argumento ya no salva la consistencia del pooled.

-----------------------------------------------------------------------------------------------
6) Conclusión operativa para este taller (según lo que salió en tus resultados)

- En estos datos, el test Mundlak rechaza (p≈0.000), lo que sugiere correlación c_i–x_it.
- Por lo tanto, la lectura "benigna" de 15.7.1 (pooled APE consistente aun omitiendo c_i) NO es el benchmark apropiado aquí.
- En este contexto, CRE es el modelo que está alineado con la evidencia empírica del panel, y el pooled queda como referencia
  (o como caso particular bajo un supuesto que parece fallar).

**************************************************************************************************/

*/



**# Tabla comparativa

*========================
* 8) TABLA FINAL: comparar APEs (3 modelos)
*    (requiere esttab / estout)
*========================
capture which esttab
if _rc {
    di as txt "No encontré esttab. Instalando estout desde SSC..."
    ssc install estout, replace
}

esttab APE_probit_pooled APE_RE_probit APE_CRE_pooled  APE_CRE_probit , ///
    se label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Pool-Probit" "RE-Probit" "CRE-Pool-Probit-" "CRE-Probit") ///
    stats(N, fmt(%9.0g) labels("N")) ///
    compress nogaps


**# Interpretacion de los resultados
	
/*

MODELO 1: PROBIT AGRUPADO (POOLED) con vce(cluster id)
- Signos "razonables" y altamente significativos:
  kids < 0: más hijos reduce la prob. de participación.
  lhinc < 0: mayor ingreso del esposo (en log) reduce participación.
  educ > 0: más educación aumenta participación.
  black > 0: efecto positivo y significativo en pooled.
  age > 0 y agesq < 0: perfil cóncavo con la edad.
- Efectos parciales promedio (APEs):
  magnitudes relativamente grandes (por ejemplo kids ~ -6.6 p.p. por hijo; lhinc ~ -7.0 p.p.).
- Lectura clave: este modelo "mezcla" variación dentro de mujer y entre mujeres,
  y además ignora heterogeneidad no observada persistente (c_i). Eso puede inflar o sesgar efectos.

MODELO 2: RE-PROBIT (xtprobit, re) con vce(cluster id)
- Estimación sugiere heterogeneidad individual MUY importante:
  sigma_u ≈ 4.54  => Var(c_i) ≈ 20.6
  rho ≈ 0.954     => fuerte correlación intra-individuo de la propensión latente.
  (Esto es consistente con que hay "tipos" de mujeres con distinta propensión permanente a participar.)
- APEs bajo RE:
  kids sigue negativo pero de menor magnitud que en pooled (~ -4.6 p.p.).
  lhinc se achica muchísimo (~ -1.6 p.p.).
  black pasa a no ser claramente significativo.
  => Interpretación: una parte grande del efecto pooled estaba capturando diferencias permanentes entre mujeres.
- ATENCIÓN TÉCNICA: en la salida del RE aparecen varios errores estándar como ".".
  Eso suele indicar problemas numéricos con la VCE robust/cluster (matriz singular o no bien calculada)
  aun cuando el punto estimado converge. Si necesitás inferencia sobre coeficientes (no solo APE),
  puede convenir: 
  (i) probar vce(oim) o vce(robust) sin cluster como chequeo, 
  o (ii) bootstrap por cluster,
  o (iii) reescalar/centrar covariables muy colineales (age y agesq) para estabilidad numérica.

MODELO 3: CRE "AGRUPADO" (Mundlak) = pooled probit + kidsbar + lhincbar
- kidsbar y lhincbar salen muy significativos y el test conjunto rechaza fuerte (p≈0.000).
  Lectura: hay evidencia clara de que c_i está correlacionado con X_it (al menos con kids y/o lhinc).
  => Por eso, el supuesto clásico de RE "c_i independiente de X_it" es dudoso.
- Dentro del CRE:
  - El efecto "within" contemporáneo de kids y lhinc (coef. de kids y lhinc) se achica
    respecto al pooled simple.
  - Los promedios (kidsbar, lhincbar) capturan el componente "entre" / persistente:
    mujeres con mayor kids promedio o mayor ingreso promedio del esposo tienden a participar menos.
- APEs CRE-pooled:
  quedan entre pooled y RE, pero más cerca de un efecto "within" depurado del componente permanente.

  
 /**************************************************************************************************
INTERPRETACIÓN: ¿Por qué el test Mundlak rechaza, pero los APE(RE) quedan cerca de APE(CRE)?

En estos resultados:

    APE pooled-probit  :    kids=-0.066 ; lhinc=-0.070
    APE RE-probit     :     kids=-0.052 ; lhinc=-0.019
    APE CRE-pooled-probit : kids=-0.039 ; lhinc=-0.010

y a la vez el test Mundlak (H0: kidsbar=lhincbar=0) rechaza fuerte (p≈0.000).

Esto NO es una contradicción. El test Mundlak y la cercanía numérica de APEs no miden lo mismo.

1) El "driver" principal acá es la magnitud de la heterogeneidad permanente:
   En RE-probit salió sigma_u grande (≈4.54) y rho ≈0.95. Eso sugiere que gran parte de la variación/persistencia
   en lfp se explica por diferencias permanentes entre mujeres (c_i).
   Cuando integramos una heterogeneidad tan grande (RE), las probabilidades se vuelven menos sensibles a x_it,
   y por eso los APE bajan mucho en magnitud respecto del pooled probit, que ignora c_i y tiende a inflar sensibilidad.

2) El test Mundlak (kidsbar, lhincbar) detecta correlación c_i–x_it (o, más precisamente, que la historia/promedio
   individual de x ayuda a explicar y). Eso puede afectar FUERTE los NIVELES (probabilidades) y la composición
   de quién está cerca del umbral, sin necesariamente cambiar enormemente la pendiente promedio (APE) respecto a kids o lhinc.
   En modelos no lineales, "correlación existe" no implica "APE cambia muchísimo": depende de cómo la correlación
   altera el índice y dónde cae la masa de observaciones (cerca o lejos del umbral).

3) Con N=28,315, rechazar H0 en Mundlak es fácil incluso si el efecto económico no es gigantesco.
   p≈0.000 significa "no es exactamente cero", no "la diferencia numérica en APE tiene que ser enorme".

4) Importante: que APE(RE) quede cerca de APE(CRE) NO valida el supuesto de independencia del RE.
   RE puede ser inconsistente si c_i está correlacionado con x_it, aunque en este dataset el APE resulte parecido.
   La comparación relevante es conceptual: pooled ignora heterogeneidad -> APE suele inflarse; RE integra heterogeneidad
   (y por eso se "encoge"); CRE intenta además capturar correlación sistemática vía promedios individuales.

Conclusión práctica: la gran distancia es (pooled) vs (RE/CRE) y es por la magnitud de Var(c_i). La diferencia APE-RE vs APE-CRE puede
ser más chica en APE aunque Mundlak rechace, porque el rechazo puede reflejar cambios de nivel y no necesariamente un cambio
grande en la pendiente promedio.

**************************************************************************************************/
 
  
*/




**# RE-Probit-CRE con SD por BOOTSTRAP


****************************************************************
* RE-Probit-CRE: APE puntuales (fijos) + SE bootstrap (cluster id)
* SIN locals / SIN foreach
****************************************************************

set more off
* 0) Chequeo panel
duplicates report id period

* 1) Guardar base original (porque simulate reemplaza el dataset en memoria)
preserve
tempfile base_original
save `base_original', replace

****************************************************************
* A) APE PUNTUAL FIJO (muestra completa) usando margins
****************************************************************
xtset id period

quietly xtprobit lfp kids lhinc educ i.black age agesq ///
    kidsbar lhincbar i.period, ///
    re intpoints(40) nolog 

quietly margins, dydx(kids lhinc educ 1.black age agesq) predict(pr)
matrix b0 = r(b)

scalar APE_kids0  = el(b0,1,colnumb(b0,"kids"))
scalar APE_lhinc0 = el(b0,1,colnumb(b0,"lhinc"))
scalar APE_educ0  = el(b0,1,colnumb(b0,"educ"))
scalar APE_age0   = el(b0,1,colnumb(b0,"age"))
scalar APE_agesq0 = el(b0,1,colnumb(b0,"agesq"))
scalar APE_black0 = el(b0,1,colnumb(b0,"1.black"))

****************************************************************
* B) Programa de UNA réplica bootstrap (cluster id) con margins
****************************************************************
capture program drop one_rep_ape_m
program define one_rep_ape_m, rclass
    version 15.0
    preserve

    bsample, cluster(id) idcluster(id_b)
    quietly xtset id_b

    quietly xtprobit lfp kids lhinc educ i.black age agesq ///
        kidsbar lhincbar i.period, ///
        re intpoints(16) nolog
    * pongo intpoints(16) para que no demore una eternidad, esto es para el bootstrap para los SE
	
    return scalar conv = e(converged)
    if (e(converged)==0) restore
    if (e(converged)==0) exit

    quietly margins, dydx(kids lhinc educ 1.black age agesq) predict(pr)
    matrix bb = r(b)

    return scalar ape_kids  = el(bb,1,colnumb(bb,"kids"))
    return scalar ape_lhinc = el(bb,1,colnumb(bb,"lhinc"))
    return scalar ape_educ  = el(bb,1,colnumb(bb,"educ"))
    return scalar ape_age   = el(bb,1,colnumb(bb,"age"))
    return scalar ape_agesq = el(bb,1,colnumb(bb,"agesq"))

    capture scalar __tmp = el(bb,1,colnumb(bb,"1.black"))
    if (_rc) return scalar conv = 0
    if (_rc) restore
    if (_rc) exit
    return scalar ape_black = __tmp
    scalar drop __tmp

    restore
end

****************************************************************
* C) Bootstrap SOLO para SE: simulate guarda las réplicas
****************************************************************
simulate ///
    conv=r(conv) ///
    ape_kids=r(ape_kids) ///
    ape_lhinc=r(ape_lhinc) ///
    ape_educ=r(ape_educ) ///
    ape_black=r(ape_black) ///
    ape_age=r(ape_age) ///
    ape_agesq=r(ape_agesq), ///
    reps(35) seed(12345) ///
	cluster (id): ///
    one_rep_ape_m

** en panel agregar "cluster (id)" como opcion en simulate

** puse solo 35 reps porque no quiero esperar mucho, asi y todo, ya demora como 1,5 hora. Si fuese para un paper, final, me tomo tiempo y pondria 200 reps quiza. Pero seria algo para una sola vez.

save "ape_boot_reps.dta", replace

drop if conv==0 | missing(conv)

* SE bootstrap = sd de las réplicas 
quietly summarize ape_kids
scalar SE_kids = r(sd)

quietly summarize ape_lhinc
scalar SE_lhinc = r(sd)

quietly summarize ape_educ
scalar SE_educ = r(sd)

quietly summarize ape_black
scalar SE_black = r(sd)

quietly summarize ape_age
scalar SE_age = r(sd)

quietly summarize ape_agesq
scalar SE_agesq = r(sd)

****************************************************************
* D) Guardar tabla final: APE puntual fijo + SE bootstrap
****************************************************************
clear
input str10 var double ape se
"kids"   . .
"lhinc"  . .
"educ"   . .
"black"  . .
"age"    . .
"agesq"  . .
end

replace ape = APE_kids0   in 1
replace se  = SE_kids     in 1

replace ape = APE_lhinc0  in 2
replace se  = SE_lhinc    in 2

replace ape = APE_educ0   in 3
replace se  = SE_educ     in 3

replace ape = APE_black0  in 4
replace se  = SE_black    in 4

replace ape = APE_age0    in 5
replace se  = SE_age      in 5

replace ape = APE_agesq0  in 6
replace se  = SE_agesq    in 6

save "ape_cre_re_table.dta", replace
*export delimited using "ape_cre_re_table.csv", replace

****************************************************************
* E) Volver a la base original
****************************************************************
use `base_original', clear
restore


preserve
use "ape_cre_re_table.dta", clear
format ape se %9.4f
list var ape se, noobs
restore

  
*******************************************************************************


**# Extension: VI en panel con probit

/**************************************************************************************************
NOTA (extensión práctica): cómo pensar endogeneidad + panel en probit (Wooldridge, cap. 15)

Contexto:
- Tenemos un panel corto (id-period) con y_it binaria.
- Sabemos que puede haber heterogeneidad no observada persistente c_i.
- Además, podemos sospechar endogeneidad de algún regresor "x_it^endo" (por simultaneidad, medición, etc.).
- En el libro, los enfoques "probit-VI" se discuten principalmente en contexto cross-section (sin panel). (ver talleres previos).
  Acá dejamos explícito cómo se pueden adaptar de forma práctica al panel corto.

-----------------------------------------------------------------------------------------------
ESTRATEGIA 1 (VIABLE): POOLED PROBIT + VI  (tomo el panel como pooled cross-section)
-----------------------------------------------------------------------------------------------
Qué hace:
- Trata el panel como un pooled cross-section: apila todas las (i,t).
- Corrige endogeneidad de "x_it^endo" usando instrumentos (IV/CF/FIML según el caso).
- Infiere con errores estándar robustos cluster(id), porque hay dependencia serial dentro de mujer.

Qué NO hace:
- No modela c_i explícitamente: la heterogeneidad persistente queda "dentro del error".
- Si c_i está correlacionado con x_it, la corrección IV puede no alcanzar para eliminar sesgo total:
  se corrige endogeneidad "puntual", pero queda el problema de heterogeneidad no observada correlacionada.

Cuándo sirve:
- Si el foco principal es la endogeneidad (tenés buenos instrumentos) y querés un pipeline claro,
  transparente y defendible con supuestos relativamente estándar.
- Útil como benchmark "con IV" y cluster(id).

Cómo reportar:
- Coefs + APEs (derivadas para continuas; cambios discretos para binarias/categóricas).
- Siempre cluster(id).

-----------------------------------------------------------------------------------------------
ESTRATEGIA 2 (VIABLE): CRE-POOLED (Mundlak) + VI  (pooled + promedios individuales + IV)
-----------------------------------------------------------------------------------------------
Qué hace:
- Mantiene el enfoque pooled (apilado), pero agrega promedios individuales xbar_i
  para capturar correlación sistemática entre c_i y x_it (idea Mundlak/Chamberlain).
- Luego, encima, trata endogeneidad de "x_it^endo" con instrumentos (igual que en cross-section).
- Infiere con cluster(id).

Qué cubre (intuitivamente):
- Parte del sesgo por heterogeneidad persistente correlacionada (vía xbar_i).
- El sesgo por endogeneidad del regresor sospechoso (vía VI).
- Es un "híbrido" pragmático: no es el modelo panel estructural completo como se puede obtener en el caso lineal, pero ataca dos frentes.

Qué NO garantiza:
- No convierte el problema en un "panel IV probit" plenamente estructural.
- Mundlak solo controla la parte de c_i que se puede aproximar linealmente con promedios de x_it;
  puede quedar heterogeneidad residual.

Cuándo sirve:
- Si el test Mundlak rechaza independencia (xbar_i significativos) y además te preocupa endogeneidad
  de un regresor particular.
- Suele ser la opción más razonable cuando querés robustez conceptual sin complejidad excesiva.

Cómo reportar:
- Reportar test Mundlak (H0: coef(xbar_*) = 0).
- Coefs + APEs del 
- Siempre cluster(id).

-----------------------------------------------------------------------------------------------
ESTRATEGIA 3 (EVITAR): RE-PROBIT + VI  (panel estructural con IV)
-----------------------------------------------------------------------------------------------
Por qué evitarla (en práctica aplicada):
- Obliga a especificar y defender una estructura conjunta compleja:
  (i) distribución del efecto aleatorio c_i,
  (ii) ecuación de endogeneidad/primera etapa,
  (iii) correlaciones entre shocks de ecuaciones,
  (iv) supuestos de normalidad conjunta y condiciones de independencia condicional.
- Es fácil que "ande" por ML pero difícil de diagnosticar: pequeños errores de especificación
  pueden sesgar bastante sin señales claras.
- En panel corto, identificación y robustez suelen ser frágiles; el costo de supuestos extra es alto.


-----------------------------------------------------------------------------------------------
Resumen operativo:
- Si querés un tratamiento IV claro y directo: usar (1) pooled probit + VI + cluster(id).
- Si además Mundlak rechaza independencia y querés controlar correlación c_i–x_it: usar (2) CRE-pooled + VI.
**************************************************************************************************/











