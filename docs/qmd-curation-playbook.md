# QMD Curation Playbook

## Propósito

Este archivo fija el contrato maestro para construir piezas públicas `.qmd` del portfolio.

No es un manual de Stata ni un resumen de logs.  
Es una guía editorial y operativa para transformar talleres, do-files, logs y diagnósticos privados en piezas públicas profesionales, consistentes y curadas.

La meta no es “publicar todo”.  
La meta es construir piezas que funcionen como portfolio profesional.

---

## 0. Alcance, capas de reglas y precedencia

Este playbook combina dos capas:

- reglas universales del portfolio (aplican siempre)
- reglas específicas por objetivo de sección (aplican según `econometria-clasica`, `causalidad`, `ML`)

Regla explícita de precedencia:

- si una regla general entra en tensión con una regla específica de sección, manda la regla específica de sección.

Regla sobre benchmark de `econometria-clasica`:

- `econometria-clasica` sigue siendo benchmark de curaduría formal (pulido, orden narrativo, limpieza visual, calidad editorial).
- ese benchmark no implica copiar automáticamente su lenguaje sustantivo a `causalidad` o `ML`.

---

## 1. Principio general

Una pieza pública no debe parecer:

- apunte de clase
- log comentado
- guía pedagógica cruda
- secuencia de comandos
- acumulación de resultados sin jerarquía

Una pieza pública sí debe parecer:

- pieza profesional de portfolio
- narrativa clara
- lectura empírica ordenada
- decisión econométrica visible
- conclusión honesta y sobria

La técnica debe sostener la historia.  
No debe reemplazarla.

---

## 2. Regla cero: no empezar directamente por el `.qmd`

Codex no debe producir una pieza pública directamente desde `do-file + log`.

Antes de tocar un `.qmd`, debe existir una ficha técnica-editorial privada del taller.

Si esa ficha no existe, el `.qmd` no debería empezar.

---

## 3. Ficha técnica privada obligatoria

Toda ficha técnica privada debe responder, como mínimo, estas preguntas:

1. ¿Cuál es la pregunta del taller?
2. ¿Cuál es la variable resultado?
3. ¿Cuáles son los regresores o comparaciones centrales?
4. ¿Qué métodos o modelos se comparan?
5. ¿Cuál es la tabla o bloque del log que contiene la comparación decisiva?
6. ¿Hay una especificación ganadora?
7. Si no la hay, ¿cuál es entonces la enseñanza del taller?
8. ¿Qué afirmación sí puede hacerse?
9. ¿Qué afirmación no debe hacerse?
10. ¿Cuál debería ser el objeto de decisión final de la pieza pública?

La ficha privada no es un apéndice burocrático.  
Es la capa que evita perder la decisión empírica central.

---

## 4. Clasificación editorial obligatoria de cada taller

Antes de escribir la pieza pública, cada taller debe clasificarse en una de estas familias:

### A. Hallazgo sustantivo
Hay una historia empírica fuerte y el método ayuda a sostener un patrón claro.

### B. Comparación metodológica
La historia principal no es solo el fenómeno económico, sino qué cambia cuando cambia el método.

### C. Evidencia débil o nula, pero informativa
La conclusión no es “no salió nada”, sino que con esa base y ese diseño la evidencia no alcanza para sostener algo más fuerte.

### D. Pieza principalmente técnica
No se debe fingir una gran historia aplicada.  
La historia correcta es: qué problema econométrico se enfrenta, cómo se resuelve, y qué cambia en la lectura cuando se corrige.

Esta clasificación debe quedar explícita en la lógica del `.qmd`, aunque no siempre se muestre con ese nombre al lector final.

---

## 5. Arquitectura fija de toda pieza pública

Toda pieza pública debe seguir una arquitectura narrativa fija.

No idéntica en redacción, pero sí en lógica:

1. **Pregunta**
2. **Por qué la pregunta es difícil o por qué el método importa**
3. **Qué se compara**
4. **Resultado principal**
5. **Qué lectura gana**
6. **Cierre honesto**

No alcanza con mostrar resultados.  
Siempre hay que mostrar qué lectura debe llevarse el lector.

---

## 6. Etiquetas editoriales obligatorias

Toda pieza debe quedar, explícita o implícitamente, dentro de una de estas tres situaciones:

- **Especificación ganadora**
- **Comparación sin ganador único**
- **Ejercicio metodológico, no orientado a una especificación final única**

Esto elimina ambigüedad.

No en todos los talleres tiene sentido coronar un único modelo.  
Pero en todos tiene sentido decir qué lectura domina.

---

## 7. Objeto de decisión final

Toda pieza pública debe tener un **objeto de decisión final**.

Ese objeto puede ser:

- una tabla comparativa corta
- una caja final de lectura
- un bloque resumen
- una tabla de contraste entre métodos
- una conclusión compacta con una decisión visible

Pero siempre debe existir algo que responda:

**“Entre todo lo que se corrió, esto es lo que el lector debe retener.”**

Si no existe ese objeto, la pieza queda abierta, dispersa o con cierre débil.

### Objeto de decisión final según tipo de bloque

- `econometria-clasica`: especificación o lectura econométrica dominante.
- `causalidad`: estimando causal + población objetivo + alcance del diseño.
- `ML`: modelo o pipeline ganador bajo métrica objetivo y validación fuera de muestra adecuada.

---

## 8. Regla sobre tablas

La tabla principal debe ser:

- corta
- limpia
- comparativa
- legible
- suficiente para sostener la lectura principal

La tabla principal no debe ser:

- la salida cruda de Stata
- una tabla gigantesca
- una acumulación de columnas que nadie va a leer
- una repetición del log

La tabla debe ayudar a responder:

- qué se está comparando
- qué especificación o lectura domina
- por qué esa lectura es la correcta

---

## 9. Regla sobre gráficos

No incluir gráficos por decoración.

Solo incluir gráficos si agregan valor real a:

- soporte
- overlap
- balance
- pesos
- primera etapa
- forma reducida
- interpretación del diseño

Si un gráfico no mejora la comprensión, debe omitirse.

### Criterios orientativos por bloque

- **Matching / PSM**: overlap, balance, soporte
- **IPWRA**: love plots, overlap ponderado, pesos
- **IV**: gráficos descriptivos solo si ayudan a leer primera etapa o forma reducida

No saturar la pieza con demasiados gráficos.

---

## 10. Regla sobre diagnósticos técnicos

Los diagnósticos técnicos deben existir, pero no dominar visualmente la pieza.

Deben aparecer:

- después del resultado principal
- en bloques breves
- como apoyo a la decisión
- no como protagonista absoluto

La pieza no debe estar organizada alrededor de tests y comandos.  
Debe estar organizada alrededor de una pregunta y una lectura.

---

## 11. Lenguaje inferencial según objetivo de sección

Nunca mezclar por reflejo semánticas de estimación, causalidad y predicción.

Mini-matriz operativa:

| Sección | Foco principal | Lenguaje por defecto | Guardrails clave |
| --- | --- | --- | --- |
| `econometria-clasica` | Lectura econométrica y comparación de especificaciones | relación, estimación, evidencia, cambio estimado | no usar causalidad por defecto; solo si el diseño del caso realmente lo justifica |
| `causalidad` | Efectos causales interpretables dentro del diseño | efecto causal, contrafactual, población objetivo, alcance del diseño | no degradar automáticamente a “asociación” cuando el estimando causal está bien definido en el marco válido |
| `ML` | Predicción y generalización | desempeño, error, métrica, generalización, calibración, precision/recall/AUC según caso | no hablar de causalidad por defecto; no confundir importancia predictiva con efecto causal; exigir evaluación fuera de muestra y baseline cuando corresponda |

Reglas complementarias:

- en `causalidad`, mantener firmeza sobria: efecto causal dentro del diseño y para la población objetivo, sin exagerar.
- en `causalidad`, un no-rechazo de sobreidentificación **no prueba** validez; una primera etapa débil **debilita** lectura causal.
- en `ML`, reportar métrica objetivo con partición/validación explícita y comparación contra baseline defendible.
- en cualquier sección, no narrar “corrección” de coeficientes si cambia también la muestra o el objetivo inferencial.

### 11.1 Errores de traducción entre secciones (prohibidos)

- trasladar lenguaje causal por reflejo a `econometria-clasica`.
- trasladar lenguaje asociativo por reflejo a `causalidad` cuando el diseño ya fija un estimando causal.
- trasladar causalidad a `ML` cuando el objetivo es predicción.
- cerrar todas las piezas con la misma semántica ignorando el objetivo de sección.

---

## 12. Regla sobre selectores

Los talleres tipo selector no deben convertirse automáticamente en fichas públicas autónomas.

Su función normal es respaldar técnicamente una pieza principal.

Ejemplos típicos:
- selector de matching respalda matching principal
- selector de PSM respalda PSM principal
- selector de IPWRA respalda IPWRA principal

La pieza visible debe ser el resultado principal.  
El selector debe aparecer como justificación breve de la elección de especificación, no como protagonista del portfolio.

Patrón operativo ya validado:
- T3 respalda T2
- T5 respalda T4
- T7 respalda T6

Diferencia clave entre bloques:
- En T2/T3 y T4/T5, la ficha principal compara varias especificaciones y el selector posterior ayuda a cerrar la preferida.
- En T6/T7, la ficha principal ya corre con la especificación ganadora y el selector solo justifica internamente ese diseño.

Regla de publicación:
- si un selector no aporta historia aplicada nueva para lector externo, no se publica como pieza autónoma.

Regla de visibilidad pública:
- si el selector no es público, la pieza principal no debe remitir al lector como si pudiera consultarlo.
- en la cara pública, reemplazar referencias internas por formulaciones impersonales (por ejemplo: "regla previa de selección de diseño", "criterio de comparabilidad, soporte y precisión", "diseño preseleccionado").

---

## 13. Regla sobre la historia

La historia no se fuerza.

Si el taller no tiene una gran historia aplicada, la historia correcta pasa a ser:

- el problema econométrico
- la comparación entre métodos
- lo que cambia cuando se trata bien ese problema
- por qué la lectura final debe ser cauta o técnica

Nunca inventar “gran aplicación” donde no la hay.

---

## 14. Regla sobre tono y estilo

Usar tono:

- profesional
- claro
- sobrio
- humano
- preciso

Evitar:

- tono de clase
- tono excesivamente técnico en el arranque
- frases grandilocuentes
- cierre triunfalista
- expresiones coloquiales impropias
- afirmaciones más fuertes que el diseño

Preferir:

- formulaciones limpias
- frases de evidencia
- cierres honestos
- transición clara entre pregunta, método y lectura

### Refuerzos explícitos consolidados (benchmark formal + objetivos diferenciados)

El benchmark de `econometria-clasica` se mantiene para pulido formal, no como plantilla automática de lenguaje sustantivo para todas las secciones.

**A. Narrativa y lenguaje público**

1. Registro externo: redactar para lector externo, sin conversación interna ni metadiscurso editorial.
2. Pregunta sustantiva visible: explicitar “efecto/relación de qué sobre qué” en lenguaje humano.
3. Respuesta corta opcional: usarla debajo de la pregunta cuando mejore legibilidad.
4. Historia con criterio: no inventar storytelling, pero tampoco perder narrativa cuando el material la permite.
5. Nombres internos en segundo plano: `S1`, `spec_1`, sintaxis de variables y etiquetas de taller no deben dominar la lectura pública.
6. Traducción técnica obligatoria cuando haga falta: transformar notación interna en formulaciones públicas (por ejemplo, logaritmos, nombres de especificación).
7. “Datos y variables” legible: incluir unidad de análisis, tratamiento, resultado, covariables relevantes y población objetivo sin estilo de log crudo.
8. Interpretación sustantiva explícita: atar número + estimando + población + significado y, cuando corresponda, darle entidad visual suficiente.
9. Alcance sobrio: explicar validez por diseño y población sin convertir el cierre en lista defensiva de negaciones.

**B. Síntesis comparativa y tablas públicas**

10. Tabla principal con función de decisión clara: evitar acumulación de variantes sin jerarquía.
11. Rótulos públicos y siglas claras: evitar etiquetas internas crudas; expandir siglas ambiguas (por ejemplo, “AI”).
12. Inferencia consistente: si corresponde bootstrap para la especificación reportada, mantener esa convención sin mezclar versiones confusas.
13. Contrastes auxiliares subordinados: no sobredimensionar comparaciones intermedias (`common` vs `trim(10)`, etc.) cuando no son el núcleo.
14. Patrones con precisión formal: cuando aplique, usar notación ordenada y no ambigua (por ejemplo, `ATET_3 > ATET_2 > ATET_1 > 0`).

**C. Control técnico-editorial no negociable**

15. UTF-8 sin BOM siempre; control explícito de front matter cuando se toca metadata o estructura.
16. Antes de render: auditar el `.qmd` real y separar problemas narrativos, sustantivos y técnicos.
17. Si se toca `format`, `toc`, `page-layout`, `css`, título o front matter, correr verificación previa tipo `quarto inspect`.
18. Después de render: revisar HTML real (TOC, hero, CSS, layout, tablas y bloques); compilar no equivale a curar.
19. Ante regresión técnica, restaurar baseline sana antes de reaplicar edición narrativa.
20. Checklist de cierre: codificación, metadata leída, estructura visual, limpieza del español y ausencia de lenguaje interno.

---

## 15. Qué evitar siempre

Evitar:

- copiar la secuencia del do-file
- resumir el log en orden cronológico
- abrir con demasiada jerga
- mostrar demasiados tests sin jerarquía
- meter tablas gigantes
- duplicar resultados equivalentes
- esconder la pregunta central
- esconder la decisión final
- concluir más de lo que la evidencia permite

---

## 16. Qué debe tener siempre una buena pieza

Una buena pieza pública debe tener siempre:

- una pregunta clara
- una dificultad o problema metodológico reconocible
- una comparación dominante
- un resultado principal visible
- una lectura que gane
- un cierre honesto
- una estructura visual consistente con el resto del portfolio

---

## 17. Semántica fija de las tarjetas del sitio

Las tarjetas del listado general no deben mezclar significados.

Todas deben seguir la misma lógica:

- **Título humano**
- **Pregunta en una línea**
- **Método principal**
- **Tipo de datos o diseño**
- **Hallazgo o enseñanza principal en una frase**
- **Estado de la evidencia**

### Estados de evidencia sugeridos

- Resultado robusto
- Comparación metodológica
- Evidencia débil pero informativa
- Pieza técnica
- Desempeño predictivo fuera de muestra (ML)

No usar coeficientes crudos como centro de la tarjeta.  
El valor de la tarjeta está en claridad, criterio y lectura, no en el número aislado.

---

## 18. Orden de exposición del portfolio

El sitio no debe comportarse como un curso.

No ordenar solo por número de taller si eso debilita la lectura externa.

Ordenar por valor externo:

1. piezas más fuertes y legibles
2. piezas más aplicadas
3. piezas más técnicas

El portfolio debe verse curado, no secuencialmente docente.

---

## 19. Flujo ideal entre Daniel, Codex y ChatGPT

### Daniel
Define verdad sustantiva, límites de interpretación, tono aceptable y criterio final.

### Codex
Extrae, ordena, ejecuta y produce archivos bajo reglas explícitas.  
No debe interpretar libremente ni “crear historia” por sí solo.

### ChatGPT
Edita, audita, detecta huecos narrativos y refuerza consistencia entre piezas.

---

## 20. Flujo operativo recomendado

1. **Insumos**: do-file, log, gráficos, auxiliares
2. **Ficha técnica privada obligatoria**
3. **Clasificación editorial del taller**
4. **Definición del objeto de decisión final**
5. **Diseño narrativo de la pieza**
6. **Redacción del `.qmd`**
7. **Auditoría final de sobriedad, coherencia y cierre**

No invertir este orden.

---

## 21. Definición de “pieza terminada”

Una pieza pública está bien terminada cuando:

- no parece apunte de clase
- no parece log comentado
- se entiende la pregunta central
- se entiende qué método importa
- se entiende qué lectura gana
- existe un objeto de decisión final
- el cierre es honesto
- la estética y la semántica son coherentes con el resto del portfolio

---

## 22. Regla final

El criterio no es “si el `.qmd` compila”.

El criterio es:

**si la pieza puede mostrarse como trabajo profesional curado y si transmite criterio metodológico consistente con el objetivo de su sección, no solo ejecución técnica.**
