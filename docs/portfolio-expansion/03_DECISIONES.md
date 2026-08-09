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
