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

Si existe duda de interpretación, preferir formulación sobria y explícita en alcance.
