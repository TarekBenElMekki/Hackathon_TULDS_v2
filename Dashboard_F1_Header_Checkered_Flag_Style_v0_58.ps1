param(
  [string]$ProjectRoot = ".",
  [switch]$RunBuild
)

$ErrorActionPreference = "Stop"

function Write-Info($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

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
$backupDir = Join-Path $root ".backup-header-checkered-flag-style-v0_58-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force
Write-Ok "Backup created: $backupDir"

# ------------------------------------------------------------
# PATCH TSX
# ------------------------------------------------------------
$tsx = Get-Content -LiteralPath $tsxFile -Raw

if ($tsx -notmatch 'sketch-header-flag-deco') {
  $old = '<header className="sketch-header">'
  $new = @'
<header className="sketch-header">
          <div className="sketch-header-flag-deco" aria-hidden="true">
            <span className="sketch-header-flag-pole" />
            <span className="sketch-header-flag-cloth" />
          </div>
'@

  if ($tsx.Contains($old)) {
    $tsx = $tsx.Replace($old, $new)
    Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
    Write-Ok "Inserted decorative checkered-flag layer into header"
  }
  else {
    throw "Could not find <header className=""sketch-header""> in dashboard-f1.tsx"
  }
}
else {
  Write-Warn "Header decorative flag markup already exists; skipping TSX injection"
}

# ------------------------------------------------------------
# PATCH CSS
# ------------------------------------------------------------
$css = Get-Content -LiteralPath $cssFile -Raw

$start = "/* === HEADER CHECKERED FLAG STYLE v0_58 START === */"
$end   = "/* === HEADER CHECKERED FLAG STYLE v0_58 END === */"

$startEsc = [regex]::Escape($start)
$endEsc   = [regex]::Escape($end)

$css = [regex]::Replace(
  $css,
  "(?s)$startEsc.*?$endEsc\s*",
  ""
)

$patch = @'

/* === HEADER CHECKERED FLAG STYLE v0_58 START === */

.sketch-header {
  position: relative !important;
  isolation: isolate !important;
  overflow: hidden !important;
  background:
    radial-gradient(circle at 20% 12%, rgba(255,255,255,0.07), transparent 24%),
    radial-gradient(circle at 78% 10%, rgba(225,6,0,0.08), transparent 20%),
    linear-gradient(135deg, rgba(16,18,28,0.97), rgba(7,8,12,0.99)) !important;
  border-bottom: 3px solid #e10600 !important;
}

/* keep content above decoration */
.sketch-header > *:not(.sketch-header-flag-deco) {
  position: relative !important;
  z-index: 3 !important;
}

/* subtle checkered strip accent */
.sketch-header::after {
  content: "" !important;
  position: absolute !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  height: 10px !important;
  z-index: 2 !important;
  pointer-events: none !important;
  background:
    linear-gradient(90deg, #ffffff 0 18px, #0b0d12 18px 36px) 0 0 / 36px 100% repeat-x !important;
  opacity: 0.16 !important;
  box-shadow: 0 -1px 0 rgba(255,255,255,0.10) inset !important;
}

/* decorative flag group */
.sketch-header-flag-deco {
  position: absolute;
  right: clamp(150px, 19vw, 250px);
  top: 4px;
  width: 180px;
  height: 105px;
  z-index: 1;
  pointer-events: none;
  opacity: 0.34;
  transform: rotate(4deg);
  filter: drop-shadow(0 10px 20px rgba(0,0,0,0.34));
}

/* flag pole */
.sketch-header-flag-pole {
  position: absolute;
  left: 0;
  top: 10px;
  width: 7px;
  height: 94px;
  border-radius: 999px;
  background: linear-gradient(180deg, #d8ccb8 0%, #bca98c 100%);
  box-shadow:
    inset 1px 0 0 rgba(255,255,255,0.30),
    0 0 0 1px rgba(0,0,0,0.18);
}

.sketch-header-flag-pole::before {
  content: "";
  position: absolute;
  top: -4px;
  left: -2px;
  width: 12px;
  height: 8px;
  border-radius: 3px;
  background: linear-gradient(180deg, #d8ccb8 0%, #bca98c 100%);
  box-shadow: 0 0 0 1px rgba(0,0,0,0.18);
}

/* waving checkered cloth */
.sketch-header-flag-cloth {
  position: absolute;
  left: 10px;
  top: 0;
  width: 154px;
  height: 88px;
  border-radius: 8px 10px 14px 10px;
  transform:
    perspective(280px)
    rotateY(-18deg)
    skewY(-4deg)
    rotate(-2deg);
  clip-path: polygon(
    0% 10%, 17% 5%, 33% 11%, 52% 2%, 73% 8%, 100% 0%,
    100% 88%, 80% 96%, 60% 90%, 36% 100%, 17% 92%, 0% 98%,
    3% 78%, 0% 60%, 6% 41%, 0% 22%
  );
  background-color: #ffffff;
  background-image:
    linear-gradient(45deg, #050608 25%, transparent 25%, transparent 75%, #050608 75%, #050608),
    linear-gradient(45deg, #050608 25%, transparent 25%, transparent 75%, #050608 75%, #050608);
  background-size: 28px 28px;
  background-position: 0 0, 14px 14px;
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.15),
    0 12px 22px rgba(0,0,0,0.30);
}

.sketch-header-flag-cloth::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background:
    linear-gradient(180deg, rgba(255,255,255,0.28) 0%, rgba(255,255,255,0.04) 20%, rgba(0,0,0,0.18) 100%),
    radial-gradient(circle at 18% 30%, rgba(255,255,255,0.28), transparent 28%),
    radial-gradient(circle at 82% 76%, rgba(255,255,255,0.20), transparent 30%);
  mix-blend-mode: soft-light;
  opacity: 0.95;
}

.sketch-header-flag-cloth::after {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background:
    radial-gradient(circle at 18% 50%, rgba(255,255,255,0.14), transparent 24%),
    radial-gradient(circle at 44% 46%, rgba(255,255,255,0.11), transparent 18%),
    radial-gradient(circle at 73% 55%, rgba(255,255,255,0.12), transparent 20%);
  opacity: 0.90;
}

/* text side a bit cleaner against the new decoration */
.sketch-brand h1 {
  text-shadow: 0 2px 12px rgba(0,0,0,0.35) !important;
}

.sketch-kicker {
  color: #ff3b30 !important;
}

.sketch-header-metrics {
  position: relative;
  z-index: 4;
}

/* refine metric blocks so they still feel premium beside the flag style */
.sketch-metric,
.sketch-clock,
.sketch-refresh,
.sketch-control,
.sketch-live-pill {
  background: rgba(255,255,255,0.060) !important;
  border-color: rgba(255,255,255,0.12) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.05) !important;
}

/* responsive */
@media (max-width: 1200px) {
  .sketch-header-flag-deco {
    right: 110px;
    width: 150px;
    height: 92px;
    opacity: 0.28;
  }

  .sketch-header-flag-cloth {
    width: 130px;
    height: 74px;
    background-size: 24px 24px;
    background-position: 0 0, 12px 12px;
  }

  .sketch-header-flag-pole {
    height: 80px;
  }
}

@media (max-width: 900px) {
  .sketch-header-flag-deco {
    display: none !important;
  }

  .sketch-header::after {
    opacity: 0.13 !important;
  }
}

/* === HEADER CHECKERED FLAG STYLE v0_58 END === */
'@

$css = $css.TrimEnd() + "`r`n`r`n" + $patch + "`r`n"
Write-Utf8NoBomFile -Path $cssFile -Content $css
Write-Ok "Added checkered-flag inspired header styling"

if ($RunBuild) {
  Write-Info "Running npm run build..."
  Push-Location $root
  try {
    npm run build
    Write-Ok "Build completed"
  }
  finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "HEADER CHECKERED FLAG STYLE APPLIED v0_58" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Backups: $backupDir" -ForegroundColor White
