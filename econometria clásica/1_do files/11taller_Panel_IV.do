**# Capitulo 11


*******************************************************************************
****************************** VI-EF & VI-RE **********************************
*******************************************************************************
/*
TALLER: RE-IV (Wooldridge 11.2) con "airfare" 

Modelo:
  lpassen_it = b1*ldist_it + b2*ldistsq_it + b3*lfare_it + c_i + u_it
  lfare_it endógena
  Instrumento excluido: concern_it
  Exógenas: ldist_it, ldistsq_it (también son instrumentos)
*/


clear all
set more off

bcuse airfare, clear

xtset id year
sort id year

*------------------------------------------------------------*
* Especificación 
*------------------------------------------------------------*
local y     "lpassen"
local exog  "ldist ldistsq"
local endog "lfare"
local zexcl "concen"

* Chequeo mínimo
foreach v in id year `y' `exog' `endog' `zexcl' {
    cap confirm variable `v'
    if _rc {
        di as error "Falta la variable: `v'. (Revisá nombres en la base)."
        exit 198
    }
}


xtivreg `y' `exog' (`endog' = `zexcl'), re
estimates store REIV_base

 scalar lambda_xt_base = e(theta)
    di as txt "lambda = " %9.6f lambda_xt_base
	
**# RE-IV: directo con xtivreg

*------------------------------------------------------------*
* A) RE-IV directo (GIV bajo estructura RE)
*------------------------------------------------------------*

** reproduce primera columna del cuadro del manual:
xtreg lpassen lfare ldist ldistsq i.year, re
xtreg lpassen lfare ldist ldistsq i.year, re vce(cluster id)
xtreg lpassen lfare ldist ldistsq i.year, re vce(cluster id) theta
** reproduce tercera columna del cuadro del manual:
xtivreg lpassen ldist ldistsq (lfare = concen) i.year, re
xtivreg lpassen ldist ldistsq (lfare = concen) i.year, re vce(cluster id)
xtivreg lpassen ldist ldistsq (lfare = concen) i.year, re vce(cluster id) theta

/* que es lo que hace el comando xtivreg:
		1) Si bien Stata nos muestra una sola salida, por detras hace dos etapas. 
		   Primero, realiza una regresion POOL-2SLS y extra las varianzas de los componentes
		   de heterogeneidad inobservale, y la varianza idiosincratica. 
		   Con ello, arma una matriz de pesos W, y la arma con una estructura particular: la estructura RE.
		   Para ello utiliza las dos varianzas anteriores estimadas. 
		   Una vez que tiene la estimacion de W, esto es, con la forma RE, lo que hace es pasar a la segunda etapa.
		2) En la segunda etapa, estima el mismo modelo, pero ya no sera por POOL-2SLS, sino que, al utilizar a
		   W con esta estructura como ponderacion, lo que hace es estimar por un estimador GIV.
		   Este estimador GIV, que usa este W particular (estructura RE), es el estimador GIV=RE-IV.
		   
* El instrumentos entra tanto en la primera etapa, como en la segunda cuando ya se impone la estructura RE en la matriz W.
  la primera etapa es necesaria para obtener los componentes de varianza del componente de error RE. 
  la segunda etapa es aplicar el GIV particular y asi obtiene el famoso estimador RE-IV.

*/

**# RE-IV: transformacion quasi-demeaning y luego aplico 2SLS

*------------------------------------------------------------*
* B) RE-IV alternativo: por transformacion quasi-demeaned.
* partimos de un modelo RE-IV. 
* (no es correcto partir de un modelo RE, tenemos que partir de un modelo RE-IV para que 
*  los componentes de varianza estimados, y lambda, surjan sin endogeneidad)
* Pero hacer lo anterior "manual" es tedioso, y llevaria bastante codigo de stata, 
* asi que mejor usar directamente, otra vez, el comando xtivreg para ayudarnos a ahorrar pasos. 
* Una vez estimamos ese modelo, podemos extraer lo que precisamos.
* extraemos sus componentes de varianza y la lambda. 
* generamos las variables quasi-demeaned
* segunda etapa: estimo la especificacion quasi-demeaned por POOL-2SLS 
*
*------------------------------------------------------------*

xtivreg lpassen ldist ldistsq i.year (lfare = concen), re 

scalar sigma_c2 = (e(sigma_u))^2   // Var(c_i)
scalar sigma_u2 = (e(sigma_e))^2   // Var(u_it)

bys id: gen int Ti = _N
gen double theta_i = 1 - sqrt( sigma_u2 / (sigma_u2 + Ti*sigma_c2) )

* medias por id
bys id: egen double mean_lpassen = mean(lpassen)
bys id: egen double mean_ldist   = mean(ldist)
bys id: egen double mean_ldistsq = mean(ldistsq)
bys id: egen double mean_lfare   = mean(lfare)
bys id: egen double mean_concen = mean(concen)
bys id: egen double mean_y98     = mean(y98)
bys id: egen double mean_y99     = mean(y99)
bys id: egen double mean_y00     = mean(y00)

* transformadas
gen double q_lpassen = lpassen - theta_i*mean_lpassen
gen double q_ldist   = ldist   - theta_i*mean_ldist
gen double q_ldistsq = ldistsq - theta_i*mean_ldistsq
gen double q_lfare   = lfare   - theta_i*mean_lfare
gen double q_concen = concen - theta_i*mean_concen
gen double q_y98     = y98     - theta_i*mean_y98
gen double q_y99     = y99     - theta_i*mean_y99
gen double q_y00     = y00     - theta_i*mean_y00

* intercepto quasi-demeaned: 1~ = 1 - theta_i
gen double cons_q = 1 - theta_i

ivregress 2sls q_lpassen cons_q q_ldist q_ldistsq q_y98 q_y99 q_y00 (q_lfare = q_concen), nocons
estimates store RE2SLS_quasi

*--------------------------------------------------------------------------------
** ahora el mismo RE-IV alternativo pero con errores estandar robustos

xtivreg lpassen ldist ldistsq i.year (lfare = concen), re vce(cluster id)

scalar sigma_c2r = (e(sigma_u))^2   // Var(c_i)
scalar sigma_u2r = (e(sigma_e))^2   // Var(u_it)

bys id: gen int Tir = _N
gen double theta_ir = 1 - sqrt( sigma_u2r / (sigma_u2r + Tir*sigma_c2r) )

* transformadas
gen double q_lpassenr = lpassen - theta_ir*mean_lpassen
gen double q_ldistr   = ldist   - theta_ir*mean_ldist
gen double q_ldistsqr = ldistsq - theta_ir*mean_ldistsq
gen double q_lfarer   = lfare   - theta_ir*mean_lfare
gen double q_concenr = concen - theta_ir*mean_concen
gen double q_y98r     = y98     - theta_ir*mean_y98
gen double q_y99r     = y99     - theta_ir*mean_y99
gen double q_y00r     = y00     - theta_ir*mean_y00

* intercepto quasi-demeaned: 1~ = 1 - theta_i
gen double cons_qr = 1 - theta_ir

ivregress 2sls q_lpassenr cons_qr q_ldistr q_ldistsqr q_y98r q_y99r q_y00r (q_lfarer = q_concenr), nocons vce(cluster id)
estimates store RE2SLS_quasi_rob

summ theta_ir theta_i


**# RE-IV: Prueba de exogeneidad 

*------------------------------- PRUEBAS -----------------------------------------

/****************************************************************************************
ACLARACIÓN: ¿qué es y_it2 y y_it3 en cada prueba RE-IV?

Hay dos pruebas distintas, y por eso la "partición" cambia:

(1) Test de exogeneidad (Control Function, eqs. 11.19–11.21)
    Pregunta: "¿puedo tratar cierta variable como EXÓGENA bajo RE?"
    - y_it3 = bloque "en duda" (la variable cuya exogeneidad testeo).
    - y_it2 = endógenas "aceptadas" (que ya trato como endógenas y para las que tengo
             instrumentos excluidos).
    En nuestra aplicación:
      y_it3 = lfare   (queremos testear si lfare es exógena o endógena)
      y_it2 = -       (no hay otras endógenas aparte de lfare, así que este bloque es nulo)
    El test se basa en: H0: rho = 0 (coeficiente del residuo de la forma reducida).

(2) Test de sobreidentificación (Overid, eqs. 11.22–11.23)
    Pregunta: "DADO que una variable es endógena y la instrumento, ¿son válidos (exogenos) los
              instrumentos EXCEDENTES?"
    - En esta prueba NO existe y_it3 (se omite).
    - y_it2 = vector de endógenas instrumentadas.
    En nuestra aplicación:
      y_it2 = lfare   (ahora lfare se trata como endógena instrumentada)
      y_it3 = (omitido)
    Condición clave: para poder hacer overid se necesita sobreidentificación.
      Con 1 endógena (lfare), necesito al menos 2 instrumentos excluidos.
      Si solo tengo concen -> justo identificado -> no hay overid.
      Si agrego origin y/o destin (instrumentos adicionales) -> sí hay overid y el test tiene sentido.
****************************************************************************************/


*------------------------ (1) Prueba de exogeneidad sobre lfare ----------------------

* lpassen = (cons + ldist + ldistsq + y98  + y99  + y00)*delta + (lfare)*gamma + c + u      (11.19)
* nota: en este caso no tenemos variables que vayan en y_it2*alpha. 
*       en ese vector irian otras variables que consideremos endogenas, y para las que tambien contemos con al menos un instrumento no trivial, y para las cuales no nos interesa evaluar su exogeneidad.
*       Entonces, las que van en y_it2 son endogenas que no nos interesa evaluar.
*       Mientras que, las que van en y_it3 son la o las endogenas que nos interesa evaluar su exogeneidad. 
*       En este caso, solo hay una endogena, y nos interesa evaluarla, por lo tanto, tenemos una en y_it3 y no tenemos ninguna en y_it2.
 
* (1) Reduced form para lfare: podés usar pooled OLS o RE (11.20)
xtreg lfare ldist ldistsq y98 y99 y00 concen, re
* (2) Residuo de la reduced form (composite residual)
* En xtreg, 'ue' es el residual compuesto (efecto + idiosincrático)
predict double vhat_lfare, ue
* (3) estimamos ecuacion ampliada por RE-IV:
xtivreg lpassen ldist ldistsq y98 y99 y00 vhat_lfare (lfare = concen), re vce(cluster id)
* Wald test de H0: rho=0  (si rechazás, lfare NO es exógena)
test vhat_lfare

/*Conclusion: no se rechaza la hipotesis nula, por lo tanto, no rechazamos que lfare sea exogena.
              No confundirse, este resultado lo que nos sugiere es que no es necesario implementar una estrategia IV.
			  Lo siguiente seria elegir entre RE o FE para esta especificacion. (o incluso POLS!)
			  Eso dependera de si los c_i se correlacionan o no con los regresores, conceptualmente hablando.
			  Formalmente podemos usar el test de hausman para acompañar en la decision. 
			  O la version robusta con Mundlak. 
*/

*La prueba anterior la deberiamos hacer SIEMPRE. 

**# RE-IV: Prueba de sobreidentificacion

*------------------------ (2) Prueba de sobreidentificacion (precisamos mas de un instrumento para lfare) ----------------------

* vamos a hacer de cuenta que el test anterior dio que lfare era endogena (aunque nos dio que no rechaza su exogeneidad) para poder mostrar el test.
* Entonces tiene sentido instrumentarla, y supongamos que tenemos mas de un instrumnento.
* necesito por lo menos un instruemento externo mas.

describe
** solo dos posibles extras: origin o destin

/****************************************************************************************
TEST DE SOBREIDENTIFICACIÓN (RE-IV) — 3 etapas (Wooldridge 11.2)
Endógena:   lfare
Exógenas:   ldist ldistsq y98 y99 y00
Instrumentos excluidos: concen  origin  
Idea: con 1 endógena y 2 instrumentos excluidos => Q1=2-1=1 restricción overid
****************************************************************************************/

encode origin, gen(origin_id)

********************************************************************************
* (0) Estimar RE-IV con instrumentos excedentes (concen + origin) y obtener theta
********************************************************************************

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), re
scalar theta = e(theta)

* residual estructural uhat = y - X*b  (del modelo RE-IV)
predict double xb_reiv, xb
gen double uhat = lpassen - xb_reiv

* Quasi-demeaning (usar theta)
*     ddot(a_it) = a_it - theta * mean_i(a_it)
foreach v in lpassen lfare ldist ldistsq y98 y99 y00 concen origin_id uhat{
    bys id: egen double m_`v' = mean(`v')
    gen double ddot_`v' = `v' - theta*m_`v'
}

* constante quasi-demeaned: 1* = 1 - theta  (la agregamos como variable y luego nocons para que el modelo no ponga su constante por defecto)
capture drop cons_q
gen double cons_q = 1 - theta

********************************************************************************
* (1) ETAPA (i): primera etapa (sobre datos quasi-demeaned) para lfare
*     produce ddot_lfare_hat
********************************************************************************
reg ddot_lfare cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 ddot_concen ddot_origin_id, nocons
predict double ddot_lfare_hat, xb

********************************************************************************
* (2) ETAPA (ii): "depurar" instrumento adicional ddot_origin_id respecto de
*     (ddot_z1, ddot_lfare_hat) y obtener residuo ddot_rhat
********************************************************************************
reg ddot_origin_id cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 ddot_lfare_hat, nocons
predict double ddot_rhat, resid

********************************************************************************
* (3) ETAPA (iii): ecuación auxiliar (11.23) y Wald robusto (cluster id)
*     ddot_uhat = eta*ddot_rhat + error
********************************************************************************
reg ddot_uhat ddot_rhat, vce(cluster id)

* H0: eta = 0  -> si rechazás, el instrumento extra (origin) no pasa overid
test ddot_rhat

/* conclusion: no se rechaza la hipotesis nula. 
			   no hay evidencia de que origin_id sea inválido como instrumento adicional
			   (es decir, no hay evidencia de correlación con el error compuesto, bajo la especificación IV-RE que usamos). 
			   Este es un ejemplo didactico. (Seguramente si bien parece ser exogena, es posible que no sea relevante para explicar lfare, que es la otra condicion que debe verificarse en un buen instrumento).
*/


/****************************************************************************************
ACLARACIÓN 

1) Aunque "xtivreg, re" aplica internamente la transformación RE para estimar, cuando hacemos:
       "predict xb_reiv, xb" los valores predichos xb_reiv estan en NIVELES (escala original) 
	   y por ende los residuos "uhat = y - xb_reiv" tambien.
   Recién después nosotros construimos: ddot_uhat = uhat - theta*mean_i(uhat)
   Eso es UNA sola transformación quasi-demeaned aplicada al residuo.

2) En el test de sobreidentificación (ec. 11.23), el residuo debe venir del RE-IV
   El objeto del test es:  ddot(uhat), donde uhat = y - x'*b_hat
   y b_hat debe ser el estimador RE-IV (xtivreg, re), porque estamos testeando la validez
   de instrumentos "extra" bajo ese modelo IV-RE.
   Si en cambio usaramos uhat de un POLS (que trata lfare como exógena), el residuo incorpora
   endogeneidad y el test deja de corresponder a la definición teórica.

3) Ojo con la interpretación: este test NO evalúa relevancia
   El test de sobreidentificación evalúa VALIDEZ/EXOGENEIDAD del instrumento extra
   (si está correlacionado con el error).
	
****************************************************************************************/


**# RE-IV: Relevancia y Validez de los IV 

*--------------------------------- RELEVANCIA DE LOS INSTRUMENTOS (RE-IV) ------------------------------------

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), re vce(cluster id) first

/*Cuidado: estat firststage/ estat endogenous/ estat overid
	Esos estat ... son postestimation de ivregress, no de xtivreg. 
	En la documentación oficial, estat endogenous, estat firststage y estat overid están definidos para ivregress (2SLS/GMM/LIML), incluyendo las versiones robustas cuando usás VCE robusta/cluster. 
	Entonces, si querés exactamente esos estadísticos "tipo estat ..." en tu contexto RE-IV, la vía limpia es:
	
	1-Hacés tu quasi-demeaning con λ.
	2-Estimás el 2SLS pooled sobre las variables quasi-demeaned con ivregress 2sls ... , vce(cluster id).
	3- Ahí sí corrés los estat.
*/

drop m_lpassen ddot_lpassen m_lfare ddot_lfare m_ldist ddot_ldist m_ldistsq ddot_ldistsq m_y98 ddot_y98 m_y99 ddot_y99 m_y00 ddot_y00 m_concen ddot_concen m_origin_id ddot_origin_id cons_q

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), re
scalar theta = e(theta)
foreach v in lpassen lfare ldist ldistsq y98 y99 y00 concen origin_id{
    bys id: egen double m_`v' = mean(`v')
    gen double ddot_`v' = `v' - theta*m_`v'
}

capture drop cons_q
gen double cons_q = 1 - theta

*ivregress 2sls  ddot_lpassen cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 (ddot_lfare = ddot_concen ddot_origin_id), nocons vce(cluster id) 
*ivregress 2sls  ddot_lpassen cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 (ddot_lfare = ddot_concen ddot_origin_id), nocons vce(cluster id) first
ivreg2 ddot_lpassen cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 (ddot_lfare = ddot_concen ddot_origin_id), nocons cluster(id)
ivreg2 ddot_lpassen cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 (ddot_lfare = ddot_concen ddot_origin_id), nocons cluster(id) first



/* Observar que si queremos hacer un analisis sobre los instrumentos rapidamente, hariamos esto mismo,
  	1-Hacés tu quasi-demeaning con λ.
	2-Estimás el 2SLS pooled sobre las variables quasi-demeaned con ivreg2 ..., nocons cluster(id) first
	y obtenemos todo el analisis tanto de la exogeneidad de los instrumentos como de la relevancia de los mismos.
	Esto es mucho mas directo y nos permite fundamentar nuestra eleccion de instrumentos y estar confiados en caso satisfactorio. 
	Esto mismo, lo podemos hacer en el otro contexto de FE-IV, que trabajaremos a continuacion.
*/


*** CONCLUSION: En este caso, los instrumentos parecen ser buenos instrumentos: no se rechaza que sean exogenos.. y en conjunto tienen relevancia para explicar la endogena lfare.
*** Aunque, es interesante estudiar que pasa si dejamos solo a concen, ya que origin_id lo use para poder probar como es la prueba de sobreidentificacion. Veamos:

*** primero veamos, para ambos instrumentos, que ambos enfoques coinciden en los coeficientes. 
xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), re vce(cluster id)
ivreg2 ddot_lpassen cons_q ddot_ldist ddot_ldistsq ddot_y98 ddot_y99 ddot_y00 (ddot_lfare = ddot_concen ddot_origin_id), nocons cluster(id) 


*** segundo, veamos que pasa si uso solamente concer como instrumento no trivial, pero ahora, debo generar una nueva transformacion quasi-demeaned, porque el theta cambiara:
xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen), re
scalar theta2 = e(theta)
foreach v in lpassen lfare ldist ldistsq y98 y99 y00 concen origin_id{
    bys id: egen double m2_`v' = mean(`v')
    gen double ddot2_`v' = `v' - theta2*m_`v'
}

capture drop cons_q2
gen double cons_q2 = 1 - theta2

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen), re vce(cluster id)
ivreg2 ddot2_lpassen cons_q2 ddot2_ldist ddot2_ldistsq ddot2_y98 ddot2_y99 ddot2_y00 (ddot2_lfare = ddot2_concen), nocons cluster(id) 

* Lectura comparativa: por un lado, esta claro que cuando uso un unico instrumento no trivial para una endogena, el estadistico J de hansen no se puede calcular. 
* 					   por lo que ahora concen, en cuanto a su exogeneidad como instrumento, solo se podria justificar teoricamente. 
*                      pero lo interesante es analizar que pasa con la relevancia cuando pasamos de usar concer y origin_id a utilizar solamente concern.
*                      lo que vemos es que el F de KP paso de 33,04 a 15,31. Este valor de 15.31 esta un poquito por debajo del F de tabla para un maximo de 10% de sesgo relativo a OLS. 
*                      Por lo que, contrario a lo que yo pensaba, parece ser que usar origin_id en adicion a concen, puede hacer que los instrumentos tengan un poco mas de fuerza en cuanto a relevancia para lfare.

 
 /* de todas formas, recordar que la primera prueba que hicimos nos daba que lfare no se rechaza que sea exogena, con lo cual, no hariamos RE-IV, solamente RE (o solamente FE), pero no nos meteriamos a usar instrumentos. 
 */

 
**# FE-IV

*******************************************************************************
********************************* FE-IV **************************************
*****************************************************************************


clear all
set more off
bcuse airfare, clear

xtset id year
sort id year


local y     "lpassen"
local exog  "ldist ldistsq"
local endog "lfare"
local zexcl "concen"

foreach v in id year `y' `exog' `endog' `zexcl' y98 y99 y00 {
    cap confirm variable `v'
    if _rc {
        di as error "Falta la variable: `v'."
        exit 198
    }
}

*------------------------------------------------------------*
* A) FE (sin IV) — referencia
* recreamos la segunda columna de la tabla del manual
*------------------------------------------------------------*
xtreg lpassen lfare  ldist ldistsq i.year, fe
xtreg lpassen lfare  ldist ldistsq i.year, fe vce(cluster id)
estimates store FE_base
** las variables de distancia no cambian en el tiempo, por lo que se omiten (within)


**# FE-IV: directo con xtivreg

*------------------------------------------------------------*
* B) FE-IV directo
* recreamos la cuarta columna de la tabla del manual
*------------------------------------------------------------*
xtivreg lpassen ldist ldistsq i.year (lfare = concen), fe
xtivreg lpassen ldist ldistsq i.year (lfare = concen), fe vce(cluster id)
xtivreg lpassen ldist ldistsq i.year (lfare = concen), fe vce(cluster id) first
estimates store FEIV_base

**# FE-IV: Prueba de exogeneidad


*------------------------ (1) Prueba de exogeneidad sobre lfare ----------------------
 
* (1) Reduced form para lfare: podés usar pooled OLS o FE 
xtreg lfare ldist ldistsq y98 y99 y00 concen, fe
* (2) Residuo de la reduced form (composite residual)
* En xtreg, 'ue' es el residual compuesto (efecto + idiosincrático)
predict double vhat_lfare, ue
* (3) estimamos ecuacion ampliada por FE-IV:
xtivreg lpassen ldist ldistsq y98 y99 y00 vhat_lfare (lfare = concen), fe 
* Wald test de H0: rho=0  (si rechazás, lfare NO es exógena)
test vhat_lfare

/* El estadistico NO robusto es grande en magnitud y diriamos que se rechaza la HO, y que entonces lfare es endogena... perooooo,
	pero dada la diferencia entre los errores estandar no robustos vs los errores estandar robustos, sospechamos que lo correcto
    es trabajar con errores estandar robustos, entonces, si repetimos esta prueba: */
drop vhat_lfare

* (1) Reduced form para lfare: podés usar pooled OLS o FE 
xtreg lfare ldist ldistsq y98 y99 y00 concen, fe
* (2) Residuo de la reduced form (composite residual)
* En xtreg, 'ue' es el residual compuesto (efecto + idiosincrático)
predict double vhat_lfare, ue
* (3) estimamos ecuacion ampliada por FE-IV:
xtivreg lpassen ldist ldistsq y98 y99 y00 vhat_lfare (lfare = concen), fe vce(cluster id)
* Wald test de H0: rho=0  (si rechazás, lfare NO es exógena)
test vhat_lfare

/*Conclusion: no se rechaza la hipotesis nula, por lo tanto, no rechazamos que lfare sea exogena. (aunque el p-valor es mas bajo que cuando hicimos esta prueba en el entorno RE)
              No confundirse, este resultado lo que nos sugiere es que no es necesario implementar una estrategia IV.
			  Lo siguiente seria elegir entre RE o FE para esta especificacion. (o incluso POLS!)
			  Eso dependera de si los c_i se correlacionan o no con los regresores, conceptualmente hablando.
			  Formalmente podemos usar el test de hausman para acompañar en la decision. 
			  O la version robusta con Mundlak. 
			  aunque un lambda (theta) tan elevado sugiere que quiza directamente uno podria quedarse con RE sin necesidad de una prueba formal.
			  es decir, un analisis de los 4 modelos apunta a que el indicado en estos datos es simplemente RE (que ademas permite capturar distancia y distancia al cuadrado)
			  la otra opcion es probar un modelo FE donde las dummies de año interactuen con ldist y ldistsq. 
*/


**# FE-IV: Prueba de sobreidentificacion

*------------------------ (2) Prueba de sobreidentificacion  ----------------------

* vamos a hacer de cuenta que el test anterior dio que lfare era endogena (aunque nos dio que no rechaza su exogeneidad) para poder mostrar el test.
* Entonces tiene sentido instrumentarla, y supongamos que tenemos mas de un instrumnento.
* necesito por lo menos un instruemento externo mas.

describe
** solo dos posibles extras: origin o destin

/****************************************************************************************
TEST DE SOBREIDENTIFICACIÓN (FE-IV)
Endógena:   lfare
Exógenas:   ldist ldistsq y98 y99 y00
Instrumentos excluidos: concen  origin  
Idea: con 1 endógena y 2 instrumentos excluidos => Q1=2-1=1 restricción overid
****************************************************************************************/

encode origin, gen(origin_id)
* aunque origin_id no tiene sentido ahora porque no varia en el tiempo, y la transformacion within lo va a eliminar.
* POR LO TANTO, solo dejo este bloque del test de sobreidentificacion en FE a modo de ejemplo, pero no tiene sentido, solo hay un instrumento no trivial ahora en FE.


********************************************************************************
* (0) Estimar FE-IV con instrumentos excedentes (concen + origin) y obtener theta
********************************************************************************

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), fe

* residual estructural uhat = y - X*b  (del modelo FE-IV)
predict double xb_feiv, xb
gen double uhat = lpassen - xb_feiv

* demeaning (within)
*     tilde(a_it) = a_it - mean_i(a_it)
foreach v in lpassen lfare ldist ldistsq y98 y99 y00 concen origin_id uhat{
    bys id: egen double m_`v' = mean(`v')
    gen double tilde_`v' = `v' - m_`v'
}


********************************************************************************
* (1) ETAPA (i): primera etapa (sobre datos demeaned) para lfare
*     produce tilde_lfare_hat
********************************************************************************
reg tilde_lfare tilde_ldist tilde_ldistsq tilde_y98 tilde_y99 tilde_y00 tilde_concen tilde_origin_id, nocons
predict double tilde_lfare_hat, xb

********************************************************************************
* (2) ETAPA (ii): "depurar" instrumento adicional ddot_origin_id respecto de
*     (tilde_z1, tilde_lfare_hat) y obtener residuo tilde_rhat
********************************************************************************
reg tilde_origin_id tilde_ldist tilde_ldistsq tilde_y98 tilde_y99 tilde_y00 tilde_lfare_hat, nocons
predict double tilde_rhat, resid


********************************************************************************
* (3) ETAPA (iii): ecuación auxiliar (11.23) y Wald robusto (cluster id)
*     tilde_uhat = eta*tilde_rhat + error
********************************************************************************
reg tilde_uhat tilde_rhat, vce(cluster id)
* H0: eta = 0  -> si rechazás, el instrumento extra (origin) no pasa overid
test tilde_rhat


****************************************************************************************/

**# FE-IV: Relevancia y Validez de los IV

*--------------------------------- RELEVANCIA DE LOS INSTRUMENTOS (FE-IV) ------------------------------------

** recordemos que en este caso, esto solo lo muestro para fines didacticos y aplicar a otra base, porque aca solo hay un unico instrumento valido en la transformacion within. 

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), fe vce(cluster id) first

drop m_lpassen tilde_lpassen m_lfare tilde_lfare m_ldist tilde_ldist m_ldistsq tilde_ldistsq m_y98 tilde_y98 m_y99 tilde_y99 m_y00 tilde_y00 m_concen tilde_concen m_origin_id tilde_origin_id 

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), fe
foreach v in lpassen lfare ldist ldistsq y98 y99 y00 concen origin_id{
    bys id: egen double m_`v' = mean(`v')
    gen double tilde_`v' = `v' - m_`v'
}

ivreg2 tilde_lpassen tilde_ldist tilde_ldistsq tilde_y98 tilde_y99 tilde_y00 (tilde_lfare = tilde_concen tilde_origin_id), nocons cluster(id)
ivreg2 tilde_lpassen tilde_ldist tilde_ldistsq tilde_y98 tilde_y99 tilde_y00 (tilde_lfare = tilde_concen tilde_origin_id), nocons cluster(id) first


*** primero veamos, para ambos instrumentos, que ambos enfoques coinciden en los coeficientes. 
xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen origin_id), fe vce(cluster id)
ivreg2 tilde_lpassen tilde_ldist tilde_ldistsq tilde_y98 tilde_y99 tilde_y00 (tilde_lfare = tilde_concen tilde_origin_id), nocons cluster(id)


*** segundo, veamos que pasa si uso solamente concer como instrumento no trivial, notar que ahora no necesito regenerar la transformacion porque para whitin siempre lambda=1

xtivreg lpassen ldist ldistsq y98 y99 y00 (lfare = concen), fe vce(cluster id)
ivreg2 tilde_lpassen tilde_ldist tilde_ldistsq tilde_y98 tilde_y99 tilde_y00 (tilde_lfare = tilde_concen), nocons cluster(id)

** NOTA: me queda la duda acerca de si debo usar la opcion "nocons" en los ivreg2. Pero creo que tanto con el comando reg, como con ivreg2, 
** 			cuando usamos todas la especificacion en tilde (transformacion within) tiene sentido usar nocons. (y si la pongo deberia dar 0)



**# Comparacion: Hausman



*****************************************************************
********************** HAUSMAN **********************************
*****************************************************************


* OJO: teóricamente el Hausman compara el vector δ de regresores que cambian en i y t (w_it).
* Las dummies de año se incluyen en ambos modelos para no sesgar nada, pero la interpretación del test es sobre las que tienen variación dentro de firma.

/**********************************************************************
* A) HAUSMAN "CLÁSICO", BAJO RE-IV.3
*    - Ambos modelos con varianza clásica.
*    - RE-IV es eficiente bajo H0; 
     - FE-IV y RE-IV consistentes bajo H0.
***********************************************************************/

* RE-IV con varianza clásica (RE-IV.3)
* Modelo reducido SOLO con las variables que varían en i y t
* ldist, ldistsq solo varian en i
* i.year solo varian en t

* Test de Hausman clásico
* - 'sigmamore' fuerza que las dos matrices de varianza usen un parámetro de varianza común basado en el estimador eficiente (RE).
*   Esto es lo que encaja con la derivación teórica estándar del Hausman (Wooldridge, Stata manual).

xtivreg lpassen  (lfare = concen), re 
estimates store REIV_clasico
xtivreg lpassen  (lfare = concen), fe 
estimates store FEIV_clasico
hausman FEIV_clasico REIV_clasico, sigmamore


* Interpretación:
* - H0: Cov(c_i, w_it) = 0  (supuesto RE-IV.1b válido)  -> RE-IV consistente y eficiente.
* - H1: Cov(c_i, w_it) != 0 -> RE-IV inconsistente; FE-IV sigue siendo consistente.
*
* - Si el p-valor es chico (5% o 1%) => evidencia contra H0 -> usar FE-IV.
* - Si el p-valor es grande         => no hay evidencia fuerte contra H0 -> es razonable RE-IV; 
*   en ese caso RE-IV es una opción razonable, pero igual conviene mirar las diferencias de magnitud entre coeficientes FE-IV y RE-IV (tamaño de efecto).

** En nuestro caso: tenemos un problema para realizar la prueba de hausman ya que no tenemos muchas variables que varien en i y en t, solo lfare y su instrumento. 
**  aun podemos comparar : |b_FE - b_RE| / |b_FE|  para lfare
** pero podemos hacer la prueba a la MUNDLAK

**# Comparacion: prueba basada en especificacion CRE-IV (Mundlak)


/**********************************************************************
* B) VERSIÓN MUNDLAK (HAUSMAN ROBUSTO VIA VARIABLE ADDITION)
*
*  Idea (Mundlak + Wooldridge):
*  - Parametrizar c_i = c + (w̄_i)'ξ + a_i.
*  - Bajo H0 (RE-IV válido): ξ = 0  -> c_i no correlacionado con medias de w_it.
*  - Basta estimar un modelo "correlated random effects" agregando w̄_i
*    y hacer un test de Wald sobre ξ = 0.
*
*  Ventajas:
*  - Se puede usar vce(cluster firm) o cualquier VCE robusto.
*  - El coeficiente de w_it coincide con FE-IV (si se arma bien).
***********************************************************************/
*--------------------------------------------------------------*
* 1. Construir medias temporales de las variables w_it        *
*     (acá solamente: lfare y concen. El resto o solo varian en i o solo varian en t)   
*
*--------------------------------------------------------------*

summ m_concen m_lfare 

*--------------------------------------------------------------*
* C2. Estimar el modelo tipo Mundlak con efectos aleatorios   *
*     y error robusto/cluster                                  *
*     y_it = z_i'γ + w_it'δ + w̄_i'ξ + (a_i + u_it)            *
*
*  - En la especificacion de Mundlak, que se estima por RE-IV, podemos agregar:
*  - dummies temporales y tambien variables que no varian en el tiempo (z_i)
*  - Entonces:
*  - Incluimos i.year como parte de x_it (efectos de tiempo).
*  - Incluimos m_lfare y m_concen como regresores extra: el corazon de la especificacion de Mundlak (con instrumentos, tambien agregamos su media en la especifacion , por eso agregamos a m_concen)
*  - podemos optar por incluir variables z_i como podria ser ldist y ldistsq, por ejemplo. 

/*

Dummies de tiempo en Mundlak: sí, incluirlas, porque así CRE se parece al modelo que realmente vas a reportar.

Variables z_i: Teóricamente, sí conviene incluirlas. 
               Pedagógicamente, se puede decidir incluirlas o no según qué tan alineado quieras que esté el test con el Hausman clásico que corriste antes.
               Lo importante es que expliques: "Este test de Mundlak está chequeando la correlación entre c_i​ y las medias de w_it, condicional en [conjunto de regresores que tengo en el modelo]".
*/

* Si estimamos la especificacion de Mundlak, los coeficientes asociados a w_it (es decir, δ) coinciden para esta estimacion (CRE) con una estimacion por FE para estos coeficientes:
xtivreg lpassen i.year m_lfare m_concen (lfare=concen), re
xtivreg lpassen i.year                  (lfare=concen), fe
** se comprueba que los coeficentes para lfare son identicos (solo es valido para este vector w_it). ¿y si agregamos una variable z_i, por ejemplo, ldist?
xtivreg lpassen i.year m_lfare m_concen (lfare=concen) ldist, re
xtivreg lpassen i.year                  (lfare=concen) ldist, fe
** sigue pasando que los coeficientes para lfare son identicos.

* Test de "hausman" basado en CRE:

*el modelo RE-IV "usual" sin el vector w_bar es justamente el caso restringido ξ=0. 
* Bajo la parametrización c_i = c + w̄_i' ξ + a_i:
*  H0 (RE-IV válido)   : ξ = 0  -> coeficientes de medias temporales = 0
*  H1 (FE-IV preferido): ξ != 0

xtivreg lpassen i.year m_lfare m_concen (lfare=concen), re
estimates store CRE_mundlak_clasico
* Test de Wald conjunto sobre las medias temporales (Hausman)
test m_lfare m_concen

* Interpretación del test de Mundlak:
* - Si no rechazás H0: ξ = 0  -> evidencia consistente con RE-IV.1b;
*   RE-IV "tradicional" es una especificación razonable.
* - Si rechazás H0: ξ != 0  -> medias temporales correlacionadas con c_i;
*   RE-IV clásico es inconsistente; FE-IV (o CRE con Mundlak completo) es preferible.

* Bajo esos supuestos (homocedasticidad + estructura RE-IV estándar), el Wald sobre m_lfare es asintóticamente equivalente al Hausman clásico.
* Eso es lo "limpio algebraicamente" pero poco realista empíricamente.

* El valor agregado de Mundlak es justamente que te permite hacer un Hausman robusto, o sea:
*--------------------------------------------------------------*
xtivreg lpassen i.year m_lfare m_concen (lfare=concen), re vce(cluster id)
estimates store CRE_mundlak_robusto
test m_lfare m_concen

/* En este caso, rechazamos HO, y por tanto elegiriamos el modelo FE-IV. 
*/


**# Disclaimer

/* Asumiendo que lfare es una variable endogena, tiene sentido comparar RE-IV vs FE-IV como acabamos de hacer. 
   En ese contexto, el test de hausman nos resulto problematico, pero no por un asunto asociado a la prueba de hausman, sino que mas bien se debe, 
   a que no contamos con suficientes variables que varien en i y en t, que es de lo que se nutre el test de hausman.
   Pero aun asi, podemos implementar la version de Mundlak, incluso su version robusta, y ahi la conclusion fue clara: debemos usar FE-IV. 
   
   SIN EMBARGO, RECORDAR QUE,
   nosotros habiamos realizado el test hoy temprano y lfare NO es endogena. Pero aun asi hicimos todo esto para fines didacticos.
   Asi que lo correcto en realidad si fuese un caso real de trabajo, seria estimar RE y estimar FE (sin instrumentar nada) y luego hacer un hausman sobre estos dos modelos. 
   De hecho, si hicieramos eso:*/


*-----------------------------------------------------------
* C) Hausman RE vs FE  "clásico" (ojo: no es robusto a vce(cluster))
*-----------------------------------------------------------
xtreg lpassen lfare, re
estimates store RE_clasico
xtreg lpassen lfare, fe
estimates store FE_clasico
hausman FE_clasico RE_clasico, sigmamore

/* Cuando hacemos caso a que lfare no es endogena, y por lo tanto no es necesario estimar con IV, tenemos que el test de hausman nos dice otra cosa.
   Sin IV, cuando comparamos los vectores de coeficientes de ambos estimadores (FE vs RE) (solo para los que varian en i y en t, en este caso, solamente lfare), 
   tenemos que no hay diferencia sistematica entre ambos vectores de coeficientes
   para las variables que varian en i y en t, por lo cual, rechazamos la hipotesis nula de que existe tal diferencia sistematica. 
   Eso nos dice que debemos estimar por RE, ya que es consistente y eficiente cuando no hay diferencias sistematica entre los coeficientes. 
   Conclusion si tuviera este dataset real: estimo por RE como modelo final.
*/






