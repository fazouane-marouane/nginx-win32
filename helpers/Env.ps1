function Import-BatchEnvironment {
    # Source: https://github.com/olegsych/posh-vs/blob/master/posh-vs.psm1
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $batchFile
    )
    process{
        if (-not (Test-Path $batchFile)) {
            Throw "Batch file '$batchFile' does not exist."
        }
        Write-Verbose "Executing '$batchFile' to capture environment variables it sets."
        cmd /c "`"$batchFile`" > nul & set" | ForEach-Object {
            if ($_ -match "^(.+?)=(.*)$") {
                [string] $variable = $matches[1]
                [string] $value = $matches[2]
                Write-Verbose "`$env:$variable=$value"
                Set-Item -Force -Path "env:\$variable" -Value $value
            }
        }
    }
}

function Import-Msys {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string] $MsysPath = "C:\MinGW\msys\1.0\bin",

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string] $MingwPath = "C:\MinGW\bin"
    )
    process{
        $local:GitPaths = ""
        foreach($item in ($env:Path.Split(";") | Group-Object { $_.Contains("Git") })){
            if($item.Name -eq $true) {
                $local:GitPaths = $item.Group -join ";"
            }
            else {
                $env:Path = $item.Group -join ";"
            }
        }
        foreach($item in @( $MsysPath, $MingwPath, $local:GitPaths )){
            if(-Not ($env:Path.Split(";") -contains $item)){
                $env:Path = "$env:Path;$item"
            }
        }
    }
}

function Start-Bash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [System.Management.Automation.PathInfo] $ScriptPath,

        [Parameter()]
        [string] $BashExe = "C:\MinGW\msys\1.0\bin\bash.exe"
    )
    process{
        Push-Location (Split-Path $ScriptPath -Parent)
        & $BashExe "$(Split-Path $ScriptPath -Leaf)" 2> $null
        if ($LASTEXITCODE) {
            Write-Error "config: failed"
        }
        Pop-Location
    }
}

function Start-Nmake{
    [CmdletBinding()]
    param(
    )
    process{
        & "nmake.exe" 2> $null
        if ($LASTEXITCODE) {
            Write-Error "nmake: failed"
        }
    }
}

function Import-VisualStudioEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $VS
    )
    process {
        Import-BatchEnvironment (Get-BatFilename $VS)
    }
}

function Get-BatFilename {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $VS
    )
    process {
        [string]$local:VsBatFile = ""
        switch ($VS) {
            "2017" { $local:VsBatFile="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\VsDevCmd.bat" }
            "2015" { $local:VsBatFile= Join-Path $env:VS140COMNTOOLS "VsDevCmd.bat" }
            "2013" { $local:VsBatFile= Join-Path $env:VS120COMNTOOLS "vsvars32.bat" }
            "2010" { $local:VsBatFile= Join-Path $env:VS100COMNTOOLS "vsvars32.bat" }
            "2008" { $local:VsBatFile= Join-Path $env:VS90COMNTOOLS  "vsvars32.bat" }
            Default { }
        }
        $local:VsBatFile
    }
}

function Import-VisualStudio {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $VS=""
    )
    process{
        if(-Not $VS) {
            if ((Test-Path (Get-BatFilename "2017"))) {
                $VS = "2017"
            }
            elseif ($env:VS140COMNTOOLS -and (Test-Path (Get-BatFilename -VS:"2015"))) {
                $VS = "2015"
            }
            elseif ($env:VS120COMNTOOLS -and (Test-Path (Get-BatFilename -VS:"2013"))) {
                $VS = "2013"
            }
            elseif ($env:VS100COMNTOOLS -and (Test-Path (Get-BatFilename -VS:"2010"))) {
                $VS = "2010"
            }
            elseif ($env:VS90COMNTOOLS -and (Test-Path (Get-BatFilename -VS:"2008"))) {
                $VS = "2008"
            }
        }
        Write-Host "Importing Visual Studio $VS."
        Import-VisualStudioEnvironment -VS:$VS
    }
}
