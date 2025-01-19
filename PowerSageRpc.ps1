function Start-SageDaemon{
    <#
    .SYNOPSIS
    Starts the SageDaemon job.

    .DESCRIPTION
    The Start-SageDaemon function initiates a background job named "SageDaemon" that runs the command `sage rpc start`.

    .EXAMPLE
    Start-SageDaemon

    This command starts the SageDaemon job.

    .NOTES
    Make sure the `sage` command is available in the system's PATH.
    #>

    Start-Job -Name "SageDaemon" -ScriptBlock {
        sage rpc start
    }
}

function Stop-SageDaemon{
    <#
    .SYNOPSIS
    Stops the SageDaemon job.

    .DESCRIPTION
    The Stop-SageDaemon function stops the background job named "SageDaemon".

    .EXAMPLE
    Stop-SageDaemon

    This command stops the SageDaemon job.

    .NOTES
    This will remove and clear out the SageDaemon Job.
    #>

    Stop-Job -Name "SageDaemon"
    Remove-Job -Name "SageDaemon"
}

function Confirm-SageDaemon{
    
    

    if(Get-Job -Name "SageDaemon" -ErrorAction SilentlyContinue){
        return $true
    } else {
        return $false
    }
}

function Get-SageDaemonOutput {
    Receive-Job -Name "SageDaemon"
}

function Invoke-SageRPC {
    
    param(
        [Parameter(Mandatory=$true)]
        $endpoint,
        $json
    )

    $data = $json | ConvertTo-Json -Depth 30

    sage rpc $endpoint $data | ConvertFrom-Json
}

function New-SageMnemonic {
    param(
        [switch] $Use24Words
    )
    $json = @{
        use_24_words = $Use24Words.IsPresent
    }
    $mnemonic = Invoke-SageRPC -endpoint generate_mnemonic -json $json
    $mnemonic.mnemonic  
}

function Import-SageKeys {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$mnemonic,
        [Parameter(Mandatory=$true)]
        [string]$name
    )
    process {
        $json = @{
            name = $name
            key = $mnemonic
        }
        Invoke-SageRPC -endpoint import_key -json $json
    }
}

function Get-SageKey {
    param (
        [Parameter(Mandatory=$true)]
        [uint32]$fingerprint
    )
    $json = @{
        fingerprint = $fingerprint
    }
    $key = Invoke-SageRPC -endpoint get_key -json $json
    $key.key
}


function Get-SageKeys {
    $keys = Invoke-SageRPC -endpoint get_keys -json @{}
    $keys.keys
}

function Connect-SageFingerprint {
    param (
        [Parameter(Mandatory=$true)]
        [UInt32]$fingerprint
    )
    $json = @{
        fingerprint = $fingerprint
    }
    Invoke-SageRPC -endpoint login -json $json
}

function Disconnect-Sage {
    Invoke-SageRPC -endpoint logout -json @{}
}


function Get-SageDerivations {
    param(
        [switch]
        $hardened,
        [Parameter(Mandatory=$true)]
        [UInt32]
        $offset,
        [Parameter(Mandatory=$true)]
        [UInt32]
        $limit
    )

    $json = @{
        hardened = $hardened.IsPresent
        offset = $offset
        limit = $limit
    }

    $derivations = Invoke-SageRPC -endpoint get_derivations -json $json
    $derivations.derivations
}

function Get-SageSyncStatus{
    Invoke-SageRPC -endpoint get_sync_status -json @{}
}

function Get-SageCats{
    $cats = Invoke-SageRPC -endpoint get_cats -json @{}
    $cats.cats
}

function Get-SageCatCoins{
    param(
        [Parameter(Mandatory=$true)]
        [string]$asset_id,
        [ValidateSet("any","spent","unspent")]
        [string]$status
        
    )
    $json = @{
        asset_id = $asset_id
    }
    $coins = Invoke-SageRPC -endpoint get_cat_coins -json $json

    if($status -eq "spent"){
        $coins.coins | Where-Object { $null -ne $_.spent_height }
    } elseif($status -eq "unspent"){
        $coins.coins | Where-Object { $null -eq $_.spent_height }
    } else {
        $coins.coins
    }
}

function Get-SageCat{
    param(
        [Parameter(Mandatory=$true)]
        [string]$asset_id
    )
    $json = @{
        asset_id = $asset_id
    }
    $cat = Invoke-SageRPC -endpoint get_cat -json $json
    $cat.cat
}

function Remove-Cat{
    param(
        [Parameter(Mandatory=$true)]
        [string]$asset_id
    )
    $json = @{
        asset_id = $asset_id
    }
    Invoke-SageRPC -endpoint remove_cat -json $json
}

function Set-SageDerivationIndex {
    param(
        [switch]
        $hardened,
        [UInt32]
        $index
    )
    $json = @{
        hardened = $hardened.IsPresent
        index = $index
    }
    Invoke-SageRPC -endpoint increase_derivation_index -json $json
}

function Sync-SageFingerprint {
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$fingerprint
    )
    $json = @{
        fingerprint = $fingerprint
    }
    Invoke-SageRPC -endpoint resync -json $json
}

function Remove-SageKey{
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$fingerprint
    )
    $json = @{
        fingerprint = $fingerprint
    }
    Invoke-SageRPC -endpoint delete_key -json $json
}

function Rename-SageKey {
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$fingerprint,
        [Parameter(Mandatory=$true)]
        [string]$name
    )
    $json = @{
        fingerprint = $fingerprint
        name = $name
    }
    Invoke-SageRPC -endpoint rename_key -json $json
}

function Get-SageSecretKey {
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$fingerprint
    )
    $json = @{
        fingerprint = $fingerprint
    }

    $secrets = Invoke-SageRPC -endpoint get_secret_key -json $json
    $secrets.secrets
}


function Get-SageXchCoins{
    param(
        [ValidateSet("any","spent","unspent")]
        [string]$status
    )

    $coins = Invoke-SageRPC -endpoint get_xch_coins -json @{}
    
    if($status -eq "spent"){
        $coins.coins | Where-Object { $null -ne $_.spent_height }
    } elseif($status -eq "unspent"){
        $coins.coins | Where-Object { $null -eq $_.spent_height }
    } else {
        $coins.coins
    }
    
}

function Get-SageDids {
    $dids = Invoke-SageRPC -endpoint get_dids -json @{}
    $dids.dids
}

function Get-SagePendingTransactions {
    $transactions = Invoke-SageRPC -endpoint get_pending_transactions -json @{}
    $transactions.transactions
}

function Get-SageTransactions {
    param(
        [Parameter(Mandatory=$true)]
        [uint32]$offset,
        [Parameter(Mandatory=$true)]
        [uint32]$limit
    )
    $json = @{
        offset = $offset
        limit = $limit
    }
    $transactions = Invoke-SageRPC -endpoint get_transactions -json $json
    $transactions.transactions
}

function Get-SageTransaction {
    param(
        [Parameter(Mandatory=$true)]
        [string]$transaction_id
    )
    $json = @{
        transaction_id = $transaction_id
    }
    $transaction = Invoke-SageRPC -endpoint get_transaction -json $json
    $transaction.transaction
}

function Get-SageNftCollections {
    param(
        [Parameter(Mandatory=$true)]
        [uint32]$offset,
        [Parameter(Mandatory=$true)]
        [uint32]$limit,
        [switch]
        $include_hidden
    )

    $json = @{
        offset = $offset
        limit = $limit
        include_hidden = $include_hidden.IsPresent
    }

    $collections = Invoke-SageRPC -endpoint get_nft_collections -json $json
    $collections.collections
}

function Get-SageNftCollection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$collection_id
    )

    $json = @{
        collection_id = $collection_id
    }

    $collection = Invoke-SageRPC -endpoint get_nft_collection -json $json
    $collection.collection
}

function Get-SageNfts {
    param(
        [string]$collection_id,
        [Parameter(Mandatory=$true)]
        [uint32]$offset,
        [Parameter(Mandatory=$true)]
        [uint32]$limit,
        [ValidateSet("name","recent")]
        $sort_mode,
        [switch]
        $include_hidden
    )

    $json = @{
        offset = $offset
        limit = $limit
        include_hidden = $include_hidden.IsPresent
    }

    if ($collection_id) {
        $json.collection_id = $collection_id
    }
    if($sort_mode){
        $json.sort_mode = $sort_mode
    } else {
        $json.sort_mode = "recent"
    }

    $nfts = Invoke-SageRPC -endpoint get_nfts -json $json
    $nfts.nfts
}

function Get-SageNft {
    param(
        [Parameter(Mandatory=$true)]
        [string]$nft_id
    )

    $json = @{
        nft_id = $nft_id
    }

    $nft = Invoke-SageRPC -endpoint get_nft -json $json
    $nft.nft
}

function Get-SageNftData {
    param(
        [Parameter(Mandatory=$true)]
        [string]$nft_id
    )

    $json = @{
        nft_id = $nft_id
    }

    $data = Invoke-SageRPC -endpoint get_nft_data -json $json
    $data.data
}

function Send-SageXch {
    param(
        [Parameter(Mandatory=$true)]
        [UInt64]$amount,
        [Parameter(Mandatory=$true)]
        [string]$address,
        [uint64]$fee,        
        [string[]]$memos,
        [bool]$auto_submit
    )
    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $memos){
        $memos = @("")
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }


    $json = @{
        amount = $amount
        address = $address
        fee = $fee
        memos = $memos
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint send_xch -json $json
}

function Send-SageXchBulk {
    throw "Not implemented"
}

function Join-SageXchCoins {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$coin_ids,
        [uint64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }
    $json = @{
        coin_ids = $coin_ids
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint combine_xch -json $json
}

function Split-SageXchCoin {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$coin_ids,
        [Parameter(Mandatory=$true)]
        [UInt32]$output_count,
        [UInt64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        coin_ids = $coin_ids
        output_count = $output_count
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint split_xch -json $json
}



function ConvertFrom-XchMojo{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [decimal]$amount
    )
    # Check if the amount is an integer
    if ($amount -ne [math]::truncate($amount)) {
        throw "The amount must be an integer value without decimal points."
    }
    [Math]::round([double]($amount / 1000000000000), 12)
    
}

function ConvertTo-XchMojo{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [decimal]$amount
    )
    [Math]::round([double]($amount * 1000000000000), 0)
}

function ConvertFrom-CatMojo{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [decimal]$amount
    )
    # Check if the amount is an integer
    if ($amount -ne [math]::truncate($amount)) {
        throw "The amount must be an integer value without decimal points."
    }
    [Math]::round([double]($amount / 1000), 3)
}

function ConvertTo-CatMojo{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [decimal]$amount
    )
    [Math]::round([double]($amount * 1000), 0)
}

function Join-SageCatCoins{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$coin_ids,
        [uint64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }
    $json = @{
        coin_ids = $coin_ids
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint combine_cat -json $json
}

function Split-SageCatCoins{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$coin_ids,
        [Parameter(Mandatory=$true)]
        [UInt32]$output_count,
        [UInt64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        coin_ids = $coin_ids
        output_count = $output_count
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint split_cat -json $json
}


function Deploy-SageCat {
    param(
    [Parameter(Mandatory=$true)]    
    [string]$name,
    [Parameter(Mandatory=$true)]
    [string]$ticker,
    [Parameter(Mandatory=$true)]
    [UInt64]$amount,
    [UInt64]$fee,
    [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }
    $json = @{
        name = $name
        ticker = $ticker
        amount = $amount
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint issue_cat -json $json

}

function Send-SageCat {
    param(
        [Parameter(Mandatory=$true)]
        [UInt64]$amount,
        [Parameter(Mandatory=$true)]
        [string]$address,
        [Parameter(Mandatory=$true)]
        [string]$asset_id,
        [UInt64]$fee,
        [string[]]$memos,
        [bool]$auto_submit
    )
    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $memos){
        $memos = @("")
    }

    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        amount = $amount
        address = $address
        asset_id = $asset_id
        fee = $fee
        memos = $memos
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint send_cat -json $json

}

function Send-SageCatBulk {
    throw "Not implemented"
}

function New-SageDid {
    param(
        [Parameter(Mandatory=$true)]
        [string]$name,
        [uint32]$fee,
        [bool]$auto_submit
    )
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    if($null -eq $fee){
        $fee = 0
    }
    $json = @{
        name = $name
        fee = $fee
        auto_submit = $auto_submit
    }
    $did = Invoke-SageRPC -endpoint create_did -json $json
    $did
}

function Update-SageDid {
    param(
        [Parameter(Mandatory=$true)]
        [string]$did_id,
        [string]$name,
        [bool]$visible
    )
    if($null -eq $visible.IsPresent){
        $visible = $true
    }

    $json = @{
        did_id = $did_id
        name = $name
        visible = $visible
    }

    Invoke-SageRPC -endpoint update_did -json $json
}


function Send-SageDid {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$did_ids,
        [Parameter(Mandatory=$true)]
        [string]$address,
        [uint64]$fee,
        [bool]$auto_submit
    )
    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }
    $json = @{
        did_ids = $did_ids
        address = $address
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint transfer_dids -json $json
}

function Send-SageNfts{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$nft_ids,
        [Parameter(Mandatory=$true)]
        [string]$address,
        [uint64]$fee,
        [bool]$auto_submit
    )
    if($null -eq $fee){
        $fee = 0
    }

    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        nft_ids = $nft_ids
        address = $address
        fee = $fee
        memos = $memos
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint transfer_nfts -json $json
}

function Move-SageNftsToDid{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$nft_ids,
        [Parameter(Mandatory=$true)]
        [string]$did_id,
        [uint64]$fee,
        [bool]$auto_submit
    )
    if($null -eq $fee){
        $fee = 0
    }

    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        nft_ids = $nft_ids
        did_id = $did_id
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint assign_nfts_to_did -json $json
}

Class SageOffer{
    [SageAsset]$requested_assets
    [SageAsset]$offered_assets
    [UInt64]$fee
    [string]$receive_address
    [UInt64]$expires_at_second
    [pscustomobject]$offer_data
    $json


    SageOffer(){
        $this.requested_assets = [SageAsset]::new()
        $this.offered_assets = [SageAsset]::new()
        $this.fee = 0
    }

    [void] setFee([UInt64]$fee){
        $this.fee = $fee
    }

    [void] setReceiveAddress([string]$address){
        $this.receive_address = $address
    }

    [void] setExpiresAt([UInt64]$expires_at){
        $this.expires_at_second = $expires_at
    }

    [void] setMinutesUntilExpires($min){
        $DateTime = (Get-Date).ToUniversalTime()
        $DateTime = $DateTime.AddMinutes($min)
        $this.expires_at_second = [System.Math]::Truncate((Get-Date -Date $DateTime -UFormat %s))
    }

    [void] setRequestedXch([UInt64]$amount){
        $this.requested_assets.addXch($amount)
    }

    [void] setOfferedXch([UInt64]$amount){
        $this.offered_assets.addXch($amount)
    }

    [void] addRequestedCat([string]$asset_id, [UInt64]$amount){
        $this.requested_assets.addCat($asset_id, $amount)
    }

    [void] addRequestedNft([string]$nft_id){
        $this.requested_assets.addNft($nft_id)
    }

    [void] addOfferedCat([string]$asset_id, [UInt64]$amount){
        $this.offered_assets.addCat($asset_id, $amount)
    }

    [void] addOfferedNft([string]$nft_id){
        $this.offered_assets.addNft($nft_id)
    }

    [void] toJson(){
        $this.json = @{
            requested_assets = $this.requested_assets.toJson() | ConvertFrom-Json
            offered_assets = $this.offered_assets.toJson() | ConvertFrom-Json
            fee = $this.fee
        }

        if ($this.receive_address.Length -eq 62 -and $this.receive_address.StartsWith("xch")) {
            $this.json.receive_address = $this.receive_address
        }
        
        if($this.expires_at_second -gt 0){
            $this.json.expires_at_second = $this.expires_at_second
        }

        
    }

    create() {
        $this.toJson()
        $this.offer_data = Invoke-SageRPC -endpoint make_offer -json ($this.json)
        $this.import()
    }

    import(){
        Import-SageOffer -offer ($this.offer_data.offer)
    }
}



Class SageAsset{
    [UInt64]$xch
    [pscustomobject]$cats
    [string[]]$nfts

    SageAsset(){
        $this.xch = 0
        $this.cats = @()
        $this.nfts = @()
    }

    [void] addCat([string]$asset_id, [UInt64]$amount){
        $catAmount = @{
            asset_id = $asset_id
            amount = $amount
        }
        $this.cats += $catAmount
    }

    [void] addNft([string]$nft_id){
        $this.nfts += $nft_id
    }

    [void] addXch([UInt64]$amount){
        $this.xch = $amount
    }

    [string] toJson(){
        $json = @{
            xch = $this.xch
            cats = $this.cats
            nfts = $this.nfts
        }
        return $json | ConvertTo-Json -Depth 10
    }

}



function Read-SageOffer {
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer
    )
    $json = @{
        offer = $offer
    }
    
    $resolved_offer = Invoke-SageRPC -endpoint view_offer -json $json
    $resolved_offer.offer

}

function Complete-SageOffer{
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer,
        [UInt64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    if (-not $offer.StartsWith("offer1")) {
        throw "The offer must start with 'offer1'."
    }

    if($null -eq $fee){
        $fee = 0
    }
    $json = @{
        offer = $offer
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint take_offer -json $json
}

function Show-Base64Image {
    param(
        [Parameter(Mandatory=$true)]
        [string]$base64String
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $bytes = [Convert]::FromBase64String($base64String)
    $image = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new($bytes))

    $form = New-Object Windows.Forms.Form
    $form.Text = "Base64 Image Viewer"
    $form.Width = $image.Width
    $form.Height = $image.Height

    $pictureBox = New-Object Windows.Forms.PictureBox
    $pictureBox.Image = $image
    $pictureBox.Dock = "Fill"

    $form.Controls.Add($pictureBox)
    $form.ShowDialog()
}

function Submit-SageTransaction{
    param(
        [Parameter(Mandatory=$true)]
        [pscustomobject]$spendbundle
    )
    $json = @{
        spend_bundle = $spendbundle     
    }
    Invoke-SageRPC -endpoint submit_transaction -json $json
}

function Import-SageOffer{
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer
    )
    $json = @{
        offer = $offer
    }
    Invoke-SageRPC -endpoint import_offer -json $json
}


function Get-SageOffers{
    param(
        [ValidateSet("active","cancelled","expired","completed")]
        [string]$status
    )
    $json = @{}
    $offers = Invoke-SageRPC -endpoint get_offers -json $json
    
    switch ($status) {
        "active" {
            $offers.offers | Where-Object { $_.status -eq "active" }
        }
        "cancelled" {
            $offers.offers | Where-Object { $_.status -eq "cancelled" }
        }
        "expired" {
            $offers.offers | Where-Object { $_.status -eq "expired" }
        }
        "completed" {
            $offers.offers | Where-Object { $_.status -eq "completed" }
        }
        default {
            $offers.offers
        }
    }
    
}


Class SageNft{
    [UInt32]$edition_number
    [UInt32]$edition_total
    [string[]]$data_uris
    [string[]]$metadata_uris
    [string[]]$license_uris
    [string]$royalty_address
    [UInt32]$royalty_ten_thousandths

    SageNft(){
        $this.data_uris = @()
        $this.metadata_uris = @()
        $this.license_uris = @()
        $this.royalty_ten_thousandths = 0
    }

    [void] setEdition([UInt32]$edition_number, [UInt32]$edition_total){
        $this.edition_number = $edition_number
        $this.edition_total = $edition_total
    }

    [void] addDataUri([string]$uri){
        $this.data_uris += $uri
    }

    [void] addMetadataUri([string]$uri){
        $this.metadata_uris += $uri
    }

    [void] addLicenseUri([string]$uri){
        $this.license_uris += $uri
    }

    [void] setRoyaltyAddress([string]$address){
        $this.royalty_address = $address
    }

    [void] setRoyaltyTenThousandths([UInt32]$ten_thousandths){
        $this.royalty_ten_thousandths = $ten_thousandths
    }

}


function Start-SageBulkMint{
    param(
        [Parameter(Mandatory=$true)]
        [SageNft[]]$nfts,
        [Parameter(Mandatory=$true)]
        [string]$did_id,
        [UInt64]$fee,
        [bool]$auto_submit
    )

    Confirm-SageDidId -did_id $did_id

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        nfts = @()
        did_id = $did_id
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint bulk_mint_nfts -json $json


}

function Confirm-SageDidId{
    param(
        [Parameter(Mandatory=$true)]
        [string]$did_id
    )
    if($null -eq (Get-SageDids | Where-Object {$_.launcher_id -eq $did_id})){
        throw "The DID ID does not exist."
    }
}

function Get-SageOffer{
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer_id
    )
    $json = @{
        offer_id = $offer_id
    }
    $offer = Invoke-SageRPC -endpoint get_offer -json $json
    $offer.offer
}

function Revoke-SageOffer{
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer_id,
        [UInt64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        offer_id = $offer_id
        fee = $fee
        auto_submit = $auto_submit
    }

    Confirm-SageOffer -offer_id $offer_id -status "active"

    Invoke-SageRPC -endpoint cancel_offer -json $json
}

function Confirm-SageOffer{
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer_id,
        [ValidateSet("active","cancelled","expired","completed")]
        $status
    )

    switch ($status) {
        "active" {
            $offers = Get-SageOffers -status "active"
        }
        "cancelled" {
            $offers = Get-SageOffers -status "cancelled"
        }
        "expired" {
            $offers = Get-SageOffers -status "expired"
        }
        "completed" {
            $offers = Get-SageOffers -status "completed"
        }
        default {
            $offers = Get-SageOffers
        }
    }
    


    if($null -eq ($offers | Where-Object {$_.offer_id -eq $offer_id})){
        throw "The Offer ID does not exist."
    }
}

function Remove-SageOffer{
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer_id
    )
    $json = @{
        offer_id = $offer_id
    }

    Confirm-SageOffer -offer_id $offer_id 
    Invoke-SageRPC -endpoint delete_offer -json $json
}


function Get-SagePeers{
    $peers = Invoke-SageRPC -endpoint get_peers -json @{}
    $peers.peers
}

function Remove-SagePeer {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ip,
        [bool]$ban
    )

    if($null -eq $ban.IsPresent){
        $ban = $false
    }

    $json = @{
        ip = $ip
        ban = $ban
    }

    Invoke-SageRPC -endpoint remove_peer -json $json
}

function Add-SagePeer {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ip
    )

    $json = @{
        ip = $ip
    }

    Invoke-SageRPC -endpoint add_peer -json $json
}

function Set-SageTargetPeers {
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$target_peers
    )

    $json = @{
        target_peers = $target_peers
    }

    Invoke-SageRPC -endpoint set_target_peers -json $json
}


function Set-SageDiscoverPeers {
    param(
        [bool]$discover_peers
    )

    if($null -eq $discover_peers.IsPresent){
        $discover_peers = $true
    }

    $json = @{
        discover_peers = $discover_peers
    }

    Invoke-SageRPC -endpoint set_discover_peers -json $json
}

function Get-SageNetworks {
    $networks = Invoke-SageRPC -endpoint get_networks -json @{}
    $networks.networks
}

function Set-SageNetworkId {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("mainnet","testnet11")]
        [string]$network_id
    )

    $json = @{
        network_id = $network_id
    }

    Invoke-SageRPC -endpoint set_network_id -json $json
}

function Update-SageNft {
    param(
        [Parameter(Mandatory=$true)]
        [string]$nft_id,
        [bool]$visible
    )

    if($null -eq $visible.IsPresent){
        $visible = $true
    }

    $json = @{
        nft_id = $nft_id
        visible = $visible
    }

    Invoke-SageRPC -endpoint update_nft -json $json
}

function Add-SageNftUri{    
    param(
        [Parameter(Mandatory=$true)]
        [string]$nft_id,
        [Parameter(Mandatory=$true)]
        [string]$uri,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Data","Metadata","License")]
        [string]$kind,
        [UInt64]$fee,
        [bool]$auto_submit
    )

    if($null -eq $fee){
        $fee = 0
    }
    if($null -eq $auto_submit.IsPresent){
        $auto_submit = $true
    }

    $json = @{
        nft_id = $nft_id
        uri = $uri
        kind = $kind
        fee = $fee
        auto_submit = $auto_submit
    }

    Invoke-SageRPC -endpoint add_nft_uri -json $json
}

function Approve-SageCoinSpend {

}

<#

sign_coin_spends
view_coin_spends
submit_transaction


set_derive_automatically
set_derivation_batch_size

remove_cat
update_cat
increase_derivation_index

#>