*** Capitulo 16 ***

clear all
bcuse pension, clear 

describe
tab pctstck
** la variable "pctstck" es la dependiente que es categorica ordenada.
** las covariables son: choice, age, educ, female, black, married, finc25;...; finc101, wealth89, and prftshr.

** esta base no tiene panel, pero la adaptacion seria facil: 
** seteamos periodo y tiempo;
** agregamos dummies temporales en la especificacion;
** usamos vce(cluster id)

**# Probit Ordenado

*==============================================================*
* 16.3.1 Probit/Logit ordenado: MLE, probabilidades, APEs
*==============================================================*

* Logit ordenado:
ologit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101  i.prftshr, vce(robust)

* Probit ordenado (sin intercepto explícito; los cutpoints lo absorben):
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101  i.prftshr, vce(robust)

** si tuvieramos datos de panel, agregariamos dummies temporales y vce(cluster id)
** de ahora en adelante, nos basamos en el modelo en base al probit ordenado.

* Probabilidades ajustadas por categoría: 
tab pctstck
* 0, 50 o 100.
margins, predict(outcome(0))
margins, predict(outcome(50))
margins, predict(outcome(100))

********************************************************************************
* INTERPRETACIÓN: PROBABILIDADES PREDICHAS POR CATEGORÍA (Ordered Probit)
********************************************************************************
* En el oprobit, la variable dependiente pctstck toma 3 categorías observables:
* pctstck e {0, 50, 100}. El modelo supone una variable latente continua y*:
*
*     y* = Xβ + u,     u ~ N(0,1)
*
* y las categorías se determinan por puntos de corte (cutpoints):
*
*     pctstck = 0    si   y* ≤ cut1
*     pctstck = 50   si   cut1 < y* ≤ cut2
*     pctstck = 100  si   y* > cut2
*
* Entonces, para un X dado, el modelo genera 3 probabilidades predichas:
*
*     Pr(pctstck==0 | X)
*     Pr(pctstck==50 | X)
*     Pr(pctstck==100 | X)
*
* Con:
*     Pr(pctstck==0 | X)   = Φ(cut1 - Xβ)
*     Pr(pctstck==50 | X)  = Φ(cut2 - Xβ) - Φ(cut1 - Xβ)
*     Pr(pctstck==100 | X) = 1 - Φ(cut2 - Xβ)
*
* En Stata, cuando corrés:
*     margins, predict(outcome(0))
* Stata reporta el PROMEDIO MUESTRAL de Pr(pctstck==0 | Xi) sobre todos los i.
*
* Por ejemplo, tus resultados:
*     Pr(pctstck==0)   = 0.3314
*     Pr(pctstck==50)  = 0.3702
*     Pr(pctstck==100) = 0.2984
*
* se interpretan así:
* "En promedio (sobre la muestra), el modelo predice que un individuo tiene:
*  33.1% de probabilidad de estar en pctstck=0,
*  37.0% de probabilidad de estar en pctstck=50,
*  29.8% de probabilidad de estar en pctstck=100,
*  dados sus valores observados de X."
*
* Importante: estas 3 probabilidades siempre suman 1 (salvo redondeos),
* porque son las probabilidades asignadas a TODAS las categorías posibles.
********************************************************************************



**# **#  APEs
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101  i.prftshr, vce(robust)
margins, dydx(*) post
estimates store ape_ord_probit_pctstck


********************************************************************************
* INTERPRETACIÓN: APEs (Average Partial Effects) EN ORDERED PROBIT
********************************************************************************
* Cuando corrés:
*     margins, dydx(*) post
* Stata calcula, para cada regresor, el efecto marginal sobre CADA probabilidad:
*
*     ∂Pr(pctstck==0)/∂x
*     ∂Pr(pctstck==50)/∂x
*     ∂Pr(pctstck==100)/∂x
*
* y después promedia esos efectos sobre todos los individuos de la muestra.
*
* Es decir, un APE es:
*     APE_k(outcome=j) = (1/N) * Σ_i  [ efecto de x_k sobre Pr(y=j | Xi) ]
*
* En ordered probit, el efecto marginal NO es constante: depende de Xiβ,
* por eso se calcula primero individuo por individuo y luego se promedia.
*
* Abajo van DOS interpretaciones didácticas:
* (A) una para variable continua
* (B) otra para variable discreta (dummy)
********************************************************************************


********************************************************************************
* (A) EJEMPLO DE APE PARA VARIABLE CONTINUA: age
********************************************************************************
* age es continua, así que el APE reportado por Stata es un DERIVADO:
*     dPr(pctstck==j) / dage
*
* Tus APEs para age:
*   outcome=0:    +0.016928
*   outcome=50:   -0.0007046
*   outcome=100:  -0.0162234
*
* Interpretación (en puntos porcentuales):
* - Para pctstck==0:
*   "Un aumento de 1 año en age incrementa en promedio la probabilidad
*    predicha de estar en pctstck=0 en 0.0169 (≈ 1.69 p.p.),
*    manteniendo constantes el resto de variables."
*
* - Para pctstck==50:
*   "Un aumento de 1 año en age cambia en promedio la probabilidad de estar
*    en pctstck=50 en -0.0007 (≈ -0.07 p.p.), un efecto casi nulo."
*
* - Para pctstck==100:
*   "Un aumento de 1 año en age reduce en promedio la probabilidad predicha
*    de pctstck=100 en 0.0162 (≈ 1.62 p.p.)."
*
* Nota clave (propiedad mecánica del ordered probit):
* Como las 3 probabilidades deben sumar 1, los APEs entre outcomes tienden
* a compensarse: si age aumenta la probabilidad de un outcome, típicamente
* reduce la de otro(s). De hecho:
*     0.016928 + (-0.000705) + (-0.016223) ≈ 0
*
* Esto no es una coincidencia: es una restricción de las probabilidades.
********************************************************************************


********************************************************************************
* (B) EJEMPLO DE APE PARA VARIABLE DISCRETA (DUMMY): 1.choice
********************************************************************************
* choice entra como factor i.choice, por lo cual 1.choice es un indicador
* (dummy) respecto a la categoría base 0.choice (la que Stata omite).
*
* En este caso, margins NO calcula un "derivado" (porque la variable no es
* continua). Calcula un CAMBIO DISCRETO:
*
*     ΔPr_j = Pr(pctstck==j | choice=1, X_otros) - Pr(pctstck==j | choice=0, X_otros)
*
* y luego promedia esa diferencia sobre la muestra.
*
* Tus APEs para 1.choice:
*   outcome=0:    -0.1281393
*   outcome=50:   +0.0103508
*   outcome=100:  +0.1177885
*
* Interpretación clara:
* - Para pctstck==0:
*   "En promedio, cambiar de choice=0 (categoría base) a choice=1 reduce
*    la probabilidad predicha de estar en pctstck=0 en 0.128 (≈ 12.8 p.p.),
*    manteniendo constantes las demás covariables."
*
* - Para pctstck==50:
*   "Ese mismo cambio incrementa la probabilidad predicha de pctstck=50
*    en 0.010 (≈ 1.0 p.p.)."
*
* - Para pctstck==100:
*   "Y aumenta la probabilidad predicha de pctstck=100 en 0.118 (≈ 11.8 p.p.)."
*
* Lectura económica directa:
* "Estar en choice=1, versus la categoría base, reubica masa de probabilidad
* desde el outcome más bajo (pctstck=0) hacia el outcome más alto (pctstck=100)."
*
* Recordatorio: Stata lo dice explícitamente al final:
* "dy/dx for factor levels is the discrete change from the base level."
********************************************************************************









**# **#  PCP (forma 1)
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101  i.prftshr, vce(robust)
predict phat1 phat2 phat3, pr
gen psum = phat1+phat2+phat3
summ psum
** tener en cuenta que las categorias estan etiquetadas como: 0, 50 y 100
egen pmax = rowmax(phat1 phat2 phat3)
gen yhat = .
replace yhat = 0 if phat1==pmax
replace yhat = 50 if phat2==pmax
replace yhat = 100 if phat3==pmax
gen correct = (yhat==pctstck)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"


**# **#  PCP (forma 2)
drop phat1 phat2 phat3 psum pmax yhat correct
* Predicción por máxima probabilidad:
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101  i.prftshr, vce(robust)
predict phat1 phat2 phat3, pr
gen psum = phat1+phat2+phat3
summ psum
** tener en cuenta que las categorias estan etiquetadas como: 0, 50 y 100
* Categoría predicha = argmax
gen yhat = 0
replace yhat = 50 if phat2>phat1 & phat2>=phat3 
replace yhat = 100 if phat3>phat1 & phat3>phat2 
gen correct = (pctstck==yhat) if !missing(pctstck)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"


** da 44.33%.
** Interpretación: el clasificador "argmax" acierta menos de la mitad de las veces. (Un rendimiento malo si tengo en cuenta que al azar seria 1/3=0.3333, un 33,33%. Mejora por poco margen el azar. )
**  Ojo con algo importante: este 44.33% es in-sample (en la misma muestra con la que estimaste). No es out-of-sample. 
** Si tuvieramos en un enfoque de prediccion de Machine Learning, es posible que el resultado de acierto de PCP sea bastante peor fuera de la muestra. Por eso para multiples categorias, en ML se usan otras tecnicas.

* Matriz de clasificación (real vs predicho)
tab pctstck yhat, row


*******************************************************************************

** si redefino pctstck, no cambiara nada:

gen invest = .
replace invest = 1 if pctstck == 0
replace invest = 2 if pctstck == 50
replace invest = 3 if pctstck == 100

oprobit invest age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101  i.prftshr, vce(robust)
margins, dydx(*) post
estimates store ape_ord_probit_invest


estimates dir

esttab ape_ord_probit_pctstck ape_ord_probit_invest, ///
    b se nolabel ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Ord-probit" "Ord-probit" ///
    stats(N, fmt(%9.0g) labels("N"))) ///
    compress nogaps

** efectivamente, no hay ningun cambio. 


*******************************************************************************



**# Probit Ordenado - CRE

** No tengo una base de datos de panel, pero aca se deja el codigo como si fuera el caso para esta base:
** debemos incorporar medias historicas para variables que varien en i y en t.

/*

*==============================================================*
*  Panel CRE (Mundlak): promedios temporales + pooled oprobit
*==============================================================*

* Suponga panel: id individuo, t tiempo.
* Crear promedios temporales (Mundlak) de regresores que varían en el tiempo:
bysort id: egen age_bar = mean(age)
bysort id: egen educ_bar = mean(educ)
bysort id: egen wealth89_bar = mean(wealth89)

* Probit ordenado - CRE
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr age_bar educ_bar wealth89_bar i.year, vce(cluster id)
**# **#  APEs:
margins, dydx(*) post
estimates store ape_ord_probit_pctstck_cre


* test heterogeneidad tipo mundlak
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr age_bar educ_bar wealth89_bar i.year, vce(cluster id)
test age_bar educ_bar wealth89_bar


**# **#  PCP (forma 2)
*drop phat1 phat2 phat3 psum pmax yhat correct
* Predicción por máxima probabilidad:
oprobit pctstck age educ wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr age_bar educ_bar wealth89_bar i.year, vce(cluster id)
predict phat1 phat2 phat3, pr
gen psum = phat1+phat2+phat3
summ psum
** tener en cuenta que las categorias estan etiquetadas como: 0, 50 y 100
* Categoría predicha = argmax
gen yhat = 0
replace yhat = 50 if phat2>phat1 & phat2>=phat3 
replace yhat = 100 if phat3>phat1 & phat3>phat2 
gen correct = (pctstck==yhat) if !missing(pctstck)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"

* Matriz de clasificación (real vs predicho)
tab pctstck yhat, row


*/
