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
- lenguaje
- jerarquía narrativa
- sobriedad visual
- tipo de tablas
- estructura de lectura
- calidad editorial

No crear una estética nueva para `causalidad`.

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

### T8
No presentarlo como “caso exitoso de IV” sin matices.
La lectura correcta es metodológica y cauta:
la especificación rica es conceptualmente importante, pero la primera etapa resulta débil y no corresponde sobreactuar la conclusión causal.

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