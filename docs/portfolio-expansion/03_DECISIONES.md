# Decisiones de expansión del portfolio

## Navegación principal objetivo

- Inicio
- Investigación
- Econometría
- Causalidad
- Machine Learning
- Sobre mí

## Investigación

Los proyectos extensos de investigación no se presentan como talleres.

El proyecto TIC-productividad / shift-share tendrá posteriormente una página/proyecto destacado propio.

## Causalidad

Dos niveles:

### Diseños causales fundamentales

Incluye:

- matching;
- PSM;
- IPWRA;
- IV;
- RDD;
- DiD básico.

#### RDD01

- Pieza pública principal: `Elecciones reñidas y escolarización femenina: evidencia local con RDD`.
- Ubicación: después de IV y antes del futuro bloque de DiD básico.
- Lectura del resultado: efecto local positivo de magnitud sustantiva, con evidencia sugestiva bajo inferencia robusta (`p ≈ 0,076`) y sin conclusión definitiva al 5%.
- Objeto central: tabla que contrasta la reconstrucción lineal local con la estimación MSE-óptima y corrección robusta de sesgo.
- Visuales públicos: `rdplot` local y diagnóstico compacto de densidad; la condición sharp se comunica como métrica, no como gráfico separado.
- Estado: cerrada, implementada y comprometida en el repositorio.

#### DiD clásico e inferencia

- Arquitectura aprobada: dos piezas. Talleres 1 + 2 forman una pieza integrada de DiD clásico; Taller 3 queda reservado para una pieza autónoma posterior sobre inferencia y BDM.
- Primera pieza: `Difference-in-Differences clásico: de la doble diferencia a la comparabilidad condicional`.
- Aplicación principal: Nueva Jersey / Pensilvania, con DiD 2×2 sobre empleo FTE.
- Extensión metodológica: NSW, tendencias paralelas condicionales, ponderación de Abadie y soporte común.
- La progresión del bloque será: DiD canónico → comparabilidad condicional → inferencia clásica / BDM → crisis moderna de TWFE → soluciones modernas.
- Estado: DID01 y BDM01 cerradas e implementadas; la expansión continúa en el bloque DiD moderno.

#### BDM01

- Pieza autónoma: `Cuando DiD encuentra efectos que no existen: correlación serial e inferencia`.
- Objeto central: calibración de la inferencia bajo tratamientos placebo persistentes y correlación serial del outcome.
- Comparación dominante: 44% de rechazo con OLS convencional frente a un nivel nominal de 5%; no establecer rankings finos entre tasas cercanas al nominal con solo 100 repeticiones.
- Visuales públicos: persistencia residual en los primeros tres rezagos y tasas de rechazo bajo el nulo por método.
- Distinción metodológica obligatoria: BDM trata un problema de inferencia; la crisis moderna de TWFE agrega problemas de identificación e interpretación bajo adopción escalonada y heterogeneidad.
- Estado: cerrada e implementada.

### Difference-in-Differences moderno

El portal de Causalidad se organiza en dos bloques: `Fundamentos y diseños de inferencia causal`, que conserva las ocho piezas publicadas, y `Difference-in-Differences moderno`, con subportal propio.

El subportal organiza la transición DiD canónico → problemas de TWFE bajo adopción escalonada y heterogeneidad → diagnósticos → estimadores modernos, sin anticipar piezas todavía no curadas.

#### Crisis moderna de Difference-in-Differences

- Los Módulos 4, 5 y 6 tendrán piezas públicas autónomas dentro de este bloque.
- DID-M04 abre la secuencia con `Cuando los tratados se vuelven controles: adopción escalonada y la descomposición de TWFE`.
- Su objeto central es mostrar que TWFE combina múltiples DiD 2×2 y puede utilizar cohortes ya tratadas como controles bajo adopción escalonada.
- La descomposición de Goodman–Bacon funciona como diagnóstico del coeficiente; no se presenta como estimador alternativo ni como solución a la heterogeneidad dinámica.
- La distinción con BDM01 es sustantiva: clustering trata la inferencia, pero no corrige comparaciones causales contaminadas.
- DID-M05 continúa con `Cuando TWFE cambia el signo: pesos negativos y heterogeneidad en Difference-in-Differences`.
- Su objeto central es la agregación de efectos grupo-período con pesos que pueden ser negativos y, bajo heterogeneidad, producir estimaciones fuera del rango de los efectos verdaderos.
- La aplicación WAGEPAN debe mantener una lectura cauta: la masa negativa es pequeña, WAS reduce la estimación y el primer placebo limita una interpretación causal fuerte.
- DID-M06 cierra la crisis moderna con `Cuando los leads mezclan efectos pos-tratamiento: contaminación dinámica en event studies TWFE`.
- Su objeto central es mostrar que una etiqueta de tiempo relativo no define por sí sola el estimando: leads y lags TWFE pueden mezclar cohortes y otros momentos de exposición.
- El contraste interaction-weighted se utiliza para precisar la propiedad que se desea recuperar, sin convertir la pieza en una revisión general de soluciones modernas.
- Con DID-M04, DID-M05 y DID-M06, el bloque de crisis moderna queda conceptualmente completo; el bloque de soluciones modernas continúa pendiente.

#### Soluciones modernas

- DID-M07 inaugura el bloque con `Efectos por cohorte y período: Callaway–Sant’Anna para adopción escalonada`.
- Su objeto central es `ATT(g,t)`: identificar efectos por cohorte y período mediante controles válidos y agregarlos después con ponderaciones explícitas.
- La especificación principal utiliza DR-IPW y condados nunca tratados; las unidades todavía no tratadas funcionan como sensibilidad.
- Los promedios global simple y por cohorte se presentan como estimandos legítimos diferentes, no como una competencia con ganador automático.
- DID-M08 continúa con `Imputar el contrafactual: Borusyak–Jaravel–Spiess en Difference-in-Differences`.
- Su objeto central es la brecha tratada imputable: estimar `Y(0)` exclusivamente con observaciones no tratadas, imputarlo para las tratadas y agregar después los efectos según la pregunta causal.
- La pieza distingue imputabilidad de información efectiva; los horizontes `K=2` y `K=3` no se publican como resultados inferenciales ni se representan como efectos cero.
- Los visuales públicos muestran el flujo observado–contrafactual–brecha y un event study compacto con dos períodos previos, `K=0` y `K=1`.

## Econometría

Organización conceptual objetivo:

1. Modelos lineales, panel e IV.
2. Modelos no lineales y variables dependientes especiales.
3. Inferencia, estimación y simulación.
4. Panel avanzado.
5. Métodos no paramétricos y semiparamétricos.

Estas categorías son curatoriales. No obligan a que cada taller tenga pieza propia.

## Regla de duplicación temática

Si un nuevo taller trata un tema ya presente en el portfolio, no crear automáticamente una segunda pieza.

Evaluar si:

- sustituye a la anterior;
- permite actualizarla;
- se integra;
- ofrece una aplicación sustantivamente distinta;
- o no amerita publicación.
