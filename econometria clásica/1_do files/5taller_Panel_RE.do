**# Capitulo 10



clear all  
  
bcuse wagepan, clear
describe

* Declarar la estructura de panel y ordenar observaciones
xtset nr year
sort nr year
 

**# RE: directo con xtreg

/********************************************************************/
/*  1. EFECTOS ALEATORIOS (RE) CLÁSICO Y VERSIÓN ROBUSTA           */
/********************************************************************/

/*
  Modelo:
    y_it = x_it' * beta + c_i + u_it

  Bajo RE.1 y RE.2, el estimador de efectos aleatorios es FGLS con
  matriz de varianza:
    W = sigma_u^2 * I_T + sigma_c^2 * j_T * j_T'

  Caso 1a) RE clásico:
    - xtreg, re       -> FGLS con W de RE, varianza "clásica".
    - Supone que RE.3 es cierto (estructura exacta de W).

  Caso 1b) RE con matriz robusta tipo cluster:
    - xtreg, re vce(robust)
    - Con xtreg, vce(robust) = matriz sándwich cluster por id
      (usa el panel declarado en xtset).
    - Robusta a heterocedasticidad y correlación serial arbitraria
      dentro de cada unidad.
*/


/*** 1a) EFECTOS ALEATORIOS (RE) CLÁSICO (VARIANZA CLASICA) ***/

xtreg lwage educ exper expersq union married black, re

** "sigma_u" representa para Stata (xtreg) el desvio estandar de "sigma_c^2" del libro de Wooldridge. 
** Si lo elevamos al cuadrado, tendremos la varianza constante asociada a los efectos inobservables, c_i.

** "sigma_e", representa para Stata (xtreg) el desvio estandar de "sigma_u^2" del libro de Wooldridge. 
** Si lo elevamos al cuadrado, tendremos la varianza constante asociada a los errores idiosincráticos, u_it. 

** "rho", representa el peso de "sigma_c^2" entre el total de la varianza: (sigma_c^2+sigma_u^2) = sigma_v^2, esto es: sigma_c^2/sigma_v^2.
** en este caso con la salida de xtred: rho = ((sigma_u)^2)/((sigma_u^2)+(sigma_e^2))

** evidentemente, te muestra que se asume corr(u_i, X) = 0. (En xtreg se usa u_i para denotar a la heterogeneidad inobservable, mientras que en el libro usa notacion c_i para la heterogeneidad inobservable). 


**# Prueba para binarias temporales

xtreg lwage educ exper expersq union married black d81-d87 , re
 test d81 d82 d83 d84 d85 d86 d87
 ** no agrego dummies temporales en este caso. Si las agregara, en teoria haria que las interpretaciones de mis controles sea "neta de efectos comunes en el tiempo", pero en este caso,
 ** el test nos sugiere no incluirlas: por lo tanto no se incluyen. Es como que en estos datos, no hay nada que "limpiar" respecto a shocks macros comunes. 
 
 
/*** 1b) EFECTOS ALEATORIOS (RE) CON MATRIZ DE VARIANZA ROBUSTA (CLUSTER ID) ***/

/*
  NOTA: En modelos xt*, vce(robust) = vce(cluster id) implícito.
  Es la versión recomendada en la práctica.
*/

** sabemos que los coeficientes no deben cambiar.
** tampoco deben cambiar los valores de las estimaciones para los parametros de la varianza: se usa el mismo W, al tener misma estructura, es gobernado por los mismo valores de parametros.
** lo que cambia es que ahora la matriz de varianzas-covarianzas se pondera de otra forma al permitir una estructura tipo sandwich, usando el producto interior de los residuos. 
** en suma, solo esperaremos que puedan modificarse los errores estandar, y con ello los t, p-valor e intervalos de confianza.

xtreg lwage educ exper expersq union married black, re vce(robust)
** con xtreg, es indistinto usar vce(robust) o vce(cluster nr)
xtreg lwage educ exper expersq union married black, re vce(cluster nr)


**# Obtenemos parámetros de varianza (componente de error)

/********************************************************************/
/*  2. Estimemos "manualmente" los parametros de la varianza del estimador RE 
MCO AGRUPADO Y RESIDUOS vtilde_it PARA ESTIMAR VARIANZAS     */
/********************************************************************/

/*
  Objetivo, en notación Wooldridge: 
    - Obtener sigma_v^2 = Var(v_it) // total 
    - Obtener sigma_c^2 = Var(c_i) // asociada a heterogeneidad inob
    - Obtener sigma_u^2 = Var(u_it) // asociada a errores 
  Objetivo, en notación xtreg: 
    - Obtener sigma^2 = Var(v_it) // total 
    - Obtener sigma_u^2 = Var(u_i) // asociada a heterogeneidad inob
    - Obtener sigma_e^2 = Var(e_it) // asociada a errores 
	
	*/

xtreg lwage educ exper expersq union married black, re

scalar varianza_v = e(sigma)^2
display "varianza_v  = " varianza_v 

scalar varianza_c = e(sigma_u)^2
display "varianza_c  = " varianza_c 

scalar varianza_u = e(sigma_e)^2
display "varianza_u  = " varianza_u


/* Estos son los valores de los parametros de varianza que surgen de xtreg, re y que debemos compararlos con los que calculemos "manualmente".
   En teoria, deben ser identicos, pero es esperable que tengan una diferencia minima ya que estamos utilizando dos métodos distintos de estimación para los parámetros de varianza.
   Esto es porque en nuestra forma "manual" seguiremos explicitamente lo que Wooldridge plantea en el capitulo 10. 
   Mientras que en xtreg los parametros de la varianza surgen de otra manera: internamente usa un estimador quasi–ML/GLS iterado para la descomposición de varianzas.
   En términos conceptuales, combina "within" y "between" y resuelve un sistema tipo máxima verosimilitud.
   No está basado en los residuos de MCO agrupado, sino en la estructura RE misma. 
   
   Pero deberian ser diferencias muy muy chicas. 

 */
 
**# Estimamos "manualmente" parametros de varianza.

 
/*** 2.1 MCO AGRUPADO (BASE PARA RESIDUOS) ***/

reg lwage educ exper expersq union married black
predict vhat, resid


/********************************************************************/
/*  ESTIMACIÓN DE sigma_v^2, sigma_c^2, sigma_u^2                      */
/********************************************************************/

/*** 2.2 ESTIMAR sigma_v^2 = Var(v_it) ***/

/*
  Bajo RE.3(a), el estimador natural de sigmav2 es la varianza residual clásica de la MCO agrupada:
  recordando que sigma son desvios estandar y que los residuos de mco se guardan con rmse:
    sigmav^2 = (e(rmse))^2
*/

scalar varianza_v_manual = e(rmse)^2
display "varianza_v_manual = " varianza_v_manual

** vemos que 0.23109152 vs 0.22850257 es una diferencia despreciable. 1.13 %
display ((varianza_v_manual - varianza_v)/varianza_v)*100

*****

/*** 2.3 ESTIMAR sigma_c^2 a partir de los productos interiores: vhat_it * vhat_is  (esto surge de seccion 10.4)   ***/

/*
  Usamos la identidad (10.37):
    E( sum_{t<s} v_it v_is ) = sigmac2 * [T(T-1)/2]

  Estrategia:
    1) Asegurarnos de tener xtset nr year y datos en formato long.
    2) Crear un índice de tiempo tindex = 1,...,T.
    3) PRESERVAR la base y quedarnos solo con nr, tindex, vhat.
    4) reshape wide vhat, i(nr) j(tindex).
    5) Para cada i, construir:
         A_i = sum_{t<s} vhat_it * vhat_is
    6) sigmac2_hat ≈ [ sum_i A_i ] / [ N * T(T-1)/2 ].
    7) RESTORE para volver a la base original.
*/

/* Asegurarnos de que el panel está declarado (formato long) */
xtset nr year
/* Crear un índice de tiempo 1,...,T a partir de year */
capture drop tindex
egen tindex = group(year)
label var tindex "Índice de tiempo 1,...,T"
/* Guardar el número de periodos T */
quietly levelsof tindex, local(tlist)
local T : word count `tlist'

/* ---- Trabajamos en una copia reducida de la base ---- */
preserve
    /* Nos quedamos solo con lo necesario para construir A_i */
    keep nr tindex vhat

    /* Pasar vhat a formato wide: vhat1, vhat2, ..., vhatT */
    reshape wide vhat, i(nr) j(tindex)

    /* Para cada individuo i, construir A_i = sum_{t<s} vhat_it * vhat_is */
    gen A = 0
    forvalues p = 1/`T' {
        forvalues q = `=`p'+1'/`T' {
            replace A = A + vhat`p' * vhat`q'
        }
    }

    /* Suma sobre i de A_i y número de individuos N */
    summarize A
    scalar sumA = r(sum)
    scalar Npan = r(N)

    /* Estimador de sigmac2 sin ajuste de grados de libertad */
    scalar varianza_c_manual = sumA / ( Npan * (`T' * (`T' - 1) / 2) )
    display "varianza_c_manual (no ajustado por df) = " varianza_c_manual

    /*
      Si se quiere ajustar por df como en (10.37), restando K (número
      de regresores en la MCO agrupada) en el denominador:

      OJO: K se tomó de la regresión MCO previa:
        reg lwage educ exper expersq union married black
      y por eso usamos e(df_m)+1 (incluyendo el intercepto).
    */
    scalar K = e(df_m) + 1
    scalar varianza_c_manual_df = sumA / ( Npan * (`T' * (`T' - 1) / 2) - K )
    display "varianza_c_manual (con ajuste df) = " varianza_c_manual_df
restore

/* En este punto, la base vuelve a su estado original (long),
   pero las scalars sigmav2, sigmac2 y sigmac2_df ya están guardadas. */


** nuevamente, diferencias pequeñitas: 0.81%
display ((varianza_c_manual_df - varianza_c)/varianza_c)*100  


/*** 2.4 ESTIMAR sigma_u^2 = sigma_v^2 - sigma_c^2           ***/


scalar varianza_u_manual = varianza_v_manual - varianza_c_manual_df
display " varianza_u_manual = "  varianza_u_manual

** nuevamente, diferencias pequeñitas: 1.40 %
display ((varianza_u_manual - varianza_u)/varianza_u)*100  


**# Prueba para heterogeneidad inobservable c_i


/********************************************************************/
/*  3. TEST H0: varianza_c = 0 (No hay heterogeneidad inobservable, c_i)          */
/*     ESTADÍSTICO Z (EC. 10.40)                                   */
/********************************************************************/

/*
  Supuestos:
    - Partimos de los residuos MCO agrupado: vhat_it.
    - Ya hicimos: xtset nr year.
    - Queremos construir:

       A_i = sum_{t<s} vhat_it * vhat_is

     y luego:

       Z = [ sum_i A_i ] / [ sum_i A_i^2 ]^{1/2}

  Bajo H0: varianza_c = 0, Z ~ N(0,1) asintóticamente.
*/

* Asegurarnos de tener el panel declarado
xtset nr year

preserve
    * Nos quedamos solo con lo necesario para construir A_i
    keep nr year vhat

    * Obtener el número de periodos T
    quietly levelsof year, local(tlist)
    local T : word count `tlist'

    * Pasar vhat a formato wide: vhat1980, vhat1981, ..., vhat1987
    reshape wide vhat, i(nr) j(year)

    * Para cada individuo i, construir:
    *   A_i = sum_{t<s} vhat_it * vhat_is
    gen A = 0
    forvalues p = 1/`T' {
        forvalues q = `=`p'+1'/`T' {
            replace A = A + vhat`=word("`tlist'", `p')' * ///
                            vhat`=word("`tlist'", `q')'
        }
    }

    * Numerador y denominador del estadístico Z
    summarize A
    scalar num = r(sum)

    gen A2 = A^2
    summarize A2
    scalar den = sqrt(r(sum))

    scalar Z = num / den
    display "Estadístico Z (test H0: varianza_c = 0) = " Z
restore

/********************************************************************
* INTERPRETACIÓN DEL TEST H0:  varianza_c  = 0  (estadístico Z, ec. 10.40)
*
* - Este test contrasta:
*
*       H0:  varianza_c  = 0      (no hay efecto no observado c_i)
*       H1:  varianza_c  > 0      (existe un componente c_i != 0)
*
*   donde:
*       v_it = c_i + u_it
*       sigma_c^2 = Var(c_i)
*
* - Bajo H0, el error compuesto v_it no tiene componente fijo c_i:
*     • No hay heterogeneidad individual permanente.
*     • No hay correlación serial inducida por c_i dentro de cada individuo.
*     • El modelo "correcto" sería MCO agrupado con errores independientes en t.
*
* - El estadístico que calculamos es:
*
*       Z = [ sum_i A_i ] / sqrt( sum_i A_i^2 )
*
*   donde:
*       A_i = sum_{t<s} vhat_it * vhat_is
*
*   y vhat_it son los residuos MCO agrupado.
*   Bajo H0 y con N grande, Z ~ N(0,1).
*
* - Regla de decisión (prueba bilateral estándar):
*     • Nivel 5%:   rechazar H0 si |Z| > 1.96
*     • Nivel 1%:   rechazar H0 si |Z| > 2.58
*
* - En esta base, el programa arrojó típicamente un valor de |Z| >> 3
*   (por ejemplo, alrededor de 10.6 en wagepan), lo que implica:
*
*     • Rechazamos H0 de forma muy contundente.
*     • Concluimos que varianza_c > 0: existe heterogeneidad inobservable
*       relevante entre individuos (c_i distinto de cero).
*     • Equivalente: el error compuesto v_it muestra correlación serial
*       positiva dentro de cada individuo, explicada por el componente c_i.
*
* - Consecuencia práctica:
*     • No es adecuado tratar el modelo como un MCO agrupado simple con
*       errores independientes en t.
*     • Tiene sentido usar modelos que reconozcan la heterogeneidad
*       individual:
*           - efectos aleatorios (RE) o
*           - efectos fijos (FE),
*       y/o trabajar siempre con varianzas robustas agrupadas por individuo.
*
* - Advertencia:
*     • Este test detecta "alguna" forma de correlación serial en v_it;
*       el rechazo de H0 indica que hay dependencia en el tiempo, pero
*       NO garantiza que la estructura exacta RE clásica sea correcta.
*     • Si se quiere testear la forma específica de la correlación (por ej.
*       RE frente a AR(1) u otras), se requieren tests adicionales.
********************************************************************/

**# FGLS: RE con matriz W no restringida (pseudo codigo)


/********************************************************************/
/*  4. FGLS GENERAL: (MATRIZ W NO RESTRINGIDA)                       */
/********************************************************************/

/*
  Idea teórica:
    - Estimar W = E(v_i v_i') como:
        W_hat = (1/N) * sum_i vtilde_i vtilde_i'
    - Construir una matriz C_hat tal que:
        C_hat' * C_hat = W_hat^{-1}
    - Transformar:
        y_i*  = C_hat * y_i
        X_i*  = C_hat * X_i
    - Estimar:
        reg y_star x1_star ... xK_star

  La varianza "clásica" de esa regresión es la varianza FGLS general.
  En la práctica, esto requiere programación adicional (no hay un
  comando único en Stata que haga todo en un paso).
*/

/* PSEUDOCÓDIGO (NO EJECUTABLE DIRECTO, SOLO ESQUEMA):

   1) Ya tenemos vhat_it de la MCO agrupada.
   2) Para cada i, juntar vhat en vectores vtilde_i (T x 1).
   3) Construir W_hat = (1/N) * sum_i vtilde_i vtilde_i'.
   4) Calcular C_hat tal que C_hat' * C_hat = inv(W_hat).  (por ejemplo, descomposición de Cholesky)
   5) Aplicar transformación:
        y_star  = (C_hat ⊗ I_N) * y
        X_star  = (C_hat ⊗ I_N) * X
   6) Estimar:
        reg y_star x1_star ... xK_star
*/



/********************************************************************/
/*  5. FGLS GENERAL CON MATRIZ DE VARIANZA ROBUSTA (SÁNDWICH)       */
/********************************************************************/

/*
  Una vez que se tienen los datos transformados (y_star, x*_k), basta
  con usar vce(cluster id) para obtener una matriz sándwich:

    reg y_star x1_star ... xK_star, vce(cluster id)

  - Los coeficientes son los del FGLS general.
  - La matriz de varianza es robusta a heterocedasticidad y correlación
    serial arbitraria dentro de cada unidad.
*/

/* PSEUDOCÓDIGO (TRAS LA TRANSFORMACIÓN GLS):

reg y_star x1_star x2_star ... xK_star, vce(cluster id)
*/



**# FGLS: RE con W con estructura AR(1) para correlacion serial + heterocedasticidad

/********************************************************************/
/*  6. FGLS PARAMÉTRICO CON ESTRUCTURA AR(1) VIA XTGLS              */
/********************************************************************/

/* Ahora en lugar de estimar un FGLS general, que como vimos, Wooldridge nos lo enseña teoricamente, 
  y parece "facil" llevarlo a Stata, pero no hay un comando que haga los pasos anteriores automaticamente.
  Entonces, salvo que realmente se tenga interes en crearlo, en Stata lo que si hay son caminos "intermedios" entre RE clasico estimado arriba y el FGLS general (no estimado por falta de paquete)
  Esto se logra imponiendo alguna estructura sobre W: no se deja general como en FGLS general, pero tampoco se deja como en RE clasico con un estimador que tiene pesos que se basan en 
  a) homocedasticidad 
  b) solo correlacion serial inducida por la heterogeneidad inobservable, que es siempre constante en el tiempo. No se degrada como un AR(1) por ejemplo. 
  
  Compromiso entre RE y FGLS general:
    - Suponer una estructura paramétrica para E(u_i u_i').
    - Ejemplo típico: AR(1) en el tiempo para u_it y heterocedasticidad en i.

  El comando xtgls implementa este tipo de modelos. Por ejemplo:
*/

xtgls lwage educ exper expersq union married black, igls panels(hetero) corr(ar1)

/*
  Donde:
    - corr(ar1) impone correlación AR(1) en el tiempo.
    - panels(hetero) permite varianzas distintas entre paneles.
  xtgls reporta la matriz de varianza "clásica" asociada a esa estructura: es decir, NO tiene la forma de sandwich, sino que mantiene la forma clasica de RE para la varianza, pero los W que utiliza no son tan estrictos, son otros!.
 el estimador usa otros pesos diferente al estimador RE: mientras RE usar los W "clasicos" homocedasticos y solo con la correlacion constante inducida por c_i, el FGLS estima con pesos usando W que tienen la estructura indicada con este comando, en este caso correlacion ar(1) y heterocedasticidad entre individuos. Lo que mantienen en comun es la forma que adopta la estructura de la varianza, no será tipo sandwich. Pero alli tambien usan diferente W (peso).
 
 El punto teorico es, ¿será que la verdadera varianza (desconocida) es mas de esta forma con cierta estructura que la clasica casi sin estructura? En wooldridge se dejan avisos interesantes sobre esta discusion. 
  
  Si uno quiere cubrirse, podria volver a estimar un RE (con estimador con pesos RE) pero con matriz de var-cov tipo sandwich como hicimos mas arriba en 1b). 
  Esto ultimo hace a esa estrategia mas robusta por el lado de inferencia, pero los coeficientes se estiman con pesos clasicos de RE. No es una estrategia "robusta-robusta".
  Para llegar a algo muy general, "robusta-robusta", deberia hacer lo que en este taller se especificó en el item 4) y luego lo del item 5). Ya que de esa manera, los coeficientes se estiman con pesos robustos (generales) y tambien la matriz de varianzas y covarianzas lo hace. En el caso del item4), con una estructura clasica pero usando pesos genericos, en el caso del item 5) con estructura de sandwich tipica de cluster. 
  costo computacional: hay que crear todo el codigo.
  
  Entre esto ultimo de versiones "robustas-robustas" y el RE clasico, estan las opciones FGLS con las opciones panels(hetero) o corr(ar1) implementada en item 6) o la opcion implementada en 1b). 
*/



**# Ejemplo: RE en tasa de descarte jtrain.dta

/********************************************************************/
/*  EJEMPLO 10.4: EFECTOS ALEATORIOS EN TASA DE DESCARTE         */
/********************************************************************/

clear all
bcuse jtrain, clear
describe
/*
  Suposiciones de nombres de variables:
    fcode        = identificador de firma
    year      = año (1987, 1988, 1989)
    scrap     = tasa de descarte
    d88, d89  = dummies de año
    union     = dummy de sindicato
    grant     = subsidio en el año t
    grant_1   = subsidio en el año t-1
*/

/* Declarar panel */

xtset fcode year

** spoiler: es probable que de "cualquier cosa" porque este panel tiene un N muy chico...
** el problema no esta en que se use la variable dependiente como un cambio en y
** tampoco es problema que se use un rezago de un regresor exogeno.
** faltan observaciones, no estamos en teoria asintotica.

/* Variable dependiente: cambio en log(scrap) */
gen l_scrap = log(scrap)
by fcode (year): gen d_lscrap = l_scrap - l.l_scrap

/* RE clásico */
xtreg d_lscrap d88 d89 union grant grant_1, re

/* Prueba conjunta H0: grant = 0 y grant_1 = 0 (Wald, chi2_2) */
test grant grant_1

/* RE con matriz de varianza robusta tipo cluster */
xtreg d_lscrap d88 d89 union grant grant_1, re vce(robust)

** no es la misma base que usa wooldridge en su libro, esta es una version "cortita".



**# Comparacion: POLS, RE, REGLS (AR(1)+Heteroc.) 

********************************************************************

/********************************************************************/
/*  COMPARACIÓN DE 5 MODELOS: RE, RE-robusto, REGLS AR(1), OLS, OLS-cluster  */
/********************************************************************/
/*
 Modelos estimados (sobre wagepan):
   M1: xtreg lwage educ exper expersq union married black, re
   M2: xtreg lwage educ exper expersq union married black, re vce(cluster nr)
   M3: xtgls lwage educ exper expersq union married black, igls panels(hetero) corr(ar1)
   M4: reg   lwage educ exper expersq union married black
   M5: reg   lwage educ exper expersq union married black, vce(cluster nr)

 Objetivo:
   - Poner los 5 modelos en una sola tabla prolija con esttab.
   - Definir un ÚNICO indicador de "R2" llamado R2_clean:
       * Para los modelos RE (M1, M2): usar el R² overall de xtreg: e(r2_o).
       * Para FGLS (M3) y OLS (M4, M5): usar el R² clásico de e(r2).
   - En la tabla, la fila se llama: "R2 (overall / pseudo)".
     * En RE: es R² overall, comparable al R² de MCO agrupado.
     * En FGLS: es un pseudo-R² en la escala transformada (leerlo con cuidado).
*/

/********************************************************************/
/*  0. PREPARACIÓN                                                  */
/********************************************************************/

* Cargar datos (si no están cargados ya)
clear all
bcuse wagepan, clear

* Declarar panel
xtset nr year

* Si no tenés estout instalado:
ssc install estout, replace
eststo clear


/********************************************************************/
/*  1. CONSTRUIR UN R2 COMÚN: R2_clean                              */
/********************************************************************/
/*
  Idea:

  - En RE (xtreg, re), Stata guarda tres R²:
      e(r2_w)  : within
      e(r2_b)  : between
      e(r2_o)  : overall

    Para comparar con MCO en corte transversal, lo más razonable es el R² overall:
      -> mide qué parte de la varianza total de y_it en niveles se explica por los regresores del modelo RE.
    Por eso, para M1 y M2 definimos:
      R2_clean = e(r2_o)
*/

/********************************************************************/
/*  NOTA SOBRE EL R² EN EL MODELO FGLS (xtgls)                       */
/********************************************************************/

/*
  - El comando xtgls NO guarda un R² estándar en e(r2), por eso
    no podemos usar estadd scalar R2_clean = e(r2) como en regress
    o xtreg.

  - En su lugar, definimos un R² "limpio" en la escala original de
    la variable dependiente como:

        R2_gls = corr(lwage, yhat_gls)^2

    donde:
      * lwage     = variable dependiente original (sin transformar),
      * yhat_gls  = valores ajustados del modelo FGLS:
                      predict yhat_gls, xb

    Es decir, tomamos la correlación muestral entre lwage e yhat_gls
    y la elevamos al cuadrado.

  - Interpretación:
      * R2_gls mide qué proporción de la variación de lwage (en su
        escala original) está asociada linealmente a las predicciones
        del modelo FGLS.
      * Es comparable como "medida de ajuste" con el R² clásico de
        MCO y el R² overall de RE, porque siempre se calcula sobre
        la misma variable dependiente original.

  - Advertencia:
      * Este R² no es el "pseudo-R²" interno de xtgls en la escala
        transformada, sino una construcción ex post en la escala
        original. Sirve para comparar niveles de ajuste entre modelos
        (RE, MCO, FGLS), pero hay que recordar que las predicciones
        de FGLS vienen de un modelo estimado sobre datos transformados
        según la estructura de varianza-covarianza especificada. 
*/


/********************************************************************/
/*  2. ESTIMACIÓN DE LOS 5 MODELOS  y R2 comparables                               */
/********************************************************************/

* M1: RE clásico (varianza RE clásica)
xtreg lwage educ exper expersq union married black, re
eststo re_classic
* M1: RE clásico -> usar R² overall ---
estimates restore re_classic
estadd scalar R2_clean = e(r2_o)

* M2: RE con varianza robusta tipo cluster (misma W, pero matriz sándwich)
xtreg lwage educ exper expersq union married black, re vce(cluster nr)
eststo re_robust
* --- M2: RE robusto -> usar también R² overall ---
estimates restore re_robust
estadd scalar R2_clean = e(r2_o)


* M3: FGLS paramétrico: heterocedasticidad entre paneles + AR(1) en el tiempo
xtgls lwage educ exper expersq union married black, ///
    igls panels(hetero) corr(ar1)
eststo fgls_ar1_het
* --- M3: FGLS AR(1) -> usar e(r2) (pseudo-R² en escala transformada) ---
estimates restore fgls_ar1_het

* Construimos un R² en la escala original:
*   R² = corr(lwage, yhat_gls)^2

capture drop yhat_gls
predict yhat_gls, xb

corr lwage yhat_gls
scalar R2_gls = r(rho)^2

estadd scalar R2_clean = R2_gls

* M4: MCO agrupado clásico
reg lwage educ exper expersq union married black
eststo ols_classic
* --- M4: OLS clásico -> usar R² clásico de MCO ---
estimates restore ols_classic
estadd scalar R2_clean = e(r2)

* M5: MCO agrupado con matriz robusta tipo cluster
reg lwage educ exper expersq union married black, vce(cluster nr)
eststo ols_cluster
* --- M5: OLS cluster -> mismo R² clásico ---
estimates restore ols_cluster
estadd scalar R2_clean = e(r2)


**# Tabla comparativa

/********************************************************************/
/*  3. TABLA CON ESTTAB                                             */
/********************************************************************/

* Tabla básica en pantalla
esttab re_classic re_robust fgls_ar1_het ols_classic ols_cluster, ///
    se b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(R2_clean N, labels("R2 (overall / pseudo)" "N obs.")) ///
    title("Comparación de modelos RE, RE-Cluster, FGLS AR(1)-HET(Panel), POOL-OLS, POOL-OLS-Cluster ") ///
    nonote

    


/********************************************************************/
/*  FIN DEL BLOQUE DO: EFECTOS ALEATORIO  EN STATA           */
/********************************************************************/

 