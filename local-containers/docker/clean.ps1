# Clean writable per-run state for the local Mockingbird stack.
# Removes Mockingbird's persistent index cache so the next boot does a
# fresh parse of the SCS tree. Safe to run while the stack is down.

$ErrorActionPreference = "Stop"

$cachePath = Join-Path $PSScriptRoot "..\mockingbird-cache"
if (Test-Path $cachePath) {
    Get-ChildItem -Path $cachePath -Exclude ".gitignore" -Recurse |
        Remove-Item -Force -Recurse -Verbose
}
