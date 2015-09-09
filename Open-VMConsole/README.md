#Open-VMConsole
##Since Open-VMConsoleWindow stopped working for me (today) i had to come with another way of connecting to VM consoles (rather then opening the fat client or using a differnt browser)
##Currertly piping to the commad works, next update i will include adding paramters. 

**Requriments:**
- **Powershell 3.0**
	- Powershell 3.0 Required - https://www.microsoft.com/en-gb/download/details.aspx?id=34595
-  **PowerCLI 6.0**
	-  https://blogs.vmware.com/PowerCLI/2015/03/powercli-6-0-r1-now-generally-available.html
- **VMware RC
	- https://my.vmware.com/web/vmware/details?downloadGroup=VMRC70&productId=353 

**To Load:**
- Place Open-VMConsole Folder in -> C:\Users\<Username>\Documents\WindowsPowerShell\Modules\
- Open Powershell and run - Get-Command -Module Open-VMConsole
- Run - Import-module Open-VMConsole

**Usage** 
- Get-VM <VM> | Open-VMConsole
