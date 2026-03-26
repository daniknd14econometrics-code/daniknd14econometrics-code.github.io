**# Capitulo 7

clear all  
  
bcuse wagepan, clear
describe

* Declarar la estructura de panel y ordenar observaciones
xtset nr year
sort nr year


**# POOL-MCO

  *MCO agrupado (pooled OLS) con varianza clásica
regress  lwage educ exper expersq union married black 
 
  *MCO agrupado con matriz de varianza robusta "simple" (Huber-White)
regress  lwage educ exper expersq union married black, vce(robust)
  
  *MCO agrupado con matrizde varianza robusta tambien a correlacion serial (cluster en id)
regress  lwage educ exper expersq union married black, vce(cluster nr)
 
***** nota ****
** observar que con el supuesto POLS.1 es suficiente (Exogeneidad contemporanea, version debil)
 
 
 * Podemos agregar dummies temporales como controles adicionales:
regress  lwage educ exper expersq union married black i.year, vce(cluster nr)

 
**# Pruebas de correlacion serial

 
 ************************************ Prueba de correlacion serial AR(1) basada en ˆui,t−1 **************************************
  
 * Podemos usar los residuos de MCO agrupado con varianza homocedastica:
regress  lwage educ exper expersq union married black i.year
 * Guardar residuos de MCO agrupado: \hat{u_it}
predict uhat, resid
  
 * Generar el rezago de los residuos: \hat{u_i,t-1}
sort nr year
by nr: gen uhat_L1 = uhat[_n-1]
 
 * Estimar la ecuación de prueba (7.82) con varianza robusta por clúster en id, 
 * utilizando los residuos previos ya guardados:
  
regress lwage educ exper expersq union married black i.year uhat_L1 if !missing(uhat_L1), vce(cluster nr)

 /* Esta regresión no es un modelo estructural que nos interese para interpretar β; es solo una regresión auxiliar para testear si los residuos están autocorrelacionados. 
 El t de uhat_L1 ≠ 0 indica evidencia de AR(1) en los errores (bajo exogeneidad secuencial).*/
 * El test t sobre uhat_L1 = 0 es la prueba de H0: rho_1 = 0 (sin AR(1) en u_it)
 * Valido bajo POLS.1 asumiendo que u_it no esta correlacionado con u_it-1, que es una función de x_it-1 y de y_it-1; por ello le sienta mas natural la exogeneidad secuencial.
 
/* El test te dice: "Hay autocorrelación remanente en los errores".
Las causas posibles: dinámica mal especificada (falta de rezagos), heterogeneidad inobservable, mala forma funcional (falta de terminos cuadraticos), etc.
Una "solución" podria ser agregar rezagos; pero también podría ser cambiar la forma funcional, o pasar a modelos FE/RE. */ 
 
***********************************  Prueba de correlación serial AR(1) basada sólo en residuos (de MCO agrupado) *********************************

 * Regresión de residuos sobre su rezago: versión alternativa de la prueba AR(1)
 regress uhat uhat_L1 i.year if !missing(uhat_L1), vce(cluster nr)

 /* Si uhat_L1 sale significativo, hay evidencia de autocorrelación en los errores. 
  * El test t sobre uhat_L1 = 0 contrasta H0: rho_1 = 0
 * Valido bajo exogeneidad estricta. (No creible) 
 Como ya estamos usando vce(cluster nr) en nuestro modelo estimado, eso no "rompe" nuestros errores estándar, pero sí nos dice que la dinámica del modelo está incompleta.*/

  
**# Prueba de heterocedasticidad
 
*************************************  Prueba de heterocedasticidad tipo LM   ********************************
 
* utilizando los residuos previos ya guardados:

 * 1) Construir el cuadrado de los residuos: \hat{u_it^2}
 gen uhat2 = uhat^2
 * 2) Regresión auxiliar: uhat^2 sobre h_it (aqui representadas por los regresores, sus cuadrados..)
 gen educsq = educ^2
 gen educ_exper = exper*educ
 
 
regress uhat2 educ exper expersq union married black i.year educsq educ_exper
 
 * 3) Estadístico LM = N_obs * R^2 de la regresión auxiliar (R^2 sin corregir)
 scalar LM = e(N)*e(r2)
 * 4) Grados de libertad = número de variables explicativas en h_it (df_m)
 scalar df = e(df_m)
 * 5) p-valor de la prueba chi-cuadrado
 display "LM = " LM ", df = " df ", p-value = " chi2tail(df, LM)
 
 /*Bajo la hipótesis nula de homocedasticidad respecto de las variables en "h_it" (δ = 0), el estadístico LM tiene aproximadamente una distribución χ2
 Q, donde Q es la dimensión de "h_it" (número de regresores en la regresión auxiliar). 
 
 Se rechaza la hipotesis nula al 5% usual: encuentra heterocedasticidad. 
 Esta heterocedasticidad es respecto a las variables incluidas como "h_it" en la auxiliar, meter educ^2 y educ*exper hace el test más flexible.*/
 
 
 **# POOL-FGLS
 
 
 *******************************   Implementación de FGLS bajo estructuras específicas de Ω   *******************************************
 
 /* Como alternativa a usar una varianza robusta (vce(cluster nr)), podemos imponer una estructura paramétrica concreta sobre la matriz de varianzas y covarianzas de los errores:
   AR(1) + heterocedasticidad por panel y luego usar FGLS (xtgls). Esto puede ser más eficiente si el modelo de Ω es correcto, pero es menos robusto. 
   Por eso, como modelo "final" del taller, preferimos mantener MCO con vce(cluster nr).
*/
   * FGLS con correlación AR(1) dentro de cada unidad (misma estructura en el tiempo)
xtgls  lwage educ exper expersq union married black i.year, corr(ar1) panels(heteroskedastic)
    
 
**# Conclusion y reflexion final 

 ************************************************************************************************************************************************************************************************
 ***************************** POOL-MCO SIN presencia de heterogeneidad inobservable (seccion 7.8) ********************************************************************************************* 
 
** modelo "final" del taller:
 regress lwage educ exper expersq union married black i.year, vce(cluster nr)

  * Claro que podria tener sesgo por heterogeneidad inobservable, eso no se trata en este apartado. Pero es muy interesante ver que un panel agrupado puede tener su valor: 
 * a) permite varianzas robustas a correlacion serial por id
 * b) permite controlar por dummies temporales como controles adicionales
 * c) las pruebas de correlacion serial permiten explorar la completitud dinamica de la relacion entre y y x: esto apunta a la especificación del modelo. 
 * d) la prueba de heterocedasticidad permite evaluar si efectivamente hay heterocedasticidad. 

 
/* Lo mas recomendable es que usemos la matriz robusta a todo (heterocedasticidad+correlacion serial) para nuestro modelo final de MCO por datos agrupados. 
Es coherente bajo supuestos mucho más generales que los de homocedasticidad + no autocorrelación, y por eso la tomamos como nuestra especificación estándar.
Tener datos de panel permite cosas que el corte transversal no puede: nos da mas datos, nos permite unos controles adicionales por año, 
nos permite una estructura de varianza que permita correlacion serial dentro de cada individuo en el tiempo.
Lo que no nos da el MCO agrupado es el tratamiendo especial a un componente inobservado c_i, que no considerarlo podria sesgar los resultados. 
En ese caso, estimar por MCO agrupado se "come" un sesgo por variable omitida, que podria solucionarse si se contara con una buena proxy, o con instrumentos.
otra forma: disponer de un panel nos lleva a los modelos RE/FE que podrian solucionar esto, bajo ciertos supuestos quiza más exigentes. */

   
   
/* Todo eso, junto, hace que el "MCO agrupado" sea un modelo perfectamente respetable y muy útil.
¿Qué le falta, honestamente?
Básicamente una sola cosa:
No trata por separado un componente inobservable fijo c_i posiblemente correlacionado con x_it.
Si eso está correlacionado y es fuerte, el MCO agrupado se come el sesgo de variable omitida (la variable c_i).
Ahí entran los modelos Fixed E/Random E. Pero eso es otro problema conceptual (heterogeneidad inobservable), no una descalificación automática del pooled.

Dicho de forma frontal:
Pooled OLS con vce(cluster id) puede estar sesgado por omisión (como cualquier MCO mal especificado),
pero no es un modelo "tonto": en términos de inferencia y uso de la estructura temporal es muy potente.
*/ 