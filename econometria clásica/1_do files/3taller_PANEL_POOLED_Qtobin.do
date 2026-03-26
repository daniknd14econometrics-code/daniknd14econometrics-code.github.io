**# Capitulo 7

clear all 

bcuse q, clear
describe

 * Declarar la estructura de panel y ordenar observaciones
xtset cusip year
sort cusip year

**# POOL-MCO: rezago de x

  *MCO agrupado (pooled OLS) con varianza clásica
regress ikb qb_1
 
  *MCO agrupado con matriz de varianza robusta "simple" (Huber-White)
regress  ikb qb_1, vce(robust)
  
  *MCO agrupado con matrizde varianza robusta (cluster enid)
regress  ikb qb_1, vce(cluster cusip)
 
 ***** nota 1: analisis de POLS1 con rezago de regresor exogeno ****
/* observar que si usamos un regresor rezagado como sucede en este caso, el supuesto POLS.1 sigue siendo suficiente ya que las condiciones de momento teoricas 
 que se usaran ahora seran de los errores del periodo corriente, u_it, con un rezago del regresor, luego, podriamos justificar esto teoricamente:
 fundamentar con una historia que la información pasada no afecta al shock actual, ya que esta condicion de momento es la usadas bajo POLS1 en este modelo con un rezago de un regresor exogeno.
 Pero hay una forma mas natural dado este contexto: exigir la exogeneidad secuencial que el autor presenta en la seccion de completitud dinamica. 
 En resumen, bajo POLS1 sigue siendo consistente, con una historia que fundamente que el shock actual no se correlaciona con el regresor del periodo anterior.
 Si vamos un pelin mas lejos, exigimos mejor la exogeneidad secuencial que dice que el shock actual no se correlaciona con toda la historia pasada de los regresores (ni de la dependiente). 
 Esto ultimo equivale a decir que toda la informacion pasado no afecta al shock actual. */

**# POOL-MCO: con dinamica

  *¿que pasa si agregaramos un rezago de la variable dependiente? 
  *MCO agrupado con matrizde varianza robusta (cluster enid)
  
 regress  ikb ikb_1 qb_1, vce(cluster cusip)
 
 ***** nota 2: analisis de POLS1 en modelo dinamico ****
/* El supuesto POLS.1 sigue siendo suficiente ya que las condiciones de momento teoricas 
 que se usaran, ahora seran de los errores del periodo corriente, u_it, con rezago del regresor y ahora tambien con rezago de la variable dependiente, luego, podriamos justificar esto teoricamente:
 fundamentar con una historia que la información pasada no afecta al shock actual, ya que estas dos condiciones de momentos son las usadas bajo POLS1 en este modelo dinamico.
 Pero hay una forma mas natural dado este contexto: exigir la exogeneidad secuencial que el autor presenta en la seccion de completitud dinamica. 
 En resumen, bajo POLS1 sigue siendo consistente, con una historia que fundamente que el shock actual no se correlaciona con el regresor del periodo anterior ni con la dependiente en el periodo anterior.
 Si vamos un pelin mas lejos, exigimos mejor la exogeneidad secuencial que dice que el shock actual no se correlaciona con toda la historia pasada de los regresores ni de la dependiente. 
 Esto ultimo equivale a decir que toda la informacion pasado no afecta al shock actual. */
 
 
*** nota 3: ¿que pasa con la heterogeneidad inobservable? ****
/* Observar que todo esto es para el caso donde no se explicita presencia de c_i (heterogeneidad inobservable), tal como se presenta en el capitulo 7, seccion 8.
   De manera implicita, en el contexto del capitulo 7 se asume a c_i incorrelacionado con los regresores. 
   ¿que pasa en los dos anteriores modelos si asumimos la presencia de c_i? */
 
 regress  ikb qb_1, vce(cluster cusip)

 /* modelo con rezago de regresor exogeno:
  ahora, ademas de cumplirse POLS1, que vimos que podriamos encontrar una historia para defensa, y que mecanimente siempre se puede estimar, la pregunta ahora 
  es si la presencia de c_i, que va al error porque no es observable, nos exige algo mas? y la respuesta es que si, nos exige una condicion extra.
  La condicion extra es que c_i no debe correlacionarse con los regresores del modelo. 
  
 En este caso, que el rezago de un regresor exogeno, qb_it-1, esté incorrelacionado con c_i. Si encontramos una historia creible para ello en el contexto de nuestro proceso generador de datos,
 entonces podemos interpretar a las estimaciones POOL-MCO como consistentes. Si no hay historia creible, o mejor dicho, si el contexto es tal que se impone mas bien todo lo contrario: 
 que c_i probablemente se correlacione con al menos un regresor, entonces estimar por POOL-MCO nos dara estimaciones sesgadas e inconsistentes. 
 
 Este analisis le cabe a modelos estaticos en panel, y a modelos con rezagos de regresores exogenos. ¿que pasa si se especifica un modelo dinamico? */
 
  regress  ikb ikb_1 qb_1, vce(cluster cusip)

/* modelo dinamico:
   como vismo, la condicion extra es que c_i no debe correlacionarse con los regresores del modelo.
   En este caso, donde incluimos un rezago de la variable dependiente, ikb_it-1, lo cierto es que NO se cumple que c_i este incorrelacionado con los regresores, ya que no estara incorrelacionado con ikb_it-1.
   Por lo tanto, no es que haya que encontrar una historia creible, es que simplemente mecanicamente la estructura del modelo te muestra que se viola la condicion extra de que c_i sea incorrelaciondo con los regresores.
   Por lo tanto, en un modelo dinamico, no podes estimarlo por POOL-MCO: sus coeficientes estarán sesgados necesariamente!
   Veremos que este tipo de modelo, tampoco se podrá estimar por otras tecnicas como efectos aleatorios: viola tanto que c_i este incorrelaciondo con los regresores,
   como tambien viola otro supuesto necesario para efectos aleatorios, que es la exogeneidad estrica. 
   Este modelo tampoco se podra estimar con tecnicas como efectos fijos ya que viola la exogeneidad estrica. 
   Este modelo solo se puede estimar con otro conjunto de tecnicas como los metodos de Arellano-Bond, capitulo 11.
 */   
   
   
**# Conclusion sobre rezagos

 * Con esto claro, continuamos con nuestro taller. 
 * No podemos estimar un modelo dinamico (con variable dependiente rezagada) por POOL-MCO (ni por FE/RE) e interpretar sus coeficientes como consistentes.
 * Pero si los rezagos son solo de regresores exogenos, entonces si podemos, aun, tener una historia para defender que los valores estimados sean consistentes.
 * Por lo tanto nuestro modelo de este taller es:

regress ikb qb_1, vce(cluster cusip)

* al cual podemos agregar dummies temporales como controles adicionales:

regress ikb qb_1 i.year, vce(cluster cusip)

**# Prueba para las binarias temporales
 
** evaluamos anios y decidimos si dejarlos o no:
regress ikb qb_1 d77 d78 d79 d80 d81 d82 d83 d84 d85, vce(cluster cusip)
test d77 d78 d79 d80 d81 d82 d83 d84 d85
** mantenemos dummies temporales.

  ****************************** modelo final del taller *****************************
regress ikb qb_1 i.year, vce(cluster cusip)


 ** Se podria probar agregando  qb_1sq como regresor. Lo hice: aporta muy poquito, y complica mas interpretacion, asi que por parsimonia no vale la pena.

 
 
 
**# Pruebas de correlacion serial

 ********************************** Prueba de correlacion serial AR(1) basada en ˆui,t−1 ********************************
  
 * Podemos usar los residuos de MCO agrupado con varianza homocedastica:
 regress ikb qb_1 i.year
 * Guardar residuos de MCO agrupado: \hat{u_it}
 predict uhat, resid
  
 * Generar el rezago de los residuos: \hat{u_i,t-1}
 sort cusip year
 by cusip: gen uhat_L1 = uhat[_n-1]
 
  * Estimar la ecuación de prueba (7.82) con varianza robusta por clúster en id, 
  * utilizando los residuos previos ya guardados:
  
 regress ikb qb_1 uhat_L1 i.year if !missing(uhat_L1), vce(cluster cusip)
  /* Esta regresión no es un modelo estructural que nos interese para interpretar β; es solo una regresión auxiliar para testear si los residuos están autocorrelacionados. 
 El t de uhat_L1 ≠ 0 indica evidencia de AR(1) en los errores (bajo exogeneidad secuencial).*/
 * El test t sobre uhat_L1 = 0 es la prueba de H0: rho_1 = 0 (sin AR(1) en u_it)
 * Valido bajo POLS.1 o, mas naturalmente, bajo exogeneidad secuencial.

 /* El test te dice: "Hay autocorrelación remanente en los errores".
Las causas posibles: dinámica mal especificada (falta de rezagos), heterogeneidad inobservable, mala forma funcional (falta de terminos cuadraticos), etc.
Una "solución" podria ser agregar rezagos (de los regresores); pero también podría ser cambiar la forma funcional, o pasar a modelos FE/RE. */ 
 
 
***********************  Prueba de correlación serial AR(1) basada sólo en residuos (de MCO agrupado) *************************************************

 * Regresión de residuos sobre su rezago: versión alternativa de la prueba AR(1)
 regress uhat uhat_L1 i.year if !missing(uhat_L1), vce(cluster cusip)
 * El test t sobre uhat_L1 = 0 contrasta H0: rho_1 = 0
 * Valido bajo exogeneidad estricta. (No creible) 
 
**# Prueba de heterocedasticidad
 
**************************************  Prueba de heterocedasticidad tipo LM *************************************************************************
 
   * utilizando los residuos previos ya guardados:

 * 1) Construir el cuadrado de los residuos: \hat{u_it^2}
 gen uhat2 = uhat^2
 * 2) Regresión auxiliar: uhat^2 sobre h_it (aqui representadas por los regresores, sus cuadrados..)
 gen qb_1sq = qb_1^2
 regress uhat2 qb_1 qb_1sq  i.year
 * 3) Estadístico LM = N_obs * R^2 de la regresión auxiliar (R^2 sin corregir)
 scalar LM = e(N)*e(r2)
 * 4) Grados de libertad = número de variables explicativas en h_it (df_m)
 scalar df = e(df_m)
 * 5) p-valor de la prueba chi-cuadrado
 display "LM = " LM ", df = " df ", p-value = " chi2tail(df, LM)
 
 /*Bajo la hipótesis nula de homocedasticidad respecto de las variables en "h_it" (δ = 0), el estadístico LM tiene aproximadamente una distribución χ2
 Q, donde Q es la dimensión de "h_it" (número de regresores en la regresión auxiliar). 
 
 Se rechaza la hipotesis nula al 1%: encuentra heterocedasticidad. 
 Esta heterocedasticidad es respecto a las variables incluidas como "h_it" en la auxiliar, meter qb_1^2 hace el test más flexible.*/
 
 
**# POOL-FGLS

 
 ******************************************** Implementación de FGLS bajo estructuras específicas de Ω  **********************************************************************
  
  /* Como alternativa a usar una varianza robusta (vce(cluster cusip)), podemos imponer una estructura paramétrica concreta sobre la matriz de varianzas y covarianzas de los errores:
   AR(1) + heterocedasticidad por panel y luego usar FGLS (xtgls). Esto puede ser más eficiente si el modelo de Ω es correcto, pero es menos robusto. 
   Por eso, como modelo "final" del taller, preferimos mantener MCO con vce(cluster nr)."
*/

 
  * FGLS con correlación AR(1) dentro de cada unidad (misma estructura en el tiempo)
 xtgls  ikb qb_1 i.year, corr(ar1) panels(heteroskedastic)

 
 
 *******************************************************************************************************************************************************************************

**# Modelo final para Q tobin 
 
**** ¿Cual es el modelo final para esta aplicacion? No solo ver significativos y R2, también evaluar teoria economica. ****
 
 
gen qb_sq = qb*qb
gen qb_1sq = qb_1*qb_1

** hasta ahora trabajamos con un rezago de un regresor. 
regress ikb qb_1 i.year, vce(cluster cusip) 
** Si uno solo mira este modelo, parece que el lag de qb tiene un efecto claro y positivo.
 
regress ikb qb qb_1 i.year, vce(cluster cusip)
** Cuando dejas a qbt competir "cara a cara" con qbt−1, el contemporáneo se lleva toda la gloria y el lag se vuelve pequeño e impreciso.
** el efecto que veía en el lag en el primer modelo probablemente estaba capturando en parte el efecto de qbt (que se omitía). 
** Eso huele a omisión de variable relevante si el modelo "verdadero" incluye qbt.
  
	​
** estimemos relaciones cuadraticas para cada uno:
regress ikb qb qb_sq  qb_1 qb_1sq i.year, vce(cluster cusip) 
 
**No linealidad en el qbt: el patrón positivo en qbt y negativo en qbt_sq te da una relación cóncava (tipo U invertida) en qt. 
**No linealidad en el rezago qb_1: El lag y su cuadrado muestran efectos mucho más débiles e inestables.
 
** la cosa apunta a no linealidad y en el contemporaneo:
regress ikb qb qb_sq  i.year, vce(cluster cusip) 
** ademas, se ganan observaciones al no requerir el lag.

**# Comparativa usando !missing

** para comparartiva con caso anterior podria volver a correr para las mismas observaciones agregando   if !missing(qb_1)
regress ikb qb qb_sq i.year if !missing(qb_1), vce(cluster cusip)
 
** por ultimo, comparemos solo contemporaneo version efecto lineal: 
regress ikb qb  i.year, vce(cluster cusip) 
regress ikb qb  i.year if !missing(qb_1), vce(cluster cusip) 


 ** El modelo con efecto cuadratico tiene mejor ajuste global (F) y tambien mejor R2 que el efecto lineal (modelo lineal). Independientemente de si restringo a if !missing(qb_1) o no. 
 ** Ambos coeficientes son significativos, justamente, parece que seria un efecto cuadratico.
 ** ¿tiene sentido economico asumir efectos cuadraticos?
 
 
 regress ikb qb qb_sq  i.year, vce(cluster cusip) 

/* con los coeficientes del modelo con qb y qb_sq, el máximo de la curva es:
 qb* = - B_1/2B_2 =  0.028/(2x0.00254) =  5.5 
 Es decir, para qb alrededor de 5–6, el efecto marginal de mayores qb se apaga.
 Si en mis datos la mayor parte de los qb están por debajo de eso, estás en la parte creciente de la curva → interpretación económica relativamente limpia:
 más qb aumenta la inversión, pero a tasas decrecientes. */
 
 summ qb, det
 
 /*
1) Forma de la relación ikb–qb: cuadratica
   Modelo: ikb = 0.0936 + 0.0280*qb - 0.00254*qb_sq + dummies de año + error.
   Signos: coef(qb) > 0 y coef(qb_sq) < 0, ambos muy significativos.
   Interpretación: relación cóncava (tipo U invertida) entre ikb y qb. 

2) Punto de máximo teórico
   Derivada de funcion cuadratica: d(ikb)/d(qb) = 0.0280 + 2*(-0.00254)*qb = 0.0280 - 0.005078*qb.
   Máximo de funcion cuadratica: qb* = -0.0280 / (2 * -0.00254) ≈ 5.5.
   Eso significa que la relación crece hasta qb ≈ 5.5 y desde ahí empezaría a caer. (U invertida)

3) Dónde cae (en temrinos de lugar) ese máximo de 5.5 en la distribución de qb
   Resumen de qb:
     - P25 ≈ -0.63
     - Mediana ≈ -0.22
     - P75 ≈ 0.56
     - P90 ≈ 1.92
     - P95 ≈ 3.35
     - P99 ≈ 6.36
   El máximo qb* ≈ 5.5 está por encima de casi todas las observaciones (cerca de P99).
   En la práctica: para casi toda la muestra, ikb crece con qb, pero con rendimientos decrecientes.

4) Efectos marginales en puntos concretos
   Efecto marginal: ME(qb) = 0.0280 - 0.005078*qb.
   Ejemplos aproximados:
     - P25 (qb ≈ -0.63): ME ≈ 0.031
     - Mediana (qb ≈ -0.22): ME ≈ 0.029
     - P75 (qb ≈ 0.56): ME ≈ 0.025
     - P95 (qb ≈ 3.35): ME ≈ 0.011
     - P99 (qb ≈ 6.36): ME ≈ -0.004
   Casi todas las observaciones tienen ME > 0; sólo en la cola extrema puede volverse levemente negativa.

5) Magnitud del efecto (no sólo significancia)
   Cambio de qb del P25 al P75 (aprox. -0.63 a 0.56) implica:
     - Diferencia en ikb predicho ≈ 0.0335 puntos.
   Con Root MSE ≈ 0.074, esto es casi media desviación estándar de ikb.
   Conclusión: el efecto de qb sobre ikb es grande en términos económicos y no sólo "estadísticamente significativo".
*/

**# Modelo final
 
******************** MODELO FINAL ***********************
regress ikb qb qb_sq  i.year, vce(cluster cusip) 
********************************************************
  
** Termino siendo un modelo estático (no hay lag de regresor exogeno). Pero en lugar de lineal, se ajusta mejor un modelo cuadrático en el regresor qb. 
** Esto es consistente con la teoria de la Q de tobin.
