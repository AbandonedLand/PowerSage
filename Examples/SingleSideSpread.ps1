$requested_token = "ea3ace5525d6aaf6d921b66052afc67da11c820b676de91d61ae1a766c8ce615"

$xch_per_offer = 0.2
$offered_xch_amount = ($xch_per_offer  | ConvertTo-XchMojo)
$start_price = 900000 * 0.2  # 900 crt/xch
$increments = 5000 # 5 crt/xch

0..99 | ForEach-Object {
    $requested_amount = ($start_price + ($increments * $_))
    $offer = Build-SageOffer
    $offer.offerXch($offered_xch_amount)
    $offer.requestCat($requested_token,$requested_amount)
    $offer.createoffer()
    Submit-DexieOffer -offer ($offer.offer_data.offer)

}