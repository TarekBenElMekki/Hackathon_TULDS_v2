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
$backupDir = Join-Path $root ".backup-fix-applicant-promo-text-v0_67-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Write-Ok "Backup created: $backupDir"

$tsx = Get-Content -LiteralPath $tsxFile -Raw

if ($tsx -notmatch "const\s+applicantPromoText\s*=") {
  $componentToken = "export default function DashboardF1"
  $componentIndex = $tsx.IndexOf($componentToken)

  if ($componentIndex -lt 0) {
    throw "Could not find export default function DashboardF1"
  }

  $returnIndex = $tsx.IndexOf("return (", $componentIndex)

  if ($returnIndex -lt 0) {
    throw "Could not find return ( inside DashboardF1"
  }

  $insert = @'

  const applicantPromoText = useMemo(() => {
    if (!rows || rows.length === 0) return "No applicant data yet";

    return rows
      .map((row) => `${row.shortLabel}: ${row.appliedTotal} applicants`)
      .join(" | ");
  }, [rows]);

'@

  $tsx = $tsx.Substring(0, $returnIndex) + $insert + $tsx.Substring($returnIndex)
  Write-Ok "Inserted applicantPromoText before DashboardF1 return"
}
else {
  Write-Warn "applicantPromoText already exists. Skipping insertion."
}

# Replace the applicant promo footer with clean ASCII text.
$footerPattern = '(?s)<footer className="sketch-news-bar sketch-applied-news-bar">.*?</footer>'

$footerReplacement = @'
<footer className="sketch-news-bar sketch-applied-news-bar">
          <div className="sketch-news-label"><Radio size={14} /> APPLICANTS</div>
          <div className="sketch-news-track">
            <span>Applicant count by LC | {applicantPromoText} |</span>
          </div>
        </footer>
'@

if ([regex]::IsMatch($tsx, $footerPattern)) {
  $tsx = [regex]::Replace($tsx, $footerPattern, $footerReplacement, 1)
  Write-Ok "Replaced applicant promo footer"
}
else {
  Write-Warn "Could not find sketch-applied-news-bar footer. Leaving footer unchanged."
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
