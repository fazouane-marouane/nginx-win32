Push-Location $PSScriptRoot

# Helper function to extract vars out of the vsvars batch file
function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

try {
Import-Module ./helpers -Global

#Set environment variables for Visual Studio Command Prompt
$vsvarspath = Join-Path $env:VS120COMNTOOLS vsvars32.bat
Get-BatchFile($vsvarspath)

# I. Clone Nginx
Remove-Item -Path (Get-Local "nginx") -Force -Recurse -ErrorAction SilentlyContinue
$local:repo = Clone-Repository -RepoUri:"https://github.com/nginx/nginx.git" -Destination:(Get-Location) |
    Checkout-Tag -TagName:"release-1.10.2" |
    Apply-Patch -PatchLocation:(Resolve-Path "nginx.patch")

# II. Gather the dependencies
$Local:dependenciesLocation = Combine-Paths -PathParts @("nginx", "objs", "lib")
Remove-Item -Path $Local:dependenciesLocation -Force -Recurse -ErrorAction SilentlyContinue
New-Item -Path $Local:dependenciesLocation -ItemType Directory -ErrorAction SilentlyContinue
Push-Location $Local:dependenciesLocation
try{
$local:dependencies=@(
    [Uri]"https://github.com/openssl/openssl/archive/OpenSSL_1_0_2j.zip",
    [Uri]"https://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.zip",
    [Uri]"http://zlib.net/zlib128.zip",
    [Uri]"http://www.nasm.us/pub/nasm/releasebuilds/2.12.02/win32/nasm-2.12.02-win32.zip"
) | ForEach-Object { [PSCustomObject]@{ Uri=$_; File=(Get-Local -Name ($_.Segments[-1]))} }
# Download dependencies & Unzip them
$local:dependencies | ForEach-Object { (New-Object Net.WebClient).DownloadFile($_.Uri, $_.File) }
$local:dependencies | ForEach-Object { Expand-Archive -Path:$_.File -DestinationPath:(Get-Location) }
Rename-Item -Path:(Get-Local -Name:"openssl-OpenSSL_1_0_2j") "openssl"
Rename-Item -Path:(Get-Local -Name:"pcre-8.39") "pcre"
Rename-Item -Path:(Get-Local -Name:"zlib-1.2.8") "zlib"
Rename-Item -Path:(Get-Local -Name:"nasm-2.12.02") "nasm"
foreach($item in @( (Get-Local "nasm"), (Combine-Paths -PathParts @("nasm", "rdoff")) )){
    if(-Not ($env:Path.Split(";") -contains $item)){
        $env:Path = "$item;$env:Path"
    }
}
$local:GitPaths = ($env:Path.Split(";") | Where-Object { $_.Contains("Git") }) -join ";"
$env:Path = ($env:Path.Split(";") | Where-Object { -Not ($_.Contains("Git")) }) -join ";"
foreach($item in @( "C:\MinGW\msys\1.0\bin", "C:\MinGW\bin", $local:GitPaths )){
    if(-Not ($env:Path.Split(";") -contains $item)){
        $env:Path = "$env:Path;$item"
    }
}
}
finally {
Pop-Location
}
# III. Configure & build nginx
Push-Location (Get-Local "nginx")
try{
    & "C:\MinGW\msys\1.0\bin\bash.exe" "config.sh" 2> $null
    if ($LASTEXITCODE) {
        Write-Error "config: failed"
    }
    & "nmake" 2> $null
    if ($LASTEXITCODE) {
        Write-Error "nmake: failed"
    }
}
finally {
Pop-Location
}
}
finally {
Pop-Location
}
