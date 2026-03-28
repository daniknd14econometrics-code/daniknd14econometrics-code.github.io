**# Capitulo 10

clear all  


use jtrain1, clear
describe
xtset fcode year  

**# RE: directo con xtreg

*--------------------------------------------------------------*
* 1. Estimamos por RE: 
     * incluimos las z_i: variables que solamente varian entre indiviudos pero no en el tiempo.
*    Calcular T_i y su promedio (Tbar)                         *
*--------------------------------------------------------------*


xtreg lscrap grant grant_1 d88 d89, re

**# Dimension T del panel: balanceado vs no balanceado

bys fcode: gen Ti = _N
summ Ti, meanonly
scalar Tbar = r(mean)

* con un panel balanceado, cada i tiene el mismo T, y entonces la formula para lambda es unica para todo i. (igual a capitulo 10)

*------------ con panel desbalanceado usar e(Tbar) -------------------
*help xtreg
*e(Tbar)                harmonic mean of group sizes
scalar Tbar_2 = e(Tbar)  
** con panel desbalanceado, cada i tiene un T diferente, y por lo tanto, cada i tiene un lambda diferente. 
** entonces deberiamos hacer cuentas algo artesanales: a nivel de individuo, ponemos Ti en lugar de T, para cada i. Esto nos arroja lambda_i.
** pero si no queremos tener N lambda_i diferentes, podemos luego de hacer eso, tomar un promedio. 
** Stata nos adelanta camino ya que nos da el promedio armonico de los T_i. El cual podemos usar en la formula de lamda (unico).
** Esto seria una forma que tenemos nosotros, y de forma rapida, de ver didacticamente como seria aplicar la formula teorica de panel balanceado en el caso de contar con un panel desbalanceado.
** Es como una solucion, rapida, pero no es una solucion completa.

**# Recupero parametros de varianza RE

*--------------------------------------------------------------*
* 2. Recuperar varianzas de RE                                *
*    sigma_c^2 = Var(c_i), sigma_u^2 = Var(u_it)               *
*--------------------------------------------------------------*
scalar var_c = e(sigma_u)^2   // componente entre (c_i)
scalar var_u = e(sigma_e)^2   // componente idiosincrático (u_it)

**# Recupero el parametro Lambda (theta)

*--------------------------------------------------------------*
* 3. Lambda tipo Wooldridge (cuasi-demean)                     *
*    λ = 1 - sqrt( σ_u^2 / (σ_u^2 + Tbar * σ_c^2) )            *
*--------------------------------------------------------------*
scalar lambda = 1 - sqrt( var_u / (var_u + Tbar*var_c) )
display "lambda (usando Tbar simple) = " lambda

scalar lambda2 = 1 - sqrt( var_u / (var_u + Tbar_2*var_c) )
display "lambda (usando Tbar armonico) = " lambda2

** en este caso, es un panel balanceado entonces T es unico para todo i, y por lo tanto, lambda es unico para todo i, como sucede en la teoria del cap 10. 
** el valor usando Tbar armonico coincide puesto que el panel es balanceado. Ambos coinciden.
** pero si el panel fuese desbalanceado, lamda sera diferente de lamda2. 
** Pero tener presenta que Stata no nos reportara lamda2: stata se toma el trabajo de hacer el calculo para cada i, es decir, calcula todos los lamnda_i y te informa sobre los percentiles claves de la distribucion de los lambda_i.
** Si queremos que nos informe Stata de ello, usar la opcion "theta".

**# Solicito el parametro Lambda (theta)

** podriamos obtener el lamnda con la opcion theta:
xtreg lscrap grant grant_1 d88 d89, re theta

** Con un valor de lambda de 0.80, la transformacion RE termina siendo parecida a aplicar la transformacion "demeaning" del within (lambda=1)
** los coeficientes de RE y FE tienden a ser similares en este caso.
** Es posible que no rechazemos la hipotesis nula del test de Hausman. 


**# RE: transformacion quasi_demeaning y luego POLS

*******************************************************************
********* hacer transformacion "cuasi-demeaning" para replicar RE
*******************************************************************

* Medias por individuo
bys fcode: egen lscrap_bar  = mean(lscrap)
bys fcode: egen grant_bar = mean(grant)
bys fcode: egen grant_1_bar = mean(grant_1)
bys fcode: egen d88_bar = mean(d88)
bys fcode: egen d89_bar = mean(d89)


* Transformación RE con lambda global
gen lscrap_re  = lscrap  - lambda*lscrap_bar
gen grant_re   = grant   - lambda*grant_bar
gen grant_1_re = grant_1 - lambda*grant_1_bar
gen d88_re     = d88     - lambda*d88_bar
gen d89_re     = d89     - lambda*d89_bar

* intercepto quasi-demeaned: cons = 1 - lambda
gen double cons_q = 1 - lambda

* Regresión RE "manual":
reg lscrap_re cons_q grant_re grant_1_re d88_re d89_re, nocons
xtreg lscrap grant grant_1 d88 d89, re



**# Comparacion RE vs FE: Hausman

******************************************************************
 ******************** PRE-HAUSMAN ***********************************
*****************************************************************

xtreg lscrap grant grant_1 d88 d89, re
xtreg lscrap grant grant_1 d88 d89, fe

** los coeficientes son algo parecidos.
** otras cosas a evaluar
				* si se eligiera RE: justificacion de que los c_i no se correlacion con los regresores.
							* un fundamento puede venir de que, estimando por FE, esta correlacion es cercana a 0 (-0.0714). 
							* otro fundamento puede venir de que este lambda es de 0.80, parece cercano a 1 que seria la transformacion within (FE)
							* usar RE permite controlar por variables que no varian en el tiempo.
							* alguan otra argumentacion economica.
				* si se eligiera FE: justificar que se tiene argumentos para sostener la correlacion a pesar de ese valor de -0.07. (y no significativo)
							* uno va en la linea de que esta correlacion se basa en la estimacion de unos c_i que tienen el problema de "parametros incidentales" 
							* y en este caso, con T=3, es probable sean inconsistentes: correlacion poco confiable.
				            * otro va en la linea de que, por otro lado, quiza el lambda 0.80 si bien es alto, no es exactamente igual a 1 (es como si esos 0.20 son lo suficientemente relevantes), puede ser mas rebuscado.
							* teoria economica que no confie en una correlacion estadistica baja (asociado a parametros incidentales). 
							* 
** tenemos otra via estadistica para decidir si hay correlacion de los c_i con los regresores o no la hay (RE.1B), y eso la hipotesis nula implicita que se evalua en el test de Hausman. 
** si el test de hausman no se rechaza, nos indica que no rechaza que los regresores no se correlacion con los c_i, lo que nos lleva a implementar el modelo RE.
** si el test de hausman se rechaza, nos indica que rechazamos que los regresores no se correlacionen con los c_i, lo que nos lleva a usar el modelo FE.
* pero hay que tener cuidados extras: 1) rechazo fuerte de la HO), mientras que observamos diferencias insignificantes entre los coeficientes de RE y FE. 
*                                        Si bien el test nos sugiere usar FE, es razonable reportar tambien los resultados de RE. 
*									2) no rechaza la HO), mientras que se observan grandes diferencias entre los coeficientes de RE y FE. 
* 										En ese caso, no conviene confiar ciegamente en usar RE por el resultado del test, ya que esto puede ser peligroso.
*										la ausencia de rechazo puede deberse a falta de potencia (error de tipo II) y no a que RE.1B sea valida. 

* EN CONCLUSION: ademas de mirar el test de hauman, debemos evaluar si las distancias entre los coeficientes RE vs FE son chicas o grandes y acompañar el analisis para la toma de decision. 
* no basta solo con el test de hausman. 
** tiene sentido complementar el análisis haciendo cosas como:
* 1) Mirar los intervalos de confianza de FE y RE por separado.
* 2) Mirar la diferencia en términos relativos entre los coeficientes,
*    por ejemplo: |b_FE - b_RE| / |b_FE|.
* 3) Redactar algo del estilo:
*    "El Hausman no rechaza, pero la diferencia de magnitud entre los
*     coeficientes FE y RE es X%."
* Todo esto aporta información sobre el tamaño de efecto, no sobre la
* significancia estadística en el sentido estricto del test de hipótesis.

* incluso, tener en cuenta el diseño del panel, el contexto economico de los datos, y otros diagnosticos como por ejemplo:
* 								la importancia de introducir en la especificacion las variables que no varian en el tiempo (si son muy importantes, inclina a usar RE).


*****************************************************************
********************** HAUSMAN ********************************
*****************************************************************



* 1. Estimamos por RE:  no incluimos las dummies temporales.
	 
/**********************************************************************
* TALLER: PRUEBA DE HAUSMAN (FE vs RE) Y VERSIÓN MUNDLAK (ROBUSTA)
* Basado en Wooldridge, secc. Hausman: RE.1–RE.3 y exogeneidad estricta
***********************************************************************/


* Modelo de trabajo (mismas regresoras en FE y RE):
* y_it = lscrap_it
* w_it = (grant_it, grant_1_it)    -> variables que cambian en i y t
* dummies de año: d88, d89         -> efectos de tiempo puros
*
* OJO: teóricamente el Hausman compara el vector δ de regresores que cambian en i y t (w_it).
* Las dummies de año se incluyen en ambos modelos para no sesgar nada, pero la interpretación del test es sobre 'grant' y 'grant_1' (las que tienen variación dentro de firma).

/**********************************************************************
* A) HAUSMAN "CLÁSICO", BAJO RE.3
*    - Ambos modelos con varianza clásica.
*    - RE es eficiente bajo H0; FE y RE consistentes bajo H0.
***********************************************************************/



* FE con varianza clásica (RE.3)
* Modelo reducido SOLO con las variables que varían en i y t
xtreg lscrap grant grant_1, fe
estimates store FE_clasico


* RE con varianza clásica (RE.3)
* Modelo reducido SOLO con las variables que varían en i y t
xtreg lscrap grant grant_1, re
estimates store RE_clasico

* Test de Hausman clásico
* - 'sigmamore' fuerza que las dos matrices de varianza usen un parámetro de varianza común basado en el estimador eficiente (RE).
*   Esto es lo que encaja con la derivación teórica estándar del Hausman (Wooldridge, Stata manual).
hausman FE_clasico RE_clasico, sigmamore


* Después, para el modelo "final" que vas a reportar, volvés a estimar FE/RE con las dummies de año y hacés la inferencia ahí.


* Interpretación:
* - H0: Cov(c_i, w_it) = 0  (supuesto RE.1b válido)  -> RE consistente y eficiente.
* - H1: Cov(c_i, w_it) != 0 -> RE inconsistente; FE sigue siendo consistente.
*
* - Si el p-valor es chico (5% o 1%) => evidencia contra H0 -> usar FE.
* - Si el p-valor es grande         => no hay evidencia fuerte contra H0 -> es razonable RE; 
*   en ese caso RE es una opción razonable, pero igual conviene mirar las diferencias de magnitud entre coeficientes FE y RE (tamaño de efecto).

** En nuestro caso: no rechazamos HO, por lo tanto, parece razonable estimar por RE.
*    comparar : |b_FE - b_RE| / |b_FE| para cada beta



/**********************************************************************
* B) ¿Y SI ESTIMO FE Y RE CON ERRORES TIPO CLUSTER?
*
*  - xtreg ... , vce(cluster id) rompe la "historia clásica":
*      * RE deja de ser estrictamente eficiente,
*      * la matriz Var(b_FE - b_RE) != Var_FE - Var_RE de forma limpia,
*      * la χ2 del Hausman clásico se vuelve dudosa y la matriz puede
*        dejar de ser definida positiva (errores, chi2 negativa, etc.).
*
*  - Práctica razonable (Wooldridge):
*      1) Usar el Hausman clásico como test de especificación. (sin opcion vce(cluster id) y sin variables que no varien tanto en i como en t)
*      2) Elegido el modelo, reestimar ese modelo con vce(cluster id) para la inferencia e incorporando las dummies temporales (y, ademas, si se elige RE, tambien variables invariantes en el tiempo).
***********************************************************************/

* RE con errores agrupados (para el modelo final de inferencia) y con las dummies temporales. (por ahora no incluye otra dummies como efecto industria)
xtreg lscrap grant grant_1 d88 d89, re vce(cluster fcode)
estimates store RE_cluster

* FE con errores agrupados (si eventualmente decidieramos usar FE) y con las dummies temporales.
xtreg lscrap grant grant_1 d88 d89, fe vce(cluster fcode)
estimates store FE_cluster

* NOTA IMPORTANTE:
*   NO es recomendable hacer: hausman FE_cluster RE_cluster
*   porque el Hausman clásico no está diseñado para matrices robustas/cluster
*   aquí y puede dar matrices no definidas positivas o resultados difíciles
*   de interpretar. Para un test totalmente robusto, usamos Mundlak.


**# Comparacion RE vs FE: test basado en especificacion CRE (Mundlak)

/**********************************************************************
* C) VERSIÓN MUNDLAK (HAUSMAN ROBUSTO VIA VARIABLE ADDITION)
*
*  Idea (Mundlak + Wooldridge):
*  - Parametrizar c_i = c + (w̄_i)'ξ + a_i.
*  - Bajo H0 (RE válido): ξ = 0  -> c_i no correlacionado con medias de w_it.
*  - Basta estimar un modelo "correlated random effects" agregando w̄_i
*    y hacer un test de Wald sobre ξ = 0.
*
*  Ventajas:
*  - Se puede usar vce(cluster firm) o cualquier VCE robusto.
*  - El coeficiente de w_it coincide con FE (si se arma bien).
***********************************************************************/


*--------------------------------------------------------------*
* C1. Construir medias temporales de las variables w_it        *
*     (acá: grant y grant_1)         *
*--------------------------------------------------------------*
drop grant_bar grant_1_bar
bys fcode: egen grant_bar    = mean(grant)
bys fcode: egen grant_1_bar  = mean(grant_1)

*--------------------------------------------------------------*
* C2. Estimar el modelo tipo Mundlak con efectos aleatorios   *
*     y error robusto/cluster                                  *
*     y_it = z_i'γ + w_it'δ + w̄_i'ξ + (a_i + u_it)            *
*
*  - En la especificacion de Mundlak, que se estima por RE, podemos agregar:
*  - dummies temporales y tambien variables que no varian en el tiempo (z_i)
*  - Entonces:
*  - Incluimos d88 y d89 como parte de x_it (efectos de tiempo).
*  - Incluimos grant_bar y grant_1_bar como regresores extra: el corazon de la especificacion de Mundlak.
*  - podemos optar por incluir variables z_i como podria ser union, por ejemplo. 

/*

Dummies de tiempo en Mundlak: sí, incluirlas, porque así CRE se parece al modelo que realmente vas a reportar.

Variables z_i: Teóricamente, sí conviene incluirlas. 
               Pedagógicamente, se puede decidir incluirlas o no según qué tan alineado quieras que esté el test con el Hausman clásico que corriste antes.
               Lo importante es que expliques: "Este test de Mundlak está chequeando la correlación entre c_i​ y las medias de w_it, condicional en [conjunto de regresores que tengo en el modelo]".
*/


* Si estimamos la especificacion de Mundlak, los coeficientes asociados a w_it (es decir, δ) coinciden para esta estimacion (CRE) con una estimacion por FE para estos coeficientes:
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar, re
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar, fe
** se comprueba que  grant y  grant_1 son identicos (solo es valido para este vector w_it). ¿y si agregamos una variable z_i, por ejemplo, union?
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar union, re
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar union, fe
** sigue pasando que los coeficientes grant y  grant_1 son identicos.

* Test de "hausman" basado en CRE:

*el modelo RE "usual" sin el vector w_bar (grant_bar y grant_1_bar) es justamente el caso restringido ξ=0. 
* Bajo la parametrización c_i = c + w̄_i' ξ + a_i:
*  H0 (RE válido)   : ξ = 0  -> coeficientes de medias temporales = 0
*  H1 (FE preferido): ξ != 0

xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar, re
estimates store CRE_mundlak_clasico
* Test de Wald conjunto sobre las medias temporales (Hausman)
test grant_bar grant_1_bar

* Interpretación del test de Mundlak:
* - Si no rechazás H0: ξ = 0  -> evidencia consistente con RE.1b;
*   RE "tradicional" es una especificación razonable.
* - Si rechazás H0: ξ != 0  -> medias temporales correlacionadas con c_i;
*   RE clásico es inconsistente; FE (o CRE con Mundlak completo) es preferible.

* Bajo esos supuestos (homocedasticidad + estructura RE estándar), el Wald sobre grant_bar grant_1_bar es asintóticamente equivalente al Hausman clásico.
* Eso es lo "limpio algebraicamente" pero poco realista empíricamente.

* El valor agregado de Mundlak es justamente que te permite hacer un Hausman robusto, o sea:
*--------------------------------------------------------------*
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar, re vce(cluster fcode)
estimates store CRE_mundlak_robust
test grant_bar grant_1_bar





*-------------------------------------------------------------------------------------------
 ************* DECISION FINAL: RE **************
	 
*--------------------------------------------------------------*
* Interpretación conjunta: Hausman, theta y Mundlak   y decision *
*--------------------------------------------------------------*
* 1) Valor de theta (λ) en el modelo RE:
*    - theta ≈ 0.80, es decir, la transformación RE está bastante
*      cerca de la transformación FE (theta = 1 implica FE puro;
*      theta = 0 implica pooled).
*    - Esto anticipa que los coeficientes de FE y RE serán numéricamente
*      muy similares, algo que se puede comprobar comparando las tablas.
*
* 2) Test de Hausman (FE vs RE):
*    - No se rechaza H0: Cov(c_i, x_it) = 0.
*    - Bajo esta lectura, RE es consistente y eficiente, por lo que,
*      desde el punto de vista del test, la elección natural es RE.
*    - Refuerza coeficientes similares entre RE y FE.

*
* 3) Estrategia de Mundlak:
*    - Al incluir las medias temporales de los regresores que varían
*      en el tiempo (w̄_i: grant_bar, grant_1_bar) en un modelo RE
*      ampliado (CRE-Mundlak) y testear H0: coeficientes de w̄_i = 0,
*      obtenemos una versión robusta del test de Hausman. (usando vce(cluster id)).
*    - En este caso, el test de Mundlak tampoco rechaza la nula, lo que
*      refuerza la evidencia a favor de la ausencia de correlación entre
*      c_i y los regresores w_it.
*	 - coeficientes similares entre los CRE y RE
*    - pero con theta 0.8, los coeficientes CRE tambien se pareceran a los de FE.
*
* 4) Coeficientes en FE, RE y Mundlak:
*    - los coeficientes de grant y grant_1 sean muy parecidos en las tres especificaciones:
*      FE, RE y CRE-Mundlak.
*    - En otras palabras, los tres modelos cuentan la misma historia para
*      las variables clave, lo cual es coherente con la hipótesis de que
*      c_i no está correlacionado con los regresores.
*
* 5) Decisión de modelo:
*    - Dado que:
*        (i) Hausman no rechaza H0,
*       (ii) el test tipo Mundlak (clasico y robusto) tampoco rechaza,
*      (iii) theta es alto (0.80, transformación RE cercana a FE),
*           y los coeficientes FE, RE y Mundlak son muy similares,
*      una decisión razonable es trabajar con el modelo de efectos
*      aleatorios (RE).
*    - RE tiene, además, la ventaja práctica de permitir incluir regresores que no varían en el tiempo (variables puramente
*      entre individuos), algo que el modelo FE estándar no identifica.




****************************************************************************************

**# Comparacion RE vs FE vs CRE: Reflexiones finales

xtreg lscrap grant grant_1 d88 d89, re 
xtreg lscrap grant grant_1 d88 d89, fe
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar, re 

/* FE vs RE vs CRE (Mundlak): coeficientes y varianzas (o desvios estandar)

- En el modelo CRE-Mundlak usamos xtreg, re agregando las medias temporales w_bar.
  Eso implica:
    * Los coeficientes de las variables que varían en i y t (w_it) coinciden con los de FE si Mundlak está bien especificado.
    * Pero el estimador es un GLS tipo RE sobre (c_i + u_it), no un within como en FE. Pero... c_i se reparametriza!. ¿como son sus varianzas respecto a FE y RE? 

- Con varianza "clásica":
	* si comparamos los valores de la columan  Std. err. :
											-CRE vs FE, para las variables compartidas, CRE tiene exactamente mismos desvios estandar que FE. (bajo estructura de varianza clasica, resultan en la misma varianza).
											-CRE vs RE, para las variables compartidas, CRE tiene mayor varianza que RE. (resultado esperado, RE es el mas eficiente bajo RE3)
*/

xtreg lscrap grant grant_1 d88 d89, re vce(cluster fcode)
xtreg lscrap grant grant_1 d88 d89, fe vce(cluster fcode)
xtreg lscrap grant grant_1 d88 d89 grant_bar grant_1_bar, re vce(cluster fcode)

/*
	
-  Bajo una estructura tipo sandwich de la matriz var-cov?  
    * Los coeficientes de CRE siguen siendo los de GLS-RE, pero la matriz de var-cov pasa a ser tipo sandwich (robusta).
    	* si comparamos los valores de la columan  Std. err. :
											-CRE vs FE, para las variables compartidas, los errores estandar de CRE son casi identicos a los de FE. Ambos estan usando la misma estructura sandwich.
														lo unico que cambia, es que uno usa los residuos tipo GLS para un error compuesta con c_i parametrizado a la mundlak y otro usa los residuos de un within.
											-CRE vs RE, para las variables compartidas, CRE tiene mayor errores estandar que RE. Ambos usan la misma estructura sanwich, pero
														CRE usa GLS para un error compuesto con c_i parametrizado a la mundlak mientras que RE usa GLS para un error compuesto con c_i "normal".
*/

/* FE vs RE vs CRE (Mundlak): comparación de desvíos estándar

(1) Varianza clásica (por defecto en xtreg):

  - En el modelo CRE-Mundlak usamos xtreg, re agregando las medias w_bar.
    Los coeficientes de las variables que varían en i y t (w_it: grant, grant_1)
    coinciden con los de FE si Mundlak está bien especificado.

  - Comparando la columna Std. err.:

      * CRE vs FE:
          Para las variables compartidas, FE y CRE tienen EXACTAMENTE los
          mismos desvíos estándar. Esto refleja el resultado teórico:
          con Mundlak bien armado, FE y CRE usan la misma información para
          identificar δ (grant, grant_1).

      * CRE vs RE:
          Para esas mismas variables, RE tiene desviaciones estándar algo
          menores que CRE. Bajo RE.3, RE es el estimador más eficiente dentro
          de esta clase; CRE es RE aplicado a un modelo ampliado (incluye w_bar),
          y por eso pierde un poco de eficiencia relativa frente al RE "puro".

(2) Varianza robusta tipo sandwich (vce(cluster fcode)):

  - Los coeficientes de CRE siguen siendo los de un GLS-RE con Mundlak,
    pero la matriz de var-cov se calcula ahora con la fórmula robusta tipo
    sandwich.

  - Comparando de nuevo Std. err.:

      * CRE vs FE:
          Para las variables compartidas, los errores estándar son casi
          idénticos. Ambos usan la misma familia de varianzas robustas, pero
          a partir de residuos distintos (within vs GLS-Mundlak).

      * CRE vs RE:
          CRE tiene errores estándar mayores que RE. De nuevo, ambos usan
          la matriz sandwich, pero aplicada a dos especificaciones distintas
          del modelo (RE "puro" vs RE con c_i parametrizado a lo Mundlak).

Resumen:
  - Con varianza clásica: FE y CRE comparten SE para w_it; RE es algo más
    eficiente (SE menores).
  - Con varianza robusta (cluster): FE y CRE siguen siendo muy parecidos;
    RE mantiene SE algo menores, pero la comparación de eficiencia ya no es
    tan "limpia" como bajo RE.3 con varianza clásica.
*/




