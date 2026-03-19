param(
  [string]$DeviceId = "9dacfbc0"
)

$envFile = Join-Path $PSScriptRoot ".env.supabase"
if (-not (Test-Path $envFile)) {
  Write-Error "Khong tim thay file .env.supabase"
  exit 1
}

$envMap = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
    return
  }

  $parts = $line -split "=", 2
  if ($parts.Count -eq 2) {
    $envMap[$parts[0].Trim()] = $parts[1].Trim()
  }
}

$required = @("SUPABASE_URL", "SUPABASE_ANON_KEY")
$missing = $required | Where-Object { -not $envMap.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($envMap[$_]) }
if ($missing.Count -gt 0) {
  Write-Error ("Thieu bien trong .env.supabase: " + ($missing -join ", "))
  exit 1
}

$bucket = if ($envMap.ContainsKey("SUPABASE_AVATAR_BUCKET") -and -not [string]::IsNullOrWhiteSpace($envMap["SUPABASE_AVATAR_BUCKET"])) {
  $envMap["SUPABASE_AVATAR_BUCKET"]
} else {
  "avatars"
}

flutter run -d $DeviceId --dart-define="SUPABASE_URL=$($envMap['SUPABASE_URL'])" --dart-define="SUPABASE_ANON_KEY=$($envMap['SUPABASE_ANON_KEY'])" --dart-define="SUPABASE_AVATAR_BUCKET=$bucket"
