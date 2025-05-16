# PowerSage
PowerSage is a PowerShell module to help interact with the Sage Wallet. 

## Sage Wallet
Sage is a wallet for the Chia Blockchain.  Downloads can be found here https://github.com/xch-dev/sage

## Version 1.0.0
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


The first time running you will need to use the command to create a PFX certificate that powershell will use to connect the the RPC.

```PowerShell 

New-SagePfxCertificate

```

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