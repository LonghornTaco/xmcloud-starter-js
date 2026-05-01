$ErrorActionPreference = "Stop"

# Set the root of the repository.
$RepoRoot = Resolve-Path "$PSScriptRoot\..\.."

Write-Host "Stopping containers..." -ForegroundColor Green
Push-Location (Join-Path $RepoRoot "local-containers")
try {
    docker compose down
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Container down failed, see errors above."
    }
}
finally {
    Pop-Location
}
