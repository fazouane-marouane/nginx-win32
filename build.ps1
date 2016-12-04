Push-Location $PsScriptRoot
Import-Module ./helpers

Clone-Repository -RepoUri:"https://github.com/nginx/nginx.git" -Destination:(Get-Location) |
    Checkout-Tag -TagName:"release-1.10.2" |
    Apply-Patch -PatchLocation:(Resolve-Path "nginx.patch") |
    Out-Null
Pop-Location
