/*------------------------------------------------------------------------------ 
						Causalidad (intro) en Stata 

						  Taller 1 Microeconometría 
------------------------------------------------------------------------------*/

**# Directorio de trabajo comun
clear all      
set more off
global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"

local username = c(username)
display "`username'"

local username = c(username)

if "`username'" == "Equipo" {
     global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"
}
else if "`username'" == "dmendez" {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"
}
else {
    global seteo "C:\Users\Equipo\OneDrive\Desktop\Notebook HP NEGRA\POSGRADO\MicroEconometría Aplicada\Talleres y Prácticos\1. Talleres\"
}


**# Base 1

use "$seteo\Directorio común bases\base1.dta", clear 
set more off


**# Exploro la base


describe
** no se trata de un panel. pero tengo un tratamiento. 



summarize

* ¿Qué sucede con las variables? ¿Presentan algún problema?

** claramente esta base es un "ejemplo de juguete".
** la variable tratamiento tiene la misma media  y desvio estandar que la variable dpto, pero ojo, no tienen porque ser identicas.*
** Ver comparacion para verlo. Seguramente fue generado asi a proposito.
compare treat dpto
** no son iguales.

** Por otro lado, ademas, dpto, en alusion a departamentos de uruguay, no tiene 19 niveles, tiene solo 1, que corresponde a montevideo.

rename dpto mont
label var mont "Montevideo"

** ademas edu (eduacion en años) tiene al menos un valor negativo. no puede ser. podriamos pensar que en lugar de -6, correspondia un 6.
** o podemos eliminar esa fila.


* reemplazar por 6 (solo si estamos seguros que correspondia a un 6)
tab edu 
preserve
replace edu = 6 if edu==-6
tab edu
restore

* o, para ser mas conservador, eliminamos esa fila:
tab edu 
sort edu
browse id edu
drop if id==830	


* salario también presenta un valor negativo.
sum salario, detail
sum salario
*Era la misma observacion (id==830) la que tenia un valor negativo en salario.


* Observar que ahora tenemos 999 observaciones (individuos) en la muestra.
	
* Observar correlaciones
pwcorr treat mont edu salario
corr treat mont edu salario

*Por un lado, las covariables (mont y edu) están correlacionadas positivamente
*con el tratamiento (Treat), por otro lado, las covariables estan correlacionadas 
*positivamente con la variable dependiente (salario).
** en particular, eduacion y salario estan tremendamente correlacionadas, casi 1!
** esto es porque se genero asi la base de juguete, evidentemente a cada nivel de educacion le corresponde un nivel determinado de salario, y van aumentando juntas a la par.


*-------------------------------------------------------------------------------

**# Diferencia de medias

* Parte A: 
* Diferencia de medias entre tratados y controles para las variables salario, educación y departamento
* (Realizar un test de medias entre tratados y controles para las variables salario, educación y departamento).

** Primero veamos una simple y poderosa tabla
tabstat mont edu salario, by(treat) stats(mean)

* El salario medio de los tratados es de 47523, mayor al salario medio de los controles 40359.
* El nivel de educación de los tratados es mayor al de los controles. (11.8 a 10.0 respectivamente).
* Montevideanos tratados son un 49% de los tratados, mientras que montevideanos no tratados son un 16% de los no tratados.
 
* pero, ¿es significativa la diferencia?: 
* NO PERDER DE VISTA QUE QUEREMOS TENER UN BUEN CONTRAFACTUAL. Para ello, necesitamos que ambos grupos, tratados y controles, tengan caracteristicas similares.
* Lo anterior implica que me gustaria que la diferencia de medias entre tradados y controles sea NO significativa en las caracteristicas observables.

** Test de medias
ttest salario, by(treat)
	* el error estandar (std err) hace referencia al error estandar asociado a la media estimada. 
	* Es decir, es lo que se usa para construir el intervalo de confianza del nivel medio estimado, en este caso, al 95%, basicamente +-(1.96)*(std err) y reconstruis los IC al 95%.
	* por su parte, la desviacion estandar, hacer referencia al desvio estandar muestral que tiene esta variable en la muestra. Lo confirmamos si hacemos:
tabstat salario, by(treat) stats(mean sd)

** ahora, regramos al test de medias:
ttest salario, by(treat)
	* diff = mean(0) - mean(1)
	* diff = 40359-47523 = -7163.819  ---> entonces la hipot. alternativa sería que la diferencia sea negativa. Prueba de una cola.
	* Ha: diff < 0 entonces Pr(T < t) = 0.0000 
	* t = -8.9937   (el estadístico observado nos da -8,99, hay que compararlo con valor critico)
	* El valor critico de la t-student para alpha de 0.05 es un valor que queda a la derecha de -8,99. 
	* -----(-8.99obs)---------------------(t_vc=-1.645 (creo))---------------(0)---------------
	*Entonces, cae fuera de la zona de aceptación de la hipotesis nula. 
	*Se rechaza que H0: diff = mean(0) - mean(1) = 0.
	*Ergo, no se rechaza que la diferencia en media en salarios sea significativa estadisticamente. (no es producto del azar tal diferencia)
	
ttest edu, by(treat)
	* diff = mean(0) - mean(1)
	* diff = -1.724498
	* Ha: diff < 0 entonces Pr(T < t) = 0.0000
	* t =  -8.6605
	* El valor critico de la t-student cae a la derecha del valor del estadistico observado. Es decir, esta fuera de la zona de aceptacion
	* de la hipotesis nula. Por tanto, se rechaza que H0: diff = mean(0) - mean(1) = 0.
	*Ergo, no se rechaza la hipotesis alternativa, Ha: diff < 0, para los años de eduacion. 

ttest mont, by(treat)
	* diff = mean(0) - mean(1)
	* diff = -0.3313253
	* Ha: diff < 0 entonces Pr(T < t) = 0.0000
	* t = -11.0880
	* No se rechaza la hipotesis alternativa.

*En suma, hemos visto que las diferencias en medias en observables, para tratados y controles, son significativas, 
* es decir, no atribuibles al azar, sino que son diferencias estadisticamente significativas.

*Por tanto, nuestros tratados y nuestros controles son personas con caracteristicas diferentes. Esto es malo.
*Si usaramos estos controles como contrafactuales de estos tratados: error de concepto!. Todo mal.

	
*-------------------------------------------------------------------------------

**# Regresion 


* Parte B: 
* Regresion MCO: E(Y/D) donde D es el tratamiento.


** recordemos el test de diferencia de medias.
ttest salario, by(treat)
** la diferencia en promedio entre controles y tratados es de -7163.819. 
** veamos una regresion de salario contra el tratamiento:
reg salario treat
** Nos da el mismo valor para el coeficiente: el coeficiente asociado a Treat(tratamiento) es igual a la diferencia de medias. (solo que ahora mean(1) - mean (0)), por ello el signo opuesto.
* Observar tambien que la constante es la media del salario de los no tratados (controles). (40359)

** incluso, como no usamos errores robustos a heterocedasticidad (ni controles, X), nos da el mismo error estandar asociado a este coeficiente.
** y de hecho, el valor del estadistico t es el mismo.

** pero en el contexto de regresion, podemos solicitar errores estandar robustos:
reg salario treat, vce(robust)
display _b[treat]


* ¿Es esto el efecto del tratamiento? ¿Por qué?

	*NO, porque existe sesgo de selección, entonces esta diferencia tiene, ademas del ATET, el sesgo de selección, y
	* este ultimo puede ser muy grande y jodernos por completo nuestro ATET. En particular, estamos usando a toda la muestra
	* con tratados y controles que recién vimos que no cumplen con el balance en observables,
	* por lo tanto, no es creible que cumplan el balance en INobservables, es decir, no es 
	* creible uncounfedness.

* Incorporar controles
* Regresion MCO: E(Y/D,X) donde D es el tratamiento y X son controles.

reg salario treat mont edu, robust
display _b[treat] = 100.0774
	* El programa de empleo aumenta en 100 pesos el salario de los tratados.  (¿será así?)
	* Notar que seguimos usando los mismos tratados y controles, que no tienen similares caracteristicas.
	* (y este es un ejemplo de juguete, basta con mirar el R2 de 1, un modelo totalmente irreal, deterministico)
	
* ¿Se puede realizar una interpretación causal? --> SIC
	* recordemos que SIC es el supuesto de independencia entre D, tratamiento, y X, los controeles.
	* Para realizar una interp. causal necesitamos que el supuesto de independencia condicional (SIC) sea creíble. El SIC nos dice que
	* los resultados potenciales deben ser ortogonales (independientes) del tratamiento condicional en las covariables.
	* Dado que nuestros test de hipotesis de diferencias en medias entre tratados y controles nos dieron que existen diferencias significativas
	* para todas las variables entre tratados y controles, parece dificil creer o convencer a alguien de que se cumple el supuesto de SIC.
	* en suma, no podemos interpretarlo como efecto causal dado que usamos gente como controles que son bastante diferentes de
	* la gente tratada, aun controlando por covariables, tengo inobservables que me joden la estimación.
	* veamos que pasa con Matching.
	
*-------------------------------------------------------------------------------

**# Propensity Score Matching: vecino mas cercano

* Parte C:
* Propensity-score matching con el metodo del vecino mas cercano

help teffects psmatch

**Stat
** ate	estimate average	treatment	effect	in	population;	the	default
** atet	estimate average	treatment	effect	on	the treated

** AI= errores estándar de Abadie-Imbens 


teffects psmatch (salario) (treat mont edu, probit), ate vce(robust, nn(3))
teffects psmatch (salario) (treat mont edu, probit), ate vce(robust)
teffects psmatch (salario) (treat mont edu, probit), ate 
teffects psmatch (salario) (treat mont edu, logit), ate 

	* ATE = 976
* ¿Interpretación? 976 es el efecto promedio del tratamiento en la POBLACION: pedimos el ate.
	* los tratados son, en promedio, $976 más ricos que los controles por haber sido tratados. 
	
** lo mismo pero con probit:	
teffects psmatch (salario) (treat mont edu, probit), ate 
** en este caso, con un modelo probit, el ATE (POBLACION) nos dice que los tratados son, en promedio, $1012 pesos mas ricos que los controles por haber sido tratados.


** Si queremos conocer el efecto promedio del tratamiento sobre los tratados, por haber sido tratados, esto es de $3614 pesos:
teffects psmatch (salario) (treat mont edu, logit), atet




describe

/*

_treated is a variable that equals 0 for control observations and 1 for treatment observations.
_support is an indicator variable with equals 1 if the observation is on the common support and 0 if the observatio is off the support.
_pscore is the estimated propensity score or a copy of the one provided by pscore().
_outcome_variable for every treatment observation stores the value of the matched outcome.
_weight. For nearest neighbor matching, it holds the frequency with which the observation is used as a match; 
		with option ties and k-nearest neighbors matching it holds the normalized weight; 
		for kernel matching, and llr matching with a weight other than stata's tricube, it stores the overall weight given to the matched observation. 
		When estimating att only _weight = 1 for the treated.
_id In the case of one-to-one and nearest-neighbors matching, a new identifier created for all observations.
_nk In the case of one-to-one and nearest-neighbors matching, for every treatment observation, it stores the observation number of the k-th matched control observation. Do not forget to sort by _id if you want to use the observation number (id) of for example the 1st nearest neighbor as in
. sort _id
. g x_of_match = x[_n1]
_nn In the case of nearest-neighbors matching, for every treatment observation, it stores the number of matched control observations.

*/
* Crear una variable que indique el match correspondiente a cada observacion
teffects psmatch (salario) (treat mont edu), gen(match)
	* Ver por ej. el match (7, 28)
sort id
browse

* Conservar solo las variables del inicio
keep id treat mont edu salario

