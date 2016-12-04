function Clone-Repository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $RepoUri,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [System.Management.Automation.PathInfo] $Destination,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Name
    )
    process {
        Push-Location $Destination
        if(!$Name){
            $script:RepoNameMatcher = ([regex]"([^/]*)\.git$").Match($RepoUri)
            $Name = $script:RepoNameMatcher.Groups[1].Value
        }
        git @("clone", $RepoUri, $Name)
        Pop-Location
        $script:RepoDestination = Resolve-Path (Join-Path -Path $Destination -ChildPath $Name)
        $script:RepoDestination
    }
}

function Checkout-Tag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Management.Automation.PathInfo] $RepoPath,

        [Parameter(Mandatory=$true)]
        [String] $TagName
    )
    process{
        Push-Location $RepoPath
        $script:Args = @("checkout", "tags/$TagName")
        git $script:Args
        Pop-Location
        $RepoPath
    }
}

function Apply-Patch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Management.Automation.PathInfo] $RepoPath,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PathInfo] $PatchLocation
    )
    process{
        Push-Location $RepoPath
        $script:Args = @("apply", $PatchLocation)
        git $script:Args
        Pop-Location
        $RepoPath
    }
}
