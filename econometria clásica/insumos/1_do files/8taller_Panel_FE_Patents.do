**# Capitulo 10

clear all  
cd  
dir


use patent, clear
describe

/* La idea en este segundo taller de EFECTOS FIJOS es tomar una base e intentar dar con un modelo adecuado usando FE. 
   Asi que en este taller continuamos con el modelo FE/WITHIN clasico. */
   
/* 
Posible modelo con la base patent.dta (para taller de métodos de panel)

1. Descripción rápida de la base

un panel de firmas identificado por:
- cusip  : identificador de la firma
- year   : 1972 a 1981

Variables clave:

(1) Innovación / output de conocimiento
- patents   : patentes solicitadas
- patentsg  : patentes concedidas
- lpat      : log(1 + patents) ---> notar como usa la transformacion ln(1+x) para manejar el tema de la cantidad de 0s en la variable patente medida en niveles. 

(2) Esfuerzo en I+D
- rnd       : gasto en I+D (millones de dólares corrientes)
- lrnd      : log(1 + rnd)
- rndeflt   : gasto en I+D deflactado (base 1972) ---> si tenemos un panel, deberiamos usar la variable deflactada en gastos o ingresos. 
- rndstck   : stock acumulado de I+D (capital de conocimiento)
- lrnd_1, ..., lrnd_5  : rezagos de I+D

(3) Tamaño y desempeño de la firma
- sales, lsales : ventas y su log  ---> pero las ventas solo estan en pesos corrientes... 
- employ        : empleo (en miles)
- stckpr        : precio de la acción
- return        : rentabilidad de la acción (%)

(4) Otras
- merger : =1 si hay una gran fusión
- sic    : sector de 4 dígitos
- y72–y81: dummies de año (además de la variable year)

La historia típica con esta base:
- Estudiar una función de producción de conocimiento a nivel de firma:
  patentes como output (y), I+D como input (x), controlando por tamaño de la firma, fusiones, shocks agregados y heterogeneidad inobservable.

La pregunta económica central:
- ¿Cómo se relacionan el gasto en I+D (y sus rezagos) con la producción de patentes, controlando por tamaño, fusiones y shocks macro (años), usando la estructura de panel?

---------------------------------------------------------------------------------------------------
2. Modelo base: función de producción de conocimiento con efectos fijos

Modelo econométrico:

  lpat_it = β0 + β1*lrnd_it + β2*lsales_it + γ_t + c_i + u_it,

donde:
- i = firma (cusip),
- t = año (1972–1981),
- c_i = heterogeneidad inobservable (capacidad innovadora, cultura, management),
- γ_t = dummies de año.

*/

*-----------------------------------------------------------------------------------------

**# Un modelo FE para patentes

* Declarar estructura de panel
  xtset cusip year
  

* Modelo FE: patentes solicitadas en función del gasto en I+D (millones de dólares corrientes) 
** (ponemos el gasto I+D en MM dolares corrientes porque usaremos tambien a Sales, que esta solo en dolares corrientes),
** tamaño: usaremos a Sales como medida de tamaño de la firma (alternativamente, podriamos usar empleo o probar)
** una variable asociada al rendimiento financiero de la firma: la rentabilidad de la accion. 
** con dummies de año

xtreg lpat lrnd lsales return i.year, fe

** Observar que si bien "sic" nos tienta a intentar agregar controles por industria,
** no podemos hacerlo puesto que no varian por empresa: una empresa que pertenece a una categoria de Sic, no cambia a otra categoria. (Solo podria pasar en un panel muy largo y muy pocas veces)
** de hecho en estos datos eso no pasa nunca, asi que se omite porque justamente, la transformacion within la absorve. 

/*
Interpretando:
  - lrnd: -0.0863698 (p ≈ 0.084)
  -> No es significativo al 5%, sólo marginalmente al 10%.
  -> El signo negativo sugiere que, controlando por lsales (tamanio), dummies temporales y por heterogeneidad inobservable, un mayor I+D corriente no se traduce en más patentes en el mismo año.
  -> Económicamente: consistente con la idea de que la I+D impacta con rezagos.
     Sería natural probar especificaciones con lrnd rezagado o con rndstck (stock de I+D) en lugar del flujo corriente.

*/

** con stock de I+D en lugar de flujo corriente (tengo duda acerca de si esta en nivel o en log esta variable):
xtreg lpat rndstck lsales return i.year, fe



/*
---------------------------------------------------------------------------------------------------
3. Versión con rezagos de regresor exogeno: I+D contemporánea y rezagada


La idea:
- Medir efectos de corto y largo plazo de la I+D sobre la producción de patentes.
- La suma (β0 + β1 + ... + β5) es una medida del efecto acumulado de I+D sobre patentes a lo largo de varios años.

Discusión posible:
- ¿Los efectos de la I+D son inmediatos o se materializan con rezago?
- ¿Qué sugiere la evidencia sobre la "vida útil" de la I+D en la generación de patentes?

*/

xtreg lpat lrnd lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5 lsales return i.year, fe 

/*
- Todos los coeficientes salen negativos, pero salvo el contemporáneo y el quinto rezago, ninguno es significativo individualmente.
- NO conviene interpretar cada βk "uno a uno" como efecto causal bien identificado: hay fuerte riesgo de multicolinealidad entre 
  lrnd,  lrnd_1, ..., lrnd_5 (la I+D de años consecutivos está muy correlacionada).
- En presencia de tanta correlación entre regresores, los coeficientes individuales se vuelven inestables; los signos y niveles exactos pueden
  estar muy distorsionados aunque el modelo global tenga buen ajuste.

 Recomendación práctica 
- Mirar tests conjuntos:
    test lrnd lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5  para ver si la I+D "en bloque" afecta al patentamiento.
- Explorar especificaciones más parsimoniosas, por ejemplo:
    * Menos rezagos (por ej. 0–2 en lugar de 0–5),
    * O usar un stock de I+D (rndstck) en lugar del flujo y sus 5 rezagos,
	
 Dummies de año
- Sólo aparecen 78, 79, 80, 81 
- Casi todas son poco significativas salvo 1981, que muestra un efecto fuertemente negativo:
    year81 ≈ -0.83  (p ≈ 0.000)
  -> Para una firma dada y dados los controles, 1981 tiene un nivel de patentes mucho menor respecto al año base.
	*/


xtreg lpat lrnd lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5 lsales return i.year, fe 
test lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5

/*
Interpretación:

1) Significado de la prueba conjunta

- Aunque muchos coeficientes individuales (lrnd_1, ..., lrnd_4) no sean significativos en sus tests t por separado, lo que H0 plantea aquí es:
    "Dado lrnd (I+D contemporánea) y el resto de controles, ¿los rezagos de I+D en conjunto NO aportan nada para explicar lpat?"

- Como p = 0.0075 < 0.01, se rechaza H0 al 1%.
  -> Concluimos que, CONJUNTAMENTE, los rezagos de I+D sí tienen poder explicativo sobre lpat, más allá del efecto de lrnd contemporánea.

- Ojo: en la restricción NO entra lrnd (t), solo lrnd_1,...,lrnd_5. Es decir, estamos testeando el efecto adicional de la historia de I+D
     (los 5 años previos) condicionando en el gasto de I+D del año t.

2) Implicancias económicas

- Resultado consistente con una historia de "efectos dinámicos" o de "acumulación" en el proceso de innovación:
    * La producción de patentes en t no depende sólo de la I+D en t, sino también de la trayectoria de I+D en los años previos.
    * Aunque cada lag por separado tenga un coeficiente impreciso, el conjunto de lags aporta información relevante.

- Sin embargo, hay que ser prudente:
    * Los lags de I+D están muy correlacionados entre sí -> multicolinealidad.
    * Esto hace que los coeficientes individuales sean ruidosos, y el signo de cada β_k no deba sobreinterpretarse.
    * La prueba F conjunta es más estable que los t individuales, pero la sobrecarga de lagged variables en un panel corto sigue siendo un  problema de especificación.

*/

* Modelo de efectos fijos con una matriz de var-cov tipo "sandwich" (robusta)

xtreg lpat lrnd lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5 lsales return i.year, fe vce(cluster cusip)
test lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5


*-----------------------------------------------------------------------------------------


* Modelo de efectos fijos con errores AR(1)
 xtregar lpat lrnd lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5 lsales return y72-y81, fe
test lrnd_1 lrnd_2 lrnd_3 lrnd_4 lrnd_5
 
 
 
 *--------------------------------------------------------------------------------------
 

