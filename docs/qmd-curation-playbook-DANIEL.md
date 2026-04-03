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

### 0.1 Criterios visuales consolidados del sitio (rediseño reciente)

Estos criterios ya consolidados pasan a ser regla explícita del proyecto:

- `home`: hero visual fuerte pero sobrio.
- `portales de sección`: hero visible + sistema visual consistente entre secciones.
- `piezas individuales`: estética editorial clara, sin imagen de fondo aplicada a todo el cuerpo del artículo.

Regla de imagen:

- uso protagonista de imagen en `home` y `portales`.
- no usar imagen de fondo en todo el cuerpo de piezas individuales.

### 0.2 Regla de intervención y preservación

- no rediseñar por defecto una pieza que ya funciona.
- preferir microajustes compatibles y no invasivos.
- priorizar fidelidad de contenido y estructura de la pieza.
- integrar `hero-box`, métricas, TOC, tablas y figuras con sobriedad, sin forzar una plantilla única.
- ante conflicto entre rediseño global y pieza individual consolidada, priorizar la pieza individual.
- cuando exista versión canónica/original consolidada, tratarla como fuente de verdad y restaurarla ante regresiones visuales.

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

Los gráficos no son obligatorios en todas las piezas.

Solo incluir gráficos si agregan valor real de comprensión pública.  
Si un recurso visual no aclara la decisión, debe omitirse.

### 9.1 Principio editorial no negociable

- No agregar gráficos por relleno, por estética o porque “toda página debería tener algo visual”.
- Si un gráfico compacta complejidad sin traducirla, no conviene.
- Regla práctica: si el lector necesita recordar el log o el taller para entender el visual, el visual está fallando.
- El gráfico nunca reemplaza tabla principal, decisión metodológica ni cierre narrativo.
- El gráfico debe funcionar como apoyo visual, no como hero graphic.

### 9.2 Familias visuales activas del proyecto

El proyecto trabaja con familias visuales distintas.  
No forzar un formato único para todos los talleres.

#### Familia 1: mini gráfico de estimación puntual + IC 95%

Usar esta familia cuando:

- hay comparación binaria limpia entre dos enfoques, o
- hay una especificación dominante clara y escalable.

Reglas de diseño:

- formato pequeño y sobrio
- orientación horizontal
- sin nota al pie
- sin leyenda
- sin grilla cargada
- 1 o 2 estimaciones, no más
- línea vertical en 0
- etiquetas claras para lector externo
- no convertirlo en “coeficiente estrella”

Referencias validadas actuales en econometría clásica:

- `T1` (2 estimaciones)
- `T5` (1 estimación)
- `T11` (2 estimaciones)
- `T13` (2 estimaciones)
- `T14` (2 estimaciones)

#### Familia 2: síntesis visual de trayectoria metodológica / decisión secuencial

Usar esta familia cuando:

- la pieza no gira en torno a un coeficiente único, y
- la lectura central es una trayectoria metodológica o decisión secuencial.

Reglas de diseño:

- SVG simple y sobrio
- bloque secuencial horizontal
- texto corto y claro
- sin estética de infografía vistosa

El recurso debe resumir:

- qué se compara
- qué cambia
- qué decisión deja

El recurso no debe:

- coronar un modelo por un test aislado
- reducir toda la lectura a un único coeficiente
- borrar la lógica de transición entre enfoques
- depender de códigos internos para ser entendido

Referencias consolidadas actuales:

- implementados/validados: `T9`, `T15`
- ya explorados para simplificación de lenguaje: `T2`, `T4`, `T6`, `T7`

#### Familia 3: desplazamientos de probabilidad / categorías

Usar esta familia cuando la lectura central exige mostrar:

- probabilidades
- categorías
- redistribución entre outcomes
- desplazamientos ordinales

Regla de diseño y lectura:

- no asumir formato único rígido
- tratar esta familia como paraguas con subfamilias

Subfamilias detectadas:

- Subfamilia A (redistribución multiclase/ordinal): `T16`, `T18`, `T19`
- Subfamilia B (comparación binaria entre especificaciones): `T12` como caso puente

Orden de pilotos auditado:

- primer piloto recomendado: `T19`
- segundo piloto: `T18`
- luego `T16`
- `T12` al final por su carácter de puente y no de núcleo puro

#### Familias futuras

Hay talleres que pueden requerir otras familias visuales (por ejemplo, no linealidad o rezagos).  
No forzar familia 1, familia 2 ni familia 3 cuando el objeto de decisión sea otro.

Casos ya identificados fuera de las tres familias activas:

- `T3`: objeto de no linealidad
- `T8`: bloque dinámico / rezagos

### 9.3 Sobriedad y diseño común

- Gráficos chicos o medianos, nunca protagonistas.
- Estética sobria.
- Preferir 1 a 2 tonos neutros del portfolio.
- Evitar colores fuertes.
- Evitar iconografía decorativa.
- Evitar cajas/flechas grandilocuentes.
- Evitar leyendas innecesarias.
- Evitar notas al pie debajo del gráfico.
- Evitar estética de infografía marketinera o escolar.

Reglas adicionales:

- En SVG secuenciales: texto corto, sin sobrecarga de números, peso bajo.
- En mini gráficos con IC: mantener coherencia de escala y estilo con `T1`.

### 9.4 Lenguaje público dentro de SVG y tarjetas visuales

- Escribir para lector externo, no para quien ya conoce el taller.
- Evitar tono interno de cocina econométrica.
- Minimizar jerga o código técnico en el visual.
- Si un concepto técnico es necesario, traducirlo a lenguaje público.

Ejemplos de jerga/código a evitar como texto principal del visual:

- `AR(1)`
- `LM`
- `Cov(x_it,c_i)`
- `D.educ`
- `uhat_L1`
- `chi2(...)`
- `within`
- `baseline`
- `benchmarks`

Regla práctica para texto de esta familia:

- decir qué se compara
- decir qué cambia
- decir qué decisión queda

Aprendizaje de auditorías recientes:

- el problema dominante fue exceso de jerga econométrica dentro de la tarjeta
- `T9` quedó como referencia relativamente bien calibrada
- `T4` y `T15` requirieron mayor simplificación de lenguaje
- `T2` también fue simplificado bajo el mismo criterio
- `T6` y `T7` quedaron en la misma cola de revisión fina de legibilidad

### 9.4.1 Categorías públicas vs códigos internos

Regla conceptual:

- en piezas públicas (tablas, captions, gráficos y SVG), mostrar primero el significado de la categoría
- no usar como primera capa el código interno del do-file

Patrón transversal detectado:

- mayor gravedad en multinomiales/ordinales (`T16`, `T18`, `T19`)
- gravedad media o leve en binarias (`T12`, `T13`, `T14`, `T15`)

Regla práctica:

- evitar como etiqueta principal `1 escuela`, `2 hogar`, `3 trabajo`, `0/1`, `choice=1`, `prftshr=1`
- si el número tiene significado sustantivo, acompañarlo siempre con nombre conceptual

Ejemplo orientativo:

- no dejar solo `0 / 50 / 100`
- preferir `0% en acciones (cartera conservadora)`, `50% en acciones (cartera mixta)`, `100% en acciones (cartera más expuesta a acciones)`

### 9.5 Higiene tipográfica y codificación

- Todo texto visible en `.qmd`, HTML y SVG debe salir con tildes, eñes y signos correctos.
- Revisar explícitamente el texto de cada SVG antes de cerrar pieza.
- Guardar `.qmd` en UTF-8 correcto y, cuando corresponda, sin BOM.
- Si aparecen secuencias como `Ã`, `Â`, `â€™` u otras equivalentes, tratarlo como error de codificación y corregir antes de cerrar.
- Si el problema está solo en el SVG, corregir el asset sin abrir una nueva ronda editorial del `.qmd`.

Palabras sensibles que conviene revisar en control final:

- síntesis
- decisión
- comparación
- metodología
- diagnóstico
- transición
- restricción
- clásico
- patrón
- señal
- atenuación

### 9.6 Formato técnico de assets y peso

- No usar Stata como flujo por defecto para generar visuales de apoyo editorial.
- Generar assets dentro del proyecto.
- Para visuales simples de apoyo, preferir SVG liviano.
- Para exportaciones pesadas de Stata, preferir PNG (o WebP si es razonable).
- Si un SVG exportado desde Stata queda pesado o complejo, no usarlo en web.
- Mantener assets livianos y sin complejidad innecesaria.
- `.gph` es fuente editable de Stata, no formato de publicación web.
- Para gráficos estadísticos con texto/ejes/líneas, evitar JPG como formato preferente.

Caso aprendido consolidado en causalidad:

- en `c08`, dos SVG de Stata resultaron desproporcionadamente pesados
- la resolución correcta fue reemplazarlos por PNG
- el problema no era la cantidad de gráficos, sino peso y complejidad del asset

### 9.7 Ubicación narrativa del recurso visual

Para mini gráfico punto + IC:

- ubicar normalmente después de tabla principal
- ubicar antes del bloque de salvedades/diagnósticos/cierre intermedio

Para síntesis visual de decisión secuencial:

- ubicar normalmente después de evidencia o diagnósticos
- ubicar antes de lectura profesional o cierre narrativo

Para desplazamientos de probabilidad/categorías:

- ubicar normalmente después del bloque de APEs narrables o de síntesis de magnitudes
- ubicar antes del bloque de contexto secundario o diagnósticos
- usarlo solo si aclara; no usarlo como duplicado confuso de tablas/texto

Regla común:

- el visual sintetiza y ordena
- no adelanta en sesgo
- no reemplaza explicación textual

### 9.8 Workflow de decisión visual

1. Auditoría primero: evaluar si el taller admite visual y de qué familia.
2. Piloto primero: validar 1-2 casos antes de expandir.
3. Expansión por tandas homogéneas: una vez validada la familia.
4. Auditoría de legibilidad durante expansión: frenar si la familia se vuelve demasiado técnica.
5. No forzar: si un caso no entra limpio en la familia elegida, no usarla.

### 9.9 Sincronización entre árboles

Cuando una pieza existe en ambos árboles (`econometria-clasica` y `portfolio-site`):

- replicar el asset visual en ambos árboles cuando corresponda
- actualizar el `.qmd` correspondiente en ambos árboles según flujo canónico vigente
- renderizar HTML en ambos árboles
- verificar que la versión del portal quede efectivamente actualizada
- mantener sincronía real de contenido y assets, no solo intención de sincronía

### 9.10 Cierre editorial de visuales

El proyecto no trabaja con la idea de “un gráfico para todos los talleres”.  
Trabaja con familias visuales distintas, aplicadas solo cuando suman comprensión real, con lenguaje público, assets livianos y control editorial fino.

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
