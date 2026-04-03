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

## Criterios operativos vigentes (visual/editorial)

Este README resume criterios operativos ya consolidados.
El contrato maestro sigue siendo `docs/qmd-curation-playbook.md`.

- `home`: hero visual fuerte pero sobrio.
- `portales de sección`: hero + sistema visual consistente.
- `piezas individuales`: estética editorial clara, con fondo claro y lectura larga cómoda.
- `piezas individuales`: no usar imagen de fondo en todo el cuerpo del artículo.
- intervenir por defecto con microajustes compatibles y no invasivos; no rediseñar una pieza que ya funciona.
- priorizar fidelidad de contenido y estructura; sobreeditar una pieza consolidada es regresión editorial.
- si hay conflicto entre rediseño global y pieza individual consolidada, priorizar la pieza.
- cuando exista versión canónica/original consolidada, usarla como fuente de verdad ante regresiones visuales.

## Próximo paso sugerido

Revisar textos y metadatos de las 17 fichas, y luego decidir si los HTML curados se integran por enlace (actual) o por copia controlada de artefactos públicos al propio `portfolio-site/`.
