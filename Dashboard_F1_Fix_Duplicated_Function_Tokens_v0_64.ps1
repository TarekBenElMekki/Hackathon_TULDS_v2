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

if (!(Test-Path -LiteralPath $tsxFile)) {
  throw "Missing file: $tsxFile"
}

Write-Info "Working in: $root"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root ".backup-fix-duplicated-function-tokens-v0_64-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item -LiteralPath $tsxFile -Destination (Join-Path $backupDir "dashboard-f1.tsx") -Force
Write-Ok "Backup created: $backupDir"

$tsx = Get-Content -LiteralPath $tsxFile -Raw

# Fix duplicated function names caused by previous token replacement.
$tsx = $tsx -replace 'function\s+LeaderboardTable\s*function\s+LeaderboardTable', 'function LeaderboardTable'
$tsx = $tsx -replace 'function\s+ProductTable\s*function\s+ProductTable', 'function ProductTable'
$tsx = $tsx -replace 'function\s+TrackMap\s*function\s+TrackMap', 'function TrackMap'
$tsx = $tsx -replace 'function\s+Podium\s*function\s+Podium', 'function Podium'
$tsx = $tsx -replace 'export\s+default\s+function\s+DashboardF1\s*export\s+default\s+function\s+DashboardF1', 'export default function DashboardF1'

# Extra safety for malformed glued tokens without spaces.
$tsx = $tsx.Replace('function LeaderboardTablefunction LeaderboardTable', 'function LeaderboardTable')
$tsx = $tsx.Replace('function ProductTablefunction ProductTable', 'function ProductTable')
$tsx = $tsx.Replace('function TrackMapfunction TrackMap', 'function TrackMap')
$tsx = $tsx.Replace('function Podiumfunction Podium', 'function Podium')
$tsx = $tsx.Replace('export default function DashboardF1export default function DashboardF1', 'export default function DashboardF1')

Write-Utf8NoBomFile -Path $tsxFile -Content $tsx
Write-Ok "Fixed duplicated function tokens in dashboard-f1.tsx"

if ($RunBuild) {
  Write-Info "Running npm run build..."
  Push-Location $root
  try {
    npm run build
  }
  finally {
    Pop-Location
  }
}
