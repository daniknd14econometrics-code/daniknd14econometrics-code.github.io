*** Capitulo 15 ***

clear all
bcuse mroz, clear 
describe

* Inspeccionar la variable dependiente y verificar que sea binaria
tabulate inlf

**# MPL (lineal)

* Estimar el modelo de probabilidad lineal (MPL) por MCO
* La opción vce(robust) calcula errores estándar robustos a heterocedasticidad.
* Por construcción, necesitamos usar una varianza robusta: la naturaleza de la variable dependiente, inlf, toma solamente dos valores: {0,1}.
* En este contexto, esta variable tiene una distribucion Bernoulli. En este caso, la varianza es igual a var(u/x)=xb*(1-xb)
* Que es, necesariamente, heterocedastica porque depende de cada xi.

regress inlf nwifeinc educ exper expersq age kidslt6 kidsge6, vce(robust)
estimates store mpl_full

* Obtener probabilidades predichas del LPM
predict double phat, xb

* Verificar cuántas predicciones están fuera del intervalo [0,1]
count if phat < 0 | phat > 1
scalar N_oob  = r(N)
scalar pct_oob = 100*N_oob/_N
display pct_oob
* Tenemos casi un 5% de observaciones con una probabilidad predicha que se escapa del intervalo [0,1]

* Inspeccionar algunos casos con predicciones extremas
list phat if phat < 0 | phat > 1 

* Si nos interesa realmente la probabilidad para este ejercicio, nos deberiamos preguntar,
* ¿cuantas observaciones estan por fuera del intervalo de probabilidades? en este caso, casi un 5%. 
* Quiza podemos considerar que es un buen resultado, y podriamos hacer un analisis donde quitemos estas probabilidades problematicas
* si el objetivo es sobre las probabilidades.

* Pero si el objetivo que mas nos interesa es más sobre los mecanismos y conocer el Efecto Parcial Promedio (APE),
* entonces podemos ignorar esto, y enfocarnos en reportar el APE para cada regresor.
* De hecho, es buena practica mirar los coeficientes del modelo lineal de probabilidad para luego tenerlo como referencia,
* y compararlo con las magnitudes de APE provenientes de modelos no lineales (probit, logit).



**# MCP (lineal-ponderados)

** Estimar el modelo de minimos cuadrados ponderados (MCP) para probabilidad

* Varianza condicional estimada y pesos
gen double varhat = phat*(1 - phat)

* Submuestra "válida" para el esquema MCP (evita pesos infinitos)
gen byte trim = inrange(phat, 0, 1) & varhat>0 & varhat<.
* Ponderaciones inversamente proporcionales a la varianza condicional
generate double w = 1/varhat

count if trim==1
scalar N_trim = r(N)
scalar pct_trim = 100*N_trim/_N
display pct_trim

* (1) modelo lineal: modelo auxiliar en el esquema MCPonderados
regress inlf nwifeinc educ exper expersq age kidslt6 kidsge6 if trim==1, vce(robust)
estimates store mpl_trim
predict double phat_t, xb

* (2) Implementar MCGP aproximado, si todas las phat están en (0,1)
* Estimar el modelo ponderado (MCGP). En Stata, aweights implementa pesos ~ 1/Var(u_i)
* En la segunda etapa, no necesitamos usar errores estandar robustos, ya lo son por construccion!.
regress inlf nwifeinc educ exper expersq age kidslt6 kidsge6 [aweight = w] if trim==1
estimates store mcp
predict phat_pt, xb

** El modelo MCPonderados podria ser mas eficiente que el MPL, pero siempre y cuando el verdadero proceso generador de datos se corresponda a un modelo lineal.
** Si el PGD no es lineal, entonces usar un MCP ya no es eficiente, incluso puede estar lejos de ello. 
** Un MCP se basa en un modelo lineal, y por lo tanto la varianza tiene la forma var(u/x)=xb*(1-xb) con y como Bernoulli. (Igual que en un modelo MPL).
** Pero si el verdadero modelo no es lineal (logit, probit, etc) , entonces la varianza tomara otra forma, tambien con y como Bernoulli.
** En conclusion, MCP es el mas eficiente solo bajo un modelo lineal. En contexto mas realista o donde eso no se sostenga como creible, no usaria un MCP.

** De hecho, a veces, incluso en un contexto lineal, es mejor quedarse con el MPL que el MCP. 
** El MCP solo trabaja con valores predichos entre [0,1], y si hay varias valores por fuera, usar MCP se hace con menos observaciones. Por eso esta bueno cuantificar cuantas predicciones estan fuera. 
** en tanto que MPL puede trabajar con todas las observaciones y, ademas, si el interes esta en el ATE (efecto parcial promedio), no nos importara que algunas predicciones se salgan del intervalo [0,1]

**# Tabla comparativa: MPL vs MCP


* 4) Tabla en pantalla (texto, con estrellas)
capture which esttab
if _rc ssc install estout, replace

esttab mpl_full mpl_trim mcp, ///
    label ///
    mtitles("MPL full (robust)" "MPL trim (robust)" "MCP trim (aweight)") ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Obs." "R2") fmt(0 3)) ///
    compress nogaps ///
    addnotes("SE entre paréntesis. * p<0.10, ** p<0.05, *** p<0.01", ///
             "%% p-hat fuera [0,1] (desde MPL full): " + string(pct_oob,"%6.2f") ///
				+ " | %% submuestra trim: " + string(pct_trim,"%6.2f"))


/*
Interpretación:
MPL: estimación de efecto promedio lineal. En general, se usa como referencia y para APE aproximado.
MCP ponderado: está tratando de "corregir" la heterocedasticidad del Bernoulli bajo el supuesto de modelo lineal correcto. Pero usa
 p^ estimada, y algunos de los pesos explotan en los extremos, con lo cual puede cambiar mucho la estimación para algun coeficiente,
    incluso el signo, si el modelo lineal no es el PGD o si hay puntos de alto leverage en extremos. Esto paso con la variable nwifeinc.
*/

/****************************************************************************************
INTERPRETACIÓN DE LA TABLA: MPL full vs MPL trim vs MCP (WLS) trim

1) El recorte (trim) NO es la fuente del cambio grande:
   - MPL full y MPL trim dan coeficientes muy similares.
   - Eso indica que eliminar las obs con p-hat fuera de [0,1] casi no altera el ajuste.

2) El cambio fuerte (incluyendo cambio de signo) viene de la PONDERACIÓN del MCP:
   - En el MCP usamos w_i = 1 / (p-hat_i * (1 - p-hat_i)).
   - Si p-hat está cerca de 0 o 1, entonces p-hat(1-p-hat) es muy chico y el peso w_i explota.
   - Resultado: el MCP queda dominado por un subconjunto de observaciones con pesos enormes
     (típicamente casos "casi determinísticos"), y el coeficiente puede cambiar mucho e incluso
     cambiar de signo si en esa zona de la muestra la correlación parcial es diferente.

3) Lectura práctica:
   - El MCP puede ser "eficiente" solo si el verdadero PGD es lineal y la forma de Var(u|x)
     realmente es proporcional a p(1-p). Si el PGD no es lineal (lo habitual con variable "ye" binaria),
     el MCP puede volverse muy sensible a extremos.
   - Por eso conviene diagnosticar la distribución de w (percentiles y máximos) y probar una
     versión robusta: re-estimar MCP capando pesos extremos (p.ej., al p99/p95) para ver si el
     signo/magnitud es estable.
****************************************************************************************/

**# Diagnóstico para los pesos W

*------------------------------------------
* Diagnóstico: distribución de pesos (w)
*------------------------------------------
* Resumen con percentiles (muestra trim)
summ w if trim==1, detail
* Percentiles específicos 
centile w if trim==1, centile(1 5 10 25 50 75 90 95 99)
* Ver cuán extremos son los máximos
sort w
list w phat varhat in -10/l if trim==1   
/* Efectivamente, o bien son probabilidades predichas cercanas a 1 o cercanas a 0, en ambos casos, p(1-p) se hace pequeño, por ende w=1/p(1-p) se hace muy grande. */

* proporción de pesos arriba de cierto corte p99
_pctile w if trim==1, p(99)
scalar w_p99 = r(r1)
count if trim==1 & w > w_p99
display "Obs con w > p99: " r(N)

*------------------------------------------
* MCP capando pesos al p99 (winsor simple)
*------------------------------------------
_pctile w if trim==1, p(99)
scalar cap99 = r(r1)

gen double w_cap99 = w
replace w_cap99 = cap99 if trim==1 & w > cap99

regress inlf nwifeinc educ exper expersq age kidslt6 kidsge6 [aweight=w_cap99] if trim==1
estimates store mcp_cap99

*------------------------------------------
* MCP capando pesos al p95 (mas agresivo el capado)
*------------------------------------------
_pctile w if trim==1, p(95)
scalar cap95 = r(r1)

gen double w_cap95 = w
replace w_cap95 = cap95 if trim==1 & w > cap95

regress inlf nwifeinc educ exper expersq age kidslt6 kidsge6 [aweight=w_cap95] if trim==1
estimates store mcp_cap95


**# Tabla comparativa definitiva: MPL vs MCP

* 4) Tabla en pantalla (texto, con estrellas)
capture which esttab
if _rc ssc install estout, replace

esttab mpl_full mpl_trim mcp mcp_cap99 mcp_cap95, ///
    label ///
    mtitles("MPL full (robust)" "MPL trim (robust)" "MCP trim (aweight)" "MCP wcap99" "MCP wcap95") ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Obs." "R2") fmt(0 3)) ///
    compress nogaps ///
    addnotes("SE entre paréntesis. * p<0.10, ** p<0.05, *** p<0.01", ///
             "%% p-hat fuera [0,1] (desde MPL full): " + string(pct_oob,"%6.2f") ///
				+ " | %% submuestra trim: " + string(pct_trim,"%6.2f"))
				

/* (1) Hay variables muy robustas como exper, expersq, age, kidslt6 y kidsge6. 
   (2) Hay otras variables que son sensibles al peso, como nwifeinc, educ y la constante.
   pero cuando capeamos el peso, cuanto mas lo hacemos, los valores se acercan a los del MPL. 
   Basto con capear al 9pp para volver a nwifeinc no signifativa, lo cual tiene mas sentido que un signo positivo.
   ademas educ vuelve a tomar fuerza, a valores similares a MPL, algo similar pasa con la constante.
*/




*-----------------------------------------------------------
* Modelos índice para respuesta binaria: probit y logit
*-----------------------------------------------------------

**# Probit

* 1) Estimar probit
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
estimates store probit
scalar r2_probit = e(r2_p)
                             /* Observar que se estima por el metodo de Maxima Verosimilitud. 
                             la log-verosimilud de la muestra es de -401.30 */
* 2) Probabilidades predichas P(y=1|x)
predict phat_probit, pr 

* 3) Efectos parciales para variables continuas: dydx = g(xb)*beta_j

/* Ahora, estos coeficientes son informativos solamente respecto de la direccion (signo) del efecto.
   Pero su efecto sobre la probabilidad dependera del valor de todas las covariables, a traves de g(xb) */
  
**  average partial effect (APE)
margins, dydx(nwifeinc)
margins, dydx(nwifeinc educ exper expersq age kidslt6 kidsge6)
margins, dydx(*) post
estadd scalar r2   = r2_probit
estimates store APE_probit
 

/*  Lo que estamos haciendo con la orden anterior es lo siguiente:
          Para la variable nwifeinc, que es continua, calcula para cada i, la derivada del efecto parcial: dy_i/dx_i = g(x_ib)*beta_nwifeic
		  Luego, suma a traves de todos los i, y luego los divide entre el total de individuos: es decir, hace un promedio con todos los efectos parciales individuales.
          Para variables continuas hace la derivada parcial, mientras que para binarias o categoricas, se hace la diferencia entre categorias.
		  Mas abajo veremos como interpretar casos de continuas, binarias y categorias.
	Esto se conoce como Average Partial Effect (APE).
	Estos valores son naturalmente comparables a MPL y MCP con errores estandar homocedasticos.
	Como veremos mas adelante, tambien haremos su version robusta, pero debemos tener en cuenta algo si hacemos esto ultimo. Ver mas abajo. 
*/

/* Tambien podemos pedir los efectos parciales para el "individuo promedio", al solicitar cual es el efecto para un individuo con valores medio en sus variables continuas.
   Debemos elegir una categoria concreta para el caso de las variables binarias.
   Si no elegimos nosotros mismos, pone el valor medio, aunque este valor es dificil de interpretar ya en una binaria perteneces a una categoria o a la otra, por ejemplo. */
   
** Partial Effect at Means (PEM) - Version naive: sin definir perfil en binarias o categoricas
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
margins, dydx(nwifeinc educ exper expersq age kidslt6 kidsge6) atmeans 
tab kidslt6
tab kidsge6
** una manera correcta para el Partial Effect at Means (PEM) es seleccionando un "perfil":
margins, dydx(nwifeinc educ exper expersq age kidslt6 kidsge6) atmeans at(kidslt6==0  kidsge6==0) 


**# Errores estandar de betas vs errores estandar de ATE

*************** Varianza y sd de coeficientes b |  Varianza y sd de efectos APE o PEM ************************* 

** Varianza de los coeficientes: la matriz de varianza-covarianza surge de invertir la expresion del Hessiano del problema de MV.
** Por construccion, si realmente se cree el que proceso generador de datos proviene de una distribucion normal estandar (z)
** Entonces, todos los momentos de la distribucion quedaran definidos, y por lo tanto, su varianza tambien. 
** Ello implica que la varianza estimada, que es la inversa del Hessiano del problema de la log-verosimilud, es la correcta.
** Por lo tanto, ¿que pasa si podemos la opcion robusta de la varianza? Podemos hacerlo, pero debemos tener presente lo siguiente:
** Si pedimos la version robusta, entonces estamos diciendo implicitamente que no creemos que la verdadera distribucion sea una normal estandar,
** sino que esta normal estandar es una aproximacion a una verdadera distribucion desconocida.
** Por lo tanto, podemos solicitar la opcion vce(robust), pero debemos tener presente este detalle: como se lee en el contexto binario.

** Cuando tenemos un panel, es casi seguro que existira dependencia temporal entre los individuos, ello nos lleva a pedir una matriz
** que sea robusta a la correlacion serial (vce(cluster id)). Ahi no queda de otra que interpretar a la distribucion normal estandar
** como una aproximacion a una verdadera distribucion desconocida.

** como veremos a continuacion, todo este mismo fundamento le cabe a usar logit, donde la distribucion que usa es una distribucion logistica.
** Antes, vamos a poner foco en la interpretacion de los efectos parciales.

** Varianza de los efectos parciales o APE:
** Por ultimo, observar que la varianza de los coeficientes, y por ende, sus errores estandar que surgen del hessiano del problema de MV,
** se obtienen via calculo u operaciones, pero cuando pedimos los efectos parciales, por ejemplo, o atraves de cada efecto parcial individual calculamos el APE, 
** nos devuelve un valor puntual (estimacion) junto con un desvio estandar. Ese desvio estandar no es el mismo del que surge de la matriz de varianzas y covarianzas de los coeficientes. 
** Lo que hace es aplicar el Metodo Delta: si la variable es continua, se construye un vector de gradientes. Se usa como producto externo (o sandwich), en el medio se usa la matriz de varianzas V. 
** Esto se hace para cada coeficiente asociado a una variable continua. La raiz cuadrada de la diagonal principal de esa matriz "tipo sandwich", con V en el centro y los score de los gradientes de los efectos parciales,
** es el desvio estandar de ese coeficiente. Si en un lugar de un efecto parcial, se calcula la sumatoria de todos los efectos parciales individuales, la idea no cambia: se calcula su gradiente y se aplica analogamente.
** Si la variable es discreta, se toma la diferencia (en lugar de derivar la funcion G() respecto de beta_j) en los cambios de categorias. Luego se aplica el metodo delta. 
** Hay otra alternativa al metodo delta: bootstrap. 


probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6, vce(robust)
estimates store probit_rob
scalar r2_probit_r = e(r2_p)
predict phat_probit_rob, pr 
margins, dydx(*) post
estadd scalar r2   = r2_probit_r
estimates store APE_probit_rob

*** Para el logit la interpretacion es identica al caso probit, lo mismo le cabe a las consideraciones acerca de la varianza de los coeficientes. 
*** solo que ahi la distribucion es la de una logistica.




**# Interpretación de los efectos: continua, binaria, categorica

********************************************************************************
*** PROBIT: interpretación (continua vs binaria vs categórica) 
********************************************************************************

*------------------------------------------------------------
* 0) Preparación: crear una binaria y una categórica (mroz)
*------------------------------------------------------------
* Binaria: tener al menos 1 hijo <6 (0/1)
capture drop kidslt6_bin
gen byte kidslt6_bin = (kidslt6>0) if !missing(kidslt6)
label define kidslt6b 0 "0 hijos <6" 1 ">=1 hijo <6", replace
label values kidslt6_bin kidslt6b

* Categórica: número de hijos 6+ agrupado (0,1,2,3+)
cap drop kidsge6_cat
gen byte kidsge6_cat = .
replace kidsge6_cat = 0 if kidsge6==0
replace kidsge6_cat = 1 if kidsge6==1
replace kidsge6_cat = 2 if kidsge6==2
replace kidsge6_cat = 3 if kidsge6>=3 & kidsge6<.
label define kidsge6c 0 "0 hijos 6+" 1 "1 hijo 6+" 2 "2 hijos 6+" 3 "3+ hijos 6+", replace
label values kidsge6_cat kidsge6c

* Chequeo rápido
tab kidslt6_bin
tab kidsge6_cat

*------------------------------------------------------------
* 1) Estimar probit 
*------------------------------------------------------------
probit inlf nwifeinc educ exper expersq age i.kidslt6_bin i.kidsge6_cat 

/****************************************************************************************
INTERPRETACIÓN GENERAL 
- En probit, los betas NO son efectos sobre la probabilidad.
- El efecto sobre P(inlf=1|X) depende de X a través de φ(Xb) (la densidad normal).
- Por eso interpretamos con MARGINS:

  A)   APE (Average Partial Effect):
     - "margins, dydx(x)" calcula el efecto para cada i y luego promedia.
     - Es el estándar para reportar un "efecto promedio" en probit/logit. 
     - Supongamos que tenemos una variable continua, donde podemos plantear la derivada parcial de la probabilidad de exito respecto de esa variable: dy/dxj = g(xb)*bj = APE para xj
	 - Esto ultimo, depende de todo el vector xb, ademas del coeficiente bj. Entonces podemos, para cada uno de los i de la muestra, calcular esta derivada
	 - cada i tendra su propio vector xb, con lo cual, luego podemos sumar y promediar. 
	 
  B) PEM (Partial Effect at Means):
     - "margins, dydx(x) atmeans" evalúa el efecto en el individuo "promedio".
	 - Parte de la misma derivada, pero solo la calcula una vez: dy/dxj = g(xb)*bj
	 - Es decir, en lugar de calcular el efecto para cada i, lo que hace es tomar, valores medios de cada regresor, y sustituir en g(xb), donde x esta evaluado en el promedio.
	 - luego hace dy/dxj = g(xb)*bj = PEM para xj
	 
     - Ojo: para binarias/categóricas, "atmeans" puede poner valores no enteros (poco interpretable).
     - En binarias/categorías, mejor fijar explícitamente escenarios con at().

  C) Variables discretas (binarias/categóricas):
     - No tiene sentido una derivada "infinitesimal": el efecto se interpreta como cambio discreto:
       ΔP = P(Y=1|D=1, X) - P(Y=1|D=0, X), promediado (AME) o en un punto (at()).
****************************************************************************************/

*------------------------------------------------------------
* 2) Variable CONTINUA (ej.: nwifeinc)
*------------------------------------------------------------

* 2.1 APE (promedio muestral de efectos individuales)
margins, dydx(nwifeinc)
* Interpretación: "Un aumento de 1 unidad en nwifeinc cambia, en promedio,
* la probabilidad de participar en el mercado laboral en dydx puntos porcentuales (en nivel)."
* Este es el APE para nwifeinc
* Interpretación mas natural para comparar con MPL/MCP

* 2.2 PEM (efecto en el vector de medias) — útil pero NO siempre el mejor resumen
margins, dydx(nwifeinc) atmeans
* Este es el "PEM" para nwifeinc pero ojo, hay variables que es binaria y/o categorica: seria mejor especificar una categoria para ellas.
* un ejemplo de PEM correcto:
margins, dydx(nwifeinc) atmeans at(kidslt6_bin=0 kidsge6_cat=0)
* Es el efecto de nwifeinc sobre el promedio de inlf para un individuo con valores promedio de educacion, experiencia y edad y que ademas no tiene hijos. 
* otro ejemplo de PEM correcto:
margins, dydx(nwifeinc) atmeans at(kidslt6_bin=1 kidsge6_cat=2)
* Es el efecto de nwifeinc sobre el promedio de inlf para un individuo con valores promedio de educacion, experiencia y edad y que ademas tiene al menos un hijo menor de 6 anios, y tiene 2 hijos mayores de 6 anios.

* 2.3 El efecto (en el promedio) de una continua depende del punto: evaluarlo en varios valores. Esto nos da diferentes APEs para la misma variable, pero al estilo "contrafactico". 
sum nwifeinc
margins, dydx(nwifeinc) at(nwifeinc=(0 10 20 30)) 

/****************************************************************************************
* Interpretación: "El efecto marginal (en el promedio) no es constante: cambia con nwifeinc (y con el resto de X)."
Stata hace esto 4 veces (margins, dydx(nwifeinc) at(nwifeinc=(0 10 20 30))):

- Toma toda la muestra.
- Para cada a perteneciente a {0,10,20,30}:
  - Construye un "mundo contrafactual" donde a todos los individuos les pone nwifeinc = a. (Por ejemplo, pone que todos los individuos tienen nwifeinc=0 )
  - Deja el resto de covariables tal como están en los datos para cada individuo (educ_i, age_i, kids... etc.),
    o sea: no las promedia, no las fija, no las cambia.
  - Con ese vector modificado x_i(a), calcula el efecto marginal individual:

        PE_i(a) = φ(x_i(a)'β)*β_nw.

  - Después promedia sobre i:

        APE(a) = (1/N)*Σ_i PE_i(a).

Resultado: te devuelve cuatro promedios APE(0), APE(10), APE(20), APE(30).

¿qué pasa con "las otras covariables"?
- Se usan sus valores observados, uno por uno, tal como están en tu base (para cada individuo).
- No se fijan en el promedio, salvo que se pida con atmeans o con at() para esas variables.

****************************************************************************************/

*------------------------------------------------------------
* 3) Variable BINARIA (ej.: kidslt6_bin)
*------------------------------------------------------------

* 3.1 AME discreto: promedio de [P(D=1) - P(D=0)] sobre la muestra
margins, dydx(kidslt6_bin)
* Interpretación: 
*En promedio, pasar de 0 a 1 en kidslt6_bin (tener al menos un hijo menor de 6 vs no tener) reduce la probabilidad de participar (inlf=1) en aproximadamente 0.316, es decir, 31.6 puntos porcentuales, manteniendo el resto de covariables como observadas y promediando sobre la muestra.
* Esta es el "APE" para una binaria. Es la interpretacion natural comparable con un MPL.

* 3.2 Efecto discreto en un punto concreto: es un PEM.
*     Elegimos un "perfil" 
margins, atmeans at(kidslt6_bin=(0 1) kidsge6_cat=0) predict(pr) post
lincom _b[2._at] - _b[1._at]
/* Pr(inlf =1 / x=xbar ,  kidsge6_cat=0, kidslt6_bin=0) = 0.635
   Pr(inlf =1 / x=xbar ,  kidsge6_cat=0, kidslt6_bin=0) = 0.254
   Diferencia = 0.3806
Para una mujer con covariables en sus valores medios y con 0 hijos de 6+, pasar de no tener hijos menores de 6 a tener al menos uno reduce la probabilidad predicha de participar en el mercado laboral en aproximadamente 0.381, es decir, 38.1 puntos porcentuales.    */

** podemos pedir lo mismo que lo anterior pero mas directo, pero como usamos "post" debemos volver a generar el modelo probit
probit inlf nwifeinc educ exper expersq age i.kidslt6_bin i.kidsge6_cat 
margins, dydx(kidslt6_bin) atmeans at(kidsge6_cat=0)



*------------------------------------------------------------
* 4) Variable CATEGÓRICA (ej.: kidsge6_cat con 4 niveles)
*------------------------------------------------------------

* 4.1 APE 
margins, dydx(kidsge6_cat)

/****************************************************************************************
INTERPRETACIÓN: margins, dydx(kidsge6_cat)   (APE para variable categórica)
Comando:
    margins, dydx(kidsge6_cat)

Qué está calculando Stata:
- kidsge6_cat es una variable categórica incluida como factor (i.kidsge6_cat).
- Para variables factor, "dydx()" NO es una derivada continua: es un CAMBIO DISCRETO
  respecto de la categoría base (por defecto, la base es kidsge6_cat = 0).

Qué reporta cada fila (efecto promedio, APE):
- Para cada individuo i, Stata calcula:
      ΔP_i(c) = Pr(inlf=1 | kidsge6_cat=c, X_i)  -  Pr(inlf=1 | kidsge6_cat=0, X_i),
  manteniendo el resto de covariables X_i en sus valores observados (tal como están en los datos).
- Luego promedia ese cambio sobre toda la muestra:
      APE(c) = (1/N) * Σ_i ΔP_i(c).
- Este valor es el naturalmente comparable a una interpretacion de una variable categorica en un MPL.

Cómo leer los números (en puntos de probabilidad, nivel):
- "1 hijo 6+":   APE = -0.0104
    → En promedio, pasar de 0 hijos 6+ a 1 hijo 6+ cambia la probabilidad predicha de inlf=1 en -0.010
      (≈ -1.0 puntos porcentuales), ceteris paribus (en el sentido de X_i observadas), y promediando sobre la muestra.
- "2 hijos 6+":  APE = +0.0542
    → Pasar de 0 a 2 hijos 6+ aumenta la probabilidad en ≈ 0.054 (≈ 5.4 p.p.) en promedio.
- "3+ hijos 6+": APE = +0.0439
    → Pasar de 0 a 3+ hijos 6+ aumenta la probabilidad en ≈ 0.044 (≈ 4.4 p.p.) en promedio.

Significancia:
- En esta salida, ninguno de estos cambios discretos es estadísticamente significativo
  (p-values 0.814, 0.247 y 0.366). Por lo tanto, no hay evidencia fuerte de que, en promedio,
  la probabilidad de participación difiera entre 0 hijos 6+ y las categorías 1, 2 o 3+,
  una vez controladas las demás covariables del modelo probit.

Nota importante (base level):
- La nota de Stata ("discrete change from the base level") significa exactamente esto:
  cada efecto está medido RELATIVO A LA CATEGORÍA BASE kidsge6_cat=0.
****************************************************************************************/


* 4.2 "Pasar de una categoría a otra" (comparaciones entre categorías): basicamente tambien esto es ATE
* Opción A (si tu Stata lo soporta): pairwise comparisons automáticos
margins kidsge6_cat, pwcompare(effects)

* Opción B (universal): calculo márgenes y luego diferencias con lincom
margins, at(kidsge6_cat=(0 1 2 3)) post
* Efecto de pasar 0 -> 1:
lincom _b[2._at] - _b[1._at]
* Efecto de pasar 1 -> 2:
lincom _b[3._at] - _b[2._at]
* Efecto de pasar 2 -> 3+:
lincom _b[4._at] - _b[3._at]
* Efecto de pasar 0 -> 3+ (salto grande):
lincom _b[4._at] - _b[1._at]

* Nota: para comparaciones "categoría c vs base", margins, dydx(kidsge6_cat) y
* margins kidsge6_cat, pwcompare(effects) dan el mismo número:
* promedio[P(c)-P(base)] = promedio[P(c)] - promedio[P(base)].
* La ventaja de pwcompare es que permite comparar también categorías no-base (ej. 2 vs 1).

* 4.3 Ahora calculemos algun PEM: variables continuas en el promedio y kidslt6_bin==0.
probit inlf nwifeinc educ exper expersq age i.kidslt6_bin i.kidsge6_cat 
margins kidsge6_cat, atmeans at(kidslt6_bin==0) pwcompare(effects) 

/* Es decir, nos da el efecto de pasar de una categoria a otra categoria de kidsge6_cat pero
   para un individuo que tiene sus valores en el promedio (variables continuas) y que no tiene hijos menores de 6 anios. 
   Por ello es un PEM. */
   
 * PEM: comparar categorías, fijando otras categóricas en valores concretos
margins, atmeans at(kidslt6_bin=0) at(kidsge6_cat=(0 1 2 3)) post
lincom _b[2._at] - _b[1._at]   // 1 vs 0 en el individuo promedio (y kidslt6_bin=0)
  
   
********************************************************************************
* Fin bloque interpretación Probit
********************************************************************************



*********************************************************************************
**# Logit
*********************************************************************************

 
logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
estimates store logit
scalar r2_logit = e(r2_p)
predict phat_logit, pr
  
**  average partial effect (APE)
margins, dydx(nwifeinc)
margins, dydx(nwifeinc educ exper expersq age kidslt6 kidsge6)
margins, dydx(*) post
estadd scalar r2   = r2_logit
estimates store APE_logit
 
** Partial Effect at Means (PEM) - Version naive: sin definir perfil en binarias o categoricas
logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
margins, dydx(nwifeinc educ exper expersq age kidslt6 kidsge6) atmeans 
tab kidslt6
tab kidsge6
** una manera correcta para el Partial Effect at Means (PEM) es seleccionando un "perfil":
margins, dydx(nwifeinc educ exper expersq age kidslt6 kidsge6) atmeans at(kidslt6==0  kidsge6==0) 


** varianza robusta (logistica como aproximacion a una verdadera distribucion desconocida)
logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6, vce(robust)
estimates store logit_rob
scalar r2_logit_r = e(r2_p)
predict phat_logit_rob, pr
margins, dydx(*) post
estadd scalar r2   = r2_logit_r
estimates store APE_logit_rob


**# Tabla comparativa: MPL vs Probit (APE) vs Logit (APE)

** tabla comparativa
esttab mpl_full mcp APE_probit APE_probit_rob APE_logit APE_logit_rob, ///
    label ///
    mtitles("MPL (robust)" "MCP (aweight)" "APE Probit" "APE Probit_robust" "APE Logit" "APE Logit_robust") ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, labels("Obs." "R2 (Pseudo-R2)") fmt(0 3)) ///
    compress nogaps 

** salvo el MCPonderados, el resto son similares.
** es decir, el Efecto Parcial Promedio (APE) tanto del probit como del logit son similares al efecto de MPL.
** Este es un modelo donde se asume que todas son exogenas, por lo que no hay tratamiento por endogeneidad para alguna variable particular
** Tampoco tenemos datos de panel, y por ende no se trata la posible heterogeneidad inobservable a nivel individual.





********************************************************************************
******    Medidas de diagnostico                                  **************
********************************************************************************

*==============================================================*
* PROBIT: Medidas de ajuste / capacidad predictiva (Sección 15.6)
*==============================================================*

*-------------------------------*
* Probit 
*-------------------------------*
drop phat
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
predict double phat, pr

**# Porcentaje Correctamente Predicho (PCP)

*-------------------------------*
*  PCP con umbral t = 0.5
*-------------------------------*
gen byte yhat_05 = (phat >= 0.5)   // crea variable que vale 1 si ^p>=0.5
tab yhat_05

* PCP global
gen byte ok_05 = (yhat_05 == inlf)   // crea variable que vale 1 si yhat_05=inlf, por ejemplo, si yhat_05=inlf=1 o si yhat_05=inlf=0
summ ok_05, meanonly
scalar PCP_05 = 100*r(mean)
tab ok_05

* PCP condicional en y=0 o y=1
summ ok_05 if inlf==0, meanonly
scalar PCP0_05 = 100*r(mean)
tab ok_05 if inlf==0

summ ok_05 if inlf==1, meanonly
scalar PCP1_05 = 100*r(mean)
tab ok_05 if inlf==1

display "PCP (t=0.5) global = " %6.2f PCP_05
display "PCP (t=0.5) | y=0  = " %6.2f PCP0_05
display "PCP (t=0.5) | y=1  = " %6.2f PCP1_05


**# Pseudo-R2

*--------------------------------------------*
*  Pseudo-R2 de McFadden: 1 - LL_ur/LL_0
*--------------------------------------------*
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
scalar LL_ur = e(ll)

* Estimar modelo con solo intercepto (nula)
quietly probit inlf
scalar LL_0 = e(ll)

scalar R2_McF = 1 - (LL_ur/LL_0)

display "LL_ur (modelo completo) = " %10.4f LL_ur
display "LL_0  (solo constante)  = " %10.4f LL_0
display "Pseudo-R2 McFadden      = " %8.4f R2_McF


*--------------------------------------------------------------*
*  R2_SSR: 1 - SSR_ur / SSR_0  con uhat = y - phat
*--------------------------------------------------------------*
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6

* SSR_ur = sum (y - phat)^2
gen double uhat = inlf - phat
gen double uhat2 = uhat^2
summ uhat2, meanonly
scalar SSR_ur = r(sum)

* SSR_0 = "suma total de cuadrados de y"
* (para y binaria: sum (y - ybar)^2)
summ inlf, meanonly
scalar ybar = r(mean)

gen double ydev2 = (inlf - ybar)^2
summ ydev2, meanonly
scalar SSR_0 = r(sum)

scalar R2_SSR = 1 - (SSR_ur/SSR_0)

display "SSR_ur = " %10.4f SSR_ur
display "SSR_0  = " %10.4f SSR_0
display "R2_SSR = " %8.4f R2_SSR














********************************************************************************
****                     Pruebas de hipotesis                                ***
********************************************************************************



/* A continuacion vamos a ver diferentes pruebas para los modelos 
   de respuesta binaria. Son validas tanto para Probit como para Logit.
   Vamos a replicarlas para el Logit en este caso.
*/

**# Pruebas de hipotesis sobre los coeficientes (Wald, LR, LM)



** Wald (estimando el modelo no restringido)
** Vamos a suponer que queremos constrastar que kidslt6b y kidsge6 no forman parte de la ecuacion estructural para linf
** x = nwifeinc educ exper expersq age
** z = kidslt6 kidsge6
** H0) gamma=0  
** Q=2

logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
test kidslt6 kidsge6

logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6, vce(robust)
test kidslt6 kidsge6

/*Ese test te da el Wald χQ2 para H0: ambos coeficientes = 0.
*/

**   Tambien podriamos poner a prueba una categorica, cada una de sus dummies
** Usemos las variables creadas anteriormente 
logit inlf nwifeinc educ exper expersq age kidslt6_bin kidsge6_cat
test kidsge6_cat

logit inlf nwifeinc educ exper expersq age kidslt6_bin kidsge6_cat
test kidslt6_bin kidsge6_cat

**   Tambien podriamos poner a prueba formas funcionales
logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
test expersq


** LR (comparando no restringido vs restringido)

** Importante: para que lrtest sea válido y Stata lo permita, estimar ambos con MV estándar, sin opcion robusta para la varianza.
** volvamos al caso donde ponemos a prueba a kidslt6 kidsge6

logit inlf nwifeinc educ exper expersq age
estimates store R

logit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
estimates store UR

lrtest UR R

/* Esto computa LR=2(Lur−Lr) ∼ χQ2  Q=2 */


** LM   (Score vía regresión auxiliar (15.22))
** Acá solo estimás el modelo restringido (sin kidslt6 kidsge6) y después armás la auxiliar.

* a) estimo modelo restringido y construyo u, G, g estimados.
logit inlf nwifeinc educ exper expersq age

predict double phat_lm, pr                       // valores predichos = G(x'^b) = ^p
drop uhat
gen double uhat   = inlf - phat_lm               // residuos ^u
gen double denom  = sqrt(phat_lm*(1 - phat_lm))   // denominador para los residuos

gen double s = uhat/denom                      // para simplificar, sera la variable dependiente transformada

** Punto importante: ahora debemos calcular la funcion g(xb), que es la densidad de la funcion acumulada G(xb)
** En el caso logit, la funcion G debe derivarse y asi obtenemos la funcion de densidad estandar logistica.
** Podemos optar por hacer esto explicitamente y evaluarlo en x'^b, donde ^b son los coeficientes estimados de la regresion anterior, restringida.
** Pero cuando tenemos la funcion logistica uno puede demostrar un resultado que simplifica las cuentas muchisimo:

/* -------------------------------------------------------------------------
LM en logit

En la teoría, g(·) se define como la derivada de G(·) respecto del índice:
    G(x'b) = P(y=1 | x)    
    g(x'b) = dG(x'b)/dx'b

En LOGIT, G es la CDF logística:
    G(x'b) = Λ(x'b) = exp(x'b) / (1 + exp(x'b))

Su derivada (la "densidad logística" evaluada en x'b) es:
    g(x'b) = Λ'(x'b) = exp(x'b) / (1 + exp(x'b))^2

Pero existe la identidad:
    Λ'(x'b) = Λ(x'b) * [1 - Λ(x'b)]

Demostración rápida:
    Λ(η)[1-Λ(η)] = [exp(η)/(1+exp(η))] * [1 - exp(η)/(1+exp(η))] = 
	               [exp(η)/(1+exp(η))] * [1/(1+exp(η))] =
                  = exp(η)/(1+exp(η))^2
    Λ(η)[1-Λ(η)]  = Λ'(η)

Esto NO "reemplaza" la densidad por otra cosa: es exactamente la misma
densidad logística, solo expresada en función de la probabilidad estimada.
Por eso el LM en logit queda especialmente simple de implementar.
------------------------------------------------------------------------- */

** entonces:
gen double ghat = phat_lm*(1 - phat_lm)        // g = G(1-G) (solo valido en logit)
gen double w_lm = ghat/denom                 // denominador para las variables x y z

* b)  Armar regresores ponderados y correr la auxiliar sin constante

* Incluyo el "intercepto" de la auxiliar como wcons = w (porque el intercepto en x se vuelve una columna que varía con wi): 

gen double wcons = w_lm

gen double w_nwifeinc = w_lm*nwifeinc
gen double w_educ     = w_lm*educ
gen double w_exper    = w_lm*exper
gen double w_expersq  = w_lm*expersq
gen double w_age      = w_lm*age

gen double w_kidslt6  = w_lm*kidslt6
gen double w_kidsge6  = w_lm*kidsge6

regress s wcons w_nwifeinc w_educ w_exper w_expersq w_age w_kidslt6 w_kidsge6, nocons 

* c) LM = ESS (y variante NR2 no centrado)

scalar LM_ESS  = e(mss)
scalar LM_NR2  = e(N)*e(r2)

display "LM (ESS)  = " LM_ESS
display "LM (N*R2) = " LM_NR2

display "p-value (df=2) usando ESS:  " chi2tail(2, LM_ESS)
display "p-value (df=2) usando N*R2: " chi2tail(2, LM_NR2)



*----------------------- LM: alternativa: pedir explicitamente la densidad g(xb) del logit ---------------------------------------

/* ------------------------------------------------------------
LM (alternativa explícita): ghat como densidad logística en xb
Bajo H0 (modelo restringido): logit con x solamente.
Luego:
  Ghat_i = phat_i = Λ(xb_i)
  Su derivada (la "densidad logística" evaluada en x'b) es:
    g(x'b) = Λ'(x'b) = exp(x'b) / (1 + exp(x'b))^2
------------------------------------------------------------ */
drop uhat phat_lm denom s ghat w_lm wcons w_nwifeinc w_exper w_expersq w_kidslt6 w_kidsge6 w_age w_educ

* 1) Modelo restringido (H0: excluís el bloque z)
logit inlf nwifeinc educ exper expersq age
* 2) Predicciones bajo H0
predict double phat_lm, pr      // Ghat_i = Λ(xb_i)
predict double xb, xb        // xb_i = x_i' b_hat  (índice bajo H0)

* 3) Residuo y estandarización
gen double uhat  = inlf - phat_lm
gen double denom = sqrt(phat_lm*(1 - phat_lm))
gen double s     = uhat/denom                 // residuos estandarizados (transformados)

* 4) ghat explícito: densidad logística evaluada en xb
gen double exb   = exp(xb)
gen double ghat  = exb/((1 + exb)^2)


* 5) Peso de regresores auxiliares: ghat / sqrt(Ghat*(1-Ghat))
gen double w_lm = ghat/denom

* 6) Construir regresores ponderados (incluye intercepto como wcons = w)
gen double wcons = w_lm

gen double w_nwifeinc = w_lm*nwifeinc
gen double w_educ     = w_lm*educ
gen double w_exper    = w_lm*exper
gen double w_expersq  = w_lm*expersq
gen double w_age      = w_lm*age

* Bloque z (restricciones H0: coeficientes=0)
gen double w_kidslt6  = w_lm*kidslt6
gen double w_kidsge6  = w_lm*kidsge6

* 7) Regresión auxiliar LM (sin constante)
regress s wcons w_nwifeinc w_educ w_exper w_expersq w_age w_kidslt6 w_kidsge6, nocons

* 8) Estadístico LM: ESS (y variante NR2)
scalar LM_ESS = e(mss)
scalar LM_NR2 = e(N)*e(r2)

display "LM (ESS)  = " LM_ESS
display "LM (N*R2) = " LM_NR2

* p-values (Q = #restricciones = 2)
display "p-value (df=2) usando ESS:  " chi2tail(2, LM_ESS)
display "p-value (df=2) usando N*R2: " chi2tail(2, LM_NR2)


** Take Aeway: 
/*           Wald: más cómodo si el modelo "no restringido" se estima fácil. Permite estimarse bajo varianza robusta.
             LR: muy estándar, pero exige estimar ambos y no usar robust/cluster. (El menos ventajoso de los tres)
			 LM: útil si el modelo "no restringido" es pesado (muchos z), porque estimás solo bajo H0 (solo para x). Ventaja computacional.
			 LM: si usas logit se puede pedir tanto la densidad explicitamente evaluada en x^b, como tambien usar el resultado discutido.
			     si usas probit debemos pedir la densidad explicitamente, pero la densidad en ese caso es la de la normal estandar, tambien evaluada en x^b
*/


********************************************************************************
******               LM para heterocedasticidad                          *******
********************************************************************************


**# Prueba LM para la heterocedasticidad en variable latente: caso probit

/* El modelo probit  parten de un modelo de variable latente, donde e es el error para dicho modelo latente.
   Este error, e, se asume que sigue una distribucion condicial en X como N(0,1), es decir, una normal estandar.
   En particular, la varianza es unitaria, y no depende de X. 
   ¿Que pasa si la verdadera distribucion es tal que e tiene una distribucion normal que ya no es la estandar, y, por sobre todo, 
   depende de X? Esto es heterocedasticidad.
*/

drop uhat denom s exb ghat w_lm wcons w_nwifeinc w_educ w_exper w_expersq  w_age w_kidslt6 w_kidsge6 phat_lm xb
** Uso como nula el probit estándar: 
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
** definir x1 (las variables que "mueven" la varianza) como el subconjunto sin constante. 
** por ejemplo, x1 = todas las regresoras excepto la constante.

** A) LM explícito (eq. 15.28): ESS de la regresión auxiliar


*-------------------------------*
* 0) Nula: probit homocedástico
*-------------------------------*
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6

* Índice bajo H0: xb = x^b
predict double xb, xb

* Probabilidad bajo H0: Fhat = Φ(xb)
predict double Fhat, pr

* Densidad normal: fhat = φ(xb)
gen double fhat = normalden(xb)

* Residuo tipo Bernoulli: uhat = y - Fhat
gen double uhat = inlf - Fhat

* Estandarización: denom = sqrt(Fhat*(1-Fhat))
gen double denom = sqrt(Fhat*(1 - Fhat))

* LHS auxiliar: s = uhat / denom
gen double s = uhat/denom


*----------------------------------------------*
* 1) Bloque β: (fhat/denom) * x   (incluye 1)
*----------------------------------------------*
gen double wB0 = fhat/denom          // corresponde al intercepto ponderado

gen double wB_nwifeinc = wB0*nwifeinc
gen double wB_educ     = wB0*educ
gen double wB_exper    = wB0*exper
gen double wB_expersq  = wB0*expersq
gen double wB_age      = wB0*age
gen double wB_kidslt6  = wB0*kidslt6
gen double wB_kidsge6  = wB0*kidsge6

*------------------------------------------------------*
* 2) Bloque δ: (xb*fhat/denom) * x1   (x1 sin constante) 
* este es el termino nuevo que aparece ahora, que es el gradiente de m() respecto de delta para el caso probit.
* notar que fhat es la densidad normal estandar evaluada x^b. 
* necesitamos ademas el indice, y luego ponderar por el peso.
* si aplicamos lo anterior a cada variable ya luego podremos correr la regresion.

*------------------------------------------------------*
gen double wD0 = xb*fhat/denom

*  ELECCIÓN DE x1 (K1 variables, sin constante) 
gen double wD_nwifeinc = wD0*nwifeinc
gen double wD_educ     = wD0*educ
gen double wD_exper    = wD0*exper
gen double wD_expersq  = wD0*expersq
gen double wD_age      = wD0*age
gen double wD_kidslt6  = wD0*kidslt6
gen double wD_kidsge6  = wD0*kidsge6

*--------------------------------------------------*
* 3) Regresión auxiliar (15.28): como constante uso wB0
*--------------------------------------------------*
regress s  wB0 wB_nwifeinc wB_educ wB_exper wB_expersq wB_age wB_kidslt6 wB_kidsge6 ///
    wD_nwifeinc wD_educ wD_exper wD_expersq wD_age wD_kidslt6 wD_kidsge6, nocons

* LM = ESS (y variante N*R2 no centrado)
scalar LM_ESS = e(mss)
scalar LM_NR2 = e(N)*e(r2)

display "LM (ESS)  = " LM_ESS
display "LM (N*R2) = " LM_NR2

* Grados de libertad = K1 (dimensión de x1)
* En la opción amplia de arriba: K1 = 7
display "p-value (df=7) usando ESS:  " chi2tail(7, LM_ESS)
display "p-value (df=7) usando N*R2: " chi2tail(7, LM_NR2)

 
	
** B) Variante LM con 1 g.l. (regresor basado en (x^b)^2)

* Regresor único (1 df)
gen double wD1 = (xb^2)*fhat/denom

regress s ///
    wB0 wB_nwifeinc wB_educ wB_exper wB_expersq wB_age wB_kidslt6 wB_kidsge6 ///
    wD1, nocons

scalar LM1_ESS = e(mss)
scalar LM1_NR2 = e(N)*e(r2)

display "LM 1df (ESS)  = " LM1_ESS
display "LM 1df (N*R2) = " LM1_NR2

display "p-value (df=1) ESS:  " chi2tail(1, LM1_ESS)
display "p-value (df=1) NR2:  " chi2tail(1, LM1_NR2)

**# Prueba VAT

**C) VAT (Variable Addition Test): alternativa práctica al score test
**La idea: crear variables (xb)x1 (usando el xb del probit nulo) y correr un probit auxiliar, luego testear ese bloque con un Wald.

* xb ya lo tenés del probit nulo

gen double add_nwifeinc = xb*nwifeinc
gen double add_educ     = xb*educ
gen double add_exper    = xb*exper
gen double add_expersq  = xb*expersq
gen double add_age      = xb*age
gen double add_kidslt6  = xb*kidslt6
gen double add_kidsge6  = xb*kidsge6

probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 ///
    add_nwifeinc add_educ add_exper add_expersq add_age add_kidslt6 add_kidsge6

test add_nwifeinc add_educ add_exper add_expersq add_age add_kidslt6 add_kidsge6

* VAT con 1 g.l. (usando xb2)

gen double add1 = xb^2

probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6 add1
test add1



********************************************************************************
******    Metodo delta y bootstrap para APE                       **************
********************************************************************************
 
*==============================================================*
* PROBIT + Efectos parciales (APE) + EE delta y bootstrap
* Ejemplo base: inlf nwifeinc educ exper expersq age kidslt6 kidsge6
*==============================================================*


*-------------------------------*
* 0) Estimar probit (H0 estándar)
*-------------------------------*
probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
*drop xb 

**# Error estandar de ATE: Metodo delta


* APE y EE delta "oficial" (Stata)
margins, dydx(age)
* 0023587 

* Preparar insumos para Mata
tempvar touse
gen byte `touse' = e(sample)

matrix b = e(b)
matrix V = e(V)

local xvars "nwifeinc educ exper expersq age kidslt6 kidsge6"
local k_age = colnumb(b,"age")

mata:
    // 1) traer b y V
    b = st_matrix("b")'              // p x 1
    V = st_matrix("V")               // p x p

    // 2) traer X (sin constante) en el mismo orden que xvars
    X = st_data(., tokens(st_local("xvars")), st_local("touse"))
    N = rows(X)

    // 3) agregar constante al final (porque _cons está al final en e(b))
    X = X, J(N,1,1)

    // 4) objetos del APE continuo: APE = b_k * mean(phi(xb))
    xb  = X*b
    phi = normalden(xb)
    a   = mean(phi)

    // 5) derivada de phi: phi'(t) = -t*phi(t)
    phip = -xb :* phi

    // 6) da/db = mean_i[ phi'(xb_i) * x_i ]
    da = (X' * phip) / N

    // 7) gradiente total: grad = a*e_k + b_k*da
    k  = strtoreal(st_local("k_age"))
    bk = b[k]

    grad = bk*da
    grad[k] = grad[k] + a

    ape = bk*a
    se  = sqrt( grad' * V * grad )

    st_numscalar("APE_age_man", ape)
    st_numscalar("SE_age_man",  se)
end

display "APE(age) manual (punto) = " %10.7f scalar(APE_age_man)
display "SE delta manual         = " %10.7f scalar(SE_age_man)



* ---------- DELTA MANUAL (APE discreta) ----------


probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
estimates store PROBIT0

* APE discreta y EE delta "oficial" (para comparar)
margins, at(kidslt6=(0 1)) post
lincom _b[2._at] - _b[1._at]

* Volver al probit (porque margins, post pisó e(b), e(V))
estimates restore PROBIT0

* ---------- DELTA MANUAL (APE discreta 0->1) ----------
tempvar touse
gen byte `touse' = e(sample)

matrix b = e(b)
matrix V = e(V)

local xvars "nwifeinc educ exper expersq age kidslt6 kidsge6"
local k = colnumb(b,"kidslt6")

mata:
    b = st_matrix("b")'
    V = st_matrix("V")

    X = st_data(., tokens(st_local("xvars")), st_local("touse"))
    N = rows(X)

    // agregar constante al final (_cons está al final en e(b))
    X = X, J(N,1,1)

    k  = strtoreal(st_local("k"))
    xk = X[,k]
    bk = b[k]

    xb  = X*b
    xb1 = xb + bk*(1 :- xk)     // forzar kidslt6=1 para todos
    xb0 = xb - bk*(xk)          // forzar kidslt6=0 para todos

    p1  = normal(xb1)
    p0  = normal(xb0)
    ape = mean(p1 - p0)

    // gradiente: mean[ phi(xb1)*d(xb1)/db  - phi(xb0)*d(xb0)/db ]
    phi1 = normalden(xb1)
    phi0 = normalden(xb0)

    D1 = X
    D0 = X
    D1[,k] = J(N,1,1)           // en el escenario kidslt6=1
    D0[,k] = J(N,1,0)           // en el escenario kidslt6=0

    grad = (D1' * phi1 - D0' * phi0) / N
    se   = sqrt( grad' * V * grad )

    st_numscalar("APE_kidslt6_man", ape)
    st_numscalar("SE_kidslt6_man",  se)
end

display "APE kidslt6 0->1 manual (punto) = " %10.7f scalar(APE_kidslt6_man)
display "SE  delta manual                = " %10.7f scalar(SE_kidslt6_man)


**# Error estandar de ATE: bootstrap


**************** bootstrap ****************

* ejemplo continua age
capture program drop ape_age
program define ape_age, rclass
    probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
    margins, dydx(age)
    matrix bb = r(b)
    return scalar ape = bb[1,1]
end
bootstrap r(ape), reps(400) seed(12345): ape_age

** en panel agregar "cluster(id)" como opcion en el bootstrap.

* ejemplo discreta kidslt6
capture program drop ape_kidslt6
program define ape_kidslt6, rclass
    probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6
    margins, at(kidslt6=(0 1))
    matrix bb = r(b)
    return scalar ape = bb[1,2] - bb[1,1]
end
bootstrap r(ape), reps(400) seed(12345): ape_kidslt6

** en panel agregar "cluster(id)" como opcion en el bootstrap.


********************************************************************************
******  Bootstrap APE: continuas (dydx) + dummies (0->1) en una sola corrida  ***
********************************************************************************

capture program drop ape_all
program define ape_all, rclass
    probit inlf nwifeinc educ exper expersq age kidslt6 kidsge6

    * --- Definí acá qué tratás como continua vs dummy ---
    local contvars "nwifeinc educ exper expersq age"
    local discvars "kidslt6 kidsge6"

    *-------------------------------*
    * A) APE CONTINUAS: dydx (AME/APE)
    *-------------------------------*
    margins, dydx(`contvars')
    matrix bb = r(b)

    foreach v of local contvars {
        return scalar ape_`v' = bb[1,"`v'"]
    }

    *----------------------------------------*
    * B) APE DUMMIES: cambio discreto 0 -> 1
    *----------------------------------------*
    foreach d of local discvars {
        margins, at(`d'=(0 1))
        matrix bd = r(b)
        return scalar ape_`d'_01 = bd[1,2] - bd[1,1]
    }
end

bootstrap ///
    r(ape_nwifeinc) r(ape_educ) r(ape_exper) r(ape_expersq) r(ape_age) ///
    r(ape_kidslt6_01) r(ape_kidsge6_01), ///
    reps(400) seed(12345): ape_all

** comparar estos errores estandar para APE por bootstrap vs los del metodo delta.
** los coeficientes deben ser identicos en ambos metodos.


** en panel agregar "cluster(id)" como opcion en el bootstrap.

  
 