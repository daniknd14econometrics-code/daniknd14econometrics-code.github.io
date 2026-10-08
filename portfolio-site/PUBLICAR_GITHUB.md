# Procedimiento permanente de desarrollo y publicación en GitHub Pages

Este documento define el flujo canónico y seguro para desarrollar, renderizar y publicar el sitio personal construido con Quarto. Debe usarse como lista de comprobación por la persona responsable y por Codex.

## Ubicaciones vigentes

Repositorio fuente y raíz Git de desarrollo:

~~~text
C:\Users\dani-\OneDrive\Documentos\REPOSITORIO APPS\APP repositorio github_quarto
~~~

Proyecto Quarto:

~~~text
C:\Users\dani-\OneDrive\Documentos\REPOSITORIO APPS\APP repositorio github_quarto\portfolio-site
~~~

Salida renderizada, según project.output-dir en _quarto.yml:

~~~text
C:\Users\dani-\OneDrive\Documentos\REPOSITORIO APPS\APP repositorio github_quarto\portfolio-site\_site
~~~

Repositorio local fijo de publicación:

~~~text
C:\Users\dani-\OneDrive\Documentos\REPOSITORIO APPS\portfolio-publicacion-github-pages
~~~

Repositorio GitHub y sitio público:

~~~text
https://github.com/daniknd14econometrics-code/daniknd14econometrics-code.github.io
https://daniknd14econometrics-code.github.io/
~~~

Ambos repositorios locales usan este remoto:

~~~text
origin = https://github.com/daniknd14econometrics-code/daniknd14econometrics-code.github.io.git
~~~

## Arquitectura Git

Existen dos historias con funciones distintas y deliberadamente separadas.

### master: proyecto fuente

La rama master del repositorio fuente contiene el proyecto Quarto completo:

- archivos QMD;
- CSS y recursos;
- assets;
- configuración _quarto.yml;
- documentación y materiales de desarrollo.

La edición se realiza en master. El proyecto portfolio-site no es una raíz Git independiente: su raíz Git es el directorio padre APP repositorio github_quarto.

### main: sitio público renderizado

La rama main del repositorio fijo portfolio-publicacion-github-pages contiene solamente el sitio renderizado que sirve GitHub Pages.

La única fuente del despliegue es:

~~~text
portfolio-site\_site
~~~

No deben copiarse a main:

- archivos .qmd ni otras fuentes del proyecto;
- .quarto, .quarto-localappdata o caches;
- auditorías o diagnósticos;
- backups;
- scripts, datos privados o archivos auxiliares.

## Reglas críticas

- No hacer merge ni rebase entre master y main.
- No cambiar de rama en el repositorio fuente para publicar.
- No usar la rama local main del repositorio fuente como destino de publicación.
- No crear worktrees temporales para el despliegue habitual.
- No hacer force push.
- No ejecutar git clean, git reset --hard, git checkout -- . ni operaciones equivalentes de descarte.
- No asumir que un hash histórico sigue vigente; comprobar siempre las referencias actuales.
- No crear commits ni ejecutar git push sin autorización humana expresa.
- No publicar si algún control falla o existe una divergencia no explicada.

## Herramientas y autenticación

La versión canónica de renderizado es Quarto 1.10.19. Antes de renderizar:

~~~powershell
where.exe quarto
quarto --version
quarto check install
~~~

Si quarto --version no devuelve exactamente 1.10.19, detenerse y aclarar la versión antes de modificar _site.

Git usa HTTPS con Git Credential Manager:

~~~powershell
git credential-manager --version
git config --show-origin --get-all credential.helper
~~~

No se presupone que exista una sesión autenticada. Una operación autenticada, como el primer push, puede abrir el navegador. No mostrar, copiar ni guardar tokens en archivos, comandos, logs o mensajes. GitHub CLI no es un requisito de este procedimiento.

## Preparación de la sesión

Abrir PowerShell y definir las rutas una sola vez:

~~~powershell
$sourceRepo = 'C:\Users\dani-\OneDrive\Documentos\REPOSITORIO APPS\APP repositorio github_quarto'
$quartoProject = Join-Path $sourceRepo 'portfolio-site'
$renderedSite = Join-Path $quartoProject '_site'
$publishRepo = 'C:\Users\dani-\OneDrive\Documentos\REPOSITORIO APPS\portfolio-publicacion-github-pages'
~~~

Validar rutas y raíces Git:

~~~powershell
foreach ($path in @($sourceRepo, $quartoProject, $publishRepo)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "No existe el directorio esperado: $path"
    }
}

$sourceTop = (git -C $sourceRepo rev-parse --show-toplevel).Replace('/', '\')
$publishTop = (git -C $publishRepo rev-parse --show-toplevel).Replace('/', '\')

if (-not [string]::Equals($sourceTop, $sourceRepo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Raíz Git fuente inesperada: $sourceTop"
}

if (-not [string]::Equals($publishTop, $publishRepo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Raíz Git de publicación inesperada: $publishTop"
}
~~~

## 1. Comprobar el repositorio fuente

Confirmar que el trabajo continúa en master:

~~~powershell
git -C $sourceRepo branch --show-current
git -C $sourceRepo rev-parse HEAD
git -C $sourceRepo remote -v
git -C $sourceRepo status --short --branch --untracked-files=all
~~~

La rama debe ser master. Si no lo es, detenerse; no cambiar de rama automáticamente.

El repositorio fuente puede contener cambios locales y archivos sin seguimiento legítimos. Antes de editar o renderizar:

1. Leer la lista completa de cambios.
2. Identificar cuáles pertenecen al trabajo aprobado.
3. Preservar todos los cambios preexistentes.
4. No añadir archivos en bloque sin revisar su procedencia.
5. No usar comandos de limpieza o descarte para intentar obtener un estado limpio.

Un árbol fuente sucio no autoriza a borrar nada. Si impide distinguir el alcance del trabajo, detenerse y pedir instrucciones.

## 2. Desarrollar y validar antes del render final

Realizar solamente los cambios expresamente aprobados dentro de master. Para revisión visual durante el desarrollo:

~~~powershell
Set-Location -LiteralPath $quartoProject
quarto preview
~~~

Revisar en el navegador las páginas modificadas, navegación, enlaces, imágenes, estilos y consola. Detener el servidor con Ctrl+C.

Antes del render final:

~~~powershell
quarto --version
git -C $sourceRepo status --short --branch --untracked-files=all
~~~

## 3. Renderizar con Quarto 1.10.19

El render requiere autorización para modificar portfolio-site\_site.

~~~powershell
Set-Location -LiteralPath $quartoProject
quarto render

if ($LASTEXITCODE -ne 0) {
    throw 'El render de Quarto falló. No continuar con la publicación.'
}
~~~

La configuración vigente establece project.output-dir: _site y formato HTML. No cambiar _quarto.yml durante el despliegue.

## 4. Validar la salida renderizada

~~~powershell
if (-not (Test-Path -LiteralPath (Join-Path $renderedSite 'index.html') -PathType Leaf)) {
    throw 'Falta _site\index.html.'
}

$htmlFiles = @(Get-ChildItem -LiteralPath $renderedSite -Recurse -File -Filter '*.html')
if ($htmlFiles.Count -eq 0) {
    throw 'La salida no contiene archivos HTML.'
}

$forbiddenSources = @(Get-ChildItem -LiteralPath $renderedSite -Recurse -File -Force |
    Where-Object { $_.Extension -in @('.qmd', '.Rmd', '.ipynb') })

if ($forbiddenSources.Count -gt 0) {
    $forbiddenSources.FullName
    throw 'La salida contiene fuentes que no deben publicarse.'
}
~~~

Revisar visualmente desde un servidor local:

- portada y navegación;
- páginas nuevas o modificadas;
- enlaces internos y externos;
- imágenes y hojas de estilo;
- ausencia de borradores o materiales privados no aprobados;
- robots.txt, sitemap.xml y la verificación de Google cuando correspondan.

No continuar si aparecen errores, rutas locales absolutas, fuentes, caches o contenido no aprobado.

## 5. Actualizar el repositorio fijo de publicación

Esta es la única copia local usada como destino. No crear worktrees temporales.

La rama debe ser main y el árbol debe estar completamente limpio:

~~~powershell
$publishBranch = git -C $publishRepo branch --show-current
$publishStatus = @(git -C $publishRepo status --porcelain=v1 --untracked-files=all)

if ($publishBranch -ne 'main') {
    throw "La rama de publicación no es main: $publishBranch"
}

if ($publishStatus.Count -ne 0) {
    $publishStatus
    throw 'El repositorio de publicación contiene cambios. No continuar.'
}

git -C $publishRepo remote -v
$remoteLine = git -C $publishRepo ls-remote --heads origin refs/heads/main
if ($LASTEXITCODE -ne 0 -or -not $remoteLine) {
    throw 'No fue posible consultar origin/main.'
}

$remoteHash = ($remoteLine -split '\s+')[0]

git -C $publishRepo fetch origin main
if ($LASTEXITCODE -ne 0) {
    throw 'Falló git fetch origin main.'
}

$originMain = git -C $publishRepo rev-parse origin/main
if ($originMain -ne $remoteHash) {
    throw 'origin/main no coincide con la referencia consultada en GitHub.'
}

git -C $publishRepo merge-base --is-ancestor main origin/main
if ($LASTEXITCODE -ne 0) {
    throw 'main no es ancestro de origin/main. Existe divergencia; detenerse.'
}

$localOnly = [int](git -C $publishRepo rev-list --count origin/main..main)
if ($localOnly -ne 0) {
    throw 'Existen commits locales exclusivos en main; detenerse.'
}

$incoming = [int](git -C $publishRepo rev-list --count main..origin/main)
Write-Host "Commits remotos a incorporar: $incoming"

git -C $publishRepo merge --ff-only origin/main
if ($LASTEXITCODE -ne 0) {
    throw 'No fue posible actualizar main mediante fast-forward.'
}
~~~

Después, comprobar que HEAD, main y origin/main coinciden y que el árbol sigue limpio.

## 6. Sincronizar _site con el repositorio de publicación

Esta etapa modifica solamente el árbol de trabajo del repositorio de publicación. No modifica el repositorio fuente ni publica por sí sola.

Antes de ejecutarla:

~~~powershell
git -C $publishRepo status --porcelain=v1 --untracked-files=all
Test-Path -LiteralPath (Join-Path $publishRepo '.git') -PathType Container
Test-Path -LiteralPath (Join-Path $publishRepo '.nojekyll') -PathType Leaf
~~~

El estado debe estar vacío y ambas comprobaciones deben devolver True.

Preservar siempre:

- .git;
- .nojekyll;
- CNAME, si se incorpora un dominio personalizado;
- .github, si en el futuro contiene configuración aprobada de GitHub.

Actualmente .nojekyll es el archivo especial presente. Si aparecen nuevos archivos de configuración, actualizar esta lista antes de sincronizar.

La sincronización canónica en Windows usa robocopy con espejo y exclusiones explícitas:

~~~powershell
$gitDir = Join-Path $publishRepo '.git'
$githubDir = Join-Path $publishRepo '.github'

$robocopyArgs = @(
    '/MIR'
    '/COPY:DAT'
    '/DCOPY:DAT'
    '/R:2'
    '/W:2'
    '/XJ'
    '/XD'
    $gitDir
    $githubDir
    '/XF'
    '.nojekyll'
    'CNAME'
)

& robocopy $renderedSite $publishRepo @robocopyArgs

$robocopyExit = $LASTEXITCODE
if ($robocopyExit -ge 8) {
    throw "Robocopy falló con código $robocopyExit. No crear commits ni publicar."
}
~~~

La opción /MIR elimina del repositorio de publicación archivos públicos obsoletos que ya no existen en _site. Solo debe ejecutarse después de validar exactamente ambas rutas y nunca contra el repositorio fuente.

Comprobar inmediatamente:

~~~powershell
if (-not (Test-Path -LiteralPath (Join-Path $publishRepo '.git') -PathType Container)) {
    throw 'Falta .git después de la sincronización.'
}

if (-not (Test-Path -LiteralPath (Join-Path $publishRepo '.nojekyll') -PathType Leaf)) {
    throw 'Falta .nojekyll después de la sincronización.'
}
~~~

## 7. Revisar antes de cualquier commit

~~~powershell
git -C $publishRepo status --short --branch --untracked-files=all
git -C $publishRepo diff --stat
git -C $publishRepo diff --name-status
git -C $publishRepo diff --check
~~~

La revisión debe confirmar que:

- todos los cambios corresponden al render aprobado;
- no se copiaron QMD, caches, diagnósticos, backups ni fuentes;
- .nojekyll permanece;
- no se eliminó ninguna configuración persistente;
- las eliminaciones de archivos públicos son intencionales;
- index.html y los recursos esenciales están presentes.

Si el diff es inesperado, detenerse. No corregirlo con limpieza destructiva. Mientras no exista commit ni push, los cambios permanecen únicamente en la copia local.

## 8. Crear el commit, solo con autorización expresa

No ejecutar esta sección durante una tarea de diagnóstico, render o preparación si no se autorizó explícitamente crear el commit.

~~~powershell
git -C $publishRepo add -A
git -C $publishRepo diff --cached --stat
git -C $publishRepo diff --cached --name-status
git -C $publishRepo diff --cached --check
~~~

Revisar nuevamente todo lo staged. Si es correcto:

~~~powershell
git -C $publishRepo commit -m 'Deploy approved portfolio'
~~~

No modificar master durante esta etapa.

## 9. Publicar, solo con autorización expresa de push

Antes del push, comprobar nuevamente que GitHub no avanzó mientras se preparaba el despliegue:

~~~powershell
git -C $publishRepo fetch origin main

git -C $publishRepo merge-base --is-ancestor origin/main HEAD
if ($LASTEXITCODE -ne 0) {
    throw 'El remoto cambió y ya no es ancestro del commit local. No publicar.'
}

$remoteOnly = [int](git -C $publishRepo rev-list --count HEAD..origin/main)
if ($remoteOnly -ne 0) {
    throw 'Hay commits remotos no incorporados. No publicar.'
}
~~~

Solo después de autorización humana explícita:

~~~powershell
git -C $publishRepo push origin main
~~~

Debe ser un push normal y fast-forward. Nunca usar --force ni --force-with-lease.

## 10. Verificar la publicación

Después de un push exitoso:

~~~powershell
$localHead = git -C $publishRepo rev-parse HEAD
$publishedLine = git -C $publishRepo ls-remote --heads origin refs/heads/main
$publishedHead = ($publishedLine -split '\s+')[0]

if ($localHead -ne $publishedHead) {
    throw 'El commit local no coincide con origin/main después del push.'
}

git -C $publishRepo status --short --branch --untracked-files=all
~~~

Esperar a que GitHub Pages termine el despliegue y revisar:

~~~text
https://daniknd14econometrics-code.github.io/
~~~

Comprobar portada, navegación, páginas modificadas, recursos, robots.txt y sitemap.xml. Informar el hash publicado y el resultado de la verificación.

## Prompt operativo para Codex

Usar un pedido explícito que delimite la autorización:

~~~text
Renderizá con Quarto 1.10.19 los cambios ya aprobados del proyecto
portfolio-site y validá la salida _site.

Seguí PUBLICAR_GITHUB.md y usá exclusivamente el repositorio fijo
portfolio-publicacion-github-pages como destino.

Antes de sincronizar, actualizá main mediante fetch y fast-forward únicamente.
Conservá .git y .nojekyll; no copies QMD, caches, auditorías, diagnósticos,
backups ni auxiliares. No mezcles master y main, no hagas rebase y no uses
force push.

Mostrame el diff de publicación y detenete antes del commit y del push salvo
que este mismo pedido los autorice de forma expresa.
~~~

Si la autorización incluye commit o push, debe decirlo explícitamente. Codex debe informar cada control, el número de commits incorporados, el commit de despliegue y el resultado final.

## Referencia histórica no operativa

En la computadora anterior se documentó como despliegue de referencia el commit f12c6a55bfdcd0aeb410f5c739a4ec2aa7f91e88, con el mensaje Deploy approved portfolio.

Este hash se conserva únicamente como antecedente histórico. No representa necesariamente el estado actual y nunca debe usarse para decidir un despliegue. La referencia vigente se obtiene siempre con git ls-remote, seguida de fetch y validaciones de ancestralidad.
