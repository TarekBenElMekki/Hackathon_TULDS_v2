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

function Patch-TextFile {
  param(
    [string]$Path,
    [scriptblock]$PatchBlock
  )

  if (!(Test-Path -LiteralPath $Path)) {
    Write-Warn "Missing file, skipped: $Path"
    return
  }

  $text = Get-Content -LiteralPath $Path -Raw
  $newText = & $PatchBlock $text

  if ($newText -ne $text) {
    Write-Utf8NoBomFile -Path $Path -Content $newText
    Write-Ok "Patched: $Path"
  } else {
    Write-Warn "No changes needed: $Path"
  }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$dashboardFile = Join-Path $root "src\components\dashboard-f1.tsx"
$adminApiFile  = Join-Path $root "src\app\admin\api\page.tsx"
$cssFile       = Join-Path $root "src\app\globals.css"

if (!(Test-Path -LiteralPath $dashboardFile)) { throw "Missing file: $dashboardFile" }
if (!(Test-Path -LiteralPath $cssFile)) { throw "Missing file: $cssFile" }

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-bullaregia-exclude-virtual-global12-v0_69-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item -LiteralPath $dashboardFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force
if (Test-Path -LiteralPath $adminApiFile) {
  Copy-Item -LiteralPath $adminApiFile -Destination (Join-Path $backupDir "admin-api-page.tsx") -Force
}

Write-Ok "Backup created: $backupDir"

# ------------------------------------------------------------
# Patch dashboard-f1.tsx
# ------------------------------------------------------------
Patch-TextFile -Path $dashboardFile -PatchBlock {
  param($tsx)

  # Add BullaRegia ID mapping.
  if ($tsx -match 'const\s+LC_NAME_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{') {
    if ($tsx -notmatch '"6707"\s*:\s*"BullaRegia"') {
      $tsx = [regex]::Replace(
        $tsx,
        '(const\s+LC_NAME_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{)',
        '$1' + "`r`n  `"6707`": `"BullaRegia`",",
        1
      )
    }
  }

  # Add label mapping for BullaRegia too.
  if ($tsx -match 'const\s+LC_LABEL_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{') {
    if ($tsx -notmatch '"bullaregia"\s*:\s*"BullaRegia"') {
      $tsx = [regex]::Replace(
        $tsx,
        '(const\s+LC_LABEL_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{)',
        '$1' + "`r`n  `"bullaregia`": `"BullaRegia`",`r`n  `"bulla regia`": `"BullaRegia`",",
        1
      )
    }
  }

  # Insert excluded IDs constant after mapping block if it does not exist.
  if ($tsx -notmatch 'EXCLUDED_RANKING_IDS') {
    if ($tsx -match '/\* === REAL API LC NAME MAP v0_61 END === \*/') {
      $tsx = $tsx.Replace(
        '/* === REAL API LC NAME MAP v0_61 END === */',
        '/* === REAL API LC NAME MAP v0_61 END === */' + "`r`nconst EXCLUDED_RANKING_IDS = new Set([`"2156`", `"2157`"]);"
      )
    } else {
      $tsx = [regex]::Replace(
        $tsx,
        '(const\s+COLORS\s*=\s*\[[\s\S]*?\];)',
        '$1' + "`r`n`r`nconst EXCLUDED_RANKING_IDS = new Set([`"2156`", `"2157`"]);",
        1
      )
    }
  }

  # Exclude 2156 and 2157 from buildRows filter.
  $tsx = [regex]::Replace(
    $tsx,
    '\.filter\(\(row\)\s*=>\s*String\(row\.row_id\s*\?\?\s*""\)\.toLowerCase\(\)\s*!==\s*"global"\)',
    '.filter((row) => String(row.row_id ?? "").toLowerCase() !== "global" && !EXCLUDED_RANKING_IDS.has(String(row.row_id ?? "").trim()))',
    1
  )

  # Older buildRows variant safety.
  $tsx = [regex]::Replace(
    $tsx,
    '\.filter\(\(row\)\s*=>\s*String\(row\.row_id\s*\?\?\s*""\)\s*!==\s*"global"\)',
    '.filter((row) => String(row.row_id ?? "") !== "global" && !EXCLUDED_RANKING_IDS.has(String(row.row_id ?? "").trim()))',
    1
  )

  # Change global carousel visible rows from 7 to 12 in component logic.
  $tsx = $tsx.Replace('rankedRows.length <= 7', 'rankedRows.length <= 12')
  $tsx = $tsx.Replace('Math.min(7, rankedRows.length)', 'Math.min(12, rankedRows.length)')

  # Fix status text if present.
  $tsx = $tsx.Replace('Visible rows: exactly 7', 'Visible rows: exactly 12')

  return $tsx
}

# ------------------------------------------------------------
# Patch admin/api page too, if it exists
# ------------------------------------------------------------
Patch-TextFile -Path $adminApiFile -PatchBlock {
  param($tsx)

  if ($tsx -match 'const\s+LC_NAME_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{') {
    if ($tsx -notmatch '"6707"\s*:\s*"BullaRegia"') {
      $tsx = [regex]::Replace(
        $tsx,
        '(const\s+LC_NAME_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{)',
        '$1' + "`r`n  `"6707`": `"BullaRegia`",",
        1
      )
    }
  }

  if ($tsx -notmatch 'EXCLUDED_RANKING_IDS') {
    $tsx = [regex]::Replace(
      $tsx,
      '(const\s+LC_NAME_MAP\s*:\s*Record<string,\s*string>\s*=\s*\{[\s\S]*?\};)',
      '$1' + "`r`n`r`nconst EXCLUDED_RANKING_IDS = new Set([`"2156`", `"2157`"]);",
      1
    )
  }

  # Exclude virtual IDs from admin LC rows too.
  $tsx = [regex]::Replace(
    $tsx,
    'return\s+rows\.filter\(\(row\)\s*=>\s*String\(row\.row_id\s*\?\?\s*""\)\.toLowerCase\(\)\s*!==\s*"global"\);',
    'return rows.filter((row) => String(row.row_id ?? "").toLowerCase() !== "global" && !EXCLUDED_RANKING_IDS.has(String(row.row_id ?? "").trim()));',
    1
  )

  return $tsx
}

# ------------------------------------------------------------
# Patch CSS: global table 12 visible rows, full height
# ------------------------------------------------------------
Patch-TextFile -Path $cssFile -PatchBlock {
  param($css)

  $start = "/* === GLOBAL TABLE 12 ROWS v0_69 START === */"
  $end   = "/* === GLOBAL TABLE 12 ROWS v0_69 END === */"

  $startEsc = [regex]::Escape($start)
  $endEsc = [regex]::Escape($end)

  $css = [regex]::Replace($css, "(?s)$startEsc.*?$endEsc\s*", "")

  # Update old CSS variables if present.
  $css = $css -replace '--global-visible-rows:\s*7;', '--global-visible-rows: 12;'

  # Update hardcoded /7 calculations from previous global patches.
  $css = $css.Replace('/ 7) !important', '/ 12) !important')
  $css = $css.Replace('exactly 7', 'exactly 12')

  $patch = @'

/* === GLOBAL TABLE 12 ROWS v0_69 START === */

/* Global Approval Table: use the whole left card and display 12 ranked rows. */
.sketch-global-card {
  display: flex !important;
  flex-direction: column !important;
  min-height: 0 !important;
  overflow: hidden !important;
}

.sketch-global-card > .sketch-card-head {
  flex: 0 0 auto !important;
}

.sketch-global-card .sketch-global-carousel-window {
  flex: 1 1 auto !important;
  height: auto !important;
  max-height: none !important;
  min-height: 0 !important;
  overflow: hidden !important;
  display: flex !important;
  flex-direction: column !important;
}

.sketch-global-carousel-table {
  width: 100% !important;
  height: 100% !important;
  table-layout: fixed !important;
  border-collapse: separate !important;
  border-spacing: 0 !important;
}

.sketch-global-carousel-table thead th {
  height: 32px !important;
  padding: 0 9px !important;
  font-size: 9px !important;
  background: linear-gradient(180deg, #202938 0%, #111722 100%) !important;
  color: #f8fafc !important;
  z-index: 180 !important;
}

.sketch-global-carousel-row,
.sketch-global-carousel-table td {
  height: calc((100% - 32px) / 12) !important;
  min-height: 0 !important;
  padding: 0 9px !important;
  font-size: clamp(10px, 0.78vw, 14px) !important;
  line-height: 1.02 !important;
  vertical-align: middle !important;
}

.sketch-global-carousel-table .sketch-pos {
  font-size: clamp(12px, 0.9vw, 16px) !important;
  font-weight: 1000 !important;
}

.sketch-global-carousel-table .sketch-score {
  font-size: clamp(11px, 0.85vw, 15px) !important;
  font-weight: 1000 !important;
}

.sketch-global-carousel-table .sketch-team-label {
  font-size: clamp(10px, 0.78vw, 14px) !important;
  font-weight: 950 !important;
}

.sketch-global-carousel-table .sketch-color-bar {
  width: 4px !important;
  height: clamp(16px, 1.45vh, 24px) !important;
}

.sketch-global-carousel-window::before {
  height: 32px !important;
  z-index: 170 !important;
  background: linear-gradient(180deg, #202938 0%, #111722 100%) !important;
}

/* Global columns adjusted for 12 visible rows. */
.sketch-global-carousel-table th:nth-child(1),
.sketch-global-carousel-table td:nth-child(1) {
  width: 42px !important;
  text-align: center !important;
}

.sketch-global-carousel-table th:nth-child(3),
.sketch-global-carousel-table td:nth-child(3),
.sketch-global-carousel-table th:nth-child(4),
.sketch-global-carousel-table td:nth-child(4),
.sketch-global-carousel-table th:nth-child(5),
.sketch-global-carousel-table td:nth-child(5) {
  width: 50px !important;
  text-align: right !important;
}

/* === GLOBAL TABLE 12 ROWS v0_69 END === */
'@

  return $css.TrimEnd() + "`r`n`r`n" + $patch + "`r`n"
}

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

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "BULLAREGIA + EXCLUDE VIRTUAL + GLOBAL 12 v0_69" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Added mapping: 6707 => BullaRegia" -ForegroundColor White
Write-Host "Excluded IDs: 2156, 2157" -ForegroundColor White
Write-Host "Global left table: 12 visible rows" -ForegroundColor White
Write-Host "Backups: $backupDir" -ForegroundColor White
