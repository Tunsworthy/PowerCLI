<# 
Name:Datastore-OutHTML.ps1
Version: 1
Download Link: 
Author: Tom Unsworth (mail@tomunsworth.net)
Comment: 
    This script will output your current datastore usage levels and show any overprovising into a HTMl file and a CSV
#>
if ( (Get-PSSnapin -Name vmware.vimautomation.core -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin vmware.vimautomation.core
}
#starts off by disconncting just in case
if ($global:DefaultVIServers.Count -gt 0) {
	Write-Host "... Disconnecting existing VIServer connections ...."
	Disconnect-VIServer -Server * -Force -confirm: $false
}
#Pulls the Vcenter list from an xml file
$folder = get-location
#Pulls the Vcenter list from an xml file
[xml]$VC_list = Get-Content ($folder.path +"\Data\vcenter.xml")

$script:output = @()
<#-------------------------------
Any arrays or custom settings here please
--------------------------------#>
$CSS = "
<style> 
  .container{
   	color: #fff;
	width: 700px;
    text-align: center;
    font-family: calibri;
	position: center;
    clear: both;
	background: rgba(0,0,0,.5);
    border-radius: 5px 5px 5px 5px;
    padding: 1px;
    margin-bottom: 2px;
    margin-top: 2px;
    }

  table { 
    width: 100% 
     }
  tr {
    width: 100% 
    }
  td{
	color: #fff;
    font-size: 14px;
    font-weight: 300;
    text-shadow: 0 1px 0px rgba(#000, .7);
    text-align: widget-align; 
  }
  .widget-title{
    font-size 10px;
    text-transform uppercase;
    font-weight bold;
  }
.holder{
    color: white;
    text-align: center;
    font-family: calibri;
	position: relative;
    clear: both;
	background: rgba(255,255,255,.5);
    border-radius: 5px 5px 5px 5px;
    }

.bar-container{
    display: block;
	width: 100%;
    border-radius: 0px;
    float: widget-align;
    clear: both;
    background: rgba(#fff, .5);
    position: absolute;
	}

.bar-container-used {
    clear: both;	
    display: inline;
    float: left;
	border-radius: 20px 0px 0px 20px;
	background:rgba(102, 153, 255,5);
	height: 20px;
    margin-bottom: 0px;
    }

.bar-container-free {
    display: inline;
    float: left;
   	border-radius: 0px 20px 20px 0px;
	background: rgba(71, 209, 71,.5);
	height: 20px;
    margin-bottom: 0px;
    }
 .bar-container-Capacity {
    clear: both;
    display:block-inline;
    float: left;
    border-radius: 20px 0px 0px 20px;
	//background: rgba(0, 187, 255,.5);
	height: 20px;
    margin-bottom: 2px;
	}

.bar-container-Provisoned {
    display: inline;
    float: right;
    border-radius: 0px 20px 20px 0px;
	background: rgba(204, 0, 0,.5);
	height: 20px;
    margin-bottom: 2px;
}

</style>

<div class='container'>
         <div class='widget-title'>Key</div>
    <table> 
        <tr>
            <td style='width: 20%'><b>Used:</b></td>
            <td style='width: 5%;background:rgba(102, 153, 255,5);'>&nbsp;</td>
            <td style='width: 75%'>&nbsp;</td>
        </tr>
        <tr>
            <td style='width: 20%'><b><b>Free:</b></td>
            <td style='width: 5%;background: rgba(71, 209, 71,.5);'>&nbsp;</td>
            <td style='width: 75%'>&nbsp;</td>
        </tr>
        <tr>
            <td style='width: 20%'><b><b>Over Provisioned:</b></td>
            <td style='width: 5%;background: rgba(204, 0, 0,.5);'>&nbsp;</td>
            <td style='width: 75%'>&nbsp;</td>
        </tr>
    </table>
      </div>  
"





<#-------------------------------
Function to connect to VCs
-------------------------------#>
Function VC-Connect {
    if ($global:DefaultVIServers.Count -gt 0) {Disconnect-VIServer -Server * -Force -confirm: $false} 
    Try {Connect-VIServer $VC_Server.fqdn -user $VC_Server.user -password $VC_Server.pass -WarningAction SilentlyContinue -ErrorAction stop | Out-Null
           Write-output "Successfully conncted to vCenter"}
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
In this scetion Put the code you want to excute
-------------------------------#>
Function VC-Process {
#Gather Datastore Information
foreach ($datastore in Get-Datastore) {
   #make numbers easier
   $capacity = [math]::round($datastore.ExtensionData.Summary.capacity/1GB,2)
   $uncommited = [math]::round(($datastore.ExtensionData.Summary.Uncommitted)/1GB,2)
   $free =  [math]::round($datastore.ExtensionData.Summary.Freespace/1GB,2)
   $provisined = [math]::round(($datastore.CapacityGB – $datastore.FreespaceGB +($datastore.extensiondata.summary.uncommitted/1GB)),2)
   $provisinedper = [math]::round(($provisined / $Capacity)*100,2)
   $used = [math]::round(($datastore.ExtensionData.Summary.capacity - $datastore.ExtensionData.Summary.Freespace)/1GB,2)
   $freePer = [math]::round(($free / $Capacity)*100,2)
   $usedper = [math]::round(($used / $Capacity)*100,2)
   if ($provisined -ge $capacity){
   $overprovisend = [math]::round($provisined - $Capacity,2)
   }
   Else {
   $overprovisend = "0"
   }
   if ($used -eq "0"){
        $freeusedcode = "<div class='bar-container-free' style='width:$($freeper)%; border-radius: 20px 20px 20px 20px;'></div> "
    }
    if ($free -eq "0") {
        $freeusedcode = " <div class='bar-container-used' style='width:$($usedper)%; border-radius: 20px 20px 20px 20px'></div>"
	}
    if ($used -ne "0") {
         $freeusedcode = "<div class='bar-container-used' style='width:$($usedper)%'></div>
	              <div class='bar-container-free' style='width:$($freeper)% ; border-radius: 0px 0px 0px 0px''></div>
                    "
    }
    if ($overprovisend -eq "0") {
        $freeusedcode = "<div class='bar-container-used' style='width:$($usedper)%; border-radius: 20px 0px 0px 20px'></div>
	              <div class='bar-container-free' style='width:$($freeper)% ; border-radius: 0px 20px 20px 0px;'></div>
                    "
                      }

    if ($provisined -ge $Capacity) {
    $capacitywidth = [math]::round(($Capacity / $provisined)*100,2)
    $Provisonedwidth = 100 - $capacitywidth
    $capprocode ="<div class='bar-container-Capacity' style='width:$($capacitywidth)%'>
      $($freeusedcode)
    </div>
    <div class='bar-container-Provisoned' style='width:$($Provisonedwidth)%'></div>
    "
    }
    Else {
    $capacitywidth = [math]::Round((100 - $freeper),2)
    $Provisonedwidth = $provisinedper
    $capprocode = "
    <div class='bar-container-Capacity' style='width:$($capacitywidth)%'></div>
        $($freeusedcode)
        "
    }
    if ($provisined -eq $Capacity) {
    $capacitywidth = 100
    $capprocode = "
    <div class='bar bar-container-Capacity' style='width:$($capacitywidth)%; border-radius: 20px 20px 20px 20px;'>
    $($freeusedcode)
    </div>
    "
    }
   
$info = "" | select VC,DSName,Provisioned,Used,Free,Code,overprovisioned,capacity,Uncommitted
$info.VC = $VC_Server.fqdn
$info.DSName = $datastore.name
$info.Provisioned = $provisined
$info.capacity = $capacity
$info.overprovisioned = $overprovisend
$info.Used = $used
$info.free = $free
$info.Uncommitted = $uncommited
$info.code = 
    "<div class='container'>
         <div class='widget-title'>$($VC_Server.name) - Datastore - $($datastore.name) </div>
    <table> 
        <tr>
            <td style='width: 25%'>
                <b>Used:</b>$($used)GB </br>
                <b>Free:</b>$($free)GB</br>
                <b>Over Provisioned:</b>$($overprovisend)GB</br>           
                <b>Capacity:</b>$($Capacity)GB</br>
                <b>Provisioned:</b>$($provisined)GB            
            </td>
            <td> 
               <div class='holder' style='width:100%'>
                 $($capprocode)
                </div>
             </div>
            </td>
        </tr>
    </table>
      </div>  
    "

$script:output += $info
}


<#-----------------------------
End of your section
------------------------------#>
}

#Start of Vcenter login loop
foreach ($VC_Server in $VC_list.vcenter_servers.server) {
#Connect to VC
    VC-Connect
#Code to Process
    VC-Process
#Disconnet before end of loop
    VC-Disconnect
}
$CSS | Out-File $folder\datastore.html
$script:output | select VC,DSName,Provisioned,Used,Free,overprovisioned,capacity,Uncommitted | Export-Csv -NoTypeInformation $folder\datastore.csv
$graphout = @()
$graphout = $script:output | Sort -Descending VC, overprovisioned 
$graphout.code | Out-File -Append $folder\datastore.html
#End of VC Look