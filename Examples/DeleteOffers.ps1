$offers = Get-SageOffers

foreach($offer in $offers){
    # Display the offer string.
    $offer.offer
    # Delete the offer.
    Remove-SageOffer -offer_id $offer.offer_id
}