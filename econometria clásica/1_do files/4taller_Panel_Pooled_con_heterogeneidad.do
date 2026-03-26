**# Capitulo 10.1

clear all  
  
bcuse wagepan, clear
describe

* Declarar la estructura de panel y ordenar observaciones
 xtset nr year
 sort nr year

**# POOL-MCO con c_i
 
************************************************* POOL-OLS con presencia de Heterogeneidad inobservable: c_i *************************************************
**************************************************************************************************************************************************************


** Retomemos el caso del taller anterior, pero ahora asumamos que c_i se correlaciona con los regresores. Lo consideramos de forma explicita en nuestro POOL-OLS.

/* Si admitimos la presencia de un componente inobservable que es especifico de la unidad de observacion i, llamemosle c_i, 
   entonces sabemos que estimar por POOLED-MCO debe exigir algo mas que la exogeneidad contemporanea dada por POLS.1, E(x_it,u_it)=0.
   Ademas de ello, DEBE exigir que E(x_it,c_i)=0, que juntas forman la condición (22) del capitulo 10 del libro del autor.. 
   
   Pero entonces, si estimamos una regresión por POOL-OLS deberiamos preguntarnos, ¿es cierto que se cumple que (22) y, en particular, E(x_it,c_i)=0? 
   Si no podemos sostener este argumento, la estimación tendrá un sesgo por variable omitida ya que c_i es inobservable y a su vez estará correlacionado con los regresores. 
   */
   
  *MCO agrupado (pooled OLS) con varianza clásica:   lwage_it ​= β0​ + β1​educ_it ​+ β2​exper_it​ + β3​expersq_it ​+ β4​union_i + β5​married_i ​+ β6​black_i ​+ c_i​ + u_it​        (con c_i inobservable, nos queda v_it = c_i+u_it)
regress  lwage educ exper expersq union married black 
 
/* Dada la salida anterior, si sospechamos que elementos que podrian representar a c_i como la habilidad de la persona
   (si asumimos ademas que la habilidad no cambia en el tiempo, solo entre individuos), 
   están correlacionados con la educación, entonces esta regresión se "come" un sesgo por variable omitida, c_i.
   
   En modelos estaticos como el de este taller, a veces si se suele asumir que se cumple E(x_it,c_i)=0 (junto con E(x_it,u_it)=0), pero en este caso del taller no parece tan creíble esperar que E(x_it,c_i)=0: 
   En modelos con variables exogenas (regresores) rezagados, también se suele asumir que se podria cumplir E(x_it,c_i)=0 y E(x_it,u_it)=0, pero dependerá del contexto de esos datos su defensa. 
   En modelos con variable dependiente rezagada, se viola necesariamente la condición E(x_it,c_i)=0 y por tanto no se sostiene (22).
 
   Por otro lado, otra consecuencia de asumir que existe c_i, es que entonces será seguro que tiene consecuencias sobre la estructura de matriz de varianzas y covarianzas:
   esto es, si existe c_i, su presencia impone correlación serial a nivel del mismo individuo en el tiempo, por lo que estimar pool-ols con la matriz de varianza-covarianza homocedastica no es correcto, 
   pero tampoco alcanza con la versión robusta a la huber-white para heterocedasticidad de sección cruzada, tenemos que estimar con la versión robusta a todo: a la heterocedasticidad y a la correlacion serial. */ 
  
  *MCO agrupado con matrizde varianza robusta (cluster enid)
regress  lwage educ exper expersq union married black, vce(cluster nr)
 
 /* esto hace que ahora podamos usar el modelo para inferencia estadistica como las pruebas de hipotesis tipicas. 
   Pero debemos ser conscientes de que los coeficientes son los mismos, y por lo tanto, posiblemente sean sesgados si c_i está correlacionado con al menos uno de los regresores, 
   como podria ser con la educación en este caso. */

 * Podemos agregar dummies temporales como controles adicionales ya que disponemos de datos agrupados: lwage_it ​= β0​ + β1​educ_it ​+ β2​exper_it​ + β3​expersq_it ​+ β4​union_i + β5​married_i ​+ β6​black_i ​+ γ_t​ + c_i​ + u_it​

 regress lwage educ exper expersq union married black i.year, vce(cluster nr)

/* ahora los coeficientes cambian un poquito...: al incluir otros controles, hay mas información a priori. 
  Se puede ver que algunos coeficientes de año son significativos y otros no. 
   Observar que el F global del modelo cae respecto de la anterior regresion sin dummies temporales, y el R2 apenas aumenta.
   Pero ademas el R2 siempre aumenta cuando se agregan variables, lo que nos da la sensación que por parsimonia, en este caso, podria considerarse no incluir estas dummies de año.
   Veamos una prueba F de exclusión para las dummies temporales, para evaluarlo con rigor estadístico:
   */
   
**# Prueba para binarias temporales
   
 regress lwage educ exper expersq union married black d81 d82 d83 d84 d85 d86 d87, vce(cluster nr)
 test d81 d82 d83 d84 d85 d86 d87 

 /* No rechazá HO) d81=d82=...=d87=0 al 5%.
   Traducción: dado este modelo y esta varianza robusta agrupada, no hay evidencia fuerte de que los efectos de año sean distintos de 0 en promedio.
   Con estos controles y esta especificación, los años no están apareciendo como significativamente distintos de 1980 en el log-salario.
*/
  
**# Modelo final
  
 ** Entonces el "modelo final" será sin dummies por año y con la matriz de var-cov robusta por cluster como corresponde:
regress  lwage educ exper expersq union married black, vce(cluster nr)

/* si no podemos sostener el argumento de que E(x_it,c_i)=0, entonces estos coeficientes estarán sesgados: sesgo por variable omitida. Pero con inferencia válida.
Si por el contrario, tenemos una historia para sostener E(x_it,c_i)=0, entonces estos coeficientes son consistentes.  */
  
 
**************************************************************************************************************************************************************
**# opcional
 
** podemos analizar algo más que es muy didactico: el modelo pool-ols con todos los datos (usando vce(cluster nr)) 
** vs ols por cada seccion transversal (usando vce(robust) ya que no es posible modelar la correlacion serial):

regress  lwage educ exper expersq union married black, vce(cluster nr)
/* un error estandar de educ de  0.0089413 */

 regress  lwage educ exper expersq union married black if year==1980, vce(robust)
  regress  lwage educ exper expersq union married black if year==1981, vce(robust)
   regress  lwage educ exper expersq union married black if year==1982, vce(robust)
    regress  lwage educ exper expersq union married black if year==1983, vce(robust)
	 regress  lwage educ exper expersq union married black if year==1984, vce(robust)
	  regress  lwage educ exper expersq union married black if year==1985, vce(robust)
	   regress  lwage educ exper expersq union married black if year==1986, vce(robust)
	    regress  lwage educ exper expersq union married black if year==1987, vce(robust)
 
/* los errores estandar para educ están basicamente en el doble de tamaño: 0.015 aprox, lo que implica intervalos de confianza más amplios --> más imprecisión. 
   esta es una forma de ver que pool-ols es mejor que ols en corte transversal al usar más datos, y eligiendo bien la varianza estimada.
   ambos enfoques son susceptibles a "comerse" sesgo por variable omitida.
   -En corte transversal tenemos proxys o estrategias de variables instrumentales
   -mientras que en panel tenemos, ademas de proxy o de VI, la posibilidad nueva de modelar ese componenente c_i: ver en siguiente taller Modelos RE,FE,CRE.  
   
   asi que podriamos mejorar el modelo (regress lwage educ exper expersq union married black, vce(cluster nr)) si contaramos: 
   a) o con un buen proxy de c_i (proxy para la habilidad si entendemos que c_i en este caso es habilidad)
   b) o si contaramos con instrumentos para la endogena (educ) 
   c) o si implementamos alternativas propias de panel como RE/FE.
   d) o incluso estrategias VI-RE o VI-FE
   
   todo esto, tambien esta sujeta a la forma de la variable dependiente: una cosa es si es continua: todo barbaro. 
   Pero si es binaria: logit/probit 
              categorica: multinomiales
			  ordenada: probit/logit ordenados. 
   donde estos modelos son todos  'no lineales', y ya no es igual el tema de VI, ni el tema de RE o de FE. Eso te mete "en un lio".
   Para ello: capitulos 15 y 16 del libro de wooldridge. Ver talleres posteriores.
   
   En lo que sigue, tocará talleres para RE/FE, antes de meternos con variables dependientes no continuas.
  */
 
 
********************************************************************************************************************************************************************
**************************************************EXTRA (opcional): probar transformación del pooled mco en primera diferencia con c_i ******************************************* **********************************************************************************************************************************************************************
 
**# POOL-MCO en primera diferencia (opcional)
 
 /* Una manera de "lidiar" con c_i es transformar el modelo en niveles a un modelo en primeras diferencias. Esto hace que la variable inobservable c_i se elimine del modelo. 
    Pero también se eliminarán otras variables que no cambien a nivel de individuo en el tiempo, como es el caso de black. 
	
	Si hacemos esta transformacion a primeras diferencias, aunque c_i podria estar correlacionado con x_it (con al menos un regresor), es producto de la transformación que desaparece de la ecuacion a estimarse.
	Sin embargo, el costo que se debe pagar es doble: 
	Esta ecuacion en primeras diferencias sólo será consistente bajo el supuesto de "exogeneidad estricta", que es mucho más exigente que la POLS.1 (version debil de la exogeneidad contemporanea). 
	Parte de la condicion (22) corresponde justamente a POLS.1: E(x_it,u_it)=0.
	
	La exogeneidad estricta exige que el error de un periodo cualquiera, u_it, no este correlacionado con los regresores en ningun otro periodo. 
	(Tiene una version fuerte basada en medias condicionales y otra version debil basada en medias sin condicionar, pero en ambas es estricta.)
	Este costo puede ser bastante alto ya que en muchas ocasiones no podemos sostener este supuesto.
	El contexto del problema que estamos analizando hace muy dificil creer que ese supuesto se cumpla, ya que no alcanza con asumir exogeneidad contemporanea, sino que los errores
	de un periodo no podrian correlacionarse con los regresores en ninguno de los periodos (pasado, presente y futuro). 
	Esto hace que, contexto como modelos de evaluaciones de programas con participacion, modelos con rezagos distribuidos del regresor de interes, entre otros contextos, sea dificil justificar que se pueda cumplir la exogeneidad estricta:
	es decir, es dificil que encontremos una historia que nos justifique que en nuestro proceso generador de datos se cumpla la exogeneidad estricta. Es mas factible encontrar fundamentos que la violen en algun punto.
	Por otro lado, si se pretende modelar la variable dependiente como rezagada (modelo dinámico), esto necesariamente viola la exogeneidad estricta. 
	Con lo cual el modelo planteado en primeras diferencias, lidia con c_i, pero debe saberse que es consistente sólo bajo exogeneidad estricta.
	
	Por otro lado, perderemos las variables que no tienen variación en el tiempo para la observacion i, ejemplo: black siempre vale 1 o siempre vale 0 para la observacion i,
	no puede pasar que para la misma observacion, black una vez valga 0 y luego en otro año valga 1. 
	Esto ultimo impacta en la condicion de rango: Stata omitirá estas variables como black si la ponemos en la regresion, para que de todas formas nos arroje una estimación. 
	Ojo con variables que varien muy poco como married o union, pueden variar, pero poco y esto no es muy bueno. 
	
	En esta base de datos, tenemos un problema mayor, e inesperado:
	 en Wagepad la variable educ: es casi constante por persona, entonces cuando tomamos su primera diferencia, es practicamente 0 para todo el panel. 
	           en cuanto a exper, esta aumenta exactamente en 1 unidad por año para cada individuo (cuando no hay huecos), por lo que cuando tomamos su primera diferencia, es practicamente 1 en todo el panel. 
*/
 

*--------------------------------------------------------------
* Modelo en primeras diferencias
*   D.lwage sobre D.educ D.exper D.expersq, D.union, D.married i.year


xtset nr year
summ D.exper D.educ
reg D.lwage D.educ D.exper D.expersq D.union D.married i.year, vce(cluster nr)


* Nota:
* - D.educ se omite porque educ es constante por individuo:
*   educ_it = educ_i  =>  D.educ_it = 0 para todo t.
*   => no hay variación dentro de nr, no se puede identificar
*      el retorno a la educación con FD.
*
* - D.exper se omite porque exper aumenta exactamente en 1 por año
*   para cada individuo (perfil determinista):
*   exper_it = exper_i0 + (t - t0)  =>  D.exper_it = 1.
*   => D.exper es colineal con la constante (_cons).
*
* - D.expersq sí varía en el tiempo:
*   D.expersq_it = 2*exper_{i,t-1} + 1,
*   por eso captura la curvatura del perfil experiencia–salario.
*
* - D.union y D.married miden el efecto de CAMBIAR de estado
*   (por ejemplo 0->1) sobre el cambio en log(salario).
*
* - i.year en esta regresión no se diferencia como datos, pero
*   algebraicamente está parametrizando las diferencias de los
*   efectos de año (gamma_t - gamma_{t-1}) discutidos en la teoría.
*--------------------------------------------------------------


** comprobamos que se omiten d.exper y d.educ, no se pueden identificar para estos datos de wagepan. 
** Asi que en esta base de datos, la estrategia de Primeras Diferencias NO es factible. 

**# Nota: dummies de año en primeras diferencias

/* *--------------------------------------------------------------
* Nota sobre dummies de año en el modelo en primeras diferencias
*
* Modelo en niveles:
*   y_it = x_it*b + gamma_t + c_i + u_it
*
* Al tomar primeras diferencias:
*   Δy_it = b*Δx_it + (gamma_t - gamma_{t-1}) + Δu_it
*
* Es decir, los efectos de año no desaparecen: pasan a estar en
* forma de diferencias (gamma_t - gamma_{t-1}).
*
* En la práctica, esto se implementa de manera muy cómoda
* incluyendo dummies de año (i.year) en la regresión sobre
* las diferencias:
*
*   reg D.y D.x ..., i.year, vce(cluster id)
*
* Esas dummies ya están parametrizando los términos
* (gamma_t - gamma_{t-1}) hasta una constante (una categoría base).
*
* Por eso NO hace falta, ni tiene sentido práctico, intentar
* usar algo como D.i.year: el modelo con D.y, D.x e i.year es
* algebraicamente equivalente al modelo en primeras diferencias
* con los efectos de año diferenciados.

*--------------------------------------------------------------
* Versión didáctica: diferenciar explícitamente las dummies de año
* y comparar con la especificación estándar con i.year
*--------------------------------------------------------------
*/


tab year, gen(yd)
local J = r(r)
xtset nr year

forvalues j = 2/`J' {
    gen D_yd`j' = D.yd`j'
}

*  Modelo FD "estándar" con i.year
reg D.lwage D.educ D.exper D.expersq D.married i.year, vce(cluster nr)
predict xb_fd_std, xb

*  Modelo FD con dummies de año en diferencias
*    (usamos D_yd2,...,D_ydJ en lugar de i.year)
reg D.lwage D.educ D.exper D.expersq D.married D_yd2-D_yd`J', vce(cluster nr)
predict xb_fd_diff, xb

*  Comparación: los valores ajustados son (prácticamente) iguales
corr xb_fd_std xb_fd_diff if !missing(xb_fd_std, xb_fd_diff)

* La correlación ~ 1 muestra que ambos modelos generan el mismo ajuste:
* solo cambian los coeficientes porque es una reparametrización lineal
* del mismo conjunto de efectos de tiempo.
*--------------------------------------------------------------



