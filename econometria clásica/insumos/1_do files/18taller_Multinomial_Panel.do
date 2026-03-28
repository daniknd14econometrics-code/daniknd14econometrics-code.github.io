*** Capitulo 16 ***

clear all
bcuse keane, clear 
describe

* Ahora implementamos una estrategia de "efectos fijos" en el contexto de multiples categorias en datos de panel.
* en realidad, nos estamos refiriendo a incorporar la heterogeneidad inobserbable en el modelo.
* la forma mas parsimoniosa de hacerlo es mediante un enfoque CRE: promedios temporales.


* Declarar la estructura de panel y ordenar observaciones
xtset id year
sort id year

**# MNL: status

*====================================================================================*
* 1) Logit multinomial (MNL) con variables específicas del individuo + CRE (Mundlak)
*====================================================================================*

/* MNL: es un modelo LOGIT multinomial. Por lo tanto, la distribucion de los errores provienen de la distribucion logistica estandar.
		ver detalles en el libro/manuscrito en espaniol elaborado por mi.
		en este modelo, las covariables son identicas para cada alternativa (eleccion), pero se permite que los coeficientes sean distintos en cada alternativa.
*/


* Inspeccionar la variable dependiente y verificar que sea categorica NO ordenada
tabulate status

** Como vemos, las 3 opciones son: escuela, casa, y trabajo

mdesc lwage wage educ exper expersq manuf black y81 y82	y83	y84	y85	y86	y87 status

misstable summarize wage lwage educ exper expersq manuf black y81 y82 y83 y84 y85 y86 y87 status

** observar que no se puede usar wage (o lwage) como covariable puesto que el salario solo esta presente para la alternativa work
** dicho de otra manera, no hay salario en las alternativas "scholar" o "home". Por lo que si pones wage, se pierden todas las observaciones de las categorias scholar, home, etc
** y directamente se cae la posibilidad de estimar por un modelo de multiples opciones.


**# **# Medias temporales

** no necesitamos para la variable dependiente, tampoco para variables que no varian en i y en t.
bysort id: egen educ_bar  = mean(educ)
bysort id: egen exper_bar  = mean(exper)
bysort id: egen expersq_bar  = mean(expersq)
*bysort id: egen numyrs_bar  = mean(numyrs)

**# MLN-pooled


mlogit status educ exper expersq i.black y82-y87, baseoutcome(1) vce(cluster id)
margins, dydx(educ exper expersq black) post
estimates store ape_mln_pooled


// mlogit estima por MLE el modelo logit multinomial
// baseoutcome(1) fija la categoría "scholar" como 1 (normalización)
// vce(cluster id) pide errores robustos (útil ante heterocedasticidad + correlacion serial)
// deje un anio fuera (1981)
// ponemos i.black para que la interprete como binaria/categorica
// ojo: si incluimos muchas dummies, puede que tengamos problemas numericos en la estimacion.



**# MLN-CRE


mlogit status educ exper expersq i.black y82-y87 educ_bar exper_bar expersq_bar, baseoutcome(1) vce(cluster id)
margins, dydx(educ exper expersq black) post
estimates store ape_mln_cre


**# Prueba heterogeneidad inobserbable tipo Mundlak
mlogit status educ exper expersq i.black y82-y87 educ_bar exper_bar expersq_bar, baseoutcome(1) vce(cluster id)
test educ_bar exper_bar expersq_bar


**# TABLA COMPARATIVA FINAL

*  chequear que estén todas
estimates dir

esttab ape_mln_pooled ape_mln_cre, ///
    b se nolabel ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MLN" "MLN-CRE" ///
    stats(N, fmt(%9.0g) labels("N"))) ///
    compress nogaps





**# **# PCP

* Predicción por máxima probabilidad:
mlogit status educ exper expersq i.black y82-y87 educ_bar exper_bar expersq_bar, baseoutcome(1) vce(cluster id)
*mlogit status educ exper expersq i.black y82-y87, baseoutcome(1) vce(cluster id)
predict phat1 phat2 phat3, pr

/* 1) ¿Qué calcula predict phat1 ... phat3, pr?

Después de mlogit, Stata estima, para cada observación i y cada alternativa j (1,2,3), la probabilidad predicha
Pr(choice_{i}=j | x_{i})= exp(x_{i}′b_{j})/ (∑k=1,...,3 exp⁡(x_{i}′b_{k}).

Para la base (outcome 1), Stata normaliza b_{1}=0. Eso no significa que P_{i1}=0, sino que la utilidad sistemática de la base se fija a cero como referencia.
Con "predict ..., pr" Stata te devuelve esas probabilidades.

Entonces:

phat1 = P_{i1} = probabilidad predicha de escuela (1)
phat2 = P_{i2} = prob predicha de casa (2)
phat3 = P_{i3} = prob predicha de trabajar (3)

Chequeo simple (debería dar ~1 salvo redondeo):*/

gen psum = phat1+phat2+phat3
summ psum

** o sea: son probabilidades predichas por alternativa, tal como queríamos.

* Categoría predicha = argmax
gen yhat = 1
replace yhat = 2 if phat2>phat1 & phat2>=phat3 
replace yhat = 3 if phat3>phat1 & phat3>=phat2  

gen correct = (status==yhat) if !missing(status)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"


** da  79.54%.
** interesante que, sin enfoque CRE, el PCP es de 69.02%. Un poco menor.

** Interpretación: el clasificador "argmax" acierta más de la mitad de las veces, un poco por encima de 3/4. (Parece un rendimiento algo bueno si tengo en cuenta que al azar seria 1/3=0.33, un 33.33%)
**  Ojo con algo importante: este 79.54% es in-sample (en la misma muestra con la que estimaste). No es out-of-sample. 
** Si tuvieramos en un enfoque de prediccion de Machine Learning, es posible que el resultado de acierto de PCP sea bastante peor fuera de la muestra. Por eso para multiples categorias, en ML se usan otras tecnicas.

* Matriz de clasificación (real vs predicho)
tab status yhat, row

/* Tu matriz es la pieza clave. La diagonal (aciertos por categoría real) es:

status=1 (school):  73.92% correcto
status=2 (home):  56.48% correcto 
status=3 (work):  92.27% correcto 


*/

**# APRENDIZAJE


/* =====================================================================================
   INTERPRETACIÓN (para do-file): APEs en mlogit + por qué cambian con CRE (Mundlak)
   =====================================================================================

1) ¿Qué son los APEs que reporta `margins, dydx(...)` después de `mlogit`?

   - Stata reporta Average Partial Effects (APEs): el promedio muestral del efecto marginal.
   - En `mlogit`, `margins, dydx(X)` devuelve el efecto de cada covariable X sobre
     cada probabilidad predicha Pr(status==j).

   En tu caso:
     _predict 1 = Pr(status==1) = escuela
     _predict 2 = Pr(status==2) = casa
     _predict 3 = Pr(status==3) = trabajo

   Por eso, para cada variable (educ, exper, expersq, black) aparecen 3 filas:
   una por outcome/categoría.

2) ¿Por qué "interactúan" las probabilidades y por qué aparecen efectos en todas?

   En MNL:
		P_ij = exp(X_i * beta_j)
			--------------------
			sum_k exp(X_i * beta_k)

   Como el denominador incluye todas las alternativas, un cambio en X afecta
   simultáneamente todas las probabilidades. Entonces:
     - si sube Pr(trabajo), necesariamente deben bajar Pr(escuela) y/o Pr(casa) (y viceversa).
   Implicación práctica:
     - para cada variable, los APEs sobre outcomes suelen sumar aproximadamente 0
       (salvo redondeo), porque las probabilidades deben sumar 1.

3) ¿Cómo interpretar los APEs concretamente?

   - Para variables continuas (educ, exper, expersq):
       APE = cambio promedio (en puntos porcentuales si multiplicás por 100) en Pr(status==j) ante un aumento de 1 unidad en X.

   - Para variables factor/binarias (i.black):
       Stata reporta "discrete change from base level":  el cambio en Pr(status==j) al pasar de black=0 a black=1.

4) ¿Qué cambia al pasar de MLN pooled a MLN-CRE (Mundlak) y por qué los APEs pueden "darse vuelta"?

   En MLN-CRE agregaste promedios por individuo:
     educ_bar, exper_bar, expersq_bar

   Eso implementa un enfoque tipo Mundlak/CRE para capturar heterogeneidad inobservable
   correlacionada con X. Con esa parametrización:

     - Los coeficientes/APE de educ, exper, expersq se interpretan como efectos "within"
       (intra-individuo): cómo cambia la elección cuando X cambia en el tiempo dentro
       de la misma persona, manteniendo fijo su "tipo" promedio.

     - Los promedios (educ_bar, exper_bar, expersq_bar) capturan el componente "between"
       (diferencias permanentes entre individuos) y absorben parte de la selección.

   Por eso es esperable que:
     - Cambien magnitudes,
     - y hasta cambien signos,
   porque el pooled mezcla within + between, mientras el CRE separa esos componentes.

5) ¿Qué significa el test de Mundlak que hiciste?

   `test educ_bar exper_bar expersq_bar` con p-valor ~0 implica que
   los promedios son conjuntamente significativos => evidencia fuerte de que hay
   heterogeneidad inobservable correlacionada con X.

   Interpretación:
     - el pooled MLN es potencialmente sesgado por "tipo de persona" (efectos no observados),
     - y el CRE está más justificado porque controla esa correlación vía promedios.

===================================================================================== */

