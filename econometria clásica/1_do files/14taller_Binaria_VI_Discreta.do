* Capitulo 15.

* En el taller previo vimos el caso en el cual tenemos una variable dependiente binaria y una variable endogena continua. 
* Bajo ese enfoque podemos estimar tanto por la estrategia de Control Function (un enfoque de residuo en dos etapas).
* o mediante el enfoque de estimar la log-verosimiltud conjunta de un modelo donde y1 es binaria pero y2 es continua,
* lo cual nos lleva a una log-verosimiltud que tiene una parte bernoulli (por y1) y una parte normal (por y2).
* Lo importante es que esta log-verosimiltud es diferente si, por el contrario, y2 fuese binaria. 

* En el presente taller, ahora la variable que suponemos endogena tambien es binaria.
* En este caso, como explica Wooldridge, se nos anula la estrategia de Control Function, ya que no nos arroja estimaciones consistentes de los APE.
* Por lo que el comando cfprobit lo abandonamos.
* Pero tambien debemos abandonar el comando ivprobit, ya que este comando esta hecho para log-verosimiltud que surje cuando y2 es continua. 
* El comando que usa la log-verosimiltud correcta para el caso donde y2 es binaria, es el comando biprobit.
* Para detalles de las log-verosimiltudes en un caso y en otro, ver el libro de wooldridge.

* Si pensamos por ejemplo, en el caso de estimar una binaria que representa si se esforzaron o no en innovar, entonces esa variable dependiente es binaria.
* Pero quiza en ese contexto, podria pasar que no tenemos una variable endogena siquiera. Y si la tenemos, si es continua, no estariamos en el caso de este taller, sino del caso del taller anterior.
* Pero si nuestra variable dependiente es, en cambio, la binaria que representa si innovaron o no, y dado que esto acontece luego de haberse esforzado, entonces ahora si,
* tenemos nuestra dependiente innova=1 como y1 que dependera de si se esforzaron o no, la binaria y2=1 si se esforzaron. En este caso, y2 claramente seria endogena, y dado que ambas son binarias,
* estamos en el caso del presente taller. Posiblemente sea de interes ver el impacto de y2 en y1, lo que incluso representa el efecto promedio del tratamiento (ATE). 
* Es decir, el efecto promedio de haberse esforzado sobre la probabilidad de innovar. Estos detalles se encuentran en el manual de Wooldridge.
* Eso si, hay que tener instrumentos no triviales para y2 para la identificacion.
* recordar que siempre podemos estimar, alternativamente, para referencia, el MPL-IV, asi como un MPL exogeno o un probit exogeno.

* Ojo, si la variable dependiente y1 fuese continua, pero y2 sigue siendo binaria (un tratamiento), entonces sigue pasando que y2 sera endogena en la ecuacion de y1, pero
* pero como y1 es ahora continua, no estariamos en el contexto de modelos de respuesta binaria, y en particular, no vamos a estimar este escenario con esta log-verosimiltud,
* sino que simplemente es un caso del mundo de los modelos lineales, con un regresor endogeno, que no importa si es binario o continuo, se trata igual. (ver teoria de IV-2SLS).

***************************************************************************

clear all
set more off
set seed 12345

use labsup, clear

describe 
summarize 

gen age2 = age^2

****************************************************************************
*************** Modelos de referencia para este caso ***********************
****************************************************************************

**# MPL (exogeno)
regress worked i.morekids nonmomi educ age age2 black hispan, vce(robust)
estimates store mpl  

**# Probit (exogeno)
probit worked i.morekids nonmomi educ age age2 i.black i.hispan, vce(robust)
*  APE promedio (margins usa método delta)
margins, dydx(*) post
estimates store  ape_probit

**# MPL-IV (justoid)
ivregress 2sls worked nonmomi educ age age2 black hispan (i.morekids = samesex), vce(robust)
estimates store mpl_iv   
* recordar que APE en MPL = coeficiente

ivregress 2sls worked nonmomi educ age age2 black hispan (morekids = samesex), vce(robust)
* Relevancia (1ra etapa) 
estat firststage
* validez (solo si hay sobreidentificación)
*estat overid

 
*************************************************************************
***************Biprobit con y2 = binaria y v2~N(0,1) ********************
*************************************************************************

**# Bi-Probit: dos probit conjuntos con VI

/*
El caso 15.7.3 es un recursive bivariate probit (dos ecuaciones probit con errores correlacionados, 
y y2 aparece como regressor en la ecuación de y1). Eso en Stata se estima por MLE con biprobit.

Opción A (directa y "Wooldridge 15.7.3"): 
biprobit estima modelos probit bivariados por máxima verosimilitud. 
Para el caso recursivo, lo clave es poner y2 en la ecuación 1:
biprobit (y1 = y2 z1) (y2 = z1 z2), vce(robust)
z2 son los instrumentos excluidos (idealmente al menos uno).
El parámetro de dependencia entre errores aparece como rho (o athrho internamente).
Esto corresponde a tu verosimilitud en términos de (⋅): una sola log-verosimilitud total que suma 
sobre i, evaluando cada observación en el "caso" que le toca (00,01,10,11).
*/

** Pero falta un pequeño ajuste: biprobit estima dos ecuaciones, una para worked y otra para morekids.
** En ambas ecuaciones las estima por probit, y de hecho las estima conjuntamente, por eso es un biprobit. 
** si hacemos un tab morekids vemos que solamente toma dos valores. ¿que pasa con morekids cuando entra como regresor en la ecuacion de worked?
**  es lo mismo para Stata ponerlo como morekids o como i.morekids a la hora de que nos calcule los coeficientes.
** Sin embargo, luego queremos pedir efectos parciales, por ejemplo, el efecto parcial promedio (APE) para cada coeficiente, y ahi si conviene ser claros con Stata,
** cuando pidamos el APE, es mejor indicarle sin rodeos a Stata si la variable z es binaria o categorica con "i.z" 
** Esto es porque al calcular un efecto parcial, si stata interpreta que es continua, entonces aplica la derivada parcial.
** pero si la variable es binaria o categorica, hay que ser claros con stata para que no haga la derivada en ese caso, si no que debe hacer la diferencia entre dos "indices" diferentes.

biprobit (worked = i.morekids nonmomi educ age age2 i.black i.hispan) (morekids = nonmomi educ age age2 i.black i.hispan i.samesex), vce(robust)
margins, dydx(*) 

/* Stata lo dice explícito:
Expression: Pr(worked=1,morekids=1), predict()
O sea: con biprobit, cuando vos ponés "margins, dydx(*)" sin especificar predict(), Stata usa por defecto la probabilidad conjunta 
P(y1=1,y2=1) (el caso "11", pero nos falta el caso "10"). Esto es estándar: en modelos bivariados, el default suele ser el evento conjunto 
Entonces el −0.1206 para morekids es el efecto marginal sobre: 
Pr(worked=1, morekids=1), no sobre Pr(worked=1).
*/

biprobit (worked = i.morekids nonmomi educ age age2 i.black i.hispan) (morekids = nonmomi educ age age2 i.black i.hispan i.samesex), vce(robust)
margins, dydx(*) predict(pmarg1) post
estimates store ape_biprobit

** AHORA SI: vemos que ahora si obtenemos el valor exacto de la tabla de Wooldridge.
** incluso un error estandar similar, mas alla que estos fueron calculados por metodo delta. 
biprobit (worked = i.morekids nonmomi educ age age2 i.black i.hispan) (morekids = nonmomi educ age age2 i.black i.hispan i.samesex), vce(robust)
margins, at(morekids=(0 1)) predict(pmarg1) post
lincom _b[2._at] - _b[1._at]
disp (.4550432 -  .7109564)

** Notar que este es el ATE(z1) = P(worked=1 | z1, morekids=1) - P(worked=1 | z1, morekids=0)


/*
Opción B (más general, soporta varios tipos de endogeneidad): comando eprobit
eprobit (extended probit) permite covariables endógenas continuas, binarias u ordinales y te deja especificar que la endógena es binaria vía "probit" dentro de endogenous(). 
Para tu caso:
eprobit y1 z1, endogenous(y2 = z1 z2, probit)
Esto también es MLE y, conceptualmente, está alineado con el modelo de 15.7.3 (dos índices latentes con errores correlacionados y varianzas normalizadas).
*/

eprobit worked nonmomi educ age age2 i.black i.hispan, endogenous(morekids = nonmomi educ age age2 i.black i.hispan i.samesex, probit) vce(robust)
margins, dydx(*) post
estimates store  ape_eprobit

/*
En eprobit, margins te reporta:
Average structural function probability
Eso corresponde a la probabilidad estructural del outcome, tipo:
Pr(worked=1 | intervengo morekids=0/1, x),
y por eso el APE de 1.morekids te da el famoso −0.256 que coincide con Wooldridge.

*/


**# BI-Probit: dos probit conjuntos EXOGENO

biprobit (worked = i.morekids nonmomi educ age age2 i.black i.hispan) (morekids = nonmomi educ age age2 i.black i.hispan), vce(robust)
margins, dydx(*) predict(pmarg1) post
estimates store ape_biprobit_exog




**# Tabla comparativa final

estimates dir

esttab ///
    mpl ///
    ape_probit ///
    mpl_iv ///
    ape_biprobit ///
    ape_eprobit ///
    ape_biprobit_exog ///
    , ///
    se label ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MPL" "Probit" ///
            "MPL-IV" ///
            "BIProb-VI" "eBIProb-VI" ///
            "BIProb") ///
    stats(N, fmt(%9.0g) labels("N")) ///
    compress nogaps

	
	
**# Prueba de exogeneidad

** si usamos el comando biprobit, podemos ver directamente en la salida esta prueba de exogeneidad
** alternativamente, tambien podemos solicitarla o armarla con la informacion que guarda el comando biprobit
** tambien podemos hacer lo mismo con el comando eprobit

**# Prueba de relevancia

** podemos armar una prueba pero no con estos comandos en forma directa, si no que lo que podemos hacer es una primera etapa como hicimos en el taller anterior.


**# Prueba de sobreidentificación

** en el caso de contar con mas de un instrumento no trivial, podriamos armar una prueba al estilo Wooldridge, como hicimos en el taller anterior.





