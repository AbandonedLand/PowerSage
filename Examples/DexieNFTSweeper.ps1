


$offered = "col19wpxue09n5d4h7r85zzr38yz3zz2jtrveqreghr06z8lfwhj44ws0at3xp"
$requested = "wUSDC.b"
$quantity = 2
$to_buy = @()
$nfts = Get-DexieOffers -requested $requested -offered $offered -page_size $quantity -sort date_found 
foreach($nft in $nfts.offers){
    
    $to_buy += $nft.offer
}
# Combine the offers into a single offer.
$combined_offer = Join-SageOffers -offers $to_buy

# Display the offer string.
$combined_offer.offer
