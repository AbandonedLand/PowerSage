using namespace Terminal.Gui
$module = (Get-Module Microsoft.PowerShell.ConsoleGuiTools -List).ModuleBase
Add-Type -Path (Join-path $module Terminal.Gui.dll)
$version = "1.0.0"



function New-AppWindow{
    param(
        [string]$Title
        )
    $Window = [Window]::new()
    $Window.Title = $Title
    $Window.Height = [Dim]::Fill()
    $Window.Width = [Dim]::Fill()

    return $Window
}

function Show-StatusBar{
    try{
        $SageKey = Get-SageKey
    } catch {
        $SageKey = $null
    }   
    if($SageKey.key){
        $status = "~Sage Fingerprint:~ $($SageKey.key.fingerprint)"
    } else {
        $status = "~Sage Fingerprint:~ Not Connected"
    }

    [StatusBar]::new( @(
        [StatusItem]::new("unknown", "Sage Terminal v$version", {}),
        [StatusItem]::new(1048588,"~F1~ Help",{
            Show-HelpWindow
        }),
        [StatusItem]::new(1048589,"~F2~ About",{
            [MessageBox]::Query("About",
"Created by The Mayor. 
@MayorAbandoned on X.com",@("OK"))       
        }),
        [StatusItem]::new(1048592,"~F5~ Home",{
            Show-MainWindow
        }),
        [StatusItem]::new("Unknown","$status",{})            
    ))
}



function Show-MenuWindow{
    $frame = [FrameView]::new()
    $frame.Width = [Dim]::Percent(20)
    $frame.Height = [Dim]::Fill()
    $rightFrame = [FrameView]::new()
    $rightFrame.Width = [Dim]::Percent(80)
    $rightFrame.Height = [Dim]::Fill()
    $rightFrame.X = [Pos]::Right($frame)
    $rightFrame.Y = 0
    try {
        $xch = Get-SageSyncStatus
        $cats = get-sagecats
    } catch {
        $xch = $null
        $cats = $null
    }
    $label = [Label]::new()
    $label.Text = "XCH Balance: $($xch.balance / 1e12)"
    $label.Y = 0
    $label.x = 1
    $rightFrame.Add($label)
    
    $MenuList = [ListView]::new()
    $MenuList.SetSource(@("Wallet", "Circuit Vaults", "Settings"))
    $MenuList.Width = [Dim]::Fill()
    $MenuList.Height = [Dim]::Fill()
    $MenuList.add_OpenSelectedItem({
        switch (($MenuList.SelectedItem)) {
            "Wallet" {
                $rightFrame.add((Show-WalletView))
            }
            "Circuit Vaults" {
                Show-CircuitVault -VaultName 1de27bd3aefa5be386397de8478e0ecb50a53a3fa9b5fc828d1a3de3eec12849
            }
            "Settings" {
                Show-ConfirmationBox -Title "Settings" -Message "This is where settings would go." -AffirmTitle "OK"
            }
        }
    })
    $frame.Add($MenuList)
    $window = New-AppWindow -Title "Menu"
    $window.Add($frame)
    $window.Add($rightFrame)
    [Application]::Top.RemoveAll()
    [Application]::Top.Add((Show-StatusBar))
    [Application]::Top.Add($window)

}

function Show-MainWindow{

    $Window = New-AppWindow -Title "Sage Terminal"
    
    Show-MenuWindow

}

function Show-HelpWindow{
    $window = New-AppWindow -Title "Help"
    [Application]::Top.RemoveAll()
    [Application]::Top.Add((Show-StatusBar))

    $text = [Label]::new("
Verify Sage is running and the RPC service is turned on.
https://docs.xch.dev/rpc/setup/ [CTRL + Click]

Make sure you are logged into the correct wallet fingerprint.

    ")
    $text.Y = 0
    $text.x = 1

    $window.Add($text)
    
    [Application]::Top.Add($window)
}
function Show-CircuitVault {
    param(
        [string]$VaultName
    )
    $vault = Get-CDVault -vault $VaultName
    if (-not $vault) {
        Show-ConfirmationBox -Title "Vault Not Found" -Message "No vault found with the name '$($VaultName)'" -AffirmTitle "OK" -Callback {Show-MainWindow}
    }

    $window = New-AppWindow -Title "Vault: $($VaultName)"
    $window.Modal = $true

    $list = [System.Collections.Generic.List[object]]::new()


    $vault.collateral = $vault.collateral / 1e12
    $vault.principal = $vault.principal / 1e3
    $vault.stability_fees = $vault.stability_fees / 1e3
    $vault.debt_owed_to_vault = $vault.debt_owed_to_vault / 1e3
    $vault.max_withdraw = $vault.max_withdraw / 1e12
    $vault.debt = $vault.debt / 1e3
    $vault.max_borrow = $vault.max_borrow / 1e3
    $vault.max_repay = $vault.max_repay / 1e3
    $list.Add("Collateral:         $($vault.collateral)")
    $list.Add("Principal:          $($vault.principal)")
    $list.Add("Stability Fees:     $($vault.stability_fees)")
    $list.Add("Debt Owed to Vault: $($vault.debt_owed_to_vault)")
    $list.Add("Max Withdraw:       $($vault.max_withdraw)")
    $list.Add("Debt:               $($vault.debt)")
    $list.Add("Max Borrow:         $($vault.max_borrow)")
    $list.Add("Max Repay:          $($vault.max_repay)")


    $ListView = [ListView]::new()
    $ListView.x = 2
    $ListView.Y = 2
    $listView.Width = [Dim]::Fill()
    $ListView.Height = [Dim]::Fill()
    $ListView.SetSource($list)
    $frame = [FrameView]::new()

    $frame.Width = [Dim]::Percent(35)
    $frame.Height = [Dim]::Fill()
    $frame.add($ListView)

    $window.Add($frame)
    
    $closeButton = [Button]::new("Close")
    $closeButton.X = [Pos]::Center()    # adjust for button width + margin
    $closeButton.Y = [Pos]::Bottom($ListView) - 3
    $closeButton.CanFocus = $true
    $closeButton.add_Clicked({
        Show-MainWindow
    })
    $window.Add($closeButton)

    [Application]::Top.RemoveAll()
    [Application]::Top.Add($window)
    $window.SetFocus()
    $window.FocusFirst()

}


function Start-SageTerminal {

    [Application]::Init()
    [Terminal.Gui.Application]::IsMouseDisabled = $false
    [Application]::QuitKey = 27

    Show-MainWindow


    [Application]::Run()

    # This makes it so it actually closes
    [Application]::Shutdown()
}

Start-SageTerminal

