<# 
Name:Datastore vMotioning.ps1
Version: 1
Author: Tom Unsworth (mail@tomunsworth.net)
Comment: 
    This script was made to vmotion VMs from a source datastore to a destination,it monitors the tasks and will email a report when all the tasks are done 
    
Requriments:
    PowerCLI

#>

<#-------------------------------
Paramaters
--------------------------------#>
Param(
  [Parameter(Mandatory=$false,Position=1,helpmessage="vcenter server")]
  [string]$VC_Server,
  [Parameter(Mandatory=$false,Position=2,helpmessage="Location of CSV File with Souce and Destination Datastores")]
  [string]$CSV,
  [Parameter(Mandatory=$true,Position=3,helpmessage="SMTP Server to use")]
  [string]$SMTPServer,
  [Parameter(Mandatory=$true,Position=4,helpmessage="Send From Email Address")]
  [string]$SMTPFrom,
  [Parameter(Mandatory=$true,Position=5,helpmessage="Send To Email Address(s)")]
  [string]$SMTPTo  
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

$locations = Import-Csv "$($CSV)"

$script:errorreport = @()
$script:successfulreport = @()
$script:report_file = "report.html"

<#-------------------------------
Function Rerpot Header
-------------------------------#>
Function Report-Header {

Remove-Item $report_file -ErrorAction SilentlyContinue

$Report_infomration = "
    <style>
    body { background-color:#FFFFFF;
           font-family:arial;
           font-size:12pt; }
    </style>
    <body>
    <p><h2>Vmotions List</h2></p></body>  	
    "

$Report = $Report_infomration
$Report | Out-File -Append $report_file

}


<#-------------------------------
Function Report Body
-------------------------------#>
Function Report-Body {
#Get all the Successful vmotions
$report_infomration ="<body><h2>Successful vmotions</h2></body>"
$Report = $Report_infomration
$Report | Out-File -Append $report_file 

$Report = $script:successfulreport | select @{Expression={(get-vm -id $($_.ObjectId)).name};label="VM"},StartTime,FinishTime | ConvertTo-Html
$Report | Out-File -Append $report_file

#Get all the Failed vmotions

$report_infomration ="<body><h2>Failed vmotions</h2></body>"
$Report = $Report_infomration
$Report | Out-File -Append $report_file

$Report = $script:errorreport | select @{Expression={(get-vm -id $($_.ObjectId)).name};label="VM"},StartTime,FinishTime | ConvertTo-Html
$Report | Out-File -Append $report_file
}


<#-------------------------------
Function Email Report
-------------------------------#>
Function Report_Email {
    $messageSubject = "Datastore vMotion Report"
    $message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
    $message.Subject = $messageSubject
    $message.IsBodyHTML = $true
    $message.Body = Get-Content $script:report_file

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($message)
}

<#-------------------------------
Function to connect to VCs
-------------------------------#>
Function VC-Connect {
    if ($global:DefaultVIServers.Count -gt 0) {Disconnect-VIServer -Server * -Force -confirm: $false} 
    Try {Connect-VIServer $VC_Server -User "user" -Password "passowrd" -WarningAction SilentlyContinue -ErrorAction stop | Out-Null
           Write-output "Successfully conncted to vCenter"}
    Catch {Write-Error $(throw "Failed to connect")}
 }

 <#------------------------------
In this scetion Put the code you want to excute
-------------------------------#>
Function Vmotions {
$tasklist = @()

foreach ($location in $locations){
    $vmlist = get-datastore $location.source | get-vm
    foreach ($vm in $vmlist){
    $vmid = (get-vm $vm).Id
    move-vm $vm -Datastore $location.destination -RunAsync
    $task = get-task | where {$_.ObjectId -eq $vmid}
    $tasklist += $task
    }
}

$Collection = {$tasklist}.Invoke()

$erroredvms = @()
$successfulvms = @()

do {
    foreach ($watched in $tasklist){ 
    if($Collection -notcontains $watched){continue}
    try {$currentstate = get-task -id $watched.id -ErrorAction SilentlyContinue}
    catch {$Collection.Remove($watched);continue}
    
      if (($currentstate).State -eq "Success"){
        if ($successfulvms -contains $watched) {continue}
        else{$successfulvms += $currentstate;$Collection.Remove($watched)}
       }

      if (($currentstate).State -eq "Error"){
        if($erroredvms -contains $watched){continue}
        else{$erroredvms += $currentstate;$Collection.Remove($watched)}
      } 
   
   #Write-host "Collection Count $($Collection.count)"
   sleep 5
   }
   }until ($Collection.count -eq "0")
   
write-host "end of Collection finished"

$script:errorreport += $erroredvms
$script:successfulreport += $successfulvms

}
<#-----------------------------
End of your section
------------------------------#>

Report-Header
#Connect to VC
    VC-Connect
#Code to Process
   Vmotions
Report-Body
Report_Email
#End of VC Look