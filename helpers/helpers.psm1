Push-Location $PsScriptRoot
. .\Git.ps1
. .\Localpaths.ps1
Pop-Location

Export-ModuleMember -Function @(
    'Clone-Repository',
    'Checkout-Tag',
    'Apply-Patch',
    'Get-Local',
    'Combine-Paths'
)
