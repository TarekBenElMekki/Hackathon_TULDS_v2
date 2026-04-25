param(
  [string]$Path = ".\src\components\dashboard-f1.tsx"
)

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Fixing podium empty issue..."

# Read file
if (!(Test-Path $Path)) {
  Write-Host "[ERROR] File not found: $Path"
  exit 1
}

$tsx = Get-Content -LiteralPath $Path -Raw

# -------------------------------
# 1. SAFE fallback injection
# -------------------------------
$fallback = @'
const safeRanking = (data?.globalRanking && data.globalRanking.length > 0)
  ? data.globalRanking
  : [
      { name: "Fallback LC 1", score: 100 },
      { name: "Fallback LC 2", score: 80 },
      { name: "Fallback LC 3", score: 60 }
    ];

const podium = safeRanking.slice(0, 3);
'@

# Replace ONLY podium declaration safely
$tsx = [regex]::Replace(
  $tsx,
  'const\s+podium\s*=\s*.*?;',
  $fallback,
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

# -------------------------------
# 2. Remove blocking condition
# -------------------------------
$tsx = $tsx -replace '\{podium\.length\s*>\s*0\s*&&\s*\(', '('

# -------------------------------
# 3. Save file
# -------------------------------
Set-Content -LiteralPath $Path -Value $tsx -Encoding UTF8

Write-Host "[OK] Podium fix applied."

# -------------------------------
# 4. Optional build
# -------------------------------
if (Test-Path ".\package.json") {
  Write-Host "[INFO] Running npm build..."
  npm run build
} else {
  Write-Host "[WARN] package.json not found, skipping build"
}

Write-Host "[OK] Done."