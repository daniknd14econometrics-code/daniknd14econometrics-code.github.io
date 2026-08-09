# AGENTS.md

## Propósito de esta sección

Este AGENT fija el contrato editorial específico para `econometria-clasica`.

La sección `econometria-clasica` es una sección de:

- lectura econométrica
- comparación de especificaciones
- interpretación sobria
- criterio metodológico aplicado

No debe tratarse como una sección de causalidad por defecto.

## Relación con el playbook maestro

Seguir obligatoriamente `docs/qmd-curation-playbook.md`.

Regla de precedencia:
- si una regla general del playbook entra en tensión con una regla específica de `econometria-clasica`, prevalece la regla específica de `econometria-clasica` para esta sección.

## Alcance de este AGENT

Estas reglas gobiernan piezas de `econometria-clasica`.

No deben extrapolarse automáticamente a:
- `causalidad` (donde cambia el objetivo inferencial)
- futuros bloques de `ML` (donde el foco es predicción y desempeño fuera de muestra)

## Lenguaje sustantivo por defecto

En `econometria-clasica`, preferir por defecto:

- relación
- cambio estimado
- evidencia
- contraste entre especificaciones
- lectura econométrica dominante

Solo usar lenguaje causal si el diseño particular del caso lo justifica de forma explícita y defendible.
No copiar automáticamente el lenguaje de `causalidad`.

## Regla de producción

No producir una pieza pública (`.qmd`) directamente desde do-file/log sin lectura privada previa.

Antes de redactar o editar, debe existir diagnóstico privado que deje claro:

- pregunta del caso
- variable resultado y comparaciones centrales
- conjunto de especificaciones comparadas
- lectura dominante posible
- afirmaciones que sí y que no corresponden
- objeto final de decisión

## Tipos de pieza esperables

Esta sección admite, en línea con el playbook:

1. hallazgo sustantivo
2. comparación metodológica
3. evidencia débil pero informativa
4. pieza principalmente técnica

La clasificación debe guiar la narrativa y el cierre.

## Regla narrativa central

Toda pieza pública debe verse como portfolio profesional, no como apunte ni log comentado.

Debe incluir:

- pregunta clara
- lectura dominante
- cierre honesto

La técnica sostiene la historia; no la reemplaza.

## Datos y variables

- Definir variables en lenguaje público y claro.
- Evitar sintaxis interna como puerta de entrada visual.
- Ubicar detalles técnicos en bloque de “Datos y variables”, sin crudeza de log.

## Tablas, gráficos y objeto de decisión final

- Toda pieza debe tener objeto de decisión final visible (tabla, bloque o cierre de decisión).
- Tablas públicas: cortas, legibles, comparativas y orientadas a lectura/decisión.
- Usar rótulos públicos; evitar semántica interna de taller en etiquetas visibles.
- Expandir siglas ambiguas para lector externo cuando corresponda.
- Mantener convención de inferencia consistente (incluyendo bootstrap cuando sea la convención elegida para reportar).
- No sobredimensionar contrastes auxiliares cuando no son el núcleo del mensaje.
- Gráficos solo si agregan comprensión real; nunca por decoración.

## Reglas visuales específicas de econometría clásica

No asumir “un gráfico por taller”.  
En este módulo, muchos talleres no son aptos para una familia visual dada y eso no implica que estén incompletos.

### Familia 1: mini gráfico punto + IC 95%

Usar cuando hay comparación binaria limpia o especificación dominante clara.

Casos validados:

- `T1` (2 estimaciones)
- `T5` (1 estimación)
- `T11` (2 estimaciones)
- `T13` (2 estimaciones)
- `T14` (2 estimaciones)

Reglas mínimas:

- pequeño, horizontal y sobrio
- sin nota al pie ni leyenda
- sin grilla pesada
- 1 o 2 estimaciones como máximo
- línea vertical en 0

### Familia 2: síntesis de trayectoria metodológica / decisión secuencial

Usar cuando la lectura central no es “un coeficiente único” sino una transición de enfoque.

Casos consolidados:

- implementados/validados: `T9`, `T15`
- explorados para simplificación de lenguaje: `T2`, `T4`, `T6`, `T7`

Reglas mínimas:

- SVG simple, liviano y horizontal
- texto breve para lector externo
- foco en qué se compara, qué cambia y qué decisión queda
- no coronar modelos por un test aislado

### Familia 3: desplazamientos de probabilidad / categorías

Usar cuando la lectura dominante es de probabilidades, categorías, outcomes ordinales o redistribución entre resultados.

Subfamilias y orden de pilotos auditado:

- Subfamilia A (multiclase/ordinal): `T19` como primer piloto, `T18` segundo, `T16` después
- Subfamilia B (caso puente binario): `T12` al final

Regla clave:

- no imponer un formato único rígido; elegir subfamilia según objeto de decisión

### Casos especiales fuera de familia principal

- `T3`: no linealidad (familia propia)
- `T8`: bloque dinámico / rezagos (familia propia)
- `T10`, `T17`, `T20`: mantener como notas técnicas/no públicas por ahora

### Regla de lenguaje visual y legibilidad pública

- Evitar código interno o jerga en tarjetas/SVG (`AR(1)`, `LM`, `Cov(x_it,c_i)`, `D.educ`, `chi2(...)`, `within`, etc.).
- Traducir nociones técnicas a formulación pública cuando sean necesarias.
- Aprendizaje consolidado: el principal riesgo de esta familia fue sobrecarga de jerga; `T9` quedó mejor calibrado, mientras `T4` y `T15` exigieron simplificación adicional.
- En la misma línea de simplificación, `T2`, `T6` y `T7` se auditan con el mismo criterio fino de legibilidad.

### Regla de categorías públicas vs códigos internos

- En tablas, captions, gráficos y SVG, mostrar primero el significado conceptual de la categoría.
- Evitar que `0/1`, `choice=1`, `prftshr=1` o códigos equivalentes sean la etiqueta pública principal.
- Si el número tiene sentido sustantivo, acompañarlo por nombre conceptual.
- Prioridad de control en este módulo: alta en `T16`, `T18`, `T19`; media en `T12`, `T13`, `T14`, `T15`.

### Regla técnica para assets visuales del módulo

- Preferir SVG simple y liviano para recursos editoriales.
- Si un SVG exportado desde Stata queda pesado/complejo, usar PNG.
- `.gph` no es formato de publicación web.
- Revisar tildes/eñes y codificación en texto visible del SVG antes de cerrar.

### Regla de expansión del módulo

- No asumir que todos los talleres deben tener gráfico.
- Expandir por tandas solo después de validar pilotos limpios por familia.
- Si un caso no entra limpio en familia 1, 2 o 3, no forzarlo.

## Tono y estilo

Usar tono:

- profesional
- sobrio
- externo
- preciso

Evitar:

- metadiscurso interno
- lenguaje coloquial
- sobreactuación inferencial
- afirmaciones más fuertes que la evidencia y el diseño

## Regla operativa para Codex

Cuando trabajes en `econometria-clasica`:

- primero identificar objetivo econométrico de la pieza
- luego definir comparación dominante de especificaciones
- después construir cierre con objeto de decisión final
- no trasladar lenguaje causal por reflejo
- no convertir la pieza en cronología de comandos/tests
- no forzar familia visual cuando la decisión metodológica del taller pide otro recurso o ninguno

Si existe duda de interpretación, preferir formulación sobria y explícita en alcance.

## Sincronización entre árboles (econometría)

Cuando la pieza también vive en `portfolio-site/econometria`:

- replicar assets cuando corresponda
- mantener coherencia de `.qmd` entre espejo y canónico
- renderizar y verificar en ambos árboles
