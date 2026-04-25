param(
  [string]$ProjectRoot = ".",
  [switch]$RunBuild
)

$ErrorActionPreference = "Stop"

function Write-Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "[OK] $m" -ForegroundColor Green }

function Write-Utf8NoBomFile {
  param([string]$Path, [string]$Content)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$tsxFile = Join-Path $root "src\components\dashboard-f1.tsx"
$cssFile = Join-Path $root "src\app\globals.css"

if (!(Test-Path -LiteralPath $tsxFile)) { throw "Missing file: $tsxFile" }
if (!(Test-Path -LiteralPath $cssFile)) { throw "Missing file: $cssFile" }

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-remove-table-status-chips-v0_72-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force

Write-Ok "Backup created: $backupDir"

# ------------------------------------------------------------
# Remove JSX status chip from dashboard-f1.tsx
# ------------------------------------------------------------
$tsx = Get-Content -LiteralPath $tsxFile -Raw

$tsx = [regex]::Replace(
  $tsx,
  '(?s)\s*<div\s+className="sketch-global-carousel-status">\s*.*?\s*</div>\s*',
  "`r`n"
)

# Remove any accidental HTML className/class variants if pasted/generated differently.
$tsx = [regex]::Replace(
  $tsx,
  '(?s)\s*<div\s+class="sketch-global-carousel-status">\s*.*?\s*</div>\s*',
  "`r`n"
)

Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
Write-Ok "Removed sketch-global-carousel-status JSX"

# ------------------------------------------------------------
# Add CSS safety hide for any remaining similar chips
# ------------------------------------------------------------
$css = Get-Content -LiteralPath $cssFile -Raw

$start = "/* === REMOVE TABLE STATUS CHIPS v0_72 START === */"
$end   = "/* === REMOVE TABLE STATUS CHIPS v0_72 END === */"

$startEsc = [regex]::Escape($start)
$endEsc = [regex]::Escape($end)

$css = [regex]::Replace($css, "(?s)$startEsc.*?$endEsc\s*", "")

$patch = @'

/* === REMOVE TABLE STATUS CHIPS v0_72 START === */

/* Remove global/table floating status chips like "ALL RANKED LCs ... TOTAL". */
.sketch-global-carousel-status,
[class*="carousel-status"],
[class*="table-status"],
[class*="ranking-status"] {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  pointer-events: none !important;
}

/* === REMOVE TABLE STATUS CHIPS v0_72 END === */
'@

$css = $css.TrimEnd() + "`r`n`r`n" + $patch + "`r`n"

Write-Utf8NoBomFile -Path $cssFile -Content $css
Write-Ok "Added CSS safety hide for table status chips"

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
