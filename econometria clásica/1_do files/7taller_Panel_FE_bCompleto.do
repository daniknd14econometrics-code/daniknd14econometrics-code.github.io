**# Capitulo 10

clear all  

** instalar solo la primera vez:
*net from http://www.stata.com/data/jwooldridge/
*net describe eacsap
*net get eacsap
  
cd
dir

use jtrain1, clear
describe

**# FE: directo con xtreg

*--------------------------------------------------------------*
* Consistencia del estimador de efectos fijos con jtrain1.dta
* Modelo teórico: lscrap_it = x_it' β + c_i + u_it
* Aquí usamos como regresores: d88, d89, grant, grant_1, union
* - FE permite corr(c_i, x_it)
* - Solo identifica efectos de variables que varían en el tiempo
*--------------------------------------------------------------*

* 0. Cargar datos y declarar panel
use jtrain1, clear
xtset fcode year  

* 1. Estimador FE  (within)
*    Implementa la ecuación transformada:      (lscrap_it - l̄scrap_i) = (...)' β + (u_it - ū_i)
*    Bajo FE.1 y FE.2, β̂_FE es insesgado condicional en X y consistente.
xtreg lscrap d88 d89 grant grant_1 union, fe

* - Observa que Stata va a omitir union si no varía en el tiempo  dentro de la firma: esto ilustra que FE solo usa variación  "dentro de i" (within) para identificar β.
* - El R2 que importa para FE es el de "within".
* - El F de la salida FE tiene:
*     df1 = K = e(df_m)  (número de regresores excluida la constante)
*     df2 = N(T-1) - K = e(df_r)
*   En este ejemplo: df1 = 4, df2 = 104.


**# FE: "manual" con transformación within y luego POLS

* 2. Construir la transformación dentro de la firma (within) "a mano"
*    y replicar el estimador FE con MCO sobre variables centradas.

* Medias temporales por firma (sobre todo el panel de la firma)
bysort fcode: egen lscrap_bar  = mean(lscrap)
bysort fcode: egen d88_bar     = mean(d88)
bysort fcode: egen d89_bar     = mean(d89)
bysort fcode: egen grant_bar   = mean(grant)
bysort fcode: egen grant1_bar  = mean(grant_1)
bysort fcode: egen union_bar   = mean(union)

* Variables con media temporal removida:  ŷ_it = y_it - ȳ_i, X̃_it = X_it - X̄_i
gen lscrap_tilde  = lscrap  - lscrap_bar
gen d88_tilde     = d88     - d88_bar
gen d89_tilde     = d89     - d89_bar
gen grant_tilde   = grant   - grant_bar
gen grant1_tilde  = grant_1 - grant1_bar
gen union_tilde   = union   - union_bar // se cancela porque es union es constante en el tiempo.
* la constante de año base menos su media, tambien se cancela

* MCO sobre la ecuación within (sin constante):   l̃scrap_it = d̃88_it β_1 + d̃89_it β_2 + g̃rant_it β_3 + g̃rant1_it β_4 + ũ_it
* Esto corresponde a las ecuaciones (10.46), (10.49) y (10.50) en la teoría.
regress lscrap_tilde d88_tilde d89_tilde grant_tilde grant1_tilde union_tilde, nocons

* Los coeficientes de esta regresión deben coincidir (salvo redondeo)
* con los de xtreg lscrap ... , fe: es el mismo estimador within.

**# Estimador between

* 3. Estimador "between" para contrastar (usa solo variación entre firmas)
*    Aplica MCO a la ecuación de promedios:
*      l̄scrap_i = x̄_i' β + c_i + ū_i
*    Bajo FE.1, c_i puede estar correlacionado con x̄_i => between inconsistente.
*    between solo usa las N observaciones: 54.

preserve
collapse (mean) lscrap d88 d89 grant grant_1 union, by(fcode)
regress lscrap d88 d89 grant grant_1 union
restore

* Comparar:
* - β̂_FE (within) es consistente bajo FE.1 y FE.2.
* - β̂_between es en general inconsistente si corr(c_i, x_i) ≠ 0,  porque c_i queda en el error y está correlacionado con los regresores.
* - si asumieramos que c_i esta incorrelacionado con x_i, entonces el estimador between es consistente, pero menos eficiente que el de RE (random effects)-



******************************************************************************************************

**# Parámetros de varianza: v = c + u

*--------------------------------------------------------------*
* Inferencia clásica con efectos fijos en jtrain1.dta
* Basado SOLO en la subsección de inferencia FE (FE.3, σ_u^2, σ_v^2, σ_c^2, F-test)
* Modelo: lscrap_it = β1 d88_it + β2 d89_it + β3 grant_it + β4 grant_1_it + c_i + u_it
*--------------------------------------------------------------*

* 1. Estimar el modelo FE con errores estándar "clásicos"
*    (esto corresponde exactamente al setting FE.1–FE.3: homocedasticidad
*     y sin correlación serial en u_it; nada de robust ni cluster acá)
xtreg lscrap d88 d89 grant grant_1, fe

* Stata está usando:
*   Var(β̂_FE | X) = σ_u^2 * (Σ_i X̃_i' X̃_i)^(-1)   donde σ_u^2 se estima como SSR / [N(T-1) - K]
*   y los gl residuales e(df_r) ya son N(T-1) - K en este contexto FE.

* 2. Recuperar σ̂_u^2 usando exactamente la fórmula de Wooldridge (10.56)
*    σ̂_u^2 = SSR / [N(T-1)- K]
*    SSR = e(rss),
*    df_r = e(df_r) 

/* xtreg, fe stores	the	following in e():

Scalars	 
e(N)		number of observations
e(N_g)		number of groups
e(mss)		model sum of squares
e(df_m)		model degrees of freedom
e(rss)		residual sum of squares  <----
e(df_r)		residual degrees of freedom  <----
e(tss)		total sum of squares
e(corr)		corr(u_i, Xb)
e(sigma)		square root of the sum of e(sigma_e)-squared and e(sigma_u)-squared
e(sigma_u)		panel-level standard deviation
e(sigma_e)		standard deviation of epsilon_it   <----
e(r2)		R-squared
e(r2_a)		adjusted R-squared
e(r2_w)		R-squared within model
e(r2_o)		R-squared overall model
e(r2_b)		R-squared between model
e(N_clust)		number of clusters
e(rho)		rho
e(F)		F statistic
e(F_f)		F statistic for test of u_i=0
e(p)		p-value for model test
e(p_f)		p-value for test of u_i=0
e(df_a)		degrees of freedom for absorbed panel effect
e(df_b)		numerator degrees of freedom for F statistic
e(rmse)		root mean squared error  <----
e(Tbar)		mean of group sizes
e(rank)		rank of e(V)
*/

xtreg lscrap d88 d89 grant grant_1, fe
scalar varianza_u_manual = e(rss) / e(df_r)
display "varianza_u (manual, FE clásica) = " varianza_u_manual
** ojo, si uno calculara la varianza σ_u^2 "manual" (componente idiosincrático u_it) pero partiendo desde la transformación within "a mano" (sin usar la opcion ,fe)
** entonces se deberia corregir esto ultimo por un factor de correcion (NT-K/N(T-1)-K)^(1/2). En este caso, como partimos de usar la opcion ,fe --->  no es necesario corregir. 

* Comparar con lo que usa Stata internamente:
display "varianza_u (Stata)            = " e(rmse)^2
* Alternativamente, tambien Stata usa:
display(e(sigma_e)* e(sigma_e))

** Coinciden. 
/* Notar que en el modelo de EFECTOS FIJOS (FE) la matriz de varianzas y covarianzas está gobernada 
  por el parametro de la varianza asociado al error idiosincratico, que acabamos de calcular, igual a 0.2477493, y también 
  esta gobernada por los valores de los regresores transformados. 
  Cuando vemos la estructura, si comparamos con el modelo de EFECTOS ALEATORIOS (RE), vemos algunas diferencias: 
	1) en FE, los terminos de la varianza son un poco mas chicos: T-1/T por la varianza del error idiosincratico. Mientras que RE no existe tal factor (o vale 1).
	2) en FE, los terminos de covarianza dentro de un mismo i son negativos a diferencia de RE.
	3) en FE, los terminos de covarianza dependen de la varianza del error idionsincratico, mientras que en RE dependen de la varianza de la heterogeneidad inobservable. 
	
En suma, en FE solamente interviene el parametro de la varianza idionsincratica en la matriz de var-cov. 

Pero se advierte que, una varianza relativa grande de la heterogeneidad inobservable (medida con ICC) influye de forma indirecta: 
a mayor valor de esta ultima, que recoge variacion "entre", hace que tenga mas variacion "entre" y menos "dentro". La falta de variacion "dentro" es la que hace se inflen las varianzas,
porque los regresores transformados tendran poca variacion dentro de las unidades. Esto hace que podriamos ver que las varianzas (desvios estandar) de los coeficientes estimados sean mas grandes,
con ello los t se reducen y los p-valor se agrandan: riesgo de no significacion para las variables. ---> calcular ICC (rho).
*/
	

* 3. Estimar la varianza TOTAL del error compuesto v_it = c_i + u_it:  
* σ_v^2 = Var(v_it) ≈ SSR_v / (NT - K) . 
* donde SSR_v es la suma de cuadrados de los residuos en NIVELES, usando los coeficientes de la estimacion de efectos fijos: .
 * v̂_it = y_it - x_it' β̂_FE

xtreg lscrap d88 d89 grant grant_1, fe

* Componente sistemático en niveles, usando X en niveles y betas FE
gen double xb_level = _b[_cons] + _b[d88]*d88 + _b[d89]*d89 + ///
                      _b[grant]*grant + _b[grant_1]*grant_1 if e(sample)

* Residuos en niveles con coeficientes FE: vhat_it = y_it - x_it' β_FE
gen double vhat = lscrap - xb_level if e(sample)

* crear vhat^2 y sumar
gen double vhat2 = vhat^2 if e(sample)
quietly summarize vhat2 if e(sample), meanonly
scalar SSR_v = r(sum)

* Número de regresores K 
scalar K = e(df_m)  + 1  // slopes + constante
scalar NT = e(N)  // ya cuenta NT

* Estimador "plug-in" de varianza_v = SSR_v / (NT - K)
scalar varianza_v_manual = SSR_v / (NT - K)

display "varianza_v_manual (plug in) = " varianza_v_manual

* Comparar con lo que usa Stata internamente:
display "varianza_v (Stata)            = " e(sigma)^2



**# Discusion: plug-in vs Stata internamente


/* discusion: por que pueden diferir si se supone deberian coincidir?
------------------------------------------------------------------------------
   Nota sobre σ_v^2 (error compuesto) y lo que hace Stata

   - En el código anterior definimos:

       vhat_it   = y_it - x_it' * b_FE
       sigma2_v_hat = SSR_v / (NT - K)

     Es decir, estamos usando un estimador "plug-in" al estilo Wooldridge:
     tomamos los coeficientes FE (b_FE), construimos v̂_it en NIVELES y
     estimamos la varianza total del error compuesto v_it = c_i + u_it
     como el promedio de v̂_it^2 con divisor (NT - K).

   - Stata, en cambio, cuando reporta:

       e(sigma_u)^2  (varianza del efecto individual c_i)
       e(sigma_e)^2  (varianza del error idiosincrático u_it)

     está usando un procedimiento más sofisticado de componentes de varianza
     (ANOVA / error-components), que combina información "within" y "between"
     para separar estos dos componentes de varianzas. Si luego calculamos:

       sigma2_v_stata = e(sigma_u)^2 + e(sigma_e)^2 (o, alternativamente sigma2_v_stata = e(sigma)^2 )

     obtenemos OTRO estimador de σ_v^2. Es consistente bajo los supuestos
     de panel, pero NO es el mismo plug-in simple que sugiere Wooldridge.

   - Por eso, en muestras chicas y con T corto (como aquí, T = 3), es normal que:

       sigma2_v_hat      !=      sigma2_v_stata

     No es que uno esté "mal" y el otro "bien": son dos estimadores diferentes
     del mismo parámetro poblacional σ_v^2 = σ_c^2 + σ_u^2.

   - En términos asintóticos, si N y T crecen (especialmente T), ambos
     procedimientos tienden a converger al mismo límite poblacional.
     En ese sentido, la discrepancia que vemos ahora es un fenómeno
     de muestra finita, agravado por tener T muy pequeño.

   - En este do-file seguimos deliberadamente el enfoque plug-in de Wooldridge
     para mantener la conexión directa con la teoría explicada en el texto.
     Replicar "a mano" exactamente lo que hace Stata con σ_u y σ_e es posible,
     pero implicaría implementar el esquema de componentes de varianza y ya
     no sería el mismo procedimiento plug-in sencillo que estamos ilustrando.
------------------------------------------------------------------------------


En conclusion: mejor nos quedamos con los que Stata reporta internamente, en su salida.    */


* 4. Estimar "manualmente" la varianza del efecto no observado c_i:
*    σ_c^2 = σ_v^2 - σ_u^2
scalar varianza_c_manual = varianza_v_manual - varianza_u_manual
display "varianza_c_manual (plug-in) = " varianza_c_manual

* Comparar con lo que usa Stata internamente:
display "varianza_c (Stata)            = " e(sigma_u)^2
* alternativamente
display e(sigma)^2 - e(sigma_e)^2

/* Dado que la varianza del error compuesto nos dio diferente, la consecuencia es que tambien nos dara diferente la varianza de la heterogeneidad inobservable,
   ya que esta se obtiene como diferencia. En suma, si bien la varianza del componente idiosincratico nos coincide siempre, 
   nosotros estimamos de forma "manual" a la varianza del error compuesto con el metodo "plug in" de wooldridge, pero Stata hace algo mas complejo,
   y con N chico y sobre todo T chico, se tendran diferencias. 
   Esto de calcular los componentes es un ejercicio teorico, que sirve para saber que refleja cada cosa, de donde salen. 
   Tambien para comparar con RE. */
   
   
**# replicar ICC (rho)

* 5. Índice de correlación intraclase (ICC):
*    ρ = σ_c^2 / (σ_c^2 + σ_u^2)

/* El principal motivo que se tiene para obtener medidas de las varianzas es poder calcular el ICC, que lo vemos como "rho" en la salida. 
   Si vale 1, nos diria que toda la varianza (del error compuesto) es explicada enteramente por la varianza de la heterogeneidad inobservable 
   que es la parte de la variacion "entre". 
   Si eso sucede, quiere decir que no hay variacion "dentro". En este caso, si bien la varianza del componente de heterogeneidad no entra directamente en la matriz de varianzas y covarianzas como parametro, 
   Si le pega indirectamente a los regresores transformados de la matriz de varianzas y covarianzas: la falta de variacion "dentro" es la que inflará las varianzas de cada uno de los estimadores.
   La consecuencia es que en ese caso, todos los estimadores tendran desvios estandar relativamente elevados, t chicos, p-valor grandes. Por lo tanto, en esos casos usar un modelo de FE no es recomendado!.
   Esto es clave. Debemos mirar este valor y analizar los t y los p-valor. 
   Esta bien luego usar un test de Hausman para evaluar RE vs FE, pero no hay que quedarnos solo con ese test. Se deben evaluar otras cosas como esta.
   Si yo tengo un ICC cercano a 1, tendriamos que desistir de un modelo de FE. En ese caso, ir por un RE por un MCO agrupado. */
   
scalar rho_icc_plugin = varianza_c_manual / (varianza_c_manual + varianza_v_manual)
display "ICC_manual (rho plug-in) = " rho_icc_plugin

** Este valor, esta a medio camino, pero sabemos que es mas eficiente usar el que calcula Stata internamente:
scalar rho_stata1 = (e(sigma_u)^2)/[(e(sigma_e)^2)+(e(sigma_u)^2)]
display rho_stata1
scalar rho_stata2 = e(rho)
display rho_stata2

** vemos que el valor "correcto" que usa Stata nos da un valor muy elevado: casi 0.90!! esto nos esta diciendo: ojo con usar un modelo FE. 

xtreg lscrap d88 d89 grant grant_1, fe

** podemos ver que muchos coeficientes son no significativos, como grant en el periodo contemporaneo. Otros al borde del 5%. 


**# Prueba sobre coeficientes

* 6. Test F clásico para una hipótesis lineal en FE:
*    Ejemplo del texto: H0: grant = 0 y grant_1 = 0 (q = 2)
*    Bajo FE.1–FE.3, el estadístico
*      F = [ (SSR_R - SSR_U)/q ] / [ SSR_U / (N(T-1) - K) ]
*    tiene distribución F_{q, N(T-1)-K} aproximadamente.

* (ya tenemos el modelo irrestricto estimado arriba)
test grant grant_1

* Stata reporta:
* - El F(q, e(df_r)), donde e(df_r) = N(T-1) - K,
*   tal como en la fórmula (10.57) del texto.

*--------------------------------------------------------------*


**# FE = POLS con dummies individuales


*---------------------------------------------------------------------*
* 10.5.3 Regresión con dummies y equivalencia con FE (LSDV vs FE)
* Supuestos: ya cargaste jtrain1 y tenés:
*   xtset fcode year
*   xtreg lscrap d88 d89 grant grant_1, fe
*---------------------------------------------------------------------*

** Comparacion modelo FE vs modelo con dummies


* 1. Guardar la estimación FE "oficial" (xtreg, fe)
xtreg lscrap d88 d89 grant grant_1, fe
estimates store FE

* 2. Regresión con dummies de unidad (LSDV)
regress lscrap d88 d89 grant grant_1 i.fcode
estimates store LSDV

* Los coeficientes deben coincidir.
* La diferencia es que acá los c_i están parametricamente representados como las dummies i.fcode.

* 2.1. Comparar coeficientes FE vs LSDV (solo slopes)
 esttab FE LSDV, keep(grant grant_1 d88 d89) se label

* 2.2. Verificar que la SSR y la varianza idiosincrática coinciden
scalar varianza_u_LSDV = e(rss) / e(df_r)
display "varianza_u^2 (LSDV, por MSE) = " varianza_u_LSDV

* Volver a FE y comparar:
estimates restore FE
display "varianza_u (FE) = " e(sigma_e)^2

* Comentario:
* - En la LSDV, e(df_r) = NT - (K + N) = N(T-1) - K, así que
*   e(rss)/e(df_r) implementa automáticamente el denominador correcto  de Wooldridge para sigma_u^2.
* - Como los residuos de LSDV y FE coinciden, varianza_u también coincide.


**# FE: estimar los c_i explicitos

*---------------------------------------------------------------------*
* 2. Estimar los efectos fijos c_i "explícitos" a partir de FE
*---------------------------------------------------------------------*

* 1. Estimar FE
xtreg lscrap d88 d89 grant grant_1, fe
* Guarda la muestra FE
gen byte sample_fe = e(sample)

drop lscrap_bar d88_bar d89_bar grant_bar grant1_bar

* 2. Promedios temporales SOLO en la muestra FE
bysort fcode: egen lscrap_bar = mean(lscrap) if sample_fe
bysort fcode: egen d88_bar    = mean(d88)    if sample_fe
bysort fcode: egen d89_bar    = mean(d89)    if sample_fe
bysort fcode: egen grant_bar  = mean(grant)  if sample_fe
bysort fcode: egen grant1_bar = mean(grant_1) if sample_fe

* 2.1. Construir [x̄_i'*beta_FE] 
gen double xbar_beta_FE = ///
    _b[d88]*d88_bar      + ///
    _b[d89]*d89_bar      + ///
    _b[grant]*grant_bar  + ///
    _b[grant_1]*grant1_bar if sample_fe


* 2.3. Efectos fijos estimados:   c_i = ȳ_i - x̄_i' beta_FE
gen double c_i = lscrap_bar - xbar_beta_FE if sample_fe

* Tenemos ahora un c_i por firma (54 valores en jtrain1.dta).
* Estos c_I son exactamente los interceptos de la regresión con dummies (LSDV), sólo que obtenidos vía la fórmula teórica:
*    c_i = ȳ_i - x̄_i' beta_FE.
	
summ c_i
browse fcode year c_i
summ c_i if year == 1987

* observar que para cada i (fcode) tenemos el mismo c_i repitiendose para todos los años que está presente ese i.
* Esto es porque se usaron promedios temporales.


**# Replicar corr(c_i, Xb)

*---------------------------------------------------------------------*
* 3. Replicar (aproximar) corr(u_i, Xb) que reporta xtreg, fe
*---------------------------------------------------------------------*


* 3. Xb a nivel observación (predicción en niveles)
gen double xb_fe = _b[_cons]              + ///
                   _b[d88]*d88           + ///
                   _b[d89]*d89           + ///
                   _b[grant]*grant       + ///
                   _b[grant_1]*grant_1   if sample_fe

 br xb_fe fcode year

* 4. Correlación "a la Stata": c_i (repetido) vs Xb en cada t
corr c_i xb_fe if sample_fe
scalar corr_manual = r(rho) 

display "corr(u_i, Xb) en xtreg, fe = " e(corr)
display "corr(u_i, Xb) manual = " corr_manual


	 
/*
  Nota sobre corr(u_i, Xb) de xtreg, fe

  - Stata reporta "corr(u_i, Xb)" como la correlación muestral entre:
      (i)  los efectos fijos estimados c_i (reconstruidos a partir de FE), y
      (ii) los valores ajustados (predichos) Xb en niveles para cada observación del panel.

  - Es decir, conceptualmente:
        u_i  ≈  c_i  (un valor por firma, replicado en todos sus años)
        Xb   =  x_it*β_FE   (predicción para cada t del panel)

    y luego se calcula corr(c_i, Xb) usando TODAS las observaciones (NT), con c_i repetido dentro de cada i.

  - Si en cambio uno promedia primero Xb por firma y calcula corr(c_i, Xb),
    obtiene otra cifra (correlación entre c_i y el componente "between" de Xb),
    que no coincide con la que Stata muestra como corr(u_i, Xb).
*/

** la correlacion ¿es significativa?

pwcorr c_i xb_fe if sample_fe, star(.10) 



**# Prueba de igualdad de interceptos c_i entre los i


*---------------------------------------------------------------------*
* 4. Test de igualdad de interceptos entre unidades vía dummies
*---------------------------------------------------------------------*

* 4.1. Modelo con intercepto común + dummies de firma
regress lscrap d88 d89 grant grant_1 i.fcode

* 4.2. Test conjunto de que todas las dummies de firma (salvo la base) son cero:
testparm i.fcode

* Comentario:
* - H0: todas las firmas comparten el mismo intercepto (no hay c_i).
* - El F de este test es el análogo, en la parametrización LSDV,
*   del "F test that all u_i=0" que reporta xtreg, fe.
* - Bajo FE.1–FE.3, es un F exacto con df = (N-1, N(T-1)-K).


**# Uso practico de los c_i estimados y parametros incidentales

*---------------------------------------------------------------------*
* 5. Uso práctico de los c_i_hat (cuando T es razonablemente grande)
*---------------------------------------------------------------------*

* 5.1. Describir la distribución de los efectos fijos
summarize c_i
_pctile c_i, p(10 25 50 75 90)
kdensity c_i

* 5.2. (Opcional) guardar los c_i_hat para análisis posteriores
*       (por ejemplo, relacionarlos con características observables de la firma)
preserve
keep fcode c_i
duplicates drop
sort fcode
save "c_i_firmas.dta", replace
restore

* Comentario sobre teoría:
* - Los c_i_hat son insesgados, pero con T fijo no son consistentes
*   cuando N→∞ (problema de parámetros incidentales).
* - En la práctica, se usan más para descripción (mapear heterogeneidad,
*   percentiles, correlaciones con otras variables) que para inferencia
*   puntual sobre cada c_i.
* - No confundir la correlacion del punto 3 con el ICC (rho de xtreg): el ICC mide
*   la proporción de varianza explicada por c_i sobre la varianza total
*   del error compuesto, y es otra cosa distinta.
*---------------------------------------------------------------------*



**# Conclusion sobre FE hasta este punto

/* RESUMEN DE EFECTO FIJO */

xtreg	lscrap	d88	d89	grant	grant_1,	fe

 
 ** Primero miro "rho". Si esta cerca de 1 sabemos que el modelo presenta gran variacion relativa "entre" pero poca variacion relativa "dentro". 
 ** Esto te infla las varianzas de los estimadores (coeficientes). --> siguiente aspecto a observar.
 ** Por lo que nos interpela en cuanto al uso de FE para estos datos. Quiza deberiamos optar por otra estrategia.
 ** Si vamos a RE o MCO agrupado, tenemos que fundamentar la no correlacion entre u_i y X. (En el taller de RE vimos todo el analisis de RE e incluso un test RE vs MCO.)
 ** Si no podemos fundamentar que los u_i no se correlacionen con los regresores, hay que ser prudente porque con un valor de rho cercano a uno, como dijimos, infla la varianza ya que
 ** la poca variacion "dentro" impacta en los regresores transformados (within) y eso aumenta la varianza. 
 
 ** Por otro lado, sabemos que podemos obtener estimaciones de cada c_i. Hay dos cosas que vemos en la salida asociadas a esto:
 ** Una es la correlacion de c_i con xb: esto es mas una medida que sirve en ocaciones para justificar ex post el uso de FE. 
 ** si la correlacion se aleja de cero (en cualquiera de las dos direcciones), entonces podria servir como justificacion de que usar FE resulte apropiado. 
 ** Por otro lado, se hace un test F de exclusion de todos los c_i. Si no se rechaza, es una forma de justificar que FE o RE son candidatos a utilizarse.
 
 /* Se estima una regresion con dummies y se corre el test:
    Si F test that all	u_i=0:	F(53, 104)	=	24.66	Prob>F	=	0.0000
	---> concluimos que, ex post, rechazamos la nula y por lo tanto los c_i son todos diferente de cero. 
	---> el test nos dice que los c_i son diferente de 0, pero no nos dice nada acerca de si tienen relacion o no con los regresores.
	---> este test solo nos estaria diciendo que podriamos tener c_i diferente de cero y por lo tanto, nos plantea la pregunta ¿Estimar por RE? o ¿Estimar por FE?
	
	Pero luego, el calculo de la correlacion entre c_i y los xb (valores predichos) nos indica que, si esta lejos de cero,
	esta justificando (ex post) que deberiamos usar FE, ya que esos c_i se estan correlacionando con los regresores. En ese caso, RE no seria consistente. Estimar por FE si. 
	Si, por el contrario, esta cercano a 0, seria una surencia de que quizas no es necesario FE, y la estrategia RE se presenta como más creible. 
	Se termina transformando en un argumento para usar RE.
	
	De todas maneras, debemos considerar tanto el primer test F como esta correlacion con algo de cuidado:
	los c_i tienen el problema de "parametros incidentales", cuanto mas pequeño es el T ( periodo de panel) mas imprecisas suelen ser sus estimaciones.
	Estos c_i solamente son estimados de forma consistente cuando T crece mucho, pero con T pequeños tenes estimaciones no consistentes.
	Eso nos advierte sobre no confiar ciegamente ni en el F de exclusion de todos los c_i, ni en el valor que nos arroje la correlacion entre c_i y xb. 
	
	
    En estos datos: 1) los c_i parecen ser diferentes de 0 --> ¿RE o FE?
	                2) los c_i tiene una correlacion lineal baja con los valores predichos de FE: 0.07 --> cercano a 0.
					   y segun pwcorr no es significativo ni al 10%.  ---> entonces en lugar de ser un argumento para usar FE, termina siendo un argumento para usar RE.
					Hasta aca me inclino por RE en lugar de FE, pero la lectura de los puntos 1) y 2) debe matizarse
					con el hecho de que tenemos solo T=3, y la estimacion de los c_i no es consistente en este caso.
					
					3) Por otro lado, el rho es de 0.90, muy cercano a 1. Con un valor tan alto, los regresores transformados tienen poca variacion "dentro", esto hace que las estimaciones sean mas imprecisas.
					   ---> puede dificultar encontrar coeficientes significativos.
					   
					4) Cuando las señales no son claras, o no son favorables a FE, uno empieza a preguntarse si usar RE, o MCO agrupado. (mas adelante veremos CRE como otra estrategia intermedia).
					   Si nos vamos a RE o MCO agrupado, hay que justificar que los c_i no se correlacionan con los X. 
					   Pero si hacemos esta justificacion por la correlacion entre c_i y xb, no creo que sea creible si se basa en unos c_i que se obtienen con T=3.
					   No se de cuanto tendria que ser, pero cuanto mas mejor. (Aunque N siempre debe ser >> que T.). 
					   
					   En si, estos datos ya sea estimados por FE o RE tendran el mismo problema de poca variacion "dentro": 
								en FE: no lo vemos directamente en la matriz de varianzas y covarianzas en cuanto a que no esta presente el parametro de varianza de la heregoneidad inobservable,
									pero lo vemos en la poca variacion de los regresores transformados que estan en la formula de la varianza.
									Aun asi, podemos estimar igual el parametro de varianza de la heterogeneidad inobservable, será alta.
								en RE: lo vemos directamente en la matriz de var-cov que incorpora directamente esta varianza como parametro. 
								
					   Esto a veces es un tema inherente de tus datos: puede faltar mayor N, y tambien algunos periodos más. 
					   O en si, estos datos no ayudan en el sentido de tener intrinsecamente poca variacion "dentro". 
					   
					 5) Pero tambien pueden ser problemas de especificacion. Probar con mas rezagos o probar con mas controles, a veces alguna variable importante para tener otro control. 
					    Recordar que en RE podemos poner dummies de industria, pero no en FE.
						
					  6) Por ultimo, hay cosas que veremos mas adelante: efectos fijos con VI. quiza hay endogeneidad por variable omitida, por ejemplo. entonces VI-EF podria ser lo que resulte mejor. 
					    Tambien esta VI-RE como otra opcion. Pero creo que estas estrategias de VI-RE vs VI-FE deben definirse antes. Es mejor antes decidir entre RE vs FE. 
						Por ello, tener presente algunas cosas
						   a) a continuacion vamos a usar otra medida que comparar directamente FE vs RE
						   b) y luego usaremos un test (hausman) para terminar de evaluar FE vs RE.
						   
						Con el analisis de la salidad de FE que hemos hecho hasta ahora, mas la medida comparativa que veremos, más el test de hausman, tenemos elementos suficientes para tener una decision fundamentada.
						
						Luego, considerar que existen otros modelos como CRE (intermedio entre RE y FE), o la posibilidad de instrumentar una endogena, luego de  haber elegir RE o FE.
						
*/
	

	
**# FE: con varianza robusta a heterocedasticidad y correlacion serial
		

/******************************************************************
* 1. Estimación FE y varianza robusta/clúster 
******************************************************************/


*  Estimador FE con varianza "clásica" (asume FE.3: homocedasticidad, no corr. serial)
xtreg lscrap d88 d89 grant grant_1, fe

* Mismo estimador FE pero con matriz de varianza robusta tipo "cluster por id"
*     Esto implementa en la práctica la matriz sandwich:
*     (X'X)^(-1) sum_i X_i' u_i u_i' X_i (X'X)^(-1)
*     permitiendo heterocedasticidad y correlación serial arbitraria dentro de cada id.
xtreg lscrap d88 d89 grant grant_1, fe vce(cluster fcode)

* Comentario para el taller:
* - Los coeficientes FE son los mismos en 1.2 y 1.3.
* - Lo que cambia son los errores estándar y, por ende, los t y los F.
* - En 1.2 son válidos solo si FE.3 es razonable (homocedasticidad + sin corr. serial).
* - En 1.3 son robustos a heterocedasticidad y corr. serial arbitraria dentro de cada id.

** en este caso, grant presenta un desvio estandar apenas mas chico, mientras que grant_1 ahora tiene un desvio estandar más grande.

**# Pruebas sobre coeficientes robusta

/******************************************************************
* 2. Tests F / Wald luego de FE con vce(cluster id)
******************************************************************/

* Estimamos el modelo FE con varianza robusta/clúster
xtreg lscrap d88 d89 grant grant_1,	fe vce(cluster fcode)

* 2.1 Test conjunto de significancia de varios regresores
*     H0: x2 = 0 y x3 = 0
test grant	grant_1

** no rechazamos que ambas sean cero. Es un modelo mal especificado. 

* Stata:
* - Usa la matriz de varianza robusta ya estimada.
* - El F que reporta es un F de Wald robusto (asintótico).
* - La interpretación: test de hipótesis válido bajo heterocedasticidad
*   y corr. serial arbitraria dentro de id, con N grande y T fijo.

* 2.2 Test de una restricción lineal genérica, por ejemplo:
*     H0: x2 + x3 = 0
test grant	+ grant_1 = 0

* Comentario para el taller:
* - Con varianza "clásica", el F coincide con el F exacto basado en SSR_U y SSR_R bajo FE.3.
* - Con vce(cluster id), SSR ya no te da un F con distribución exacta F(q, N(T-1)-K),  por eso el texto insiste en que hay que usar tests de Wald robustos. (El del comando test luego de usar vce(cluster id))


**# Prueba de correlacion serial

/******************************************************************
* 3. Tests de correlación serial usando residuos FE
******************************************************************/

* Paso 1: Estimar el modelo FE (puede ser con o sin vce(cluster))
xtreg lscrap	d88	d89	grant grant_1, fe vce(cluster fcode)

* Paso 2: Guardar los residuos FE (residuos de la ecuación within)
predict u_fe, e


/******************************************************************
* 3.2 Test simple: correlación entre residuos FE en T-1 y T
*      (solo tiene sentido si T >= 3 )
******************************************************************/

* Ejemplo: T = 3 con años 87, 88 y 89
* H0: Corr(u_fe_{i,88}, u_fe_{i,89}) = -1/(T-1) = -1/2

preserve

* Nos quedamos solo con los residuos FE y las variables id y year
keep fcode year u_fe
* Nos quedamos con los dos últimos años (por ejemplo, 88 y 89)
keep if inlist(year, 1988, 1989)
* Reorganizamos a formato wide para tener una fila por id
reshape wide u_fe, i(fcode) j(year)

* Renombramos por claridad
rename u_fe1988 u_fe_Tm1   // residuos en T-1
rename u_fe1989 u_fe_T     // residuos en T

* Regresión transversal: u_fe_T sobre u_fe_Tm1
reg u_fe_T u_fe_Tm1, vce(cluster fcode)

* Valor teórico bajo FE.3: d0 = -1/(T-1)
local T 3
local d0 = -1/(`T' - 1)

* Test de H0: d = d0
test _b[u_fe_Tm1] = `d0'

restore

* Comentario para el taller:
* - Si rechazás H0, hay evidencia de que la correlación serial en u_it  es distinta de la que induce la de-meanización (posible corr. serial real).
* - Si no rechazás, el patrón observado es compatible con FE.3 (sin corr. serial).

/* Resultados clave:

Coeficiente estimado: d^≈−0.507.
Valor teórico bajo FE.3: d0=−1/(T−1)=−1/2=−0.5.


Interpretación de Test:
La correlación estimada entre u_i,88  y u_i,89 es prácticamente -0.5, como predice la teoría cuando:
los errores verdaderos u_it no tienen correlación serial, y la única correlación en los residuos FE proviene de la de-meanización.
Como el p-value es ≈ 0.99, no rechazás H₀: d = -0.5.

 Mensaje didáctico fuerte:
"Si me fijo solo en 1988–1989, el patrón de correlación de residuos FE es perfectamente compatible con FE.3: parece que la única correlación viene de restar la media, no de correlación serial real de u_it."

*/


/******************************************************************
* 3.3 Test general: regresión de residuos FE sobre su rezago
*     con vce(cluster id)
******************************************************************/

* Ya tenemos u_fe de xtreg, fe
* Paso 1: crear el rezago dentro de cada id (solo cuando el año es consecutivo)
sort fcode year
by fcode: gen u_fe_L1 = u_fe[_n-1]

* Asegurarnos de que el rezago corresponde al período anterior (no saltos de años)
by fcode: gen dt = year - year[_n-1]
replace u_fe_L1 = . if dt != 1
drop dt

* Paso 2: regresión panel de u_fe sobre su rezago
regress u_fe u_fe_L1 if !missing(u_fe_L1), vce(cluster fcode)


* Valor teórico bajo FE.3:	d0	=	-1/(T-1)
scalar d0 = -1/(3 - 1)
* Test de H0: d = d0
test _b[u_fe_L1] = d0


* Interpretación:
* - Bajo FE.3 y T >= 3, la correlación inducida por de-meanización es -1/(T-1) = -1(3-1) = -1/2.
* - Si el coeficiente de u_fe_L1 es muy distinto de ese valor, hay indicios de  correlación serial adicional en u_it.
* - Se puede formalizar comparando con -1/(T-1) (como antes) o, más simple, probando si el coeficiente es "cercano a 0" como test básico de corr. serial.

/* 

Resultados Clave:

Obs. con rezago válido: 108 (54 firmas × 2 transiciones: 87→88 y 88→89).

Coeficiente estimado: d^≈−0.206.

Test de H₀: d=−0.5:

Interpretación del Test:

Ahora la correlación "promedio" entre residuos FE consecutivos es mucho menos negativa que -0.5 (≈ -0.21).

Bajo FE.3 y T = 3, cualquier par (87–88, 88–89) debería tener corr. ≈ -0.5 si no hubiese correlación serial en los u_it.
Como rechazás que d=−0.5, y además d^ está bastante más cerca de 0, la lectura natural es:

"Los errores verdaderos u_it parecen tener correlación serial positiva; la de-meanización induce -0.5, pero la autocorrelación real contrarresta parte de eso y deja una correlación observada menos negativa (−0.21)."
Y también es significativo distinto de 0 (F(1,53)=25.11, p=0.000) → hay correlación entre u_it y u_it−1 después de controlar por media.

Mensaje para el taller:

"Cuando miro todas las transiciones y uso un modelo panel con errores agrupados, rechazo la historia FE.3: la correlación de los residuos no es la que debería surgir solo de la transformación within. Hay evidencia de correlación serial verdadera en u_it."

*/



***** la conclusion del test generico para la correlacion, nos sugiere que hay correlacion serial real en los datos, mas alla de la inducida por la transformacion within.
**** entonces deberiamos usar una matriz robusta a la correlacion serial, por ejemplo, podemos usar el mismo estimador FE pero con la opcion vce(cluster id). Esto es lo que hicimos en la parte previa.


**# FGLS: FEGLS con estructura AR(1). Con xtregar


***************************************************************************************************************
*******************************    FEGLS ***********************************************************************
***************************************************************************************************************


* Declarar panel
xtset fcode year
* Asegurarnos (o al menos chequear) que el panel está balanceado
xtdescribe

** Pasamos a un estimador diferente, GLS. Este estimador pondera por la matriz de varianza y covarianza. 
** Si tuvieramos informacion a priori de que estos datos siguen un PGD donde la estructura de correlacion serial fuese un AR(1), podriamos interiorizar esta estructura en la varianza, lo que lo haria mas eficiente, 
** pero siempre y cuando esta estructura fuese cierta. Aca no solo cambia la matriz de varianzas y covarianzas, sino tambien el estimador de los coeficientes.

*---------------------------------------------------------------*
*  FE con errores AR(1) usando xtregar
*---------------------------------------------------------------*

* 1) Declarar la estructura de panel
xtset fcode year

* 2) Estimador FE "normal" con varianza robusta-cluster (benchmark)
xtreg lscrap d88 d89 grant grant_1, fe vce(cluster fcode)
eststo fe_robust

* 3) Estimador FE con estructura AR(1) en el error idiosincrático
xtregar lscrap d88 d89 grant grant_1, fe
eststo fe_ar1

* Opcional: guardar y comparar
esttab fe_robust fe_ar1, se label

/*
Esa es tu Λ: correlación serial AR(1) + homocedasticidad en el tiempo (dada Λ), igual entre unidades.
xtregar, fe aplica una transformación GLS (básicamente "descorrelación" AR(1)) y luego hace FE sobre los datos transformados.

*/
** observar como si AR(1) fuese cierta en el PGD, y si miramos su estimacion, practicamente no habria correlacion entre los c_i y los regresores. 
** sigue pasando que la varianza de los c_i pesa mucho en la varianza total: si estimaramos por RE con AR(1) esto seguira pasando. 


**# FGLS: Replica FEGLS como explicita Wooldridge 

*****************************************************************
*---------------------------------------------------------------*
*  FEGLS.3: implementando estimacion FEGLS con los pasos del libro 
*          (no hay comando que facilite esto)
*---------------------------------------------------------------*

/* Explota la estructura "común" de correlación/heterocedasticidad en el tiempo entre todas las unidades (FEGLS.3).
Si en realidad FE.3 fuese cierto (errores esféricos), W sería proporcional a una identidad y este FEGLS colapsaría a FE.
*/


*============================================================*
* FEGLS a lo Wooldridge para lscrap, T = 3 (1987–1989)
*============================================================*

* 0) Cargar base y declarar panel (ajustar path si hace falta)
* use "wooldridge_scrap.dta", clear
xtset fcode year


*-----------------------------------------------------------*
* 1. FE estándar y construcción de variables within (tilde)
*-----------------------------------------------------------*

xtreg lscrap d88 d89 grant grant_1, fe

* Residuos FE (within)
drop u_fe
predict u_fe, e

* y~ = lscrap - promedio por firma
drop lscrap_tilde lscrap_bar
bysort fcode: egen lscrap_bar = mean(lscrap)
generate lscrap_tilde = lscrap - lscrap_bar

* x~ para cada regresor
drop d88_tilde d88_bar
bysort fcode: egen d88_bar = mean(d88)
generate d88_tilde = d88 - d88_bar

drop d89_tilde d89_bar
bysort fcode: egen d89_bar = mean(d89)
generate d89_tilde = d89 - d89_bar

drop grant_tilde grant_bar
bysort fcode: egen grant_bar = mean(grant)
generate grant_tilde = grant - grant_bar

drop grant1_tilde grant1_bar
bysort fcode: egen grant1_bar = mean(grant_1)
generate grant1_tilde = grant_1 - grant1_bar

sort fcode year

*-----------------------------------------------------------*
* 2. Estimar W_hat (matriz de covarianzas de residuos recortados)
*-----------------------------------------------------------*

preserve

* Guardar la muestra usada por FE
gen byte fe_sample = e(sample)

* Quedarnos solo con esas observaciones (las 162)
keep if fe_sample

keep fcode year u_fe

* T=3 → usamos 1987 y 1988
keep if year == 1987 | year == 1988

reshape wide u_fe, i(fcode) j(year)

correlate u_fe1987 u_fe1988, cov
matrix W_hat = r(C)
matrix list W_hat

restore


*-----------------------------------------------------------*
* 3. FEGLS via Mata + matriz de varianza, SE y t
*-----------------------------------------------------------*

preserve
sort fcode year

* (ya hiciste antes keep if e(sample), etc. y tenés tilde bien definidas)
gen byte fe_sample = e(sample)
keep if fe_sample
drop fe_sample

mata: mata clear

mata:
    // 1. Traer datos a Mata
    st_view(id    = ., ., "fcode")
    st_view(time  = ., ., "year")
    st_view(ytilde= ., ., "lscrap_tilde")
    st_view(Xtilde= ., ., "d88_tilde d89_tilde grant_tilde grant1_tilde")

    // Matriz W y su inversa (estimada en el paso 2)
    W_hat = st_matrix("W_hat")
    W_inv = invsym(W_hat)

    // Estructura temporal
    tvals = uniqrows(time)
    T     = rows(tvals)
    TT    = T - 1
    tmax  = tvals[T]

    // Nos quedamos con los primeros T-1 periodos (sistema recortado)
    idx_keep = (time :!= tmax)
    id2      = select(id, idx_keep)
    time2    = select(time, idx_keep)
    y2       = select(ytilde, idx_keep)
    X2       = select(Xtilde, idx_keep)

    // Dimensiones
    ids_uniq = uniqrows(id2)
    N        = rows(ids_uniq)
    K        = cols(X2)

    // Inicializar sumas A y b
    A = J(K, K, 0)
    b = J(K, 1, 0)

    // Loop por unidad
    for (j = 1; j <= N; j++) {
        thisid = ids_uniq[j]
        rows_i = selectindex(id2 :== thisid)

        Xi = X2[rows_i,]
        yi = y2[rows_i,]

        if (rows(Xi) != TT) {
            _error(3499, "Panel no balanceado o tiempos mal para fcode " + strofreal(thisid))
        }

        A = A + Xi' * W_inv * Xi
        b = b + Xi' * W_inv * yi
    }

    // FEGLS: beta_hat = A^(-1) b
    beta_fegls = invsym(A) * b

    // Var(beta_hat) = A^(-1)   (bajo FEGLS.3)
    V_fegls    = invsym(A)

    // Desvíos estándar = sqrt(diagonal)
    se_fegls   = sqrt(diagonal(V_fegls))

    // Pasar todo a Stata
    // beta como fila 1 x K
    st_matrix("beta_fegls", beta_fegls')
    st_matrix("V_fegls",    V_fegls)
    st_matrix("se_fegls",   se_fegls')
end
*restore

* Nombrar filas/columnas
matrix colnames beta_fegls = d88 d89 grant grant_1
matrix rownames V_fegls    = d88 d89 grant grant_1
matrix colnames V_fegls    = d88 d89 grant grant_1

matrix list beta_fegls
matrix list se_fegls

* Postear como si fuera una estimación oficial
ereturn post beta_fegls V_fegls, depname(lscrap) obs(162)

* Mostrar tabla de coeficientes, SE, z, p, IC
ereturn display

restore

/* esta es el procedimiento de wooldridge para FEGLS del libro. 
cuando exploto una estructura de correlación común en el tiempo, el estimador cambia (el estimador incorpora estos pesos) y también los SD; 
en este ejemplo, la historia cualitativa no cambia mucho (ninguno es fuertemente significativo), pero podría hacerlo en otros paneles.
*/







