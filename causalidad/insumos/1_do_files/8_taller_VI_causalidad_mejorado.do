******************************************************************************************************************************
******************************************** MICROECONOMETRIA APLICADA *******************************************************
******************************************************************************************************************************

*******************
*** CURSO 2021
*** TALLER 2
*** VARIABLES INSTRUMENTALES
*** ANGRIST Y KRUEGER (1991)
*** VERSION AMPLIADA Y ORDENADA
*******************

clear all
set more off

*==================================================================================================*
* 0. PAQUETES Y CONFIGURACION                                                                      *
*==================================================================================================*

cap which ivreg2
if _rc ssc install ivreg2

cap which ranktest
if _rc ssc install ranktest

cap which overid
if _rc ssc install overid

* Ajustar la ruta si hiciera falta.
cd "C:/Users/Equipo/OneDrive/Desktop/Notebook HP NEGRA/POSGRADO/MicroEconometría Aplicada/Talleres y Prácticos/1. Talleres/Directorio común bases"

* Abrir la base
use base_2, clear

*==================================================================================================*
* 1. RENOMBRE, LIMPIEZA Y PREPARACION BASICA                                                       *
*==================================================================================================*

rename v1  edad
rename v2  edadT
rename v4  educ
rename v5  ENOCENT
rename v6  ESOCENT
rename v9  logSalSem
rename v10 casado
rename v11 MIDATL
rename v12 MT
rename v13 NEWENG
rename v16 censo
rename v18 TdN
rename v19 raza
rename v20 urbano
rename v21 SOATL
rename v24 WNOCENT
rename v25 WSOCENT
rename v27 AdN

capture drop v8

describe
summarize

* Estandarizo algunas variables temporales
tab censo
tab edadT 
tab edadT censo
* mejorar edadT si el censo es de 1980
replace edadT = edadT - 1900 if censo == 80
tab edadT

tab AdN
*mejorar AdN para 1930-1949 
replace AdN   = 1900 + AdN if AdN < 100
tab AdN

* genero variable al cuadrado correcta
gen edadTQ = edadT^2

* Cohortes por decadas (solo con fines descriptivos)
gen COHORTE = .
replace COHORTE = 2029 if inrange(AdN,1920,1929)
replace COHORTE = 3039 if inrange(AdN,1930,1939)
replace COHORTE = 4049 if inrange(AdN,1940,1949)

label define coh_lbl 2029 "1920-1929" 3039 "1930-1939" 4049 "1940-1949"
label values COHORTE coh_lbl

tab COHORTE
summarize edad edadT edadTQ educ logSalSem TdN AdN

global muestra "inrange(AdN,1930,1939)"
*==================================================================================================*
* 2. DUMMIES E INTERACCIONES                                                                       *
*==================================================================================================*


* Limpiar globals para evitar duplicados si re-ejecutas este bloque
global yob_controls ""
global qob_excl     "qob_2 qob_3 qob_4"
global z_yobqob     ""

* Dummies por año de nacimiento (1930-1939)
forvalues yy = 1930/1939 {
    capture confirm variable yob_`yy'
    if _rc {
        gen yob_`yy' = (AdN == `yy')
    }
}

* Dummies por trimestre de nacimiento
forvalues q = 1/4 {
    capture confirm variable qob_`q'
    if _rc {
        gen qob_`q' = (TdN == `q')
    }
}

* Controles por año de nacimiento: se omite 1930 como categoría base
forvalues yy = 1931/1939 {
    global yob_controls "$yob_controls yob_`yy'"
}

* Instrumentos simples: dummies de trimestre (se omite qob_1)
global qob_excl "qob_2 qob_3 qob_4"

* Instrumentos ricos de Angrist-Krueger: interacciones trimestre x año de nacimiento
* Se dejan los tres primeros trimestres; el cuarto queda como base
foreach q in 1 2 3 {
    forvalues yy = 1930/1939 {
        capture confirm variable z_q`q'_`yy'
        if _rc {
            gen z_q`q'_`yy' = qob_`q' * yob_`yy'
        }
        global z_yobqob "$z_yobqob z_q`q'_`yy'"
    }
}


*==================================================================================================*
* 3. LOGICA DESCRIPTIVA DE LA ESTRATEGIA IV                                                        *
*==================================================================================================*

sort AdN TdN
egen AdNTdN = group(AdN TdN)

bysort AdNTdN: egen prom_edu = mean(educ)
bysort AdNTdN: egen prom_sal = mean(logSalSem)

* Figura descriptiva de la "primera etapa"
twoway connected prom_edu AdNTdN if inrange(AdN,1930,1939), ///
    title("Educacion promedio por anio-trimestre de nacimiento") ///
    ytitle("Educacion promedio") xtitle("Grupo anio-trimestre") name(fs, replace)

* Figura descriptiva de la "forma reducida"
twoway connected prom_sal AdNTdN if inrange(AdN,1930,1939), ///
    title("Log salario promedio por anio-trimestre de nacimiento") ///
    ytitle("Log salario promedio") xtitle("Grupo anio-trimestre") name(rf, replace)

* Instrumento: Promedios simples por trimestre 1 versus resto de trimestres
gen Z = (TdN == 1)

summarize educ if $muestra & Z == 0
summarize educ if $muestra & Z == 1

tabstat educ if $muestra, by(Z) stat(mean sd n)


summarize logSalSem if $muestra & Z == 0
summarize logSalSem if $muestra & Z == 1

tabstat logSalSem if $muestra, by(Z) stat(mean sd n)

* Comentario conceptual:
* Si Z mueve educacion, hay una primera senal de relevancia.
* Si Z mueve salarios, hay una primera senal de forma reducida.
* Todavia no alcanza para concluir nada formal sobre identificacion.

*==================================================================================================*
* 4. ESTIMADOR DE WALD Y 2SLS MAS BASICO                                                           *
*==================================================================================================*

*------------------------------------------*
* 4.1 MCO base y MCO robusto               *
*------------------------------------------*
regress logSalSem educ if $muestra
regress logSalSem educ if $muestra, vce(robust)

*------------------------------------------*
* 4.2 Forma reducida y primera etapa       *
*------------------------------------------*
regress logSalSem Z if $muestra, vce(robust)
regress educ Z if $muestra, vce(robust)

*------------------------------------------*
* 4.3 2SLS con un solo instrumento binario *
*------------------------------------------*
ivregress 2sls logSalSem (educ = Z) if $muestra
ivregress 2sls logSalSem (educ = Z) if $muestra, vce(robust)

*------------------------------------------*
* 4.4 2SLS "a mano" para ver la logica     *
*------------------------------------------*
regress educ Z if $muestra
capture drop educ_hat_Z
predict educ_hat_Z, xb

regress logSalSem educ_hat_Z if $muestra		

* IMPORTANTE:
* El coeficiente coincide con 2SLS, pero los errores estandar de hacer "MCO en dos etapas"
* no son correctos porque no propagan la incertidumbre de la primera etapa.

*------------------------------------------*
* 4.5 ivreg2 corrige la inferencia         *
*------------------------------------------*
ivreg2 logSalSem (educ = Z) if $muestra
ivreg2 logSalSem (educ = Z) if $muestra, robust first

* Con un solo instrumento excluido para una sola endogena el modelo queda exactamente identificado.
* Por eso, en este caso, NO hay test de sobreidentificacion.

*==================================================================================================*
* 5. DISTINTAS FORMAS DE DEFINIR EL INSTRUMENTO                                                    *
*==================================================================================================*

*------------------------------------------*
* 5.1 Usando TdN como variable numerica    *
*------------------------------------------*
ivreg2 logSalSem (educ = TdN) if $muestra, robust first

* Ojo: tratar TdN como numerica impone una estructura lineal muy fuerte
* entre pasar del trimestre 1 al 2, del 2 al 3 y del 3 al 4.

*------------------------------------------*
* 5.2 Usando dummies de trimestre          *
*------------------------------------------*
ivreg2 logSalSem (educ = $qob_excl) if $muestra, robust first

* Aqui la primera etapa ya no obliga a que el efecto del trimestre sea lineal.
* Se estima un desplazamiento distinto respecto del trimestre base.

*==================================================================================================*
* 6. ESPECIFICACIONES CON CONTROLES E INSTRUMENTOS RICOS                                           *
*==================================================================================================*

*------------------------------------------*
* 6.1 MCO con controles                     *
*------------------------------------------*
regress logSalSem educ $yob_controls if $muestra
regress logSalSem educ edad edadTQ $yob_controls if $muestra, vce(robust)

*------------------------------------------*
* 6.2 IV con interacciones QOB x YOB        *
*------------------------------------------*
* Exogenas incluidas: edad, edad^2, dummies de anio de nacimiento
* Endogena: educ
* Instrumentos excluidos: interacciones trimestre x anio de nacimiento
ivreg2 logSalSem $yob_controls (educ = $z_yobqob) if $muestra, robust first
ivreg2 logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra, robust first

* Esta especificacion respeta mejor la logica del paper:
* los anios de nacimiento (yob_controls) quedan como controles incluidos,
* mientras que las interacciones trimestre x anio de nacimiento (z_yobqob) proveen la variacion exogena.

*==================================================================================================*
* 7. DIAGNOSTICOS FORMALES: ENDOGENEIDAD, RELEVANCIA Y VALIDEZ                                     *
*==================================================================================================*

/****************************************************************************************************
IMPORTANTE:
- Test de endogeneidad:
      pregunta si educ realmente necesita ser tratada como endogena
      o si MCO podria alcanzar.
- Test de sobreidentificacion:
      NO pregunta eso.
      Pregunta, una vez que ya decidiste instrumentar educ, si los
      instrumentos excedentes parecen compatibles con exogeneidad.
- Test de primera etapa / weak IV:
      pregunta si los instrumentos tienen fuerza suficiente para mover educ.
No conviene confundir estas tres preguntas porque responden a cosas distintas.
****************************************************************************************************/

*------------------------------------------*
* 7.1 Test de endogeneidad (DWH)           *
*------------------------------------------*

* Version mas directa
ivregress 2sls logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra
estat endogenous

* Version "manual" tipo Hausman clasico (no robusta)
regress logSalSem educ edad edadTQ $yob_controls if $muestra
estimates store ols_nr

ivregress 2sls logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra
estimates store iv_nr

hausman iv_nr ols_nr, sigmamore

* Lectura:
* - p-valor chico  -> evidencia de endogeneidad -> preferir IV.
* - p-valor grande -> no se rechaza exogeneidad -> MCO podria bastar.

* en este caso, MCO bastaría. (pero MCO no nos sirve para nuestra identificacion causal)

*------------------------------------------*
* 7.2 Relevancia / fuerza de instrumentos  *
*------------------------------------------*

* Diagnosticos integrados
ivregress 2sls logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra, vce(robust) first
estat firststage

* Primera etapa "a mano": test conjunto de instrumentos excluidos
regress educ edad edadTQ $yob_controls $z_yobqob if $muestra, vce(robust)
test $z_yobqob

* Version mas completa con ivreg2
ivreg2 logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra, robust first

* Comentario:
* - Bajo homocedasticidad mirar Cragg-Donald y Stock-Yogo.
* - Con robustez a heterocedasticidad mirar Kleibergen-Paap.
* Si la primera etapa es debil, la inferencia IV convencional se vuelve fragil.

* en este caso, el instrumento es débil (Z mueve muy poco a X=educ).

*------------------------------------------*
* 7.3 Sobreidentificacion / validez IV     *
*------------------------------------------*

* Ahora SI tiene sentido porque estamos sobreidentificados:
* hay una endogena y muchos instrumentos excluidos.
ivregress 2sls logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra, vce(robust)
estat overid

* Repeticion con ivreg2 + overid
ivreg2 logSalSem edad edadTQ $yob_controls  (educ = $z_yobqob) if $muestra, robust
overid

* Lectura:
* - p-valor grande -> no se rechaza la validez conjunta de los instrumentos excedentes.
* - p-valor chico  -> al menos uno de los instrumentos excedentes parece problematico.


*==================================================================================================*
* 8. EXTRA: GMM EN DOS ETAPAS                                                                      *
*==================================================================================================*

* Con heterocedasticidad, GMM2S puede ser mas eficiente asintoticamente que 2SLS.
ivreg2 logSalSem edad edadTQ $yob_controls  (educ = $z_yobqob) if $muestra, robust

ivreg2 logSalSem edad edadTQ $yob_controls (educ = $z_yobqob) if $muestra, robust gmm2s

* La comparacion interesante no es tanto del coeficiente puntual,
* sino de los errores estandar y de la matriz de ponderacion utilizada.

*==================================================================================================*
* 9. EXTRA: PRUEBAS DE HIPOTESIS SOBRE EL PARAMETRO IV                                             *
*==================================================================================================*

ivreg2 logSalSem edad edadTQ $yob_controls  (educ = $z_yobqob) if $muestra, robust

* H0: el retorno de un anio adicional de educacion es 0
test educ = 0

* H0: el retorno es, por ejemplo, 10%
test educ = 0.10

* H0: el retorno es, por ejemplo, 7%
test educ = 0.07

* Intervalo de confianza y lectura puntual del parametro
lincom educ

*==================================================================================================*
* 10. EXTRA: PUENTE CON PANEL IV                                                                   *
*==================================================================================================*

/****************************************************************************************************
Este taller es de corte transversal, pero varias ideas se trasladan casi uno a uno al contexto panel.

1) Si la variable es endogena en panel, se puede usar FE-IV o RE-IV:
       xtivreg y x (d = z), fe vce(cluster id)
       xtivreg y x (d = z), re vce(cluster id)

2) La logica econometrica no cambia:
       - endogeneidad de d,
       - relevancia de z,
       - validez de instrumentos excedentes.

3) Lo que si cambia es el estimador:
       - en FE-IV la identificacion usa la variacion within;
       - en RE-IV entra una transformacion quasi-demeaned.

4) Una estrategia muy util en panel, cuando queres mas diagnosticos,
   es transformar los datos (within o quasi-demeaning) y luego correr ivreg2
   sobre las variables transformadas. Eso permite recuperar pruebas de primera etapa,
   overid, KP, etc., de manera mas transparente.

Esto recoge la intuicion central del taller de panel IV, sin romper el flujo
de este taller de causalidad en seccion cruzada.
****************************************************************************************************/

* FIN DEL DO-FILE
