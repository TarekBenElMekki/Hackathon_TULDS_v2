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

function Replace-BlockByTokens {
  param(
    [string]$Text,
    [string]$StartToken,
    [string]$EndToken,
    [string]$Replacement
  )

  $startIndex = $Text.IndexOf($StartToken)
  $endIndex = $Text.IndexOf($EndToken)

  if ($startIndex -lt 0) {
    throw "Could not find start token: $StartToken"
  }

  if ($endIndex -lt 0) {
    throw "Could not find end token: $EndToken"
  }

  if ($endIndex -le $startIndex) {
    throw "End token appears before start token: $EndToken"
  }

  return $Text.Substring(0, $startIndex) + $Replacement + $Text.Substring($endIndex)
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$tsxFile = Join-Path $root "src\components\dashboard-f1.tsx"
$cssFile = Join-Path $root "src\app\globals.css"

if (!(Test-Path -LiteralPath $tsxFile)) { throw "Missing file: $tsxFile" }
if (!(Test-Path -LiteralPath $cssFile)) { throw "Missing file: $cssFile" }

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-real-api-all-tables-v0_61-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Copy-Item -LiteralPath $cssFile -Destination (Join-Path $backupDir "globals.css") -Force
Write-Ok "Backup created: $backupDir"

$tsx = Get-Content -LiteralPath $tsxFile -Raw

# ------------------------------------------------------------
# 1) Add/replace LC name mapping helpers after COLORS
# ------------------------------------------------------------
$mapStart = "/* === REAL API LC NAME MAP v0_61 START === */"
$mapEnd   = "/* === REAL API LC NAME MAP v0_61 END === */"

$tsx = [regex]::Replace(
  $tsx,
  "(?s)\Q$mapStart\E.*?\Q$mapEnd\E\s*",
  ""
)

$mapBlock = @'

/* === REAL API LC NAME MAP v0_61 START === */
const LC_NAME_MAP: Record<string, string> = {
  "513": "Carthage",
  "1277": "Bardo",
  "1270": "Medina",
  "1559": "Ariana",
  "1601": "Sfax",
  "1702": "Sousse",
  "1803": "Bizerte",
};

const LC_LABEL_MAP: Record<string, string> = {
  "lc carthage": "Carthage",
  "carthage": "Carthage",
  "lc bardo": "Bardo",
  "bardo": "Bardo",
  "lc medina": "Medina",
  "medina": "Medina",
  "lc ariana": "Ariana",
  "ariana": "Ariana",
  "lc sfax": "Sfax",
  "sfax": "Sfax",
  "lc sousse": "Sousse",
  "sousse": "Sousse",
  "lc bizerte": "Bizerte",
  "bizerte": "Bizerte",
};

function normalizeLcKey(value: string): string {
  return value
    .toLowerCase()
    .replace(/\s*\(\d+\)\s*$/, "")
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function displayLcName(rowId: string, label: string): string {
  const idKey = String(rowId ?? "").trim();
  if (LC_NAME_MAP[idKey]) return LC_NAME_MAP[idKey];

  const cleaned = label.replace(/\s*\(\d+\)\s*$/, "").trim();
  const normalized = normalizeLcKey(cleaned);

  if (LC_LABEL_MAP[normalized]) return LC_LABEL_MAP[normalized];

  return cleaned.replace(/^LC\s+/i, "").trim() || cleaned || idKey || "Unknown LC";
}
/* === REAL API LC NAME MAP v0_61 END === */

'@

$colorsPattern = 'const COLORS\s*=\s*\[[\s\S]*?\];'
$colorsMatch = [regex]::Match($tsx, $colorsPattern)

if ($colorsMatch.Success) {
  $insertAt = $colorsMatch.Index + $colorsMatch.Length
  $tsx = $tsx.Insert($insertAt, $mapBlock)
  Write-Ok "Inserted LC name mapping helpers"
}
else {
  throw "Could not find COLORS constant to insert LC name map."
}

# ------------------------------------------------------------
# 2) Replace cleanLabel so all labels go through mapping
# ------------------------------------------------------------
$tsx = [regex]::Replace(
  $tsx,
  '(?s)function cleanLabel\(value: string\): string \{.*?\}',
  'function cleanLabel(value: string): string { return displayLcName("", value); }',
  1
)

# ------------------------------------------------------------
# 3) Replace buildRows: all real API rows, global approval ranking
# ------------------------------------------------------------
$newBuildRows = @'
function buildRows(rows: DashboardRow[]): BoardRow[] {
  return rows
    .filter((row) => String(row.row_id ?? "").toLowerCase() !== "global")
    .map((row, index) => {
      const rowId = String(row.row_id ?? index + 1);
      const rawLabel = String(row.row_label ?? row.row_name ?? row.office_name ?? rowId);
      const shortLabel = displayLcName(rowId, rawLabel);

      const approvedTotal = toNumber(row, "approved_total");
      const realizedTotal = toNumber(row, "realized_total");
      const completedTotal = toNumber(row, "completed_total");
      const finishedTotal = toNumber(row, "finished_total");
      const appliedTotal = toNumber(row, "applied_total");

      const o7 = toNumber(row, "o_approved_7");
      const i7 = toNumber(row, "i_approved_7");
      const o8 = toNumber(row, "o_approved_8");
      const i8 = toNumber(row, "i_approved_8");
      const o9 = toNumber(row, "o_approved_9");
      const i9 = toNumber(row, "i_approved_9");

      return {
        rowId,
        label: rawLabel,
        shortLabel,
        approvedTotal,
        realizedTotal,
        completedTotal,
        finishedTotal,
        appliedTotal,
        o7,
        i7,
        o8,
        i8,
        o9,
        i9,
        score: approvedTotal,
        rank: 0,
        color: COLORS[index % COLORS.length],
      };
    })
    .sort((a, b) =>
      b.approvedTotal - a.approvedTotal ||
      b.appliedTotal - a.appliedTotal ||
      b.realizedTotal - a.realizedTotal ||
      a.shortLabel.localeCompare(b.shortLabel)
    )
    .map((row, index) => ({ ...row, rank: index + 1 }));
}

function LeaderboardTable
'@

$tsx = Replace-BlockByTokens `
  -Text $tsx `
  -StartToken "function buildRows" `
  -EndToken "function LeaderboardTable" `
  -Replacement $newBuildRows

Write-Ok "Rebuilt rows from real API fields and ranked globally by approvals"

# ------------------------------------------------------------
# 4) Replace ProductTable: each table ranks by concerned product approvals
# ------------------------------------------------------------
$newProductTable = @'
function ProductTable({ config, rows }: { config: ProductBoard; rows: BoardRow[] }) {
  const rankedRows = useMemo(() => {
    return [...rows]
      .sort((a, b) =>
        Number(b[config.key] ?? 0) - Number(a[config.key] ?? 0) ||
        b.approvedTotal - a.approvedTotal ||
        b.appliedTotal - a.appliedTotal ||
        a.shortLabel.localeCompare(b.shortLabel)
      )
      .map((row, index) => ({ ...row, productRank: index + 1 }));
  }, [config.key, rows]);

  const carouselRows = rankedRows.length > 0 ? [...rankedRows, ...rankedRows] : [];

  return (
    <section className="sketch-card sketch-product-card sketch-carousel-card">
      <div className="sketch-card-head sketch-mini-head">
        <div>
          <h3>{config.title}</h3>
          <p>{config.subtitle} Ã‚Â· real API approvals</p>
        </div>
        <div className="sketch-product-tag">APPROVALS</div>
      </div>

      <div className="sketch-carousel-window">
        <table className="sketch-table sketch-mini-table sketch-carousel-table">
          <thead>
            <tr>
              <th>Pos</th>
              <th>LC</th>
              <th>Appr</th>
            </tr>
          </thead>
          <tbody className="sketch-carousel-track-y">
            {carouselRows.map((row, index) => (
              <tr key={`${config.key}-${row.rowId}-${index}`}>
                <td className="sketch-pos">{row.productRank}</td>
                <td>
                  <div className="sketch-team-cell">
                    <span className="sketch-color-dot" style={{ background: row.color }} />
                    <span className="sketch-team-label">{row.shortLabel}</span>
                  </div>
                </td>
                <td className="sketch-score">{Number(row[config.key] ?? 0)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function TrackMap
'@

$tsx = Replace-BlockByTokens `
  -Text $tsx `
  -StartToken "function ProductTable" `
  -EndToken "function TrackMap" `
  -Replacement $newProductTable

Write-Ok "Linked all six product tables to real API product approval fields"

# ------------------------------------------------------------
# 5) Replace TrackMap: logos positioned by global approval rank
# ------------------------------------------------------------
$newTrackMap = @'
function TrackMap({ rows }: { rows: BoardRow[] }) {
  const nodes = rows;

  const points = [
    [52, 10],
    [63, 17],
    [74, 29],
    [80, 45],
    [76, 62],
    [67, 79],
    [56, 90],
    [43, 82],
    [31, 64],
    [23, 45],
    [28, 25],
    [42, 15],
    [70, 18],
    [84, 53],
    [61, 86],
    [37, 74],
  ];

  return (
    <section className="sketch-card sketch-map-card">
      <div className="sketch-card-head">
        <div>
          <h2>Global Race Track</h2>
          <p>Logos follow global approval ranking</p>
        </div>
        <Flag size={18} />
      </div>

      <div className="sketch-track-stage">
        <svg className="sketch-track-svg" viewBox="0 0 420 320" aria-hidden="true">
          <defs>
            <linearGradient id="trackGlow" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#e10600" />
              <stop offset="48%" stopColor="#ffffff" />
              <stop offset="100%" stopColor="#e10600" />
            </linearGradient>
          </defs>

          <path
            className="sketch-track-shadow"
            d="M214 23
               C247 26 272 42 293 67
               C318 96 342 129 351 167
               C357 194 347 226 326 247
               C307 266 287 278 270 292
               C252 307 229 312 206 309
               C182 306 163 297 149 283
               C136 270 131 252 127 235
               C121 209 102 194 91 177
               C80 160 74 140 77 118
               C80 96 92 77 111 59
               C128 43 146 32 169 26
               C187 21 201 21 214 23 Z"
          />
          <path
            className="sketch-track-main"
            d="M214 23
               C247 26 272 42 293 67
               C318 96 342 129 351 167
               C357 194 347 226 326 247
               C307 266 287 278 270 292
               C252 307 229 312 206 309
               C182 306 163 297 149 283
               C136 270 131 252 127 235
               C121 209 102 194 91 177
               C80 160 74 140 77 118
               C80 96 92 77 111 59
               C128 43 146 32 169 26
               C187 21 201 21 214 23 Z"
          />
          <path
            className="sketch-track-inner"
            d="M214 53
               C236 56 253 67 267 85
               C286 109 306 133 313 161
               C318 182 311 203 294 221
               C280 236 264 248 250 260
               C236 272 219 277 202 275
               C184 273 170 267 160 256
               C151 246 148 232 145 219
               C141 199 127 188 118 173
               C109 159 104 143 107 126
               C109 110 118 96 132 84
               C145 72 158 65 174 61
               C187 58 200 58 214 53 Z"
          />

          <circle cx="216" cy="28" r="8" className="sketch-start-marker" />
          <circle cx="228" cy="303" r="8" className="sketch-arrival-marker" />
          <line x1="205" y1="20" x2="235" y2="35" className="sketch-finish-line" />
        </svg>

        <div className="sketch-track-chip sketch-track-start" style={{ left: "52%", top: "9%" }}>
          <span className="sketch-track-dot" />
          START
        </div>

        <div className="sketch-track-chip sketch-track-arrival" style={{ left: "55%", top: "89%" }}>
          <span className="sketch-track-dot sketch-track-dot-arrival" />
          ARRIVAL
        </div>

        {nodes.map((row, index) => {
          const [left, top] = points[index % points.length];
          const offset = Math.floor(index / points.length) * 2;

          return (
            <div
              className="sketch-map-node sketch-map-node-global"
              key={row.rowId}
              style={{
                left: `${Math.min(91, left + offset)}%`,
                top: `${Math.min(92, top + offset)}%`,
              }}
              title={`P${row.rank} Ã‚Â· ${row.shortLabel} Ã‚Â· ${row.approvedTotal} approvals`}
            >
              <span className="sketch-map-rank">P{row.rank}</span>
              <span
                className="sketch-map-logo"
                style={{ borderColor: row.color, boxShadow: `0 0 18px ${row.color}66` }}
              >
                {initials(row.shortLabel)}
              </span>
              <span className="sketch-map-label">{row.shortLabel}</span>
            </div>
          );
        })}

        <div className="sketch-map-live">
          <MapPin size={13} /> GLOBAL RACE
        </div>
      </div>
    </section>
  );
}

function Podium
'@

$tsx = Replace-BlockByTokens `
  -Text $tsx `
  -StartToken "function TrackMap" `
  -EndToken "function Podium" `
  -Replacement $newTrackMap

Write-Ok "Linked race track logo order to global approval ranking"

# ------------------------------------------------------------
# 6) Replace Podium: bottom rank based on global table
# ------------------------------------------------------------
$newPodium = @'
function Podium({ rows }: { rows: BoardRow[] }) {
  const top = rows.slice(0, 3);
  const first = top[0];
  const second = top[1];
  const third = top[2];

  return (
    <section className="sketch-card sketch-podium-card">
      <div className="sketch-card-head sketch-podium-head">
        <div>
          <h2>Global Ranking Podium</h2>
          <p>Top 3 by total approvals</p>
        </div>
        <Trophy size={18} />
      </div>
      <div className="sketch-podium-stage">
        {[second, first, third].filter(Boolean).map((row) => (
          <div key={row.rowId} className={`sketch-podium-item sketch-place-${row.rank}`}>
            <div className="sketch-podium-logo" style={{ borderColor: row.color }}>{initials(row.shortLabel)}</div>
            <div className="sketch-podium-name sketch-podium-rank-label">P{row.rank}</div>
            <div className="sketch-podium-points">{row.approvedTotal} approvals Ã‚Â· {row.appliedTotal} applicants</div>
            <div className="sketch-podium-step sketch-podium-entity-label">{row.shortLabel}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default function DashboardF1
'@

$tsx = Replace-BlockByTokens `
  -Text $tsx `
  -StartToken "function Podium" `
  -EndToken "export default function DashboardF1" `
  -Replacement $newPodium

Write-Ok "Linked podium to global approval ranking"

# ------------------------------------------------------------
# 7) Add applicant promo text variable after rows are built
# ------------------------------------------------------------
if ($tsx -notmatch 'applicantPromoText') {
  $needle = 'const rows = useMemo(() => buildRows(payload?.rows ?? FALLBACK_ROWS), [payload]);'
  $insert = @'
const rows = useMemo(() => buildRows(payload?.rows ?? FALLBACK_ROWS), [payload]);

  const applicantPromoText = useMemo(() => {
    if (rows.length === 0) return "No applicant data yet";
    return rows
      .map((row) => `${row.shortLabel}: ${row.appliedTotal} applicants`)
      .join(" Ã‚Â· ");
  }, [rows]);
'@

  if ($tsx.Contains($needle)) {
    $tsx = $tsx.Replace($needle, $insert)
    Write-Ok "Added applicant promo bar text from real API applied_total"
  }
  else {
    Write-Warn "Could not auto-insert applicantPromoText; attempting fallback insertion."
    $tsx = [regex]::Replace(
      $tsx,
      '(const rows\s*=\s*useMemo\(\(\)\s*=>\s*buildRows\(payload\?\.rows\s*\?\?\s*FALLBACK_ROWS\),\s*\[payload\]\);)',
      '$1

  const applicantPromoText = useMemo(() => {
    if (rows.length === 0) return "No applicant data yet";
    return rows
      .map((row) => `${row.shortLabel}: ${row.appliedTotal} applicants`)
      .join(" Ã‚Â· ");
  }, [rows]);',
      1
    )
  }
}

# ------------------------------------------------------------
# 8) Replace footer/promo bar
# ------------------------------------------------------------
$footerPattern = '(?s)<footer className="sketch-news-bar[^"]*">.*?</footer>'
$newFooter = @'
<footer className="sketch-news-bar sketch-applied-news-bar">
          <div className="sketch-news-label"><Radio size={14} /> APPLICANTS</div>
          <div className="sketch-news-track">
            <span>Ã°Å¸ÂÂ Applicant count by LC Ã‚Â· {applicantPromoText} Ã‚Â·</span>
          </div>
        </footer>
'@

if ([regex]::IsMatch($tsx, $footerPattern)) {
  $tsx = [regex]::Replace($tsx, $footerPattern, $newFooter, 1)
  Write-Ok "Updated promo bar to show applicants by mapped LC name"
}
else {
  Write-Warn "Could not find sketch-news-bar footer. Promo bar not replaced."
}

# ------------------------------------------------------------
# 9) Update header text/count label from Top 12 to all ranked LCs
# ------------------------------------------------------------
$tsx = $tsx.Replace(
  'Top ${Math.min(rows.length, 12)} entities',
  'All ${rows.length} ranked LCs'
)

Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
Write-Ok "Saved dashboard-f1.tsx"

# ------------------------------------------------------------
# 10) CSS polish for real API map/applicant bar
# ------------------------------------------------------------
$css = Get-Content -LiteralPath $cssFile -Raw

$cssStart = "/* === REAL API ALL TABLES v0_61 START === */"
$cssEnd   = "/* === REAL API ALL TABLES v0_61 END === */"

$css = [regex]::Replace(
  $css,
  "(?s)\Q$cssStart\E.*?\Q$cssEnd\E\s*",
  ""
)

$cssPatch = @'

/* === REAL API ALL TABLES v0_61 START === */

.sketch-map-node-global {
  z-index: 8 !important;
}

.sketch-map-rank {
  position: absolute;
  top: -13px;
  left: 50%;
  transform: translateX(-50%);
  padding: 1px 5px;
  border-radius: 999px;
  background: rgba(225, 6, 0, 0.88);
  color: #fff;
  font-size: 8px;
  font-weight: 1000;
  letter-spacing: 0.04em;
  box-shadow: 0 4px 10px rgba(0,0,0,0.35);
}

.sketch-applied-news-bar {
  border-color: rgba(225,6,0,0.34) !important;
}

.sketch-applied-news-bar .sketch-news-label {
  background: linear-gradient(135deg, #e10600, #650000) !important;
}

.sketch-applied-news-bar .sketch-news-track span {
  font-weight: 950 !important;
  color: #ffffff !important;
}

/* Keep product values readable with real API data. */
.sketch-product-card .sketch-score {
  color: #ffd700 !important;
  font-weight: 1000 !important;
}

.sketch-product-card .sketch-product-tag {
  color: #ffffff !important;
  background: rgba(225,6,0,0.20) !important;
  border-color: rgba(225,6,0,0.38) !important;
}

/* === REAL API ALL TABLES v0_61 END === */
'@

$css = $css.TrimEnd() + "`r`n`r`n" + $cssPatch + "`r`n"
Write-Utf8NoBomFile -Path $cssFile -Content $css
Write-Ok "Saved globals.css"

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
Write-Host "REAL API DASHBOARD LINK PATCH v0_61" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Global table: approved_total ranking" -ForegroundColor White
Write-Host "Product tables: product approval fields" -ForegroundColor White
Write-Host "Podium: global approval ranking" -ForegroundColor White
Write-Host "Track logos: global ranking order" -ForegroundColor White
Write-Host "Promo bar: applied_total applicants by mapped LC name" -ForegroundColor White
Write-Host "Backups: $backupDir" -ForegroundColor White
