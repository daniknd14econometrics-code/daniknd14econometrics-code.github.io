*** Capitulo 16 ***

clear all
bcuse keane, clear 
describe

* Declarar la estructura de panel y ordenar observaciones
xtset id year
sort id year

**# MNL: choice

*=======================================================================*
* 1) Logit multinomial (MNL) con variables específicas del individuo
*=======================================================================*

/* MNL: es un modelo LOGIT multinomial. Por lo tanto, la distribucion de los errores provienen de la distribucion logistica estandar.
		ver detalles en el libro/manuscrito en espaniol elaborado por mi.
		en este modelo, las covariables son identicas para cada alternativa (eleccion), pero se permite que los coeficientes sean distintos en cada alternativa.
*/


* Inspeccionar la variable dependiente y verificar que sea categorica NO ordenada
tabulate choice

** sch=1, 
** home=2,
** wc=3, 
** bc=4,	
** serv=5

** Como vemos, las 5 opciones son: escuela, casa, white collar , blue collar , services 

mdesc lwage wage educ exper expersq manuf black y81 y82	y83	y84	y85	y86	y87 choice status

misstable summarize wage lwage educ exper expersq manuf black y81 y82 y83 y84 y85 y86 y87 choice status

** observar que no se puede usar wage (o lwage) como covariable puesto que el salario solo esta presente para la alternativa work
** dicho de otra manera, no hay salario en las alternativas "scholar" o "home". Por lo que si pones wage, se pierden todas las observaciones de las categorias scholar, home, etc
** y directamente se cae la posibilidad de estimar por un modelo de multiples opciones.


*======== 
* choice
*========

** probamos para "choice" como dependiente, dejando la categoria escuela como referencia:
mlogit choice educ exper expersq i.black y82-y87, baseoutcome(1) vce(cluster id)

// mlogit estima por MLE el modelo logit multinomial
// baseoutcome(1) fija la categoría "scholar" como 1 (normalización)
// vce(cluster id) pide errores robustos (útil ante heterocedasticidad + correlacion serial)
// deje un anio fuera (1981)
// ponemos i.black para que la interprete como binaria/categorica
// ojo: si incluimos muchas dummies, puede que tengamos problemas numericos en la estimacion.
// en este caso, si bien tenemos un panel, omitimos completamente la posible heterogeneidad inobservable


**# **# APEs

* APE: Efectos marginales promedios:
margins, dydx(educ exper expersq black)

** los APE suele ser lo que  mas interesa cuando el objetivo es aprender sobre las relaciones entre variables, estructurales, o efectos causales en ultima instancia.

* PEM: efecto marginal evaluado en el promedio (variables continuas) y en determinado perfil de variables discretas (afrodesciente en el anio 82)
margins, dydx(educ exper expersq black) at(black==1 y82==1 y83==0 y84==0 y85==0 y86==0 y87==0) atmeans


**# **# PCP

* Predicción por máxima probabilidad:
predict phat1 phat2 phat3 phat4 phat5, pr

/* 1) ¿Qué calcula predict phat1 ... phat5, pr?

Después de mlogit, Stata estima, para cada observación i y cada alternativa j (1,2,3,4,5), la probabilidad predicha

Pr(choice_{i}=j | x_{i})= exp(x_{i}′b_{j})/ (∑k=1,...,5 exp⁡(x_{i}′b_{k}).

Para la base (outcome 1), Stata normaliza b_{1}=0. Eso no significa que P_{i1}=0, sino que la utilidad sistemática de la base se fija a cero como referencia.
Con "predict ..., pr" Stata te devuelve esas probabilidades.

Entonces:

phat1 = P_{i1} = probabilidad predicha de escuela (1)
phat2 = P_{i2} = prob predicha de casa (2)
phat3 = P_{i3} = prob predicha de white collar (3)
phat4 = P_{i4} = prob predicha de blue collar (4)
phat5 = P_{i5} = prob predicha de services (5)

Chequeo simple (debería dar ~1 salvo redondeo):*/

gen psum = phat1+phat2+phat3+phat4+phat5
summ psum

** o sea: son probabilidades predichas por alternativa, tal como queríamos.

* Categoría predicha = argmax
gen yhat = 1
replace yhat = 2 if phat2>phat1 & phat2>=phat3 & phat2>=phat4 & phat2>=phat5
replace yhat = 3 if phat3>phat1 & phat3>phat2  & phat3>=phat4 & phat3>=phat5
replace yhat = 4 if phat4>phat1 & phat4>phat2  & phat4>phat3  & phat4>=phat5
replace yhat = 5 if phat5>phat1 & phat5>phat2  & phat5>phat3  & phat5>phat4

gen correct = (choice==yhat) if !missing(choice)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"

** da 53.83%.
** Interpretación: el clasificador "argmax" acierta un poco más de la mitad de las veces. (Parece un rendimiento algo regular si tengo en cuenta que al azar seria 1/5=0.20, un 20%. Mejora el azar pero bueno.)
**  Ojo con algo importante: este 53.8% es in-sample (en la misma muestra con la que estimaste). No es out-of-sample. Si tuvieramos en un enfoque de prediccion de Machine Learning, es posible que el resultado 
** de acierto de PCP sea bastante peor fuera de la muestra. Por eso para multiples categorias, en ML se usan otras tecnicas.

* Matriz de clasificación (real vs predicho)
tab choice yhat, row

/* Tu matriz es la pieza clave. La diagonal (aciertos por categoría real) es:

choice=1 (school): 70.89% correcto (1753/2473)
choice=2 (home): 52.77% correcto (1706/3233)
choice=3 (wc): 30.46% correcto (637/2091)
choice=4 (bc): 69.63% correcto (2721/3908)
choice=5 (serv): 0% correcto

Lectura rápida:
Predice bien "escuela" y "blue collar".
Predice regular "home".
Predice muy mal "white collar".
Y acá viene lo más interesante:
no esta prediciendo "services" correctamente nunca, porque de los 960 casos donde el individuo elige "services", en ningun caso el modelo predice que elegira "services".

4) ¿Por qué nunca predijo yhat=5 (services)?

Esto ya es una señal fuerte del modelo + covariables:
En tu replace yhat = 5 ... te dio 0 real changes.
O sea: para ninguna observación se cumple que phat5 sea la más alta.

Eso significa:

∀𝑖:𝑝^𝑖5<max⁡{𝑝^𝑖1,𝑝^𝑖2,𝑝^𝑖3,𝑝^𝑖4}.

¿Cómo puede ser si la categoría 5 existe y no es mínima (7.57%)?

Porque con tus regresores (educ exper expersq black y82-y87), el modelo está encontrando que "services" no se separa como "modo dominante" para nadie.
 En cambio, cuando el individuo está cerca de "services", el modelo probablemente lo ve todavía más probable como:
"blue collar" (4), o
"home" (2), dependiendo del perfil.

Tu tabla lo confirma: los servicios reales (choice=5) se clasifican sobre todo como 4 (52.6%) o 2 (26.0%). Es decir, el modelo "absorbe" services dentro de esas dos.

 Traducción económica: con solo educ/exper/black/año, "services" no tiene un perfil distintivo suficiente para ganar el argmax frente a "bc" o "home". 
Seguramente necesitarías variables más específicas (por ejemplo, algo de industria/ocupación, o historia laboral más detallada).


*/


**# MNL: status

*======== 
* status
*========
tabulate status

** sch=1, 
** home=2,
** work=5

** Como vemos, las 3 opciones son: escuela, casa, trabajo

mdesc lwage wage educ exper expersq manuf black y81 y82	y83	y84	y85	y86	y87 status
misstable summarize wage lwage educ exper expersq manuf black y81 y82 y83 y84 y85 y86 y87 status

*mlogit status educ exper expersq i.black i.manuf y82-y87, baseoutcome(1) vce(cluster id)
mlogit status educ exper expersq i.black y82-y87, baseoutcome(1) vce(cluster id)

// mlogit estima por MLE el modelo logit multinomial
// baseoutcome(1) fija la categoría "scholar" como 1 (normalización)
// vce(cluster id) pide errores robustos (útil ante heterocedasticidad + correlacion serial)
// deje un anio fuera (1981)
// ponemos i.black para que la interprete como binaria/categorica
// ojo: si incluimos muchas dummies, puede que tengamos problemas numericos en la estimacion.
// en este caso, si bien tenemos un panel, omitimos completamente la posible heterogeneidad inobservable


**# **#  APEs

* APE: Efectos marginales promedios:
margins, dydx(educ exper expersq black)
** los APEs suele ser lo que  mas interesa cuando el objetivo es aprender sobre las relaciones entre variables, estructurales, o efectos causales en ultima instancia.

* PEM: efecto marginal evaluado en el promedio (variables continuas) y en determinado perfil de variables discretas (afrodesciente en el anio 82)
margins, dydx(educ exper expersq black) at(black==1 y82==1 y83==0 y84==0 y85==0 y86==0 y87==0) atmeans


**# **#  PCP

* Predicción por máxima probabilidad:
drop phat* yhat psum correct
predict phat1 phat2 phat3, pr

/* 1) ¿Qué calcula predict phat1 ... phat3, pr?

Después de mlogit, Stata estima, para cada observación i y cada alternativa j (1,2,3), la probabilidad predicha

Pr(choice_{i}=j | x_{i})= exp(x_{i}′b_{j})/ (∑k=1,...,3 exp⁡(x_{i}′b_{k}).

Para la base (outcome 1), Stata normaliza b_{1}=0. Eso no significa que P_{i1}=0, sino que la utilidad sistemática de la base se fija a cero como referencia.
Con "predict ..., pr" Stata te devuelve esas probabilidades.

Entonces:

phat1 = P_{i1} = probabilidad predicha de escuela (1)
phat2 = P_{i2} = prob predicha de casa (2)
phat3 = P_{i3} = prob predicha de trabajo (3)

Chequeo simple (debería dar ~1 salvo redondeo):*/

gen psum = phat1+phat2+phat3
summ psum

** o sea: son probabilidades predichas por alternativa, tal como queríamos.

* Categoría predicha = argmax
gen yhat = 1
replace yhat = 2 if phat2>phat1 & phat2>=phat3 
replace yhat = 3 if phat3>phat1 & phat3>phat2 

gen correct = (status==yhat) if !missing(status)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"

** da 69.02%.
** Interpretación: el clasificador "argmax" acierta mas de la mitad de las veces. (Parece un rendimiento algo aceptable si tengo en cuenta que al azar seria 1/3=0.3333, un 33,33%. Mejora por mayor margen al azar. )
**  Ojo con algo importante: este 69.02% es in-sample (en la misma muestra con la que estimaste). No es out-of-sample. 
** Si tuvieramos en un enfoque de prediccion de Machine Learning, es posible que el resultado de acierto de PCP sea bastante peor fuera de la muestra. Por eso para multiples categorias, en ML se usan otras tecnicas.

* Matriz de clasificación (real vs predicho)
tab status yhat, row

/* Tu matriz es la pieza clave. La diagonal (aciertos por categoría real) es:

status=1 (school): 67.77% correcto 
status=2 (home): 45.87% correcto 
status=3 (work): 80.23% correcto 

Lectura rápida:
Predice muy bien/bien "work".
Predice bien "sholar".
Predice mal "home".

pd: si agregamos al modelo mlogit la variable "i.manuf" aumentamos un poco el PCP sobre todo de la categoria "home".

nuevamente recordemos: en un contexto de econometria, causalidad, lo que nos importa son los APEs, no el PCP.

*/




**# CL


*======================================================================*
* 2) Logit condicional (CL) con variables específicas de alternativa
*======================================================================*

* Para asclogit, la data debe estar en "formato largo":
* una fila por (id, alternativa), con una variable choice=1 si elegida.
* "alt" identifica a la alternativa, "id" identifica al individuo.

webuse choice, clear
describe
tab choice
tab car

** no esta en panel, es seccion cruzada este ejemplo.


* Ver una persona y sus 3 alternativas:
*----------------------------------------
* Esto te muestra explícitamente el formato largo:

list id car choice dealer sex income in 1/18, sepby(id)

*Vas a ver:
* - sex e income repetidos dentro del id
* - dealer variando por car
* - choice==1 en una sola fila dentro de id

asclogit choice dealer,	case(id) alternatives(car) casevars(i.sex	income) vce(robust)


/*
================================================================================
EXPLICACIÓN COMPLETA DEL EJEMPLO CON asclogit (Capítulo 16 - Wooldridge / Stata)
================================================================================

asclogit. Es el modelo clásico de elección discreta tipo McFadden (conditional logit),
donde cada individuo elige 1 alternativa entre varias, y los datos están en
formato LARGO (una fila por combinación persona–alternativa).

------------------------------------------------------------------------------
1) Cómo están armados los datos (choice.dta)
------------------------------------------------------------------------------

En choice.dta tenemos:
- 295 personas/casos identificados por "id"
- 3 alternativas por persona identificadas por "car": American, Japan, Europe

Esto cuadra con el output:

    Number of cases = 295
    Alts per case:   min=3 avg=3 max=3
    Number of obs = 885 = 295*3

La variable dependiente "choice" NO es "la categoría elegida" como 1..3, sino un
indicador 0/1 POR FILA:

- choice = 1 si esa fila (esa alternativa j dentro del individuo i) fue elegida
- choice = 0 si esa alternativa j NO fue elegida

Por eso, cuando tabulamos choice:

    295 unos  (uno por cada persona)
    590 ceros (dos por cada persona, las dos alternativas no elegidas)

En otras palabras: cada id tiene exactamente una fila con choice==1, y dos filas
con choice==0.

------------------------------------------------------------------------------
2) Qué modelo está estimando asclogit (estructura teórica)
------------------------------------------------------------------------------

El modelo de elección discreta se escribe como:

    U_ij = V_ij + e_ij

donde:
- i = persona/caso (id)
- j = alternativa (car)
- V_ij = parte observable (función de covariables)
- e_ij = shock no observado

Supuesto clave del logit condicional:
- e_ij i.i.d. Extreme Value Tipo I

Entonces la probabilidad de elegir alternativa j dentro del conjunto de elección
del individuo i es:

                exp(V_ij)
    P_ij = -------------------------
          sum_k exp(V_ik)

Esto es la forma multinomial logit, pero aplicada a sets de elección donde
las covariables pueden variar por alternativa.

------------------------------------------------------------------------------
3) Qué significa cada parte del comando que corriste
------------------------------------------------------------------------------

Tu comando fue:

    asclogit choice dealer, case(id) alternatives(car) casevars(sex income)

Interpretación detallada:

(a) case(id)
------------
Define el "grupo de elección": dentro de cada id, las alternativas compiten y se
elige una sola. Es decir: dentro del mismo id, una sola fila tendrá choice=1.

(b) alternatives(car)
---------------------
Define cuál variable identifica la alternativa j. En este ejemplo car toma los
valores: American / Japan / Europe.

(c) Variables que entran en el modelo: DOS TIPOS
------------------------------------------------

TIPO 1: variables que varían por alternativa (alternative-specific covariates)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Acá pusiste: "dealer"

Esto significa que para cada individuo i, dealer puede tomar valores distintos
según la alternativa j. Por ejemplo:

- dealer_ij = número de concesionarios (dealers) de autos de esa nacionalidad
  en la ciudad del individuo i.

Entonces dealer entra como:

    V_ij = beta*dealer_ij + (otros términos)

y el coeficiente beta es COMÚN a todas las alternativas (una sola pendiente).


TIPO 2: variables que solo varían por individuo/caso (case-specific covariates)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Acá pusiste: "sex income" dentro de casevars()

Estas variables NO cambian con la alternativa dentro de un mismo individuo:
para un mismo id, sex e income son iguales en las 3 filas (American/Japan/Europe).

Si las metieras "directo" como en un modelo estándar, se cancelarían al comparar
utilidades dentro del mismo set de elección, porque son constantes dentro del id.

Por eso asclogit las usa de forma correcta: las mete INTERACTUADAS con dummies de
alternativa (excepto la alternativa base).

En el output eso aparece como:

- Para alternativa Japan:
      sex, income, _cons
- Para alternativa Europe:
      sex, income, _cons
- American es la base: por normalización, esos términos no se reportan ahí

Formalmente, lo que se estima es algo tipo:

    V_ij = beta*dealer_ij
         + 1{j=Japan}  *(gamma_J_sex*sex_i + gamma_J_inc*income_i + alpha_J)
         + 1{j=Europe} *(gamma_E_sex*sex_i + gamma_E_inc*income_i + alpha_E)

y para American (la base) esa parte se normaliza a cero.


------------------------------------------------------------------------------
4) Intuición final para cerrar la idea
------------------------------------------------------------------------------

- mlogit típico: una fila por persona, y la choice es la categoría elegida.
- asclogit: 3 filas por persona (una por alternativa), y la dependiente es 0/1
  por fila.

- Variables que cambian por alternativa (dealer) entran directamente en V_ij.
- Variables del individuo (sex, income) entran diferenciando alternativas
  (Japan vs American, Europe vs American) mediante interacciones implícitas
  con dummies de alternativa.

  */







**# **# APEs

*======
* APEs
*======

asclogit choice dealer,	case(id) alternatives(car) casevars(i.sex	income) vce(robust)
* APE: Efectos marginales promedios:
margins, dydx(*)
** los APEs suele ser lo que  mas interesa cuando el objetivo es aprender sobre las relaciones entre variables, estructurales, o efectos causales en ultima instancia.


/*
================================================================================
INTERPRETACIÓN DE LOS APE (Average Partial Effects) DESPUÉS DE asclogit
Y POR QUÉ APARECEN "INTERACTUANDO" EN EL OUTPUT DE margins
================================================================================

Contexto del modelo estimado:
-----------------------------
Se estimó:

    asclogit choice dealer, case(id) alternatives(car) casevars(sex income) vce(robust)

- i = caso/persona (id)
- j = alternativa (car ∈ {American, Japan, Europe})
- choice_ij = 1 si el individuo i elige alternativa j; 0 si no.

La probabilidad predicha es:

                exp(V_ij)
    P_ij = ----------------------
          sum_k exp(V_ik)

Con:
- dealer_ij (varía por alternativa) entra "directo" en V_ij con UNA pendiente común.
- sex_i e income_i (no varían por alternativa dentro de i) entran como "casevars":
  asclogit los incorpora efectivamente mediante efectos diferenciales por alternativa
  (interacciones implícitas con dummies de alternativa, tomando una base).

--------------------------------------------------------------------------------
1) Qué es un APE acá (qué calcula margins, dydx(*))
--------------------------------------------------------------------------------

margins, dydx(*) calcula EFECTOS MARGINALES PROMEDIO sobre probabilidades:

- Para cada observación (i,j) calcula la derivada parcial de la probabilidad
  con respecto a cada covariable (dealer, sex, income).
- Luego promedia esas derivadas sobre la muestra (por defecto, sobre las filas
  usadas en el modelo).

En símbolos, para una variable continua x:

    APE_x(alt = m) = (1/N) * sum_i [ ∂ P_im / ∂ x ]

Para una variable discreta binaria (sex):
- Stata calcula un "discrete change": P(sex=1) - P(sex=0), manteniendo todo lo
  demás constante, y luego promedia.

--------------------------------------------------------------------------------
2) Por qué el APE de dealer aparece como "_outcome#car" (parece interacción)
--------------------------------------------------------------------------------

Esto es lo más importante:

- dealer es una variable QUE CAMBIA POR ALTERNATIVA: dealer_ij.
- En un modelo logit condicional, cambiar dealer de una alternativa afecta
  TODAS las probabilidades del set porque deben sumar 1.

Por eso, la derivada relevante NO es única: depende de
(1) cuál alternativa "tocás" con dealer (car = American/Japan/Europe)
y (2) para cuál probabilidad estás mirando el efecto (outcome = American/Japan/Europe).

En otras palabras, margins está reportando:

    ∂ P_i(outcome = m) / ∂ dealer_i(car = k)

para todo par (m,k).

Eso es exactamente lo que Stata te muestra como:

    _outcome#car
    American#Japan, Europe#American, etc.

Interpretación práctica:
- "American#Japan" bajo dealer significa:
  "cómo cambia la probabilidad de elegir American cuando aumenta en 1 unidad el
   dealer asociado a la alternativa Japan, manteniendo todo lo demás constante".

Regla general (propiedad mecánica del logit):
- Aumentar dealer_k sube la probabilidad de elegir k,
  y baja las probabilidades de las otras alternativas (porque suman 1).

Tu output lo refleja:
- dealer: American#American = +0.0149 (sube P(American) si sube dealer_American)
- dealer: American#Japan     = -0.0092 (baja P(American) si sube dealer_Japan)
- dealer: American#Europe    = -0.0057 (baja P(American) si sube dealer_Europe)
y análogamente para los otros outcomes.

Observación útil:
- Para cada "car = k", si sumás los tres efectos sobre outcomes (American, Japan, Europe),
  debe dar aproximadamente 0 (por la restricción de suma a 1):
      ∑_m ∂P_im/∂dealer_ik ≈ 0

--------------------------------------------------------------------------------
3) Cómo interpretar los APE de sex e income (por qué NO aparecen con #car)
--------------------------------------------------------------------------------

sex e income son casevars: NO varían por alternativa dentro del individuo.
Cuando cambian, cambian el set completo de utilidades relativas, y por ende
las probabilidades de cada outcome.

Por eso margins reporta, para cada outcome m:

    ∂ P_im / ∂ sex_i
    ∂ P_im / ∂ income_i

y lo muestra como:

    _outcome
    American
    Japan
    Europe

Interpretación:
- "sex: Japan = -0.1045" significa:
  En promedio, pasar de sex=0 a sex=1 reduce la probabilidad de elegir Japan en 0.1045
  (≈ 10.45 puntos porcentuales), manteniendo dealer e income constantes.
  (Y las otras probabilidades se ajustan para que la suma siga siendo 1.)

- "income: Japan = +0.0044" significa:
  En promedio, aumentar income en 1 unidad (1 "thousand", porque income está en miles)
  aumenta la probabilidad de elegir Japan en 0.0044 (≈ 0.44 puntos porcentuales),
  manteniendo lo demás constante.
  (American cae -0.0071 y Europe sube +0.0026, consistente con la suma a 1.)

Nota importante:
- Estos APE son sobre PROBABILIDADES, no sobre odds ni sobre utilidades.
- Para income, la unidad es "1" en la escala de la variable (miles de dólares).

--------------------------------------------------------------------------------
4) Lectura económica rápida de tus APE (lo que "dice" el modelo)
--------------------------------------------------------------------------------

(1) dealer:
- Más dealers de una nacionalidad aumentan (en promedio) la probabilidad de elegir
  esa nacionalidad y reducen las otras dos.

(2) sex:
- sex=1 (según codificación del dataset) reduce fuertemente la probabilidad de elegir Japan
  (~ -10.45 pp) y aumenta la de Europe (~ +7.96 pp); el efecto en American no es significativo.

(3) income:
- A mayor ingreso, cae la probabilidad de American (-0.706 pp por cada +1 en income)
  y suben Japan (+0.442 pp) y Europe (+0.265 pp) por cada +1 en income.

--------------------------------------------------------------------------------
5) Por qué "aparecen interactuando" aunque vos no hayas puesto interacciones
--------------------------------------------------------------------------------

No es una interacción "modelada a mano", es que:

- dealer es alternativa-específica (dealer_ij), por lo que el efecto marginal depende
  de "qué alternativa estoy moviendo" (car=k) y "qué probabilidad estoy mirando"
  (outcome=m). Eso obliga a reportar pares (m,k), y Stata lo imprime como outcome#car.

- sex e income son case-specific: no hay "dealer_i(American) vs dealer_i(Japan)".
  Por eso se reportan solo por outcome.

*/






**# **# PCP

* (ii) Predicciones: probabilidades por alternativa
* ------------------------------------------------
* Después de asclogit:

predict phat, pr
*verificacion: psum debería ser ~1 para cada id (salvo redondeo).
by id: egen psum = total(phat)
summ psum

*(iii) "Cuál predice como elegida" usando argmax
*------------------------------------------------
*Esto construye un clasificador por máxima probabilidad predicha:
by id: egen pmax = max(phat)
gen yhat = (phat==pmax)
tab choice yhat

gen correct = (choice==yhat) if !missing(choice)
summ correct
display "Porcentaje correctamente predicho = " 100*r(mean) "%"

**Esto indica si la alternativa con mayor probabilidad predicha coincide con la alternativa realmente elegida (choice==1). Ojo que empates exactos son raros, pero teóricamente pueden existir por redondeo.








