**# Capitulo 10



clear all  
  
bcuse wagepan, clear
describe

* Declarar la estructura de panel y ordenar observaciones
xtset nr year
sort nr year

 

**# FE: una primera mirada


/********************************************************************/
/*  1. EFECTOS FIJOS (FE)                                */
/********************************************************************/

xtreg lwage educ exper expersq union married black, fe

** En una primera mirada, antes de meternos en detalles:

/*
 a) El F global F(K,N(T-1)-K):    F(4, 545*(8-1)-4) = F(4, 3811)   -----> efectivamente, el F usa N(T-1)-K en lugar de NT-K.
 b) El R2 que nos interesa es el de Within  = 0.1780
 c) Efectivamente ahora veremos un valor diferente de cero para corr(u_i, Xb) = -0.1139   ----> FE permite correlacion entre la heterogeneidad inobservable y los regresores.
*/ 


*************************************************************************
** Mas adelante en este taller profundizaremos acerca de:

/* 
a) que significa corr(u_i, Xb) = -0.1139  y de dónde surge.
b) veremos de donde surgen:
                           sigma_u   .40005389  (desvio estandar asociado a la heterogeneidad inobservable)
                           sigma_e   .35125535  (desvio estandar asociado a los errores idiosincraticos)
                           rho   .56467848

c) e interpretaremos el test F de exclusion de los u_i (heterogeneidad inobservable)
En suma, profundizaremos sobre la estructura de varianzas-covarianzas y otros supuestos en el marco de un modelo FE "clasico".
*/


** Tambien veremos el mismo estimador FE pero con otras estructuras de la matriz de varianzas-covarianzas. (robustas)
** También probaremos otros estimadores FGLS con efectos fijos. 

****************************************************************************

**# Perdemos variables que no varien en t

/* Pero antes tenemos varias cosas que se pueden analizar en un modelo de FE "clasico". */

** Educ y Black se omitieron. Sabemos que el estimador FE omite toda aquella variable que no varie en el tiempo. 
** En este caso, Black no varia y, sorprendentemente tal vez, Educ tampoco tiene variacion en el tiempo (solo entre individuos al igual que Black).
** Por lo tanto, Stata automaticamente las tuvo que suprimir de su estimación para que no se viole la condición de rango completo (supuesto FE.2) sobre el modelo transformado (estimación FE/Within.).
 
xtreg lwage educ exper expersq union married black, fe
xtreg lwage exper expersq union married, fe

** Confirmamos que el modelo es exactamente el mismo. 

/* Ahora bien, no tiene ningun sentido economico estimar una ecuacion para los salarios y que no se pueda controlar por la educacion. 
   No deberia ser el caso, pero esta base de datos tiene la particularidad de que Educacion no cambia en el tiempo para cualquier individuo i. 
   Por lo que en este punto, si todo lo que uno tiene es una base de datos como esta, no presentaria un trabajo usando el modelo de FE. 
   Migraria hacia modelos basados en Random Effects o POOL-MCO. Notar que no seria necesario hacer una prueba de Hausman entre ambos modelos. En casos asi, el sentido economico debe primar. 
   Sin embargo, algo que hemos aprendido es que, los modelos de efectos fijos, si bien nos absorben todo lo que no varia en el tiempo, podemos recuperar algo de informacion de ellos:
   Para lograrlo, se debe considerar interctuar a Educ con dummies temporales */
 
**# Podemos agregar binarias temporales
 
xtreg lwage exper expersq union married d81-d87, fe
  
/* Primero decidimos colocar solamente las dummies temporales, y haremos un test F de exclusion para ellas. 
   A su vez, notar que tenemos 8 años, del 80 al 87, elegimos excluir la dummy del 80: 
			el primer año (80), se excluye en la especificacion en niveles. 
			No tiene nada que ver con la transformacion que hace luego. 
*/

**# Prueba para las binarias temporales

xtreg lwage exper expersq union married d81-d87, fe
test d82 d83 d84 d85 d86 d87
  
/*  al 5% no se rechaza la HO), de hecho tampoco la rechaza con un criterio al 10%. Asi que no deberiamos poner estas dummies temporales en el modelo para estos datos.
   Pero para fines didacticos, vamos a mantenerlas. En ese caso, podemos poner a Educ interactuando con las dummies temporales: 
*/

**# Recuperamos algo: interactuamos variables

 xtreg lwage exper expersq union married c.educ##i.year, fe
 
 /* Como vemos, los coeficientes de las interacciones son todos no significativos y es seguro que si hicieramos un test F de exclusion nos dará que no se rechaza HO). 
    Lo que nos confirma que si el anterior test F ya nos decia que no deberiamos incluir dummies temporales, no deberiamos tampoco incluir estas interacciones. 
	Pero para motivos didacticos lo hicimos.
	
	Si fueran significativas,
	las dummies de anio se interpretan como sigue:  
													g_1981=-0.0714052 ---> como el cambio de nivel en el log-Salario en el anio 1981 respecto de dicho año base, 1980.
	                                                 y asi sucesivamente con cada uno de los restantes años, respecto del año base. 
													  
	mientras que las interacciones se interpretan como sigue: 
	                                                    
													d_1981=0.0049906  ---> mide cómo cambia el efecto de la Educacion sobre el log-Salario en el año 1981 respecto del año base, 1980.
													y asi sucesivamente. 	

*/


**# Elegimos otro año como base

** Yapa: ¿que pasa si quiero establecer otro año base distinto de 1980? 
** con la funcion ib(z_i) se puede establecer el año base que querramos. Por ejemplo 1983:
																									
* Base = año 1983
xtreg lwage exper expersq union married ib1983.year, fe 

*ib(first).year → usa el primer valor como base.
xtreg lwage exper expersq union married ib(first).year, fe 

*ib(last).year → usa el último valor como base.
xtreg lwage exper expersq union married ib(last).year, fe 

*ib(freq).year → usa la categoría (anio en este caso) más frecuente como base (si todos tienen la misma frecuencia, usa el first)
xtreg lwage exper expersq union married ib(freq).year, fe 


************************************************************************************************





