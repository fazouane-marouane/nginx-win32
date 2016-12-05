Push-Location $PSScriptRoot
try {
Import-Module ./helpers -Global

# I. Clone Nginx
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
    [Uri]"ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.zip",
    [Uri]"http://zlib.net/zlib128.zip"
) | ForEach-Object { [PSCustomObject]@{ Uri=$_; File=(Get-Local -Name ($_.Segments[-1]))} }
# Download dependencies & Unzip them
$local:dependencies | ForEach-Object { (New-Object Net.WebClient).DownloadFile($_.Uri, $_.File) }
$local:dependencies | ForEach-Object { Expand-Archive -Path:$_.File -DestinationPath:(Get-Location) }
Rename-Item -Path:(Get-Local -Name:"openssl-OpenSSL_1_0_2j") "openssl"
Rename-Item -Path:(Get-Local -Name:"pcre-8.39") "pcre"
Rename-Item -Path:(Get-Local -Name:"zlib-1.2.8") "zlib"
}
finally {
Pop-Location
}
}
finally {
Pop-Location
}