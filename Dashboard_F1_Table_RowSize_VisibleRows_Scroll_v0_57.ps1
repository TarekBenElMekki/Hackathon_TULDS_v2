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

function Replace-FirstRegexBlock {
  param(
    [string]$Text,
    [string]$Pattern,
    [string]$Replacement
  )

  $rx = [System.Text.RegularExpressions.Regex]::new(
    $Pattern,
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  $m = $rx.Match($Text)
  if (-not $m.Success) {
    throw "Pattern not found: $Pattern"
  }

  return $Text.Substring(0, $m.Index) + $Replacement + $Text.Substring($m.Index + $m.Length)
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$tsxFile = Join-Path $root "src\components\dashboard-f1.tsx"
$cssFile = Join-Path $root "src\app\globals.css"

if (!(Test-Path -LiteralPath $tsxFile)) { throw "Missing file: $tsxFile" }
if (!(Test-Path -LiteralPath $cssFile)) { throw "Missing file: $cssFile" }

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-table-row-size-visible-scroll-v0_57-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force

Write-Ok "Backup created: $backupDir"

# ------------------------------------------------------------
# PATCH TSX: make the big Global Approval table carousel-scroll too
# ------------------------------------------------------------
$tsx = Get-Content -LiteralPath $tsxFile -Raw

$newLeaderboard = @'
function LeaderboardTable({ rows }: { rows: BoardRow[] }) {
  const topRows = useMemo(() => rows.slice(0, 12), [rows]);
  const carouselRows = topRows.length > 0 ? [...topRows, ...topRows] : [];

  return (
    <div className="sketch-carousel-window sketch-global-carousel-window">
      <table className="sketch-table sketch-global-table sketch-global-carousel-table">
        <thead>
          <tr>
            <th>Pos</th>
            <th>ID / Entity</th>
            <th>App</th>
            <th>Appr</th>
            <th>Real</th>
          </tr>
        </thead>
        <tbody className="sketch-carousel-track-y sketch-global-carousel-track-y">
          {carouselRows.map((row, index) => (
            <tr key={`global-${row.rowId}-${index}`}>
              <td className="sketch-pos">{row.rank}</td>
              <td>
                <div className="sketch-team-cell">
                  <span className="sketch-color-bar" style={{ background: row.color }} />
                  <span className="sketch-team-label">{row.shortLabel}</span>
                </div>
              </td>
              <td>{row.appliedTotal}</td>
              <td className="sketch-score">{row.approvedTotal}</td>
              <td>{row.realizedTotal}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ProductTable
'@

$tsx = Replace-FirstRegexBlock `
  -Text $tsx `
  -Pattern 'function LeaderboardTable\(\{ rows \}: \{ rows: BoardRow\[\] \}\) \{.*?\n\}\n\nfunction ProductTable' `
  -Replacement $newLeaderboard

Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
Write-Ok "Updated Global table to use vertical carousel scrolling"

# ------------------------------------------------------------
# PATCH CSS
# ------------------------------------------------------------
$css = Get-Content -LiteralPath $cssFile -Raw

$start = "/* === TABLE ROW SIZE VISIBLE ROWS SCROLL v0_57 START === */"
$end   = "/* === TABLE ROW SIZE VISIBLE ROWS SCROLL v0_57 END === */"

$startEsc = [regex]::Escape($start)
$endEsc = [regex]::Escape($end)

$css = [regex]::Replace(
  $css,
  "(?s)$startEsc.*?$endEsc\s*",
  ""
)

$patch = @'

/* === TABLE ROW SIZE VISIBLE ROWS SCROLL v0_57 START === */

:root {
  --global-visible-rows: 7;
  --small-visible-rows: 5;

  --global-table-head-h: 30px;
  --global-table-row-h: 34px;

  --small-table-head-h: 28px;
  --small-table-row-h: 31px;
}

/* Let table cards allocate enough vertical space for readable rows. */
.sketch-global-card {
  min-height: 0 !important;
}

.sketch-product-card {
  min-height: 0 !important;
}

/* Bigger card headers but still compact enough for the dashboard. */
.sketch-card-head {
  min-height: 52px !important;
  padding: 10px 12px !important;
}

.sketch-mini-head {
  min-height: 46px !important;
  padding: 8px 10px !important;
}

.sketch-card-head h2 {
  font-size: 18px !important;
}

.sketch-card-head h3 {
  font-size: 16px !important;
}

.sketch-card-head p {
  font-size: 9px !important;
}

/* Shared carousel window behavior. */
.sketch-carousel-window {
  position: relative !important;
  z-index: 2 !important;
  overflow: hidden !important;
  width: 100% !important;
  flex: 0 0 auto !important;
}

/* Big table: exactly 7 visible rows + header. */
.sketch-global-carousel-window {
  height: calc(var(--global-table-head-h) + (var(--global-table-row-h) * var(--global-visible-rows))) !important;
  max-height: calc(var(--global-table-head-h) + (var(--global-table-row-h) * var(--global-visible-rows))) !important;
}

/* Small tables: exactly 5 visible rows + header. */
.sketch-product-card .sketch-carousel-window {
  height: calc(var(--small-table-head-h) + (var(--small-table-row-h) * var(--small-visible-rows))) !important;
  max-height: calc(var(--small-table-head-h) + (var(--small-table-row-h) * var(--small-visible-rows))) !important;
}

/* Important: use separate borders so sticky/solid headers paint cleanly. */
.sketch-global-carousel-table,
.sketch-carousel-table,
.sketch-mini-table,
.sketch-global-table {
  border-collapse: separate !important;
  border-spacing: 0 !important;
  table-layout: fixed !important;
}

/* Solid fixed header layer. */
.sketch-table thead {
  position: sticky !important;
  top: 0 !important;
  z-index: 120 !important;
}

.sketch-table thead tr,
.sketch-table thead th {
  position: sticky !important;
  top: 0 !important;
  z-index: 130 !important;
  background: linear-gradient(180deg, #202938 0%, #111722 100%) !important;
  background-color: #111722 !important;
  opacity: 1 !important;
  color: #f8fafc !important;
  text-shadow: none !important;
  box-shadow:
    0 2px 0 rgba(225, 6, 0, 0.72),
    0 8px 14px rgba(0, 0, 0, 0.72) !important;
}

/* Big table sizing. */
.sketch-global-table th {
  height: var(--global-table-head-h) !important;
  padding: 0 9px !important;
  font-size: 9px !important;
  line-height: 1 !important;
}

.sketch-global-table td {
  height: var(--global-table-row-h) !important;
  padding: 0 9px !important;
  font-size: 12px !important;
  line-height: 1.05 !important;
}

/* Small table sizing. */
.sketch-mini-table th,
.sketch-carousel-table th {
  height: var(--small-table-head-h) !important;
  padding: 0 8px !important;
  font-size: 8.5px !important;
  line-height: 1 !important;
}

.sketch-mini-table td,
.sketch-carousel-table td {
  height: var(--small-table-row-h) !important;
  padding: 0 8px !important;
  font-size: 11px !important;
  line-height: 1.05 !important;
}

/* Bigger rank and score emphasis. */
.sketch-pos {
  font-size: 13px !important;
  font-weight: 1000 !important;
}

.sketch-score {
  font-size: 12px !important;
  font-weight: 1000 !important;
}

.sketch-global-table .sketch-pos {
  font-size: 14px !important;
}

.sketch-global-table .sketch-score {
  font-size: 13px !important;
}

/* Bigger content labels. */
.sketch-team-label {
  font-size: inherit !important;
  font-weight: 900 !important;
}

.sketch-team-cell {
  gap: 7px !important;
}

.sketch-color-bar {
  width: 4px !important;
  height: 20px !important;
}

.sketch-color-dot {
  width: 8px !important;
  height: 8px !important;
}

/* Body rows remain behind the header. */
.sketch-table tbody,
.sketch-table tbody tr,
.sketch-table tbody td {
  position: relative !important;
  z-index: 1 !important;
}

/* Smooth vertical auto-scroll for small and big tables. */
.sketch-carousel-track-y {
  animation: sketchTableScrollY 18s linear infinite !important;
  will-change: transform !important;
}

.sketch-product-card .sketch-carousel-track-y {
  animation-duration: 16s !important;
}

.sketch-global-carousel-track-y {
  animation-duration: 20s !important;
}

/* Pause on hover for easier reading. */
.sketch-carousel-window:hover .sketch-carousel-track-y {
  animation-play-state: paused !important;
}

@keyframes sketchTableScrollY {
  0% {
    transform: translateY(0);
  }
  48% {
    transform: translateY(-50%);
  }
  50% {
    transform: translateY(-50%);
  }
  100% {
    transform: translateY(0);
  }
}

/* Hard mask under every table header so scrolling content never bleeds behind it. */
.sketch-carousel-window::before,
.sketch-global-carousel-window::before {
  content: "" !important;
  position: absolute !important;
  left: 0 !important;
  right: 0 !important;
  top: 0 !important;
  z-index: 110 !important;
  pointer-events: none !important;
  background: linear-gradient(180deg, #202938 0%, #111722 100%) !important;
  border-bottom: 1px solid rgba(255,255,255,0.22) !important;
  box-shadow:
    0 2px 0 rgba(225, 6, 0, 0.72),
    0 8px 14px rgba(0, 0, 0, 0.72) !important;
}

.sketch-global-carousel-window::before {
  height: var(--global-table-head-h) !important;
}

.sketch-product-card .sketch-carousel-window::before {
  height: var(--small-table-head-h) !important;
}

/* Header text always above mask. */
.sketch-carousel-table thead,
.sketch-global-carousel-table thead,
.sketch-mini-table thead {
  position: relative !important;
  z-index: 140 !important;
}

/* Column widths adjusted for larger content. */
.sketch-global-table th:nth-child(1),
.sketch-global-table td:nth-child(1) {
  width: 42px !important;
  text-align: center !important;
}

.sketch-global-table th:nth-child(3),
.sketch-global-table td:nth-child(3),
.sketch-global-table th:nth-child(4),
.sketch-global-table td:nth-child(4),
.sketch-global-table th:nth-child(5),
.sketch-global-table td:nth-child(5) {
  width: 52px !important;
  text-align: right !important;
}

.sketch-mini-table th:nth-child(1),
.sketch-mini-table td:nth-child(1),
.sketch-carousel-table th:nth-child(1),
.sketch-carousel-table td:nth-child(1) {
  width: 34px !important;
  text-align: center !important;
}

.sketch-mini-table th:nth-child(3),
.sketch-mini-table td:nth-child(3),
.sketch-carousel-table th:nth-child(3),
.sketch-carousel-table td:nth-child(3) {
  width: 44px !important;
  text-align: right !important;
}

/* Make sure product cards do not show more than 5 rows even if previous CSS tries to stretch them. */
.sketch-product-card .sketch-table {
  height: auto !important;
}

/* Responsive: keep visible-row counts, only slightly reduce font. */
@media (max-width: 1350px) {
  :root {
    --global-table-row-h: 31px;
    --small-table-row-h: 28px;
    --global-table-head-h: 28px;
    --small-table-head-h: 26px;
  }

  .sketch-global-table td {
    font-size: 11px !important;
  }

  .sketch-mini-table td,
  .sketch-carousel-table td {
    font-size: 10px !important;
  }

  .sketch-pos {
    font-size: 12px !important;
  }
}

/* === TABLE ROW SIZE VISIBLE ROWS SCROLL v0_57 END === */
'@

$css = $css.TrimEnd() + "`r`n`r`n" + $patch + "`r`n"

Write-Utf8NoBomFile -Path $cssFile -Content $css
Write-Ok "Added visible-row sizing and scrolling CSS"

if ($RunBuild) {
  Write-Info "Running npm run build..."
  Push-Location $root
  try {
    npm run build
    Write-Ok "Build completed"
  } finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "TABLE ROW SIZE + VISIBLE ROWS PATCH v0_57" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Big table: 7 visible rows" -ForegroundColor White
Write-Host "Small tables: 5 visible rows" -ForegroundColor White
Write-Host "Backups: $backupDir" -ForegroundColor White
