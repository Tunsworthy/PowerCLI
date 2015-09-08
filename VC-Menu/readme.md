#VC-Menu
##I'm Very lazy, so i created a menu for connecting to my VC servers.
See the example image
**Note:**This module will only allow you to be connected to one VC at a time. 

**Requriments:**
    -**Powershell 3.0**
        -Powershell 3.0 Required - https://www.microsoft.com/en-gb/download/details.aspx?id=34595
	    -Windows 7 Service Pack 1
		-64-bit versions: Windows6.1-KB2506143-x64.msu
    -**PowerCLI 6.0**
        https://blogs.vmware.com/PowerCLI/2015/03/powercli-6-0-r1-now-generally-available.html

**To Load:**
    -Place VC-Menu Folder in -> C:\Users\<Username>\Documents\WindowsPowerShell\Modules\
    -Open Powershell and run - Get-Command -Module VC-Menu (this is just an output to make sure you have put it in the correct location)
    -Run - Import-module VC-Menu
    -Run - VC-Menu-CredStore (this will add your username and password to the VC Credential store).

**Usage** 
	-run VC-Menu - input number or Customer code when prompted.