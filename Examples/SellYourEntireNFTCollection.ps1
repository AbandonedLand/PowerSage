
<#
 
Get your collection ID from the Sage Wallet.

If you don't know the collection ID you can use Get-SageNft -nft_id <nft_id> to get it.

Example:
Get-SageNft -nft_id nft1fqwpa2hjdf5ep7cms57rv9789cn4edd8szwq5n7r98cmarptzgrs4znsxp

launcher_id             : nft1fqwpa2hjdf5ep7cms57rv9789cn4edd8szwq5n7r98cmarptzgrs4znsxp
collection_id           : col1j7cj5r42x5kkszr3mv088c6gf36xuq5tqf7rlsfrs5yky862gy9qyfs6z3
collection_name         : Compression Heads
minter_did              : did:chia:1q6sc4hnkyn4ulj359kxaw94sqn7wdra5p32mme6gadwmu29daylscnvvdz
owner_did               : 
visible                 : True
sensitive_content       : False
name                    : Compression Heads #16293
created_height          : 6883464
coin_id                 : 37785ea1b7720e08cf3dd3f80f5dea0973430583723723a5c64801ca3191664c
address                 : xch14nqv3g90kfurfzmzxvkrze856wwxdy3448wgu4yuexp0rkhz250qhl5kp9
royalty_address         : xch1j75apysmced8sf3xlkt6a6fxz2dcwysgzgsf9pd242gjnsgkujeskaqedz
royalty_ten_thousandths : 500
data_uris               : {https://nftstorage.link/ipfs/bafybeic6d7foqfcxdr4swukz3cmsza2qcnv3icdk4mev377hxcrra2bobi/AA%20Chin5%20oclock%20shadowAA%20EatSmall%20FrownAA%20Ontop3%20SpikesAA%20NostrilSmall%20LowAA%20SeeTallOutlineHead.png, ipfs://bafybeic6d7foqfcxdr4swukz3cmsza2qcnv3icdk4mev377hxcrra2bobi/AA%20Chin5%20oclock%20shadowAA%20EatSmall%20FrownAA%20Ontop3%20SpikesAA%20NostrilSmall%20LowAA%20SeeTallOutlineHead.png}
data_hash               : d692348e3a05c138af4ef96f3a1a5419a98147b360476a306907feb562374e91
metadata_uris           : {https://nftstorage.link/ipfs/bafybeic6d7foqfcxdr4swukz3cmsza2qcnv3icdk4mev377hxcrra2bobi/AA%20Chin5%20oclock%20shadowAA%20EatSmall%20FrownAA%20Ontop3%20SpikesAA%20NostrilSmall%20LowAA%20SeeTallOutlineHead.json, ipfs://bafybeic6d7foqfcxdr4swukz3cmsza2qcnv3icdk4mev377hxcrra2bobi/AA%20Chin5%20oclock%20shadowAA%20EatSmall%20FrownAA%20Ontop3%20SpikesAA%20NostrilSmall%20LowAA%20SeeTallOutlineHead.json}
metadata_hash           : bbd7236203db1e5bc2cfb8b025fba4e2fe9ac7f5be925be354d4e7c1067c6eeb
license_uris            : {https://nftstorage.link/ipfs/bafybeidu6ehdxdlujzaedc22woc7pqji2nexjcbtrfzqzk6xi65ta2mtmm/Compression%20Heads%20License.pdf}
license_hash            : 57f2f2b686b6185f7573903028d020a0005a775667771a76fac86a000a79d56f
edition_number          : 1
edition_total           : 1

#>

$collection_id = "col1j7cj5r42x5kkszr3mv088c6gf36xuq5tqf7rlsfrs5yky862gy9qyfs6z3"


# Get all the NFTs in your wallet that match this collection.   

$my_nfts = Get-SageNfts -collection_id $collection_id -offset 0 -limit 1000

$xch_mojo = 1000000000000
$cat_mojo = 1000

<# 

Set your sell price in MOJO.
For example, if you want to sell for 0.1 XCH then you would use:

$price = 0.1 * $xch_mojo

If you want to sell for 25 wUSDC.b then you would use:
$price = 25 * $cat_mojo

$cat_asset_id = "fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d"

#>

$price = 0.1

# $price = $price * $cat_mojo
$price = $price * $xch_mojo

$cat_asset_id = "fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d"


<#

Now loop though the nfts in your wallet to create offers for each one.

#>

# Holder of offer data.
$offer_data = @()


foreach($nft in $my_nfts) {

    $offer = Build-SageOffer
    $offer.offerNft($nft.launcher_id)
    
    $offer.requestXch($price)
    #$offer.requestCat($cat_asset_id,$price)
    
    $offer.createoffer()

    $offer_data += $offer.offer_data.offer

}

# you how have all the offers created, check them out in your Sage Wallet before you submit them to dexie.

# Note:  They will show the requested asset + the royalty in the requested field.

# Submit them to dexie with the following command:

foreach($offer in $offer_data) {
    Submit-DexieOffer -offer $offer 
}


