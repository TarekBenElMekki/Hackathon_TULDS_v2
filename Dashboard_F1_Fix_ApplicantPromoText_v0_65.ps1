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
$backupDir = Join-Path $root ".backup-fix-applicant-promo-text-v0_65-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Write-Ok "Backup created: $backupDir"

$tsx = Get-Content -LiteralPath $tsxFile -Raw

if ($tsx -match "const\s+applicantPromoText\s*=") {
  Write-Warn "applicantPromoText already exists. No insertion needed."
}
else {
  $pattern = '(const\s+rows\s*=\s*useMemo\(\(\)\s*=>\s*buildRows\(payload\?\.rows\s*\?\?\s*FALLBACK_ROWS\),\s*\[payload\]\);)'

  $insert = @'
$1

  const applicantPromoText = useMemo(() => {
    if (!rows || rows.length === 0) return "No applicant data yet";

    return rows
      .map((row) => `${row.shortLabel}: ${row.appliedTotal} applicants`)
      .join(" Ã‚Â· ");
  }, [rows]);
'@

  $newTsx = [regex]::Replace($tsx, $pattern, $insert, 1)

  if ($newTsx -eq $tsx) {
    throw "Could not find the rows useMemo line. Open src\components\dashboard-f1.tsx and search for: const rows = useMemo"
  }

  $tsx = $newTsx
  Write-Ok "Inserted applicantPromoText after rows useMemo"
}

# Fix mojibake in the applicant footer text if present.
$tsx = $tsx -replace 'ÃƒÆ’Ã‚Â°Ãƒâ€¦Ã‚Â¸Ãƒâ€šÃƒâ€š Applicant count by LC ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â·', 'Ã°Å¸ÂÂ Applicant count by LC Ã‚Â·'
$tsx = $tsx -replace 'ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â·', 'Ã‚Â·'
$tsx = $tsx -replace 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢', 'Ã¢â€ â€™'

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
