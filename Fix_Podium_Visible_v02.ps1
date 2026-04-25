param([switch]$RunBuild)

$ErrorActionPreference = "Stop"

function Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$root = Get-Location
$tsxPath = Join-Path $root "src\components\dashboard-f1.tsx"
$cssPath = Join-Path $root "src\app\globals.css"

if (!(Test-Path $tsxPath)) { throw "Missing $tsxPath" }
if (!(Test-Path $cssPath)) { throw "Missing $cssPath" }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root ".backup-podium-visible-v02-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item $tsxPath (Join-Path $backup "dashboard-f1.tsx") -Force
Copy-Item $cssPath (Join-Path $backup "globals.css") -Force
Ok "Backup created: $backup"

$tsx = Get-Content $tsxPath -Raw

$newPodium = @'
function Podium({ rows }: { rows: BoardRow[] }) {
  const podiumRows = rows.length >= 3
    ? [rows[1], rows[0], rows[2]]
    : rows;

  return (
    <section className="sketch-card sketch-podium-card podium-force-visible">
      <div className="podium-force-title">
        <div>
          <h2>Global Ranking Podium</h2>
          <p>Top 3 directly from Global Approval Table</p>
        </div>
        <Trophy size={18} />
      </div>

      <div className="podium-force-grid">
        {podiumRows.map((row) => (
          <article key={row.rowId} className={`podium-force-item podium-force-p${row.rank}`}>
            <div className="podium-force-rank">P{row.rank}</div>
            <div className="podium-force-logo" style={{ borderColor: row.color }}>
              {initials(row.shortLabel)}
            </div>
            <div className="podium-force-name">{row.shortLabel}</div>
            <div className="podium-force-score">{row.approvedTotal} approvals</div>
            <div className="podium-force-sub">{row.appliedTotal} applicants</div>
          </article>
        ))}
      </div>
    </section>
  );
}

export default function DashboardF1
'@

$pattern = '(?s)function Podium\(\{ rows \}: \{ rows: BoardRow\[\] \}\).*?export default function DashboardF1'

if (!([regex]::IsMatch($tsx, $pattern))) {
  throw "Could not find Podium component block."
}

$tsx = [regex]::Replace($tsx, $pattern, $newPodium, 1)

$css = Get-Content $cssPath -Raw

$css = [regex]::Replace(
  $css,
  '(?s)/\* === FORCE PODIUM VISIBLE V02 START === \*/.*?/\* === FORCE PODIUM VISIBLE V02 END === \*/',
  ''
)

$patch = @'

/* === FORCE PODIUM VISIBLE V02 START === */
.podium-force-visible {
  display: grid !important;
  grid-template-rows: 34px minmax(0, 1fr) !important;
  min-height: 108px !important;
  height: 108px !important;
  padding: 10px 14px !important;
  overflow: visible !important;
  position: relative !important;
  z-index: 10 !important;
}

.podium-force-title {
  display: flex !important;
  align-items: center !important;
  justify-content: space-between !important;
  color: #fff !important;
  height: 30px !important;
}

.podium-force-title h2 {
  margin: 0 !important;
  font-size: 17px !important;
  line-height: 1 !important;
  color: #fff !important;
  text-transform: uppercase !important;
}

.podium-force-title p {
  margin: 3px 0 0 !important;
  font-size: 9px !important;
  color: #bfc7d8 !important;
}

.podium-force-grid {
  display: grid !important;
  grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
  gap: 12px !important;
  min-height: 0 !important;
  height: 62px !important;
}

.podium-force-item {
  display: grid !important;
  grid-template-columns: 42px 54px minmax(0, 1fr) !important;
  grid-template-rows: 1fr 1fr !important;
  align-items: center !important;
  column-gap: 10px !important;
  padding: 8px 12px !important;
  border-radius: 18px !important;
  border: 1px solid rgba(255,255,255,0.18) !important;
  background: linear-gradient(135deg, rgba(255,255,255,0.16), rgba(255,255,255,0.04)) !important;
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.12) !important;
  overflow: hidden !important;
}

.podium-force-p1 {
  border-color: rgba(255,215,0,0.55) !important;
  background: linear-gradient(135deg, rgba(255,215,0,0.24), rgba(255,255,255,0.05)) !important;
}

.podium-force-p2 {
  border-color: rgba(192,192,192,0.55) !important;
}

.podium-force-p3 {
  border-color: rgba(205,127,50,0.55) !important;
}

.podium-force-rank {
  grid-row: 1 / 3 !important;
  color: #ff3b30 !important;
  font-size: 24px !important;
  font-weight: 950 !important;
}

.podium-force-logo {
  grid-row: 1 / 3 !important;
  width: 42px !important;
  height: 42px !important;
  border-radius: 999px !important;
  border: 3px solid #fff !important;
  display: grid !important;
  place-items: center !important;
  color: #fff !important;
  font-size: 12px !important;
  font-weight: 950 !important;
  background: #080b12 !important;
}

.podium-force-name {
  color: #fff !important;
  font-size: 16px !important;
  font-weight: 950 !important;
  line-height: 1 !important;
  white-space: nowrap !important;
  overflow: hidden !important;
  text-overflow: ellipsis !important;
}

.podium-force-score {
  color: #ffd700 !important;
  font-size: 12px !important;
  font-weight: 900 !important;
}

.podium-force-sub {
  color: #bfc7d8 !important;
  font-size: 10px !important;
  font-weight: 800 !important;
}
/* === FORCE PODIUM VISIBLE V02 END === */
'@

$css += $patch

$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($tsxPath, $tsx, $enc)
[System.IO.File]::WriteAllText($cssPath, $css, $enc)

Ok "Podium component replaced and CSS forced visible."

if ($RunBuild) {
  Info "Running npm run build..."
  npm run build
}