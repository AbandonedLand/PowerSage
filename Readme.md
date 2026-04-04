# PowerSage
PowerSage is a PowerShell module to help interact with the Sage Wallet. 

## Sage Wallet
Sage is a wallet for the Chia Blockchain.  Downloads can be found here https://github.com/xch-dev/sage

## Version 1.0.15
This version uses the HTTPS endpoint on sage.

## Install
To install the latest version run the following in PowerShell v7.4+

```PowerShell
Install-Module -name PowerSage
```

## Upgrade older Version
```PowerShell
Update-Module -name PowerSage
```

## Getting Started
Make sure your sage wallet is running and then go to Settings -> Advanced and Start the RPC client.


## Commands

To get a list of commands use

```PowerShell 
Get-Command -Module PowerSage
```

To get help with a command type 

```PowerShell 
Get-Help {CommandName} 

# OR

Get-Help {CommandName} -Examples

```

## Basic Usage

### Converting to and from Mojo

Chia's default value of coins/tokens is in Mojos.  PowerSage helps convert to/from these values.

```PowerShell
PS> 0.5 | ConvertTo-XchMojo
500000000000

PS> 35.439 | ConvertTo-CatMojo
35439

PS> 875000000000 | ConvertFrom-XchMojo
0.875

PS> 3500 | ConvertFrom-CatMojo
3.5

```


### Createing an Offer

Example of creating an offer requesting 1 XCH for 3 wUSDC.b

```PowerShell
# Initialize the Offer Object in PowerShell

$offer = Build-SageOffer

<#
Offer Cat
$offer.offercat('asset_id',AMOUNT_Mojo)

Request Cat
$offer.requestcat('asset_id',AMOUNT_Mojo)
#>

$offer.offercat('fa4a180ac326e67ea289b869e3448256f6af05721f7cf934cb9901baa6b7a99d',3000)


<#
Request XCH
-----------
$offer.requestxch(AMOUNT_Mojo)

Offer XCH
----------
$offer.offerxch(AMOUNT_Mojo)
#>

$offer.requestxch( (1 | ConvertTo-XchMojo) )  # Converts 1 to the mojo value of 1000000000000


# Once you're done adding items to the offer, you can create it using the createoffer() command.

# NOTE: you can add additional requested or offered cats/xch to the offer and it will create a multi asset offer/request.

# NFTs:
# NFTs can also be requested/offered by using:
# $offer.offernft('nft_id')

$offer.createoffer()

# Submit to Dexie by using the Submit function

$offer.submit()

# You can view the current data in the offer by using $offer
$offer


```

