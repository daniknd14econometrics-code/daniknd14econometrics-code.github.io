# AGENTS.md

## Alcance de este AGENT

Este archivo regula la producción pública de `portfolio-site/econometria`.

Debe leerse junto con:
- `docs/qmd-curation-playbook.md` (contrato maestro)
- `econometria-clasica/AGENTS.md` (contrato específico de sección)

Regla de precedencia:
- si una regla general del playbook entra en tensión con una regla específica de `econometria-clasica`, prevalece la regla específica de sección en esta carpeta.

Estas reglas son específicas de econometría clásica y no deben extrapolarse automáticamente a `causalidad` ni a futuros bloques de `ML`.

## Regla operativa de canonicidad (.qmd)

- Fuente canónica: portfolio-site/econometria/piezas/*.qmd
- Copia espejo: econometria-clasica/01_portfolio/qmd/*.qmd
- Edición solo en la fuente canónica.
- Sincronización unidireccional explícita hacia la copia espejo.
- No editar manualmente en paralelo ambas rutas.
## Regla principal

Las piezas públicas aquí deben verse como trabajo profesional curado.
No producir estilo de taller, apunte de clase ni log comentado.

`econometria-clasica` sigue siendo benchmark de curaduría formal del portfolio, pero eso no implica adoptar automáticamente lenguaje causal.

## Estructura esperada de una pieza pública

Orden recomendado:

1. pregunta central clara
2. por qué la comparación econométrica importa
3. especificaciones/métodos comparados
4. resultado principal
5. lectura econométrica dominante
6. cierre honesto con alcance

## Lenguaje y lectura inferencial

En esta carpeta, por defecto usar:

- relación
- cambio estimado
- evidencia
- comparación de especificaciones

Solo usar causalidad si el diseño del caso lo justifica explícitamente.

## Datos y variables

- Incluir bloque claro de “Datos y variables” cuando sea necesario para legibilidad.
- Definir unidad de análisis, resultado, regresores/variables clave y población analizada.
- Evitar sintaxis interna como primera capa visual.

## Tablas, gráficos e inferencia

- Tabla principal obligatoria con función clara de lectura/decisión.
- Rótulos públicos y comprensibles; no etiquetas internas de taller.
- Expandir siglas ambiguas para lector externo.
- Mantener convención consistente de inferencia (incluyendo bootstrap cuando corresponda).
- Evitar sobredimensionar contrastes auxiliares.
- Usar gráficos solo cuando agregan comprensión real.

## Reglas visuales específicas de econometría clásica

No aplicar formato único por inercia: los gráficos son opcionales y solo entran si mejoran lectura pública.

### Familia 1: mini gráfico punto + IC 95%

Aplicar en comparaciones binarias limpias o cuando existe especificación dominante clara.

Casos validados:

- `T1` (2 estimaciones)
- `T5` (1 estimación)
- `T11` (2 estimaciones)
- `T13` (2 estimaciones)
- `T14` (2 estimaciones)

Estándar visual:

- pequeño, horizontal y sobrio
- sin leyenda ni nota al pie
- máximo 1-2 estimaciones
- línea vertical en 0

### Familia 2: síntesis de trayectoria metodológica / decisión secuencial

Aplicar cuando la pieza depende de transición metodológica y no de un coeficiente único.

Casos consolidados:

- implementados/validados: `T9`, `T15`
- explorados para simplificación: `T2`, `T4`, `T6`, `T7`

Estándar visual:

- SVG simple, liviano y horizontal
- texto corto en lenguaje externo
- foco en comparación, cambio y decisión
- evitar jerga interna de taller

### Familia 3: desplazamientos de probabilidad / categorías

Aplicar cuando el foco está en probabilidades, outcomes ordinales o redistribución entre categorías.

Subfamilias y orden auditado:

- Subfamilia A (multiclase/ordinal): `T19` primer piloto, `T18` segundo, `T16` después
- Subfamilia B (caso puente binario): `T12` al final

Regla clave:

- no imponer formato único; elegir subfamilia según el objeto de decisión

### Casos especiales fuera de familia principal

- `T3`: no linealidad (familia propia)
- `T8`: bloque dinámico / rezagos (familia propia)
- `T10`, `T17`, `T20`: no públicos por ahora / notas técnicas

### Regla de expansión del módulo

- No asumir cobertura universal de una familia visual.
- Si un taller no entra limpio en familia 1, 2 o 3, no forzarlo.
- Auditar legibilidad antes de escalar una tanda de piezas.

### Categorías públicas vs códigos internos

- Mostrar primero el significado conceptual de la categoría en tablas y visuales.
- No usar códigos internos como etiqueta pública principal (`0/1`, `choice=1`, `prftshr=1`, etc.).
- Si el número tiene significado sustantivo, acompañarlo con nombre conceptual.
- Prioridad de control en econometría: alta en `T16`, `T18`, `T19`; media en `T12`, `T13`, `T14`, `T15`.

### Lenguaje, codificación y formato de assets

- Revisar tildes/eñes del texto dentro de SVG o tarjetas.
- Corregir cualquier señal de mojibake (`Ã`, `Â`, `â€™`, etc.) antes de cerrar.
- Preferir SVG liviano para visuales editoriales simples.
- Si la exportación de Stata produce SVG pesado, reemplazar por PNG.
- `.gph` no se publica en web.
- Para familia 2, controlar lenguaje público en SVG: `T9` como referencia, con revisión fina adicional en `T2`, `T4`, `T6`, `T7`, `T15`.

## Sincronización operativa entre árboles (econometría)

Cuando la pieza existe en `portfolio-site` y en `econometria-clasica`:

- replicar asset visual en ambos árboles cuando corresponda
- mantener sincronía entre `portfolio-site/econometria/piezas/*.qmd` y `econometria-clasica/01_portfolio/qmd/*.qmd`
- renderizar HTML de ambos árboles
- verificar que el portal actualizado refleje el cambio real

## Tono y control editorial

- Tono profesional, sobrio y externo.
- Evitar metadiscurso interno y lenguaje coloquial.
- Evitar afirmaciones más fuertes que la evidencia.
- Antes de cerrar, verificar que la pieza responda en una línea: qué se estimó, qué lectura domina y bajo qué alcance.

## Control técnico mínimo

- Mantener UTF-8 sin BOM.
- Si se toca estructura/base del `.qmd`, verificar metadata antes de render.
- Después de render, revisar HTML real (TOC/layout/CSS/bloques principales); compilar no equivale a curar.
