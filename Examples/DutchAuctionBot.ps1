<#

Dutch Auction:
    - The auction starts at a high price and decreases over time.
    - The first bidder to accept the current price wins the auction.
    - The auction ends when a bid is accepted or the time limit is reached.

    - The auction can be set to a specific duration.
    - The auction can be set to a specific start price.
    - The auction can be set to a specific end price.
    - The auction can be set to a specific decrement amount.
    - The auction can be set to a specific decrement interval.
    

#>


# Start-SimpleDuctchAuction -nft_id nft10wplkl3w3n39m478pt36yd8cpx6v5g2vg87g0xwvd8zj2l5p7v6qy3p0gk -start_xch_price 5 -end_xch_price 2 -decrement_xch_amount 0.25 -decrement_min_interval 10

function Start-SimpleDuctchAuction {

    [CmdletBinding()]
    param(
                
        [Parameter(Mandatory=$true)]
        [string]$nft_id,
        
        [Parameter(Mandatory=$true)]
        [decimal]$start_xch_price,
        
        [Parameter(Mandatory=$true)]
        [decimal]$end_xch_price,
        
        [Parameter(Mandatory=$true)]
        [decimal]$decrement_xch_amount,
        
        [Parameter(Mandatory=$true)]
        [int]$decrement_min_interval
    )


    # Covert input to the mojo value.
    $current_xch_price = ($start_xch_price | ConvertTo-XchMojo)

    # Convert the end price to mojo.
    $end_xch_price = ($end_xch_price | ConvertTo-XchMojo)

    # Convert the decrement amount to mojo.
    $decrement_xch_amount = ($decrement_xch_amount | ConvertTo-XchMojo)
    
    # Set the exit flag to false.
    $exit = $false

    # While not told to exit...  do stuff.
    while(-Not $exit){
        Write-Host "Starint got at $current_xch_price"
        if( $current_xch_price -le $end_xch_price){
            $exit = $true
            break
        }
        
        # Create the offer class to build the offer.

        $offer = Build-SageOffer

        # Add the NFT to the offer side.
        $offer.offerNft($nft_id)

        # Add xch to the request side.
        $offer.requestXch($current_xch_price)

        # Set the expiration time
        $offer.setMinutesUntilExpires($decrement_min_interval)
        
        # Build the offer on your wallet.
        $offer.createoffer() 

        # Get the string for the offer.
        $offer_data = $offer.offer_data.offer
        
        # Send the offer to dexie.  Please validate your offer is right, this doesn't ask questions it just does it.

        $dexie = Submit-DexieOffer -offer $offer_data
        
        
        # Make the price lower for the next run.
        $current_xch_price = $current_xch_price - $decrement_xch_amount
        
        # Sleep for the decrement interval.
        Start-Sleep -Seconds ($decrement_min_interval*60)

    }

  

}