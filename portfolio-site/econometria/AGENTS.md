# AGENTS.md

## Alcance de este AGENT

Este archivo regula la producción pública de `portfolio-site/econometria`.

Debe leerse junto con:
- `docs/qmd-curation-playbook.md` (contrato maestro)
- `econometria-clasica/AGENTS.md` (contrato específico de sección)

Regla de precedencia:
- si una regla general del playbook entra en tensión con una regla específica de `econometria-clasica`, prevalece la regla específica de sección en esta carpeta.

Estas reglas son específicas de econometría clásica y no deben extrapolarse automáticamente a `causalidad` ni a futuros bloques de `ML`.

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

## Tono y control editorial

- Tono profesional, sobrio y externo.
- Evitar metadiscurso interno y lenguaje coloquial.
- Evitar afirmaciones más fuertes que la evidencia.
- Antes de cerrar, verificar que la pieza responda en una línea: qué se estimó, qué lectura domina y bajo qué alcance.

## Control técnico mínimo

- Mantener UTF-8 sin BOM.
- Si se toca estructura/base del `.qmd`, verificar metadata antes de render.
- Después de render, revisar HTML real (TOC/layout/CSS/bloques principales); compilar no equivale a curar.
