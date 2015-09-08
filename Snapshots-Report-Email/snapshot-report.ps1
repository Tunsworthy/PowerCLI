<# 
Name:snapshot-report.ps1
Version: 2
Download Link: https://github.com/Tunsworthy/PowerCLI-VMware-Snapshots-Report/
Author: Tom Unsworth (mail@tomunsworth.net)
Comment: 
    This script produces a weekly report of snapshots from a list of vcenter servers, it can also handel exclutions
    Make sure the user that is running this script has access to create files in the Datafolder
Requriments:
    PowerCLI

V2 Updates:
---Major---
*Added in Exemptions ability
    -Any snapshots with "Exempt" in the discription won't be shown
    -Any snapshot in the csv from the data folder will not be shown
*Prameters for SMTP settings
*Found a shorter (and stronger) way of getting the created user - http://www.vstrong.info/2013/08/20/who-created-these-vm-snapshots/ (Thanks Mark Strong)
*Used Functions
*Major Code Clean up
*Also there was a bug where some snapshots were not showing...i don't know why but this is now fixed.
*Prameters to be able to set your Minimum snapshot age and reporting size
---Minor--- 
*Created nice looking table - because its important i tell you - Although outlook sucks and dosen't render it... so you also get an attachment of the file.
*Change the font from Times New Romans to Arial (As per Adams Request)
*Dynamic Company Name
*Commneted my code and added in this section
#>
<#-------------------------------
Paramaters
--------------------------------#>
Param(
  [Parameter(Mandatory=$false,Position=0,helpmessage="Minimum Snapshot age to report (Default is 7 days old)")]
  [int]$SnapReportAge = 7,
  [Parameter(Mandatory=$false,Position=1,helpmessage="Size at which the snapshot will be reported no matter how old (Default is 15GB)")]
  [int]$SnapReportSize = 15,
  [Parameter(Mandatory=$true,Position=3,helpmessage="SMTP Server to use")]
  [string]$SMTPServer,
  [Parameter(Mandatory=$true,Position=4,helpmessage="Send From Email Address")]
  [string]$SMTPFrom,
  [Parameter(Mandatory=$true,Position=5,helpmessage="Send To Email Address(s)")]
  [string]$SMTPTo,
  [Parameter(Mandatory=$false,Position=6,helpmessage="Your Companies Name")]
  [string]$companyname = "Taco corp"
  
)


#Add PowerCIL Snapin
if ( (Get-PSSnapin -Name vmware.vimautomation.core -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin vmware.vimautomation.core
}
#starts off by disconncting just in case
if ($global:DefaultVIServers.Count -gt 0) {
	Write-Host "... Disconnecting existing VIServer connections ...."
	Disconnect-VIServer -Server * -Force -confirm: $false
}

<#-------------------------------
Any arrays or custom settings here please
--------------------------------#>
$folder = get-location
#Pulls the Vcenter list from an xml file
[xml]$VC_list = Get-Content ($folder.path +"\Data\vcenter.xml")
$Snap_exmpt = Import-Csv ($folder.path +"\Data\snapshot-exemptions.csv")
$script:resultsarray = @()
$script:Report_file = ($folder.path +"\Data\snapshot-txt.html")
<#-------------------------------
Function Rerpot Header
-------------------------------#>
Function Report-Header {
   
    Remove-Item $script:report_file
    $date = Get-Date 
    $script:Report_Header = "
    <style>
    head { background-color:#FFFFFF;
           font-family:arial;
           font-size:12pt; }
    body { background-color:#FFFFFF;
           font-family:arial;
           font-size:12pt; }
    table{border-collapse: collapse;}
    TH {border-width: 1px;padding: 1px;border-style: solid;border-color:#4BACC6; background-color: #4BACC6; color: #FFFFFF;} 
    td {border-width: 1px;padding: 1px;}
    tr {border-width: 1px;padding: 1px;border-style: solid;border-color: black;}
    tr:nth-child(odd) { background-color:#FFFFFF; } 
    tr:nth-child(even) { background-color:#DAEEF3; } 
    </style>
        <p><h2> $($companyname) - $($date.day)/$($date.Month)/$($date.Year)</h2></p>
    	<p>This Report is Generated from $($env:COMPUTERNAME) using account $($env:USERDOMAIN)\$($env:USERNAME)  </br>
    	Script Location: $($folder)\snapshots-report.ps1 </br>

    	Please Log an Incident to the respective customer using the VMWare Snapshot Removal template for all snapshots in the list</br>
       <p> Note: Snapshots will not be shown if they are:
        <li>Younger then $($SnapReportAge) Days & Smaller then $($SnapReportSize) GB</li>
        </p></br>
    	If the snapshot has been created by $($companyname) employee please log an incident to them directly.</br>
        Exemptions can be added via the exemptions file located in  $($folder)\data\snapshot-exemptions.csv </p>
      "

 
}
<#-------------------------------
Function Report Body
-------------------------------#>
Function Report-Body {
if ($script:resultsarray -ne $null){
    $Report = $script:resultsarray | Select vCenter,VM,Name,Description,Size,Created,CreatedBy | ConvertTo-Html -head $script:Report_Header | Out-File -Append $script:report_file
    }
else {
    $output = "<p>No Snapshots to report</p>" | Out-String
    $Report = $output | ConvertTo-Html -head $script:Report_Header | Out-File -Append $script:report_file
    }

}
<#-------------------------------
Function Email Report
-------------------------------#>
Function Report_Email {
    $messageSubject = "$companyname Snapshot report - $($date).day/$($date).month/$($date).year"
    $message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
    $message.Subject = $messageSubject
    $message.IsBodyHTML = $true
    $message.Body = Get-Content $script:report_file
    $message.Attachments.Add($script:report_file)
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($message)
}
<#-------------------------------
Function to connect to VCs
-------------------------------#>
Function VC-Connect {
    if ($global:DefaultVIServers.Count -gt 0) {Disconnect-VIServer -Server * -Force -confirm: $false} 
    Try {Connect-VIServer $VC_Server.fqdn -user $VC_Server.user -password $VC_Server.pass -WarningAction SilentlyContinue -ErrorAction stop | Out-Null
           Write-host "Successfully conncted to vCenter"$VC_Server.name}
    Catch {Write-Error $(throw "Failed to connect")}
 }
 
<#-------------------------------
Function to disconnect VCs
-------------------------------#>
Function VC-Disconnect {
    if ($global:DefaultVIServers.Count -gt 0) {
    try {Disconnect-VIServer -Server * -Force -confirm: $false
        Write-output "Disconected from VC"} 
    catch { write-error $(throw"Problem Disconnecting from VC")}
    }
}

<#------------------------------
Checking for Snapshots
-------------------------------#>
Function VC-Process {
$snapshots = Get-VM | Get-Snapshot
    if ($snapshots -eq $null){return}
	foreach ($snapshot in $snapshots) {
        #Check to see if the snapshot meets the threshold critera
        if (($snapshot.created -ge (get-date).adddays(-$SnapReportAge)) -and ($snapshot.sizeGB -le $SnapReportSize)){continue}
        #Check Descriptions for Exemption tag  
        if ($snapshot.description -like "Exempt*"){continue}
        #Check Exemptions file
        foreach ($exemption  in $Snap_exmpt) {        
            if (($snapshot.name -like $exemption.snapname) -and ($snapshot.vm -match $exemption.vmname)) {$exempt = $true
            break}
            else {$exempt = $false}
            }
            if ($exempt) {continue}
            $snapevent = Get-VIEvent -Entity $snapshot.VM -Types Info -Finish $snapshot.Created -MaxSamples 1 | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
    		if ($snapevent -eq $null){
                $Snapshot | Add-Member –MemberType NoteProperty –Name 'CreatedBy' –Value "Unable to find user" 
    		}
            else {
                $Snapshot | Add-Member –MemberType NoteProperty –Name 'CreatedBy' –Value $snapevent.username
            }
            $Snapshot | Add-Member -MemberType NoteProperty -Name 'vCenter' -Value $VC_Server.name         
            $script:resultsarray += $snapshot | Select vCenter,VM,Name,Description,@{Label="Size";Expression={"{0:N2} GB" -f ($_.SizeGB)}},Created,CreatedBy
        }
}
<#-----------------------------
End of your section
------------------------------#>

Report-Header
#Start of Vcenter login loop
foreach ($VC_Server in $VC_list.vcenter_servers.server) {
#Connect to VC
    VC-Connect
#Code to Process
   VC-Process
#Disconnet before end of loop
   VC-Disconnect
}
Report-Body
Report_Email
#End of VC Look
