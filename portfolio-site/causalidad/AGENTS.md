# AGENTS.md

## Alcance de este AGENT

Este archivo regula la producción de piezas públicas de la sección `causalidad` dentro de `portfolio-sitecausalidad`.

Seguir obligatoriamente `docs/qmd-curation-playbook.md` como protocolo maestro de construcción de piezas públicas `.qmd`.
Si hay conflicto entre improvisación narrativa y el playbook, prevalece el playbook.

Debe leerse junto con el `causalidadAGENTS.md` ubicado más arriba en el repo.
Ese archivo define la jerarquía editorial general de la sección.
Este archivo define cómo debe verse, estructurarse y redactarse una pieza pública `.qmd`.

## Regla principal

No empezar desde cero.

Las piezas públicas de `causalidad` deben heredar el estándar ya logrado en las piezas curadas de `econometria-clasica`.
No crear una nueva estética, una nueva lógica narrativa ni una nueva forma de presentar resultados.

La referencia obligatoria es
- el estándar visual y narrativo de `econometria-clasica`
- la jerarquía editorial fijada en `causalidadAGENTS.md`
- los diagnósticos privados ya validados de cada taller

## Qué tipo de pieza se construye aquí

Las piezas públicas de `causalidad` no son
- apuntes de clase
- resúmenes de logs
- guías pedagógicas crudas
- transcripciones técnicas del do-file

Las piezas públicas sí deben ser
- piezas profesionales de portfolio
- sobrias
- narrativas
- visualmente limpias
- conceptualmente claras
- técnicamente serias, pero no abrumadoras

## Estructura esperada de una ficha pública

Cada `.qmd` debe tener una estructura narrativa clara y contenida.

Orden preferido

1. Apertura breve con la pregunta central
2. Contexto empírico mínimo pero suficiente
3. Qué problema econométrico o causal organiza la pieza
4. Qué comparación o decisión domina la lectura
5. Resultado principal, en una tabla o bloque central
6. Lectura final profesional y sobria
7. Diagnósticos o detalles técnicos solo como apoyo secundario

## Regla de jerarquía narrativa

La historia empírica debe ir primero.
La técnica debe sostener la historia, no reemplazarla.

No abrir una pieza con una cascada de comandos, supuestos o pruebas.
No enterrar la pregunta central bajo jerga econométrica desde el primer bloque.

Primero debe quedar claro
- qué se quiere estimar o decidir
- por qué la comparación es problemática o interesante
- qué aporta el método usado

## Regla sobre el tono

Usar tono profesional, claro y sobrio.

Evitar
- tono de clase
- tono coloquial
- tono celebratorio
- afirmaciones rimbombantes
- frases tipo “demuestra definitivamente”, “corrige por completo”, “prueba que”

Preferir
- formulaciones precisas
- cierres cautos
- lenguaje de evidencia y diseño
- distinción entre resultado, identificación y límite interpretativo

## Refuerzos de curaduría pública (obligatorios)

- TOC por defecto en piezas públicas; omitir solo en notas extremadamente breves donde no aporte navegación.
- Registro para lector externo; no redactar como conversación interna, diagnóstico privado ni nota de trabajo.
- Evitar lenguaje meta-editorial en la cara pública (por ejemplo: “pieza aplicada fuerte”, “en términos editoriales”, “apertura conceptual de la sección”, “respaldo metodológico”).
- Evaluar si conviene mostrar prefijos internos (`T1`, `T2`, etc.) en títulos visibles; si debilitan la presentación profesional, omitirlos.
- No alcanza con compilar o estar “correcto”: la pieza debe sentirse tan curada como las mejores piezas de `econometria-clasica`.
- Cuando haya pregunta empírica, causal o metodológica reconocible, debe abrir la pieza y encontrar respuesta clara y sobria al cierre.
- Si el material permite una historia narrativa clara, conservarla; la técnica la sostiene, no la reemplaza.
- Incluir orientación temprana para lector externo: unidad de análisis, resultado, variable principal/tratamiento y observables o controles clave cuando corresponda.
- Si los nombres de variables no son autoexplicativos, incluir bloque breve de “Datos y variables” con traducción a lenguaje humano.
- Cuando la pieza compare contra un análisis ingenuo, explicitar por qué esa comparación falla antes o alrededor del resultado principal.
- Elegir bloque visual según función: `metric-grid` para métricas headline; en piezas introductorias, preferir `quick-grid` o equivalente (pregunta, diseño del caso, variables clave).
- La brevedad no habilita vacíos: incluso piezas introductorias deben tener densidad empírica o metodológica suficiente para lector externo.
- Evitar redacción que asuma conocimiento previo del taller; la pieza debe ser legible para quien entra por primera vez.

## Regla sobre causalidad

No sobreactuar causalidad.

Siempre distinguir entre
- resultado empírico
- estrategia de identificación
- fortaleza del diseño
- límites de interpretación

Nunca transformar automáticamente un coeficiente en afirmación causal fuerte.
Nunca usar un no-rechazo de sobreidentificación como “prueba” de validez.
Nunca presentar una especificación débil como evidencia concluyente.

## Regla sobre tablas

Toda pieza debe tener una tabla o bloque central que organice la lectura.

La tabla principal debe ser
- corta
- limpia
- comparativa
- interpretable sin leer el log

No volcar tablas enormes del taller.
No mostrar salidas crudas de Stata como pieza central.

La tabla principal debe ayudar al lector a responder
- qué métodos o especificaciones se comparan
- qué decisión o resultado domina
- qué lectura final se sostiene

## Regla sobre gráficos

No incluir gráficos por decoración.

Solo incluir gráficos si agregan valor real a
- soporte
- overlap
- balance
- pesos
- primera etapa
- forma reducida
- lectura causal

Si un gráfico no mejora la comprensión, omitirlo.

Preferencias por bloque
- matching  PSM overlap, balance, soporte
- IPWRA love plots, overlap ponderado, pesos
- IV gráficos descriptivos solo si ayudan a leer primera etapa o forma reducida

No saturar la ficha con demasiados gráficos.

## Regla sobre diagnósticos técnicos

Los diagnósticos técnicos deben existir, pero no dominar visualmente la pieza.

Ubicarlos
- después del resultado principal
- en cajas breves
- en notas secundarias
- o en subsecciones compactas

No construir la pieza alrededor de tests y comandos.
La pregunta central debe seguir siendo visible.

## Regla sobre selectores

Los talleres tipo selector no deben convertirse automáticamente en fichas públicas autónomas aquí.

Su función normal es respaldar técnicamente una pieza principal.

Aplicación actual
- T3 respalda T2
- T5 respalda T4
- T7 respalda T6

Si una pieza principal depende de un selector, debe mencionarlo brevemente como capa de decisión, sin convertir la ficha pública en una auditoría del selector.

## Mapa editorial actual de producción

### Apertura breve conceptual
- T1

### Fichas públicas principales
- T2
- T4
- T6
- T8

### Respaldos metodológicos
- T3 para T2
- T5 para T4
- T7 para T6

## Orden preferido de construcción

1. T1
2. T2
3. T4
4. T6
5. T8

No producir T3, T5 o T7 como primeras fichas públicas autónomas salvo instrucción explícita.

## Reglas específicas por pieza

### T1
Debe ser breve.
No tratarlo como caso aplicado fuerte.
Su función es abrir la sección con una idea clara
por qué una diferencia de medias no equivale a efecto causal.

### T2
Es pieza principal del bloque matching.
Debe incorporar la decisión final respaldada por T3.
No dejarlo como comparación metodológica abierta.

### T4
Es pieza principal del bloque PSM.
Debe salir ya cerrada con la regla de diseño respaldada por T5.
No dejar formulaciones provisionales.

### T6
Es pieza principal del bloque IPWRA.
Debe quedar explícito que corre sobre el diseño ganador elegido en T7.
La pieza visible es T6; T7 queda subordinado.

### T8
Debe escribirse como pieza metodológica cauta.
No presentarlo como triunfo limpio de IV.
La enseñanza central es que una estrategia IV rica puede volverse frágil.

## Qué evitar al redactar

Evitar
- copiar la secuencia del do-file
- citar demasiados tests en cadena
- duplicar resultados equivalentes
- usar jerga innecesaria
- hacer conclusiones más fuertes que el diagnóstico privado
- repetir bloques o títulos redundantes
- llenar la página con tablas secundarias

## Qué sí hacer al redactar

Hacer
- una apertura con una pregunta clara
- una narrativa que priorice la decisión central
- una tabla principal limpia
- uno o pocos gráficos con función real
- una conclusión breve, seria y recordable
- una conexión visible entre método y problema empírico

## Regla operativa

Antes de crear o editar un `.qmd` aquí

1. leer el diagnóstico privado correspondiente
2. verificar su rol editorial en `causalidadAGENTS.md`
3. confirmar si es ficha principal, apertura breve o respaldo
4. recién después producir la pieza pública

Si hay conflicto entre
- lo que sugiere el log
- lo que parece tentador narrativamente
- y lo que fija el diagnóstico privado

debe prevalecer el diagnóstico privado ya validado.

## Definición de “hecho”

Una pieza pública se considera bien hecha cuando
- se parece en calidad y tono a `econometria-clasica`
- no parece apunte de clase
- tiene una pregunta central clara
- tiene una lectura dominante clara
- usa técnica sin perder sobriedad
- no sobreactúa causalidad
- y puede mostrarse como pieza profesional de portfolio
