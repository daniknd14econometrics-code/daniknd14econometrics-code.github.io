# Portfolio de econometría aplicada

Este repositorio separa la publicación web de sus materiales de trabajo:

- `portfolio-site/`: sitio público en Quarto y fuente canónica de todas las páginas publicadas.
- `econometria-clasica/`: insumos, talleres y materiales internos de econometría clásica.
- `causalidad/`: insumos, talleres y materiales internos de causalidad.
- `docs/`: playbooks, reglas y documentación transversal del proyecto.

Para nuevas piezas públicas, no crear una segunda estructura paralela del portfolio: el contenido web vive en `portfolio-site/`.

El sitio se genera con:

```powershell
quarto render "portfolio-site" --to html
```

La salida `_site/` es regenerable y no forma parte de la fuente canónica versionada.
