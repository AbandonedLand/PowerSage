# Need to sell your DAC nfts from sols lot?

# Step 1: Check your NFTs.
# ----------------------------------


# The easiest way is to check your DACs NFT Collection ID on MintGarden.

# This is the collection ID for 1050 44th Ave N.
##  https://mintgarden.io/collections/1050-44th-ave-n-col14h5et5y0qu8l0835ry8820kda2m3r2lgqkwy3dew0ahawptnlgzspx0n0e

# For this test i'm using some NFTs from the compression heads collection.
$collection_id = "col19wpxue09n5d4h7r85zzr38yz3zz2jtrveqreghr06z8lfwhj44ws0at3xp"




# Step 2: Check Dexie for your NFTs.
# ----------------------------------


# Make sure to set the price you expect to see so you don't grab any bad offers.
# this is the current price for the 1050 44th Ave N DACs.

$expected_price = 28.471


# Make sure to set the token you expect to see so you don't grab any bad offers.
# This is the wUSDC.b token ID.
$expected_token = "fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d"



# A blank array to hold the offers.




function Complete-DACRedemption{
    param(
        [Parameter(Mandatory = $true)]
        [string]$collection_id,
        [Parameter(Mandatory = $true)]
        [string]$expected_price,
        [string]$expected_token = "fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d"
    )


    Clear-Host
    Write-Host "Checking your NFTs in collection: $collection_id" -ForegroundColor Cyan
    # Get your NFTs from the collection.

    $my_nfts = Get-SageNfts -collection_id $collection_id -offset 0 -limit 1000 
    if($null -eq $my_nfts) {
        Write-Host "No NFTs found in the collection." -ForegroundColor Red
        return
    }
    Write-Host "Found $($my_nfts.Count) NFTs in the collection." -ForegroundColor Green

    # placeholder for dexie nfts.
    # This will hold the NFTs that have offers on Dexie.
    $dexie_nfts = @()

    Write-Host "Checking Dexie for offers on your NFTs..." -ForegroundColor Cyan
    # Loop through the NFTs and check for offers.
    foreach($nft in $my_nfts) {
        # Check if the NFT is listed on Dexie.
        # You'll need to make sure you have the PowerDexie module installed.
        # If you don't have it, you can install it with the following command:
        # Install-Module -Name PowerDexie -Scope CurrentUser -Force

        $offer = Get-DexieOffers -requested $nft.launcher_id -offered $expected_token

        if($offer) {
            foreach($singleOffer in $offer.offers) {
                # Check if the offer is for the expected price.
                if($singleOffer.price -eq $expected_price) {
                    # Add the offer to the array.
                    $dexie_nfts += $singleOffer.offer
                }
            }
            
        }
    }
    if($dexie_nfts.Count -eq 0) {
        Write-Host "No offers found on Dexie for your NFTs." -ForegroundColor Yellow
        return
    }
    Write-Host "Found $($dexie_nfts.Count) offers on Dexie for your NFTs." -ForegroundColor Green


    $title    = 'Accept Dexie Offers'
    $question = 'Do you wish to redeem your offers?'
    $Choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Redeem the offers"),
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Do not redeem the offers")
    )
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)

    if($decision -eq 0) {
        Write-Host "Redeeming offers..." -ForegroundColor Cyan
        # Loop through the offers and redeem them.
        $dexie_nfts | ForEach-Object {
            Complete-SageOffer -offer $_ 
        }
        Write-Host "Offers redeemed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "This module was written by @MayorAbandoned on Twitter." -ForegroundColor Cyan
        Write-Host "If you have any questions, feel free to reach out!" -ForegroundColor Cyan
        Write-Host "https://x.com/MayorAbandoned" -ForegroundColor Cyan
        Write-Host ""
        Write-Host ""
        Write-Host "If you'd like to leave a tip, you can do so at the following address:" -ForegroundColor Green
        Write-Host "xch1xtn62vckj2dmpdlttewfgpsz6zluw8jpj57v308whcu5ty86xhlq3a0h0e" -ForegroundColor Green


    }
    else {
        Write-Host "Not redeeming offers." -ForegroundColor Yellow
    }

}

