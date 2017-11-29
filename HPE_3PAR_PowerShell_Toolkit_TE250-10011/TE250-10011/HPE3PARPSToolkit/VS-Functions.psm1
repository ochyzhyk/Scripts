## ##################################################################################
## Copyright (c) Hewlett-Packard Enterprise  Development Company, L.P. 2015
## 
##		File Name:		VS-Functions.psm1
##		Description: 	Common Module functions .
##		
##		Pre-requisites: Needs HPE3PAR cli.exe for New-3parCLIConnection
##						Needs POSH SSH Module for New-3parPoshSshConnection
##
##		Created:		June 2015
##		Last Modified:	April 2017
##
##		History:		V1.0 - Created
##						v2.0 - Added support for HP3PAR CLI 
##                      v2.1 - Added support for POSH SSH Module 
##					
##	
## ###################################################################################


# Generic connection object 

add-type @" 

public struct _Connection{
public string SessionId;
public string IPAddress;
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@


$global:LogInfo = $true
$global:DisplayInfo = $true
#$global:SANConnection = New-Object System.Collections.ArrayList #set in HPE3PARPSToolkit.psm1 
$global:SANConnection = $null #set in HPE3PARPSToolkit.psm1 

if(!$global:VSVersion)
{
	$global:VSVersion = "VS3 V2.0"
}

if(!$global:ConfigDir) 
{
	$global:ConfigDir = $null 
}
$Info = "INFO:"
$Debug = "DEBUG:"

Import-Module "$global:VSLibraries\Logger.psm1"

############################################################################################################################################
## FUNCTION Invoke-3parCLICMD
############################################################################################################################################

Function Invoke-3parCLICmd
{
<#
  	.SYNOPSIS
		Execute a command against a device using HP3PAR CLI

	.DESCRIPTION
		Execute a command against a device using HP3PAR CLI
 
		
	.PARAMETER Connection
		Pointer to an object that contains passwordfile, HP3parCLI installed path and IP address
		
	.PARAMETER Cmds
		Command to be executed
  	
	.EXAMPLE
		
		Invoke-3parCLICmd -Connection $global:SANConnection -Cmds "showsysmgr"
		The command queries a 3PAR array to get information on the 3PAr system
		$global:SANConnection is created wiith the cmdlet New-SANConnection
			
  .Notes
    NAME:  Invoke-3parCLICmd
    LASTEDIT: June 2012
    KEYWORDS: Invoke-3parCLICmd
   
  .Link
     Http://www.hp.com
 
 #Requires HP3PAR CLI -Version 3.2.2
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter(Mandatory=$true)]
			$Connection,
			
			[Parameter(Mandatory=$true)]
			[string]$Cmds  

		)

Write-DebugLog "Start: In Invoke-3parCLICmd - validating input values" $Debug 

	#check if connection object contents are null/empty
	if(!$Connection)
	{	
		$connection = [_Connection]$Connection	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $Connection
		if($Validate1 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-*Connection and pass it as parameter" "ERR:"
			Write-DebugLog "Stop: Exiting Invoke-3parCLICmd since connection object values are null/empty" "ERR:"
			return
		}
	}
	#check if cmd is null/empty
	if (!$Cmds)
	{
		Write-DebugLog "No command is passed to the Invoke-3parCLICmd." "ERR:"
		Write-DebugLog "Stop: Exiting Invoke-3parCLICmd since command parameter is null/empty null/empty" "ERR:"
		return
	}
	$clittype = $Connection.cliType
	
	if($clittype -eq "3parcli")
	{
		#write-host "In invoke-3parclicmd -> entered in clitype $clittype"
		Invoke-3parCLI  -DeviceIPAddress  $Connection.IPAddress -epwdFile $Connection.epwdFile -CLIDir $Connection.CLIDir -cmd $Cmds
	}
	elseif($clittype -eq "SshClient")
	{
		
		$Result =Invoke-SSHCommand -Command $Cmds -SessionId $Connection.SessionId
		if($Result.ExitStatus -eq 0)
		{
			return $Result.Output
		}
		else
		{
			$Error = "FAILURE : "+ $Result.Error		    
			return $Error
		}
		
	}
	else
	{
		return "FAILURE : Invalid cliType option"
	}

}# End Invoke-3parCLICMD

############################################################################################################################################
## FUNCTION SET-DEBUGLOG
############################################################################################################################################

Function Set-DebugLog
{
<#
  .SYNOPSIS
    Enables creating debug logs.
  
  .DESCRIPTION
	Creates Log folder and debug log files in the directory structure where the current modules are running.
        
  .EXAMPLE
    Set-DebugLog -LogDebugInfo $true -Display $true
	Set-DEbugLog -LogDebugInfo $true -Display $false
    
  .PARAMETER LogDebugInfo 
    Specify the LogDebugInfo value to $true to see the debug log files to be created or $false if no debug log files are needed.
	
   .PARAMETER Display 
    Specify the value to $true. This will enable seeing messages on the PS console. This switch is set to true by default. Turn it off by setting it to $false. Look at examples.
	
  .Notes
    NAME:  Set-DebugLog
    LASTEDIT: 04/18/2012
    KEYWORDS: DebugLog
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory= $true, ValueFromPipeline=$true)]
		[System.Boolean]
        $LogDebugInfo=$false,		
		[parameter(Position=2, Mandatory = $true, ValueFromPipeline=$true)]
    	[System.Boolean]
   		$Display = $true
		 
	)

$global:LogInfo = $LogDebugInfo
$global:DisplayInfo = $Display	
Write-DebugLog "Exiting function call Set-DebugLog. The value of logging debug information is set to $global:LogInfo and the value of Display on console is $global:DisplayInfo" $Debug
}

############################################################################################################################################
## FUNCTION Invoke-3parCLI
############################################################################################################################################

Function Invoke-3parCLI 
{
<#
  .SYNOPSIS
    This is private method not to be used. For internal use only.
  
  .DESCRIPTION
    Executes 3par cli command with the specified paramaeters to get data from the specified virtual Connect IP Address 
   
  .EXAMPLE
    Invoke-3parCLI -DeviceIPAddress "DeviceIPAddress" -CLIDir "Full Installed Path of cli.exe" -epwdFile "C:\loginencryptddetails.txt"  -cmd "show server $serverID"
    
   
  .PARAMETER DeviceIPAddress 
    Specify the IP address for Virtual Connect(VC) or Onboard Administrator(OA) or Storage or any other device
    
  .PARAMETER CLIDir 
    Specify the absolute path of HP3PAR CLI's cli.exe
    
   .PARAMETER epwdFIle 
    Specify the encrypted password file location
	
  .PARAMETER cmd 
    Specify the command to be run for Virtual Connect
        
  .Notes
    NAME:  Invoke-3parCLI    
    LASTEDIT: 04/04/2012
    KEYWORDS: 3parCLI
   
  .Link
     Http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
 
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $DeviceIPAddress=$null,
		[Parameter(Position=1)]
		[System.String]
        #$CLIDir="C:\Program Files (x86)\Hewlett-Packard\HP 3PAR CLI\bin",
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=2)]
		[System.String]
        $epwdFile="C:\HP3PARepwdlogin.txt",
        [Parameter(Position=3)]
		[System.String]
        $cmd="show -help"
	)
	#write-host  "Password in Invoke-3parCLI = ",$password	
	Write-DebugLog "start:In function Invoke-3parCLI. Validating PUTTY path." $Debug
	if(Test-Path -Path $CLIDir)
	{
		$clifile = $CLIDir + "\cli.exe"
		if( -not (Test-Path $clifile))
		{
			
			Write-DebugLog "Stop: HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir." "ERR:"			
			return "FAILURE : HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir. "
		}
	}
	else
	{
		$SANCObj = $global:SANConnection
		$CLIDir = $SANCObj.CLIDir
	}
	if (-not (Test-Path -Path $CLIDir )) 
	{
		Write-DebugLog "Stop: Path for HP3PAR cli.exe was not found. Make sure you have installed HP3PAR CLI" "ERR:"			
		return "FAILURE : Path for HP3PAR cli.exe was not found. Make sure you have installed HP3PAR CLI in $CLIDir "
	}	
	Write-DebugLog "Running:In function Invoke-3parCLI. Calling Test Network with IP Address = $DeviceIPAddress" $Debug	
	$Status = Test-Network $DeviceIPAddress
	if($Status -eq $null)
	{
		Write-DebugLog "Stop:In function Invoke-3parCLI. Invalid IP Address Format"  "ERR:"
		Throw "Invalid IP Address Format"
		
	}
	if($Status -eq "Failed")
	{
		Write-DebugLog "Stop:In function Invoke-3parCLI. Not able to ping the device with IP $DeviceIPAddress. Check IP address and try again."  "ERR:"
		Throw "Not able to ping the device with IP $DeviceIPAddress. Check IP address and try again."
	}
	
	Write-DebugLog "Running:In function Invoke-3parCLI. Executed Test Network with IP Address = $DeviceIPAddress. Now invoking HP3par cli...." $Debug
	
	try{

		#if(!($global:epwdFile)){
		#	Write-DebugLog "Stop:Please create encrpted password file first using New-SANConnection"  "ERR:"
		#	return "`nFAILURE : Please create encrpted password file first using New-SANConnection"
		#}	
		#write-host "encrypted password file is $epwdFile"
		$pwfile = $epwdFile
		$test = $cmd.split(" ")
		#$test = [regex]::split($cmd," ")
		$fcmd = $test[0].trim()
		$count=  $test.count
		$fcmd1 = $test[1..$count]
		#$cmdtemp= [regex]::Replace($fcmd1,"\n"," ")
		#$cmd2 = $fcmd+".bat"
		#$cmdFinal = " $cmd2 -sys $DeviceIPAddress -pwf $pwfile $fcmd1"
		#write-host "Command is  : $cmdFinal"
		#Invoke-Expression $cmdFinal	
		$CLIDir = "$CLIDir\cli.exe"
		$path = "$CLIDir\$fcmd"
		#write-host "command is 1:  $cmd2  $fcmd1 -sys $DeviceIPAddress -pwf $pwfile"
		& $CLIDir -sys $DeviceIPAddress -pwf $pwfile $fcmd $fcmd1
		if(!($?	)){
			return "`nFAILURE : FATAL ERROR"
		}	
	}
	catch{
		$msg = "In function Invoke-3parCLI -->Exception Occured. "
		$msg+= $_.Exception.ToString()			
		Write-Exception $msg -error
		Throw $msg
	}	
	Write-DebugLog "End:In function Invoke-3parCLI. If there are no errors reported on the console then HP3par cli with the cmd = $cmd for user $username has completed Successfully" $Debug
}

############################################################################################################################################
## FUNCTION TEST-NETWORK
############################################################################################################################################

Function Test-Network ([string]$IPAddress)
{
<#
  .SYNOPSIS
    Pings the given IP Adress.
  
  .DESCRIPTION
	Pings the IP address to test for connectivity.
        
  .EXAMPLE
    Test-Network -IPAddress 10.1.1.
	
   .PARAMETER IPAddress 
    Specify the IP address which needs to be pinged.
	   	
  .Notes
    NAME:  Test-Network 
	LASTEDITED: May 9 2012
    KEYWORDS: Test-Network
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>

	$Status = Test-IPFormat $IPAddress
	if ($Status -eq $null)
	{
		return $Status 
	}

	try 
	{
	  $Ping = new-object System.Net.NetworkInformation.Ping
	  $result = $ping.Send($IPAddress)
	  $Status = $result.Status.ToString()
	}
	catch [Exception]
	{
	  ## Server does not exist - skip it
	  $Status = "Failed"
	}
	                
	return $Status
				
}

############################################################################################################################################
## FUNCTION TEST-IPFORMAT
############################################################################################################################################

Function Test-IPFormat 
{
<#
  .SYNOPSIS
    Validate IP address format
  
  .DESCRIPTION
	Validates the given value is in a valid IP address format.
        
  .EXAMPLE
    Test-IPFormat -Address
	    
  .PARAMETER Address 
    Specify the Address which will be validated to check if its a valid IP format.
	
  .Notes
    NAME:  Test-IPFormat
    LASTEDIT: 05/09/2012
    KEYWORDS: Test-IPFormat
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>

	param([string]$Address =$(throw "Missing IP address parameter"))
	trap{$false;continue;}
	[bool][System.Net.IPAddress]::Parse($Address);
}


############################################################################################################################################
## FUNCTION TEST-FILEPATH
############################################################################################################################################

Function Test-FilePath ([String[]]$ConfigFiles)
{
<#
  .SYNOPSIS
    Validate an array of file paths. For Internal Use only.
  
  .DESCRIPTION
	Validates if a path specified in the array is valid.
        
  .EXAMPLE
    Test-FilePath -ConfigFiles
	    
  .PARAMETER -ConfigFiles 
    Specify an array of config files which need to be validated.
	
  .Notes
    NAME:  Test-FilePath
    LASTEDIT: 05/30/2012
    KEYWORDS: Test-FilePath
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
 
 	Write-DebugLog "Start: Entering function Test-FilePath." $Debug
	$Validate = @()	
	if(-not ($global:ConfigDir))
	{
		Write-DebugLog "STOP: Configuration Directory path is not set. Run scripts Init-PS-Session.ps1 OR import module VS-Functions.psm1 and run cmdlet Set-ConfigDirectory" "ERR:"
		$Validate = @("Configuration Directory path is not set. Run scripts Init-PS-Session.ps1 OR import module VS-Functions.psm1 and run cmdlet Set-ConfigDirectory.")
		return $Validate
	}
	foreach($argConfigFile in $ConfigFiles)
	{			
			if (-not (Test-Path -Path $argConfigFile )) 
			{
				
				$FullPathConfigFile = $global:ConfigDir + $argConfigFile
				if(-not (Test-Path -Path $FullPathConfigFile))
				{
					$Validate = $Validate + @(,"Path $FullPathConfigFile not found.")					
				}				
			}
	}	
	
	Write-DebugLog "End: Leaving function Test-FilePath." $Debug
	return $Validate
}

Function Test-PARCLi{
<#
  .SYNOPSIS
    Test-PARCli object path

  .EXAMPLE
    Test-PARCli t
	
  .Notes
    NAME:  Test-PARCli
    LASTEDIT: 06/16/2015
    KEYWORDS: Test-PARCli
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)
	$SANCOB = $SANConnection 
	$clittype = $SANCOB.CliType
	Write-DebugLog "Start : in Test-PARCli function " "INFO:"
	if($clittype -eq "3parcli")
	{
		Test-PARCliTest -SANConnection $SANConnection
	}
	elseif($clittype -eq "SshClient")
	{
		Test-SSHSession -SANConnection $SANConnection
	}
	else
	{
		return "FAILURE : Invalid cli type"
	}	

}

Function Test-SSHSession {
<#
  .SYNOPSIS
    Test-SSHSession   
	
  .PARAMETER pathFolder
    Test-SSHSession

  .EXAMPLE
    Test-SSHSession -SANConnection $SANConnection
	
  .Notes
    NAME:  Test-SSHSession
    LASTEDIT: 14/03/2017
    KEYWORDS: Test-SSHSession
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(	
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)
	
	$Result = Get-SSHSession | fl
	
	if($Result.count -gt 1)
	{
	}
	else
	{
		return "`nFAILURE : FATAL ERROR"
	}
	
}

Function Test-PARCliTest {
<#
  .SYNOPSIS
    Test-PARCli pathFolder
  
	
  .PARAMETER pathFolder
    Specify the names of the HP3par cli path

  .EXAMPLE
    Test-PARCli path -pathFolder c:\test
	
  .Notes
    NAME:  Test-PARCliTest
    LASTEDIT: 06/16/2015
    KEYWORDS: Test-PARCliTest
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #> 
 [CmdletBinding()]
	param 
	(
		[Parameter(Position=0,Mandatory=$false)]
		[System.String]
		#$pathFolder = "C:\Program Files (x86)\Hewlett-Packard\HP 3PAR CLI\bin\",
		$pathFolder="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
	)
	$SANCOB = $SANConnection 
	$DeviceIPAddress = $SANCOB.IPAddress
	Write-DebugLog "Start : in Test-PARCli function " "INFO:"
	#Write-host "Start : in Test-PARCli function "
	$CLIDir = $pathFolder
	if(Test-Path -Path $CLIDir){
		$clitestfile = $CLIDir + "\cli.exe"
		if( -not (Test-Path $clitestfile)){					
			return "FAILURE : HP3PAR cli.exe file was not found. Make sure you have cli.exe file under $CLIDir "
		}
		$pwfile = $SANCOB.epwdFile
		$cmd2 = "help.bat"
		#$cmdFinal = "$cmd2 -sys $DeviceIPAddress -pwf $pwfile"
		& $cmd2 -sys $DeviceIPAddress -pwf $pwfile
		#Invoke-Expression $cmdFinal
		if(!($?)){
			return "`nFAILURE : FATAL ERROR"
		}
	}
	else{
		$SANCObj = $SANConnection
		$CLIDir = $SANCObj.CLIDir	
		$clitestfile = $CLIDir + "\cli.exe"
		if (-not (Test-Path $clitestfile )) 
		{					
			return "FAILURE : HP3PAR cli.exe was not found. Make sure you have cli.exe file under $CLIDir "
		}
		$pwfile = $SANCObj.epwdFile
		$cmd2 = "help.bat"
		#$cmdFinal = "$cmd2 -sys $DeviceIPAddress -pwf $pwfile"
		#Invoke-Expression $cmdFinal
		& $cmd2 -sys $DeviceIPAddress -pwf $pwfile
		if(!($?)){
			return "`nFAILURE : FATAL ERROR"
		}
	}
	Write-DebugLog "Stop : in Test-PARCli function " "INFO:"
}

############################################################################################################################################
## FUNCTION TEST-CONNECTIONOBJECT
############################################################################################################################################

Function Test-ConnectionObject ($SANConnection)
{
<#
  .SYNOPSIS
    Validate connection object. For Internal Use only.
  
  .DESCRIPTION
	Validates if connection object for VC and OA are null/empty
        
  .EXAMPLE
    Test-ConnectionObject -SANConnection
	    
  .PARAMETER -SANConnection 
    Specify the VC or OA connection object. Ideally VC or Oa connection object is obtained by executing New-VCConnection or New-OAConnection.
	
  .Notes
    NAME:  Test-ConnectionObject
    LASTEDIT: 05/09/2012
    KEYWORDS: Test-ConnectionObject
   
  .Link
     http://www.hp.com
 
 #Requires PS -Version 3.0
 
 #>
	$Validate = "Success"
	if(($SANConnection -eq $null) -or (-not ($SANConnection.AdminName)) -or (-not ($SANConnection.Password)) -or (-not ($SANConnection.IPAddress)) -or (-not ($SANConnection.SSHDir)))
	{
		#Write-DebugLog "Connection object is null/empty or Connection object username,password,ipadress are null/empty. Create a valid connection object" "ERR:"
		$Validate = "Failed"		
	}
	return $Validate
}

Export-ModuleMember  Test-SSHSession , Set-DebugLog , Test-IPFormat , Test-Network , Invoke-3parCLI , Invoke-3parCLICmd , Test-FilePath , Test-PARCli , Test-PARCliTest, Test-ConnectionObject