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
###########
URL-Only Option
Author: https://github.com/jpsider (feel free to reach out if you have questions)
Comment:
	Absolutely open to input and improvements!
	This script will produce a shareable URL to a VM's console.
	I've only tested this with vCenter 5.5 and 6.0
	This page said I could use &sessionTicket=cst-VCT (http://vmnick0.me/?p=75) but I never got it to work
		So you might need to update the thumbprint to your vcenter.
	
Usage: 
	Get-ConsoleURL UrlOnly $vm

Assumptions: 
	1. You are already connected to Vcenter!
	2. $vCenter, $VCenterUN, $VCenterPW are defined 
###########

#>
$option=$args[0] 
Function Open-VMConsole($option, $vm) {
 
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

	if ($option -eq "UrlOnly"){
		#Determine vCenter version
		$vCenterVersion = $global:DefaultVIServer.ExtensionData.Content.About.Version
		if ($vCenterVersion -Like "6.*"){
			$ConsolePort = 9443 
			$myVM = Get-VM $vm
			$VMMoRef = $myVM.ExtensionData.MoRef.Value
			
			#Get Vcenter from advanced settings
			$UUID = ((Connect-VIServer $vCenter -user $vCenterUN -Password $vCenterPW -ErrorAction SilentlyContinue).InstanceUUID)
			$SettingsMgr = Get-View $global:DefaultVIServer.ExtensionData.Client.ServiceContent.Setting
			$Settings = $SettingsMgr.Setting.GetEnumerator() 
			$AdvancedSettingsFQDN = ($Settings | Where {$_.Key -eq "VirtualCenter.FQDN" }).Value
			
			#Get vCenter ticket
			$SessionMgr = Get-View $global:DefaultVIServer.ExtensionData.Client.ServiceContent.SessionManager
			$Session = $SessionMgr.AcquireCloneTicket()
			
			#Create URL and place it in the Database
			$ConsoleLink = "https://$($Vcenter):$($ConsolePort)/vsphere-client/webconsole.html?vmId=$($VMMoRef)&vm=$($myVM.Name)&serverGuid=${UUID}&host=$($AdvancedSettingsFQDN)&sessionTicket=$($Session)&thumbprint=5A:AB:D4:75:29:E8:D5:94:09:8F:D2:91:CF:DC:AB:C0:69:03:37:42"	
			return $ConsoleLink
		}
		Elseif ($vCenterVersion -Like "5.*") {
			#Create URL and place it in the Database
			$myVM = Get-VM $vm
			$UUID = ((Connect-VIServer $Vcenter -user $VCenterUN -Password $VCenterPW -ErrorAction SilentlyContinue).InstanceUUID).ToUpper()
			$MoRef = $myVM.ExtensionData.MoRef.Value
			$ConsoleLink = "https://${Vcenter}:9443/vsphere-client/vmrc/vmrc.jsp?vm=urn:vmomi:VirtualMachine:${MoRef}:${UUID}"
			return $ConsoleLink
		}
		Else {
		write-host "Unable to determine Hypervisor Version."
		}
	} 
	
<#------------------------
End of Main Function
--------------------------#>
}
