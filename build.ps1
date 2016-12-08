Push-Location $PSScriptRoot
try {
    Import-Module ./helpers
    Import-Module pscx

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
    }
    finally {
        Pop-Location
    }
    # III. Configure & build nginx
    Push-Location (Get-Local "nginx")
    try{
        Import-Msys
        Import-VisualStudio -VS:($env:VS)
        Start-Bash (Resolve-Path (Get-Local "config.sh"))
        Start-Nmake
        $Local:binPath = Get-Local "bin"
        Remove-Item -Path $Local:binPath -Force -Recurse -ErrorAction SilentlyContinue
        New-Item -Path:$Local:binPath -ItemType Directory -ErrorAction SilentlyContinue
        Move-Item -Path:(Combine-Paths -PathParts @("objs", "nginx.exe")) -Destination:$Local:binPath
        $Local:assetName = "nginx-$env:TARGET.zip"
        Get-ChildItem -Recurse $Local:binPath |
            Write-Zip -OutputPath:(Get-Local $Local:assetName) -IncludeEmptyDirectories -EntryPathRoot $Local:binPath
    }
    finally {
        Pop-Location
    }
}
finally {
    Pop-Location
}
