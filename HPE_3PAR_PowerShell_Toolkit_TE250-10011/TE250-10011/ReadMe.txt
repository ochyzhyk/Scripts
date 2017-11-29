1 Overview
==========
The HPE 3PAR StoreServ PowerShell Toolkit helps administrators to manage HPE 3PAR StoreServ Storage in Microsoft Windows environments.

Features of PowerShell Toolkit
------------------------------
• The PowerShell Toolkit supports cmdlets, which are a wrapper around the native HPE 3PAR StoreServ Storage CLI commands.
• When a cmdlet is run, the following actions take place:
	- A secure connection to the HPE 3PAR StoreServ Storage is established over Secure Shell.
• The native HPE 3PAR StoreServ Storage CLI command and parameters are formed based on the PowerShell cmdlet and parameters.
	- The native HPE 3PAR StoreServ Storage CLI command is executed.
•	The output of the cmdlets is returned as PowerShell objects. This output can be piped to other PowerShell cmdlets for search.

New features in v2.1
--------------------
• Support for HPE 3PAR StoreServ Operating System 3.3.1
• Support HPE 3PAR StoreServ commands for below features
	- Compression
	- Asynchronous streaming replication
	- Deduplication
	- Peer Persistence
	- Increase Virtual Volume Size
	- Storage Federation
	- Smart SAN Enhancements (iSCSI)
	- VMware VVols support
	- Remote Copy
	- System Reporter
• Support for PowerShell (POSH) SSH module to establish SSH connections to the storage system
• Session Management (using session variable)
• Support for all parameters in existing cmdlets 

Supported Operating Systems and PowerShell Versions
---------------------------------------------------
HPE 3PAR StoreServ Storage Toolkit works with PowerShell v3.0 and later. 
You can use this Toolkit in the following environments:
• Windows 2016
• Windows Server 2012 R2
• Windows Server 2012
• Windows Server 2008 R2 SP1
• Windows Server 2008 R2
• Windows Server 2008 SP1
• Windows 10
• Windows 8
• Windows 7 SP1
• Windows 7

Supported HPE 3PAR StoreServ Storage Platforms
----------------------------------------------
• HPE 3PAR StoreServ 7000, 8000 and 20000 series

Supported firmware's for HPE 3PAR StoreServ Storage
--------------------------------------------------
• 3.3.1
• 3.2.2 (including all MUs)
• 3.2.1 (including all MUs)

 
2 Installing HPE 3PAR StoreServ Storage PowerShell Toolkit
==========================================================
This section describes the HPE 3PAR StoreServ Storage PowerShell Toolkit installation procedure and pre-requisites.
 
Pre-requisites
--------------
Toolkit needs PowerShell v3.0 or above and .NET Framework 4.0 or above. 

To establish Secure Shell connections, you must have either one of the following software installed:
• HPE 3PAR StoreServ CLI client
• Open source POSH SSH Module

Installation of POSH SSH Module
-------------------------------
	POSH SSH module is hosted in GitHub at https://github.com/darkoperator/Posh-SSH all source code for the cmdlets and for the module is available there and it is licensed under the BSD 3-Clause License. It requires PowerShell 3.0 and .NET Framework 4.0. The quickest way to install the module is by running:
	iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
	This will download the latest version of Posh-SSH and install it in the user’s profile. Once it finishes downloading and copying the module to the right place, it will list the commands available:
 
Note: Refer below link for more detail.
http://www.powershellmagazine.com/2014/07/03/posh-ssh-open-source-ssh-powershell-module/


Installing HPE 3PAR StoreServ Storage PowerShell Toolkit
--------------------------------------------------------
The HPE 3PAR StoreServ Storage PowerShell Toolkit is provided as a zipped package. 

To complete the installation:
1. Unzip the package and copy the folder HPE3PARPSToolkit to one of the following locations:
	%USERPROFILE%\Documents\WindowsPowerShell\Modules\
	Copy to this user specific location to make HPE 3PAR StoreServ Storage PowerShell Toolkit v2.1 available for the currently logged in Windows user.
	
	%SYSTEMROOT%\system32\WindowsPowerShell\v3.0\Modules\
	Copy to this system location to make HPE 3PAR StoreServ Storage PowerShell Toolkit v2.1 available for all users.
2. If you are planning to use HPE 3PAR CLI to establish a secure connection, then install the HPE 3PAR CLI software.
	If you are planning to use POSH SSH module to establish a secure connection, then refer the section <link for Installation of POSH SSH Module>
3. Open an interactive PowerShell console.
4. Import the toolkit module to the supported Windows host as follows:
	PS C:\>Import-Module HPE3PARPSToolkit
	
	The Log file location is:
	%USERPROFILE%\Documents\WindowsPowerShell\Modules\Logs\
	%SYSTEMROOT%\system32\WindowsPowerShell\v3.0\Modules\Logs\

3 PowerShell cmdlets help
=========================
To get list of cmdlets offered by HPE 3PAR StoreServ Storage PowerShell Toolkit, run this cmdlet:
	PS C:\> Get-3parCmdList
To get cmdlet specific help, run this cmdlet:
	PS C:\> Get-Help <cmdlet>
To get cmdlet specific help using the –full option, run this cmdlet:
	PS C:\> Get-Help <cmdlet> -full

4 Connection Management cmdlets
===============================
New-3ParPoshSshConnection                  :- Builds a SAN connection object using Posh SSH connection.
New-3parCLIConnection                      :- Builds a SAN connection object using HPE 3PAR CLI.
Set-3parPoshSshConnectionPasswordFile      :- Creates an encrypted password file on client machine.
Set-3parPoshSshConnectionUsingPasswordFile :- Creates a SAN Connection object using Encrypted password file.
	
Session Management (Using Session Variable)
-------------------------------------------
Session management using session variable is a new feature in HPE 3PAR StoreServ Storage PowerShell Toolkit v2.1. Using different sessions, we can execute cmdlets on one or multiple HPE 3PAR StoreServ Storage devices, using same or different user credentials.

To run cmdlets using sessions, follow below steps:
1. Create the connection object to the array, save the connection object into a variable
2. Create as many as sessions required on same or different arrays. Each time save the connection object into a variable.
	Note:
	You can create multiple session to one array with different credentials. 
	Creating multiple session to same array using same credentials is not allowed.
3. Run the cmdlets using required connection object

Example:- 
	a. Below cmdlet will create session to 1.2.3.4
		$Connection1 = New-3ParPoshSshConnection -SANIPAddress 1.2.3.4 -SANUserName ABC
	b. Below cmdlet will create session to 1.1.1.1
		$Connection2 = New-3ParPoshSshConnection -SANIPAddress 1.1.1.1 -SANUserName ZYX
		c. Below cmdlet will be run on array 1.2.3.4   
	Get-3parVersion -SANConnection $Connection1
		d. Below cmdlet will be run on array 1.1.1.1   
	Get-3parVersion -SANConnection $Connection2