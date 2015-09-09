<# 
Name:Open-VMConsole.psm1
Version: 1
Download Link: https://github.com/Tunsworthy/PowerCLI/Open-VMConsole
Author: Tom Unsworth (mail@tomunsworth.net)
Comment: 
   Since Open-VMConsoleWindow stopped working for me (today) i had to come with another way of connecting to VM consoles (rather then opening the fat client or using a differnt browser)
   Currertly piping to the commad works, next update i will include adding paramters. 

Requriments:
    PowerCLI
    VMware RC - https://my.vmware.com/web/vmware/details?downloadGroup=VMRC70&productId=353 


Usage:
    Get-VM <VM> | Open-VMConsole

Install: 
**To Load:**
- Place VC-Menu Folder in -> C:\Users\<Username>\Documents\WindowsPowerShell\Modules\
- Open Powershell and run - Get-Command -Module VC-Menu (this is just an output to make sure you have put it in the correct location)
- Run - Import-module VC-Menu
- Run - VC-Menu-CredStore (this will add your username and password to the VC Credential store).


#>

Function Open-VMConsole {
 
<#------------------------
Generate all the settings to pass through to the launching command
--------------------------#>
     Function OVC-Settings ($vm) {
        $Session = Get-View -Id Sessionmanager
        $script:vcenter = $DefaultVIServer.serviceuri.Host
        $script:vmid =  ($vm).ExtensionData.moref.value
        $Script:ticket =  $Session.AcquireCloneTicket()
    }
<#------------------------
Command to Launch VMRC
--------------------------#>
    Function OVC-LaunchConsole {
        try {Start-Process -FilePath "C:\Program Files (x86)\VMware\VMware Remote Console\vmrc.exe" -ArgumentList "vmrc://clone:$($ticket)@$($vcenter)/?moid=$($vmid)"}
        catch {write-host $ErrorMessage}
    }

<#------------------------
This section exists for when i do the next part of allowing you to enter params
--------------------------#>

if ($input){
    OVC-Settings $input
    OVC-LaunchConsole
}
    

<#------------------------
End of Main Function
--------------------------#>
}