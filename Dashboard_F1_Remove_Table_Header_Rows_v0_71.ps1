param(
  [string]$ProjectRoot = ".",
  [switch]$RunBuild
)

$ErrorActionPreference = "Stop"

function Write-Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }

function Write-Utf8NoBomFile {
  param([string]$Path, [string]$Content)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$cssFile = Join-Path $root "src\app\globals.css"

if (!(Test-Path -LiteralPath $cssFile)) {
  throw "Missing file: $cssFile"
}

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-remove-table-header-rows-v0_71-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force
Write-Ok "Backup created: $backupDir"

$css = Get-Content -LiteralPath $cssFile -Raw

$start = "/* === REMOVE TABLE HEADER ROWS v0_71 START === */"
$end   = "/* === REMOVE TABLE HEADER ROWS v0_71 END === */"

$startEsc = [regex]::Escape($start)
$endEsc = [regex]::Escape($end)

$css = [regex]::Replace(
  $css,
  "(?s)$startEsc.*?$endEsc\s*",
  ""
)

$patch = @'

/* === REMOVE TABLE HEADER ROWS v0_71 START === */

/* Remove the visible header thread / thead row from all dashboard tables. */
.sketch-table thead,
.sketch-table thead tr,
.sketch-table thead th,
.sketch-global-carousel-table thead,
.sketch-global-carousel-table thead tr,
.sketch-global-carousel-table thead th,
.sketch-carousel-table thead,
.sketch-carousel-table thead tr,
.sketch-carousel-table thead th,
.sketch-mini-table thead,
.sketch-mini-table thead tr,
.sketch-mini-table thead th,
.board-table thead,
.board-table thead tr,
.board-table thead th,
.data-table thead,
.data-table thead tr,
.data-table thead th,
.mini-board-table thead,
.mini-board-table thead tr,
.mini-board-table thead th,
.f1-card table thead,
.f1-card table thead tr,
.f1-card table thead th,
.mini-board table thead,
.mini-board table thead tr,
.mini-board table thead th,
.main-table-container table thead,
.main-table-container table thead tr,
.main-table-container table thead th {
  display: none !important;
  height: 0 !important;
  min-height: 0 !important;
  max-height: 0 !important;
  padding: 0 !important;
  margin: 0 !important;
  border: 0 !important;
  opacity: 0 !important;
  visibility: hidden !important;
  overflow: hidden !important;
}

/* Remove the old solid-header masks that were used to protect headers. */
.sketch-carousel-window::before,
.sketch-global-carousel-window::before,
.sketch-mini-table-window::before {
  display: none !important;
  content: none !important;
  height: 0 !important;
}

/* Global table: 12 rows now use full height because the header is gone. */
.sketch-global-carousel-row,
.sketch-global-carousel-table td {
  height: calc(100% / 12) !important;
}

/* Small product tables: keep exactly 5 visible rows, no header space. */
.sketch-product-card .sketch-carousel-window {
  height: calc(var(--small-table-row-h, 31px) * 5) !important;
  max-height: calc(var(--small-table-row-h, 31px) * 5) !important;
}

/* Make the first row start cleanly from the top. */
.sketch-table tbody,
.sketch-global-carousel-body,
.sketch-carousel-track-y {
  margin-top: 0 !important;
  padding-top: 0 !important;
}

/* Since headers are gone, allow rows to be a little larger/readable. */
.sketch-global-carousel-table td {
  padding-top: 0 !important;
  padding-bottom: 0 !important;
}

.sketch-mini-table td,
.sketch-carousel-table td {
  padding-top: 0 !important;
  padding-bottom: 0 !important;
}

/* Optional admin API table header removal too. */
.api-track-table thead,
.api-track-table thead tr,
.api-track-table thead th {
  display: none !important;
  height: 0 !important;
  padding: 0 !important;
  border: 0 !important;
}

/* === REMOVE TABLE HEADER ROWS v0_71 END === */
'@

$css = $css.TrimEnd() + "`r`n`r`n" + $patch + "`r`n"

Write-Utf8NoBomFile -Path $cssFile -Content $css
Write-Ok "Removed visible table header rows via final CSS override"

if ($RunBuild) {
  Write-Info "Running npm run build..."
  Push-Location $root
  try {
    npm run build
    if ($LASTEXITCODE -ne 0) {
      throw "npm run build failed with exit code $LASTEXITCODE"
    }
    Write-Ok "Build completed successfully"
  }
  finally {
    Pop-Location
  }
}
