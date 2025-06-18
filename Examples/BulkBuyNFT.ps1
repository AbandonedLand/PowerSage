# Step 1 - Install or Update PowerDexie 

Install-Module -Name PowerDexie
# Update-Module -Name PowerDexie 

# Step 2 - Install or Update PowerSage
Install-Module -Name PowerSage
# Update-Module -Name PowerSage

# Step 3 - Import PowerDexie
Import-Module PowerDexie    

# Step 4 - Import PowerSage
Import-Module PowerSage


# Step 5 - Configure PowerSage to access your Sage Wallet

New-SagePfxCertificate

# Step 6 - Get the NFT collection you want to buy.

    # Collection = Data Layer Minions

$collection = "col1k86fjeaje70hhy46yp4c2jfuhddlt66zcd6mw86zzy2d4egage3sa302t4"

# Step 7 - Determin how to pay for the NFTs

$pay_with = "XCH" 

# Step 8 - Get a list of NFT Offers
$offers = Get-DexieOffers -offered $collection -requested $pay_with -page_size 50 

# Step 9 - How many offers do you want to buy?
$number_of_offers = 20

# Step 10 - Make array of offers 
$array_of_offers = ($offers.offers.offer | Select-Object -First $number_of_offers)


# Step 11 - Combine the offers into a single transaction
$combined_offers = Join-SageOffers -offers $array_of_offers


# Step 12 
# Uncomment to accept and run the line below to accept offer.

# Complete-SageOffer -offer $combined_offers.offer