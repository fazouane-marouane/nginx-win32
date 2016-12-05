function Get-Local {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $Name
    )
    process {
        (Join-Path -Path:(Get-Location) -ChildPath:$Name)
    }
}

function Combine-Paths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [String] $ParentPath = (Get-Location),

        [Parameter(Mandatory=$true)]
        [String[]] $PathParts
    )
    process {
        $PathParts | ForEach-Object {$script:path=$ParentPath} { $Script:path = (Join-Path -Path:$Script:path -ChildPath:$_) } {$Script:path}
    }
}
