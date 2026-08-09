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
- Estado de la primera pieza: cerrada e implementada. BDM01 queda activa como siguiente pieza autónoma del bloque clásico.

### Difference-in-Differences moderno

Debe tener un subportal propio dentro de Causalidad.

Debe poder organizar la transición: DiD clásico → problemas del TWFE → crisis moderna → diagnósticos → soluciones/estimadores modernos.

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
