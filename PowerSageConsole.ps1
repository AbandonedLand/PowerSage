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

function Join-SageOffers{
    <#
    .SYNOPSIS
    Combine multiple offer strings into a single offer string.

    .DESCRIPTION
    This is used to combine multiple offers togeter so they are accepted as a signle offer.

    .PARAMETER offers
    An array of offer strings to combine.

    .EXAMPLE
    $offer1 = "offer1....."
    $offer2 = "offer2....."
    $offer_array = @($offer1, $offer2)
    Join-SageOffers -offers $offer_array

    This will combine the two offers into a single offer string.

    #>
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$offers
    )
    $json = @{
        offers = $offers
    }
    Invoke-SageRPC -endpoint combine_offers -json $json
}