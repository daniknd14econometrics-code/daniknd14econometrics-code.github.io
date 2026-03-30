# AGENTS.md

## Propósito del repositorio

Este repositorio contiene un portfolio profesional en Quarto con varias secciones temáticas.  
La sección `econometria-clasica` ya tiene un estándar visual, narrativo y editorial validado.  
La sección `causalidad` debe heredar ese mismo estándar y expandirlo, no reinventarlo.

## Regla editorial general

Cuando trabajes en `causalidad`, debes mantener coherencia estricta con `econometria-clasica` en:

- diseño general
- colores
- tono profesional
- lenguaje público sobrio
- jerarquía narrativa
- sobriedad visual
- tipo de tablas
- estructura de lectura
- calidad editorial

No crear una estética nueva para `causalidad`.

Importante: `econometria-clasica` funciona aquí como benchmark de curaduría formal, no como plantilla automática del lenguaje sustantivo.

## Precedencia y alcance de este AGENT

- Este AGENT gobierna piezas de `causalidad`; sus reglas no deben extrapolarse automáticamente a `econometria-clasica` ni a futuros bloques de `ML`.
- Si una regla general del playbook entra en tensión con una regla específica de `causalidad`, prevalece la regla específica de `causalidad`.

## Objetivo sustantivo de la sección causalidad

- El objetivo central es comunicar efectos causales interpretables dentro del diseño y para la población objetivo.
- No degradar automáticamente a “asociación” cuando la pieza está construida para reportar un estimando causal válido.
- Mantener sobriedad: no afirmar más allá de lo que permite el diseño.

## Regla de producción

No producir una pieza pública (`.qmd`) directamente a partir de un do-file o un log sin una capa previa de diagnóstico editorial privado.

Antes de redactar o editar una ficha pública de `causalidad`, debe existir una lectura privada del taller que deje claro:

- qué pregunta econométrica o causal organiza el ejercicio
- qué comparación es realmente central
- si el taller es publicable como ficha principal, pieza breve, o solo respaldo metodológico
- qué se puede afirmar y qué no
- si hay o no una especificación ganadora
- si conviene incorporar gráficos y cuáles

## Regla de jerarquía entre talleres

No todo taller merece ficha pública independiente.

En `causalidad`, distinguir entre:

1. fichas públicas principales
2. piezas introductorias breves
3. respaldos metodológicos o apéndices técnicos

Los talleres tipo “selector”, cuando existen para el mismo tema que un taller principal, normalmente NO deben transformarse en una ficha pública autónoma de primer nivel.  
Su función usual es respaldar técnicamente la elección de especificación del taller principal.

Regla de visibilidad pública:
- si el selector no se publica como ficha autónoma, la pieza principal no debe remitir al lector como si ese selector fuera visible.
- usar formulaciones impersonales (por ejemplo: "regla previa de selección de diseño", "criterio de comparabilidad, soporte y precisión", "diseño preseleccionado").

## Mapa editorial actual de la sección causalidad

### Apertura breve conceptual
- T1: pieza breve introductoria sobre por qué una diferencia de medias no es causal

### Fichas públicas principales
- T2: Matching exacto
- T4: PSM sin selector como pieza principal del bloque PSM
- T6: IPWRA multivalue como pieza principal del bloque IPWRA
- T8: Variables instrumentales como pieza metodológica pública con lectura cauta

### Respaldos metodológicos / piezas subordinadas
- T3: selector de diseño para matching exacto, subordinado a T2
- T5: selector de diseño para PSM, subordinado a T4
- T7: selector de diseño para IPWRA, subordinado a T6

## Orden sugerido de la sección causalidad

El orden preferido de construcción, lectura o exhibición pública es:

1. T1
2. T2
3. T4
4. T6
5. T8

Los talleres T3, T5 y T7 deben usarse para reforzar la credibilidad metodológica de T2, T4 y T6 respectivamente, no para competir con ellos como fichas principales.

## Reglas específicas por bloque

### T1
Usarlo como apertura conceptual breve.
No venderlo como caso aplicado fuerte.

### T2 y T3
T2 es la ficha pública principal.
T3 funciona como respaldo metodológico de la decisión de diseño.
Si se menciona una especificación preferida en T2, debe quedar claro que surge de la regla de diseño explicitada en T3 y no del tamaño del coeficiente.

### T4 y T5
T4 es la ficha pública principal del bloque PSM.
T5 respalda metodológicamente la elección de especificación.
No presentar T5 como una nueva aplicación sustantiva; su valor es cerrar la decisión de diseño.

### T6 y T7
T6 es la pieza pública principal del bloque IPWRA.
T7 justifica la elección del diseño ganador.
La formulación correcta es que T6 corre sobre el diseño ganador elegido en T7, no que T6 elige por sí mismo la especificación.

Diferencia operativa entre bloques:
- en T2/T3 y T4/T5, la ficha principal compara especificaciones y el selector posterior ayuda a cerrar la preferida.
- en T6/T7, la ficha principal ya incorpora la especificación ganadora y el selector queda como justificación interna.

### T8
No presentarlo como “caso exitoso de IV” sin matices.
La lectura correcta es metodológica y cauta:
la especificación rica es conceptualmente importante, pero la primera etapa resulta débil y no corresponde sobreactuar la conclusión causal.

## Regla de redacción pública y variables

- La pregunta principal debe declarar con claridad el efecto de qué sobre qué en lenguaje humano y sustantivo.
- Evitar que nombres internos de variables sean la puerta de entrada visual; ubicar detalle técnico en "Datos y variables".
- Evaluar una "respuesta corta" inmediata debajo de la pregunta cuando mejore legibilidad.
- En "Datos y variables", definir de forma explícita: unidad de análisis, tratamiento, resultado, covariables relevantes y población objetivo.
- Mantener claridad técnica sin tono de log ni lista de código.
- Traducir transformaciones internas a lenguaje público cuando no aporten interpretación directa (por ejemplo, priorizar "logaritmo del gasto total del hogar" sobre sintaxis cruda).
- Evitar metadiscurso interno visible para lector externo.

## Regla sobre gráficos

No incluir gráficos por decoración.

Solo incorporar gráficos si agregan valor real de identificación, balance, soporte, overlap, pesos o lectura causal.

Criterios orientativos:
- matching / PSM: overlap, soporte, balance
- IPWRA: pesos, overlap, love plots
- IV: gráficos descriptivos solo si ayudan a leer primera etapa o forma reducida, no como adorno

Si un gráfico no mejora la comprensión, omitirlo.

## Regla sobre afirmaciones

No sobreactuar causalidad.

Siempre distinguir entre:
- resultado empírico
- estrategia de identificación
- fuerza del diseño
- límites de interpretación

No transformar automáticamente un coeficiente en una afirmación causal fuerte.
No presentar un no-rechazo de sobreidentificación como “prueba” de validez.
No presentar una especificación débil como si fuera evidencia concluyente.
Cuando el diseño causal observacional ya está fijado y el estimando admite lectura causal en ese marco, no degradar innecesariamente a "asociación".
La interpretación del efecto debe depender de Y, del tratamiento y del estimando concreto (incluyendo puntos porcentuales cuando corresponda en resultados binarios).
La sección de alcance debe explicar para qué población vale la lectura causal, bajo qué diseño y con qué prudencia, sin convertir el cierre en una lista defensiva de negaciones.

## Regla sobre tablas e inferencia pública

- Las tablas públicas deben cumplir función de decisión/lectura y no acumular variantes por inercia.
- Los rótulos de filas y columnas deben ser públicos; evitar etiquetas internas como "Referencia base del taller" y preferir "Referencia comparativa" o "Especificación de referencia".
- Toda sigla ambigua para lector externo debe aclararse o expandirse (por ejemplo, "AI" -> "Abadie-Imbens").
- Si la versión bootstrap es la que corresponde reportar para una especificación, usarla de forma consistente en la tabla pública.
- No mezclar versiones de inferencia de manera confusa.
- No sobredimensionar contrastes metodológicos auxiliares (por ejemplo `common` vs `trim(10)`) cuando no son el núcleo del mensaje.
- Al resumir patrones de estimandos, priorizar precisión formal (por ejemplo, `ATET_3 > ATET_2 > ATET_1 > 0` cuando corresponda).

## Regla de estilo narrativo

Las piezas públicas deben priorizar:
- historia empírica clara
- una pregunta central entendible
- una comparación dominante
- una conclusión sobria y profesional

Evitar que la pieza quede escrita como apunte de clase, log comentado o resumen técnico bruto.

La técnica debe estar al servicio de la historia, no al revés.

## Regla operativa para Codex

Cuando trabajes sobre `causalidad`:

- primero identificar insumos relevantes
- luego respetar la jerarquía editorial ya definida
- después proponer o editar la pieza correspondiente
- no asumir que todos los talleres requieren `.qmd`
- no promover un selector a ficha principal salvo instrucción explícita
- no romper la coherencia con `econometria-clasica`

Si existe duda entre “ficha principal” y “respaldo metodológico”, preferir la opción más conservadora y dejar explícita la duda en el diagnóstico.
