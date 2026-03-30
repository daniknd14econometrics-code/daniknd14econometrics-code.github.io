# QMD Curation Playbook

## Propósito

Este archivo fija el contrato maestro para construir piezas públicas `.qmd` del portfolio.

No es un manual de Stata ni un resumen de logs.  
Es una guía editorial y operativa para transformar talleres, do-files, logs y diagnósticos privados en piezas públicas profesionales, consistentes y curadas.

La meta no es “publicar todo”.  
La meta es construir piezas que funcionen como portfolio profesional.

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

## 11. Regla sobre causalidad e inferencia

Nunca sobreactuar causalidad.

Siempre distinguir entre:

- resultado empírico
- estrategia de identificación
- fuerza del diseño
- límite de interpretación

Nunca afirmar automáticamente que un coeficiente es causal solo porque viene de un método “más sofisticado”.

Reglas explícitas:

- un no-rechazo de sobreidentificación **no prueba** validez
- una primera etapa débil **debilita** lectura causal
- una estrategia rica pero frágil no debe venderse como evidencia concluyente
- una comparación de coeficientes no debe narrarse como “corrección” si cambia también la muestra

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

### Refuerzos explícitos validados (T1 + benchmark `econometria-clasica`)

1. **TOC por defecto**
Toda pieza pública debe incluir tabla de contenidos como opción base.
Solo puede omitirse en notas extremadamente breves donde no aporte navegación real.

2. **Registro de lenguaje público**
La redacción debe sonar a lector externo y no a conversación interna del proyecto.
No debe sonar a diagnóstico privado, nota de trabajo ni cocina metodológica.

3. **Evitar meta-editorial visible**
Las categorías internas pueden guiar la construcción, pero no deben contaminar el texto público.
Evitar fórmulas como “pieza aplicada fuerte”, “en términos editoriales”, “apertura conceptual de la sección” o “respaldo metodológico” cuando no aportan a la lectura externa.

4. **Títulos visibles con criterio de presentación**
Evaluar críticamente si conviene mostrar prefijos internos como `T1`, `T2`, etc. en el título visible.
Si el prefijo debilita la presentación profesional o refuerza una estética de taller, omitirlo en la cara pública.

5. **Nivel de curaduría esperado**
No alcanza con que el archivo compile ni con que el contenido sea técnicamente correcto.
La pieza debe sentirse tan curada como las mejores piezas de `econometria-clasica`: pulido narrativo, sobriedad, jerarquía clara y sensación de pieza profesional terminada.

6. **Pregunta al inicio, respuesta al cierre**
Cuando exista una pregunta empírica, causal o metodológica reconocible, debe aparecer desde el inicio.
La apertura no debe demorarse en metadiscusión.
La estructura debe conducir a una respuesta clara, sobria y consistente hacia el cierre.

7. **Historia narrativa cuando el material la permite**
Si el taller habilita una historia narrativa clara, esa historia debe estar presente.
No inventar storytelling donde no existe, pero tampoco perder una narrativa válida cuando sí existe.
La técnica debe organizar y sostener esa historia, no reemplazarla.

8. **Orientación temprana para lector externo**
Relativamente temprano en la pieza debe quedar claro: unidad de análisis, variable resultado, variable de interés principal o tratamiento, y observables/controles clave cuando corresponda.
Esa orientación no debe quedar escondida en tablas ni aparecer recién a mitad de la lectura.

9. **Bloque breve de datos y variables cuando haga falta**
Si se usan nombres de variables o notación no autoexplicativa, incluir una sección breve de “Datos y variables” o equivalente.
Las variables no deben quedar como código suelto: deben traducirse a lenguaje humano.

10. **Mini-sección sobre por qué falla la comparación ingenua**
Cuando la pieza demuestra que una comparación simple no alcanza, incorporar una mini-sección explícita (por ejemplo, “Por qué la comparación bruta falla”).
Esa explicación debe aparecer antes o alrededor del resultado principal, no quedar solo implícita.

11. **Elección de bloque visual según función narrativa**
No usar siempre la misma solución visual.
`metric-grid` debe reservarse para piezas con métricas headline o resultados principales que justifiquen ese tratamiento.
En piezas introductorias o de orientación, preferir `quick-grid` o un bloque equivalente con pregunta, diseño del caso y variables clave.
La forma visual debe responder a la función narrativa, no a una plantilla rígida.

12. **Brevedad con densidad editorial suficiente**
Una pieza breve no debe ser vacía.
Aunque sea introductoria, debe ofrecer suficiente aterrizaje empírico o metodológico para lector externo.
La brevedad no debe confundirse con falta de contexto.

13. **Reducir lenguaje interno de taller**
Evitar redacciones que asuman que el lector ya conoce el taller o su cocina interna.
La pieza pública debe poder leerse con claridad por alguien que entra por primera vez.

14. **Nombres internos vs. nombres públicos**
Los nombres internos (`S1`, `S2`, `spec_1`, `modelo_a`, etc.) pueden usarse para trazabilidad en repo y diagnósticos privados.
En la pieza pública no deben quedar como rótulos principales si no son intuitivos para lector externo.
La cara pública debe priorizar nombres comprensibles y profesionales.

15. **Traducción obligatoria de especificaciones opacas**
Cuando una especificación tenga nombre interno opaco, traducirla a formulación pública clara (por ejemplo: “especificación base”, “especificación ampliada”, “partición alternativa”, “regla de coarsening Scott”, “regla Freedman–Diaconis”).
Si se necesita trazabilidad, conservar la etiqueta interna en segundo plano (paréntesis o nota breve), no como etiqueta dominante.

16. **Lección metodológica vs. aplicación empírica**
Si la enseñanza principal es metodológica, no atribuirla de forma indebida a la aplicación específica.
La aplicación puede funcionar como contexto, pero la formulación visible debe distinguir la lección general del método y el caso donde se ilustra.

17. **Título y hero con formulación externa**
Título y hero deben evitar formulaciones que dependan de nombres internos, suenen a etiqueta de taller o confundan método con caso puntual.
Deben priorizar redacción humana, externa y conceptualmente limpia.

18. **Tablas públicas con rótulos comprensibles**
La tabla principal no debe usar nomenclatura interna cruda como rótulo dominante cuando debilita la lectura externa.
Usar rótulos públicos claros y, solo si hace falta, dejar la nomenclatura interna en segundo plano.

19. **Integridad técnica del `.qmd`**
Toda pieza pública debe guardarse en UTF-8 sin BOM.
Evitar BOM al inicio del archivo cuando pueda interferir con la lectura del front matter por Quarto.

20. **Verificación obligatoria de metadata antes de render**
Si la edición toca front matter, título, `format`, `toc`, `page-layout`, `css` o estructura base del `.qmd`, no renderizar directamente.
Antes del render, correr una verificación tipo `quarto inspect` y confirmar que Quarto lee metadata no vacía, en especial los campos relevantes.

21. **Render exitoso no equivale a pieza sana**
Un `exit code 0` no prueba integridad editorial o estructural.
Tras el render, verificar que el HTML conserve TOC, layout esperado, CSS de pieza y bloques visuales principales.
Si eso falla, tratarlo como regresión estructural y no como detalle visual.

22. **Orden correcto ante regresiones**
Si se pierde TOC, layout, CSS o metadata aplicada, primero restaurar baseline técnica sana del `.qmd`.
Recién después reaplicar ajustes editoriales.
No mezclar reparación técnica y reescritura narrativa en una misma pasada.

23. **Checklist mínimo de cierre técnico-editorial**
Antes de cerrar una pieza pública, verificar explícitamente: codificación correcta, front matter leído por Quarto, TOC cuando corresponde, `page-layout` correcto, CSS esperado cargado y preservación de hero/bloques/tabla principal.

24. **Notación pública antes que sintaxis interna**
La pieza pública no debe arrastrar sintaxis interna de implementación cuando no agrega valor interpretativo.
Ejemplo: si internamente se usa `ln(1+exptot)`, la cara pública puede priorizar “log del gasto total del hogar” y dejar la forma exacta en segundo plano si hace falta.

25. **Interpretación sustantiva obligatoria del parámetro**
Todo estimando principal (ATE, ATET, coeficiente IV, etc.) debe acompañarse con una frase de interpretación sustantiva que explicite: qué cambia, sobre qué variable, para quiénes, respecto de qué comparación/contrafactual y con qué alcance.
No alcanza con reportar solo el número.

26. **Población objetivo explícita del estimando**
La pieza debe declarar para qué población vale el parámetro interpretado (muestra completa, tratados, soporte común, muestra matched, cohorte específica, etc.).
No debe quedar implícito ni enterrado.

27. **Diferenciar número, estimando, población e interpretación**
El resultado numérico no equivale por sí solo a interpretación, y el parámetro no equivale por sí solo a población objetivo.
La pieza debe atar explícitamente número + estimando + población + significado sustantivo.

28. **Checklist de cierre en una línea**
Antes de cerrar una pieza, debe poder responderse en una línea: qué efecto/relación se encontró, sobre qué variable, para quiénes y bajo qué diseño.
Si eso no puede responderse con claridad, la pieza no está cerrada.

29. **No sobrecargar la cara pública con sintaxis de variables**
Los nombres de variables y fórmulas del do-file pueden aparecer, pero no deben dominar la interpretación visible.
La pieza debe poder leerse por alguien externo sin conocer la nomenclatura interna del taller.

30. **Revisión final de lenguaje público**
Antes de cerrar una pieza, realizar revisión final de tildes, ortografía, microestilo, frases internas, expresiones coloquiales y anglicismos evitables.
La cara pública debe quedar en español profesional limpio, salvo términos técnicos realmente necesarios.

31. **Eliminar tono interno en la versión final**
Traducir o eliminar formulaciones que suenen a conversación interna, auditoría o cocina del proyecto.
La pieza final no debe leerse como nota entre colaboradores.

32. **Interpretación sustantiva con entidad visual**
Si existe un resultado central claramente interpretable, su interpretación debe tener visibilidad suficiente (caja, bloque o sección breve destacada con sobriedad).
No debe quedar enterrada como párrafo suelto.

33. **Legibilidad en bloques de datos y variables**
Los bloques de “Datos y variables” deben priorizar lectura clara.
Si el ancho es limitado, evitar texto corrido excesivo y ordenar la información con separación visible (una línea por categoría o lista breve).

34. **Checklist de cierre visual-editorial**
Antes de cerrar, verificar además de contenido y método: limpieza del español, ausencia de lenguaje interno, visibilidad de la interpretación sustantiva y legibilidad de cajas informativas.

35. **Pregunta sustantiva primero**
La pregunta principal debe formular con claridad el efecto de qué sobre qué, en lenguaje humano y sustantivo.
Evitar que los nombres internos de variables sean la primera puerta de entrada visual salvo necesidad real.

36. **Respuesta corta opcional pero recomendable**
Cuando la pieza tiene pregunta central clara, evaluar si conviene una "respuesta corta" inmediata debajo de la pregunta para orientar lectura.
No es obligatoria en todos los casos, pero sí recomendable cuando mejora legibilidad.

37. **Contenido mínimo de "Datos y variables"**
El bloque de "Datos y variables" debe definir explícitamente: unidad de análisis, tratamiento, resultado, covariables relevantes y población objetivo.
Debe mantener claridad técnica sin sonar a volcado crudo de log o lista de código.

38. **Transformaciones internas en lenguaje público**
No exponer transformaciones internas como frase principal visible si no agregan interpretación.
Preferir formulación pública (por ejemplo, "logaritmo del gasto total del hogar") y dejar la sintaxis exacta en segundo plano cuando haga falta.

39. **Interpretación del efecto dependiente del diseño**
La interpretación pública del efecto debe depender de la definición concreta de Y, del tratamiento y del estimando; no de una fórmula repetida por reflejo.
Si Y está en log y el tratamiento es binario, revisar cuidadosamente la forma más comunicable y correcta.
Si el resultado es binario, comunicar en puntos porcentuales cuando corresponda.

40. **Lenguaje causal con firmeza sobria**
Cuando la pieza se apoya en un diseño causal observacional ya fijado y el estimando es interpretable causalmente dentro de ese marco, no degradar innecesariamente a "asociación".
Evitar fórmulas débiles o torpes; comunicar con sobriedad que el efecto es causal dentro del diseño y para la población objetivo.

41. **Alcance con prudencia no defensiva**
La sección de alcance debe enfatizar para qué población vale la interpretación, bajo qué diseño y con qué prudencia debe leerse.
No convertir el alcance en lista defensiva de negaciones que debilite la pieza.

42. **Tablas públicas orientadas a decisión**
Las tablas deben cumplir función clara de lectura/decisión y no acumular variantes innecesarias.
Usar rótulos de filas y columnas públicos (evitar etiquetas internas como "Referencia base del taller"; preferir "Referencia comparativa" o "Especificación de referencia").
Si aparece sigla ambigua para lector externo (por ejemplo, "AI"), aclararla o expandirla.

43. **Convención consistente de inferencia**
Si una especificación se estimó en versión base y luego con bootstrap, y bootstrap es la versión a reportar, preferir públicamente esos errores estándar.
No mezclar versiones de inferencia de forma confusa dentro de la misma tabla pública.

44. **No sobredimensionar contrastes auxiliares**
Si un contraste metodológico intermedio (por ejemplo, `common` vs `trim(10)`) no es el núcleo del mensaje, no presentarlo como conclusión central.
Subordinar contrastes auxiliares al mensaje metodológico y sustantivo principal.

45. **Precisión formal en patrones de estimandos**
Al resumir patrones, evitar formulaciones ambiguas si puede declararse el orden con precisión.
En tratamientos multivaluados, priorizar expresiones tipo `ATET_3 > ATET_2 > ATET_1 > 0` cuando correspondan.

46. **Control de calidad en dos etapas**
Antes de renderizar una pieza nueva o muy editada: auditar el `.qmd` real y separar problemas narrativos, sustantivos y técnicos.
Después del render: revisar el HTML real (TOC, hero, CSS, layout, tablas, bloques visuales y lectura pública final).
Mantener como regla operativa que render exitoso no equivale a pieza bien curada.

47. **Disciplina explícita de BOM y front matter**
Mantener control activo sobre UTF-8 sin BOM y lectura correcta del front matter en todas las piezas.
Esta verificación no es opcional cuando se toque estructura o metadata.

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

**si la pieza puede mostrarse como trabajo profesional curado y si transmite criterio econométrico, no solo ejecución técnica.**
