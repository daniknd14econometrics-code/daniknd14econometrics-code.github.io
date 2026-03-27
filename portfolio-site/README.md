# Portfolio Site (local)

Este directorio contiene un sitio Quarto nuevo e independiente para portfolio profesional.

## Estructura creada

- `_quarto.yml`: configuración del sitio y navegación.
- `styles.css`: estilo visual sobrio y profesional.
- `index.qmd`: portada del portfolio.
- `econometria/index.qmd`: hub de 17 piezas.
- `econometria/piezas/*.qmd`: 17 fichas individuales con estructura estándar.
- `causalidad/index.qmd`: hub de la sección Causalidad.
- `causalidad/piezas/`: base para futuras fichas de Causalidad.
- `machine-learning/index.qmd`: hub de la sección Machine Learning.
- `machine-learning/piezas/`: base para futuras fichas de Machine Learning.
- `_plantillas/ficha-base.qmd`: plantilla base reutilizable para fichas.
- `sobre-mi.qmd`: perfil profesional.

## Estado

- Preparado para render local.
- Sin deploy, sin publicación y sin configuración de GitHub Pages.
- No se modificó contenido fuera de `portfolio-site/`.

## Convenciones de nombres (futuro)

- Causalidad: `c01_slug-tema.qmd`, `c02_slug-tema.qmd`, ...
- Machine Learning: `ml01_slug-tema.qmd`, `ml02_slug-tema.qmd`, ...

## Próximo paso sugerido

Revisar textos y metadatos de las 17 fichas, y luego decidir si los HTML curados se integran por enlace (actual) o por copia controlada de artefactos públicos al propio `portfolio-site/`.
