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
$tsxFile = Join-Path $root "src\components\dashboard-f1.tsx"
$cssFile = Join-Path $root "src\app\globals.css"

if (!(Test-Path -LiteralPath $tsxFile)) { throw "Missing file: $tsxFile" }
if (!(Test-Path -LiteralPath $cssFile)) { throw "Missing file: $cssFile" }

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-global-table-fullheight-7rows-alllcs-v0_60-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force
Write-Ok "Backup created: $backupDir"

# ------------------------------------------------------------
# PATCH TSX SAFELY
# ------------------------------------------------------------
$tsx = Get-Content -LiteralPath $tsxFile -Raw

$startToken = "function LeaderboardTable"
$endToken = "function ProductTable"

$startIndex = $tsx.IndexOf($startToken)
$endIndex = $tsx.IndexOf($endToken)

if ($startIndex -lt 0) {
  throw "Could not find function LeaderboardTable in dashboard-f1.tsx"
}

if ($endIndex -lt 0) {
  throw "Could not find function ProductTable in dashboard-f1.tsx"
}

if ($endIndex -le $startIndex) {
  throw "function ProductTable was found before LeaderboardTable; cannot safely patch."
}

$newLeaderboard = @'
function LeaderboardTable({ rows }: { rows: BoardRow[] }) {
  const rankedRows = useMemo(() => rows, [rows]);
  const [globalOffset, setGlobalOffset] = useState(0);

  useEffect(() => {
    if (rankedRows.length <= 7) {
      setGlobalOffset(0);
      return;
    }

    const interval = window.setInterval(() => {
      setGlobalOffset((previous) => (previous + 1) % rankedRows.length);
    }, 2200);

    return () => window.clearInterval(interval);
  }, [rankedRows.length]);

  const visibleRows = useMemo(() => {
    if (rankedRows.length === 0) return [];

    const visibleCount = Math.min(7, rankedRows.length);

    return Array.from({ length: visibleCount }, (_, index) => {
      return rankedRows[(globalOffset + index) % rankedRows.length];
    });
  }, [rankedRows, globalOffset]);

  return (
    <div
      className="sketch-carousel-window sketch-global-carousel-window"
      title={`Rotating all ${rankedRows.length} ranked LCs`}
    >
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
        <tbody className="sketch-global-carousel-body">
          {visibleRows.map((row, index) => (
            <tr key={`global-${row.rowId}-${globalOffset}-${index}`} className="sketch-global-carousel-row">
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

      <div className="sketch-global-carousel-status">
        ALL RANKED LCs Ã‚Â· {rankedRows.length} TOTAL
      </div>
    </div>
  );
}


'@

$tsx = $tsx.Substring(0, $startIndex) + $newLeaderboard + $tsx.Substring($endIndex)

Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
Write-Ok "Updated Global Approval Table to rotate all ranked LCs with 7 visible rows"

# ------------------------------------------------------------
# PATCH CSS
# ------------------------------------------------------------
$css = Get-Content -LiteralPath $cssFile -Raw

$start = "/* === GLOBAL TABLE FULL HEIGHT 7 ROWS ALL LCS v0_60 START === */"
$end   = "/* === GLOBAL TABLE FULL HEIGHT 7 ROWS ALL LCS v0_60 END === */"

$startEsc = [regex]::Escape($start)
$endEsc = [regex]::Escape($end)

$css = [regex]::Replace(
  $css,
  "(?s)$startEsc.*?$endEsc\s*",
  ""
)

$patch = @'

/* === GLOBAL TABLE FULL HEIGHT 7 ROWS ALL LCS v0_60 START === */

/* Make only the Global Approval Table use the full card body. */
.sketch-global-card {
  display: flex !important;
  flex-direction: column !important;
  min-height: 0 !important;
  overflow: hidden !important;
}

.sketch-global-card > .sketch-card-head {
  flex: 0 0 auto !important;
}

/* Override old fixed-height global carousel rules. */
.sketch-global-card .sketch-global-carousel-window {
  position: relative !important;
  z-index: 2 !important;
  flex: 1 1 auto !important;
  height: auto !important;
  max-height: none !important;
  min-height: 0 !important;
  overflow: hidden !important;
  width: 100% !important;
  display: flex !important;
  flex-direction: column !important;
}

/* Full-height global table. */
.sketch-global-carousel-table {
  flex: 1 1 auto !important;
  width: 100% !important;
  height: 100% !important;
  min-height: 0 !important;
  table-layout: fixed !important;
  border-collapse: separate !important;
  border-spacing: 0 !important;
}

/* Solid premium header. */
.sketch-global-carousel-table thead,
.sketch-global-carousel-table thead tr,
.sketch-global-carousel-table thead th {
  position: sticky !important;
  top: 0 !important;
  z-index: 160 !important;
  background: linear-gradient(180deg, #202938 0%, #111722 100%) !important;
  background-color: #111722 !important;
  opacity: 1 !important;
}

.sketch-global-carousel-table thead th {
  height: 36px !important;
  padding: 0 12px !important;
  color: #f8fafc !important;
  font-size: 10px !important;
  font-weight: 1000 !important;
  letter-spacing: 0.12em !important;
  line-height: 1 !important;
  border-bottom: 1px solid rgba(255,255,255,0.22) !important;
  box-shadow:
    0 2px 0 rgba(225, 6, 0, 0.78),
    0 10px 16px rgba(0, 0, 0, 0.74) !important;
}

/* Body and rows: only 7 rows are rendered and they fill the card. */
.sketch-global-carousel-body {
  height: calc(100% - 36px) !important;
}

.sketch-global-carousel-row {
  height: calc((100% - 36px) / 7) !important;
  min-height: 44px !important;
  animation: sketchGlobalRowEnter 420ms ease both;
}

.sketch-global-carousel-table td {
  height: calc((100% - 36px) / 7) !important;
  padding: 0 12px !important;
  font-size: clamp(13px, 1.05vw, 18px) !important;
  line-height: 1.05 !important;
  vertical-align: middle !important;
}

.sketch-global-carousel-table .sketch-pos {
  font-size: clamp(16px, 1.25vw, 22px) !important;
  font-weight: 1000 !important;
  color: #ff3b30 !important;
}

.sketch-global-carousel-table .sketch-score {
  font-size: clamp(15px, 1.16vw, 21px) !important;
  font-weight: 1000 !important;
  color: #ffd700 !important;
}

.sketch-global-carousel-table .sketch-team-label {
  font-size: clamp(13px, 1.05vw, 18px) !important;
  font-weight: 950 !important;
}

.sketch-global-carousel-table .sketch-team-cell {
  gap: 10px !important;
}

.sketch-global-carousel-table .sketch-color-bar {
  width: 5px !important;
  height: clamp(24px, 2.2vh, 36px) !important;
  border-radius: 999px !important;
}

/* Better widths for large content. */
.sketch-global-carousel-table th:nth-child(1),
.sketch-global-carousel-table td:nth-child(1) {
  width: 54px !important;
  text-align: center !important;
}

.sketch-global-carousel-table th:nth-child(3),
.sketch-global-carousel-table td:nth-child(3),
.sketch-global-carousel-table th:nth-child(4),
.sketch-global-carousel-table td:nth-child(4),
.sketch-global-carousel-table th:nth-child(5),
.sketch-global-carousel-table td:nth-child(5) {
  width: 64px !important;
  text-align: right !important;
}

/* Status chip. */
.sketch-global-carousel-status {
  position: absolute !important;
  right: 10px !important;
  bottom: 8px !important;
  z-index: 170 !important;
  padding: 4px 8px !important;
  border-radius: 999px !important;
  background: rgba(0,0,0,0.62) !important;
  border: 1px solid rgba(255,255,255,0.12) !important;
  color: rgba(255,255,255,0.76) !important;
  font-size: 8px !important;
  font-weight: 950 !important;
  letter-spacing: 0.12em !important;
  pointer-events: none !important;
}

/* Row carousel feel. */
@keyframes sketchGlobalRowEnter {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.sketch-global-carousel-row:nth-child(1) { animation-delay: 0ms; }
.sketch-global-carousel-row:nth-child(2) { animation-delay: 35ms; }
.sketch-global-carousel-row:nth-child(3) { animation-delay: 70ms; }
.sketch-global-carousel-row:nth-child(4) { animation-delay: 105ms; }
.sketch-global-carousel-row:nth-child(5) { animation-delay: 140ms; }
.sketch-global-carousel-row:nth-child(6) { animation-delay: 175ms; }
.sketch-global-carousel-row:nth-child(7) { animation-delay: 210ms; }

/* Disable old translate animation only for global table. */
.sketch-global-carousel-track-y {
  animation: none !important;
  transform: none !important;
}

/* Correct header mask height. */
.sketch-global-carousel-window::before {
  height: 36px !important;
  z-index: 150 !important;
  background: linear-gradient(180deg, #202938 0%, #111722 100%) !important;
  box-shadow:
    0 2px 0 rgba(225, 6, 0, 0.78),
    0 10px 16px rgba(0, 0, 0, 0.74) !important;
}

/* Do not touch the six small product tables. */
.sketch-product-card .sketch-carousel-window {
  flex: 0 0 auto !important;
}

/* Responsive safety. */
@media (max-width: 1350px) {
  .sketch-global-carousel-table thead th {
    height: 32px !important;
    font-size: 8.5px !important;
    padding: 0 9px !important;
  }

  .sketch-global-carousel-row,
  .sketch-global-carousel-table td {
    min-height: 38px !important;
    padding: 0 9px !important;
  }

  .sketch-global-carousel-table .sketch-pos {
    font-size: 15px !important;
  }

  .sketch-global-carousel-table .sketch-team-label,
  .sketch-global-carousel-table td {
    font-size: 12px !important;
  }

  .sketch-global-carousel-table th:nth-child(1),
  .sketch-global-carousel-table td:nth-child(1) {
    width: 44px !important;
  }

  .sketch-global-carousel-table th:nth-child(3),
  .sketch-global-carousel-table td:nth-child(3),
  .sketch-global-carousel-table th:nth-child(4),
  .sketch-global-carousel-table td:nth-child(4),
  .sketch-global-carousel-table th:nth-child(5),
  .sketch-global-carousel-table td:nth-child(5) {
    width: 54px !important;
  }
}

/* === GLOBAL TABLE FULL HEIGHT 7 ROWS ALL LCS v0_60 END === */
'@

$css = $css.TrimEnd() + "`r`n`r`n" + $patch + "`r`n"

Write-Utf8NoBomFile -Path $cssFile -Content $css
Write-Ok "Added full-height 7-row styling for Global Approval Table"

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
Write-Host "GLOBAL TABLE FULL HEIGHT PATCH v0_60" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Global table: full height" -ForegroundColor White
Write-Host "Visible rows: exactly 7" -ForegroundColor White
Write-Host "Data: all ranked LCs rotate" -ForegroundColor White
Write-Host "Backups: $backupDir" -ForegroundColor White
