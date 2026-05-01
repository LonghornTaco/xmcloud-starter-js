[CmdletBinding(DefaultParameterSetName = "no-arguments")]
Param (
    [Parameter(HelpMessage = "Regenerates Traefik TLS certificates even if they already exist.")]
    [switch]$RecreateCerts
)

$ErrorActionPreference = "Stop"

# Set the root of the repository.
$RepoRoot = Resolve-Path "$PSScriptRoot\..\.."

Write-Host "Preparing the local container environment..." -ForegroundColor Green

$renderingHostName = "xmc-starter-js.localhost"
$mockingbirdHost = "mockingbird.$renderingHostName"
$nextjsHostName = "nextjs.$renderingHostName"

##################################
# Configure TLS/HTTPS certificates
##################################

$certsPath = Join-Path $RepoRoot "local-containers\docker\traefik\certs"
if (-not (Test-Path $certsPath)) {
    New-Item -ItemType Directory -Path $certsPath -Force | Out-Null
}

$certFile = Join-Path $certsPath "cert.pem"
$keyFile = Join-Path $certsPath "key.pem"

if ($RecreateCerts) {
    Remove-Item $certFile -Force -ErrorAction SilentlyContinue
    Remove-Item $keyFile -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $certFile) -or -not (Test-Path $keyFile)) {
    Push-Location $certsPath
    try {
        $mkcert = ".\mkcert.exe"
        if ($null -ne (Get-Command mkcert.exe -ErrorAction SilentlyContinue)) {
            $mkcert = "mkcert"
        }
        elseif (-not (Test-Path $mkcert)) {
            Write-Host "Downloading mkcert..." -ForegroundColor Green
            Invoke-WebRequest "https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-windows-amd64.exe" -UseBasicParsing -OutFile mkcert.exe
            if ((Get-FileHash mkcert.exe).Hash -ne "1BE92F598145F61CA67DD9F5C687DFEC17953548D013715FF54067B34D7C3246") {
                Remove-Item mkcert.exe -Force
                throw "Invalid mkcert.exe file"
            }
        }

        Write-Host "Generating Traefik TLS certificate..." -ForegroundColor Green
        & $mkcert -install
        # One cert covers both the rendering host and Mockingbird subdomains.
        & $mkcert -cert-file cert.pem -key-file key.pem $mockingbirdHost $nextjsHostName "*.$renderingHostName"

        $caRoot = "$(& $mkcert -CAROOT)\rootCA.pem"
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "TLS certificates already exist (use -RecreateCerts to regenerate)." -ForegroundColor Yellow
    $caRoot = $null
}

###############################
# Add hosts-file entries
###############################

# windows-hosts-writer takes care of these at runtime once the stack is up,
# but pre-populating gives faster first-boot UX.

Write-Host "Note: Hostnames are written by the windows-hosts-writer container." -ForegroundColor Cyan
Write-Host "  - https://$nextjsHostName"
Write-Host "  - https://$mockingbirdHost"

if ($caRoot) {
    Write-Host
    Write-Host ("#" * 75) -ForegroundColor Cyan
    Write-Host "To avoid HTTPS errors in Node, set the NODE_EXTRA_CA_CERTS env var:" -ForegroundColor Cyan
    Write-Host "  setx NODE_EXTRA_CA_CERTS $caRoot" -ForegroundColor Yellow
    Write-Host
    Write-Host "Restart your terminal or VS Code afterward." -ForegroundColor Cyan
    Write-Host ("#" * 75) -ForegroundColor Cyan
}

Write-Host "Done!" -ForegroundColor Green
