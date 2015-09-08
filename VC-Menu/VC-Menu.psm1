<# 
Name:VC-Menu.psm1
Version: 1
Download 
Author: Tom Unsworth (mail@tomunsworth.net)
Comment: 
    A Module built to make connecting to many VCenter Enviroments easier.
    This module will only allow you to be connected to one VC at a time.
Requriments:
    Powershell 3.0
        Powershell 3.0 Required - https://www.microsoft.com/en-gb/download/details.aspx?id=34595
	    Windows 7 Service Pack 1
		64-bit versions: Windows6.1-KB2506143-x64.msu
    PowerCLI 6.0
        https://blogs.vmware.com/PowerCLI/2015/03/powercli-6-0-r1-now-generally-available.html

To Load:
    Place VC-Menu Folder in -> C:\Users\<Username>\Documents\WindowsPowerShell\Modules\
    Open Powershell and run - Get-Command -Module VC-Menu (this is just an output to make sure you have put it in the correct location)
    Run - Import-module VC-Menu
    Run - VC-Menu-CredStore (this will add your username and password to the VC Credential store).

Usage - run VC-Menu - input number or Customer code when prompted.

#>
<#-------------------------------
Arrays For menu options
Enter your FQDN and Short Codes (make sure they are in the same order)
--------------------------------#>
$VC_FQDN = "FakeVC.Madeup.net","Its.a.VC","VC.Menu.example"
$VC_scode = "Fake","Its","Menu"
Function VC-Menu {
   if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    . "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
    }

<#-------------------------------
Any arrays or custom settings here please
--------------------------------#>
    $script:loopnum = 0
    $script:VC_List = @()
<#-------------------------------
Function to connect to VCs
 -------------------------------#>
    Function Connect ($VC_server) {
        if ($global:DefaultVIServers.Count -gt 0) {Disconnect-VIServer -Server * -Force -confirm: $false} 
        Try {Connect-VIServer $VC_Server -WarningAction SilentlyContinue -ErrorAction stop | Out-Null
           Write-output "Successfully conncted to vCenter"}
        Catch {Write-Error "Failed to connect"}
      }
 <#-------------------------------
Displaying the menu
--------------------------------#>   
    Function MenuDisplay {
    

    foreach ($VC in $VC_FQDN){
         $info = New-Object System.Object 
            $info | Add-Member -type NoteProperty -name ID -Value $loopnum
            $info | Add-Member -type NoteProperty -name "Short Code" -Value $VC_scode[[int]$loopnum]
            $info | Add-Member -type NoteProperty -name VCFQDN -Value $VC
        $script:VC_List += $info
        $script:loopnum ++   
    }
    $script:VC_List | ft -AutoSize
    }

    Function Selection {
      Param(
        [Parameter(Mandatory=$true,Position=0,helpmessage="Selection - Enter the ID or Short Code of the VC you would like to connect")]
        $Selection
      )

        if($Selection -match "[0-$script:loopnum]"){
            try {
              Connect $VC_List.VCFQDN[[int]$Selection]
            }  
         catch {
            write-host $ErrorMessage
            }
        }      
       if ($Selection -in $VC_List.Custcode){
          foreach ($VC in $VC_list){
            if ($Selection -match $VC.custcode){
                $connect = $VC.VCFQDN
                break
            }
          }
           try {
            Connect $connect
            }  
         catch {
            write-host $ErrorMessage
            }
           }
        }


    MenuDisplay
    Selection
}
Function VC-Menu-CredStore {
 Param(
  [Parameter(
            Mandatory=$true,
            Position=2,
            HelpMessage="Username and Password for vCenter"
        )]
       [ValidateNotNullOrEmpty()]
       [System.Management.Automation.PSCredential]$Credential
       )
 if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    . "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
    }
if ( (Get-PSSnapin -Name vmware.vimautomation.core -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin vmware.vimautomation.core
}
  
    foreach ($VC in $VC_FQDN) {
        New-VICredentialStoreItem -host $VC -User $Credential.GetNetworkCredential().username -Password $Credential.GetNetworkCredential().Password
    }
 }
