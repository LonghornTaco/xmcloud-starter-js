$ErrorActionPreference = "Stop"

# Set the root of the repository.
$RepoRoot = Resolve-Path "$PSScriptRoot\..\.."

# Verify the user has run init.ps1 (TLS certs must exist).
$certFile = Join-Path $RepoRoot "local-containers\docker\traefik\certs\cert.pem"
if (-not (Test-Path $certFile)) {
    Write-Host "TLS certificates are missing. Run ./local-containers/scripts/init.ps1 first." -ForegroundColor Red
    exit 1
}

Push-Location (Join-Path $RepoRoot "local-containers")
try {
    Write-Host "Building containers..." -ForegroundColor Green
    docker compose build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Container build failed, see errors above."
    }

    Write-Host "Starting containers..." -ForegroundColor Green
    docker compose up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Container up failed, see errors above."
    }

    Write-Host "Waiting for Mockingbird Traefik route..." -ForegroundColor Green
    $startTime = Get-Date
    do {
        Start-Sleep -Milliseconds 200
        try {
            $status = Invoke-RestMethod "http://localhost:8079/api/http/routers/mockingbird-secure@docker"
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -ne "404") { throw }
        }
    } while ($status.status -ne "enabled" -and $startTime.AddSeconds(60) -gt (Get-Date))
    if ($status.status -ne "enabled") {
        Write-Error "Timeout waiting for Mockingbird route. Check container logs."
    }

    Write-Host ""
    Write-Host "Stack is up." -ForegroundColor Green
    Write-Host "  Mockingbird Web UI: https://mockingbird.xmc-starter-js.localhost"
    Write-Host "  Rendering host:     https://nextjs.xmc-starter-js.localhost"
    Write-Host ""
    Write-Host "Logs:"
    Write-Host "  docker compose logs -f rendering"
    Write-Host "  docker compose logs -f mockingbird"
}
finally {
    Pop-Location
}
