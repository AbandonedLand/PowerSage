. ./PowerSageRpc.ps1

if (-not (Get-Module -ListAvailable -Name pwshspectreconsole)) {
    Install-Module -Name pwshspectreconsole -Scope CurrentUser -Force
}

if (-not (Get-Module -Name pwshspectreconsole)) {
    Import-Module -Name pwshspectreconsole
}


function Invoke-PowerSageConsole {
    if(Confirm-SageDaemon){
        Show-WelcomeScreen
    }
    
}

function Show-WelcomeScreen{
    Clear-Host
    Write-SpectreFigletText -Text "PowerSage Console" -Color Green1
    Show-Balances

}

function Show-Balances {
    $xch = Get-SageSyncStatus
    $cats = Get-SageCats

    $data = @()
    $data += [PSCustomObject]@{
        Name = "Xch"
        Balance = ($xch.balance | ConvertFrom-XchMojo)
    }
    foreach ($cat in $cats) {
        $data += [PSCustomObject]@{
            Name = $cat.name
            Balance = ($cat.balance | ConvertFrom-CatMojo)
        }
    }

    Format-SpectreTable -Data $data -Color Green1 -Width 50
}
