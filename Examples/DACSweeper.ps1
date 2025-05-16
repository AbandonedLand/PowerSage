# Need to sell your DAC nfts from sols lot?

# Step 1: Check your NFTs.
# ----------------------------------


# The easiest way is to check your DACs NFT Collection ID on MintGarden.

# This is the collection ID for 1050 44th Ave N.
##  https://mintgarden.io/collections/1050-44th-ave-n-col14h5et5y0qu8l0835ry8820kda2m3r2lgqkwy3dew0ahawptnlgzspx0n0e

# For this test i'm using some NFTs from the compression heads collection.
$collection_id = "col1j7cj5r42x5kkszr3mv088c6gf36xuq5tqf7rlsfrs5yky862gy9qyfs6z3"


$my_nfts = Get-SageNfts -collection_id $collection_id -offset 0 -limit 1000 

# Step 2: Check Dexie for your NFTs.
# ----------------------------------


# Make sure to set the price you expect to see so you don't grab any bad offers.
# this is the current price for the 1050 44th Ave N DACs.

$expected_price = 28.518


# Make sure to set the token you expect to see so you don't grab any bad offers.
# This is the wUSDC.b token ID.
$expected_token = "fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d"



# A blank array to hold the offers.
$dexie_nfts = @()

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

# Step 3: Combine the offers.
# ----------------------------------

$combined_offers = Join-SageOffers -offers $dexie_nfts

if($combined_offers){
    Clear-Host
    Write-Host "Your floor is swept!"
    Write-Host "Your combined offer is below:"
    Write-Host "Copy and paste into Sage Wallet to view the offer."
    Write-Host ""

    $combined_offers.offer
    Write-Host ""
    Write-Host ""

}

