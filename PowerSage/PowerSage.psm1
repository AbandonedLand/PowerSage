
function Get-SageCats{
    <#
    .SYNOPSIS
    Get a list of Chia Asset Tokens (CATs) known by the Sage wallet.

    .DESCRIPTION
    Get a list of all known Chia Asset Tokens.

    .EXAMPLE
    Get-SageCats

    asset_id    : a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913
    name        : Spacebucks
    ticker      : SBX
    balance     : 0
    description : The galactic monetary standard.
    icon_url    : https://icons.dexie.space/a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913.webp
    visible     : True

    asset_id    : 77b5178d32f66932dc9e48157f029b8a96bfed577ee877d2b22cd73d6799e424
    name        : TibetSwap LP wUSDC.b-XCH
    ticker      : TIBET-wUSDC.b-XCH
    balance     : 1
    description : 
    icon_url    : https://icons.dexie.space/77b5178d32f66932dc9e48157f029b8a96bfed577ee877d2b22cd73d6799e424.webp
    visible     : True
    
    .NOTES
    This function returns only Chia Asset Tokens that has once been in the wallet.

    .OUTPUTS
    [CatRecord] - An object containing the asset_id, name, ticker, balance, description, icon_url, and visible status of the CAT.
    

    #>
    

    $cats = Invoke-SageRPC -endpoint get_cats -json @{}
    $cat_array = @()
    $cats.cats | ForEach-Object {
        $cat = [CatRecord]::new($_)
        $cat_array += $cat
    }
    return $cat_array
}

# This is a return type for the Get-SageCats function.
Class CatRecord{
    [string]$asset_id
    [string]$name
    [string]$ticker
    [UInt64]$balance
    [string]$description
    [string]$icon_url
    [bool]$visible

    CatRecord(){
    }

    CatRecord([pscustomobject]$properties) {
        foreach ($key in $properties.PSObject.Properties.Name) {
            if ($this.PSObject.Properties.Match($key)) {
                $this.$key = $properties.$key
            }
        }
    }
}


function Invoke-SageRPC {
    <#

    .SYNOPSIS
    Invokes a Sage RPC command.

    .DESCRIPTION
    The Invoke-SageRPC function sends a JSON-RPC request to the Sage wallet daemon. The function requires the endpoint and the JSON data to be sent to the endpoint.

    .PARAMETER endpoint
    The Sage RPC endpoint to send the request to.

    .PARAMETER json
    The JSON data to be sent to the endpoint.

    .EXAMPLE
    Invoke-SageRPC -endpoint get_keys -json @{}

    This command sends a JSON-RPC request to the get_keys endpoint with no parameters.

    #>
    
    param(
        [Parameter(Mandatory=$true)]
        $endpoint,
        $json
    )
    $cert = Get-SagePfxCertificate

    $uri = "https://127.0.0.1:9257/$endpoint";
   
    $data = $json | ConvertTo-Json -Depth 30

    Invoke-RestMethod -Uri $uri -Method Post -body $data -ContentType 'Application/json' -Certificate $cert -SkipCertificateCheck
}

function Test-SageRPC{
    <#
    .SYNOPSIS
    Checks if the Sage wallet daemon is running.

    .DESCRIPTION
    The Check-SageRPC function checks if the Sage wallet daemon is running. If the daemon is not running, it will throw an error.

    .EXAMPLE
    Test-SageRPC

    This command throws an error if the Sage wallet daemon is not running.

    #>
    
    $result = Get-SageSyncStatus 
    if(-NOT $result){
        throw "Sage wallet daemon is not running."
    }
}

function New-SageMnemonic {
    <#
    .SYNOPSIS
    Generates a new mnemonic seed.

    .DESCRIPTION
    This command will generate a mnemonic seed with 12 words by default. If the -Use24Words switch is used, it will generate a mnemonic seed with 24 words.

    .EXAMPLE
    New-SageMnemonic

    This command generates a new mnemonic seed with 12 words.

    .EXAMPLE
    New-SageMnemonic -Use24Words

    This command generates a new mnemonic seed with 24 words.

    #>
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
    <#
    .SYNOPSIS
    Imports a key into the Sage wallet.

    .DESCRIPTION
    The key imported can be a mnemonic seed, private key or a public key.

    .PARAMETER key
    The key to be imported.

    .PARAMETER name
    The name shown for the wallet.

    .EXAMPLE
    Import-SageKeys -key "abandon taco cat ..." -name "TacoCat"

    This command imports a mnemonic seed into the wallet with the name "TacoCat".

    .EXAMPLE
    Import-SageKeys -key "<PUBLIC KEY>" -name "MyFriendsWallet"

    This command imports a public key into the wallet with the name "MyFriendsWallet".  Public keys can be used to create a watch-only wallet.


    #>

    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$key,
        [Parameter(Mandatory=$true)]
        [string]$name
    )
    process {
        $json = @{
            name = $name
            key = $key
        }
        Invoke-SageRPC -endpoint import_key -json $json
    }
}

function Get-SageKey {
    <#
    .SYNOPSIS
    Get the logged in key from the Sage wallet.

    .DESCRIPTION
    The Get-SageKey function retrieves a key from the Sage wallet using the key's fingerprint.

    .PARAMETER fingerprint
    The fingerprint of the key to be retrieved.

    .EXAMPLE
    Get-SageKey


    #>
    $json = @{
        
    }
    $key = Invoke-SageRPC -endpoint get_key -json $json
    $key.key
}


function Get-SageKeys {
    <#
    .SYNOPSIS
    Gets a list of keys from the Sage wallet.

    .DESCRIPTION
    Gets all the keys Sage wallet has.

    .EXAMPLE
    Get-SageKeys

    This command retrieves all the keys in the Sage wallet.

    #>

    $keys = Invoke-SageRPC -endpoint get_keys -json @{}
    $keys.keys
}

function Connect-SageFingerprint {
    <#
    .SYNOPSIS
    Switches between known keys using the key's fingerprint.

    .DESCRIPTION
    Makes a different wallet key active.

    .PARAMETER fingerprint
    The fingerprint of the key to be made active.

    .EXAMPLE
    Connect-SageFingerprint -fingerprint 12345678

    This command makes the key with the fingerprint 12345678 active.

    #>

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
    <#
    .SYNOPSIS
    Shows a list of addresses available for the current key.

    .DESCRIPTION
    Shows a list of available addresses for the current key.

    .EXAMPLE
    Get-SageDerivations -offset 0 -limit 10

    This command shows the first 10 (non-hardened) addresses available for the current key.

    .EXAMPLE
    Get-SageDerivations -hardened -offset 0 -limit 10

    This command shows the first 10 hardened addresses available for the current key.

    #>
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
    <#
    .SYNOPSIS
    Gets the current sync status of the Sage wallet as well as the XCH balance

    .DESCRIPTION
    Gets the current sync status of the Sage wallet as well as the XCH balance

    .EXAMPLE
    Get-SageSyncStatus

    balance         : 14766959169955
    unit            : @{ticker=XCH; decimals=12}
    synced_coins    : 7363
    total_coins     : 7363
    receive_address : xch14nqv3g90kfurfzmzxvkrze856wwxdy3448wgu4yuexp0rkhz250qhl5kp9
    burn_address    : xch1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqm6ks6e8mvy

    .NOTES
    
    #>

    Invoke-SageRPC -endpoint get_sync_status -json @{}
}


function Get-SageCatCoins{
    <#
    .SYNOPSIS
    Get a list of coins for a given Chia Asset Token asset_id.

    .DESCRIPTION
    Returns a list of coins for a given Chia Asset Token asset_id. The coins can be filtered by status (spent or unspent).

    .PARAMETER asset_id
    The asset_id of the Chia Asset Token.

    .PARAMETER status
    The status of the coins. The options are "any", "spent", or "unspent".

    .EXAMPLE
    Get-SageCatCoins -asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913" -status "unspent"

    This command returns a list of unspent coins for the Chia Asset Token with the asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913".

    .EXAMPLE
    Get-SageCatCoins -asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913" -status "spent"

    This command returns a list of spent coins for the Chia Asset Token with the asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913".

    .EXAMPLE
    Get-SageCatCoins -asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913"

    This command returns a list of all coins for the Chia Asset Token with the asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913".

    #>
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
    <#
    .SYNOPSIS
    Get a Chia Asset Token (CAT) by asset_id.

    .DESCRIPTION
    Get a Chia Asset Token by asset_id.

    .PARAMETER asset_id
    The asset_id of the Chia Asset Token.

    .EXAMPLE
    Get-SageCat -asset_id "a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913"

    
    asset_id    : a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913
    name        : Spacebucks
    ticker      : SBX
    description : The galactic monetary standard.
    icon_url    : https://icons.dexie.space/a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913.webp
    visible     : True
    balance     : 0


    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$asset_id
    )
    $json = @{
        asset_id = $asset_id
    }
    $cat = Invoke-SageRPC -endpoint get_cat -json $json
    $catrecord = [CatRecord]::new($cat.cat)
    return $catrecord
}

function Remove-SageCat{
    <#
    .SYNOPSIS
    IT IS NOT RECOMMENDED TO USE THIS FUNCTION.  THERE IS NO ADD-SAGECAT FUNCTION.
    Removes a Chia Asset Token (CAT) by asset_id from the wallet.

    .DESCRIPTION
    Removes a Chia Asset Token by asset_id from the wallet.  This will make the wallet stop displaying the CAT.

    .PARAMETER asset_id
    The asset_id of the Chia Asset Token.


    #>
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
    <#
    .SYNOPSIS
    Sets the derivation index for the current key.

    .DESCRIPTION
    Sets the derivation index for the current key.  This is useful when you want to generate a new address for the current key.
    This is also used to help find missing coins from imported wallets.

    .PARAMETER hardened
    This this switch is used if you want to increated the hardened derivation index.
    Leaving the switch out will increase the non-hardened derivation index.
    
    .PARAMETER index
    Set the Index height to a specific number.

    .EXAMPLE
    Set-SageDerivationIndex -index 10000

    This command sets the derivation index to 10000.

    .EXAMPLE

    Set-SageDerivationIndex -hardened -index 10000

    This command sets the hardened derivation index to 10000.

    .NOTES
    It is recommended to do both the hardened and unhardened derivation index to find missing coins.
    You will need to run the Sync-SageFingerprint command after setting the derivation.
    
    #>
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
    <#

    .SYNOPSIS
    Resyncs the known coins for the current key.

    .DESCRIPTION
    Resyncs the known coins for the current key.  This is useful when you have set the derivation index to find missing coins.

    .EXAMPLE
    Sync-SageFingerprint -fingerprint 12345678

    This command resyncs the known coins for the key with the fingerprint 12345678.

    .NOTES
    This command is useful when you have set the derivation index to find missing coins.

    #>
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
    <#
    .SYNOPSIS
    Removes a key from the Sage wallet.

    .DESCRIPTION
    Removes a key from the Sage wallet.  This will remove the key from the wallet and all the coins associated with the key.

    .PARAMETER fingerprint
    The fingerprint of the key to be removed.

    .EXAMPLE
    Remove-SageKey -fingerprint 12345678

    This command removes the key with the fingerprint 12345678.

    .NOTES
    ONLY USE THIS COMMAND IF YOU HAVE BACKED UP THE KEY AND YOU ARE SURE YOU WANT TO REMOVE IT.

    #>
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
    <#

    .SYNOPSIS
    Renames a key in the Sage wallet.

    .DESCRIPTION
    Renames a key in the Sage wallet.

    .PARAMETER fingerprint
    The fingerprint of the key to be renamed.

    .PARAMETER name
    The new name for the key.

    .EXAMPLE
    Rename-SageKey -fingerprint 12345678 -name "MyNFTProject Wallet"

    This command renames the key with the fingerprint 12345678 to "MyNFTProject Wallet".

    #>
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
    <#
    .SYNOPSIS
    Gets the secret key for a key in the Sage wallet.

    .DESCRIPTION
    Displays the secret key for a key in the Sage wallet for a given fingerprint.

    .PARAMETER fingerprint
    The fingerprint of the key to get the secret key for.

    .EXAMPLE
    Get-SageSecretKey -fingerprint 12345678

    This command gets the secret key for the key with the fingerprint 12345678.

    
    #>
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
    <#
    .SYNOPSIS
    Get a list of coins for the Chia (XCH) asset.

    .DESCRIPTION
    Returns a list of coins for the Chia (XCH) asset. The coins can be filtered by status (spent or unspent).

    .PARAMETER status
    The status of the coins. The options are "any", "spent", or "unspent".

    .EXAMPLE
    Get-SageXchCoins -status "unspent"

    This command returns a list of unspent coins for the Chia (XCH) asset.

    .EXAMPLE
    Get-SageXchCoins -status "spent"

    This command returns a list of spent coins for the Chia (XCH) asset.

    .EXAMPLE
    Get-SageXchCoins

    This command returns a list of all coins for the Chia (XCH) asset.

    #>
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$offset,
        [Parameter(Mandatory=$true)]
        [UInt32]$limit,
        [ValidateSet("coin_id","amount","created_height","spent_height")]
        [string]$sort_mode,
        [switch]$ascending,
        [switch]$include_spent_coins
    )

    if(-not $sort_mode){
        $sort_mode = "CoinId"
    }

    $json = @{
        offset = $offset
        limit = $limit
        sort_mode = $sort_mode
        ascending = ($ascending.IsPresent)
        include_spent_coins = ($include_spent_coins.IsPresent)
    } 

    $coins = Invoke-SageRPC -endpoint get_xch_coins -json $json
    
    $coins.coins
    
}

function Get-SageDids {
    <#
    .SYNOPSIS  
    Get a list of Decentralized Identities (DIDs) known by the Sage wallet.

    .DESCRIPTION
    Get a list of all known Decentralized Identities.

    .EXAMPLE
    Get-SageDids

    launcher_id           : did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw
    name                  : PowerSage
    visible               : True
    coin_id               : 54d9c5791a40f390dd10baaacb82d06d11c2f9bcdd73f7b0fbb3cde1303223b4
    address               : xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a
    amount                : 1
    created_height        : 6506509
    create_transaction_id : 

    .NOTES
    

    #>
    $dids = Invoke-SageRPC -endpoint get_dids -json @{}
    $dids.dids
}

function Get-SagePendingTransactions {

    <#
    .SYNOPSIS
    Get a list of pending transactions.

    .DESCRIPTION
    Get a list of pending transactions.

    .EXAMPLE
    Get-SagePendingTransactions

    This command returns a list of pending transactions.

    .NOTES
    This command may take a few minutes to fully sync after a transaction is submitted or completed.

    #>

    $transactions = Invoke-SageRPC -endpoint get_pending_transactions -json @{}
    $transactions.transactions
}

function Get-SageTransactions {
    <#
    .SYNOPSIS
    Get a list of transactions.

    .DESCRIPTION
    Get a list of transactions.

    .EXAMPLE
    Get-SageTransactions -offset 0 -limit 10

    This command gets the 10 most recent transactions.

    .EXAMPLE
    Get-SageTransactions -offset 0 -limit 10 -ascending

    This command gets the 10 oldest transactions in the wallet.

    .EXAMPLE
    Get-SageTransactions -offset 10 -limit 10

    This command gets the next 10 transactions after the first 10.

    #>
    param(
        [Parameter(Mandatory=$true)]
        [uint32]$offset,
        [Parameter(Mandatory=$true)]
        [uint32]$limit,
        [switch]$ascending
    )
    $json = @{
        offset = $offset
        limit = $limit
        ascending = ($ascending.IsPresent)
    }
    $transactions = Invoke-SageRPC -endpoint get_transactions -json $json
    $transactions.transactions
}

function Get-SageTransaction {
    <#
    
    .SYNOPSIS
    Get a transaction by height.

    .DESCRIPTION
    Get a transaction by height.

    .PARAMETER height
    The Block height of the transaction.

    .EXAMPLE
    Get-SageTransaction -height 6520099

    This command gets the transaction at block height 6520099.
    
    #>
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$height
    )
    $json = @{
        height = $height
    }
    $transaction = Invoke-SageRPC -endpoint get_transaction -json $json
    $transaction.transaction
}

function Get-SageNftCollections {
    <#

    .SYNOPSIS
    Get a list of NFT collections.

    .DESCRIPTION
    Get a list of NFT collections.

    .EXAMPLE
    Get-SageNftCollections -offset 0 -limit 10

    This command gets the first 10 NFT collections.

    .EXAMPLE
    Get-SageNftCollections -offset 10 -limit 10

    This command gets the next 10 NFT collections after the first 10.

    #>
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
    <#

    .SYNOPSIS
    Get an NFT collection by collection_id.

    .DESCRIPTION
    Get an NFT collection by collection_id.

    .PARAMETER collection_id
    The collection_id of the NFT collection.

    .EXAMPLE
    Get-SageNftCollection -collection_id "col1ehl8ppkrt62emyljs5v87shmj05xtzvm6zs35kzxtc58kvwt7nlsf2r4a3"

    This command gets the NFT collection with the collection_id "col1ehl8ppkrt62emyljs5v87shmj05xtzvm6zs35kzxtc58kvwt7nlsf2r4a3".

    #>

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
    <#

    .SYNOPSIS
    Get a list of NFTs.

    .DESCRIPTION
    Get a list of NFTs in the wallet.

    .EXAMPLE
    Get-SageNfts -offset 0 -limit 10

    This command gets the first 10 NFTs.

    .EXAMPLE
    Get-SageNfts -offset 10 -limit 10

    This command gets the next 10 NFTs after the first 10.

    #>

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
    <#
    .SYNOPSIS
    Get an NFT by nft_id.

    .DESCRIPTION
    Show the data for an owned NFT.

    .PARAMETER nft_id
    The nft_id of the NFT.

    .EXAMPLE
    Get-SageNft -nft_id "nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx"

    This command gets the NFT with the nft_id nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx

    
    #>
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
    <#
    .SYNOPSIS
    Get detailed data about the NFT.

    .DESCRIPTION
    Get detailed data about the NFT.

    .PARAMETER nft_id
    The nft_id of the NFT.

    .EXAMPLE
    Get-SageNftData -nft_id nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx

    This command gets detailed data about the NFT with the nft_id nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx

    #>
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
    <#
    .SYNOPSIS
    Sends Chia (XCH) to an address.

    .DESCRIPTION
    Sends Chia (XCH) to an address.

    .PARAMETER amount
    The amount of XCH to send.

    .PARAMETER address
    The address to send the XCH to.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER memos
    A list of memos to attach to the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Send-SageXch -amount 1000000000000 -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a"

    This command sends 1 XCH to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a".

    .EXAMPLE
    Send-SageXch -amount 1000000000000 -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" -fee 1000000000

    This command sends 1 XCH to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" with a fee of 0.001 XCH.

    .EXAMPLE
    Send-SageXch -amount 1000000000000 -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" -fee 1000000000 -memos "This is a test transaction."

    This command sends 1 XCH to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" with a fee of 0.001 XCH and a memo "This is a test transaction."

    .EXAMPLE
    Send-SageXch -amount 1000000000000 -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" -fee 1000000000 -memos "This is a test transaction." -auto_submit $false

    This creates a spend bundle but does not submit it to the network.

    #>

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
    <#
    .SYNOPSIS
    Combines a list of coins into a single coin.

    .DESCRIPTION
    Combines a list of coins into a single coin.

    .PARAMETER coin_ids
    A list of coin_ids to combine. The coins must be unspent. 

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Join-SageXchCoins -coin_ids @("coin1" "coin2" "coin3")

    This command combines the coins with the coin_ids "coin1", "coin2", and "coin3".

    .EXAMPLE
    Join-SageXchCoins -coin_ids @("coin1" "coin2" "coin3") -fee 1000000000

    This command combines the coins with the coin_ids "coin1", "coin2", and "coin3" with a fee of 0.001 XCH.

    #>
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
    <#
    .SYNOPSIS
    Splits a coin into multiple coins.

    .DESCRIPTION
    This command will split a coin equally into multiple coins.

    .PARAMETER coin_id
    The coin_id of the coin to split.

    .EXAMPLE
    Split-SageXchCoin -coin_id "coin1" -output_count 2

    This command splits the coin with the coin_id "coin1" into 2 equal sized coins.

    .EXAMPLE
    Split-SageXchCoin -coin_id "coin1" -output_count 8 -fee 1000000000

    This command splits the coin with the coin_id "coin1" into 8 equal sized coins with a fee of 0.001 XCH.

    #>
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
    <#
    .SYNOPSIS
    Combines a list of Chia Asset Token (CAT) coins into a single coin.

    .DESCRIPTION
    Combines a list of Chia Asset Token (CAT) coins into a single coin.

    .PARAMETER coin_ids
    A list of coin_ids to combine. The coins must be unspent.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Join-SageCatCoins -coin_ids @("coin1" "coin2" "coin3")

    This command combines the coins with the coin_ids "coin1", "coin2", and "coin3".

    .EXAMPLE
    Join-SageCatCoins -coin_ids @("coin1" "coin2" "coin3") -fee 1000000000

    This command combines the coins with the coin_ids "coin1", "coin2", and "coin3" with a fee of 0.001 CAT.

    #>
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
    <#
    .SYNOPSIS
    Splits a Chia Asset Token (CAT) coin into multiple coins.

    .DESCRIPTION
    This command will split a Chia Asset Token (CAT) coin equally into multiple coins.

    .PARAMETER coin_id
    The coin_id of the coin to split.

    .EXAMPLE
    Split-SageCatCoins -coin_id "coin1" -output_count 2

    This command splits the coin with the coin_id "coin1" into 2 equal sized coins.

    .EXAMPLE
    Split-SageCatCoins -coin_id "coin1" -output_count 8 -fee 1000000000

    This command splits the coin with the coin_id "coin1" into 8 equal sized coins with a fee of 0.001 CAT.

    #>
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
    <#
    .SYNOPSIS
    Create a new Chia Asset Token (CAT) and deploy it to the blockchain.

    .DESCRIPTION
    Create a new Chia Asset Token (CAT) and deploy it to the blockchain.

    .PARAMETER name
    The name of the Chia Asset Token. This just names it in your wallet.  You will need to use SpaceScan or Dexie.space to register the name for public use.

    .PARAMETER ticker
    The ticker symbol for the Chia Asset Token.

    .PARAMETER amount
    The amount of the Chia Asset Token to create.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Deploy-SageCat -name "Spaceducks" -ticker "SDX" -amount 1000000000

    This command creates a new Chia Asset Token named "Spaceducks" with the ticker "SDX" and an amount of 1,000,000,000.

    #>


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
    <#
    .SYNOPSIS
    Sends a Chia Asset Token (CAT) to an address.

    .DESCRIPTION
    Sends a Chia Asset Token (CAT) to an address.

    .PARAMETER amount
    The amount of the Chia Asset Token to send.

    .PARAMETER address
    The address to send the Chia Asset Token to.

    .PARAMETER asset_id
    The asset_id of the Chia Asset Token.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER memos
    A list of memos to attach to the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Send-SageCat -amount 1000 -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" -asset_id "asset1"

    This command sends 1 Chia Asset Token to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" with the asset_id "asset1".

    .NOTES
    Chia Asset Tokens (CATs) are are represented by 1000 mojos = 1 CAT.  
    #>

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
    <#
    .SYNOPSIS
    Create a new Decentralized Identity (DID).

    .DESCRIPTION
    Create a new Decentralized Identity (DID).

    .PARAMETER name
    Name for DID

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    New-SageDid -name "PowerSage"

    This command creates a new Decentralized Identity (DID) named "PowerSage".

    .EXAMPLE
    New-SageDid -name "PowerSage" -fee 1000000000

    This command creates a new Decentralized Identity (DID) named "PowerSage" with a fee of 0.001 XCH.

    .EXAMPLE
    New-SageDid -name "PowerSage" -fee 1000000000 -auto_submit $false

    This creates a DID SpendBundle but does not submit it to the network.
    #>
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
    <#
    .SYNOPSIS
    Update a Decentralized Identity (DID).

    .DESCRIPTION
    Change the name of a DID or set it to hidden.

    .PARAMETER did_id
    The did_id of the DID to update.

    .PARAMETER name
    The new name for the DID.

    .PARAMETER visible
    Set the DID to be visible or hidden. Default is visible.

    .EXAMPLE
    Update-SageDid -did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw" -name "PowerSage" 

    This command updates the DID with the did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw" to the name "PowerSage".

    .EXAMPLE
    Update-SageDid -did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw" -visible $false

    This command hides the DID with the did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw".

    #>
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
    <#
    .SYNOPSIS
    Transfer a Decentralized Identity (DID) to another address.

    .DESCRIPTION
    Transfer a Decentralized Identity (DID) to another address.

    .PARAMETER did_ids
    A list of did_ids to transfer.

    .PARAMETER address
    The address to transfer the DID to.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Send-SageDid -did_ids @("did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw") -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a"

    This command transfers the DID with the did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw" to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a".

    #>

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
    <#
    .SYNOPSIS   
    Transfer a list of NFTs to another address.

    .DESCRIPTION
    Transfer a list of NFTs to another address.

    .PARAMETER nft_ids
    A list of nft_ids to transfer.

    .PARAMETER address
    The address to transfer the NFTs to.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Send-SageNfts -nft_ids @("nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx") -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a"

    This command transfers the NFT with the nft_id "nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx" to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a".

    .EXAMPLE    
    Send-SageNfts -nft_ids @("nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx","nft1tmz9ezs8w7kjlfw3akn5gu3mcece72mspad4xmfmcf43m7e33sksp8686a") -address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" -fee 1000000000

    This command transfers the NFTs with the nft_ids "nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx" and "nft1tmz9ezs8w7kjlfw3akn5gu3mcece72mspad4xmfmcf43m7e33sksp8686a" to the address "xch1t9jujtflz6lxxtlff5ed69kdt3tzaa02xv5yl92s8cz2x69ranus6uat4a" with a fee of 0.001 XCH.


    #>
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
    <#
    .SYNOPSIS
    Assign a list of NFTs to a Decentralized Identity (DID).

    .DESCRIPTION
    Assign a list of NFTs to a Decentralized Identity (DID).

    .PARAMETER nft_ids
    A list of nft_ids to assign.

    .PARAMETER did_id
    The did_id of the DID to assign the NFTs to.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Move-SageNftsToDid -nft_ids @("nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx") -did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw"

    This command assigns the NFT with the nft_id "nft14sz0y7wfgculn7sf6wty0uw5vnt4m46dpyp7qeynmx5mn8s58tss0a2egx" to the DID with the did_id "did:chia:1238tz2ke73f22k30ety0eaumr2qry2l9rcffsshg9mgw2m8zw4ssx4carw".
    #>
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

function Build-SageOffer{
    <#
    .SYNOPSIS
    Create a new offer to trade assets.

    .DESCRIPTION
    Build an offer for trading on the chia blockchain.

    .EXAMPLE
    Create an offer to trade 2 wUSDC.b for 0.1 XCH


    $offer = Build-SageOffer
    $offer = [SageOffer]::new()
    $offer.requestXch(100000000000)
    $offer.offerCat("fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d", 20000)
    $offer.createoffer()
    $offer.showoffer()

    .EXAMPLE
    Create offer to trade an NFT with nft_id nft13yjdrww2rnpf6p3csdg3tuxzqhn26eu39akulxf3rtufurtguq5svrmama for 0.1 XCH

    $offer = Build-SageOffer
    $offer.requestXch(100000000000)
    $offer.offerNft("nft13yjdrww2rnpf6p3csdg3tuxzqhn26eu39akulxf3rtufurtguq5svrmama")
    $offer.createoffer()
    $offer.showoffer()

    .EXAMPLE
    Create an offer to trade 100 SBX for 20 DBX.

    $offer = Build-SageOffer
    $offer.offerCat("a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913",100000)
    $offer.requestCat("db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20",20000)
    $offer.createoffer()
    $offer.showoffer()

    .EXAMPLE
    Create an offer that will expire in 5 minutes.
    The trade will offer 1 XCH and 10 DBX
    The trade will request NFT nft19z7m9kp705md22nkm9urxl27jlfk64wy2ndeheecl2w64nfy2c5seg2k88

    $offer = Build-SageOffer
    $offer.setMinutesUntilExpires(5)
    $offer.offerXch(1000000000000)
    $offer.offerCat("db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20",10000)
    $offer.requestNft("nft19z7m9kp705md22nkm9urxl27jlfk64wy2ndeheecl2w64nfy2c5seg2k88")
    $offer.createoffer()
    $offer.showoffer()

    .NOTES
    Chia Asset Tokens (CATs) are are represented by 1000 mojos = 1 CAT.
    XCH is represented by 1000000000000 mojo = 1 XCH.
    NFTs are represented by their nft_id.


    #>

    $offer = [SageOffer]::new()
    return $offer
}

Class SageOffer{
    [SageAsset]$requested_assets
    [SageAsset]$offered_assets
    [UInt64]$fee
    [string]$receive_address
    [UInt64]$expires_at_second
    [pscustomobject]$offer_data
    $json
    [bool]$validate


    SageOffer(){
        $this.requested_assets = [SageAsset]::new()
        $this.offered_assets = [SageAsset]::new()
        $this.validate = $false
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

    [void] requestXch([UInt64]$amount){
        $this.requested_assets.addXch($amount)
    }

    [void] offerXch([UInt64]$amount){
        $this.offered_assets.addXch($amount)
    }

    [void] requestCat([string]$asset_id, [UInt64]$amount){
        $this.requested_assets.addCat($asset_id, $amount)
    }

    [void] requestNft([string]$nft_id){
        $this.requested_assets.addNft($nft_id)
    }

    [void] offerCat([string]$asset_id, [UInt64]$amount){
        $this.offered_assets.addCat($asset_id, $amount)
    }

    [void] offerNft([string]$nft_id){
        $this.offered_assets.addNft($nft_id)
    }

    [void] toJson(){
        $this.json = @{
            requested_assets = $this.requested_assets.toJson() | ConvertFrom-Json
            offered_assets = $this.offered_assets.toJson() | ConvertFrom-Json
            fee = $this.fee
            auto_import = $false
        }

        if ($this.receive_address.Length -eq 62 -and $this.receive_address.StartsWith("xch")) {
            $this.json.receive_address = $this.receive_address
        }
        
        if($this.expires_at_second -gt 0){
            $this.json.expires_at_second = $this.expires_at_second
        }

    }

    [void] validateOnly(){
        $this.validate = $true
    }
    
    [pscustomobject]showoffer(){
        return $this.offer_data
    }

    createoffer() {
        $this.toJson()
        $this.offer_data = Invoke-SageRPC -endpoint make_offer -json ($this.json)
        if(-not ($this.validate)){
            $this.import()
        }
        
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
    <#
    .SYNOPSIS
    Examine an offer string for chia.

    .DESCRIPTION
    Examine an offer string for chia.

    .PARAMETER offer
    The offer string to examine.

    .EXAMPLE
    $offer = "offer1qqr83wcuu2ryhmvm0929x4c7clpmq89t9q5t99g3csag94qjpzspgfpq2pmp5ds32xgp3qcfj2zf5ppsdsske94agkg5y2v0kz3jequqq7kqzyghgszgndzsq26pu92p2znzg5jqh3ee92rr0da05vh8w3nr4a4a87f8xmn7lx7lhmhmhhana07lh403gz49jn284u4aam0x0gues07aayu3tnhdld4kjgl23367ad7rgkaccgu6p4klxyl8h5yr8dhtx345hxka0lgzc092y68sv85ujw6lfe8re4l8f739p2p4uhtqc9pjuzedqyvqpshn2rtrudmqux293ezfh3g9nls48anklwx3vn269c2a0and7h0suq8yjw7wtk8mjdxh47dcwq4am9kcu3mkyx9zsrkfplxtex5jx6je9cr5pzn5cnsjm30a2rdn5023anuv2898aqyxwvr2lmu6fuexwkedhv5wvfxuzk8x5xtfflwync8kcdtcqn6fgfmxfj37lg9lk95d4nqswldqh26sgc4fkk2y58t99ngw4shhh8vghnkekxpy3cdu79l4eejemhfquzafkzzz8healtwfnxxflw4xjskeek3n83hp7h3u52j09eyp62zj2wenkklx77zlg490u2n3ppkqrerm9s4vkclm35c0md5ga94pvm5xt2vwee80ltxh0k34fy0g90c2ktv3926y8efk0c5ususw92cp5l8pfyaxrdtejx73pjus5jlt0729hk283weh7kcq9kw7n7fsh6dehwfkhegh2kzm846kdk4xh2hxynlp3u79fcws2f5jqxuqh5s0j6x7757kcq8vqq6d5c7g9cyr52nc42g66y24xv7f30gj5wjw3r9n2d5zypttd86e9kqqnqqs3m4eq656s3mh9d29zvj6fdp4y6svzagjq40egsajh26vwfd7z7ntcssj7cdm9tem8fmuk3nhk5r4zhmpsh5nm0qy9qy7xhmzc85m3zfpcukzn7zj0ynayrvs0ynayrvs0ynayrvu0leylwgyemks9m08ejynj3zt84hzlkqmn98wyzusdt6ac46aastdmm53wcehr9y7vqeqq7xmaxaml9h9dvwmuqmd844su6mvwlzzlspr88tlxtgncvmgaw23c6f8t7lakyxqlckh3yunlme0kupkga8zsgmyqvqy6aqdly76dtg286h5wm6vky56tuml6zv39tjaj7ea4hn46wfetktmqq3dm0v4z5qwahl3ktz6aa747gclr0yyk668m2nel5rxdhdem0xe7syq5w5ucpjszkknd8h86xg0nvrpuxl248d6a0e8xpfjw95ftyvm8nrhk5tluy2gq3euqrqkrylcmtvry7vzg5lcjfm33rqgmq9s89ue3kwc8fn0shfhw5kvvg9ag4a5pq9dtchxqwv67l5k7zcwj23fef3jsfeq3j3p9zr6q8yzw2frvp89metff7unjnf0ursu2cwqfa6anjmfwfr3kf2dtkl02hmrhr70xahjx0w7y4yglwd9mj9u2cxjd945ueuzfurhe58ed7pfed9zvcrjpwp6kkx822h3ecqhsvak3jz6c6qqdl6d99evrqj48neyfuggqtqnpqf6xtgfn20ka2yzugfrnhc2zw04lkv5wwn9nav90whzjelgsykts6dvc5rdptfwpw859f27a05nngv76aptl0yp7ks94m4p7v0uvdx7kj7dqu6hfvntfp2r8v5a5qng7qf8wejdmpk3akwcjqmk0g0s69edag44df85r6ld3s44z2emmflfqcwv8ydj9f9cp8nkk9lw7gn5l2tfeknsamqg6gex8mws6tm5e8wja9yruk8fk6u85405vy5kum5ggpcp8s2dqsm3rhzywpfa9phqum4uz3ts7d8mxuhmqehtuppv0r5gz3c4fy7sldkyyc93dswp3s2gkl4l9gjxwdshfqmg3l8x5xck9ge5nn2wywa0jdk3887d6nep0udmgjz6wk4xrgwmg852zt99ak0axgppzxfxytpefhnegjr0jle8cw2vvd552z9lrmgch0el67808d9ymqkrectmh76rwgpveqe544rqnru6vd97p9mq5znh8npd4e0zr8dpea5fsu6a2hc4vkp6adnyvl0enh9gljlm9mdaflx2av93zll7vupqqytlh677ynef9dpfuf0myfchae2c8vfaav38lvhagdz9ahdy4qnel48jdwpqlx72u470q5fhfcjgp3rqfhg235ny0pxj34plz4xz39greyu2xundq2yjx66r03gmuv07vyhp3pcnkc0wgpmhzulhwus5gwz6zrm7z8fgeesl30dplvv0kt2cfe0plmfuutnugp5qqnkuv4twrsm40746c9fy3nmq8q8u7y3w497ya96hxsdfn5hp9x6f7p5qgwglrh9pmeuy0zla56qmadzgtal3w5m0vapwpu2gpwx2t9cns4spvcr2rgvtd9lf38r38ugkrq8mdkp0pxavyuc5hywd9h2v24hvmhpcj3v29du9lw74layham4gj7nayamu04spcqyk0q5w2unjw8p8ugv7gjpzs9r2r59gw33a4udraqywdctsxtss3rvzyafazt8zwydd44xcqsw5u0y2punaprss35vazr83e859fv2q388pqluxjvs2a8y2h9u35lcpnu8pac9zf07dysk7x0k6c84swkw64wh2mjhlp3dtm0ej9h0avvp7a02zfld7hdut04v2xdm0kkmad909amht0t4fyg8haxl39dejrghxl4vusgm2tezv6z7nrazvm7c820e54ea74dn6wne56j38flqvy6sphl0kxa5edgnynh5vtu6a8e6xe5acs9jfa76h2m6ckhqj28zj92kc877z4a4ln5eurmmdjwvgn4cutattaypdsmlav9jr76d47qzqalr6vdluvs6pffmz6gl39ehnxhdg3c35kv3hsht8m685t00upv83yezc9qtglvqv40ykcakpw4w4vzl8ug728v6axahm8wfw8xc7fg0z50854m69dkhjdjkhalancd62gscaaqed9e0t2ueevpweejjzh4gdr4ggjkcmug389u7xjfemq7s27adu5zn8n3ty4jm2h79vl9va48xnky0ykk7rlvd5hvmsf8lsggc4nppqe63s9u"

    Read-SageOffer -offer $offer

    fee maker                 taker
    --- -----                 -----
    0 @{xch=; cats=; nfts=} @{xch=; cats=; nfts=}

    JSON OUTPUT
    {
    "fee": 0,
    "maker": {
        "xch": {
        "amount": 1000000000000,
        "royalty": 50000000000
        },
        "cats": {
        "db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20": {
            "amount": 10000,
            "royalty": 500,
            "name": "dexie bucks",
            "ticker": "DBX",
            "icon_url": "https://icons.dexie.space/db1a9020d48d9d4ad22631b66ab4b9ebd3637ef7758ad38881348c5d24c38f20.webp"
        }
        },
        "nfts": {}
    },
    "taker": {
        "xch": {
        "amount": 0,
        "royalty": 0
        },
        "cats": {},
        "nfts": {
        "nft19z7m9kp705md22nkm9urxl27jlfk64wy2ndeheecl2w64nfy2c5seg2k88": {
            "image_data": null,
            "image_mime_type": null,
            "name": null,
            "royalty_ten_thousandths": 500,
            "royalty_address": "xch122zzy6etu7epl9j0dsapadtussyhka84tz8xp9kpsjrdjyudfpds204n2p"
                }
            }
        }
    }
    #>
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
    <#

    .SYNOPSIS
    Take an offer on the chia blockchain.

    .DESCRIPTION
    Take an offer on the chia blockchain.

    .PARAMETER offer
    The offer string to take.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Take an offer
    $offer = "offer1qqr83wcuu2ryhmvm0929x4c7clpmq89t9q5t99g3csag94qjpzspgfpq2pmp5ds32xgp3qcfj2zf5ppsdsske94agkg5y2v0kz3jequqq7kqzyghgszgndzsq26pu92p2znzg5jqh3ee92rr0da05vh8w3nr4a4a87f8xmn7lx7lhmhmhhana07lh403gz49jn284u4aam0x0gues07aayu3tnhdld4kjgl23367ad7rgkaccgu6p4klxyl8h5yr8dhtx345hxka0lgzc092y68sv85ujw6lfe8re4l8f739p2p4uhtqc9pjuzedqyvqpshn2rtrudmqux293ezfh3g9nls48anklwx3vn269c2a0and7h0suq8yjw7wtk8mjdxh47dcwq4am9kcu3mkyx9zsrkfplxtex5jx6je9cr5pzn5cnsjm30a2rdn5023anuv2898aqyxwvr2lmu6fuexwkedhv5wvfxuzk8x5xtfflwync8kcdtcqn6fgfmxfj37lg9lk95d4nqswldqh26sgc4fkk2y58t99ngw4shhh8vghnkekxpy3cdu79l4eejemhfquzafkzzz8healtwfnxxflw4xjskeek3n83hp7h3u52j09eyp62zj2wenkklx77zlg490u2n3ppkqrerm9s4vkclm35c0md5ga94pvm5xt2vwee80ltxh0k34fy0g90c2ktv3926y8efk0c5ususw92cp5l8pfyaxrdtejx73pjus5jlt0729hk283weh7kcq9kw7n7fsh6dehwfkhegh2kzm846kdk4xh2hxynlp3u79fcws2f5jqxuqh5s0j6x7757kcq8vqq6d5c7g9cyr52nc42g66y24xv7f30gj5wjw3r9n2d5zypttd86e9kqqnqqs3m4eq656s3mh9d29zvj6fdp4y6svzagjq40egsajh26vwfd7z7ntcssj7cdm9tem8fmuk3nhk5r4zhmpsh5nm0qy9qy7xhmzc85m3zfpcukzn7zj0ynayrvs0ynayrvs0ynayrvu0leylwgyemks9m08ejynj3zt84hzlkqmn98wyzusdt6ac46aastdmm53wcehr9y7vqeqq7xmaxaml9h9dvwmuqmd844su6mvwlzzlspr88tlxtgncvmgaw23c6f8t7lakyxqlckh3yunlme0kupkga8zsgmyqvqy6aqdly76dtg286h5wm6vky56tuml6zv39tjaj7ea4hn46wfetktmqq3dm0v4z5qwahl3ktz6aa747gclr0yyk668m2nel5rxdhdem0xe7syq5w5ucpjszkknd8h86xg0nvrpuxl248d6a0e8xpfjw95ftyvm8nrhk5tluy2gq3euqrqkrylcmtvry7vzg5lcjfm33rqgmq9s89ue3kwc8fn0shfhw5kvvg9ag4a5pq9dtchxqwv67l5k7zcwj23fef3jsfeq3j3p9zr6q8yzw2frvp89metff7unjnf0ursu2cwqfa6anjmfwfr3kf2dtkl02hmrhr70xahjx0w7y4yglwd9mj9u2cxjd945ueuzfurhe58ed7pfed9zvcrjpwp6kkx822h3ecqhsvak3jz6c6qqdl6d99evrqj48neyfuggqtqnpqf6xtgfn20ka2yzugfrnhc2zw04lkv5wwn9nav90whzjelgsykts6dvc5rdptfwpw859f27a05nngv76aptl0yp7ks94m4p7v0uvdx7kj7dqu6hfvntfp2r8v5a5qng7qf8wejdmpk3akwcjqmk0g0s69edag44df85r6ld3s44z2emmflfqcwv8ydj9f9cp8nkk9lw7gn5l2tfeknsamqg6gex8mws6tm5e8wja9yruk8fk6u85405vy5kum5ggpcp8s2dqsm3rhzywpfa9phqum4uz3ts7d8mxuhmqehtuppv0r5gz3c4fy7sldkyyc93dswp3s2gkl4l9gjxwdshfqmg3l8x5xck9ge5nn2wywa0jdk3887d6nep0udmgjz6wk4xrgwmg852zt99ak0axgppzxfxytpefhnegjr0jle8cw2vvd552z9lrmgch0el67808d9ymqkrectmh76rwgpveqe544rqnru6vd97p9mq5znh8npd4e0zr8dpea5fsu6a2hc4vkp6adnyvl0enh9gljlm9mdaflx2av93zll7vupqqytlh677ynef9dpfuf0myfchae2c8vfaav38lvhagdz9ahdy4qnel48jdwpqlx72u470q5fhfcjgp3rqfhg235ny0pxj34plz4xz39greyu2xundq2yjx66r03gmuv07vyhp3pcnkc0wgpmhzulhwus5gwz6zrm7z8fgeesl30dplvv0kt2cfe0plmfuutnugp5qqnkuv4twrsm40746c9fy3nmq8q8u7y3w497ya96hxsdfn5hp9x6f7p5qgwglrh9pmeuy0zla56qmadzgtal3w5m0vapwpu2gpwx2t9cns4spvcr2rgvtd9lf38r38ugkrq8mdkp0pxavyuc5hywd9h2v24hvmhpcj3v29du9lw74layham4gj7nayamu04spcqyk0q5w2unjw8p8ugv7gjpzs9r2r59gw33a4udraqywdctsxtss3rvzyafazt8zwydd44xcqsw5u0y2punaprss35vazr83e859fv2q388pqluxjvs2a8y2h9u35lcpnu8pac9zf07dysk7x0k6c84swkw64wh2mjhlp3dtm0ej9h0avvp7a02zfld7hdut04v2xdm0kkmad909amht0t4fyg8haxl39dejrghxl4vusgm2tezv6z7nrazvm7c820e54ea74dn6wne56j38flqvy6sphl0kxa5edgnynh5vtu6a8e6xe5acs9jfa76h2m6ckhqj28zj92kc877z4a4ln5eurmmdjwvgn4cutattaypdsmlav9jr76d47qzqalr6vdluvs6pffmz6gl39ehnxhdg3c35kv3hsht8m685t00upv83yezc9qtglvqv40ykcakpw4w4vzl8ug728v6axahm8wfw8xc7fg0z50854m69dkhjdjkhalancd62gscaaqed9e0t2ueevpweejjzh4gdr4ggjkcmug389u7xjfemq7s27adu5zn8n3ty4jm2h79vl9va48xnky0ykk7rlvd5hvmsf8lsggc4nppqe63s9u"

    Complete-SageOffer -offer $offer

    #>

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
    <#
    .SYNOPSIS
    Submit a spendbundle to the chia blockchain.

    .DESCRIPTION
    Submit a spendbundle to the chia blockchain.

    .PARAMETER spendbundle
    The spendbundle to submit.

    
    #>
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
    <#
    .SYNOPSIS
    Track an offer on the chia blockchain. Usually your own.

    .DESCRIPTION
    Track an offer on the chia blockchain. Usually your own.

    .PARAMETER offer
    The offer string to track.

    .EXAMPLE
    $offer = "offer1qqr83wcuu2ryhmvm0929x4c7clpmq89t9q5t99g3csag94qjpzspgfpq2pmp5ds32xgp3qcfj2zf5ppsdsske94agkg5y2v0kz3jequqq7kqzyghgszgndzsq26pu92p2znzg5jqh3ee92rr0da05vh8w3nr4a4a87f8xmn7lx7lhmhmhhana07lh403gz49jn284u4aam0x0gues07aayu3tnhdld4kjgl23367ad7rgkaccgu6p4klxyl8h5yr8dhtx345hxka0lgzc092y68sv85ujw6lfe8re4l8f739p2p4uhtqc9pjuzedqyvqpshn2rtrudmqux293ezfh3g9nls48anklwx3vn269c2a0and7h0suq8yjw7wtk8mjdxh47dcwq4am9kcu3mkyx9zsrkfplxtex5jx6je9cr5pzn5cnsjm30a2rdn5023anuv2898aqyxwvr2lmu6fuexwkedhv5wvfxuzk8x5xtfflwync8kcdtcqn6fgfmxfj37lg9lk95d4nqswldqh26sgc4fkk2y58t99ngw4shhh8vghnkekxpy3cdu79l4eejemhfquzafkzzz8healtwfnxxflw4xjskeek3n83hp7h3u52j09eyp62zj2wenkklx77zlg490u2n3ppkqrerm9s4vkclm35c0md5ga94pvm5xt2vwee80ltxh0k34fy0g90c2ktv3926y8efk0c5ususw92cp5l8pfyaxrdtejx73pjus5jlt0729hk283weh7kcq9kw7n7fsh6dehwfkhegh2kzm846kdk4xh2hxynlp3u79fcws2f5jqxuqh5s0j6x7757kcq8vqq6d5c7g9cyr52nc42g66y24xv7f30gj5wjw3r9n2d5zypttd86e9kqqnqqs3m4eq656s3mh9d29zvj6fdp4y6svzagjq40egsajh26vwfd7z7ntcssj7cdm9tem8fmuk3nhk5r4zhmpsh5nm0qy9qy7xhmzc85m3zfpcukzn7zj0ynayrvs0ynayrvs0ynayrvu0leylwgyemks9m08ejynj3zt84hzlkqmn98wyzusdt6ac46aastdmm53wcehr9y7vqeqq7xmaxaml9h9dvwmuqmd844su6mvwlzzlspr88tlxtgncvmgaw23c6f8t7lakyxqlckh3yunlme0kupkga8zsgmyqvqy6aqdly76dtg286h5wm6vky56tuml6zv39tjaj7ea4hn46wfetktmqq3dm0v4z5qwahl3ktz6aa747gclr0yyk668m2nel5rxdhdem0xe7syq5w5ucpjszkknd8h86xg0nvrpuxl248d6a0e8xpfjw95ftyvm8nrhk5tluy2gq3euqrqkrylcmtvry7vzg5lcjfm33rqgmq9s89ue3kwc8fn0shfhw5kvvg9ag4a5pq9dtchxqwv67l5k7zcwj23fef3jsfeq3j3p9zr6q8yzw2frvp89metff7unjnf0ursu2cwqfa6anjmfwfr3kf2dtkl02hmrhr70xahjx0w7y4yglwd9mj9u2cxjd945ueuzfurhe58ed7pfed9zvcrjpwp6kkx822h3ecqhsvak3jz6c6qqdl6d99evrqj48neyfuggqtqnpqf6xtgfn20ka2yzugfrnhc2zw04lkv5wwn9nav90whzjelgsykts6dvc5rdptfwpw859f27a05nngv76aptl0yp7ks94m4p7v0uvdx7kj7dqu6hfvntfp2r8v5a5qng7qf8wejdmpk3akwcjqmk0g0s69edag44df85r6ld3s44z2emmflfqcwv8ydj9f9cp8nkk9lw7gn5l2tfeknsamqg6gex8mws6tm5e8wja9yruk8fk6u85405vy5kum5ggpcp8s2dqsm3rhzywpfa9phqum4uz3ts7d8mxuhmqehtuppv0r5gz3c4fy7sldkyyc93dswp3s2gkl4l9gjxwdshfqmg3l8x5xck9ge5nn2wywa0jdk3887d6nep0udmgjz6wk4xrgwmg852zt99ak0axgppzxfxytpefhnegjr0jle8cw2vvd552z9lrmgch0el67808d9ymqkrectmh76rwgpveqe544rqnru6vd97p9mq5znh8npd4e0zr8dpea5fsu6a2hc4vkp6adnyvl0enh9gljlm9mdaflx2av93zll7vupqqytlh677ynef9dpfuf0myfchae2c8vfaav38lvhagdz9ahdy4qnel48jdwpqlx72u470q5fhfcjgp3rqfhg235ny0pxj34plz4xz39greyu2xundq2yjx66r03gmuv07vyhp3pcnkc0wgpmhzulhwus5gwz6zrm7z8fgeesl30dplvv0kt2cfe0plmfuutnugp5qqnkuv4twrsm40746c9fy3nmq8q8u7y3w497ya96hxsdfn5hp9x6f7p5qgwglrh9pmeuy0zla56qmadzgtal3w5m0vapwpu2gpwx2t9cns4spvcr2rgvtd9lf38r38ugkrq8mdkp0pxavyuc5hywd9h2v24hvmhpcj3v29du9lw74layham4gj7nayamu04spcqyk0q5w2unjw8p8ugv7gjpzs9r2r59gw33a4udraqywdctsxtss3rvzyafazt8zwydd44xcqsw5u0y2punaprss35vazr83e859fv2q388pqluxjvs2a8y2h9u35lcpnu8pac9zf07dysk7x0k6c84swkw64wh2mjhlp3dtm0ej9h0avvp7a02zfld7hdut04v2xdm0kkmad909amht0t4fyg8haxl39dejrghxl4vusgm2tezv6z7nrazvm7c820e54ea74dn6wne56j38flqvy6sphl0kxa5edgnynh5vtu6a8e6xe5acs9jfa76h2m6ckhqj28zj92kc877z4a4ln5eurmmdjwvgn4cutattaypdsmlav9jr76d47qzqalr6vdluvs6pffmz6gl39ehnxhdg3c35kv3hsht8m685t00upv83yezc9qtglvqv40ykcakpw4w4vzl8ug728v6axahm8wfw8xc7fg0z50854m69dkhjdjkhalancd62gscaaqed9e0t2ueevpweejjzh4gdr4ggjkcmug389u7xjfemq7s27adu5zn8n3ty4jm2h79vl9va48xnky0ykk7rlvd5hvmsf8lsggc4nppqe63s9u"

    Import-SageOffer -offer $offer

    #>
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
    <#
    .SYNOPSIS
    Get a list of known offers from the sage wallet.

    .DESCRIPTION
    Get a list of known offers from the sage wallet.

    .PARAMETER status
    The status of the offers to return. (default: all)
    Possible options: active, cancelled, expired, completed

    .EXAMPLE
    Get-SageOffers -status active

    Get all active offers.
    #>
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

}

function Build-SageNft{
        
    $nft = [SageNft]::new()
    return $nft
    
}

function Start-SageBulkMint{
    <#
    .SYNOPSIS
    Mint a bulk of NFTs.

    .DESCRIPTION
    Mint a bulk of NFTs.

    .PARAMETER nfts
    The NFTs created from Build-SageNft

    .PARAMETER did_id
    The DID ID to mint the NFTs under.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
#>
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
    <#
    .SYNOPSIS
    Get an offer from the sage wallet by the offer id.

    .DESCRIPTION
    Get an offer from the sage wallet by the offer id.

    .PARAMETER offer_id
    The offer id to get.

    .EXAMPLE
    Get-SageOffer -offer_id c2f081db633b48e03809e10f5bb9ee0fb4575fbfa18d2fbe8cfd85b415fa599a

    Get the offer with the offer id c2f081db633b48e03809e10f5bb9ee0fb4575fbfa18d2fbe8cfd85b415fa599a

    #>
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
    <#
    .SYNOPSIS
    Cancel the offer onchain. 

    .DESCRIPTION
    Securely cancels the offer by making the offer string not spendable on the blockchain.

    .PARAMETER offer_id
    The offer id to cancel.

    .PARAMETER fee
    The fee to pay for the transaction.

    .PARAMETER auto_submit
    Automatically submit the transaction. (default: true)

    .EXAMPLE
    Revoke-SageOffer -offer_id c2f081db633b48e03809e10f5bb9ee0fb4575fbfa18d2fbe8cfd85b415fa599a

    Cancel the offer with the offer id c2f081db633b48e03809e10f5bb9ee0fb4575fbfa18d2fbe8cfd85b415fa599a

    
    #>
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
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
    <#
    .SYNOPSIS
    Remove an offer from the sage wallet but does not cancel on chain.

    .DESCRIPTION
    Remove an offer from the sage wallet but does not cancel on chain.

    .PARAMETER offer_id
    The offer id to remove.

    .EXAMPLE
    Remove-SageOffer -offer_id c2f081db633b48e03809e10f5bb9ee0fb4575fbfa18d2fbe8cfd85b415fa599a

    Remove the offer with the offer id c2f081db633b48e03809e10f5bb9ee0fb4575fbfa18d2fbe8cfd85b415fa599a
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$offer_id
    )
    $json = @{
        offer_id = $offer_id
    }

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

function Get-SageMinterDids{
    param(
        [Parameter(Mandatory=$true)]
        [UInt32]$offset,
        [Parameter(Mandatory=$true)]
        [UInt32]$limit
    )
    $json = @{
        offset = $offset
        limit = $limit
    }
    Invoke-SageRPC -endpoint get_minter_did_ids -json $json
}

function Approve-SageCoinSpend {

}

function New-SagePfxCertificate {
    
    if($IsWindows){
        $certPath = "$home\appdata\roaming\com.rigidnetwork.sage\ssl\wallet.crt"
        $keyPath = "$home\appdata\roaming\com.rigidnetwork.sage\ssl\wallet.key"
        $pfxPath = "$home\appdata\roaming\com.rigidnetwork.sage\ssl\wallet.pfx"
    }
    if($IsLinux){
        $certPath = "$home/.local/share/com.rigidnetwork.sage/ssl/wallet.crt"
        $keyPath = "$home/.local/share/com.rigidnetwork.sage/ssl/wallet.key"
        $pfxPath = "$home/.local/share/com.rigidnetwork.sage/ssl/wallet.pfx"
    }

    $cert = Get-Content -Path $certPath -Raw
    $key = Get-Content -Path $keyPath -Raw

    $certPem = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPem($cert, $key)
    $certPem = $certPem.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12)

    [System.IO.File]::WriteAllBytes($pfxPath, $certPem)
    

}

function Get-SagePfxCertificate {
   
    if($IsWindows){
        $certPath = "$home\appdata\roaming\com.rigidnetwork.sage\ssl\wallet.pfx"
    }
    if($IsLinux){
        $certPath = "$home/.local/share/com.rigidnetwork.sage/ssl/wallet.pfx"
    }
    if(-not (Test-Path -Path $certPath)){
        throw "The certificate to access the wallet does not exist. Please create it using New-SagePfxCertificate."
    }
    $certificate = Get-PfxCertificate -FilePath $certPath -Password $certPassword
    return $certificate
}


function Join-SageOffers {
    <#
    .SYNOPSIS
    Combine multiple offers into one.
    .DESCRIPTION
    Join multiple offers into one. This is useful for creating a single offer from multiple offers.
    .PARAMETER offers
    An array of offer strings to join.

    .EXAMPLE
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$offers
    )
    if($null -eq $offers){
        throw "The offers must be an array of offer strings."
    }
    if($offers.Count -lt 2){
        throw "The offers must be an array of offer strings with at least 2 elements."
    }
    $json = @{
        offers = $offers
    }
    
    Invoke-SageRPC -endpoint combine_offers -json $json
        
}

class SagePayments {
    [UInt64] $fee = 0
    [bool] $auto_submit = $true
    [array] $payments = @()
    $response

    addCatPayment([string] $asset_id,[string]$address,[uint64]$amount) {
        $payment = @{
            asset_id = $asset_id
            address = $address
            amount = $amount
        }
        $this.payments += $payment
    }
    addXchPayment([string]$address,[UInt64]$amount){
        $payment = @{
            address = $address
            amount = $amount
        }
        $this.payments += $payment
    }

    submit() {
        if($this.payments.Count -eq 0){
            throw "No payments to submit."
        }
        $json = @{
            fee = $this.fee
            auto_submit = $this.auto_submit
            payments = $this.payments
        }
        $this.response = Invoke-SageRPC -endpoint multi_send -json $json
    }
}

function Build-SageBulkPayments(){
    return [SagePayments]::new()        
}



function Hide-SageNft {
    <#
    .SYNOPSIS
    Hide an NFT from the wallet.

    .DESCRIPTION
    Hide an NFT from the wallet. This does not delete the NFT, it just hides it from the wallet.

    .PARAMETER nft_id
    The ID of the NFT to hide.

    .EXAMPLE
    Hide-SageNft -nft_id 1234567890abcdef

    Hides the NFT with the ID 1234567890abcdef

    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$nft_id
    )
    
    $json = @{
        nft_id = $nft_id
        visible = $false
    }

    Invoke-SageRPC -endpoint update_nft -json $json
}

function Show-SageNft {
    <#
    .SYNOPSIS
    Show an NFT in the wallet.

    .DESCRIPTION
    Show an NFT in the wallet. This does not delete the NFT, it just shows it in the wallet.

    .PARAMETER nft_id
    The ID of the NFT to show.

    .EXAMPLE
    Show-SageNft -nft_id 1234567890abcdef

    Shows the NFT with the ID 1234567890abcdef

    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$nft_id
    )
    
    $json = @{
        nft_id = $nft_id
        visible = $true
    }

    Invoke-SageRPC -endpoint update_nft -json $json
}


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




Export-ModuleMember -Function *