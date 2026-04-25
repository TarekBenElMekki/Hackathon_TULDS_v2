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

if (!(Test-Path -LiteralPath $tsxFile)) {
  throw "Missing file: $tsxFile"
}

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-newsbar-applicants-matched-anaccepted-v0_70-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Write-Ok "Backup created: $backupDir"

$tsx = Get-Content -LiteralPath $tsxFile -Raw

# ------------------------------------------------------------
# 1) Add matchedTotal + anAcceptedTotal to BoardRow type
# ------------------------------------------------------------
if ($tsx -notmatch 'matchedTotal:\s*number;') {
  $tsx = $tsx -replace 'appliedTotal:\s*number;', "appliedTotal: number;`r`n  matchedTotal: number;`r`n  anAcceptedTotal: number;"
  Write-Ok "Added matchedTotal and anAcceptedTotal to BoardRow type"
}
else {
  Write-Warn "BoardRow already has matchedTotal"
}

# ------------------------------------------------------------
# 2) Read matched_total + an_accepted_total from API rows in buildRows
# ------------------------------------------------------------
if ($tsx -notmatch 'const\s+matchedTotal\s*=\s*toNumber\(row,\s*"matched_total"\);') {
  $tsx = $tsx -replace 'const\s+appliedTotal\s*=\s*toNumber\(row,\s*"applied_total"\);',
    'const appliedTotal = toNumber(row, "applied_total");
      const matchedTotal = toNumber(row, "matched_total");
      const anAcceptedTotal = toNumber(row, "an_accepted_total");'
  Write-Ok "Added matched/an_accepted API extraction"
}
else {
  Write-Warn "matchedTotal extraction already exists"
}

# ------------------------------------------------------------
# 3) Add fields into returned BoardRow object
# ------------------------------------------------------------
if ($tsx -notmatch 'matchedTotal,\s*\r?\n\s*anAcceptedTotal,') {
  $tsx = $tsx -replace 'appliedTotal,\s*\r?\n\s*o7,',
    "appliedTotal,`r`n        matchedTotal,`r`n        anAcceptedTotal,`r`n        o7,"
  Write-Ok "Added matched/an_accepted to BoardRow return object"
}
else {
  Write-Warn "BoardRow return already has matched/an_accepted"
}

# ------------------------------------------------------------
# 4) Replace applicantPromoText content so the promo bar shows:
#    LC: applicants | matched | AN accepted
# ------------------------------------------------------------
$promoPattern = '(?s)const\s+applicantPromoText\s*=\s*useMemo\(\(\)\s*=>\s*\{.*?\},\s*\[rows\]\);'

$promoReplacement = @'
const applicantPromoText = useMemo(() => {
    if (!rows || rows.length === 0) return "No LC data yet";

    return rows
      .map((row) =>
        `${row.shortLabel}: ${row.appliedTotal} applicants / ${row.matchedTotal} matched / ${row.anAcceptedTotal} AN accepted`
      )
      .join(" | ");
  }, [rows]);
'@

if ([regex]::IsMatch($tsx, $promoPattern)) {
  $tsx = [regex]::Replace($tsx, $promoPattern, $promoReplacement, 1)
  Write-Ok "Updated applicantPromoText to include matched and AN accepted"
}
else {
  throw "Could not find applicantPromoText block. Run the previous applicantPromoText scope fix first, then rerun v0_70."
}

# ------------------------------------------------------------
# 5) Make footer label more complete and clean
# ------------------------------------------------------------
$footerPattern = '(?s)<footer className="sketch-news-bar sketch-applied-news-bar">.*?</footer>'

$footerReplacement = @'
<footer className="sketch-news-bar sketch-applied-news-bar">
          <div className="sketch-news-label"><Radio size={14} /> PIPELINE</div>
          <div className="sketch-news-track">
            <span>LC pipeline | {applicantPromoText} |</span>
          </div>
        </footer>
'@

if ([regex]::IsMatch($tsx, $footerPattern)) {
  $tsx = [regex]::Replace($tsx, $footerPattern, $footerReplacement, 1)
  Write-Ok "Updated bottom news bar label/footer text"
}
else {
  Write-Warn "Could not find sketch-applied-news-bar footer. applicantPromoText was updated only."
}

Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
Write-Ok "Saved dashboard-f1.tsx"

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
Write-Host "NEWS BAR PIPELINE PATCH v0_70" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Bottom bar now shows: applicants / matched / AN accepted per LC" -ForegroundColor White
Write-Host "Backups: $backupDir" -ForegroundColor White
