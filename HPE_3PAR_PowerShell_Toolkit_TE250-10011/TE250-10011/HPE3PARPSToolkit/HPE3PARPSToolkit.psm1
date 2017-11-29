## ##################################################################################
## Copyright (c) Hewlett-Packard Enterprise Development Company, L.P. 2015
## 
##		File Name:		HPE3PARPSToolkit.psm1
##		Description: 	Module functions to automate management of HPE3PAR StoreServe Storage System
##		
##		Pre-requisites: Needs HPE3PAR cli.exe for New-3parCLIConnection
##						Needs SSH library for New-3ParPoshSshConnection
##
##		Created:		June 2015
##		Last Modified:	April 2017
##	
##		History:		V1.0 - Created
##						V2.0 - Added Replication,System Reporter,Sparing,Performance Management cmdlets
##							 - Added Disk Enclosure Management,System Management cmdlets
##						V3.0 - Added Commandlets for Real Madrid Release drivers
##							 - Support all parameters for the commandlets
##							VASA:
##								Get-3ParVVolSC
##								Show-3ParVVolum
##								Set-3ParVVolSC							
##							Replication :
##								Add-3parRcopytarget 
##								Add-3parRcopyVV 
##								Approve-3parRCopyLink
##								Test-3parRcopyLink
##								Sync-Recover3ParDRRcopyGroup
##								Disable-3ParRcopylink
##								Disable-3ParRcopytarget
##								Disable-3ParRcopyVV
##								Get-3parRCopy
##								New-3parRCopyGroup
##								New-3parRCopyGroupCPG
##								Remove-3parRCopyTargetFromGroup
##								Remove-3parRCopyVVFromGroup
##								Remove-3parRCopyGroup
##								Remove-3parRCopyTarget 
##								Set-3parRCopyGroupPeriod
##								Set-3parRCopyGroupPol
##								Set-3parRCopyTargetName
##								Set-3parRCopyTarget
##								Set-3parRCopyTargetPol
##								Set-3parRCopyTargetWitness
##								Show-3ParRcopyTransport
##								Start-3parRCopyGroup 								
##								Start-3parRcopy
##								Start-3parRCopyGroup
##								Get-3parStatRCopy
##								Stop-3parRCopy
##								Stop-3parRCopyGroup
##								Sync-3parRCopy								 
##							System Reporter cmdlets : 
##								Set-3parSRAlertCrit
##								Get-3ParHistRcopyVV
##								Get-3parSRAlertCrit
##								Get-3parSRAOMoves
##								Get-3parSRCPGSpace
##								Get-3parSRHistLD
##								Get-3parSRHistPD
##								Get-3parSRHistPort
##								Get-3parSRHistVLUN
##								Get-3parSRLDSpace
##								Get-3parSRPDSpace
##								Get-3parSRStatCache
##								Get-3parSRStatCMP
##								Get-3parSRStatCPU
##								Get-3parSRStatLD
##								Get-3parSRStatPD
##								Get-3parSRStatPort
##								Get-3parSRStatVLUN
##								Get-3parSRVVSpace
##								Get-3parVLUN
##								Show-3pariSCSIStatistics
##								Show-3pariSCSISessionStatistics
##								Show-3parSRSTATISCSISession
##								Show-3parSRStatIscsi
##							User Management cmdlet : 
##								Get-3parUserConnection
##							Disk Enclosure Management cmdlets : 
##								Approve-3parPD
##								Test-3parPD
##								Find-3parCage
##								Set-3parCage
##								Set-3parPD
##								Get-3parCage
##								Get-3parPD
##							Sparing cmdlets : 
##								New-3parSpare
##								Push-3parChunklet
##								Push-3parChunkletToSpare
##								Push-3parPD,Push-3parPDToSpare
##								Push-3parRelocPD
##								Remove-3parSpare
##								Get-3parSpare
##							System Management cmdlets :
##								Get-3parSR
##								Start-3parSR
##								Stop-3parSR
##							Performance Management cmdlets : 
##								Get-3parHistChunklet,
##								Get-3parHistLD
##								Get-3parHistPD
##								Get-3parHistPort
##								Get-3parHistRCopyVV
##								Get-3parHistVLUN
##								Get-3parHistVV
##								Get-3parStatChunklet
##								Get-3parStatCMP
##								Get-3parStatCPU
##								Get-3parStatLD
##								Get-3parStatLink
##								Get-3parStatPD
##								Get-3parStatPort
##								Get-3parStatRCVV
##								Get-3parStatVLUN
##								Get-3parStatVV
##								Compress-3parVV
##                          Volume Management :
##								Add-3parVV
##								Test-3parVV
##								Get-3parSpace
##								Import-3parVV
##								Remove-3parVLUN
##								Show-3parPeer
##								Update-3parVV
##							Node Subsystem Management :
##								Show-3parISCSISession
##								Show-3parPortARP
##								Show-3parPortISNS								
##						Major changes :
##							1. Added support for secure connections using HPE3PAR CLI and POSH SSH Library 
## 						
##
### ###################################################################################

$Script3PARName = $MyInvocation.MyCommand.Name
$Info = "INFO:"
$Debug = "DEBUG:"
$global:VSLibraries = Split-Path $MyInvocation.MyCommand.Path


Import-Module "$global:VSLibraries\Logger.psm1"
Import-Module "$global:VSLibraries\VS-Functions.psm1"

add-type @" 

public struct _SANConnection{
public string SessionId;
public string IPAddress;
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@ 

add-type @" 

public struct _TempSANConn{
public string SessionId;
public string IPAddress;
public string UserName;
public string epwdFile;
public string CLIDir;
public string CLIType;
}

"@ 

add-type @" 
public struct _vHost {
	public string Id;
	public string Name;
	public string Persona;
	public string Address;
	public string Port;
}

"@

add-type @" 
public struct _vLUN {
		public string Name;
		public string LunID;
		public string PresentTo;
		public string vvWWN;
}

"@

add-type @"
public struct _Version{
		public string ReleaseVersionName;
		public string Patches;
		public string CliServer;
		public string CliClient;
		public string SystemManager;
		public string Kernel;
		public string TPDKernelCode;
		
}
"@

############################################################################################################################################
## FUNCTION Test-3parObject
############################################################################################################################################

Function Test-3parobject 
{
Param( 	
    [string]$ObjectType, 
	[string]$ObjectName ,
	[string]$ObjectMsg = $ObjectType, 
	[_SANConnection]$SANCOnnection = $global:SANConnection
	)

	$IsObjectExisted = $True
	$ObjCmd = $ObjectType -replace ' ', '' 
	$Cmds = "show$ObjCmd $ObjectName"
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmds
	if ($Result -like "no $ObjectMsg listed")
	{
		$IsObjectExisted = $false
	}
	return $IsObjectExisted
	
} # End FUNCTION Test-3parObject

######################################################################################################################
## FUNCTION New-3ParPoshSshConnection
######################################################################################################################
Function New-3ParPoshSshConnection
{
<#
  .SYNOPSIS
    Builds a SAN Connection object using Posh SSH connection
  
  .DESCRIPTION
	Creates a SAN Connection object with the specified parameters. 
    No connection is made by this cmdlet call, it merely builds the connection object. 
        
  .EXAMPLE
    New-3ParPoshSshConnection -SANUserName Administrator -SANPassword mypassword -SANIPAddress 10.1.1.1 "
		Creates a SAN Connection object with the specified SANIPAddress
	
  .PARAMETER UserName 
    Specify the SAN Administrator user name. Ex: 3paradm
	
  .PARAMETER Password 
    Specify the SAN Administrator password 
	
   .PARAMETER SANIPAddress 
    Specify the SAN IP address.
              
  .Notes
    NAME:  New-3ParPoshSshConnection    
    LASTEDIT: 13/03/2017
    KEYWORDS: 3parSSHConnection
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $SANIPAddress=$null,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SANUserName=$null,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SANPassword=$null
		      
		)
		
		$Session
		
		# Check if our module loaded properly
		if (Get-Module -ListAvailable -Name Posh-SSH) 
		{ <# do nothing #> }
		else 
		{ 
			try
			{
				# install the module automatically
				iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
			}
			catch
			{
				#$msg = "Error occurred while installing POSH SSH Module. `nPlease check the internet connection.`nOr Install POSH SSH Module using given Link. `nhttp://www.powershellmagazine.com/2014/07/03/posh-ssh-open-source-ssh-powershell-module/  `n "
				$msg = "Error occurred while installing POSH SSH Module. `nPlease check if internet is enabled. If internet is enabled and you are getting this error, then refer the below link and install POSH SSH Module. `nhttp://www.powershellmagazine.com/2014/07/03/posh-ssh-open-source-ssh-powershell-module/  `n "
				 
				return "`nFAILURE : $msg"
			}
			
		}	
		
		#####
		Write-DebugLog "start: Entering function New-3ParPoshSshConnection. Validating IP Address format." $Debug
		
		# Check IP Address Format
		if(-not (Test-IPFormat $SANIPAddress))		
		{
			Write-DebugLog "Stop: Invalid IP Address $SANIPAddress" "ERR:"
			return "FAILURE : Invalid IP Address $SANIPAddress"
		}	
		
		
		<#
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile 
		
		#add one more parameter epwdFile to establish connection using password and epwdFile in single method 
		if($epwdFile)
		{	
			if($SANPassword)
			{
				return "`nIf you are using epwdFile option then no need to enter password `nUse only one option either epwdFile or SANPassword to stablish connection`n"
			}
			if( -not (Test-Path $epwdFile))
			{
				Write-DebugLog "Running: Path for HP3PAR encrypted password file  was not found. Now created new epwd file." "INFO:"
				return " Encrypted password file does not exist , create encrypted password file using 'Set-3parSSHConnectionPasswordFile' "
			}	
			
			Write-DebugLog "Running: Patch for HP3PAR encrypted password file ." "INFO:"
			
			$tempFile=$epwdFile			
			$Temp=import-CliXml $tempFile
			$pass=$temp[0]
			$ip=$temp[1]
			$user=$temp[2]
			if($ip -eq $SANIPAddress)  
			{
				if($user -eq $SANUserName)
				{
					$Passs = UnProtect-String $pass 
					$SANPassword = $Passs
				}
				else
				{ 
					Return "Password file SANUserName $user and entered SANUserName $SANUserName dose not match  . "
					Write-DebugLog "Running: Password file SANUserName $user and entered SANUserName $SANUserName dose not match ." "INFO:"
				}
			}
			else 
			{
				Return  "Password file ip $ip and entered ip $SANIPAddress dose not match"
				Write-DebugLog "Password file ip $ip and entered ip $SANIPAddress dose not match." "INFO:"
			}
			
		}
		#>
		# Authenticate
		try
		{
		
			if(!($SANPassword))
			{				
				$securePasswordStr = Read-Host "SANPassword" -AsSecureString				
				$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $securePasswordStr)
			}
			else
			{				
				$tempstring  = convertto-securestring $SANPassword -asplaintext -force				
				$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $tempstring)									
			}
			try
			{
				#$Session = New-SSHSession -ComputerName $SANIPAddress -Credential (Get-Credential $SANUserName)				
				$Session = New-SSHSession -ComputerName $SANIPAddress -Credential $mycreds		
			}
			catch 
			{	
				$msg = "In function New-3ParPoshSshConnection. "
				$msg+= $_.Exception.ToString()	
				# Write-Exception function is used for exception logging so that it creates a separate exception log file.
				Write-Exception $msg -error		
				return "FAILURE : $msg"
			}
			Write-DebugLog "Running: Executed . Check on PS console if there are any errors reported" $Debug
			if (!$Session)
			{
				return "FAILURE : New-SSHSession command fail."
			}
		}
		catch 
		{	
			$msg = "In function New-3ParPoshSshConnection. "
			$msg+= $_.Exception.ToString()	
			# Write-Exception function is used for exception logging so that it creates a separate exception log file.
			Write-Exception $msg -error		
			return "FAILURE : $msg"
		}
		
		
		$global:SANObjArr += @()
		$global:SANObjArr1 += @()
		#write-host "objarray",$global:SANObjArr
		#write-host "objarray1",$global:SANObjArr1
		if($global:SANConnection)
		{			
			#write-host "In IF loop"
			$SANC = New-Object "_SANConnection"
			$SANC.IPAddress = $SANIPAddress			
			$SANC.UserName = $SANUserName
			$SANC.epwdFile = "Secure String"			
			$SANC.SessionId = $Session.SessionId			
			$SANC.CLIType = "SshClient"
			$SANC.CLIDir = "Null"
			$global:SANConnection = $SANC
			
			###making multiple object support
			$SANC1 = New-Object "_TempSANConn"
			$SANC1.IPAddress = $SANIPAddress			
			$SANC1.UserName = $SANUserName
			$SANC1.epwdFile = "Secure String"		
			$SANC1.SessionId = $Session.SessionId			
			$SANC1.CLIType = "SshClient"
			$SANC1.CLIDir = "Null"
			
			$global:SANObjArr += @($SANC)
			$global:SANObjArr1 += @($SANC1)			
		}
		else
		{
		
			$global:SANObjArr = @()
			$global:SANObjArr1 = @()
			#write-host "In Else loop"
			
			
			$SANC = New-Object "_SANConnection"
			$SANC.IPAddress = $SANIPAddress			
			$SANC.UserName = $SANUserName
			$SANC.epwdFile = "Secure String"		
			$SANC.SessionId = $Session.SessionId
			$SANC.CLIType = "SshClient"
			$SANC.CLIDir = "Null"
			
			
			$global:SANConnection = $SANC		
			
			###making multiple object support
			$SANC1 = New-Object "_TempSANConn"
			$SANC1.IPAddress = $SANIPAddress			
			$SANC1.UserName = $SANUserName
			$SANC1.epwdFile = "Secure String"
			$SANC1.SessionId = $Session.SessionId
			$SANC1.CLIType = "SshClient"
			$SANC1.CLIDir = "Null"		
				
			$global:SANObjArr += @($SANC)
			$global:SANObjArr1 += @($SANC1)
		
		}
		Write-DebugLog "End: If there are no errors reported on the console then the SAN connection object is set and ready to be used" $Info
		return $SANC

 }# End Function New-3ParPoshSshConnection

############################################################################################################################################
## FUNCTION Get-ConnectedSession
############################################################################################################################################
function Get-ConnectedSession 
{
<#
  .SYNOPSIS
    Command Get-ConnectedSession display connected session detail
  .DESCRIPTION
	Command Get-ConnectedSession display connected session detail 
        
  .EXAMPLE
    Get-ConnectedSession

              
  .Notes
    NAME:  Get-ConnectedSession    
    LASTEDIT: 13/03/2017
    KEYWORDS: Get-ConnectedSession 
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>

    Begin{}
    Process
    {       
		$connection = [_SANConnection]$global:SANConnection	
		return $connection
    }
    End{}
}


############################################################################################################################################
## FUNCTION NEW-3PARCLICONNECTION
############################################################################################################################################
Function New-3parCLIConnection
{
<#
  .SYNOPSIS
    Builds a SAN Connection object using HPE3par CLI.
  
  .DESCRIPTION
	Creates a SAN Connection object with the specified parameters. 
    No connection is made by this cmdlet call, it merely builds the connection object. 
        
  .EXAMPLE
    New-3parCLIConnection  -SANIPAddress 10.1.1.1 -CLIDir "C:\cli.exe" -epwdFile "C:\HPE3parepwdlogin.txt"
		Creates a SAN Connection object with the specified SANIPAddress
	
	
  .PARAMETER SANIPAddress 
    Specify the SAN IP address.
    
  .PARAMETER CLIDir 
    Specify the absolute path of HPE3par cli.exe. Default is "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin"
  
  .PARAMETER epwdFile 
    Specify the encrypted password file location , example “c:\HPE3parstoreserv244.txt” To create encrypted password file use “Set-3parPassword” cmdlet           
	
  .Notes
    NAME:  New-3parCLIConnection    
    LASTEDIT: 04/04/2012
    KEYWORDS: 3parCLIConnection
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE3par cli.exe 
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $SANIPAddress=$null,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        #$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile="C:\HPE3parepwdlogin.txt"
       
	) 

		Write-DebugLog "start: Entering function New-3parCLIConnection. Validating IP Address format." $Debug
		# Check IP Address Format
		if(-not (Test-IPFormat $SANIPAddress))		
		{
			Write-DebugLog "Stop: Invalid IP Address $SANIPAddress" "ERR:"
			return "FAILURE : Invalid IP Address $SANIPAddress"
		}		
		
		Write-DebugLog "Running: Completed validating IP address format." $Debug		
		Write-DebugLog "Running: Authenticating credentials - Invoke-3parCLI for user $SANUserName and SANIP= $SANIPAddress" $Debug
		$test = $env:Path		
		$test1 = $test.split(";")		
		if ($test1 -eq $CLIDir)
		{
			Write-DebugLog "Running: Environment variable path for $CLIDir already exists" "INFO:"			
		}
		else
		{
			Write-DebugLog "Running: Environment variable path for $CLIDir does not exists, so added $CLIDir to environment" "INFO:"
			$env:Path += ";$CLIDir"
		}
		if (-not (Test-Path -Path $CLIDir )) 
		{		
			Write-DebugLog "Stop: Path for HPE3par cli was not found. Make sure you have installed HPE3par CLI." "ERR:"			
			return "FAILURE : Path for HPE3par cli was not found. Make sure you have cli.exe file under $CLIDir"
		}
		$clifile = $CLIDir + "\cli.exe"		
		if( -not (Test-Path $clifile))
		{
			Write-DebugLog "Stop: Path for HPE3par cli was not found.Please enter only directory path with out cli.exe & Make sure you have installed HPE3par CLI." "ERR:"			
			return "FAILURE : Path for HPE3par cli was not found,Make sure you have cli.exe file under $CLIDir"
		}
		#write-host "Set HPE3par CLI path if not"
		# Authenticate		
		try
		{
			if( -not (Test-Path $epwdFile))
			{
				write-host "Encrypted password file does not exist , creating encrypted password file"				
				Set-3parPassword -CLIDir $CLIDir -SANIPAddress $SANIPAddress -epwdFile $epwdFile
				Write-DebugLog "Running: Path for HPE3par encrypted password file  was not found. Now created new epwd file." "INFO:"
			}
			#write-host "pwd file : $epwdFile"
			Write-DebugLog "Running: Path for HPE3par encrypted password file  was already exists." "INFO:"
			$global:epwdFile = $epwdFile	
			$Result9 = Invoke-3parCLI -DeviceIPAddress $SANIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -cmd "showversion" 
			Write-DebugLog "Running: Executed Invoke-3parCLI. Check on PS console if there are any errors reported" $Debug
			if ($Result9 -match "FAILURE"){
				return $Result9
			}
		}
		catch 
		{	
			$msg = "In function New-3parCLIConnection. "
			$msg+= $_.Exception.ToString()	
			# Write-Exception function is used for exception logging so that it creates a separate exception log file.
			Write-Exception $msg -error		
			return "FAILURE : $msg"
		}
		
		$global:SANObjArr += @()
		#write-host "objarray",$global:SANObjArr

		if($global:SANConnection)
		{			
			#write-host "In IF loop"
			$SANC = New-Object "_SANConnection"  
			# Get the username
			$connUserName = Get-3parUserConnectionTemp -SANIPAddress $SANIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -Option current
			$SANC.UserName = $connUserName.Name
			$SANC.IPAddress = $SANIPAddress
			$SANC.CLIDir = $CLIDir	
			$SANC.epwdFile = $epwdFile		
			$SANC.CLIType = "3parcli"
			$SANC.SessionId = "NULL"
			$global:SANConnection = $SANC
			$global:SANObjArr += @($SANC)
		}
		else
		{
		
			$global:SANObjArr = @()
			#write-host "In Else loop"			
			
			$SANC = New-Object "_SANConnection"       
			$connUserName = Get-3parUserConnectionTemp -SANIPAddress $SANIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -Option current
			$SANC.UserName = $connUserName.Name
			$SANC.IPAddress = $SANIPAddress
			$SANC.CLIDir = $CLIDir
			$SANC.epwdFile = $epwdFile
			$SANC.CLIType = "3parcli"
			$SANC.SessionId = "NULL"
			#New-3parConnection -SANConnection $SANC
			#making this object as global
			$global:SANConnection = $SANC				
			$global:SANObjArr += @($SANC)		
		}
		Write-DebugLog "End: If there are no errors reported on the console then the SAN connection object is set and ready to be used" $Info
		return $SANC

} # End Function New-3parCLIConnection

######################################################################################################################
## FUNCTION Get-3parUserConnectionTemp
######################################################################################################################
Function Get-3parUserConnectionTemp
{
<#
  .SYNOPSIS
    Displays information about users who are currently connected (logged in) to the storage system.
  
  .DESCRIPTION
	Displays information about users who are currently connected (logged in) to the storage system.
        
  .EXAMPLE
    Get-3parUserConnection  -SANIPAddress 10.1.1.1 -CLIDir "C:\cli.exe" -epwdFile "C:\HPE3parepwdlogin.txt" -Option current
		Shows all information about the current connection only.
  .EXAMPLE
    Get-3parUserConnection  -SANIPAddress 10.1.1.1 -CLIDir "C:\cli.exe" -epwdFile "C:\HPE3parepwdlogin.txt" 
	 Shows information about users who are currently connected (logged in) to the storage system.
	 
  .PARAMETER SANIPAddress 
    Specify the SAN IP address.
    
  .PARAMETER CLIDir 
    Specify the absolute path of HPE3par cli.exe. Default is "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin"
  
  .PARAMETER epwdFile 
    Specify the encrypted password file , if file does not exists it will create encrypted file using deviceip,username and password  
	
  .PARAMETER Option
    current
        Shows all information about the current connection only.

  .Notes
    NAME:   Get-3parUserConnectionTemp
    LASTEDIT: 04/04/2015
    KEYWORDS:  Get-3parUserConnectionTemp
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE3par cli.exe 
 #>
 
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=1,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$SANIPAddress=$null,
		[Parameter(Position=2,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$epwdFile ="C:\HPE3parepwdlogin.txt",
		[Parameter(Position=3,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$Option 
      
	)	
	#write-host "In connection"
	if( Test-Path $epwdFile)
	{
		Write-DebugLog "Running: HPE3par encrypted password file was found , it will use the mentioned file" "INFO:"
	}
	$passwordFile = $epwdFile
	$cmd1 = $CLIDir+"\showuserconn.bat"
	$cmd2 = "showuserconn "
	$options1 = "current"
	if(!($options1 -eq $option))
	{
		return "FAILURE : option should be in ( $options1 )"
	}
	if($option -eq "current")
	{
		$cmd2 += " -current "
	}
	#& $cmd1 -sys $SANIPAddress -file $passwordFile
	$result = Invoke-3parCLI -DeviceIPAddress $SANIPAddress -CLIDir $CLIDir -epwdFile $epwdFile -cmd $cmd2
	$count = $result.count - 3
	$tempFile = [IO.Path]::GetTempFileName()
	Add-Content -Path $tempfile -Value "Id,Name,IP_Addr,Role,Connected_since,Current,Client,ClientName"
	foreach($s in $result[1..$count]){
		$s= [regex]::Replace($s,"^ +","")
		$s= [regex]::Replace($s," +"," ")
		$s= [regex]::Replace($s," ",",")
		$s = $s.trim()
		Add-Content -Path $tempfile -Value $s
	}
	Import-CSV $tempfile		
}

######################################################################################################################
## FUNCTION Get-3parUserConnection
######################################################################################################################
Function Get-3parUserConnection{
<#
  .SYNOPSIS
    Displays information about users who are currently connected (logged in) to the storage system.
  
  
  .DESCRIPTION
	Displays information about users who are currently connected (logged in) to the storage system.
    
  .EXAMPLE
    Get-3parUserConnection  
	 Shows information about users who are currently connected (logged in) to the storage system.
	 
  .EXAMPLE
    Get-3parUserConnection   -Option current
		Shows all information about the current connection only.
   
  .EXAMPLE
    Get-3parUserConnection   -Option d
		Specifies the more detailed information about the user connection
	
  .PARAMETER Option
    current
        Shows all information about the current connection only.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with New-3ParPoshSshConnection or New-3parCLICOnnection
	
  .Notes
    NAME:   Get-3parUserConnection
    LASTEDIT: 04/04/2015
    KEYWORDS:  Get-3parUserConnection
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE3par cli.exe 
 #>
 
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$Option ,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
      
	)
	Write-DebugLog "Start: In Get-3parUserConnection - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parUserConnection since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parUserConnection since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$cmd2 = "showuserconn "
	
	if ($option)
	{
		$a = "current","d"
		$l=$option
		if($a -eq $l)
		{
			$cmd2+=" -$option "	
			if ($option -eq "d")
			{
				$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
				return $result
			}
		} 
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parUserConnection   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [i]  can be used only . "
		}
	}	
	$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
	$count = $result.count - 3
	$tempFile = [IO.Path]::GetTempFileName()
	Add-Content -Path $tempfile -Value "Id,Name,IP_Addr,Role,Connected_since_Date,Connected_since_Time,Connected_since_TimeZone,Current,Client,ClientName"
	foreach($s in $result[1..$count]){
		$s= [regex]::Replace($s,"^ +","")
		$s= [regex]::Replace($s," +"," ")
		$s= [regex]::Replace($s," ",",")
		$s = $s.trim()
		Add-Content -Path $tempfile -Value $s
	}
	Import-CSV $tempfile	
} #End Get-3parUserConnection
######################################################################################################################
## FUNCTION Set-3parPassword
######################################################################################################################
Function Set-3parPassword
{
<#
  .SYNOPSIS
   Creates a encrypted password file on client machine
  
  .DESCRIPTION
	Creates a encrypted password file on client machine
        
  .EXAMPLE
    Set-3parPassword -CLIDir "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin" -SANIPAddress "15.212.196.218"  -epwdFile "C:\HPE3paradmepwd.txt"
	
	This examples stores the encrypted password file HPE3paradmepwd.txt on client machine c:\ drive, subsequent commands uses this encryped password file 
	 
  .PARAMETER SANIPAddress 
    Specify the SAN IP address.
    
  .PARAMETER CLIDir 
    Specify the absolute path of HPE3par cli.exe. Default is "C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin"
  
  .PARAMETER epwdFile 
    Specify the file location to create encrypted password file
	
  .Notes
    NAME:   Set-3parPassword
    LASTEDIT: 04/04/2015
    KEYWORDS:  Set-3parPassword
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE3par cli.exe 
 #>
 
[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=$false, ValueFromPipeline=$true)]
		[System.string]
		$CLIDir="C:\Program Files (x86)\Hewlett Packard Enterprise\HPE 3PAR CLI\bin",
		[Parameter(Position=1,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$SANIPAddress=$null,
		[Parameter(Position=2,Mandatory=$true, ValueFromPipeline=$true)]
		[System.string]
		$epwdFile ="C:\HPE3parepwdlogin.txt"
       
	)	
	#write-host "In connection"
	if( Test-Path $epwdFile)
	{
		Write-DebugLog "Running: HPE3par encrypted password file was found , it will overwrite the mentioned file" "INFO:"
	}	
	$passwordFile = $epwdFile	
	$cmd1 = $CLIDir+"\setpassword.bat" 
	& $cmd1 -saveonly -sys $SANIPAddress -file $passwordFile
	if(!($?	))
	{
		Write-DebugLog "STOP: HPE3par System's  cli dir path or system is not accessible or commands.bat file path was not configured properly " "ERR:"
		return "`nFAILURE : FATAL ERROR"
	}
	#$cmd2 = "setpassword.bat -saveonly -sys $SANIPAddress -file $passwordFile"
	#Invoke-expression $cmd2
	$global:epwdFile = $passwordFile
	Write-DebugLog "Running: HPE3par System's encrypted password file has been created successfully and the file location is $passwordfile " "INFO:"
	return "SUCCESS : HPE3par System's encrypted password file has been created  successfully and the file location : $passwordfile"

} #End Set-3parPassword

############################################################################################################################################
## FUNCTION Set-3parHostPorts
############################################################################################################################################

Function Set-3parHostPorts
{
<#
  	.SYNOPSIS
		Configure settings of the 3PAR array.

	.DESCRIPTION
		Configures 3PAR with settings specified in the text file.
 
   	.PARAMETER FCConfigFile
		Specify the config file containing FC host controllers information
		
   	.PARAMETER iSCSIConfigFile
		Specify the config file containing iSCSI host controllers information
		
   	.PARAMETER LDConfigFile
		Specify the config file containing Logical Disks information
		
	.PARAMETER Demo
		Switch to list the commands to be executed 
		
	.PARAMETE RCIPConfiguration
		go for  RCIP Configuration
		
	.PARAMETE RCFCConfiguration
		go for  RCFC Configuration
		
	.PARAMETE Port_IP
		port ip address
		
	.PARAMETE NetMask
		Net Mask Name
		
	.PARAMETE NSP
		NSP Name
  	
	.EXAMPLE
    	Set-3parHostPorts -FCConfigFile FC-Nodes.CSV
		Configures all FC host controllers on  3PAR array
	.EXAMPLE	
    	Set-3parHostPorts -iSCSIConfigFile iSCSI-Nodes.CSV
		Configures all iSCSI host controllers on  3PAR array
	.EXAMPLE
	    Set-3parHostPorts -LDConfigFile LogicalDisks.CSV
		Configures logical disks on 3PAR array
	.EXAMPLE	
    	Set-3parHostPorts -FCConfigFile FC-Nodes.CSV -iSCSIConfigFile iSCSI-Nodes.CSV -LDConfigFile LogicalDisks.CSV
		Configures FC, iSCSI host controllers and logical disks on 3PAR array
		
	.EXAMPLE	
		Set-3parHostPorts -RCIPConfiguration -Port_IP 0.0.0.0 -NetMask xyz -NSP 1:2:3>
		for rcip port
	
	.EXAMPLE	
		Set-3parHostPorts -RCFCConfiguration -NSP 1:2:3>
		For RCFC port

			
  .Notes
    NAME:  Set-3parHostPorts    
    LASTEDIT: June 2012
    KEYWORDS: Set-3parHostPorts  
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe
 #>
 
[CmdletBinding()]
	Param(
			[Parameter()]
			[System.String]
			$FCConfigFile,
			
			[Parameter()]
			[System.String]
			$iSCSIConfigFile,		
			
			[Parameter()]
			[System.String]
			$LDConfigFile,

			[Parameter()]
			[switch]
			$RCIPConfiguration,
			
			[Parameter()]
			[switch]
			$RCFCConfiguration,
			
			[Parameter()]
			[System.String]
			$Port_IP,
			
			[Parameter()]
			[System.String]
			$NetMask,
			
			[Parameter()]
			[System.String]
			$NSP,
			
			[Parameter()]
			[_SANConnection]
			$SANConnection = $global:SANConnection,
			
			[Parameter(Position=2)]
			[switch]$Demo

		)

Write-DebugLog "Start: In Set-3PARHostPorts- validating input values" $Debug 
#check if connection object contents are null/empty
if(!$SANConnection)
{	
	#check if connection object contents are null/empty
	$Validate1 = Test-ConnectionObject $SANConnection
	if($Validate1 -eq "Failed")
	{
		#check if global connection object contents are null/empty
		$Validate2 = Test-ConnectionObject $global:SANConnection
		if($Validate2 -eq "Failed")
		{
			Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
			Write-DebugLog "Stop: Exiting Set-3PARHostPorts since SAN connection object values are null/empty" $Debug
			return " FAILURE : Exiting Set-3PARHostPorts since SAN connection object values are null/empty"
		}
	}
}
$plinkresult = Test-PARCli -SANConnection $SANConnection 
if($plinkresult -match "FAILURE :")
{
	write-debuglog "$plinkresult" "ERR:" 
	return $plinkresult
}

# ---------------------------------------------------------------------
#		FC Config file here
if (!(($FCConfigFile) -or ($iSCSIConfigFile) -or ($LDConfigFile) -or ($RCIPConfiguration) -or ($RCFCConfiguration))) 
{
	return "FAILURE : no configfile selected"
}
if ($RCIPConfiguration)
{
	$Cmds="controlport rcip addr -f "
	if($Port_IP)
	{
		$Cmds=" $Port_IP "
	}
	else
	{
		return "port_IP required with RCIPConfiguration Option"
	}
	if($NetMask)
	{
		$Cmds=" $NetMask "
	}
	else
	{
		return "NetMask required with RCIPConfiguration Option"
	}
	if($NSP)
	{
		$Cmds=" $NSP "
	}
	else
	{
		return "NSP required with RCIPConfiguration Option"
	}
	$result = Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
	return $result
}
if ($RCFCConfiguration)
{
	$Cmds="controlport rcfc init -f "	
	if($NSP)
	{
		$Cmds=" $NSP "
	}
	else
	{
		return "NSP required with RCFCConfiguration Option"
	}
	$result = Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
	return $result
}
if ($FCConfigFile)
{
	if ( -not (Test-Path -path $FCConfigFile)) 
	{
		Write-DebugLog "Configuring FC hosts using configuration file $FCConfigFile" $Info
		
		$ListofFCPorts = Import-Csv $FCConfigFile
		foreach ( $p in $ListofFCPorts)
		{
			$Port = $p.Controller 

			Write-DebugLog "Set port $Port offline " $Info
			$Cmds = "controlport offline -f $Port"
			Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
			
			Write-DebugLog "Configuring port $Port as host " $Info
			$Cmds= "controlport config host -ct point -f $Port"
			Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds

			Write-DebugLog "Resetting port $Port " $Info
			$Cmds="controlport rst -f $Port"
			Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
		}
	}	
	else
	{
		Write-DebugLog "Can't find $FCConfigFile" "ERR:"
	}	
}

# ---------------------------------------------------------------------
#		iSCSI Config file here
if ($iSCSIConfigFile)
{
	if ( -not (Test-Path -path $iSCSIConfigFile)) 
	{
		Write-DebugLog "Configuring iSCSI hosts using configuration file $iSCSIConfigFile" $Info
		
		$ListofiSCSIPorts = Import-Csv $iSCSIConfigFile		
	
		foreach ( $p in $ListofiSCSIPorts)
		{
			$Port 		= $p.Controller
			$bDHCP 		= $p.DHCP
			$IPAddr 	= $p.IPAddress
			$IPSubnet 	= $p.Subnet
			$IPgw 		= $p.Gateway		
			if ( $bDHCP -eq "Yes")
				{ $bDHCP = $true }
			else
				{ $bDHCP = $false }
			
			if ($bDHCP)
			{
				Write-DebugLog "Enabling DHCP on port $Port " $Info
				$Cmds = "controliscsiport dhcp on -f $Port"
				Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds			
			}
			else
			{
				Write-DebugLog "Setting IP address and subnet on port $Port " $Info
				$Cmds = "controliscsiport addr $IPAddr $IPSubnet -f $Port"
				Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
				
				Write-DebugLog "Setting gateway on port $Port " $Info
				$Cmds = "controliscsiport gw $IPgw -f $Port"
				Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
			}	
		
		}
	}	
	else
	{
		Write-DebugLog "Can't find $iSCSIConfigFile" "ERR:"
		return "FAILURE : Can't find $iSCSIConfigFile"
	}	
}			
} # End Function Set-3parHostPorts

############################################################################################################################################
## FUNCTION Ping-3parRCIPPorts
############################################################################################################################################

Function Ping-3parRCIPPorts
{
<#
  	.SYNOPSIS
		Verifying That the Servers Are Connected

	.DESCRIPTION
		Verifying That the Servers Are Connected.
 
   	.PARAMETER IP_address
	IP address on the secondary system to ping
	
	.PARAMETER NSP
	Interface from which to ping, expressed as node:slot:port	
		
	.EXAMPLE	
		Ping-3parRCIPPorts -IP_address 0.0.0.0 -NSP 1:2:3

			
  .Notes
    NAME:  Ping-3parRCIPPorts    
    LASTEDIT: March 2017
    KEYWORDS: Ping-3parRCIPPorts  
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe
 #>
 
[CmdletBinding()]
	Param(			
			[Parameter()]
			[System.String]
			$IP_address,
			
			[Parameter()]
			[System.String]
			$NSP,
			
			[Parameter()]
			[_SANConnection]
			$SANConnection = $global:SANConnection
		)

Write-DebugLog "Start: In Set-3PARHostPorts- validating input values" $Debug 
#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3PARHostPorts since SAN connection object values are null/empty" $Debug
				return " FAILURE : Exiting Set-3PARHostPorts since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$Cmds="controlport rcip ping "
	if($IP_address)
	{
		$Cmds=" $IP_address "
	}
	else
	{
		return "IP_address required "
	}
	
	if($NSP)
	{
		$Cmds=" $NSP "
	}
	else
	{
		return "NSP required with "
	}
	$result = Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds	
	return $result
} # End Function Ping-3parRCIPPorts

############################################################################################################################################
## FUNCTION GET-3parHOSTPORTS
############################################################################################################################################

Function Get-3parHostPorts
{
<#
  	.SYNOPSIS
		Query 3PAR to get all ports including targets, disks, and RCIP ports.

	.DESCRIPTION
		Get information for 3PAR Ports
	
	.PARAMETER option
	
	-i
        Shows port hardware inventory information.

    -c
        Displays all devices connected to the port. Such devices include cages
        (for initiator ports), hosts (for target ports) and ports from other
        storage system (for RCFC and peer ports).

    -par
        Displays a parameter listing such as the configured data rate of a port
        and the maximum data rate that the card supports. Also shown is the
        type of attachment (Direct Connect or Fabric Attached) and whether the
        unique_nwwn and VCN capabilities are enabled.

    -rc
        Displays information that is specific to the Remote Copy ports.

    -rcfc
        Displays information that is specific to the Fibre Channel Remote Copy
        ports.

    -peer
        Displays information that is specific to the Fibre Channel ports for
        Data Migration.

    -rcip
        Displays information specific to the Ethernet Remote Copy ports.

    -iscsi
        Displays information about iSCSI ports.

    -iscsiname
        Displays iSCSI names associated with iSCSI ports.

    -iscsivlans
        Displays information about VLANs on iSCSI ports.

    -fcoe
        Displays information that is specific to Fibre Channel over Ethernet
        (FCoE) ports.

    -sfp
        Displays information about the SFPs attached to ports.

    -ddm
        Displays Digital Diagnostics Monitoring (DDM) readings from the SFPs if
        they support DDM. This option must be used with the -sfp option.

    -d
        Displays detailed information about the SFPs attached to ports. This
        option is used with the -sfp option.

    -failed
        Shows only failed ports.

    -state
        Displays the detailed state information. This is the same as -s.

    -s
        Displays the detailed state information.
        This option is deprecated and will be removed in a subsequent release.

    -ids
        Displays the identities hosted by each physical port.

    -fs
        Displays information specific to the Ethernet File Persona ports.
        To see IP address, netmask and gateway information on File Persona,
        run "showfs -net".    
		
	.PARAMETER Demo
		Switch to list the commands to be executed 
		
	.PARAMETER NSP
		Nede sloat poart
  	
	.EXAMPLE
    	Get-3parHostPorts
			Lists all ports including targets, disks, and RCIP ports
			
  .Notes
    NAME:  Get-3parHostPorts  
    LASTEDIT: June 2012
    KEYWORDS: Get-3parHostPorts
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter(Position=0, Mandatory=$false)]
			[System.String]
			$option,
			
			[Parameter(Position=1, Mandatory=$false)]
			[System.String]
			$NSP,
			
			[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
            $SANConnection = $global:SANConnection,
			
			[Parameter(Position=3)]
			[switch]$Demo
		)

	Write-DebugLog "Start: In Get-3PARHostPorts- validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3PARHostPorts since 3PAR connection object values are null/empty" $Debug
				return
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}

	$Cmds = "showport"	
	if ($option)
	{
		$a = "i","par","rc","rcfc","rcip","peer","iscsi","iscsiname","iscsivlans","fcoe","sfp","failed","state","s","ids","fs"
		$l=$option
		if($a -eq $l)
		{
			$Cmds+=" -$option "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parHostPorts   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [ i | par | rc | rcfc | rcip | peer | iscsi | iscsiname | iscsivlans | fcoe | sfp | failed | state | s | ids | fs]  can be used only . "
		}
	}	
	if($NSP)
	{
		$Cmds+=" $NSP"
	}
	$Result=Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds 
	
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count -2  
	
	if($Result -match "N:S:P")
	{
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= [regex]::Replace($s,"\s+",",") 		
			$s= [regex]::Replace($s,"/HW_Addr","") 
			$s= [regex]::Replace($s,"N:S:P","Device")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s				
		}
		
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return  $Result
	}
	
	if($Result -match "N:S:P")
	{
		return  " SUCCESS : EXECUTING Get-3parHostPorts"
	}
	else
	{			
		return  $Result
	}	

} # END FUNCTION Get-3parHostPorts



############################################################################################################################################
## FUNCTION GET-3parFCPORTSToCSV
############################################################################################################################################

Function Get-3parFCPortsToCSV
{
<#
  	.SYNOPSIS
		Query 3PAR to get FC ports

	.DESCRIPTION
		Get information for 3PAR FC Ports
 
	.PARAMETER ResultFile
		CSV file created that contains all Ports definitions
		
	.PARAMETER Demo
		Switch to list the commands to be executed 
  	
	.EXAMPLE
    	Get-3parFCPortsToCSV -ResultFile C:\3PAR-FC.CSV
			creates C:\3PAR-FC.CSV and stores all FCPorts information
			
  .Notes
    NAME:  Get-3parFCPortsToCSV
    LASTEDIT: June 2012
    KEYWORDS: Get-3parFCPortsToCSV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter()]
			[_SANConnection]
			$SANConnection = $global:SANConnection,
			
			[Parameter()]
			[String]$ResultFile
		)

	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if(!($ResultFile)){
		return "FAILURE : Please specify csv file path `n example: -ResultFIle C:\portsfile.csv"
	}	
	Set-Content -Path $ResultFile -Value "Controller,WWN,SWNumber"

	$ListofPorts = Get-3PARHostPorts -SANConnection $SANConnection| where { ( $_.Type -eq "host" ) -and ($_.Protocol -eq "FC")}
	if (!($ListofPorts)){
		return "FAILURE : No ports to display"
	}

	$Port_Pattern = "(\d):(\d):(\d)"							# Pattern matches value of port: 1:2:3
	$WWN_Pattern = "([0-9a-f][0-9a-f])" * 8						# Pattern matches value of WWN

	foreach ($Port in $ListofPorts)
	{
		$NSP  = $Port.Device
		$SW = $NSP.Split(':')[-1]
		if ( [Bool]($SW % 2) )			# Check whether the number is odd
		{
			$SwitchNumber = 1
		}
		else
		{
			$SwitchNumber = 2
		}
		
		
		$NSP = $NSP -replace $Port_Pattern , 'N$1:S$2:P$3'
		
		$WWN = $Port.Port_WWN
		$WWN = $WWN -replace $WWN_Pattern , '$1:$2:$3:$4:$5:$6:$7:$8'

		Add-Content -Path $ResultFile -Value "$NSP,$WWN,$SwitchNumber"
	}
	Write-DebugLog "FC ports are stored in $ResultFile" $Info
	return "SUCCESS: FC ports information stored in $ResultFile"
} # END FUNCTION Get-3parFCPortsToCSV


############################################################################################################################################
## FUNCTION GET-3parFCPORTS
############################################################################################################################################

Function Get-3parFCPORTS
{
<#
  	.SYNOPSIS
		Query 3PAR to get FC ports

	.DESCRIPTION
		Get information for 3PAR FC Ports
 
	.PARAMETER SANConnection
		Connection String to the 3PAR array
  	
	.EXAMPLE
    	Get-3parFCPORTS 
			
  .Notes
    NAME:  Get-3parFCPORTS
    LASTEDIT: June 2012
    KEYWORDS: Get-3parFCPORTS
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter()]
			[_SANConnection]
			$SANConnection=$Global:SANConnection

		)
	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
			
Write-Host "--------------------------------------`n"
Write-host "Controller,WWN"

$ListofPorts = Get-3PARHostPorts -SANConnection $SANConnection| where { ( $_.Type -eq "host" ) -and ($_.Protocol -eq "FC")}

$Port_Pattern = "(\d):(\d):(\d)"							# Pattern matches value of port: 1:2:3
$WWN_Pattern = "([0-9a-f][0-9a-f])" * 8						# Pattern matches value of WWN

foreach ($Port in $ListofPorts)
{
	$NSP  = $Port.Device
	$SW = $NSP.Split(':')[-1]	
	
	$NSP = $NSP -replace $Port_Pattern , 'N$1:S$2:P$3'
	
	$WWN = $Port.Port_WWN
	$WWN = $WWN -replace $WWN_Pattern , '$1:$2:$3:$4:$5:$6:$7:$8'

	Write-Host "$NSP,$WWN"
}


} # END FUNCTION Get-3parFCPORTS


############################################################################################################################################
## FUNCTION SET-3parFCPORTS
############################################################################################################################################

Function Set-3parFCPORTS
{
<#
  	.SYNOPSIS
		Configure 3PAR FC ports

	.DESCRIPTION
		Configure 3PAR FC ports
 		
	.PARAMETER Port
		HPE3par port. Use syntax N:S:P
	
	.PARAMETER DirectConnect
		If present, configure port for a direct connection to a host
		By default, the port is configured as fabric attached
  	
	.EXAMPLE
    	Set-3parFCPORTS -Ports 1:2:1
		Configure 3PAR port 1:2:1 as Fibre Channel connected to a fabric 
	.EXAMPLE
    	Set-3parFCPORTS -Ports 1:2:1 -DirectConnect
		Configure 3PAR port 1:2:1 as Fibre Channel connected to host ( no SAN fabric) 
	.EXAMPLE		
		Set-3parFCPORTS -Ports 1:2:1,1:2:2 
		Configure 3PAR ports 1:2:1 and 1:2:2 as Fibre Channel connected to a fabric 
		
  .Notes
    NAME:  Set-3parFCPORTS
    LASTEDIT: Nov 2012
    KEYWORDS: Set-3parFCPORTS
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE 3par cli.exe
 #>
 
[CmdletBinding()]
	Param(	
			[Parameter()]
			[_SANConnection]
			$SANConnection = $global:SANConnection,
			
			[Parameter()]
			[String[]]$Ports,
			
			[Parameter()]
			[Switch]$DirectConnect,
			
			[Parameter()]
			[switch]$Demo
		)
$Port_Pattern = "(\d):(\d):(\d)"	

foreach ($P in $Ports)
{
	if ( $p -match $Port_Pattern)
	{
		Write-DebugLog "Set port $p offline " $Info
		$Cmds = "controlport offline -f $p"
		Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds
		
		$PortConfig = "point"
		$PortMsg    = "Fabric ( Point mode)"
		
		if ($DirectConnect)
		{
			$PortConfig = "loop"
			$PortMsg    = "Direct connection ( loop mode)"
		}
		Write-DebugLog "Configuring port $p as $PortMsg " $Info
		$Cmds= "controlport config host -ct $PortConfig -f $p"
		Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds

		Write-DebugLog "Resetting port $p " $Info
		$Cmds="controlport rst -f $p"
		Invoke-3parCLICmd -Connection $SANConnection  -cmds $Cmds	
		
		Write-DebugLog "FC port $P is configured" $Info
		return "SUCCESS : FC port $P is configured"
	}
	else
	{
		Write-DebugLog "Port $p is not in correct format N:S:P. No action is taken" $Info
		return "FAILURE : Port $p is not in correct format N:S:P. No action is taken"
	}	
}


} # END FUNCTION Set-3parFCPORTS

#EndRegion Host configuration

#Region LUN Provisionning

############################################################################################################################################
## FUNCTION NEW-3parCPG
############################################################################################################################################

Function New-3parCPG
{
<#
  .SYNOPSIS
    Creates a new CPG
  
  .DESCRIPTION
	 Creates a new CPG
        
  .EXAMPLE
    New-3parCPG -cpgName "MyCPG" -Size 32G	-RAIDType r1 
	 Creates a CPG named MyCPG with initial size of 32GB and Raid configuration is r1 (RAID 1)
	
  .PARAMETER cpgName 
    Specify new name of the CPG
	
  .PARAMETER Size 
    Specify the size of the new GPG. Valid input is: 1 for 1 MB , 1g or 1G for 1GB , 1t or 1T for 1TB
	
  .PARAMETER RaidType 
    Specify the Raid Type for CPG. Valid input is  r1 , r5
	
  .PARAMETER Domain 	
	    -domain <domain>
        Specifies the name of the domain with which the object will reside. The object must be created by a member of a particular domain with Edit or Super role. The default is to create it in the current domain, or  no domain if the current domain is not set.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
		
              
  .Notes
    NAME:  New-3parCPG 
    LASTEDIT: 15/11/2015
    KEYWORDS: New-3parCPG
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$cpgName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Size="8G", 	# Default is 32GB
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $RAIDType = "r1",
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Domain,		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In new-CPG - validating input values" $Debug 

	if(!($cpgName))
	{
		write-debuglog " No CPG name specified  - No action required" "INFO:"
		Get-Help New-3parCPG
		return
	}
	#####
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting new-3parCPG since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting new-3parCPG since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection 
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	# --------- Check whether CPG already exists

	$RAIDType = $RAIDType.ToLower()
	
	write-debuglog "Executing command --> showcpg to check whether the CPG name exists" "DEBUG:" 
	write-debuglog " Result is $result" "DEBUG:"
	
	if ( !( test-3PARObject -objectType cpg -objectName $cpgName -SANConnection $SANConnection ))
	{	
		if($Domain)
		{			
			$CreateCPGCmd = "createcpg -aw 0 -sdgs $Size -sdgl 0 -sdgw 0 -t $RAIDType -domain $Domain $cpgName"
		}
		else
		{		
			$CreateCPGCmd = "createcpg -aw 0 -sdgs $Size -sdgl 0 -sdgw 0 -t $RAIDType $cpgName" 
		}	
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateCPGCmd	
		write-debuglog " Creating CPG with the command --> $CreateCPGCmd" "INFO:" 
		write-debuglog " CPG command --> $CreateCPGCmd result $Result1" "INFO:"	
	}	
	else
	{
		write-debuglog " CPG $cpgName already exists - No action required" "INFO:"
		return "FAILURE : cpg $cpgName already exists"
	}
	if((test-3PARObject -objectType cpg -objectName $cpgName -SANConnection $SANConnection))
	{
		return "SUCCESS : Created cpg $cpgName"
	}
	else
	{
		return  "FAILURE : While creating cpg $cpgName  $Result1"
	}	
} # End of NEW-3parCPG


############################################################################################################################################
## FUNCTION NEW-3parVVSet
############################################################################################################################################

Function New-3parVVSet
{
<#
  .SYNOPSIS
    Creates a new VolumeSet 
  
  .DESCRIPTION
	 Creates a new VolumeSet
        
  .EXAMPLE
    New-3parVVSet -vvSetName "MyVolumeSet"  
	 Creates a VolumeSet named MyVolumeSet 
	
	New-3parVVSet -vvSetName "MYVolumeSet" -Domain MyDomain
	Creates a VolumeSet named MyVolumeSet in the domain MyDomain
  .EXAMPLE
 	New-3parVVSet -vvSetName "MYVolumeSet" -Domain MyDomain -vvName "MyVV"
	Creates a VolumeSet named MyVolumeSet in the domain MyDomain and adds VV "MyVV" to that vvset
  .EXAMPLE
	New-3parVVSet -vvSetName "MYVolumeSet" -vvName "MyVV"
	 adds vv "MyVV"  to existing vvset "MyVolumeSet" if vvset exist, if not it will create vvset and adds vv to vvset
	
  .PARAMETER vvSetName 
    Specify new name of the VolumeSet
	
  .PARAMETER Domain 
    Specify the domain where the Volume set will reside
  
  .PARAMETER vvName 
    Specify the VV  to add  to the Volume set 
	
  .PARAMETER comment 
    comment for Volume set 

 .PARAMETER Comment 
     Specifies any comment or additional information for the set.	
	
 .PARAMETER Count <num>
        Add a sequence of <num> VVs starting with "vvname". vvname should
        be of the format <basename>.<int>
        For each VV in the sequence, the .<int> suffix of the vvname is
        incremented by 1.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
              
  .Notes
    NAME:  New-3parVVSet 
    LASTEDIT: 05/11/2015
    KEYWORDS: New-3parVVSet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvSetName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Domain= "",
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvName= "",
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Comment,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Count,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		

	Write-DebugLog "Start: In New-3parVVSet - validating input values" $Debug 
	if (!($vvSetName))
	{
		Write-DebugLog "Stop: Exiting new-3parVVSet since no values specified for vvset" $Debug
		Get-Help New-3parVVSet
		return
	}
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting new-3parVVSet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting new-3parVVSet since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	# --------- Check whether VolumeSet already exists

	write-debuglog "Executing command --> showvvset to check whether the vvset name exists" "DEBUG:" 
	write-debuglog " Result is $result" "DEBUG:"
	
	if ( !( test-3PARObject -objectType 'vv set' -objectName $vvSetName -SANConnection $SANConnection))
	{
		$CreateVolumeSetCmd = "createvvset "
		$Option = "" 
		if ($Domain) 
		{
			$CreateVolumeSetCmd += " -domain $Domain "			
		}
		if ($Count) 
		{
			$CreateVolumeSetCmd += " -cnt $Count "			
		}
		if ($Comment) 
		{
			$CreateVolumeSetCmd += " -comment $Comment "			
		}
		if ($vvName)
		{
			$CreateVolumeSetCmd += " $vvSetName"		
			Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateVolumeSetCmd
			write-debuglog " Creating a VolumeSet first with the command --> $CreateVolumeSetCmd" "INFO:"
			
			$testSetCmd += "createvvset -add $vvSetName $vvName" 
			write-debuglog " Creating VolumeSet and add vv $vvName with the command --> $testSetCmd" "INFO:"
			Invoke-3parCLICmd -Connection $SANConnection -cmds  $testSetCmd
			$testcmd1 = "showvvset -vv $vvName"
			$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $testcmd1
			
			if ($Result3 -match "No vv set listed")
			{
				return  "FAILURE : While adding vv $vvName to vvset $vvSetName"
			}
			else
			{
				return  "SUCCESS : vv $vvName added to vvset $vvSetName"
			}

		}
		else
		{
			$CreateVolumeSetCmd += " $vvSetName"		
			Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateVolumeSetCmd
			write-debuglog " Creating a VolumeSet with the command --> $CreateVolumeSetCmd" "INFO:"
			$testcmd2 = "showvvset $vvSetName"
			$Result4 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $testcmd2
			
			if ($Result4 -match "No vv set listed")
			{
				return  "FAILURE : While creating vvset $vvSetName"
			}
			else
			{
				return  "SUCCESS : Created vvset $vvSetName"
			}
		}
	}	
	else
	{
		if ($vvName)
		{
			$CreateVVSetCmd = "createvvset -add $vvSetName $vvName " 
			write-debuglog " Add vv $vvName to existing vvset $vvSetName with the command --> $CreateVVSetCmd" "INFO:"
			Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateVVSetCmd
			$testcmd = "showvvset -vv $vvName"
			$Result5 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $testcmd
			
			if ($Result5 -match "No vv set listed")
			{
				return  "FAILURE : While adding vv $vvName to vvset $vvSetName"
			}
			else
			{
				return  "SUCCESS : vv $vvName added to vvset $vvSetName"
			}
		}
		else
		{
			write-debuglog " VolumeSet $vvSetName already exists but no vv mentioned - No action required" "INFO:" 
			return  "FAILURE : VolumeSet $vvSetName already exists but no vv mentioned"	
		}
	}
	
	
} # End of New-3parVVSet




############################################################################################################################################
## FUNCTION New-3parVV
############################################################################################################################################

Function New-3parVV
{
<#
  .SYNOPSIS
    Creates a vitual volume.
  
  .DESCRIPTION
	Creates a vitual volume.
	
  .EXAMPLE	
	New-3parVV

  .EXAMPLE
	New-3parVV -vvName AVV

  .EXAMPLE
	New-3parVV -vvName AVV -CPGName ACPG

  .EXAMPLE
	New-3parVV -vvName VV_Aslam -CPGName CPG_Aslam

  .EXAMPLE
	New-3parVV -vvName AVV -CPGName CPG_Aslam

  .EXAMPLE
	New-3parVV -vvName AVV1 -CPGName CPG_Aslam -Force

  .EXAMPLE
	New-3parVV -vvName AVV -CPGName CPG_Aslam -Force -tpvv

  .EXAMPLE
	New-3parVV -vvName AVV -CPGName CPG_Aslam -Force -Template Test_Template

        
  .EXAMPLE
    New-3parVV -vvName PassThru-Disk -Size 100g -CPGName HV -vvSetName MyVolumeSet
	The command creates a new volume named PassThru-disk of size 100GB.
	The volume is created under the HV CPG group and will be contained inside the MyvolumeSet volume set.
	If MyvolumeSet does not exist, the command creates a new volume set.	

  .EXAMPLE
    New-3parVV -vvName PassThru-Disk1 -Size 100g -CPGName MyCPG -tpvv -minalloc 2048 -vvSetName MyVolumeSet
	The command creates a new thin provision volume named PassThru-disk1 of size 100GB.
	The volume is created under the MyCPG CPG group and will be contained inside the MyvolumeSet volume set.
	If MyvolumeSet does not exist, the command creates a new volume set and allocates minimum 2048MB.
	
  .PARAMETER vvName 
    Specify new name of the virtual volume
	
  .PARAMETER Size 
    Specify the size of the new virtual volume. Valid input is: 1 for 1 MB , 1g or 1G for 1GB , 1t or 1T for 1TB
	
  .PARAMETER CPGName
    Specify the name of CPG
	
 .PARAMETER Template <tname>
        Use the options defined in template <tname>.  
		
  .PARAMETER  Volume_ID <ID>
        Specifies the ID of the volume. By default, the next available ID is chosen.

  .PARAMETER Count <count>
        Specifies the number of identical VVs to create. 

  .PARAMETER  Shared
        Specifies that the system will try to share the logical disks among the VVs. 

  .PARAMETER   Wait <secs>
        If the command would fail due to the lack of clean space, the -wait
            
  .PARAMETER vvSetName
    Specify the name of a volume set. If it does not exist, the command will also create new volume set.
	
  .PARAMETER minalloc	
	This option specifies the default allocation size (in MB) to be set
	
  .PARAMETER Snp_aw <percent>
        Enables a snapshot space allocation warning. A warning alert is
        generated when the reserved snapshot space of the VV
        exceeds the indicated percentage of the VV size.

  .PARAMETER Snp_al <percent>
        Sets a snapshot space allocation limit. The snapshot space of the
        VV is prevented from growing beyond the indicated
        percentage of the virtual volume size.
		
  .PARAMETER Comment <comment>
        Specifies any additional information up to 511 characters for the
        volume.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parVV  
    LASTEDIT: 05/11/2015
    KEYWORDS: New-3parVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Size="1G", 	# Default is 1GB
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $CPGName,		
	
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $vvSetName,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Force,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Template,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Volume_ID,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Count,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Wait,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Comment,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Shared,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$tpvv,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$tdvv,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Snp_Cpg,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Sectors_per_track,
		
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Heads_per_cylinder,
		
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $minAlloc,
		
		[Parameter(Position=16, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Snp_aw,
		
		[Parameter(Position=17, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Snp_al,
		
		[Parameter(Position=18, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-vVolume - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
         
	if ($vvName)
	{
		if ($CPGName)
		{
			## Check CPG Name 
			##
			if ( !( test-3PARObject -objectType 'cpg' -objectName $CPGName -SANConnection $SANConnection))
			{
				write-debuglog " CPG $CPGName does not exist. Please use New-CPG to create a CPG before creating vv" "INFO:" 
				return "FAILURE : No cpg $cpgName found"
			}		

			## Check vv Name . Create if necessary
			##
			if (test-3PARObject -objectType 'vv' -objectName $vvName -SANConnection $SANConnection)
			{
				write-debuglog " virtual Volume $vvName already exists. No action is required" "INFO:" 
				return "FAILURE : vv $vvName already exists"
			}
			$CreateVVCmd = "createvv"
			if($Force)
			{
				$CreateVVCmd +=" -f "
			}
			#####v0.2 
			if ($minAlloc)
			{
				if(!($tpvv))
				{
					return "FAILURE : -minalloc optiong should not use without -tpvv"
				}
			}					
			if ($tpvv)
			{
				$CreateVVCmd += " -tpvv "
				if ($minAlloc)
				{
					$ps3parbuild = Get-3parVersion -number -SANConnection $SANConnection
					if($ps3parbuild -ge "3.2.1" -Or $ps3parbuild -ge "3.1.1")
					{
						$CreateVVCmd += " -minalloc $minAlloc"
					}
					else
					{
						return "FAILURE : -minalloc option not supported in this HPE3par OS version: $ps3parbuild"
					}
				}
			}
			if($tdvv)
			{
				$CreateVVCmd +=" -tdvv "
			}
			#####
			if($Template)
			{
				$CreateVVCmd +=" -templ $Template "
			}
			if($Volume_ID)
			{
				$CreateVVCmd +=" -i $Volume_ID "
			}
			if($Count)
			{
				$CreateVVCmd +=" -cnt $Count "
				if($Shared)
				{
					if(!($tpvv))
					{
						$CreateVVCmd +=" -shared "
					}
				}
			}
			if($Wait)
			{
				if(!($tpvv))
				{
					$CreateVVCmd +=" -wait $Wait "
				}
			}
			if($Comment)
			{
				$CreateVVCmd +=" -comment $Comment "
			}
			if($Sectors_per_track)
			{
				$CreateVVCmd +=" -spt $Sectors_per_track "
			}
			if($Heads_per_cylinder)
			{
				$CreateVVCmd +=" -hpc $Heads_per_cylinder "
			}
			if($Snp_Cpg)
			{
				$CreateVVCmd +=" -snp_cpg $CPGName "
			}
			if($Snp_aw)
			{
				$CreateVVCmd +=" -snp_aw $Snp_aw "
			}
			if($Snp_al)
			{
				$CreateVVCmd +=" snp_al $Snp_al "
			}
			
			$CreateVVCmd +=" $CPGName $vvName $Size"
			$Result1 = $Result2 = $Result3 = ""
			$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateVVCmd
			#write-host "Result = ",$Result1
			if([string]::IsNullOrEmpty($Result1))
			{
				$successmsg += "SUCCESS : Created vv $vvName"
			}
			else
			{
				$failuremsg += "FAILURE : While creating vv $vvName"
			}
			write-debuglog " Creating Virtual Name with the command --> $CreatevvCmd" "INFO:" 

			# If VolumeSet is specified then add vv to existing Volume Set
			if ($vvSetName)
			{
				## Check vvSet Name 
				##
				if ( !( test-3PARObject -objectType 'vv set' -objectName $vvSetName -SANConnection $SANConnection))
				{
					write-debuglog " Volume Set $vvSetName does not exist. Use New-vVolumeSet to create a Volume set before creating vLUN" "INFO:" 
					$CreatevvSetCmd = "createvvset $vvSetName"
					$Result2 =Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreatevvSetCmd
					if([string]::IsNullOrEmpty($Result2))
					{
						$successmsg += "SUCCESS : Created vvset $vvSetName"
					}
					else
					{
						$failuremsg += "FAILURE : While creating vvset $vvSetName"					
					}
					write-debuglog " Creating Volume set with the command --> $CreatevvSetCmd" "INFO:"
				}
				
				$AddVVCmd = "createvvset -add $vvSetName $vvName" 	## Add vv to existing Volume set
				$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $AddVVCmd
				if([string]::IsNullOrEmpty($Result3))
				{
					$successmsg += "SUCCESS : vv $vvName added to vvset $vvSetName"
				}
				else
				{
					$failuremsg += "FAILURE : While adding vv $vvName to vvset $vvSetName"					
				}					
				write-debuglog " Adding vv to Volume set with the command --> $AddvvCmd" "INFO:"
			}
			if(([string]::IsNullOrEmpty($Result1)) -and ([string]::IsNullOrEmpty($Result2)) -and ([string]::IsNullOrEmpty($Result3)))
			{
				return $successmsg 
			}
			else
			{
				return $failuremsg
			}			
		}
		else
		{
			write-debugLog "No CPG Name specified for new virtual volume. Skip creating virtual volume" "ERR:" 
			return "FAILURE : No CPG name specified"
		}		
	}
	else
	{
		write-debugLog "No name specified for new virtual volume. Skip creating virtual volume" "ERR:"
		Get-help New-3parVV
		return	
	}		 
} # End New-3parVV

############################################################################################################################################
## FUNCTION Get-3parVV
############################################################################################################################################

Function Get-3parVV
{
<#
  .SYNOPSIS
    Get list of virtual volumes per Domain and CPG
  
  .DESCRIPTION
    Get list of virtual volumes per Domain and CPG
        
  .EXAMPLE
    Get-3parVV
	List all virtual volumes
  .EXAMPLE	
	Get-3parVV -vvName PassThru-Disk 
	List virtual volume PassThru-Disk
  .EXAMPLE	
	Get-3parVV -vvName PassThru-Disk -Domain mydom
	List volumes in the domain specified DomainName	
	
  .PARAMETER vvName 
    Specify name of the volume. 
	If prefixed with 'set:', the name is a volume set name.	

  .PARAMETER DomainName 
    Queries volumes in the domain specified DomainName.
	
  .PARAMETER CPGName
    Queries volumes that belongs to a given CPG.	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parVV
    LASTEDIT: 05/11/2015
    KEYWORDS: Get-3parVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvName,

		[Parameter(Position=1, Mandatory=$false)]
		[System.String[]]
		$DomainName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String[]]
		$CPGName,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$GetvVolumeCmd = "showvvcpg"

	if ($DomainName)
	{
		$GetvVolumeCmd += " -domain $DomainName"
	}
	
	if ($vvName)
	{
		$GetvVolumeCmd += " $vvName"
	}
	

	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetvVolumeCmd
	write-debuglog "Get list of Virtual Volumes" "INFO:" 
	if($Result -match "no vv listed")
	{
		return "FAILURE: No vv $vvName found"
	}

	$tempFile = [IO.Path]::GetTempFileName()
	$Result = $Result | where { ($_ -notlike '*total*') -and ($_ -notlike '*---*')} ## Eliminate summary lines
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -2  
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$s= $s.Trim() -replace ',Adm,Snp,Usr,Adm,Snp,Usr',',Adm(MB),Snp(MB),Usr(MB),New_Adm(MB),New_Snp(MB),New_Usr(MB)' 	

			Add-Content -Path $Tempfile -Value $s
		}

		if ($CPGName)
			{ Import-Csv $tempFile | where  {$_.CPG -like $CPGName} }
		else
			{ Import-Csv $tempFile }
		
		
		del $tempFile
	}	
	else
	{
		Write-DebugLog $result "INFO:"
		return "FAILURE: No vv $vvName found error:$result "
	}	

} # END GET-3parVV

############################################################################################################################################
## FUNCTION Remove-3parVV
############################################################################################################################################

Function Remove-3parVV
{
<#
  .SYNOPSIS
    Delete virtual volumes 
  
  .DESCRIPTION
     Delete virtual volumes 
        

  .EXAMPLE	
	
	Remove-3parVV -vvName PassThru-Disk -whatif
		Dry-run of deleted operation on vVolume named PassThru-Disk

  .EXAMPLE	
	
	Remove-3parVV -vvName PassThru-Disk -force
		Forcibly deletes vVolume named PassThru-Disk 
		
  .PARAMETER vvName 
    Specify name of the volume to be removed. 
	
  .PARAMETER whatif
    If present, perform a dry run of the operation and no VLUN is removed	
	
  .PARAMETER force
	If present, perform forcible delete operation
	
  .PARAMETER Pat
    Specifies that specified patterns are treated as glob-style patterns and that all VVs matching the specified pattern are removed.
	
  .PARAMETER Stale
        Specifies that all stale VVs can be removed.       

  .PARAMETER  Expired
        Remove specified expired volumes.
       
  .PARAMETER  Snaponly
        Remove the snapshot copies only.

   .PARAMETER Cascade
        Remove specified volumes and their descendent volumes as long as none has an active VLUN. 

   .PARAMETER Nowait
        Prevents command blocking that is normally in effect until the vv is removed. 
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parVV  
    LASTEDIT: 05/11/2015
    KEYWORDS: Remove-Volume
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$vvName,

		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$whatif, 
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$force, 
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Pat, 
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Stale, 
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Expired, 
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Snaponly, 
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Cascade, 
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Nowait, 
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if (!($vvName))
	{
		write-debuglog "no Virtual Volume name sprcified to remove." "INFO:"
		Get-help remove-3parvv
		return
	}
	if (!(($force) -or ($whatif)))
	{
		write-debuglog "no option selected to remove/dry run of vv, Exiting...." "INFO:"
		return "FAILURE : Specify -force or -whatif options to delete or delete dryrun of a virtual volume"
	}
	
	######
	$ListofLuns = get-3parVVList -vvName $vvName -SANConnection $SANConnection
	if($ListofLuns -match "FAILURE")
	{
		return "FAILURE : No vv $vvName found"
	}
	$ActionCmd = "removevv "
	if ($Nowait)
	{
		$ActionCmd += "-nowait "
	}
	if ($Cascade)
	{
		$ActionCmd += "-cascade "
	}
	if ($Snaponly)
	{
		$ActionCmd += "-snaponly "
	}
	if ($Expired)
	{
		$ActionCmd += "-expired "
	}
	if ($Stale)
	{
		$ActionCmd += "-stale "
	}
	if ($Pat)
	{
		$ActionCmd += "-pat "
	}
	if ($whatif)
	{
		$ActionCmd += "-dr "
	}
	else
	{
		$ActionCmd += "-f "
	}
	$successmsglist = @()
	$failuremsglist = @()
	if ($ListofLuns)
	{
		foreach ($vVolume in $ListofLuns)
		{
			$vName = $vVolume.Name
			if ($vName)
			{
				$RemoveCmds = $ActionCmd + " $vName $($vVolume.Lun)"
				$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $removeCmds
				if( ! (Test-3PARObject -objectType "vv" -objectName $vName -SANConnection $SANConnection))
				{
					$successmsglist += "SUCCESS : Removing vv $vName"
				}
				else
				{
					$successmsglist += "FAILURE : $Result1"
				}

				write-debuglog "Removing Virtual Volumes with command $removeCmds" "INFO:" 
			}
		}
		return $successmsglist		
	}	
	else
	{
		Write-DebugLog "no Virtual Volume found for $vvName." $Info
		return "FAILURE : No vv $vvName found"
	}
	

} # END REMOVE-3parVV


############################################################################################################################################
## FUNCTION New-3parVLUN
############################################################################################################################################

Function New-3parVLUN
{
<#
  .SYNOPSIS
    Creates a new vLUN and presents it to host
  
  .DESCRIPTION
    Creates a newvLUN and presents it to host
        
  .EXAMPLE
    New-3parVLUN -vvName PassThru-Disk -PresentTo HV01
	Exports a virtual volume named PassThru-Disk and present it to HV01
	
  .EXAMPLE
	New-3parVLUN -vvName set:Witness-Set -PresentTo set:HV01C-set
	Exports a volume set and present it to a host set
	
  .PARAMETER vvName 
    Specify name of the volume to be exported. 
	If prefixed with 'set:', the name is a volume set name.
	
  .PARAMETER PresentTo
    Specify the name of the host to be presented.
	If prefixed with 'set:', the name is a host set name.
  .PARAMETER LUNnumber
	Specify the Lun Number Ex:3
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  	  New-3parVLUN  
    LASTEDIT: 05/11/2015
    KEYWORDS: New-3parVLUN
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
		$PresentTo, 	
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LUNnumber = "auto",
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In New-3parVLUN - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVLUN since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVLUN since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	##### Added v2.0 : checking the parameter values if vvName or present to empty simply return
	if (!(($vvName) -and ($PresentTo)))
	{
		Write-DebugLog "No values specified for the parameters vvname , presentTo. so simply exiting " "INFO:"
		Get-help New-3parVLUN
		return
	}
	#####
	#---------- Check for existence of volume or volume set
	#	if start with 'set:', it's a volume set
	
	if ( $vvName -match "^set:")	
	{		
		$objName = $vvName.Split(':')[1]		
		$objType = "vv set"
	}
	else
	{
		$objName = $vvName
		$objType = "vv"
	}
	
	if ( ! (Test-3PARObject -objectType $objType -objectName $objName -SANConnection $SANConnection))
	{
		Write-DebugLog "Volume/Volume set $vvName does not exist. Create volume or volume set first before exporting.`n If name is a volume set, prefix it with set:. For example, set:MyVolumeSet" "ERR:"
		Write-DebugLog "Stop: Exiting New-3parVLUN. Volume (set) does not exist" $Debug
		return "FAILURE : No vv(set) $vvName found"
	}
	
	#---------- Check for existence of host or host set
	#	if start with 'set:', it's a host set
	
	Foreach ($item in $PresentTo)
	{
		if ( $item -match "^set:")	
		{
			$objName = $item.Split(':')[1]
			$objType = "host set"
			$objMsg  = $objType
		}
		else
		{
			$objName = $item
			$objType = "host"
			$objMsg  = "hosts"
		}		
		if ( ! (Test-3PARObject -objectType $objType -objectName $objName -objectMsg $objMsg -SANConnection $SANConnection))
		{
			Write-DebugLog "Host/Host set $item does not exist. Create host or host set first before exporting.`nIf name is a host set, prefix it with set:. Example: set:HV01C." "ERR:"
			Write-DebugLog "Stop: Exiting New-3parVLUN. Host (set) does not exist" $Debug
			return "FAILURE : No Host(set) $objName found"
		}	
		
		$ExportCmd = "createvlun -f $vvName $LUNNumber $item"

		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $ExportCmd
		write-debuglog "Presenting $vvName to server $item with the command --> $ExportCmd" "INFO:" 
		if($Result1 -match "no active paths")
		{
			$successmsg += $Result1
		}
		elseif([string]::IsNullOrEmpty($Result1))
		{
			$successmsg += "SUCCESS : $vvName exported to host $objName`n"
		}
		else
		{
			$successmsg += "FAILURE : While exporting vv $vvName to host $objName Error : $Result1`n"
		}
		
	}
	return $successmsg
	
} # End NEW-3parVLUN
############################################################################################################################################
## FUNCTION Get-3parVLUN
############################################################################################################################################
Function Get-3parVLUN
{
<#
  .SYNOPSIS
    Get list of LUNs that are exported/ presented to hosts
  
  .DESCRIPTION
    Get list of LUNs that are exported/ presented to hosts
        
  .EXAMPLE
    Get-3parVLUN 
	List all exported volumes
	
	Get-3parVLUN -vvName PassThru-Disk 
	List LUN number and hosts/host sets of LUN PassThru-Disk
	
  .PARAMETER vvName 
    Specify name of the volume to be exported. 
	If prefixed with 'set:', the name is a volume set name.
	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parVLUN  
    LASTEDIT: 02/17/2013
    KEYWORDS: Export-Volume
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PresentTo, 	
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parVLUN - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parVLUN since SAN connection object values are null/empty" $Debug
				return
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$ListofvLUNs = @()
	
	$GetvLUNCmd = "showvlun -t -showcols VVName,Lun,HostName,VV_WWN "
	if ($vvName)
	{
		$GetvLUNCmd += " -v $vvName"
	}
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetvLUNCmd
	write-debuglog "Get list of vLUN" "INFO:" 
	if($Result -match "Invalid vv name:")
	{
		return "FAILURE : No vv $vvName found"
	}
	
	$Result = $Result | where { ($_ -notlike '*total*') -and ($_ -notlike '*------*')} ## Eliminate summary lines
	if ($Result.Count -gt 1)
	{
		foreach ($s in  $Result[1..$Result.Count] )
		{
			
			$s= $s.Trim()
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$sTemp = $s.Split(',')
			
			$vLUN = New-Object -TypeName _vLUN
			$vLUN.Name = $sTemp[0]
			$vLUN.LunID = $sTemp[1]
			$vLUN.PresentTo = $sTemp[2]
			$vLUN.vvWWN = $sTemp[3]
			
			$ListofvLUNs += $vLUN
			
		}
	}
	else
	{
		write-debuglog "LUN $vvName does not exist. Simply return" "INFO:"
		return "FAILURE : No vLUN $vvName found Error : $Result"
	}
	

	if ($PresentTo)
		{ $ListofVLUNs | where  {$_.PresentTo -like $PresentTo} }
	else
		{ $ListofVLUNs  }
	
} # End GET-3parVLUN


############################################################################################################################################
## FUNCTION Remove-3parVLUN
############################################################################################################################################

Function Remove-3parVLUN
{
<#
  .SYNOPSIS
    Unpresent virtual volumes 
  
  .DESCRIPTION
    Unpresent  virtual volumes 
        
  .EXAMPLE
	Remove-3parVLUN -vvName PassThru-Disk -force
	Unpresent the virtual volume PassThru-Disk to all hosts
  .EXAMPLE	
	Remove-3parVLUN -vvName PassThru-Disk -whatif 
	Dry-run of deleted operation on vVolume named PassThru-Disk
  .EXAMPLE		
	Remove-3parVLUN -vvName PassThru-Disk -PresentTo INF01  -force
	Unpresent the virtual volume PassThru-Disk only to host INF01.
	all other presentations of PassThru-Disk remain intact.
  .EXAMPLE	
	Remove-3parVLUN -PresentTo INF01 -force
	Remove all LUNS presented to host INF01
  .EXAMPLE	
	Remove-3parVLUN -vvName CSV* -PresentTo INF01 -force
	Remove all LUNS started with CSV* and presented to host INF01
	
  .EXAMPLE
   Remove-3parVLUN -vvName vol2 -force -Novcn
   
  .EXAMPLE
   Remove-3parVLUN -vvName vol2 -force -Pat
   
  .EXAMPLE
   Remove-3parVLUN -vvName vol2 -force -Remove_All   
	Remove all the VLUNs connected with the VVs in a vvset.
	
  .PARAMETER vvName 
    Specify name of the volume to be exported. 
	
  .PARAMETER PresentTo 
    Specify name of the hosts where vLUns are presented to.
	
  .PARAMETER whatif
    If present, perform a dry run of the operation and no VLUN is removed	

  .PARAMETER force
	If present, perform forcible delete operation
	
  .PARAMETER Novcn
        Specifies that a VLUN Change Notification (VCN) not be issued after removal of the VLUN.
		
  .PARAMETER -pat
        Specifies that the <VV_name>, <LUN>, <node:slot:port>, and <host_name> specifiers are treated as glob-style patterns and that all VLUNs matching the specified pattern are removed.
	
  .PARAMETER Remove_All
		Remove all the VLUNs connected with the VVs in a vvset.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parVLUN  
    LASTEDIT: 05/11/2015
    KEYWORDS: Remove-3parVLUN
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$force, 
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$whatif, 		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvName,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PresentTo, 		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Novcn,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Pat,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Remove_All,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-3parVLUN - validating input values" $Debug 
	
	##### 
	if (!(($vvName) -or ($PresentTo)))
	{
		Write-DebugLog "Action required: no vv or no host mentioned - simply exiting " $Debug
		Get-help Remove-3parVLUN
		return
	}
	if(!(($force) -or ($whatif)))
	{
		write-debuglog "no -force or -whatif option selected to remove/dry run of VLUN, Exiting...." "INFO:"
		Get-help Remove-3parVLUN
		return "FAILURE : no -force or -whatif option selected to remove/dry run of VLUN"
	}
	#####
	
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parVLUN since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parVLUN since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($PresentTo)
	{
		$ListofvLuns = Get-3parVLUN -vvName $vvName -PresentTo $PresentTo -SANConnection $SANConnection
	}
	else
	{
		$ListofvLuns = Get-3parVLUN -vvName $vvName -SANConnection $SANConnection
	}
	if($ListofvLuns -match "FAILURE")
	{
		return "FAILURE : No vLUN $vvName found"
	}
	$ActionCmd = "removevlun "
	if ($whatif)
	{
		$ActionCmd += "-dr "
	}
	else
	{
		if($force)
		{
			$ActionCmd += "-f "
		}		
	}	
	if ($Novcn)
	{
		$ActionCmd += "-novcn "
	}
	if ($Pat)
	{
		$ActionCmd += "-pat "
	}
	if($Remove_All)
	{
		$ActionCmd += " -set "
	}
	if ($ListofvLuns)
	{
		foreach ($vLUN in $ListofvLuns)
		{
			$vName = $vLUN.Name
			if ($vName)
			{
				$RemoveCmds = $ActionCmd + " $vName $($vLun.LunID) $($vLun.PresentTo)"
				$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $RemoveCmds
				write-debuglog "Removing Virtual LUN's with command $RemoveCmds" "INFO:" 
				if ($Result1 -match "Issuing removevlun")
				{
					$successmsg += "SUCCESS: Unexported vLUN $vName from $($vLun.PresentTo)"
				}
				elseif($Result1 -match "Dry run:")
				{
					$successmsg += $Result1
				}
				else
				{
					$successmsg += "FAILURE : While unexporting vLUN $vName from $($vLun.PresentTo) "
				}				
			}
		}
		return $successmsg
	}
	
	else
	{
		Write-DebugLog "no vLUN found for $vvName presented to host $PresentTo." $Info
		return "FAILURE : no vLUN found for $vvName presented to host $PresentTo"
	}
	

} # END REMOVE-3parVLUN



############################################################################################################################################
## FUNCTION New-3parHost
############################################################################################################################################

Function New-3parHost
{
<#
	.SYNOPSIS
    Creates a new host.
  
	.DESCRIPTION
	Creates a new host.
        
	.EXAMPLE
    New-3parHost -hostName HV01A -persona 2 -Address 10000000C97B142E
	Creates a host entry named HV01A with WWN equals to 10000000C97B142E
	
	.EXAMPLE	
	New-3parHost -hostName HV01B -persona 2 -iSCSI:$true -Address  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	Creates a host entry named HV01B with iSCSI equals to iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	
	.EXAMPLE
    New-3parHost -hostName HV01A -persona 2 -Address 10000000C97B142E -hostSet demohostset
	Creates a host entry named HV01A with WWN equals to 10000000C97B142E and adds host to hostset demohostset if hostset present if not it will create hostset and adds host to hostset

	.EXAMPLE New-3parHost -hostName Host3 -iSCSI

	.EXAMPLE New-3parHost -hostName Host4 -iSCSI -Domain D_Aslam
	
	.PARAMETER hostName
    Specify new name of the host
	
	.PARAMETER Persona 
    Specify the persona of the new host. Persona 2 is used for Windows Server 2012
	
	.PARAMETER HostSet
    Specify host set name. If the hostset does not exist, it will be created.

	.PARAMETER Address
    Specifies the addres sof new host ( WWN or iSCSI)

	.PARAMETER iSCSI
    when specified, it means that the address is an iSCSI address
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection

	.PARAMETER Domain 
    Specify the 3PAR domain where the host will be added to
	
	.Notes
    NAME:  New-3parHost  
    LASTEDIT: 05/11/2015
    KEYWORDS: New-3parHost
   
	.Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$hostSet,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Persona=2,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Address,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
        $iSCSI = $false,

		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[String]
        $Domain = "" ,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-3parHost - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parHost since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parHost since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
      
	if ($hostName)
	{
		$objType = "host"
		$objMsg  = "hosts"
		
		## Check Host Name 
		##
		if ( test-3PARObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection)
		{
			write-debuglog " Host $hostName already exists. If -hostSet is specified, the host name will be added to the hostset"  
			#$AddAction = $true
			$successmsg += "SUCCESS : host $hostName already exists"
		}
		else
		{		
			$options = "" 
			if ($iSCSI)
				{ $options = " -iscsi "} 
			
            $DomainOption = ""
            if ($Domain)
            { $DomainOption = " -domain $Domain " }            

			$Addr = [string]$Address
			$CreateHostCmd = "createhost -f  $options $Domainoption -persona $Persona $hostName $Addr " 
			$Result5 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateHostCmd
			write-debuglog " Creating Host with the command --> $CreateHostCmd " "INFO:" 
			if ([string]::IsNullOrEmpty($Result5))
			{				
				$successmsg += "SUCCESS : Created host $hostName"
			}
			else
			{
				$failuremsg += "FAILURE : While creating host $hostName"
			}			
		}		
		if ($hostSet)
		{
			$objType = "host set"
			$objMsg  = $objType

			## Check host set name . Create if necessary
			##
			if (!(test-3PARObject -objectType $objType -objectName $hostSet -objectMsg $objMsg -SANConnection $SANConnection))
			{
				write-debuglog " Host Set name does not exist. Creating it now" "INFO:" 
				$CreateHostSetCmd = "createhostset $DomainOption $hostSet"
				$Result6 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateHostSetCmd
				write-debuglog " Creating Host Set with the command --> $CreateHostSetCmd" "INFO:" 
				if ([string]::IsNullOrEmpty($Result6)){				
					
					$successmsg += "`nSUCCESS : Created hostset $hostSet"
				}
				else
				{
					$failuremsg += "`nFAILURE : While creating hostset $hostSet"
				}
			}
			$Result3 = Get-3parHostSet -hostName $hostName
			if ($Result3 -match "No host set listed"){
				# Host set specified and created. Now add the vHost
				$AddHostCmd = "createhostset -add $hostSet $hostName"
				$Result4 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $AddHostCmd
				write-debuglog "Adding host to  Host Set with the command --> $AddHostCmd" "INFO:" 
				if ([string]::IsNullOrEmpty($Result4))
				{					
					$successmsg += "`nSUCCESS : Host $hostName added to hostset $hostSet"
				}
				else
				{
					$failuremsg += "`nFAILURE : While adding host $hostName to hostset $hostSet"
				}
				
			}
			else
			{
				write-debuglog "Host already added to hostset" "INFO:" 
				$successmsg += "`nSUCCESS : Host $hostName already added to hostset $hostSet"
			}
			
		}
		if ( test-3PARObject -objectType "host" -objectName $hostName -objectMsg "hosts" -SANConnection $SANConnection)
		{
			return $successmsg
		}
		else
		{
			return $failuremsg
		}
		
	}
	else
	{
		write-debugLog "No name specified for new host. Skip creating host" "ERR:"
		Get-help New-3parHost
		return	
	}
		 
} # End New-3parHost



############################################################################################################################################
## FUNCTION Set-3parHost
############################################################################################################################################

Function Set-3parHost
{
<#
  .SYNOPSIS
     Add WWN or iSCSI name to an existing host.
  
  .DESCRIPTION
	  Add WWN or iSCSI name to an existing host.
        
  .EXAMPLE
    Set-3parHost -hostName HV01A -Address  10000000C97B142E, 10000000C97B142F
	Adds WWN 10000000C97B142E, 0000000C97B142F to host HV01A
  .EXAMPLE	
	Set-3parHost -hostName HV01B  -iSCSI:$true -Address  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	Adds iSCSI  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com to host HV01B
	
  .PARAMETER hostName
    Name of an existing host

  .PARAMETER Address
    Specify the list of WWNs for the new host

  .PARAMETER iSCSI
    If present, the address provided is an iSCSI address instead of WWN
	
  .PARAMETER Add
        Add the specified WWN(s) or iscsi_name(s) to an existing host (at least one WWN or iscsi_name must be specified).  Do not specify host persona.

  .PARAMETER Domain <domain | domain_set>
        Create the host in the specified domain or domain set.
    
  .PARAMETER  Persona <hostpersonaval>
        Sets the host persona that specifies the personality for all ports which are part of the host set.  
		
  .PARAMETER Loc <location>
        Specifies the host's location.

  .PARAMETER  IP <IP address>
        Specifies the host's IP address.

  .PARAMETER  OS <OS>
        Specifies the operating system running on the host.

  .PARAMETER Model <model>
        Specifies the host's model.

  .PARAMETER  Contact <contact>
        Specifies the host's owner and contact information.

  .PARAMETER  Comment <comment>
        Specifies any additional information for the host.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parHost  
    LASTEDIT: 05/11/2015
    KEYWORDS: Set-3parHost
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Address,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
        $iSCSI=$false,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
        $Add,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Domain,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Loc,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $IP,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $OS,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Model,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Contact,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Comment,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]
        $Persona,
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Set-3parHost - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parHost since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parHost since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}      
	if ($hostName)
	{
		$objType = "host"
		$objMsg  = "hosts"
		
		## Check Host Name 
		##
		if (-not( test-3PARObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection))
		{
			write-debuglog " Host $hostName does not exist. use New-vHost to create the host" 
			return "FAILURE : No host $hostName found"
			#$AddAction = $true
		}
		else
		{
			$SetHostCmd = "createhost -f "			 
			if ($iSCSI)
			{ 
				$SetHostCmd +=" -iscsi "
			}
			if($Add)
			{
				$SetHostCmd +=" -add "
			}
			if($Domain)
			{
				$SetHostCmd +=" -domain $Domain"
			}
			if($Loc)
			{
				$SetHostCmd +=" -loc $Loc"
			}
			if($Persona)
			{
				$SetHostCmd +=" -persona $Persona"
			}
			if($IP)
			{
				$SetHostCmd +=" -ip $IP"
			}
			if($OS)
			{
				$SetHostCmd +=" -os $OS"
			}
			if($Model)
			{
				$SetHostCmd +=" -model $Model"
			}
			if($Contact)
			{
				$SetHostCmd +=" -contact $Contact"
			}
			if($Comment)
			{
				$SetHostCmd +=" -comment $Comment"
			}
			
			$Addr = [string]$Address
			$SetHostCmd +=" $hostName $Addr"
			
			$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $SetHostCmd
			write-debuglog " Setting  Host with the command --> $SetHostCmd" "INFO:"
			if([string]::IsNullOrEmpty($Result1))
			{
				return "SUCCESS : Set host $hostName with Optn_Iscsi $Optn_Iscsi $Addr "
			}
			else
			{
				return "FAILURE : While set host $hostName"
			}		
		}		
	}
	else
	{
		write-debugLog "No name specified for host. Skip updating  host" "ERR:"
		Get-help Set-3parHost
		return	
	} 
} # End Set-3parHost

############################################################################################################################################
## FUNCTION New-3parHostSet
############################################################################################################################################

Function New-3parHostSet
{
<#
  .SYNOPSIS
    Creates a new host set.
  
  .DESCRIPTION
	Creates a new host set.
        
  .EXAMPLE
    New-3parHostSet -hostSetName HV01C-HostSet 
	Creates an empty host set named "V01C-HostSet"

  .EXAMPLE
    New-3parHostSet -hostSetName HV01C-HostSet -Domain domain
	Create the host set in the specified domain
	
  .EXAMPLE
    New-3parHostSet -hostSetName HV01C-HostSet -hostName "MyHost"
	Creates an empty host set and  named "HV01C-HostSet" and adds host "MyHost" to hostset
			(or)
	Adds host "MyHost" to hostset "HV01C-HostSet" if hostset already exists
	
  .PARAMETER hostSetName
    Specify new name of the host set

  .PARAMETER hostName
    Specify new name of the host

  .PARAMETER Domain
    Specify domain name of the host set. If empty, use the current default domain
		
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parHostSet  
    LASTEDIT: 05/11/2015
    KEYWORDS: New-3parHostSet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$hostSetName,

		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Domain,				
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In New-3parHostSet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parHostSet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parHostSet since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
      
	if ($hostSetName)
	{
		$objType = "hostset"
		$objMsg  = "host set"
		
		## Check Hostset Name 
		##
		if ( (test-3PARObject -objectType $objType -objectName $hostSetName -objectMsg $objMsg -SANConnection $SANConnection))
		{
			write-debuglog " Host Set $hostSetName already exists. Trying to add host $hostName if exist  " 
			##### 
			if($hostName)
			{			
				if ( (test-3PARObject -objectType 'host' -objectName $hostName -objectMsg 'hosts' -SANConnection $SANConnection))
				{	
					$DomainOption = ""
					if ($Domain)
					{ $DomainOption = " -domain $Domain " }
					$CreateHostSetCmd = "createhostset -add $DomainOption $hostSetName $hostName "
					$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateHostSetCmd
					write-debuglog " Host Set $hostSetName already exists. Trying to add host $hostName " "INFO:"
					write-debuglog " Adding host to existing HostSet with the command --> $CreateHostSetCmd" "INFO:"
					if([string]::IsNullOrEmpty($Result1)){
						$successmsg += "SUCCESS : hostset $hostSetName already exists and added host $hostName"
					}
					else{
						$successmsg += "FAILURE : While adding host $hostName to hostset $hostSet"
					}
					
				}
				else
				{
					write-debuglog " Host Set $hostSetName already exists, host $hostName does not exist. Exiting... " "INFO:"
					return "FAILURE : Host Set $hostSetName already exists, host $hostName does not exist"
					
				}
			}
			else
			{
				return "FAILURE : host $hostName does not exist"
			}
			#####
			#$AddAction = $true
		}
		else
		{

            $DomainOption = ""
            if ($Domain)
            { $DomainOption = " -domain $Domain " }

			$CreateHostSetCmd = "createhostset $DomainOption $hostSetName " 
			$Result2 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateHostSetCmd
			write-debuglog " Creating HostSet with the command --> $CreateHostSetCmd" "INFO:" 
			if([string]::IsNullOrEmpty($Result2)){
				$successmsg += "SUCCESS : Created hostset $hostSetName `n"
			}
			else{
				$successmsg += "FAILURE : While creating hostset $hostSetName`n"
			}
			##### Added v0.2
			if ($hostName)
			{
				write-debuglog " Adding host to existing HostSet with the command --> $CreateHostSetCmd" "INFO:"
				$CreateHostSetCmd = "createhostset -add $hostSetName $hostName "
				$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateHostSetCmd
				write-debuglog " Adding host to existing HostSet with the command --> $CreateHostSetCmd" "INFO:" 
				if([string]::IsNullOrEmpty($Result3)){
					$successmsg += "SUCCESS : host $hostName added to hostset $hostSetName"
				}
				else{
					$successmsg += "FAILURE : While adding host $hostName to hostset $hostSet"
				}
			}
			#####
		}
		
		return $successmsg				
	}
	else
	{
		write-debugLog "No name specified for new host set. Skip creating host set" "ERR:"
		Get-help New-3parHostSet
		return	
	}
		 
} # End New-3parHostSet

############################################################################################################################################
## FUNCTION Get-3parHost
############################################################################################################################################

Function Get-3parHost
{
<#
  .SYNOPSIS
   Lists hosts
  
  .DESCRIPTION
	Queries hosts
        
  .EXAMPLE
    Get-3parHost 
	Lists all hosts
	
	Get-3parHost -hostName HV01A
	List host HV01A
	
  .PARAMETER hostName
    Specify new name of the host
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parHost  
    LASTEDIT: 05/20/2015
    KEYWORDS: Get-3parHost
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parHost - validating input values" $Debug 
	#check if connection object contents are null/empty
	if (!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHost since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHost since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if($cliresult1 -match "FAILURE :")
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	
	$CurrentId = $CurrentName = $CurrentPersona = $null
	$ListofvHosts = @()
	
	if($hostName)
	{
		$objType = "host"
		$objMsg  = "hosts"
		
		## Check Host Name 
		##
		if ( -not (test-3PARObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection))
		{
			write-debuglog "host $hostName does not exist. Nothing to List" "INFO:" 
			return "FAILURE : No host $hostName found"
		}
	}
	$GetHostCmd = "showhost "
	
	if ($option)
	{
		$a = "d","chap","desc","agent","persona","noname","verbose","pathsum"
		$l=$option
		if($a -eq $l)
		{
			$GetHostCmd+=" -$option "				
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parHost since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [ d | chap | desc | agent | persona  | noname | verbose | pathsum]  can be used . "
		}
	}
	$GetHostCmd+=" $hostName"
	#write-host "$GetHostCmd"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetHostCmd
	#write-host "$Result"
	write-debuglog "Get list of Hosts" "INFO:" 
	if ($Result -match "no hosts listed")
	{
		return "SUCCESS : no hosts listed"
	}	
	if ($option -eq "verbose" -or $option -eq "pathsum" -or $option -eq "desc")
	{
		return $Result
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$Header = $Result[0].Trim() -replace '-WWN/iSCSI_Name-' , ' Address' 
	
	set-content -Path $tempFile -Value $Header
	$Result_Count = $Result.Count - 3
	if($option -eq "agent")
	{
		$Result_Count = $Result.Count - 3			
	}
	if($Result.Count -gt 3)
	{	
		foreach ($s in $Result[1..$Result_Count])
		{
			$match = [regex]::match($s, "^  +")   # Match Line beginning with 1 or more spaces
			if (-not ($match.Success))
			{
				$s= $s.Trim()
				$s= [regex]::Replace($s, " +" , "," )	# Replace spaces with comma (,)
					$sTemp = $s.Split(',')
					$CurrentId =  $sTemp[0]
					$CurrentName = $sTemp[1]
					$CurrentPersona = $sTemp[2]			
					$address = $sTemp[3]
					$Port =  [regex]::Replace($sTemp[4] , "-+" , ""  )  # Replace '----'  with "" 	
				
				$vHost = New-Object -TypeName _vHost 
				$vHost.ID = $CurrentId
				$vHost.Persona = $currentPersona
				$vHost.Name = $CurrentName
				$vHost.Address = $address
				$vHost.Port= $port
			}
			
			else
			{
				$s = $s.trim()
				$sTemp = $s.Split(' ,')
				
				$vHost = New-Object -TypeName _vHost 
				$vHost.ID = $CurrentId
				$vHost.Persona = $currentPersona
				$vHost.Name = $CurrentName
				$vHost.Address = $sTemp[0]
				$vHost.Port= [regex]::Replace($sTemp[1] , "-+" , ""  )  # Replace '----'  with "" 	
			}
			
			$ListofvHosts += $vHost		
		}	
	}	
	else
	{
		return "SUCCESS : No Data Available for Host Name :- $hostName"
	}
	$ListofvHosts	
	
} # ENd Get-3parHost


############################################################################################################################################
## FUNCTION Remove-3parHost
############################################################################################################################################

Function Remove-3parHost
{
<#
  .SYNOPSIS
    Removes a host.
  
  .DESCRIPTION
	Removes a host.
 
  .EXAMPLE
    Remove-3parHost -hostName HV01A 
	Remove the host named HV01A
	
  .EXAMPLE
    Remove-3parHost -hostName HV01A -address 10000000C97B142E
	Remove the WWN address of the host named HV01A
	
  .EXAMPLE	
	Remove-3parHost -hostName HV01B -iSCSI -Address  iqn.1991-06.com.microsoft:dt-391-xp.hq.3par.com
	Remove the iSCSI address of the host named HV01B
	
  .PARAMETER hostName
    Specify name of the host.

  .PARAMETER Address
    Specify the list of addresses to be removed.
	
  .PARAMETER Rvl
        Remove WWN(s) or iSCSI name(s) even if there are VLUNs exported to the host.

  .PARAMETER iSCSI
    Specify twhether the address is WWN or iSCSI
	
  .PARAMETER Pat
        Specifies that host name will be treated as a glob-style pattern and that all hosts matching the specified pattern are removed. T

  .PARAMETER  Port <node:slot:port>...|<pattern>...
        Specifies the NSP(s) for the zones, from which the specified WWN will be removed in the target driven zoning. 
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parHost  
    LASTEDIT: 05/11/2015
    KEYWORDS: Remove-3parHost
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch] $Rvl,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch] $ISCSI = $false,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch] $Pat = $false,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Port,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String[]]$Address,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-3parHost - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parHost since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parHost since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}      
	if ($hostName)
	{
		$objType = "host"
		$objMsg  = "hosts"
		
		## Check Host Name 
		if ( -not ( test-3PARObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " Host $hostName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE : No host $hostName found"
		}
		else
		{
		    $RemoveCmd = "removehost "			
			if ($address)
			{			
				if($Rvl)
				{
					$RemoveCmd += " -rvl "
				}	
				if($ISCSI)
				{
					$RemoveCmd += " -iscsi "
				}
				if($Pat)
				{
					$RemoveCmd += " -pat "
				}
				if($Port)
				{
					$RemoveCmd += " -port $Port "
				}
			}			
			$Addr = [string]$address 
			$RemoveCmd += " $hostName $Addr"
			$Result1 = get-3parhostset -hostName $hostName -SANConnection $SANConnection
			
			if(($Result1 -match "No host set listed"))
			{
				$Result2 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $RemoveCmd
				write-debuglog "Removing host  with the command --> $RemoveCmd" "INFO:" 
				if([string]::IsNullOrEmpty($Result2))
				{
					return "SUCCESS : Removed host $hostName"
				}
				else
				{
					return "FAILURE : While removing host $hostName"
				}				
			}
			else
			{
				$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $RemoveCmd
				return "FAILURE : Host $hostName is still a member of set"
			}			
		}				
	}
	else
	{
		write-debuglog  "No host name mentioned to remove" "INFO:"
		Get-help Remove-3parHost			
	}
} # End of Remove-3parHost
 
#####################################################################################################################
## FUNCTION Remove-3parCPG
#####################################################################################################################

Function Remove-3parCPG
{
<#
  .SYNOPSIS
    Removes a CommonProvisionGroup(CPG)
  
  .DESCRIPTION
	 Removes a CommonProvisionGroup(CPG)
        
  .EXAMPLE
    Remove-3parCPG -cpgName "MyCPG"  -force
	 Removes a CommonProvisionGroup(CPG) "MyCPG"
	 
  .PARAMETER option
    -sa <LD_name>
        Specifies that the logical disk, as identified with the <LD_name>
        argument, used for snapshot administration space allocation is removed.
        The <LD_name> argument can be repeated to specify multiple logical
        disks.
        This option is deprecated and will be removed in a subsequent release.

    -sd <LD_name>
        Specifies that the logical disk, as identified with the <LD_name>
        argument, used for snapshot data space allocation is removed. The
        <LD_name> argument can be repeated to specify multiple logical disks.
        This option is deprecated and will be removed in a subsequent release.
	
  .PARAMETER cpgName 
    Specify name of the CPG
	
 .PARAMETER LD_name 
    Specifies that the logical disk
	
  .PARAMETER Pat 
    The specified patterns are treated as glob-style patterns and that all common provisioning groups matching the specified pattern are removed.

  .PARAMETER force 
    Specify name of the CPG
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
              
  .Notes
    NAME:  Remove-3parCPG 
    LASTEDIT: 05/12/2015
    KEYWORDS: Remove-3parCPG
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	    [Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$LD_name,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$cpgName,		

		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$force,	

		[Parameter(Position=4, Mandatory=$false)]
		[switch]
		$Pat,	
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)

	Write-DebugLog "Start: In Remove-3parCPG - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parCPG since SAN connection object values are null/empty" $Debug
				return "FAILURE: Exiting Remove-3parCPG since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if ($cpgName)
	{
		if(!($force))
		{
			write-debuglog "no force option selected to remove CPG, Exiting...." "INFO:"
			return "FAILURE: No -force option selected to remove cpg $cpgName"
		}
		$objType = "cpg"
		$objMsg  = "cpg"
		$RemoveCPGCmd = "removecpg "
		## Check CPG Name 
		##
		if ( -not ( Test-3PARObject -objectType $objType -objectName $cpgName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " CPG $cpgName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE: No cpg $cpgName found"
		}
		else
		{			
			if($force)
			{
				$RemoveCPGCmd +=" -f "
			}
			if($Pat)
			{
				$RemoveCPGCmd +=" -pat "
			}
			if ($option)
			{
				$a = "sa","sd"
				$l=$option
				if($a -eq $l)
				{
					$RemoveCPGCmd+=" -$option $LD_name"					
				}
				else
				{ 
					Write-DebugLog "Stop: Exiting  Remove-3parCPG   since -option $option in incorrect "
					Return "FAILURE : -option :- $option is an Incorrect option  [i]  can be used only . "
				}
			}
			$RemoveCPGCmd += " $cpgName "
			$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $RemoveCPGCmd
			write-debuglog "Removing CPG  with the command --> $RemoveCPGCmd" "INFO:" 
			
			if (Test-3PARObject -objectType $objType -objectName $cpgName -objectMsg $objMsg -SANConnection $SANConnection)
			{
				write-debuglog " CPG $cpgName exists. Nothing to remove"  "INFO:"  
				return "FAILURE: While removing cpg $cpgName `n $Result3"
			}
			else
			{
				if ($Result3 -match "Removing CPG")
				{
					return "SUCCESS : Removed cpg $cpgName"
				}
				else
				{
					return "FAILURE: While removing cpg $cpgName $Result3"
				}
			}			
		}		
	}
	else
	{
		write-debuglog  "No CPG name mentioned to remove " "INFO:"
		Get-help Remove-3parCPG
	}
		
} # End of Remove-3parCPG

#####################################################################################################################
## FUNCTION Remove-3parVVSet
#####################################################################################################################

Function Remove-3parVVSet
{
<#
  .SYNOPSIS
    Remove a Virtual Volume set or remove VVs from an existing set
  
  .DESCRIPTION
	Removes a VV set or removes VVs from an existing set.
        
  .EXAMPLE
    Remove-3parVVSet -vvsetName "MyVVSet"  -force
	 Remove a VV set "MyVVSet"  
  .EXAMPLE
	Remove-3parVVSet -vvsetName "MyVVSet" -vvName "MyVV" -force
	 Remove a single VV "MyVV" from a vvset "MyVVSet"
	
  .PARAMETER vvsetName 
    Specify name of the vvsetName

  .PARAMETER vvName 
    Specify name of  a vv to remove from vvset

  .PARAMETER force
	If present, perform forcible delete operation
	
	
  .PARAMETER pat
        Specifies that both the set name and VVs will be treated as glob-style patterns.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parVVSet 
    LASTEDIT: 05/11/2015
    KEYWORDS: Remove-3parVVSet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$vvsetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$force,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[switch]
		$Pat,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		

	Write-DebugLog "Start: In Remove-3parVVSet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parVVSet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parVVSet since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	if ($vvsetName)
	{
		if (!($force))
		{
			write-debuglog "no force option is selected to remove vvset, Exiting...." "INFO:"
			return "FAILURE : no -force option is selected to remove vvset"
		}
		$objType = "vvset"
		$objMsg  = "vv set"
		
		## Check vvset Name 		
		if ( -not ( Test-3PARObject -objectType $objType -objectName $vvsetName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " vvset $vvsetName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE : No vvset $vvSetName found"
		}
		else
		{
			$RemovevvsetCmd="removevvset "
			
			$options = "" 
			if($force)
			{
				$RemovevvsetCmd += " -f "
			}
			if($Pat)
			{
				$RemovevvsetCmd += " -pat "
			}
			if($vvName)
			{
				$options+=" $vvName"
			}
			
			$RemovevvsetCmd += " $vvsetName $options "
		
			$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $RemovevvsetCmd
			write-debuglog " Removing vvset  with the command --> $RemovevvsetCmd" "INFO:" 
			if([string]::IsNullOrEmpty($Result1))
			{
				if($vvName)
				{
					return  "SUCCESS : Removed vv $vvName from vvset $vvSetName"
				}
				return  "SUCCESS : Removed vvset $vvSetName"
			}
			else
			{
				return "FAILURE : While removing vvset $vvSetName $Result1"
			}
		}
		
		
	}
	else
	{
		write-debuglog  "No name mentioned for removing vvset" "INFO:"
		Get-help Remove-3parVVSet			
	}
	
	
} # End of Remove-3parVVSet 

#####################################################################################################################
## FUNCTION Remove-3parHostSet
#####################################################################################################################

Function Remove-3parHostSet
{
<#
  .SYNOPSIS
    Remove a host set or remove hosts from an existing set
  
  .DESCRIPTION
	Remove a host set or remove hosts from an existing set
        
  .EXAMPLE
    Remove-3parHostSet -hostsetName "MyHostSet"  -force 
	Remove a hostset  "MyHostSet" 
  .EXAMPLE
	Remove-3parHostSet -hostsetName "MyHostSet" -hostName "MyHost" -force
	Remove a single host "MyHost" from a hostset "MyHostSet"
	
  .PARAMETER hostsetName 
    Specify name of the hostsetName

  .PARAMETER hostName 
    Specify name of  a host to remove from hostset
 
 .PARAMETER force
	If present, perform forcible delete operation
	
 .PARAMETER Pat
	Specifies that both the set name and hosts will be treated as glob-style patterns.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
              
  .Notes
    NAME:  Remove-3parHostSet 
    LASTEDIT: 05/08/2015
    KEYWORDS: Remove-3parHostSet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$hostsetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$force,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$Pat,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		

	Write-DebugLog "Start: In Remove-3parHostSet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parHostSet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parHostSet since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$RemovehostsetCmd = "removehostset "
	if ($hostsetName)
	{
		if (!($force))
		{
			write-debuglog "no force option selected to remove hostset, Exiting...." "INFO:"
			return "FAILURE : no -force option selected to remove hostset"
		}
		$objType = "hostset"
		$objMsg  = "host set"
		
		## Check hostset Name 
		##
		if ( -not ( Test-3PARObject -objectType $objType -objectName $hostsetName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " hostset $hostsetName does not exist. Nothing to remove"  "INFO:"  
			return "FAILURE : No hostset $hostsetName found"
		}
		else
		{	
			if($force)
			{
				$RemovehostsetCmd += " -f "
			}
			if($Pat)
			{
				$RemovehostsetCmd += " -pat "
			}
			
			$options = "" 
			if($hostName)
			{
				$options+=" $hostName"
			}
			$RemovehostsetCmd += " $hostsetName $options "
		
			$Result2 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $RemovehostsetCmd
			
			write-debuglog "Removing hostset  with the command --> $RemovehostsetCmd" "INFO:"
			if([string]::IsNullOrEmpty($Result2))
			{
				if($hostName)
				{
					return "SUCCESS : Removed host $hostName from hostset $hostsetName "
				}
				else
				{
					return "SUCCESS : Removed hostset $hostsetName "
				}
			}
			else
			{
				return "FAILURE : While removing hostset $hostsetName"
			}			
		}
	}
	else
	{
			write-debuglog  "No hostset name mentioned to remove" "INFO:"
			Get-help remove-3parhostset
	}
} # End of Remove-3parHostSet 


#####################################################################################################################
## FUNCTION Get-3parCPG
#####################################################################################################################

Function Get-3parCPG
{
<#
  .SYNOPSIS
    Get list of common provisioning groups (CPGs) in the system.
  
  .DESCRIPTION
    Get list of common provisioning groups (CPGs) in the system.
        
  .EXAMPLE
    Get-3parCPG
	List all/specified common provisioning groups (CPGs) in the system.  
  
  .EXAMPLE
	Get-3parCPG -cpgName "MyCPG" 
	List Specified CPG name "MyCPG"
	
  .EXAMPLE
	Get-3parCPG -Option d -cpgName "MyCPG" 
	 Displays detailed information about the CPGs.

  .EXAMPLE
	Get-3parCPG -Option r -cpgName "MyCPG" 
	  Specifies that raw space used by the CPGs is displayed.
	  
  .EXAMPLE
	Get-3parCPG -Option alerttime -cpgName "MyCPG" 
	  Show times when alerts were posted (when applicable).
	  
  .EXAMPLE
	Get-3parCPG -Option domain -Domain_Name XYZ -cpgName "MyCPG" 
	  Show times with domain name depict.
	 
  .PARAMETER cpgName 
    Specify name of the cpg to be listed.
	
  .PARAMETER Option 
    Specify name of the cpg to be listed.
	
  .PARAMETER cpgName 
     -listcols
        List the columns available to be shown in the -showcols option
        described below (see "clihelp -col showcpg" for help on each column).
		
	-d
        Displays detailed information about the CPGs. The following columns
        are shown:
        Id Name Warn% VVs TPVVs TDVVs UsageUsr UsageSnp Base SnpUsed Free Total
        LDUsr LDSnp RC_UsageUsr RC_UsageSnp DDSType DDSSize

    -r
        Specifies that raw space used by the CPGs is displayed. The following
        columns are shown:
        Id Name Warn% VVs TPVVs TDVVs UsageUsr UsageSnp Base RBase SnpUsed
        SnpRUsed Free RFree Total RTotal

    -alert
        Indicates whether alerts are posted. The following columns are shown:
        Id Name Warn% UsrTotal DataWarn DataLimit DataAlertW% DataAlertW
        DataAlertL DataAlertF

    -alerttime
        Show times when alerts were posted (when applicable). The following
        columns are shown:
        Id Name DataAlertW% DataAlertW DataAlertL DataAlertF

    -sag
        Specifies that the snapshot admin space auto-growth parameters are
        displayed. The following columns are displayed:
        Id Name AdmWarn AdmLimit AdmGrow AdmArgs

    -sdg
        Specifies that the snapshot data space auto-growth parameters are
        displayed. The following columns are displayed:
        Id Name DataWarn DataLimit DataGrow DataArgs

    -space (-s)
        Show the space saving of CPGs. The following columns are displayed:
        Id Name Warn% Shared Private Free Total Compaction Dedup DataReduce Overprov
		
	 -hist
        Specifies that current data from the CPG, as well as the CPG's history
        data is displayed.

    -domain <domain_name_or_pattern,...>
        Shows only CPGs that are in domains with names matching one or more of
        the <domain_name_or_pattern> argument. This option does not allow
        listing objects within a domain of which the user is not a member.
        Patterns are glob-style (shell-style) patterns (see help on sub,globpat).

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parCPG  
    LASTEDIT: 05/15/2015
    KEYWORDS: Get-3parCPG
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param
	(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Domain_Name,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$ColName,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$cpgName,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parCPG - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parCPG since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parCPG since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$GetCPGCmd = "showcpg "
	if($Option)	
	{
		$opt="listcols","d","r","alert","alerttime","sag","sdg","space","hist","domain"
		$Option = $Option.toLower()
		if ($opt -eq $Option)
		{
			$GetCPGCmd += " -$Option"
			if($Option -eq "domain")
			{
				$GetCPGCmd += " $Domain_Name"
			}			
		}
		else
		{
			return " FAILURE : -option $option is Not valid use [ listcols | r | d | alert | alerttime | sag | sdg | space | hist | domain]  Only,  "
		}
	}	
	if ($cpgName)
	{
		$objType = "cpg"
		$objMsg  = "cpg"
		
		## Check cpg Name 
		##
		if ( -not ( Test-3PARObject -objectType $objType -objectName $cpgName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " CPG name $cpgName does not exist. Nothing to display"  "INFO:"  
			return "FAILURE : No cpg $cpgName found"
		}
		$GetCPGCmd += "  $cpgName"
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetCPGCmd	
	if($Option -eq "listcols" -or $Option -eq "hist")
	{
		write-debuglog "$Result" "ERR:" 
		return $Result
	}
	if ( $Result.Count -gt 1)
	{	
		if($Option -eq "alert" -Or $Option -eq "alerttime" -Or $Option -eq "sag" -Or $Option -eq "sdg")
		{			
			$Cnt
			if($Option -eq "alert")
			{
				$Cnt=2
			}
			if($Option -eq "alerttime" -Or $Option -eq "sag" -Or $Option -eq "sdg" )
			{
				$Cnt=1
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count						
			foreach ($s in  $Result[$Cnt..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()									
				Add-Content -Path $tempfile -Value $s				
			}
			if ($CPGName)
				{ 
					if($Option -eq "alert")
					{
						write-host "Column  Total,Warn and Limit values are in (MiB)"
					}
					if($Option -eq "sag" -Or $Option -eq "sdg" )
					{
						write-host "Column  Warn, Limit and Grow values are in (MiB)"
					}
					Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
				}
			else
				{
					if($Option -eq "alert")
					{
						write-host "Column  Total,Warn and Limit values are in (MiB)"
					}
					if($Option -eq "sag" -Or $Option -eq "sdg" )
					{
						write-host "Column  Warn, Limit and Grow values are in (MiB)"
					}
					Import-Csv $tempFile
				}			
			del $tempFile
		}
		elseif($Option -eq "space" -or $Option -eq "domain")
		{			
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count-2
			$incre = "true" 			
			foreach ($s in  $Result[1..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')					
					$sTemp[7]="Snp(Usage)"				
					$sTemp[9]="Snp(MiB)"										
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				Add-Content -Path $tempfile -Value $s
				$incre="false"				
			}
			if ($CPGName)
				{
					if($Option -eq "space" )
					{
						write-host "Column  Base, Snp, Shared, Free and Total values are in (MiB)" 						 
					}
					if($Option -eq "space" )
					{
						write-host "Column  Base, Snp, Free and Total values are in (MiB)"
						 
					}
					Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
				}
			else
				{
				if($Option -eq "space" )
					{
						write-host "Column  Base, Snp, Shared, Free and Total values are in (MiB)" 						 
					}
					if($Option -eq "domain" )
					{
						write-host "Column  Base, Snp, Free and Total values are in (MiB)"
						 
					}
				Import-Csv $tempFile 
				}			
			del $tempFile
		}
		else
		{
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 			
			foreach ($s in  $Result[1..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')
					if($Option -eq "d")
					{
						$sTemp[6]="Usr(Usage)"
						$sTemp[7]="Snp(Usage)"				
						$sTemp[9]="Snp(MiB)"
						$sTemp[12]="Usr(LD)"
						$sTemp[13]="Snp(LD)"
						$sTemp[14]="Usr(RC_Usage)"
						$sTemp[15]="Snp(RC_Usage)"
					}
					elseif($Option -eq "r")
					{
						$sTemp[6]="Usr(Usage)"
						$sTemp[7]="Snp(Usage)"							
						$sTemp[10]="Snp(MiB)"						
					}
					else
					{
						$sTemp[7]="Snp(Usage)"				
						$sTemp[9]="Snp(MiB)"
					}					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}						
				Add-Content -Path $tempfile -Value $s	
				$incre="false"
			}
			if ($CPGName)
				{
				write-host "Column  Base, Snp, Shared, Free and Total values are in (MiB)"
				Import-Csv $tempFile | where  {$_.Name -like $CPGName} 
				}
			else
				{
				write-host "Column  Base, Snp, Shared, Free and Total values are in (MiB)"
				Import-Csv $tempFile
				}			
			del $tempFile
		}
	}
	if($Result -match "FAILURE")
	{		
		write-debuglog "$Result" "ERR:" 
		return $Result
	}
	
		
} # End Get-3parCPG

#####################################################################################################################
## FUNCTION Get-3parVVSet
#####################################################################################################################

Function Get-3parVVSet
{
<#
  .SYNOPSIS
    Get list of Virtual Volume(VV) sets defined on the storage system and their members
  
  .DESCRIPTION
    Get lists of Virtual Volume(VV) sets defined on the storage system and their members
        
  .EXAMPLE
    Get-3parVVSet
	 List all virtual volume set(s)

  .EXAMPLE  
	Get-3parVVSet -vvSetName "MyVVSet" 
	List Specific VVSet name "MyVVSet"
	
  .EXAMPLE  
	Get-3parVVSet -vvName "MyVV" 
	List VV sets containing VVs matching vvname "MyVV"
	
  .PARAMETER vvSetName 
    Specify name of the vvset to be listed.

  .PARAMETER Option 
    
	 -d
        Show a more detailed listing of each set.
    -vv
        Show VV sets that contain the supplied vvnames or patterns
    -summary
        Shows VV sets with summarized output with VV sets names and number of VVs in those sets
	
  .PARAMETER vvName 
     Specifies that the sets containing virtual volumes	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parVVSet  
    LASTEDIT: 05/08/2015
    KEYWORDS: Get-3parVVSet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$vvSetName,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$vvName,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parVVSet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parVVSet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parVVSet since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$GetVVSetCmd = "showvvset "
	if ($option)
	{
		$a = "d","vv","summary"
		$l=$option
		if($a -eq $l)
		{
			$GetVVSetCmd +=" -$option "
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parVVSet   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [d | vv | summary]  can be used only . "
		}
	}
	if ($vvSetName)
	{
		$GetVVSetCmd += "  $vvSetName"
	}
	elseif($vvName)
	{
		$GetVVSetCmd += "  -vv $vvName"
	}
	else
	{
		write-debuglog "VVSet parameter $vvSetName is empty. Simply return all existing vvset " "INFO:"
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetVVSetCmd
		
	if($Result -match "No vv set listed")
	{
		return "FAILURE : No vv set listed"
	}
	if($Result -match "total")
	{		
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count  		
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim()
			Add-Content -Path $tempfile -Value $s
			#Write-Host	" First if statement $s"		
		}
		Import-Csv $tempFile 
		del $tempFile
	}
	else
	{
		return $Result
	}
	write-debuglog "Get list of VVSet " "INFO:" 
	
	
} # End Get-3parVVSet

#####################################################################################################################
## FUNCTION Get-3parHostSet
#####################################################################################################################

Function Get-3parHostSet
{
<#
  .SYNOPSIS
    Get list of  host set(s) information
  
  .DESCRIPTION
    Get list of  host set(s) information
        
  .EXAMPLE
    Get-3parHostSet
	
	List all host set information
	 
  .EXAMPLE
	Get-3parHostSet -hostSetName "MyVVSet"
	
	List Specific HostSet name "MyVVSet"
	
   .EXAMPLE	
	Get-3parHostSet -hostName "MyHost"
	 
	Show the host sets containing host "MyHost"	
	
  .PARAMETER hostSetName 
    Specify name of the hostsetname to be listed.

  .PARAMETER hostName 
    Show the host sets containing hostName	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parHostSet  
    LASTEDIT: 05/08/2015
    KEYWORDS: Get-3parHostSet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$hostSetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$hostName,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parHostSet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHostSet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHostSet since SAN connection object values are null/empty"
			}
		}
	}

	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$GetHostSetCmd = "showhostset "
	if ($hostSetName)
	{		
		$objType = "hostset"
		$objMsg  = "host set"
		
		## Check hostset Name 
		##
		if ( -not ( Test-3PARObject -objectType $objType -objectName $hostSetName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " hostset $hostSetName does not exist. Nothing to List"  "INFO:"  
			return "FAILURE : No hostset $hostSetName found"
		}
		$GetHostSetCmd += "  $hostSetName"		
	}
	
	if ($hostName)
	{		
		$objType = "host"
		$objMsg  = "hosts"
		$hostCmd ="showhost"
		## Check host Name 
		##
		if ( -not ( Test-3PARObject -objectType $objType -objectName $hostName -objectMsg $objMsg -SANConnection $SANConnection)) 
		{
			write-debuglog " host $hostName does not exist. Nothing to List"  "INFO:"  
			return "FAILURE : No host $hostName found"
		}
		$GetHostSetCmd += " -host $hostName "
	}
	else
	{
		write-debuglog "HostSet parameter is empty. Simply return all hostset information " "INFO:"
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetHostSetCmd
	
	if($Result -match "total")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -2  
		#Write-Host " Result Count =" $Result.Count
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s					
		}
		Import-Csv $tempFile 
		del $tempFile	
		
	}
	else
	{
		return $Result
	}
	
	if($Result -match "total")
	{
		return  " SUCCESS : EXECUTING Get-3parHostSet"
	}
	else
	{
		return $Result
	}
	
} # End Get-3parHostSet
########################################
####### FUNCTION GET-3parCmdList   ########
########################################
Function Get-3parCmdList{
<#
  .SYNOPSIS
    Get list of  All HPE3par PowerShell cmdlets
  
  .DESCRIPTION
    Get list of  All HPE3par PowerShell cmdlets
        
  .EXAMPLE
    Get-3parCmdList
	
	List all available HPE3par PowerShell cmdlets
	
  .Notes
    NAME:  Get-3parCmdList  
    LASTEDIT: 05/14/2015
    KEYWORDS: 3parCmdList
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 
 get-help *3par*| where {!($_.Name -eq "Test-3parobject")}|sort Name

 }# Ended Get-3parCmdList

##########################################
####### FUNCTION GET-3PARVersion  ########
##########################################
 
Function Get-3parVersion()
{	
<#
  .SYNOPSIS
    Get list of  HPE 3PAR Storage system software version information 
  
  .DESCRIPTION
    Get list of  HPE 3PAR Storage system software version information
        
  .EXAMPLE
    Get-3parVersion
	
	Get list of  HPE 3PAR Storage system software version information

  .EXAMPLE
    Get-3parVersion -number
	
	Get list of  HPE 3PAR Storage system release version number only
	
  .EXAMPLE
    Get-3parVersion -build
	
	Get list of  HPE 3PAR Storage system build levels
	
  .Notes
    NAME:  Get-3parVersion  
    LASTEDIT: 05/18/2015
    KEYWORDS: 3parVersion
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[switch]
		$number,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$build,
	
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parVersion - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parVersion since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parVersion since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCLi -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if($number)
	{
		$Getversion = "showversion -s"
		Invoke-3parCLICmd -Connection $SANConnection -cmds  $Getversion
		write-debuglog "Get HPE3par version info using cmd $Getversion " "INFO:"
		return
	}
	elseif($build)
	{
		$Getversion = "showversion -b "
	}
	else
	{
		$Getversion = "showversion"
	}
	
	#write-host "test"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Getversion
	write-debuglog "Get version info " "INFO:" 
	
	
	
	$Result = $Result | where { ($_ -notlike '*total*') -and ($_ -notlike '*------*')} ## Eliminate summary lines
	$version = New-Object -TypeName _Version
	$version.ReleaseVersionName = partempgetversion 0 2 3
	$version.Patches = partempgetversion 1 1 2
	$version.CliServer = partempgetversion 4 2 3
	$version.CliClient = partempgetversion 5 2 3
	$version.SystemManager = partempgetversion 6 2 3
	$version.Kernel = partempgetversion 7 1 2
	$version.TPDKernelCode = partempgetversion 8 3 4
	$version
}
function partempgetversion([String] $linenumber,[String] $index1 , [string] $index2)
{
	$s= $Result[$linenumber]
	$s= $s.Trim()
	$s= [regex]::Replace($s," ",",")			# Replace one  spaces with comma 
	$s= [regex]::Replace($s,",+",",")			# Replace one or more commad with with comma 
	$sTemp = $s.Split(',')
	return $sTemp[$index1]+$sTemp[$index2]	
		
}
######################################
### Function Get-3parTask
######################################
Function Get-3parTask
{
<#
  .SYNOPSIS
    Displays information about tasks.
  
  .DESCRIPTION
	Displays information about tasks.
	
  .EXAMPLE
    Get-3parTask 
		Display all tasks.
        
  .EXAMPLE
    Get-3parTask -option all
		Display all tasks. Unless the -all option is specified, system tasks
        are not displayed.
  .EXAMPLE		
	Get-3parTask -option done
		Display includes only tasks that are successfully completed

  .EXAMPLE
	Get-3parTask -option failed
		Display includes only tasks that are unsuccessfully completed.
  .EXAMPLE	
	Get-3parTask -option active
	Display includes only tasks that are currently in progress.
	
  .EXAMPLE	
	Get-3parTask -option t -Hours 10
	 Show only tasks started within the past <hours>
	 
  .EXAMPLE	
	Get-3parTask -option type -Task_type xyz
	  Specifies that specified patterns are treated as glob-style patterns and that all tasks whose types match the specified pattern are displayed
	
  .EXAMPLE	
	Get-3parTask -option d -taskID 4
	 Show detailed task status for specified task 4.
	 
  .PARAMETER Option
	all	Displays all tasks.
	done	Displays only tasks that are successfully completed. 
	failed	Displays only tasks that are unsuccessfully completed. 
	active	Displays only tasks that are currently in progress
	
  .PARAMETER Hours 
    Show only tasks started within the past <hours>, where <hours> is an integer from 1 through 99999.
	
  .PARAMETER Task_type 
     Specifies that specified patterns are treated as glob-style patterns and that all tasks whose types match the specified pattern are displayed. To see the different task types use the showtask column help.
	
  .PARAMETER taskID 
     Show detailed task status for specified tasks. Tasks must be explicitly specified using their task IDs <task_ID>. Multiple task IDs can be specified. This option cannot be used in conjunction with other options.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parTask
    LASTEDIT: 01/23/2017
    KEYWORDS: 3parTask
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,	

		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Hours,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Task_type,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$taskID,   

		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 		
	)		
	
	Write-DebugLog "Start: In Get-3parTask - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parTask since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parTask since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$taskcmd = "showtask "
	
	if ($option)
	{
		$a = "all","done","failed","t","type","d"
		$l=$option
		if($a -eq $l)
		{
			$taskcmd+=" -$option "	
			if($option -eq "t")	
			{
				$taskcmd+=" $Hours "
			}
			if($option -eq "type")	
			{
				$taskcmd+=" $Task_type "
			}
			if($option -eq "d")	
			{
				$taskcmd+=" $taskID "
			}
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parTask   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [ all | done | failed | t | type | d ]  can be used only . "
		}
	}
	
	$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $taskcmd
	#write-host $result 
	write-debuglog " Running get task status  with the command --> $taskcmd" "INFO:" 
	if($Result -match "Id")
	{
		$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count  
			$incre = "true"
			foreach ($s in  $Result[0..$LastItem] )
			{		
				$s= [regex]::Replace($s,"^ ","")			
				$s= [regex]::Replace($s," +",",")	
				$s= [regex]::Replace($s,"-","")
				#$s= $s.Trim()
				$s= $s.Trim() -replace 'StartTime,FinishTime','Date(ST),Time(ST),Zome(ST),Date(FT),Time(FT),Zome(FT)' 
				if($incre -eq "true")
				{
					$s=$s.Substring(1)					
				}				
				Add-Content -Path $tempfile -Value $s
				$incre="false"		
			}
			Import-Csv $tempFile 
			del $tempFile
	}	
	if($Result -match "Id")
	{
		return  " SUCCESS : EXECUTING Get-3parTask"
	}
	else
	{			
		return  $Result
	}	
}

#####################################################################################################################
## FUNCTION New-3parVVCopy
#####################################################################################################################
Function New-3parVVCopy
{
<#
  .SYNOPSIS
    Creates a full physical copy of a Virtual Volume (VV) or a read/write virtual copy on another VV.
  
  .DESCRIPTION
	Creates a full physical copy of a Virtual Volume (VV) or a read/write virtual copy on another VV.
        
  .EXAMPLE
    New-3parVVCopy -parentName VV1 -vvCopyName VV2
	
  .EXAMPLE		
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -online -CPGName CPG_Aslam

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -snapcpg CPG_Aslam

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -vvType as

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -vvType tpvv

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -vvType tdvv

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -vvType dedup

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -vvType compr

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -vvType addtoset

  .EXAMPLE
	New-3parVVCopy -parentName VV1 -vvCopyName VV2 -CPGName CPG_Aslam

  .EXAMPLE
    New-3parVVCopy -parentName vv1 -online -snapcpg cpg2 -CPGName cpg1 -vvCopyName vv2
		
	Create an online copy of vv1 that is named vv2 which is fully-provisioned, using cpg1 as its user space and cpg2 as its snapshot space:

	
  .PARAMETER parentName 
    Specify name of the parent Virtual Volume
	
  .PARAMETER Online 
    Create an online copy of Virtual Volume
	
  .PARAMETER vvCopyName 
    Specify name of the virtual Volume Copy name
	
  .PARAMETER CPGName
    Specify the name of CPG

  .PARAMETER snapcpg
    Specify the name of CPG
	

  .PARAMETER vvType
    -tpvv
        Indicates that the VV the online copy creates should be a thinly
        provisioned volume. Cannot be used with the -dedup option.

    -tdvv
        This option is deprecated, see -dedup.

    -dedup
        Indicates that the VV the online copy creates should be a thinly
        deduplicated volume, which is a thinly provisioned volume with inline
        data deduplication. This option can only be used with a CPG that has
        SSD (Solid State Drive) device type. Cannot be used with the -tpvv
        option.

    -compr
        Indicates that the VV the online copy creates should be a compressed
        virtual volume.

    -snp_cpg <snp_cpg>
        Specifies the name of the CPG from which the snapshot space will be
        allocated.
	 -addtoset <set_name>
        Adds the VV copies to the specified VV set. The set will be created if
        it does not exist. Can only be used with -online option.
		
	.PARAMETER R
        Specifies that the destination volume be re-synchronized with its parent
        volume using a saved snapshot so that only the changes since the last
        copy or resynchronization need to be copied.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parVVCopy  
    LASTEDIT: 05/26/2015
    KEYWORDS: New-3parVVCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$parentName,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$vvCopyName,

		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $online,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $CPGName,		
	
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $snapcpg,
	
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvType,

		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
        $R,
	
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	
	Write-DebugLog "Start: In New-3parVVCopy - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVVCopy since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVVCopy since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	if(!(($parentName) -and ($vvCopyName)))
	{
		write-debuglog " Please specify values for parentName and vvCopyName " "INFO:" 
		Get-help new-3parVVcopy
		return "FAILURE : Please specify values for parentName and vvCopyName"	
	}
	if ( $parentName -match "^set:")	
	{
		$objName = $item.Split(':')[1]
		$vvsetName = $objName
		$objType = "vv set"
		$objMsg  = $objType
		if(!( test-3PARObject -objectType $objType  -objectName $vvsetName -SANConnection $SANConnection))
		{
			write-debuglog " vvset $vvsetName does not exist. Please use New-3parVVSet to create a new vvset " "INFO:" 
			return "FAILURE : No vvset $vvSetName found"
		}
	}
	else
	{
		if(!( test-3PARObject -objectType "vv"  -objectName $parentName -SANConnection $SANConnection))
		{
			write-debuglog " vv $parentName does not exist. Please use New-3parVV to create a new vv " "INFO:" 
			return "FAILURE : No parent VV  $parentName found"
		}
	}
	if($online)
	{			
		if(!( test-3PARObject -objectType 'cpg' -objectName $CPGName -SANConnection $SANConnection))
		{
			write-debuglog " CPG $CPGName does not exist. Please use New-3parCPG to create a CPG " "INFO:" 
			return "FAILURE : No cpg $CPGName found"
		}		
		if( test-3PARObject -objectType 'vv' -objectName $vvCopyName -SANConnection $SANConnection)
		{
			write-debuglog " vv $vvCopyName is exist. For online option vv should not be exists..." "INFO:" 
			return "FAILURE : vv $vvCopyName is exist. For online option vv should not be exists..."
		}		
		$vvcopycmd = "createvvcopy -p $parentName -online "
		if($snapcpg)
		{
			if(!( test-3PARObject -objectType 'cpg' -objectName $snapcpg -SANConnection $SANConnection))
			{
				write-debuglog " Snapshot CPG $snapcpg does not exist. Please use New-3parCPG to create a CPG " "INFO:" 
				return "FAILURE : No snapshot cpg $snapcpg found"
			}
			$vvcopycmd += " -snp_cpg $snapcpg"
		}
		else
		{
			$vvcopycmd += " -snp_cpg $CPGName"
		}		
		if($vvType -match "tpvv")
		{
			$vvcopycmd += " -tpvv "
		}
		if($vvType -match "tdvv")
		{
			$vvcopycmd += " -tdvv "
		}
		if($vvType -match "dedup")
		{
			$vvcopycmd += " -dedup "
		}
		if($vvType -match "compr")
		{
			$vvcopycmd += " -compr "
		}
		if($vvType -match "addtoset")
		{
			$vvcopycmd += " -addtoset "
		}
		if($CPGName)
		{
			$vvcopycmd += " $CPGName "
		}
		$vvcopycmd += " $vvCopyName"
		$Result4 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $vvcopycmd
		write-debuglog " Creating online vv copy with the command --> $vvcopycmd" "INFO:" 
		if($Result4 -match "Copy was started.")
		{		
			return "SUCCESS : $Result4"
		}
		else
		{
			return "FAILURE : $Result4"
		}		
	}
	else
	{
		$vvcopycmd = " createvvcopy -p "
		if($R)
		{ 
			$vvcopycmd += " -r"
		}
		if( !(test-3PARObject -objectType 'vv' -objectName $vvCopyName -SANConnection $SANConnection))
		{
			write-debuglog " vv $vvCopyName does not exist.Please speicify existing vv name..." "INFO:" 
			return "FAILURE : No vv $vvCopyName found"
		}
		$vvcopycmd = " $parentName $vvCopyName"
		$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $vvcopycmd
		write-debuglog " Creating Virtual Copy with the command --> $vvcopycmd" "INFO:" 
		write-debuglog " Check the task status using Get-3parTask command --> Get-3parTask " "INFO:"
		if($Result3 -match "Copy was started")
		{
			return "SUCCESS : $Result3"
		}
		else
		{
			return "FAILURE : $Result3"
		}
	}

}# End New-3parVVCopy

#####################################################################################################################
## FUNCTION New-3parGroupVVCopy
######################################################################################################################

Function New-3parGroupVVCopy
{
<#
  .SYNOPSIS
    Creates consistent group physical copies of a list of virtualvolumes.
  
  .DESCRIPTION
	Creates consistent group physical copies of a list of virtualvolumes.
 
  .EXAMPLE
    New-3parGroupVVCopy –names parentvv1:destvvcopy1
		Creates consistent copies of the parentvv1 to destvvcopy1
  
  .EXAMPLE
    New-3parGroupVVCopy -names $Name -P -S

  .EXAMPLE
     New-3parGroupVVCopy -names $Name -P -Priority high

  .EXAMPLE
     New-3parGroupVVCopy -names $Name -P -Online -TPVV

  .EXAMPLE
     New-3parGroupVVCopy -names $Name -R -S

  .EXAMPLE  
     New-3parGroupVVCopy -names $Name -Halt -S
	
	
  .PARAMETER names 
    Specify name of the parent VV and destination VV in below format 
	ex1: -names parentvolume1:destinationvolume1
	ex2: -names parentvolume1:destinationvolume1,parentvolume2:destinationvolume2
	
  .PARAMETER P
        Starts a copy operation from the specified parent volume (as indicated
        using the <parent_VV> specifier) to its destination volume (as indicated
        using the <destination_VV> specifier). 
  .PARAMETER  R
        Resynchronizes the set of destination volumes (as indicated using the
        <destination_VV> specifier) with their respective parents using saved
        snapshots so that only the changes made since the last copy or
        resynchronization are copied. 

   .PARAMETER Halt
        Cancels an ongoing physical copy. 

   .PARAMETER S
        Saves snapshots of the parent volume (as indicated with the <parent_VV>
        specifier) for quick resynchronization and to retain the parent-copy
        relationships between each parent and destination volume. 

   .PARAMETER B
        Use this specifier to block until all the copies are complete. Without
        this option, the command completes before the copy operations are
        completed (use the showvv command to check the status of the copy
        operations).

   .PARAMETER Priority <high|med|low>
        Specifies the priority of the copy operation when it is started. This
        option allows the user to control the overall speed of a particular task.
        If this option is not specified, the creategroupvvcopy operation is
        started with default priority of medium. High priority indicates that
        the operation will complete faster. Low priority indicates that the
        operation will run slower than the default priority task. This option
        cannot be used with -halt option.

   .PARAMETER Online
        Specifies that the copy is to be performed online. 

   .PARAMETER Skip_zero
        When copying from a thin provisioned source, only copy allocated
        portions of the source VV. 
	 The following options can only be used when the -online option is
    specified:

    .PARAMETER TPVV
        Indicates that the VV the online copy creates should be a thinly
        provisioned volume. Cannot be used with the -dedup option.

    .PARAMETER TdVV
        This option is deprecated, see -dedup.

    .PARAMETER Dedup
        Indicates that the VV the online copy creates should be a thinly
        deduplicated volume, which is a thinly provisioned volume with inline
        data deduplication. This option can only be used with a CPG that has
        SSD (Solid State Drive) device type. Cannot be used with the -tpvv
        option.

    .PARAMETER Compressed
        Indicates that the VV the online copy creates should be a compressed
        virtual volume.    

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parGroupVVCopy  
    LASTEDIT: 05/26/2015
    KEYWORDS: New-3parGroupVVCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$names,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$P,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$R,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Halt,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$S,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$B,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]		
		$Priority,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Skip_zero,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Online,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$TPVV,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$TdVV,
		
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Dedup,
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Compressed,		
		
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-3parGroupVVCopy - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parGroupVVCopy since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parGroupVVCopy since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if($names)
	{
		$vvnameslist=$names
		$objName = $vvnameslist.Split(',')
		$limit = $objName.Length - 1
		foreach($i in 0..$limit)
		{		
			$vvNames = $objName[$i].Split(':')
			foreach($j in 0..1)
			{				
				if(!( test-3PARObject -objectType "vv"  -objectName $vvNames[$j] -SANConnection $SANConnection))
				{
					write-debuglog " vvset $vvNames[$j] does not exist. Please use New-3parVVSet to create a new vv " "INFO:" 
					$outmessage += "FAILURE : No vvset $vvNames[$j] found"
				}
			}
			
			$groupvvcopycmd = "creategroupvvcopy "
			
			$cmdsub =  $objName[$i]
			if($P)
			{
				$groupvvcopycmd += " -p "
			}
			elseif($R)
			{
				$groupvvcopycmd += " -r "
			}
			elseif($Halt)
			{
				$groupvvcopycmd += " -halt "
			}
			else
			{
				return "Please Select Atlist one from P R or Halt"
			}			
			if($S)
			{
				$groupvvcopycmd += " -s "
			}
			if($B)
			{
				$groupvvcopycmd += " -b "
			}
			if($Priority)
			{
				$groupvvcopycmd += " -pri $Priority "
			}
			if($Skip_zero)
			{
				$groupvvcopycmd += " -skip_zero "
			}
			if($Online)
			{
				$groupvvcopycmd += " -online "
				if($TPVV)
				{
					$groupvvcopycmd += " -tpvv "
				}
				if($TdVV)
				{
					$groupvvcopycmd += " -tdvv "
				}
				if($Dedup)
				{
					$groupvvcopycmd += " -dedup "
				}
				if($Compressed)
				{
					$groupvvcopycmd += " -compr "
				}								
			}
			$groupvvcopycmd = " $cmdsub"
			$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $groupvvcopycmd
			write-debuglog " Creating consistent group fo Virtual copies with the command --> $groupvvcopycmd" "INFO:"
			if ($Result1 -match "TaskID")
			{
				$outmessage += "SUCCESS : `n $Result1"
			}
			else
			{
				$outmessage += "FAILURE : `n $Result1"
			}
		}
		return $outmessage
	}
	else 
	{
		write-debuglog " Please specify values for names " "INFO:" 
		Get-help New-3parGroupVVCopy
		return
	}
}# END New-3parGroupVVCopy

#####################################################################################################################
## FUNCTION Push-3parVVCopy
######################################################################################################################

Function Push-3parVVCopy
{
<#
  .SYNOPSIS
    Promotes a physical copy back to a regular base volume
  
  .DESCRIPTION
	Promotes a physical copy back to a regular base volume
        
  .EXAMPLE
    Push-3parVVCopy –physicalCopyName volume1
		Promotes virtual volume "volume1" to a base volume
	
  .PARAMETER –physicalCopyName 
    Specifies the name of the physical copy to be promoted.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parVVCopy 
    LASTEDIT: 05/26/2015
    KEYWORDS: Push-3parVVCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$physicalCopyName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Promote-3parVVCopy - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Promote-3parVVCopy since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Promote-3parVVCopy since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if($physicalCopyName)
	{
		if(!( test-3PARObject -objectType "vv"  -objectName $physicalCopyName -SANConnection $SANConnection))
		{
			write-debuglog " vv $physicalCopyName does not exist. Please use New-3parVV to create a new vv" "INFO:" 
			return "FAILURE : No vv $physicalCopyName found"
		}
		$promotevvcopycmd = "promotevvcopy $physicalCopyName"
		$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $promotevvcopycmd
		
		write-debuglog " Promoting Physical volume with the command --> $promotevvcopycmd" "INFO:"
		if( $Result3 -match "not a physical copy")
		{
			return "FAILURE : $Result3"
		}
		elseif($Result3 -match "FAILURE")
		{
			return "FAILURE : $Result3"
		}
		else
		{
			return $Result3
		}
	}
	else 
	{
		write-debuglog " Please specify values for physicalCopyName " "INFO:" 
		Get-help Push-3parVVCopy
		return
	}
}#END Push-3parVVCopy

####################################################################################################################
## FUNCTION Set-3parVV
#####################################################################################################################

Function Set-3parVV
{
<#
  .SYNOPSIS
    Updates a snapshot Virtual Volume (VV) with a new snapshot.
  
  .DESCRIPTION
	Updates a snapshot Virtual Volume (VV) with a new snapshot.
        
  .EXAMPLE
    Set-3parVV -name volume1 -force
		snapshot update of snapshot VV "volume1"
		
  .EXAMPLE
    Set-3parVV -name volume1,volume2 -force
		snapshot update of snapshot VV's "volume1" and "volume2"
		
  .EXAMPLE
    Set-3parVV -name set:vvset1 -force
		snapshot update of snapshot VVSet "vvset1"
		
  .EXAMPLE
    Set-3parVV -name set:vvset1,set:vvset2 -force
		snapshot update of snapshot VVSet's "vvset1" and "vvset2"
	
  .PARAMETER name 
    Specifies the name(s) of the snapshot virtual volume(s) or virtual volume set(s) to be updated.

  .PARAMETER –ro 
    Specifies that if the specified VV (<VV_name>) is a read/write snapshot the snapshot’s read-only
parent volume is also updated with a new snapshot if the parent volume is not a member of a
virtual volume set

  .PARAMETER –force
    Specifies that the command is forced.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parVV 
    LASTEDIT: 05/26/2015
    KEYWORDS: Set-3parVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$name,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$ro,	
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$force,		
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if(!($name))
	{
		Get-help Set-3parVV
		return
	}
	if($force)
	{		
		if($name)
		{			
			$updatevvcmd="updatevv -f "
			if($ro)
			{
				$updatevvcmd += " -ro "
			}
			$vvtempnames = $name.split(",")
			$limit = $vvtempnames.Length - 1
			foreach ($i in 0..$limit)
			{				
				if ( $vvtempnames[$i] -match "^set:")	
				{
					$objName = $vvtempnames[$i].Split(':')[1]
					$vvsetName = $objName
					$objType = "vv set"
					$objMsg  = $objType
					if(!( test-3PARObject -objectType $objType  -objectName $vvsetName -SANConnection $SANConnection))
					{
						write-debuglog " vvset $vvsetName does not exist. Please use New-3parVVSet to create a new vvset " "INFO:" 
						return "FAILURE : No vvset $vvsetName found"
					}
				}				
				else
				{					
					$subcmd = $vvtempnames[$i]
					if(!( test-3PARObject -objectType "vv"  -objectName $subcmd -SANConnection $SANConnection))
					{
						write-debuglog " vv $vvtempnames[$i] does not exist. Please use New-3parVV to create a new vv" "INFO:" 
						return "FAILURE : No vv $subcmd found"
					}
				}
			}		

			$updatevvcmd += " $vvtempnames "
			$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $updatevvcmd
			write-debuglog " updating a snapshot Virtual Volume (VV) with a new snapshot using--> $updatevvcmd" "INFO:" 
			if($Result1 -match "Permission to perform updatevv")
			{
				return "FAILURE : $Result1"
			}
			else
			{
				return "$Result1"
			}			
		}
		else
		{
			write-debuglog " Please specify values for vvname parameter " "INFO:" 
			return "FAILURE : Please specify values for vvname parameter"
		}
		
	}
	else 
	{
		write-debuglog " Please specify -force option to use this command " "INFO:" 
		return "FAILURE : Please specify -force option to use this command"
	}
}#END Set-3parVV
####################################################################################################################
## FUNCTION New-3parSnapVolume
#####################################################################################################################
Function New-3parSnapVolume
{
<#
  .SYNOPSIS
    creates a point-in-time (snapshot) copy of a virtual volume.
  
  .DESCRIPTION
	creates a point-in-time (snapshot) copy of a virtual volume.
        
  .EXAMPLE
   New-3parSnapVolume -svName  svr0_vv0 -vvName vv0 
   Ceates a read-only snapshot volume "svro_vv0" from volume "vv0" 
   
  .EXAMPLE
   New-3parSnapVolume  -svName  svr0_vv0 -vvName vv0 -ro -exp 25H
   Ceates a read-only snapshot volume "svro_vv0" from volume "vv0" and that will expire after 25 hours
   
  .EXAMPLE
   New-3parSnapVolume -svName svrw_vv0 -vvName svro_vv0
   creates snapshot volume "svrw_vv0" from the snapshot "svro_vv0"
   
  .EXAMPLE
   New-3parSnapVolume -ro svName svro-@vvname@ -vvSetName set:vvcopies 
   creates a snapshot volume for each member of the VV set "vvcopies". Each snapshot will be named svro-<name of parent virtual volume>:
  
  .PARAMETER svName 
    Specify  the name of the Snap shot	
	
  .PARAMETER vvName 
    Specifies the parent volume name or volume set name. 

  .PARAMETER vvSetName 
    Specifies the virtual volume set names as set: vvset name example: "set:vvcopies" 
	
  .PARAMETER Comment 
    Specifies any additional information up to 511 characters for the volume. 
	
  .PARAMETER VV_ID 
    Specifies the ID of the copied VV set. This option cannot be used when VV set is specified. 
	
  .PARAMETER Rcopy 
     Specifies that synchronous snapshots be taken of a volume in a remote copy group. 
	
  .PARAMETER exp 
    Specifies the relative time from the current time that volume will expire.-exp <time>[d|D|h|H]
	<time> is a positive integer value and in the range of 1 - 43,800 hours (1,825 days). Time can be optionally specified in days or hours providing either d or D for day and h or H for hours following the entered time value. 
	
  .PARAMETER retain
	Specifies the amount of time, relative to the current time, that the volume will be retained. <time>
	is a positive integer value and in the range of 1 - 43,800 hours (1,825 days). Time can be
	optionally specified in days or hours providing either d or D for day and h or H for hours following
	the entered time value.  
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parSnapVolume  
    LASTEDIT: 05/26/2015
    KEYWORDS: New-3parSnapVolume
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$svName,
				
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$VV_ID,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$exp,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$retain,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$ro, 
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Rcopy,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvSetName,	

		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Comment,
						
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)	

	Write-DebugLog "Start: In New-3parSnapVolume - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parSnapVolume since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parSnapVolume since SAN connection object values are null/empty"
			}
		}
	}	
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	if ($svName)
	{
		if ($vvName)
		{
			## Check vv Name 
			if ( !( test-3PARObject -objectType 'vv' -objectName $vvName -SANConnection $SANConnection))
			{
				write-debuglog " VV $vvName does not exist. Please use New-3parVV to create a VV before creating SV" "INFO:" 
				return "FAILURE :  No vv $vvName found"
			}						
			$CreateSVCmd = "createsv" 
			if($ro)
			{
				$CreateSVCmd += " -ro "
			}
			if($Rcopy)
			{
				$CreateSVCmd += " -rcopy "
			}
			if($VV_ID)
			{
				$CreateSVCmd += " -i $VV_ID "
			}
			if($exp)
			{
				$CreateSVCmd += " -exp $exp "
			}
			if($retain)
			{
				$CreateSVCmd += " -f -retain $retain  "
			}
			if($Comment)
			{
				$CreateSVCmd += " -comment $Comment  "
			}
			$CreateSVCmd +=" $svName $vvName "

			$result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateSVCmd
			write-debuglog " Creating Snapshot Name $svName with the command --> $CreateSVCmd" "INFO:"
			if([string]::IsNullOrEmpty($result1))
			{
				return  "SUCCESS : Created virtual copy $svName"
			}
			else
			{
				return  "FAILURE : While creating virtual copy $svName $result1"
			}		
		}
		# If VolumeSet is specified then add SV to VVset
		elseif ($vvSetName)
		{
			if ( $vvSetName -match "^set:")	
			{
				$objName = $vvSetName.Split(':')[1]
				$objType = "vv set"
				if ( ! (Test-3PARObject -objectType $objType -objectName $objName -SANConnection $SANConnection))
				{
					Write-DebugLog " VV set $vvSetName does not exist. Please use New-3parVVSet to create a VVSet before creating SV" "INFO:"
					return "FAILURE : No vvset $vvsetName found"
				}
				$CreateSVCmdset = "createsv" 
				if($ro)
				{
					$CreateSVCmdset += " -ro "
				}
				if($Rcopy)
				{
					$CreateSVCmd += " -rcopy "
				}
				if($exp)
				{
					$CreateSVCmd += " -exp $exp "
				}
				if($retain)
				{
					$CreateSVCmd += " -f -retain $retain  "
				}
				if($Comment)
				{
					$CreateSVCmd += " -comment $Comment  "
				}
				$CreateSVCmdset +=" $svName $vvSetName "

				$result2 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateSVCmdset
				write-debuglog " Creating Snapshot Name $svName with the command --> $CreateSVCmdset" "INFO:" 	
				if([string]::IsNullOrEmpty($result2))
				{
					return  "SUCCESS : Created virtual copy $svName"
				}
				elseif($result2 -match "use by volume")
				{
					return "FAILURE : While creating virtual copy $result2"
				}
				else
				{
					return  "FAILURE : While creating virtual copy $svName $result2"
				}
			}
			else
			{
				return "VV Set name must contain set:"
			}
		}
		else
		{
			write-debugLog "No VVset or VVName specified to assign snapshot to it" "ERR:" 
			return "FAILURE : No vvset or vvname specified"
		}
		
		
	}
	else
	{
		write-debugLog "No svName specified for new Snapshot volume. Skip creating Snapshot volume" "ERR:"
		Get-help New-3parSnapVolume
		return	
	}
}#END New-3parSnapVolume

####################################################################################################################
## FUNCTION Push-3parSnapVolume
#####################################################################################################################
Function Push-3parSnapVolume
{
<#
  .SYNOPSIS
    This command copies the differences of a snapshot back to its base volume, allowing
you to revert the base volume to an earlier point in time.
  
  .DESCRIPTION
	This command copies the differences of a snapshot back to its base volume, allowing
you to revert the base volume to an earlier point in time.
        
  .EXAMPLE
   Push-3parSnapVolume -name vv1 
	copies the differences of a snapshot back to its base volume "vv1"
	
  .EXAMPLE
   Push-3parSnapVolume -target vv23 -name vv1 
	copies the differences of a snapshot back to target volume "vv23" of volume "vv1"
	
  .PARAMETER name 
    Specifies the name of the virtual copy volume or set of virtual copy volumes to be promoted 
	
  .PARAMETER target 
    Copy the differences of the virtual copy to the specified RW parent in the same virtual volume
    family tree.
	
  .PARAMETER RCP
  
	-rcp
        Allows the promote operation to proceed even if the RW parent volume is
        currently in a Remote Copy volume group, if that group has not been
        started. If the Remote Copy group has been started, this command fails.
        This option cannot be used in conjunction with the -halt option.
  
  .PARAMETER Halt
  
   -halt
        Cancels an ongoing snapshot promotion. Marks the RW parent volume with
        the "cpf" status that can be cleaned up using the promotevvcopy command
        or by issuing a new instance of the promotesv command. This option
        cannot be used in conjunction with any other option.    
   
  .PARAMETER PRI
  
	-pri <high|med|low>
        Specifies the priority of the copy operation when it is started. This
        option allows the user to control the overall speed of a particular
        task.  If this option is not specified, the promotesv operation is
        started with default priority of medium. High priority indicates that
        the operation will complete faster. Low priority indicates that the
        operation will run slower than the default priority task. This option
        cannot be used with -halt option.    
  
  .PARAMETER Online
  
	-online
        Indicates that the promote operation will be executed while the target
        volume has VLUN exports. The host should take the target LUN offline to
        initiate the promote command, but can bring it online and use it during
        the background task. The specified virtual copy and its base volume must
        be the same size. The base volume is the only possible target of online
        promote, and is the default. To halt a promote started with the online
        option, use the canceltask command. The -halt, -target, and -pri options
        cannot be combined with the -online option.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parSnapVolume 
    LASTEDIT: 05/27/2015
    KEYWORDS: Push-3parSnapVolume
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
 [CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$name,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$target,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$RCP,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Halt,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$PRI,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Online,		
							
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)	
	Write-DebugLog "Start: In Push-3parSnapVolume - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parSnapVolume since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parSnapVolume since SAN connection object values are null/empty"
			}
		}
	}	
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$promoCmd = "promotesv"	
	if($target)
	{
		## Check Target Name 
		if ( !( test-3PARObject -objectType 'vv' -objectName $target -SANConnection $SANConnection))
		{
			write-debuglog " VV $target does not exist. " "INFO:" 
			$promoCmd += " -target $target "
			return "FAILURE : No vv $target found"
		}
		$promoCmd += " -target $target "	
	}
	if ($RCP)
 	{
		$promoCmd += " -rcp "
	}
	if ($Halt)
 	{
		$promoCmd += " -halt "
	}
	if ($PRI)
 	{
		$promoCmd += " -pri $PRI "
	}
	if ($Online)
 	{
		$promoCmd += " -online "
	}
	if ($name)
 	{		
		## Check vv Name 
		if ( !( test-3PARObject -objectType 'vv' -objectName $name -SANConnection $SANConnection))
		{
			write-debuglog " VV $vvName does not exist. Please use New-3parVV to create a VV before creating SV" "INFO:" 
			return "FAILURE : No vv $vvName found"
		}								
		$promoCmd += " $name "
		$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $promoCmd
		#write-host $result -ForegroundColor DARKGRAY
		write-debuglog " Promoting Snapshot Volume Name $vvName with the command --> $promoCmd" "INFO:" 
		Return $result
	}		
	else
	{
		write-debugLog "No vvName specified to Promote snapshot " "ERR:" 
		Get-help Push-3parSnapVolume
		return
	}
}#END Push-3parSnapVolume

#####################################################################################################################
## FUNCTION New-3parGroupSnapVolume
#####################################################################################################################

Function New-3parGroupSnapVolume
{
<#
  .SYNOPSIS
    creates consistent group snapshots
  
  .DESCRIPTION
	creates consistent group snapshots
        
  .EXAMPLE
	New-3parGroupSnapVolume.

  .EXAMPLE
	New-3parGroupSnapVolume -vvNames WSDS_compr02F.
	
  .EXAMPLE
	New-3parGroupSnapVolume -vvNames WSDS_compr02F -exp 2d
 
  .EXAMPLE
	New-3parGroupSnapVolume -vvNames WSDS_compr02F -retain 2d
  
  .EXAMPLE
	NNew-3parGroupSnapVolume -vvNames WSDS_compr02F -Comment Hello
	
  .EXAMPLE
	New-3parGroupSnapVolume -vvNames WSDS_compr02F -OR
	
  .PARAMETER vvNames 
    Specify the Existing virtual volume with comma(,) seperation ex: vv1,vv2,vv3.
	
  .PARAMETER Comment 	
	 Specifies any additional information up to 511 characters for the volume.
	
  .PARAMETER  exp 
	Specifies the relative time from the current time that volume will expire. <time>[d|D|h|H] <time> is a positive integer value and in the range of 1 - 43,800 hours (1,825 days). Time can be optionally specified in days
	or hours providing either d or D for day and h or H for hours following the entered time value.
    
  .PARAMETER  retain
	Specifies the amount of time, relative to the current time, that the volume will be retained.-retain <time>[d|D|h|H]
	<time> is a positive integer value and in the range of 1 - 43,800 hours (1,825 days). Time can be
	optionally specified in days or hours providing either d or D for day and h or H for hours following
	the entered time value.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parGroupSnapVolume  
    LASTEDIT: 05/26/2015
    KEYWORDS: New-3parGroupSnapVolume
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vvNames,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$OR, 
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$exp,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$retain,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Comment,
								
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	Write-DebugLog "Start: In New-3parGroupSnapVolume - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parGroupSnapVolume since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parGroupSnapVolume since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if ($vvNames)
	{
		$CreateGSVCmd = "creategroupsv" 

		if($exp)
		{
			$CreateGSVCmd += " -exp $exp "
		}
		if($retain)
		{
			$CreateGSVCmd += " -f -retain $retain "
		}		
		if($Comment)
		{
			$CreateGSVCmd += " -comment $Comment "
		}
		if($OR)
		{
			$CreateGSVCmd += " -ro "
		}
		$vvName1 = $vvNames.Split(',')
		## Check vv Name 
		$limit = $vvName1.Length - 1
		foreach($i in 0..$limit)
		{
			if ( !( test-3PARObject -objectType 'vv' -objectName $vvName1[$i] -SANConnection $SANConnection))
			{
				write-debuglog " VV $vvName1[$i] does not exist. Please use New-3parVV to create a VV before creating 3parGroupSnapVolume" "INFO:" 
				return "FAILURE : No vv $vvName1[$i] found"
			}
		}
		
		$CreateGSVCmd += " $vvName1 "	
		$result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $CreateGSVCmd
		write-debuglog " Creating Snapshot Name with the command --> $CreateGSVCmd" "INFO:"
		if($result1 -match "CopyOfVV")
		{
			return "SUCCESS : Executing New-3parGroupSnapVolume `n $result1"
		}
		else
		{
			return "FAILURE : Executing New-3parGroupSnapVolume `n $result1"
		}		
	}
	else
	{
		write-debugLog "No vvNames specified for new Snapshot volume. Skip creating Group Snapshot volume" "ERR:"
		Get-help New-3parGroupSnapVolume
		return	
	}
}# END New-3parGroupSnapVolume	

#####################################################################################################################
## FUNCTION Push-3parGroupSnapVolume
#####################################################################################################################

Function Push-3parGroupSnapVolume
{
<#
  .SYNOPSIS
    Copies the differences of snapshots back to their base volumes.
  
  .DESCRIPTION
	Copies the differences of snapshots back to their base volumes.
        
  .EXAMPLE
    Push-3parGroupSnapVolume
	
  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr02F

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames "WSDS_compr02F"

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames "tesWSDS_compr01t_lun"

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr01 -RCP

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr01 -Halt

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr01 -PRI high

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr01 -Online

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr01 -TargetVV at

  .EXAMPLE
	Push-3parGroupSnapVolume -VVNames WSDS_compr01 -TargetVV y

  .PARAMETER VVNames 
    Specify virtual copy name of the Snap shot
	
  .PARAMETER TargetVV 
    Target vv Name

  .PARAMETER RCP 
	Allows the promote operation to proceed even if the RW parent volume is
	currently in a Remote Copy volume group, if that group has not been
	started. If the Remote Copy group has been started, this command fails.
	This option cannot be used in conjunction with the -halt option.

  .PARAMETER Halt 
    Cancels ongoing snapshot promotions. Marks the RW parent volumes with
	the "cpf" status that can be cleaned up using the promotevvcopy command
	or by issuing a new instance of the promotesv/promotegroupsv command.
	This option cannot be used in conjunction with any other option.

  .PARAMETER PRI 
    Specifies the priority of the copy operation when it is started. This
	option allows the user to control the overall speed of a particular
	task.  If this option is not specified, the promotegroupsv operation is
	started with default priority of medium. High priority indicates that
	the operation will complete faster. Low priority indicates that the
	operation will run slower than the default priority task. This option
	cannot be used with -halt option.

  .PARAMETER Online 
    Indicates that the promote operation will be executed while the target
	volumes have VLUN exports. The hosts should take the target LUNs offline
	to initiate the promote command, but can be brought online and used
	during the background tasks. Each specified virtual copy and its base
	volume must be the same size. The base volume is the only possible
	target of online promote, and is the default. To halt a promote started
	with the online option, use the canceltask command. The -halt, -target,
	and -pri options cannot be combined with the -online option.	
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parGroupSnapVolume
    LASTEDIT: 05/27/2015
    KEYWORDS: Push-3parGroupSnapVolume
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
 [CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$VVNames,
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$TargetVV,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$RCP,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Halt,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$PRI,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$Online,
						
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	Write-DebugLog "Start: In Push-3parGroupSnapVolume - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parGroupSnapVolume since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parGroupSnapVolume since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	if($VVNames)
	{
		$PromoteCmd = "promotegroupsv " 
		$objNames = $VVNames.Split(',')
		$limit = $objNames.Length - 1
		foreach($i in 0..$limit)
		{
			$tempvvs = $objNames[$i].Split(':')
			foreach($j in 0..1)
			{
				if($tempvvs[$j])
				{
					if ( !( test-3PARObject -objectType 'vv' -objectName $tempvvs[$j] -SANConnection $SANConnection))
					{
						write-debuglog " VV $tempvvs[$j] does not exist. " "INFO:" 
						return "FAILURE : No vv $tempvvs[$j] found"
					}
				}
			}
		}
		if ($TargetVV)
		{
			$PromoteCmd += " $TargetVV "
		}
		if ($RCP)
		{
			$PromoteCmd += " -rcp "
		}
		if ($Halt)
		{
			$PromoteCmd += " -halt "
		}
		if ($PRI)
		{
			$PromoteCmd += " -pri $PRI "
		}
		if ($Online)
		{
			$PromoteCmd += " -online "
		}		
		$PromoteCmd += " $objNames "		
		$result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $PromoteCmd
		write-debuglog " Promoting Group Snapshot with $VVNames with the command --> $PromoteCmd" "INFO:" 
		if( $result -match "has been started to promote virtual copy")
		{
			return "SUCCESS : Execute Push-3parGroupSnapVolume `n $result"
		}
		elseif($result -match "Error: Base volume may not be promoted")
		{
			return "FAILURE : While Executing Push-3parGroupSnapVolume `Error: Base volume may not be promoted"
		}
		elseif($result -match "has exports defined")
		{
			return "FAILURE : While Executing Push-3parGroupSnapVolume `n $result"
		}
		else
		{
			return "FAILURE : While Executing Push-3parGroupSnapVolume `n $result"
		}
	}
	else
	{
		write-debugLog "No VVNames specified to promote " "ERR:" 
		Get-help Push-3parGroupSnapVolume
		return
	}
}#END Push-3parGroupSnapVolume	

########################################################################################################
## FUNCTION Get-3parVVList
########################################################################################################
Function Get-3parVVList
{
<#
  .SYNOPSIS
    Get list of virtual volumes 
  
  .DESCRIPTION
    Get list of virtual volumes 
        
  .EXAMPLE
    Get-3parVVList
	List all virtual volumes
  .EXAMPLE	
	Get-3parVVList -vvName PassThru-Disk 
	List virtual volume PassThru-Disk
  .EXAMPLE	
	Get-3parVVList -Prov tpvv
	List virtual volume  provision type as "tpvv"
  .EXAMPLE	
	Get-3parVVList  -Type vcopy
	List snapshot(vitual copy) volumes 

  .PARAMETER Option
	
	 -listcols
        List the columns available to be shown in the -showcols option
        described below (see 'clihelp -col showvv' for help on each column).

    The [options] are generally of two kinds: those that select the type of
    information that is displayed, and those that filter the list of VVs that
    are displayed.

    By default (if none of the information selection options below are
    specified) the following columns are shown:
    Id Name Prov Compr Dedup Type CopyOf BsId Rd State Adm_Rsvd_MB Snp_Rsvd_MB
    Usr_Rsvd_MB VSize_MB

    Options that select the type of information shown include the following:

    -showcols <column>[,<column>...]
        Explicitly select the columns to be shown using a comma-separated list
        of column names.  For this option the full column names are shown in
        the header.
        Run 'showvv -listcols' to list the available columns.
        Run 'clihelp -col showvv' for a description of each column.

    -d
        Displays detailed information about the VVs.  The following columns
        are shown:
        Id Name Rd Mstr Prnt Roch Rwch PPrnt PBlkRemain VV_WWN CreationTime Udid

    -pol
        Displays policy information about the VVs. The following columns
        are shown: Id Name Policies

    -space (-s)
        Displays Logical Disk (LD) space use by the VVs.  The following columns
        are shown:
        Id Name Prov Compr Dedup Type Adm_Rsvd_MB Adm_Used_MB Snp_Rsvd_MB
        Snp_Used_MB Snp_Used_Perc Warn_Snp_Perc Limit_Snp_Perc Usr_Rsvd_MB
        Usr_Used_MB Usr_Used_Perc Warn_Usr_Perc Limit_Usr_Perc Tot_Rsvd_MB
        Tot_Used_MB VSize_MB Host_Wrt_MB Compaction Compression

        Note: For snapshot (vcopy) VVs, the Adm_Used_MB, Snp_Used_MB,
        Usr_Used_MB and the corresponding _Perc columns have a '*' before
        the number for two reasons: to indicate that the number is an estimate
        that must be updated using the updatesnapspace command, and to indicate
        that the number is not included in the total for the column since the
        corresponding number for the snapshot's base VV already includes that
        number.

    -r
        Displays raw space use by the VVs.  The following columns are shown:
        Id Name Prov Compr Dedup Type Adm_RawRsvd_MB Adm_Rsvd_MB Snp_RawRsvd_MB
        Snp_Rsvd_MB Usr_RawRsvd_MB Usr_Rsvd_MB Tot_RawRsvd_MB Tot_Rsvd_MB
        VSize_MB

    -zone
        Displays mapping zone information for VVs.
        The following columns are shown:
        Id Name Prov Compr Dedup Type VSize_MB Adm_Zn Adm_Free_Zn Snp_Zn
        Snp_Free_Zn Usr_Zn Usr_Free_Zn

    -g
        Displays the SCSI geometry settings for the VVs.  The following
        columns are shown: Id Name SPT HPC SctSz

    -alert
        Indicates whether alerts are posted on behalf of the VVs.
        The following columns are shown:
        Id Name Prov Compr Dedup Type VSize_MB Snp_Used_Perc Warn_Snp_Perc
        Limit_Snp_Perc Usr_Used_Perc Warn_Usr_Perc Limit_Usr_Perc
        Alert_Adm_Fail_Y Alert_Snp_Fail_Y Alert_Snp_Wrn_Y Alert_Snp_Lim_Y
        Alert_Usr_Fail_Y Alert_Usr_Wrn_Y Alert_Usr_Lim_Y

    -alerttime
        Shows times when alerts were posted (when applicable).
        The following columns are shown:
        Id Name Alert_Adm_Fail Alert_Snp_Fail Alert_Snp_Wrn Alert_Snp_Lim
        Alert_Usr_Fail Alert_Usr_Wrn Alert_Usr_Lim

    -cpprog
        Shows the physical copy and promote progress.
        The following columns are shown:
        Id Name Prov Compr Dedup Type CopyOf VSize_MB Copied_MB Copied_Perc

    -cpgalloc
        Shows CPGs associated with each VV.  The following columns are
        shown: Id Name Prov Compr Dedup Type UsrCPG SnpCPG

    -state
        Shows the detailed state information for the VVs.  The following
        columns are shown: Id Name Prov Compr Dedup Type State Detailed_State SedState

    -hist
        Shows the history information of the VVs.
        The following columns are shown:
        Id Name Prov Compr Dedup Type CreationTime RetentionEndTime ExpirationTime SpaceCalcTime Comment

    -rcopy
        This option appends two columns, RcopyStatus and RcopyGroup, to
        any of the display options above.

    -notree
        Do not display VV names in tree format.
        Unless either the -notree or the -sortcol option described below
        are specified, the VVs are ordered and the  names are indented in
        tree format to indicate the virtual copy snapshot hierarchy.

	 -expired
        Show only VVs that have expired.    

    -failed
        Shows only failed VVs.
		
  .PARAMETER column
        Explicitly select the columns to be shown
	
  .PARAMETER vvName 
    Specify name of the volume. 
	If prefixed with 'set:', the name is a volume set name.	

  .PARAMETER Prov 
    Specify name of the Prov type (full | tpvv |tdvv |snp |cpvv ). 
	
  .PARAMETER Type 
    Specify name of the Prov type ( base | vcopy ).
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parVVList
    LASTEDIT: 05/29/2015
    KEYWORDS: Get-3parVVList
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Column,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$vvName,
	
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Prov,
	
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Type,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parVV - validating input values" $Debug 

	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parVVList since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parVVList since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection

	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$GetvVolumeCmd = "showvv "
	if ($option)
	{
		$a = "listcols","showcols","d","pol","space","r","zone","g","alert","alerttime","cpprog","cpgalloc","state","hist","rcopy","notree","expired","failed"
		$l=$option
		if($a -eq $l)
		{			
			$GetvVolumeCmd+=" -$option "	
			if ($option -eq "listcols")
			{				
				$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetvVolumeCmd
				return $Result				
			}
			if ($option -eq "showcols")
			{				
				$GetvVolumeCmd+=" $Column"				
			}			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parVVList   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [failed | expired | notree | listcols | showcols | d | pol | space | r | zone | g | alert | alerttime | cpprog | cpgalloc | state | hist | rcopy]  can be used only . "
		}
	}
	if ($vvName)
	{
		$GetvVolumeCmd += " $vvName"
	}	

	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetvVolumeCmd
	write-debuglog "Get list of Virtual Volumes" "INFO:" 
	
	if($Result -match "no vv listed"){
		return "FAILURE : No vv $vvName found"
	}
	$tempFile = [IO.Path]::GetTempFileName()
		
	if ( $Result.Count -gt 1)
	{
		$cnt=1
		if ($option)
		{
			$cnt=0
		}
		if ($option -eq "zone" -Or $option -eq "rcopy" -Or $option -eq "notree" -Or $option -eq "failed")
		{
			$cnt=1
		}
		if($option -eq "space" -Or $option -eq "r" -Or $option -eq "alert" -Or $option -eq "alerttime")
		{
			$cnt=2
		}
		$incre = "true"
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -3  
		foreach ($s in  $Result[$cnt..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")		# Replace one or more spaces with comma to build CSV line			
			$s= $s.Trim() -replace ',Id,Name,Prov,Type,CopyOf,BsId,Rd,-Detailed_State-,Adm,Snp,Usr,VSize',',Id,Name,Prov,Type,CopyOf,BsId,Rd,-Detailed_State-,Adm(MB),Snp(MB),Usr(MB),VSize(MB)' 	
			if($option -eq "space")
			{			
				if($incre -eq "true")
				{								
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')	
					$sTemp[6]="Rsvd(MiB/Snp)"					
					$sTemp[7]="Used(MiB/Snp)"				
					$sTemp[8]="Used(VSize/Snp)"
					$sTemp[9]="Wrn(VSize/Snp)"
					$sTemp[10]="Lim(VSize/Snp)"  
					$sTemp[11]="Rsvd(MiB/Usr)"					
					$sTemp[12]="Used(MiB/Usr)"				
					$sTemp[13]="Used(VSize/Usr)"
					$sTemp[14]="Wrn(VSize/Usr)"
					$sTemp[15]="Lim(VSize/Usr)"
					$sTemp[16]="Rsvd(MiB/Total)"					
					$sTemp[17]="Used(MiB/Total)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			if($option -eq "r")
			{			
				if($incre -eq "true")
				{					
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')	
					$sTemp[6]="RawRsvd(Snp)"					
					$sTemp[7]="Rsvd(Snp)"				
					$sTemp[8]="RawRsvd(Usr)"
					$sTemp[9]="Rsvd(Usr)"
					$sTemp[10]="RawRsvd(Tot)"  
					$sTemp[11]="Rsvd(Tot)"					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			if($option -eq "zone")
			{
				if($incre -eq "true")
				{				
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')											
					$sTemp[7]="Zn(Adm)"				
					$sTemp[8]="Free_Zn(Adm)"
					$sTemp[9]="Zn(Snp)"	
					$sTemp[10]="Free_Zn(Snp)"
					$sTemp[11]="Zn(Usr)"		
					$sTemp[12]="Free_Zn(Usr)"					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp				
				}
			}
			if($option -eq "alert")
			{
				if($incre -eq "true")
				{				
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')											
					$sTemp[7]="Used(Snp(%VSize))"				
					$sTemp[8]="Wrn(Snp(%VSize))"
					$sTemp[9]="Lim(Snp(%VSize))"	
					$sTemp[10]="Used(Usr(%VSize))"				
					$sTemp[11]="Wrn(Usr(%VSize))"
					$sTemp[12]="Lim(Usr(%VSize))"	
					$sTemp[13]="Fail(Adm)"	
					$sTemp[14]="Fail(Snp)"	
					$sTemp[15]="Wrn(Snp)"	
					$sTemp[16]="Lim(Snp)"	
					$sTemp[17]="Fail(Usr)"	
					$sTemp[18]="Wrn(Usr)"	
					$sTemp[19]="Lim(Usr)"					
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			if($option -eq "alerttime")
			{
				if($incre -eq "true")
				{				
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')											
					$sTemp[2]="Fail(Adm))"				
					$sTemp[3]="Fail(Snp)"
					$sTemp[4]="Wrn(Snp)"	
					$sTemp[5]="Lim(Snp)"				
					$sTemp[6]="Fail(Usr)"
					$sTemp[7]="Wrn(Usr)"	
					$sTemp[8]="Lim(Usr)"										
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
			}
			Add-Content -Path $tempfile -Value $s
			$incre="false"
		}
		
		if ($Prov)
			{ Import-Csv $tempFile | where  {$_.Prov -like $Prov} }
		elseif($Type)
			{ Import-Csv $tempFile | where  {$_.Type -like $Type} }
		else{ Import-Csv $tempFile}
		
		
		del $tempFile
	}	
	else
	{
		Write-DebugLog $result "INFO:"
		return "FAILURE : No vv $vvName found Error : $Result"
	}
	

} # END GET-3parVVList
# End


#######################################################################################################
## FUNCTION Get-3parSystem
########################################################################################################
Function Get-3parSystem
{
<#
  .SYNOPSIS
    Command displays the 3PAR Storage system information. 
  
  .DESCRIPTION
    Command displays the 3PAR Storage system information.
        
  .EXAMPLE
    Get-3parSystem 
	Command displays the 3PAR Storage system information.such as system name, model, serial number, and system capacity information.
  .EXAMPLE
    Get-3parSystem -Option space
	Lists 3PAR Storage system space information in MB(1024^2 bytes)
  	
  .PARAMETER Option
	space 
    Displays the system capacity information in MB (1024^2 bytes)
    domainspace 
    Displays the system capacity information broken down by domain in MB(1024^2 bytes)	
    fan 
    Displays the system fan information.
    date	
	command displays the date and time for each system node
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSystem
    LASTEDIT: 01/23/2017
    KEYWORDS: Get-3parSystem
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	$Option = $Option.toLower()
	Write-DebugLog "Start: In Get-3parSystem - validating input values" $Debug 

	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSystem since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSystem since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$sysinfocmd = "showsys "

	if(!($option))
	{
		$options = " -d "
		$cmd4 = $sysinfocmd+$options
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd4
		write-debuglog "Get 3par system information " "INFO:" 
		write-debuglog "Get 3par system fan information cmd -> $cmd4 " "INFO:"
		#$Result1 = $Result | where { ($_ -notlike '*---*')} ## Eliminate summary lines
		$tempFile = [IO.Path]::GetTempFileName()
		$sysinfo = @{}
		foreach ($s in  $Result[0..$Result.Count] )
		{
			if(-not $s)
			{
				continue
			}
			else
			{			
				$s= [regex]::Replace($s,"-","")
				$splits = $s.split(":")
				$final1 = $splits[0].trim()
				$final2 = $final1.replace(" ","_")	
				$testcontains = "System Capacity (MB)","System Fan","System Descriptors"					
				if($testcontains -like $final1){
					break
				}		
				if ( $splits[1]){
					$final3 = $splits[1].trim()				
					$sysinfo.add($final2,$final3)				
				}
			}
		}
		$sysinfo
		return
	}
	$options1  = "space","domainspace","fan","date"
	if($option)
	{
		if(!($options1 -eq $option))
		{
			write-host "FAILURE : Option should be in [ $options1 ]" 
			return 
		}	
	}
	if($Option -eq "space")
	{		
		$sysinfocmd += " -space"		
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysinfocmd
		
		return $Result
	
	}	
	if($Option -eq "domainspace")
	{
		$sysinfocmd += " -domainspace"
		write-debuglog "Get 3par system domianspace information " "INFO:" 
		write-debuglog "Get 3par system fan information cmd -> $sysinfocmd " "INFO:"
						
		$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysinfocmd
		
		return	$Result3	
	}
	if($Option -eq "fan")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$sysinfocmd += " -fan"
		write-debuglog "Get 3par system fan information " "INFO:" 
		$Result3 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysinfocmd
		write-debuglog "Get 3par system fan information cmd -> $sysinfocmd " "INFO:" 
		if (-not $Result3){
			write-debuglog "Get 3par system fan information " "INFO:"
			write-debuglog "There is no system fan information" "INFO:"
			return "There is no system fan information"
		}
		elseif($Result3 -match "There is no system fan information"){
			write-debuglog "Get 3par system fan information " "INFO:"
			write-debuglog "There is no system fan information" "INFO:"
			return "There is no system fan information"
		}
		else{
		
			foreach ($s in  $Result3[0..$Result3.Count] ){
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s,"-","")
				$s= [regex]::Replace($s," +",",")
				Add-Content -Path $tempfile -Value $s
			}
			Import-Csv $tempFile
		}
		return
	}
	if($Option -eq "date"){
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  "showdate"
		write-debuglog "Get 3par system date information " "INFO:"
		write-debuglog "Get 3par system fan information cmd -> showdate " "INFO:"
		$tempFile = [IO.Path]::GetTempFileName()
		Add-Content -Path $tempfile -Value "Node,Date"
		foreach ($s in  $Result[1..$Result.Count] ){
			$splits = $s.split(" ")
			$var1 = $splits[0].trim()
			#write-host "var1 = $var1"
			$var2 = ""
			foreach ($t in $splits[1..$splits.Count]){
				#write-host "t = $t"
				if(-not $t){
					continue
				}
				$var2 += $t+" "
				
				#write-host "var2 $var2"
			}
			$var3 = $var1+","+$var2
			Add-Content -Path $tempfile -Value $var3
		}
		Import-Csv $tempFile
		return
	}	
}
##### END Get-3parSystem #####
##### Start Get-3parSpace #####
Function Get-3parSpace
{
<#
  .SYNOPSIS
    Displays estimated free space for logical disk creation.
  
  .DESCRIPTION
    Displays estimated free space for logical disk creation.
        
  .EXAMPLE
    Get-3parSpace 
	Displays estimated free space for logical disk creation.
	
  .EXAMPLE
    Get-3parSpace -raidType r1
	 Example displays the estimated free space for a RAID-1 logical disk:
	 
  .PARAMETER cpgName
    Specifies that logical disk creation parameters are taken from CPGs that match the specified CPG
	name or pattern,Multiple CPG names or patterns can be specified using a comma separated list, for
	example cpg1,cpg2,cpg3.

  .PARAMETER raidType
	Specifies the RAID type of the logical disk: r0 for RAID-0, r1 for RAID-1, r5 for RAID-5, or r6 for
	RAID-6. If no RAID type is specified, the default is r1 for FC and SSD device types and r6 is for
	the NL device types
	
  .PARAMETER cage 
	Specifies one or more drive cages. Drive cages are identified by one or more integers (item).
	Multiple drive cages are separated with a single comma (1,2,3). A range of drive cages is
	separated with a hyphen (0–3). The specified drive cage(s) must contain disks.
	
  .PARAMETER disk
	Specifies one or more disks. Disks are identified by one or more integers (item). Multiple disks
	are separated with a single comma (1,2,3). A range of disks is separated with a hyphen (0–3).
	Disks must match the specified ID(s).
	
  .PARAMETER History
	 Specifies that free space history over time for CPGs specified

  .PARAMETER SSZ
	Specifies the set size in terms of chunklets.
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSpace
    LASTEDIT: 08/06/2015
    KEYWORDS: Get-3parSpace
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$cpgName,
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$raidType,
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$cage,
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$disk,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$History,
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$SSZ,		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)	
	Write-DebugLog "Start: In Get-3parSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSpace since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSpace since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$sysspacecmd = "showspace "
	$sysinfo = @{}	
	if($cpgName)
	{		
		if(($raidType) -or ($cage) -or($disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}		
		$sysspacecmd += " -cpg $cpgName"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysspacecmd
		write-debuglog "Get 3par system space cmd -> $sysspacecmd " "INFO:"
		if ($Result -match "FAILURE :")
		{
			write-debuglog "no CPGs found or matched" "Info:"
			return "FAILURE : no CPGs found or matched"			
		}
		if( $Result -match "There is no free space information")
		{
			write-debuglog "FAILURE : There is no free space information" "Info:"
			return "FAILURE : There is no free space information"			
		}
		$tempFile = [IO.Path]::GetTempFileName()
		$3parosver = Get-3parVersion -number -SANConnection  $SANConnection 
		$incre = "true" 
		foreach ($s in  $Result[2..$Result.Count] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			
			if($3parosver -eq "3.1.1")
			{
				$s= $s.Trim() -replace 'Name,RawFree,LDFree,Total,Used,Total,Used,Total,Used','CPG_Name,EstFree_RawFree(MB),EstFree_LDFree(MB),Usr_Total(MB),Usr_Used(MB),Snp_Total(MB),Snp_Used(MB),Adm_Total(MB),Adm_Used(MB)'
			}
			if($3parosver -eq "3.1.2")
			{
				$s= $s.Trim() -replace 'Name,RawFree,LDFree,Total,Used,Total,Used,Total,Used','CPG_Name,EstFree_RawFree(MB),EstFree_LDFree(MB),Usr_Total(MB),Usr_Used(MB),Snp_Total(MB),Snp_Used(MB),Adm_Total(MB),Adm_Used(MB)' 
			}
			else
			{
				$s= $s.Trim() -replace 'Name,RawFree,LDFree,Total,Used,Total,Used,Total,Used,Compaction,Dedup','CPG_Name,EstFree_RawFree(MB),EstFree_LDFree(MB),Usr_Total(MB),Usr_Used(MB),Snp_Total(MB),Snp_Used(MB),Adm_Total(MB),Adm_Used(MB),Compaction,Dedup'
			}
			
			if($incre -eq "true")
			{
				$s=$s.Substring(1)								
				$sTemp1=$s				
				$sTemp = $sTemp1.Split(',')							
				$sTemp[1]="RawFree(MiB)"				
				$sTemp[2]="LDFree(MiB)"
				$sTemp[3]="OPFree(MiB)"				
				$sTemp[4]="Base(MiB)"
				$sTemp[5]="Snp(MiB)"				
				$sTemp[6]="Free(MiB)"
				$sTemp[7]="Total(MiB)"		
				
				$newTemp= [regex]::Replace($sTemp,"^ ","")			
				$newTemp= [regex]::Replace($sTemp," ",",")				
				$newTemp= $newTemp.Trim()
				$s=$newTemp							
			}
			
			Add-Content -Path $tempfile -Value $s
			$incre="false"
		}		
		Import-Csv $tempFile
		return
	}		
	if($raidType)
	{
		if(($cpgName) -or ($cage) -or($disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$raidType = $raidType.toLower()
		$sysspacecmd += " -t $raidType"
		write-debuglog "Get 3par system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "FAILURE :")
		{
			write-debuglog "FAILURE : Illegal raid type $raidType, specify r0, r1, r5, or r6" "Info:"
			return "FAILURE : Illegal raid type $raidType, specify r0, r1, r5, or r6"
		}		
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
		return
	}
	if($cage)
	{
		if(($raidType) -or ($cpgName) -or($disk)){
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += " -p -cg $cage"
		write-debuglog "Get 3par system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "FAILURE :")
		{
			write-debuglog "FAILURE : Illegal pattern integer or range: $cage" "ERR:"
			return "FAILURE : Illegal pattern integer or range: $disk"
		}
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
		return
	}
	if($disk)
	{
		if(($raidType) -or ($cage) -or($cpgName)){
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += "-p -dk $disk"
		write-debuglog "Get 3par system space cmd -> $sysspacecmd " "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysspacecmd
		if ($Result -match "FAILURE :")
		{
			write-debuglog "FAILURE : Illegal pattern integer or range: $disk" "ERR:"
			return "FAILURE : Illegal pattern integer or range: $disk"
		}
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
	}
	if($History)
	{
		if(($raidType) -or ($cage) -or($cpgName) -or($disk))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += " -hist "
	}
	if($SSZ)
	{
		if(($raidType) -or ($cage) -or($cpgName) -or($disk) -or($History))
		{
			return "FAILURE : Use only One parameter at a time."
		}
		$sysspacecmd += " -ssz $SSZ "
	}
	if(-not(( ($disk) -or ($cage)) -or (($raidType) -or ($cpg))))
	{		
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysspacecmd
		write-debuglog "Get 3par system space cmd -> $sysspacecmd " "INFO:"
		if ($Result -match "FAILURE :")
		{
			write-debuglog "FAILURE : Illegal pattern integer or range: $disk" "ERR:"
			return "FAILURE : Illegal pattern integer or range: $disk"
		}
		foreach ($s in $Result[2..$Result.count])
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")
			$s = $s.split(",")
			$sysinfo.add("RawFree(MB)",$s[0])
			$sysinfo.add("UsableFree(MB)",$s[1])
			$sysinfo
		}
	}
}
#### End Get-3parSpace #####
#### Spare commandlets ##########
#### Start New-3parSpare #####
Function New-3parSpare
{
<#
  .SYNOPSIS
    Allocates chunklet resources as spares. Chunklets marked as spare are not used for logical disk creation and are reserved explicitly for spares, thereby guaranteeing a minimum amount of spare space.
  
  .DESCRIPTION
    Allocates chunklet resources as spares. Chunklets marked as spare are not used for logical disk creation and are reserved explicitly for spares, thereby guaranteeing a minimum amount of spare space. 
        
  .EXAMPLE
    New-3parSpare -Pdid_chunkNumber "15:1"
	This example marks chunklet 1 as spare for physical disk 15
  .EXAMPLE
	New-3parSpare –pos "1:0.2:3:121"
	This example specifies the position in a drive cage, drive magazine, physical disk,and chunklet number. –pos 1:0.2:3:121, where 1 is the drive cage, 0.2 is the drive magazine, 3 is the physical disk, and 121 is the chunklet number.
 	
  .PARAMETER Pdid_chunkNumber
    Specifies the identification of the physical disk and the chunklet number on the disk.
	
  .PARAMETER pos
    Specifies the position of a specific chunklet identified by its position in a drive cage, drive magazine, physical disk, and chunklet number.
  
  .PARAMETER Partial
  Specifies that partial completion of the command is acceptable.
        
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parSpare
    LASTEDIT: 08/06/2015
    KEYWORDS: New-3parSpare
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Pdid_chunkNumber,
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$pos,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Partial,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In New-3parSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parSpare since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parSpare since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$newsparecmd = "createspare "
	if($Partial)
	{
		$newsparecmd +=" -p "
	}
	if(!(($pos) -or ($Pdid_chunkNumber)))
	{
		return "FAILURE : Please specify any one of the params , specify either -PDID_chunknumber or -pos"
	}
	if($Pdid_chunkNumber)
	{
		$newsparecmd += " -f $Pdid_chunkNumber"
		if($pos)
		{
			return "FAILURE : Do not specify both the params , specify either -PDID_chunknumber or -pos"
		}
	}
	if($pos)
	{
		$newsparecmd += " -f -pos $pos"
		if($Pdid_chunkNumber)
		{
			return "FAILURE : Do not specify both the params , specify either -PDID_chunknumber or -pos"
		}
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $newsparecmd
	write-debuglog "3par spare  cmd -> $newsparecmd " "INFO:"
	#write-host "Result = $Result"
	if(-not $Result){
		write-host "SUCCESS : Create spare chunklet "
	}
	else
	{
		return "$Result"
	}
}
#### End New-3parSpare ####
#### Start Remove-3parSpare #####
Function Remove-3parSpare
{
<#
  .SYNOPSIS
    Command removes chunklets from the spare chunklet list.
  
  .DESCRIPTION
    Command removes chunklets from the spare chunklet list.        
  .EXAMPLE
    Remove-3parSpare -Pdid_chunkNumber "1:3"
	Example removes a spare chunklet from position 3 on physical disk 1:
  .EXAMPLE
	Remove-3parSpare –pos "1:0.2:3:121"
	Example removes a spare chuklet from  the position in a drive cage, drive magazine, physical disk,and chunklet number. –pos 1:0.2:3:121, where 1 is the drive cage, 0.2 is the drive magazine, 3 is the physical disk, and 121 is the chunklet number. 	
  .PARAMETER Pdid_chunkNumber
    Specifies the identification of the physical disk and the chunklet number on the disk.
  .PARAMETER pos
    Specifies the position of a specific chunklet identified by its position in a drive cage, drive magazine, physical disk, and chunklet number.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parSpare
    LASTEDIT: 08/06/2015
    KEYWORDS: Remove-3parSpare
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Pdid_chunkNumber,
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$pos,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Remove-3parSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parSpare since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parSpare since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$newsparecmd = "removespare "
	if(!(($Pdid_chunkNumber) -or ($pos)))
	{
		return "FAILURE: No parameters specified"
	}
	if($Pdid_chunkNumber)
	{
		$newsparecmd += " -f $Pdid_chunkNumber"
		if($pos)
		{
			return "FAILURE: Please select only one params, either -Pdid_chunkNumber or -pos "
		}
	}
	if($pos)
	{
		$newsparecmd += " -f -pos $pos"
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $newsparecmd
	write-debuglog "Remove spare command -> newsparecmd " "INFO:"
	#write-host "Result = $Result"
	if($Result -match "removed")
	{
		write-debuglog "SUCCESS : Removed spare chunklet "  "INFO:"
		return "SUCCESS : $Result"
	}
	else
	{
		return "$Result"
	}
}
#### End Remove-3parSpare ####

#### Start Push-3parChunklet ####
Function Push-3parChunklet
{
<#
  .SYNOPSIS
   Moves a list of chunklets from one physical disk to another.
  
  .DESCRIPTION
   Moves a list of chunklets from one physical disk to another.
        
  .EXAMPLE
    Push-3parChunklet -SourcePD_Id 24 -SourceChunk_Position 0  -TargetPD_Id	64 -TargetChunk_Position 50 -force
	This example moves the chunklet in position 0 on disk 24, to position 50 on disk 64 and chunklet in position 0 on disk 25, to position 1 on disk 27
	
  .PARAMETER SourcePD_Id
    Specifies that the chunklet located at the specified PD
	
  .PARAMETER SourceChunk_Position
    Specifies that the the chunklet’s position on that disk
	
  .PARAMETER TargetPD_Id	
	specified target destination disk
	
  .PARAMETER TargetChunk_Position	
	Specify target chunklet position
	
  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
	
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
  .PARAMETER Devtype
        Permits the moves to happen to different device types.

  .PARAMETER Perm
        Specifies that chunklets are permanently moved and the chunklets'
        original locations are not remembered.
		
  .PARAMETER Ovrd
        Permits the moves to happen to a destination even when there will be
        a loss of quality because of the move. 
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parChunklet
    LASTEDIT: 08/06/2015
    KEYWORDS: Push-3parChunklet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$SourcePD_Id,
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$SourceChunk_Position,
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$TargetPD_Id,
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$TargetChunk_Position,		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$force,		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$nowait,
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Devtype,
		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Perm,
		[Parameter(Position=8, Mandatory=$false)]
		[Switch]
		$Ovrd,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Push-3parChunklet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parChunklet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parChunklet since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "movech "
	if($force)
	{
		$movechcmd += " -f "
	}
	else
	{
		$movechcmd += " -dr -f "
	}
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($Devtype)
	{
		$movechcmd += " -devtype "
	}
	if($Perm)
	{
		$movechcmd += " -perm "
	}
	if($Ovrd)
	{
		$movechcmd += " -ovrd "
	}
	if(($SourcePD_Id)-and ($SourceChunk_Position))
	{
		$params = $SourcePD_Id+":"+$SourceChunk_Position
		$movechcmd += " $params"
		if(($TargetPD_Id) -and ($TargetChunk_Position))
		{
			$movechcmd += "-"+$TargetPD_Id+":"+$TargetChunk_Position
		}
	}
	else
	{
		return "FAILURE :  No parameters specified "
	}
	#write-host "cmd = $movechcmd"
	write-debuglog "move chunklet cmd -> $movechcmd " "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $movechcmd
	#write-host "rsut = $Result"
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : Disk $SourcePD_Id chunklet $SourceChunk_Position is not in use. "
	}
	if($Result -match "Move")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'			
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
#### End Push-3parChunklet ######
#### Start Push-3parChunkletToSpare ####
Function Push-3parChunkletToSpare
{
<#
  .SYNOPSIS
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
  
  .DESCRIPTION
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
        
  .EXAMPLE
    Push-3parChunkletToSpare -SourcePD_Id 66 -SourceChunk_Position 0  -force 
	Examples shows chunklet 0 from physical disk 66 is moved to spare

  .EXAMPLE	
	Push-3parChunkletToSpare -SourcePD_Id 3 -SourceChunk_Position 0

  .EXAMPLE	
	Push-3parChunkletToSpare -SourcePD_Id 4 -SourceChunk_Position 0 -nowait
	
  .EXAMPLE
    Push-3parChunkletToSpare -SourcePD_Id 5 -SourceChunk_Position 0 -Devtype
	
  .PARAMETER SourcePD_Id
    Indicates that the move takes place from the specified PD
	
  .PARAMETER SourceChunk_Position
    Indicates that the move takes place from  chunklet position
	
  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
	
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parChunkletToSpare
    LASTEDIT: 08/11/2015
    KEYWORDS: Push-3parChunkletToSpare
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SourcePD_Id,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SourceChunk_Position,

		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$force,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Devtype,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Push-3parChunkletToSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parChunkletToSpare since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parChunkletToSpare since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "movechtospare "
	if($force)
	{
		$movechcmd += " -f "
	}
	else
	{
		$movechcmd += " -dr -f "
	}
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($Devtype)
	{
		$movechcmd += " -devtype "
	}
	if(($SourcePD_Id) -and ($SourceChunk_Position)){
		$params = $SourcePD_Id+":"+$SourceChunk_Position
		$movechcmd += " $params"
	}
	else
	{
		return "FAILURE : No parameters specified"
	}
	#write-host "cmd = $movechcmd"
	write-debuglog "cmd is -> $movechcmd " "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $movechcmd
	#write-host "=========== = $Result"
	if([string]::IsNullOrEmpty($Result))
	{
		#write-host "IF = $Result"
		return "FAILURE : "
	}
	elseif($Result -match "does not exist")
	{
		#write-host "ELSEIF = $Result"
		return $Result
	}
	elseif($Result.count -gt 1)
	{
		#write-host "ELSE = $Result"
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			#write-host "s = $s"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
#### End Push-3parChunkletToSpare #####
#### Start Push-3parPd ####
Function Push-3parPd
{
<#
  .SYNOPSIS
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
  
  .DESCRIPTION
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system
        
  .EXAMPLE
    Push-3parPd -PD_Id 0 -force
	Example shows moves data from Physical Disks 0  to a temporary location
	
  .EXAMPLE	
	Push-3parPd -PD_Id 0  
	Example displays a dry run of moving the data on physical disk 0 to free or sparespace
	
  .PARAMETER PD_Id
    Specifies the physical disk ID. This specifier can be repeated to move multiple physical disks.

  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
	
  .PARAMETER DryRun
	 Specifies that the operation is a dry run, and no physical disks are
        actually moved.

  .PARAMETER Nowait
        Specifies that the command returns before the operation is completed.

  .PARAMETER Devtype
        Permits the moves to happen to different device types.

  .PARAMETER Perm
        Makes the moves permanent, removes source tags after relocation
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parPd
    LASTEDIT: 08/11/2015
    KEYWORDS: Push-3parPd
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$force,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$DryRun,
				
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Devtype,
		
		[Parameter(Position=4, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$PD_Id,		
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Push-3parPd - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parPd since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parPd since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "movepd "
	if($force)
	{
		$movechcmd += " -f "
	}
	else
	{
		return "Please select force option"
	}
	if($DryRun)
	{
		$movechcmd += " -dr "
	}
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($Devtype)
	{
		$movechcmd += " -devtype "
	}
	if($PD_Id)
	{
		$params = $PD_Id
		$movechcmd += " $params"
	}
	else
	{
		return "FAILURE : No parameters specified"		
	}
	#write-host "cmd = $movechcmd"
	write-debuglog "Push physical disk command => $movechcmd " "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $movechcmd
	#write-host "Result = $Result"
	if([string]::IsNullOrEmpty($Result))
	{
		#write-host "If Null"
		return "FAILURE : "
	}
	if($Result -match "FAILURE")
	{
		#write-host "If FAILURE"
		return $Result
	}
	if($Result -match "Move")
	{
		#write-host "If Move"
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		#write-host "Else"
		return $Result
	}
}
#### End Push-3parPd ####
#### Start Push-3parPdToSpare ####
Function Push-3parPdToSpare
{
<#
  .SYNOPSIS
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system.
  
  .DESCRIPTION
   Moves data from specified Physical Disks (PDs) to a temporary location selected by the system.
        
  .EXAMPLE
    Push-3parPdToSpare -PD_Id 0 -force  
	Displays  moving the data on PD 0 to free or spare space
  .EXAMPLE
    Push-3parPdToSpare -PD_Id 0 
	Displays a dry run of moving the data on PD 0 to free or spare space
	
  .PARAMETER PD_Id
    Specifies the physical disk ID.

  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parPdToSpare
    LASTEDIT: 08/11/2015
    KEYWORDS: Push-3parPdToSpare
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$PD_Id,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$force,
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$nowait,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Push-3parPdToSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parPdToSpare since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parPdToSpare since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "movepdtospare "
	if($force)
	{
		$movechcmd += " -f "
	}
	else
	{
		$movechcmd += " -dr -f "
	}
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($PD_Id)
	{
		$params = $PD_Id
		$movechcmd += " $params"
	}
	else
	{
		return "FAILURE : No parameters specified"		
	}
	#write-host "cmd = $movechcmd"
	write-debuglog "push physical disk to spare cmd is  => $movechcmd " "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $movechcmd
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : "
	}
	if($Result -match "Error:")
	{
		return $Result
	}
	if($Result -match "Move")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
#### End Push-3parPdToSpare ####
#### Start Push-3parRelocPD ####
Function Push-3parRelocPD
{
<#
  .SYNOPSIS
   Command moves chunklets that were on a physical disk to the target of relocation.
  
  .DESCRIPTION
   Command moves chunklets that were on a physical disk to the target of relocation.
        
  .EXAMPLE
    Push-3parRelocPD -diskID 8 -force
	moves chunklets that were on physical disk 8 that were relocated to another position, back to physical disk 8
	
  .PARAMETER diskID
    <fd>[-<td>]...
	Specifies that the chunklets that were relocated from specified disk (<fd>), are moved to the specified destination disk (<td>). If destination disk (<td>) is not specified then the chunklets are moved back
    to original disk (<fd>). The <fd> specifier is not needed if -p option is used, otherwise it must be used at least once on the command line. If this specifier is repeated then the operation is performed on multiple disks.

  .PARAMETER force
    Specifies that the command is forced. If this option is not used,it will do dry run,No chunklets are actually moved.
  .PARAMETER nowait
   Specifies that the command returns before the operation is completed.
  .PARAMETER partial
    Move as many chunklets as possible. If this option is not specified, the command fails if not all specified chunklets can be moved.   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Push-3parRelocPD
    LASTEDIT: 08/11/2015
    KEYWORDS: Push-3parRelocPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$diskID,		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$force,		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$nowait,		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$partial,		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Push-3parRelocPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Push-3parRelocPD since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Push-3parRelocPD since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$movechcmd = "moverelocpd "
	if($force)
	{
		$movechcmd += " -f "
	}
	else
	{
		$movechcmd += " -dr -f "
	}
	if($nowait)
	{
		$movechcmd += " -nowait "
	}
	if($partial)
	{
		$movechcmd += " -partial "
	}
	if($diskID)
	{
		$movechcmd += " $diskID"
	}
	else
	{
		return "FAILURE : No parameters specified"		
	}
	#write-host "cmd = $movechcmd"
	write-debuglog "move relocation pd cmd is => $movechcmd " "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $movechcmd
	if([string]::IsNullOrEmpty($Result))
	{
		return "FAILURE : "
	}
	if($Result -match "Error:")
	{
		return $Result
	}	
	if($Result -match "There are no chunklets to move")
	{
		return "There are no chunklets to move"
	}	
	if($Result -match " Move -State- -Detailed_State-")
	{
		$range = $Result.count
		$tempFile = [IO.Path]::GetTempFileName()
		foreach ($s in  $Result[0..$range] )
		{			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			$s= $s.Trim() -replace 'Move,-State-,-Detailed_State-','Move,State,Detailed_State'
			Add-Content -Path $tempfile -Value $s			
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
}
#### End Push-3parRelocPD ####

#### Start Get-3parSpare  ####
Function Get-3parSpare
{
<#
  .SYNOPSIS
    Displays information about chunklets in the system that are reserved for spares
  
  .DESCRIPTION
    Displays information about chunklets in the system that are reserved for spares and previously free chunklets selected for spares by the system. 
        
  .EXAMPLE
    Get-3parSpare 
	Displays information about chunklets in the system that are reserved for spares
 	
  .PARAMETER used 
    Display only used spare chunklets
	
  .PARAMETER count
	Number of loop iteration
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSpare
    LASTEDIT: 08/06/2015
    KEYWORDS: Get-3parSpare
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$used,
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$count,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSpare - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSpare since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSpare since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$spareinfocmd = "showspare "
	if($used)
	{
		$spareinfocmd+= " -used "
	}
	write-debuglog "Get list of spare information cmd is => $spareinfocmd " "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $spareinfocmd
	$tempFile = [IO.Path]::GetTempFileName()
	$range1 = $Result.count - 3 
	$range = $Result.count	
	if($count)
	{		
		foreach ($s in  $Result[0..$range] )
		{
			if ($s -match "Total chunklets")
			{
				return $s
			}
		}
	}	
	if($Result.count -eq 3)
	{
			return "No data available"			
	}	
	foreach ($s in  $Result[0..$range1] )
	{
		if (-not $s)
		{
			write-host "No data available"
			write-debuglog "No data available" "INFO:"\
			return
		}
		$s= [regex]::Replace($s,"^ +","")
		$s= [regex]::Replace($s," +"," ")
		$s= [regex]::Replace($s," ",",")
		#write-host "s is $s="
		Add-Content -Path $tempfile -Value $s
	}
	Import-Csv $tempFile
	del $tempFile
}
#### End Get-3parSpare ####

#### Start System Reporter commandlets ####

#### Start Get-3parSR ####
Function Get-3parSR
{
<#
  .SYNOPSIS
    Displays the amount of space consumed by the various System Reporter databases on the System Reporter volume.
  
  .DESCRIPTION
    Displays the amount of space consumed by the various System Reporter databases on the System Reporter volume.
        
  .EXAMPLE
    Get-3parSR 
	shows how to display the System Reporter status:
 	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSR
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSR
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,	
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Secs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSR - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSR since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSR since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "showsr "
	if ($option)
	{
		$a = "ldrg","btsecs","etsecs"
		$l=$option
		if($a -eq $l)
		{
			$srinfocmd+=" -$option "			
			if($option -eq "btsecs")
			{
				$srinfocmd+=" -$Secs "
			}
			if($option -eq "etsecs")
			{
				$srinfocmd+=" $Secs "
			}
			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parSR   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [ldrg | btsecs | etsecs]  can be used only . "
		}
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
	return  $Result	
}
#### end Get-3parSR ####
#### Start Start-3parSR ####
Function Start-3parSR
{
<#
  .SYNOPSIS
    To start 3par System reporter.
  
  .DESCRIPTION
    To start 3par System reporter.
        
  .EXAMPLE
    Start-3parSR 
	Starts 3par System Reporter
 	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Start-3parSR
    LASTEDIT: 08/11/2015
    KEYWORDS: Start-3parSR
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Start-3parSR - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Start-3parSR since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Start-3parSR since SAN connection object values are null/empty"
			}
		}
	}

	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "startsr -f "
	write-debuglog "System reporter command => $srinfocmd" "INFO:"
	$3parosver = Get-3parVersion -number -SANConnection  $SANConnection 
	if($3parosver -ge "3.1.2")
	{
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if(-not $Result)
		{
			return "SUCCESS: Started 3par System Reporter $Result"
		}
		elseif($Result -match "Cannot startsr, already started")
		{
			Return "Command Execute Sucessfully :- Cannot startsr, already started"
		}
		else
		{
			return $Result
		}		
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Start-3parSR ####
#### Start Stop-3parSR ####
Function Stop-3parSR
{
<#
  .SYNOPSIS
    To stop 3par System reporter.
  
  .DESCRIPTION
    To stop 3par System reporter.
        
  .EXAMPLE
    Stop-3parSR 
	Stop 3par System Reporter
 	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Stop-3parSR
    LASTEDIT: 08/11/2015
    KEYWORDS: Stop-3parSR
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Stop-3parSR - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Stop-3parSR since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Stop-3parSR since SAN connection object values are null/empty"
			}
		}
	}

	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "stopsr -f "
	$3parosver = Get-3parVersion -number -SANConnection  $SANConnection
	write-debuglog "System reporter command => $srinfocmd" "INFO:"
	if($3parosver -ge "3.1.2")
	{
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if(-not $Result)
		{
			return "SUCCESS: Stopped 3par System Reporter $Result"
		}
		else
		{
			return $Result
		}
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Stop-3parSR ####
#### Start New-3parSRAlertCrit ####
Function New-3parSRAlertCrit
{
<#
  .SYNOPSIS
    Creates a criterion that System Reporter evaluates to determine if a performance alert should be generated.
  
  .DESCRIPTION
    Creates a criterion that System Reporter evaluates to determine if a performance alert should be generated.
        
  .EXAMPLE
    New-3parSRAlertCrit -Type port  -Condition "write_iops>50" -Name write_port_check
	Example describes a criterion that generates an alert for each port that has more than 50 write IOPS in a high resolution sample:
  .EXAMPLE
    New-3parSRAlertCrit -Type port  -Condition "write_iops>50" -Name write_port_check -Common_option hourly
  
  .EXAMPLE
    New-3parSRAlertCrit -Type port  -Condition "write_iops>50" -Name write_port_check -Common_option hourly
	
  .EXAMPLE
    New-3parSRAlertCrit -Type port  -Condition "write_iops>50" -Name write_port_check -Common_option daily
	
  .PARAMETER Type
  Type must be one of the following: port, vlun, pd, ld, cmp, cpu, link, qos, rcopy, or rcvv.
  .PARAMETER Options

  .PARAMETER Common_Option
  Specify commaon option types from one of these (hourly,daily,hires,major,minor,info)
  .PARAMETER Options common to all types:
	-daily
		This criterion will be evaluated on a daily basis at midnight.
	-hourly
		This criterion will be evaluated on an hourly basis.
	-hires
		This criterion will be evaluated on a high resolution (5 minute) basis. This is the default.
	-major
		This alert should require urgent action.
	-minor
		This alert should require not immediate action.
	-info
		This alert is informational only. This is the default.
  
  .PARAMETER Condition
  The condition must be of the format <field><comparison><value>, where field is one of the fields corresponding to the type (see above), comparison is of the format <, <=, >, >=, =,!= and value is a numeric value. Note that some characters, such as < and >, are significant inmost shells and must be escaped or quoted when running this command from another shell.
 
  .PARAMETER Name
   Specify name for the criterion.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parSRAlertCrit
    LASTEDIT: 08/17/2015
    KEYWORDS: New-3parSRAlertCrit
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Type ,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Common_option,
		[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
        $Condition, 
		[Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
        $Name,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In New-3parSRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parSRAlertCrit since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parSRAlertCrit since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-3parVersion -number  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}	
	$srinfocmd = "createsralertcrit "	
	$typearray = "port","vlun","pd","ld","cmp","cpu","link","qos","rcopy","rcvv"
	if(((($Type) -and ($Condition)) -and ($Name)))
	{
		$commonarray = "hourly","daily","hires","major","minor","info","critical"
		if($Common_option)
		{
			if($commonarray -match $Common_option )
			{
				$typearray = "port","vlun","pd","ld","cmp","cpu","link","qos","rcopy","rcvv"
				if($typearray -match $Type)
				{
					$srinfocmd += " $Type -"
				}
				else
				{
					return "FAILURE : Type name should be in ( $typearray )"
				}	
				$srinfocmd +=$Common_option
			}
		}
		else
		{
			$typearray = "port","vlun","pd","ld","cmp","cpu","link","qos","rcopy","rcvv"
			if($typearray -match $Type)
			{
				$srinfocmd += " $Type "
			}
			else
			{
				return "FAILURE : Type name should be in ( $typearray )"
			}			
		}
		$srinfocmd += " $Condition $Name"						
	}
	else
	{
		return "FAILURE : Please specify mandatory params"
	}
	#write-host "Final Command is $srinfocmd"
	write-debuglog "Create alert criteria command => $srinfocmd" "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
	if($Result)
	{
		write-host "FAILURE : $Result"
	}
	else
	{
		return "SUCCESS: sralert $Name has been created "
	}
}
#### End New-3parSRAlertCrit ####
#### Start Remove-3parSRAlertCrit ####
Function Remove-3parSRAlertCrit
{
<#
  .SYNOPSIS
    Command removes a criterion that System Reporter evaluates to determine if a performance alert should be generated.
  
  .DESCRIPTION
    Command removes a criterion that System Reporter evaluates to determine if a performance alert should be generated.
        
  
  .EXAMPLE
    Remove-3parSRAlertCrit -force  -Name write_port_check 
	Example removes the criterion named write_port_check:
	
  .PARAMETER force
	Do not ask for confirmation before removing this criterion.

  .PARAMETER Name
	Specifies the name of the criterion to Remove.  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parSRAlertCrit
    LASTEDIT: 08/17/2015
    KEYWORDS: Remove-3parSRAlertCrit
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Name,
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
        $force,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Remove-3parSRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parSRAlertCrit since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parSRAlertCrit since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-3parVersion -number  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current 3par version $version1 does not support these cmdlet"
	}
	$srinfocmd = "removesralertcrit "
	if(($force) -and ($Name))
	{
		$srinfocmd += " -f $Name"		
	}
	else
	{
		return "FAILURE : Please specify -force or Name parameter values"
	}
	#write-host "Final Command is $srinfocmd"
	write-debuglog "Remove alert crit => $srinfocmd" "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
	if($Result)
	{
		return "FAILURE : $Result"
	}
	else
	{
		return "SUCCESS : sralert $Name has been removed"
	}	
}
#### End Remove-3parSRAlertCrit ####
#### Start Get-3parSRStatCPU ####
Function Get-3parSRStatCPU
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for CPUs.
  
  .DESCRIPTION
    Command displays historical performance data reports for CPUs.
	
  .EXAMPLE
    Get-3parSRStatCPU 
	Command displays historical performance data reports for CPUs.
  .EXAMPLE
    Get-3parSRStatCPU -option hourly -btsecs -24h
 	Example displays aggregate hourly performance statistics for all CPUs beginning 24 hours ago:	
  .EXAMPLE
    Get-3parSRStatCPU -option daily -attime -groupby node     
    Example displays daily node cpu performance aggregated by nodes
	 
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.	
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of  <groupby> items.  Each <groupby> must be different and one of the following:
        NODE      The controller node
        CPU       The CPU within the controller node

  .PARAMETER Node
 Only the specified node numbers are included, where each node is a number from 0 through 7. If want to display information for multiple nodes specift <nodenumber>,<nodenumber2>,etc. If not specified, all nodes are included.
	Get-3parSRStatCPU  -Node 0,1,2
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatCPU
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatCPU
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,	
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRStatCPU - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatCPU since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatCPU since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatcpu "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "CPU","NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower()){
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}
		}
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "NODE"
			}
			$rangestart = "1"
			$rangestart = "4"
		}
		else
		{
			$rangestart = "1"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,User%,Sys%,Idle%,Intr/s,CtxtSw/s"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "3")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatCPU ####
#### Start Get-3parSRStatCMP ####
Function Get-3parSRStatCMP
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for cache memory
  
  .DESCRIPTION
    Command displays historical performance data reports for cache memory
	
  .EXAMPLE
    Get-3parSRStatCMP 
	Command displays historical performance data reports for cache memory
  .EXAMPLE
    Get-3parSRStatCMP -option hourly -btsecs -24h
 	Example displays aggregate hourly performance statisticsfor all node caches beginning 24 hours ago:
  .EXAMPLE
    Get-3parSRStatCMP -option daily -attime -groupby node     
     Example displays daily node cache performance aggregated by nodes
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.

  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of
        <groupby> items.  Each <groupby> must be different and one of the following:
        NODE      The controller node
		
  .PARAMETER Node
 Only the specified node numbers are included, where each node is a number from 0 through 7. If want to display information for multiple nodes specift <nodenumber>,<nodenumber2>,etc. If not specified, all nodes are included.
	Get-3parSRStatCMP  -Node 0,1,2
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatCMP
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatCMP
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRStatCMP - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatCMP since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatCMP since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatcmp "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "NODE"
			if($commarr -eq $groupby.toUpper())
			{
				$srinfocmd += " -groupby $groupby"
			}
			else
			{
				return "FAILURE: Invalid groupby option it should be in ( $commarr )"
			}
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires","full","page"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"			
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby){
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "NODE"
			}
			Add-Content -Path $tempfile -Value "NODE,rhit(count/sec),whit(count/sec),r(count/sec),w(count/sec),r+w(count/sec),lockblk(count/sec),r(hit%),w(hit%),NL(dack/sec),FC(dack/sec),SSD150(dack/sec),SSD100(dack/sec)"
			$rangestart = "3"
			$rangestart = "4"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,rhit(count/sec),whit(count/sec),r(count/sec),w(count/sec),r+w(count/sec),lockblk(count/sec),r(hit%),w(hit%),NL(dack/sec),FC(dack/sec),SSD150(dack/sec),SSD100(dack/sec)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "3")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatCMP ####
#### Start Get-3parSRStatCache ####
Function Get-3parSRStatCache
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for flash cache and data cache.
  
  .DESCRIPTION
    Command displays historical performance data reports for flash cache and data cache.
	
  .EXAMPLE
    Get-3parSRStatCache 
	Command displays historical performance data reports for flash cache and data cache.
  .EXAMPLE
    Get-3parSRStatCache -option hourly -btsecs -24h
 	Example displays aggregate hourly performance statistics for flash cache and data cache beginning 24 hours ago:
  .EXAMPLE
    Get-3parSRStatCache -option daily -attime -groupby node     
    Example displays daily flash cache and data cache performance aggregated by nodes
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of
        <groupby> items.  Each <groupby> must be different and one of the following:
        NODE      The controller node
		
  .PARAMETER Node
 Only the specified node numbers are included, where each node is a number from 0 through 7. If want to display information for multiple nodes specift <nodenumber>,<nodenumber2>,etc. If not specified, all nodes are included.
	Get-3parSRStatCMP  -Node 0,1,2
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatCache
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatCache
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRStatCache - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatCache since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatCache since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatcache "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}
		if($Option)
		{
			$commarr1 = "hourly","daily","hires","internal_flashcache","fmp_queue","cmp_queue","full"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}
		}
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "NODE"
			}
			Add-Content -Path $tempfile -Value "$optionname,CMP_r/s,CMP_w/s,CMP_rhit%,CMP_whit%,FMP_rhit%,FMP_whit%,FMP_Used%,Read_Back_IO/s,Read_Back_MB/s,Dstg_Wrt_IO/s,Dstg_Wrt_MB/s"
			$rangestart = "3"
			$rangestart = "4"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,CMP_r/s,CMP_w/s,CMP_rhit%,CMP_whit%,FMP_rhit%,FMP_whit%,FMP_Used%,Read_Back_IO/s,Read_Back_MB/s,Dstg_Wrt_IO/s,Dstg_Wrt_MB/s"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "3")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatCache ####
#### Start Get-3parSRStatLD	 ####
Function Get-3parSRStatLD
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for logical disks.
  
  .DESCRIPTION
    Command displays historical performance data reports for logical disks.
	
  .EXAMPLE
    Get-3parSRStatLD 
	Command displays historical performance data reports for logical disks.
  .EXAMPLE
    Get-3parSRStatLD -option hourly -btsecs -24h
	example displays aggregate hourly performance statistics for all logical disks beginning 24 hours ago:
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of  <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        LDID      Logical disk ID
        LD_NAME   Logical disk name
        CPG_NAME  Common Provisioning Group name
        NODE      The node that owns the LD
   .PARAMETER cpgName   
	-cpgName <CPG_name|pattern>[,<CPG_name|pattern>...]
        Limit the data to LDs in CPGs with names that match one or more of the specified names or glob-style patterns.
  .PARAMETER Node
    -Node <node>[,<node>...]
        Limit the data to that corresponding to one of the specified nodes	
		-Node 0,1,2
  .PARAMETER LDName
        LDs matching either the specified LD_name or glob-style pattern are included. This specifier can be repeated to display information for multiple LDs. If not specified, all LDs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatLD
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatLD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$cpgName,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$Node,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$LDName,		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRStatLD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatLD since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatLD since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatld "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "LDID","DOM_NAME","LD_NAME","CPG_NAME","NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($Node)
		{
			$nodes = $Node.split(",")
			$srinfocmd += " $nodes"			
		}
		if($cpgName)
		{
			$srinfocmd += " -cpg $cpgName "
		}
		if($LDName)
		{
			$srinfocmd += " $LDName "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "LD_NAME"
			}
			Add-Content -Path $tempfile -Value "$optiontype,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "3"
			$rangestart = "4"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "4")
		{
			return "No data available"
		}
		$range1 = $range1 - 3
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatLD ####
#### Start Get-3parSRStatPD	 ####
Function Get-3parSRStatPD
{
<#
  .SYNOPSIS
    System reporter performance reports for physical disks (PDs).
  
  .DESCRIPTION
    System reporter performance reports for physical disks (PDs).
	
  .EXAMPLE
    Get-3parSRStatPD 
	System reporter performance reports for physical disks (PDs).
  .EXAMPLE
    Get-3parSRStatPD -option hourly -btsecs -24h
	example displays aggregate hourly performance statistics for all physical disks beginning 24 hours ago:
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        PDID      Physical disk ID
        PORT_N    The node number for the primary port for the the PD
        PORT_S    The PCI slot number for the primary port for the the PD
        PORT_P    The port number for the primary port for the the PD
        DISK_TYPE  The disktype of the PD
        SPEED     The speed of the PD
   .PARAMETER diskType   
    -diskType <type>[,<type>...]
        Limit the data to disks of the types specified. Allowed types are
            FC  - Fast Class
            NL  - Nearline
            SSD - Solid State Drive
   .PARAMETER rpmSpeed   
    -rpm <speed>[,<speed>...]
        Limit the data to disks of the specified RPM. Allowed speeds are 7, 10, 15, 100 and 150
  .PARAMETER PDID
        PDs with IDs that match either the specified PDID or glob-style pattern are included. This specifier can be repeated to include multiple PDIDs or patterns. If not specified, all PDs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatPD
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$diskType,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$rpmSpeed,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$PDID,		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRStatPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatPD since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatPD since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection

	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatpd "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "PDID","PORT_N","PORT_S","PORT_P","DISK_TYPE","SPEED"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($diskType)
		{
			$diskarr1 = "FC","NL","SSD"
			if($diskarr1 -eq $diskType.toUpper())
			{
				$srinfocmd += " -disk_type $diskType"
			}
			else
			{
				return "FAILURE: Invalid diskType Option it should be in ( $diskarr1 )"
			}	
		}
		if($rpmSpeed)
		{
			$rpmarr1 = "7","10","15","100","150"
			if($rpmarr1 -eq $rpmSpeed)
			{
				$srinfocmd += " -rpm $rpmSpeed"
			}
			else
			{
				return "FAILURE: Invalid rpm speed option it should be in ( $diskarr1 )"
			}	
		}
		if($PDID)
		{
			$srinfocmd += " $PDID "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PDID"
			}
			Add-Content -Path $tempfile -Value "PDID,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "3"
			#$rangestart = "4"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		Write-DebugLog "INFO: In Get-3parSRStatPD - cmd is -> $srinfocmd" $Debug
		#write-host " cmd = $srinfocmd"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd		
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "4")
		{
			return "No data available"
		}
		$range1 = $range1 - 3
		foreach ($s in  $Result[$rangestart..$range1] )
		{			
			$s= [regex]::Replace($s,"^ +","")			
			$s= [regex]::Replace($s," +"," ")			
			$s= [regex]::Replace($s," ",",")		
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatPD ####
#### Start Get-3parSRStatPort	 ####
Function Get-3parSRStatPort
{
<#
  .SYNOPSIS
     System reporter performance reports for ports.
  
  .DESCRIPTION
     System reporter performance reports for ports.
	
  .EXAMPLE
    Get-3parSRStatPort 
	 System reporter performance reports for ports.
  .EXAMPLE
    Get-3parSRStatPort -portType "disk,host" -option hourly -btsecs -24h -port "0:*:* 1:*:*"
	 Sexample displays aggregate hourly performance statistics for disk and host ports on nodes 0 and 1 beginning 24 hours ago:
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        PORT_N    The node number for the port
        PORT_S    The PCI slot number for the port
        PORT_P    The port number for the port
        PORT_TYPE The type of the port
        GBITPS    The speed of the port

   .PARAMETER portType   
    -portType <type>[,<type>...]
        Limit the data to port of the types specified. Allowed types are
			disk  -  Disk port
            host  -  Host Fibre channel port
            iscsi -  Host ISCSI port
            free  -  Unused port
            fs    -  File Persona port
            peer  -  Data Migration FC port
            rcip  -  Remote copy IP port
            rcfc  -  Remote copy FC port

  .PARAMETER port
    <npat>:<spat>:<ppat>
        Ports with <port_n>:<port_s>:<port_p> that match any of the specified
        <npat>:<spat>:<ppat> patterns are included, where each of the patterns
        is a glob-style pattern. This specifier can be repeated to include
        multiple ports or patterns. If not specified, all ports are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatPort
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatPort
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$portType,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$port,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRStatPort - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatPort since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatPort since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srstatport "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "PORT_N","PORT_S","PORT_P","PORT_TYPE","GBITPS"				
			$lista = $groupby.split(",")
			foreach($suba in $lista){
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($portType)
		{
			$commarr = "disk","host","iscsi","free","fs","peer","rcip","rcfc"
			$splitarr = $portType.split(",")
			foreach ($s in $splitarr){
				if($commarr -match $s.toLower())
				{				
				}
				else
				{
					return "FAILURE: Invalid port type option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -port_type $portType"

		}
		if($port)
		{
			$srinfocmd += " $port "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PORT_TYPE"
			}
			Add-Content -Path $tempfile -Value "PORT_TYPE,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "3"
			$rangestart = "4"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"			
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		if($range1 -le "4")
		{
			return "No data available"
		}
		$range1 = $range1 - 3
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatPort ####
#### Start Get-3parSRStatVLUN	 ####
Function Get-3parSRStatVLUN
{
<#
  .SYNOPSIS
    Command displays historical performance data reports for VLUNs.
  
  .DESCRIPTION
    Command displays historical performance data reports for VLUNs.
	
  .EXAMPLE
    Get-3parSRStatVLUN
	Command displays historical performance data reports for VLUNs.
  .EXAMPLE
    Get-3parSRStatVLUN -option hourly -btsecs -24h
	Example displays aggregate hourly performance statistics for all VLUNs beginning 24 hours ago:

  .EXAMPLE
    Get-3parSRStatVLUN -btsecs -2h -host "set:hostset" -vv "set:vvset*"
	 VV or host sets can be specified with patterns:
	 
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        VV_NAME   Virtual Volume name
        HOST_NAME Host name
        LUN       The LUN number for the VLUN
        HOST_WWN  The host WWN for the VLUN
        PORT_N    The node number for the VLUN  port
        PORT_S    The PCI slot number for the VLUN port
        PORT_P    The port number for the VLUN port
        VVSET_NAME    Virtual volume set name
        HOSTSET_NAME  Host set name
   .PARAMETER host
    -host <host_name|host_set|pattern>[,<host_name|host_set|pattern>...]
        Limit the data to hosts with names that match one or more of the specified names or glob-style patterns. Host set name must start with
  .PARAMETER vv
    -vv <VV_name|VV_set|pattern>[,<VV_name|VV_set|pattern>...]
        Limit the data to VVs with names that match one or more of thespecified names or glob-style patterns. VV set name must be prefixed by "set:" and can also include patterns.
   .PARAMETER lun  
       -lun <LUN|pattern>[,<LUN|pattern>...]
        Limit the data to LUNs that match one or more of the specified LUNs or glob-style patterns.
  .PARAMETER Port
    -port <npat>:<spat>:<ppat>[,<npat>:<spat>:<ppat>...]
        Ports with <port_n>:<port_s>:<port_p> that match any of the specified <npat>:<spat>:<ppat> patterns are included, where each of the patterns is a glob-style pattern. If not specified, all ports are included.	
		
	 .PARAMETER vLun <host>:<vv>[:<lun>:<port_n>:<port_s>:<port_p>][,<host>:<vv>[:<lun>:<port_n>:<port_s>:<port_p>]]...
        Limit the data to VLUNs matching the specified combination of host, VV,
        lun, and port. Each of these components in this option may be a
        glob-style pattern. The host and VV components may specify a
        corresponding object set by prefixing "set:" to the component. The
        host component may specify a WWN by prefixing the component with
        "wwn:". The lun and port components are optional, and if not present,
        data will be filtered to any matching combination of host and VV.
        This option cannot be combined with -host, -vv, -l, or -port.

    .PARAMETER vmName {<VM_name>|<pattern>}[,{<VM_name>|<pattern>}]
        Limit the data to VMs that match one or more of the specified VM names
        or glob-styled patterns for VVol based VMs.

    .PARAMETER vmId {<VM_ID>|<pattern>}[,{<VM_ID>|<pattern>}]
        Limit the data to VMs that match one or more of the specified VM IDs
        or glob-styled patterns for VVol based VMs.

    .PARAMETER vmHost {<VM_host_name>|<pattern>}[,{<VM_host_name>|<pattern>}]
        Limit the data to VMs that match one or more of the specified VM host
        names or glob-styled patterns for VVol based VMs.

    .PARAMETER vvoLsc {<VVol_container_name>|<pattern>}[,{<VVol_container_name>|<pattern>}...]
        Limit the data to VVol containers that match one or more of the
        specified VVol container names or glob-styled patterns.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRStatVLUN
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRStatVLUN
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Summary,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$host,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vv,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$lun,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$port,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vLun,
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmName,
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmHost,
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vvoLsc,
		[Parameter(Position=14, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmId,
		[Parameter(Position=15, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Get-3parSRStatVLUN - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRStatVLUN since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRStatVLUN since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
    $tempFile = [IO.Path]::GetTempFileName()	
	$srinfocmd = "srstatvlun "
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "HOST_NAME"
			}
			Add-Content -Path $tempfile -Value "Host_Name,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
			$rangestart = "4"
		}
		else
		{
			$rangestart = "3"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,IO/s_Rd,IO/s_Wr,IO/s_Tot,KBytes/s_Rd,KBytes/s_Wr,KBytes/s_Tot,Svct/ms_Rd,Svct/ms_Wr,Svct/ms_Tot,IOSz/KBytes_Rd,IOSz/KBytes_Wr,IOSz/KBytes_Tot,QLen,AvgBusy%"
		}
		if($Summary)
		{
			$srinfocmd += " -summary $Summary"
		}
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}				
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower()){
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","VV_NAME","HOST_NAME","LUN","HOST_WWN","PORT_N","PORT_S","PORT_P","VVSET_NAME","HOSTSET_NAME"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{
					$srinfocmd += " -groupby $groupby"
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}			
		}
		if($host)
		{
			$srinfocmd += " -host $host"			
		}
		if($vv)
		{
			$srinfocmd += " -vv $vv "
		}
		if($lun)
		{
			$srinfocmd += " -l $lun "
		}
		if($port)
		{
			$srinfocmd += " -port $port "
		}
		if($vLun)
		{
			$srinfocmd += " -vlun $vLun "
		}	
        if($vmName)
		{
			$srinfocmd += " -vmname $vmName "
		}
		if($vmId)
		{
			$srinfocmd += " -vmid $vmId "
		}		
		if($vmHost)
		{
			$srinfocmd += " -vmhost $vmHost "
		}
		if($vvoLsc)
		{
			$srinfocmd += " -vvolsc $vvoLsc "
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		#write-host " Result = $Result"
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}		
		if($Result.count -gt 4)
		{			
			#$tempFile = [IO.Path]::GetTempFileName()
			$range1  = $Result.count -3 
			if($range1 -le "4")
			{
				return "No data available"
			}
			foreach ($s in  $Result[$rangestart..$range1] )
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				#write-host "s $s"
				Add-Content -Path $tempfile -Value $s
			}
			Import-Csv $tempFile	
			del $tempFile
		}
		else
		{
			return "No Data Available"
		}
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRStatVLUN ####
#### Start Get-3parSRHistLd ####
Function Get-3parSRHistLd
{
<#
  .SYNOPSIS
    Displays historical histogram performance data reports for logical disks.  
  .DESCRIPTION
    Displays historical histogram performance data reports for logical disks.
  .EXAMPLE
    Get-3parSRHistLd 
	Displays historical histogram performance data reports for logical disks. 
  .EXAMPLE
    Get-3parSRHistLd -option hourly -btsecs -24h
	example displays aggregate hourly histogram performance statistics for all logical disks beginning 24 hours ago:

  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER rw
       Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        LDID      Logical disk ID
        LD_NAME   Logical disk name
        CPG_NAME  Common Provisioning Group name
        NODE      The node that owns the LD

   .PARAMETER cpgName
        Limit the data to LDs in CPGs with names that match one or more of the specified names or glob-style patterns.
  .PARAMETER node
		Limit the data to that corresponding to one of the specified nodes.

  .PARAMETER LDName
        LDs matching either the specified LD_name or glob-style pattern are included. This specifier can be repeated to display information for multiple LDs. If not specified, all LDs are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
  .Notes
    NAME:  Get-3parSRHistLd
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRHistLd   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$cpgName,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$node,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LDName,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRHistLd - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRHistLd since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRHistLd since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistld "
	$3parosver = Get-3parVersion -number -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "DOM_NAME","LDID","LD_NAME","CPG_NAME","NODE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($cpgName)
		{
			$srinfocmd +=  " -cpg $cpgName "
		}
		if($node)
		{
			$nodes = $node.split(",")
			$srinfocmd +=  " -node $nodes "			
		}
		if($LDName)
		{
				$srinfocmd += " $LDName "
		}
		if($Metric_Val)
		{			
			$a = "both","time","size"
			$l=$Metric_Val
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric_Val"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-3parSRHistLd   since -option $option in incorrect "
				Return "FAILURE : Metric :- $Metric_Val is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		#write-host " cmd = $srinfocmd"
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "LD_NAME"
			}
			Add-Content -Path $tempfile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($range1 -le "3")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] ){
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRHistLd ####
#### Start Get-3parSRHistPD ####
Function Get-3parSRHistPD
{
<#
  .SYNOPSIS
    Command displays historical histogram performance data reports for physical disks.  
  .DESCRIPTION
    Command displays historical histogram performance data reports for physical disks.  
  .EXAMPLE
    Get-3parSRHistPD 
	Command displays historical histogram performance data reports for physical disks. 
  .EXAMPLE
    Get-3parSRHistPD -option hourly -btsecs -24h
	Example displays aggregate hourly histogram performance statistics for all physical disks beginning 24 hours ago:	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER rw
       Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        LDID      Logical disk ID
        LD_NAME   Logical disk name
        CPG_NAME  Common Provisioning Group name
        NODE      The node that owns the LD

  .PARAMETER diskType
        Limit the data to disks of the types specified. Allowed types are
			FC  - Fast Class
            NL  - Nearline
            SSD - Solid State Drive
  .PARAMETER rpmSpeed
        Limit the data to disks of the specified RPM. Allowed speeds are 7, 10, 15, 100 and 150

  .PARAMETER PDID
        LDs matching either the specified LD_name or glob-style pattern are included. This specifier can be repeated to display information for multiple LDs. If not specified, all LDs are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
  .Notes
    NAME:  Get-3parSRHistPD
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRHistPD   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$diskType,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$rpmSpeed,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PDID,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRHistPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRHistPD since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRHistPD since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistpd "
	$3parosver = Get-3parVersion -number -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "PDID","PORT_N","PORT_S","PORT_P","DISK_TYPE","SPEED"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower()){
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($diskType)
		{
			$diskarr1 = "FC","NL","SSD"
			if($diskarr1 -eq $diskType.toUpper())
			{
				$srinfocmd +=  " -disk_type $diskType "
			}
			else
			{
				return "FAILURE: Invalid diskType it should be in ( $diskarr1 )"
			}
			
		}
		if($Metric_Val)
		{			
			$a = "both","time","size"
			$l=$Metric_Val
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric_Val"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-3parSRHistPD   since -option $option in incorrect "
				Return "FAILURE : Metric :- $Metric_Val is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		if($rpmSpeed)
		{
			$rpmarr1 = "7","10","15","100","150"
			if($rpmarr1 -eq $rpmSpeed)
			{
				$srinfocmd +=  " -rpm $rpmSpeed "
			}
			else
			{
				return "FAILURE: Invalid rpmSpeed it should be in ( $rpmarr1 )"
			}		
		}
		if($PDID)
		{
				$srinfocmd += " $PDID "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PDID"
			}
			Add-Content -Path $tempfile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($range1 -le "3")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRHistPD ####
#### Start Get-3parSRHistPort ####
Function Get-3parSRHistPort
{
<#
  .SYNOPSIS
    Command displays historical histogram performance data reports for ports. 
  .DESCRIPTION
    Command displays historical histogram performance data reports for ports. 
  .EXAMPLE
    Get-3parSRHistPort 
	Command displays historical histogram performance data reports for ports. 
  .EXAMPLE
    Get-3parSRHistPort -option hourly -btsecs -24h -portType "host,disk" -port "0:*:* 1:*:*"
	example displays aggregate hourly histogram performance statistics for disk and host ports on nodes 0 and 1 beginning 24 hours ago:
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER rw
       Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
		For -attime reports, generate a separate row for <groupby> items. Each <groupby> must be different and one of the following:
			• PORT_N The node number for the port
			• PORT_S The PCI slot number for the port 
			• PORT_P The port number of the port
			• PORT_TYPE Port type
			• GBITPS The speed of the port

  .PARAMETER portType
        Limit the data to port of the types specified. Allowed types are
            disk  -  Disk port
            host  -  Host Fibre channel port
            iscsi -  Host ISCSI port
            free  -  Unused port
            fs    -  File Persona port
            peer  -  Data Migration FC port
            rcip  -  Remote copy IP port
            rcfc  -  Remote copy FC port

  .PARAMETER Port
		<npat>:<spat>:<ppat>
		Ports with <port_n>:<port_s>:<port_p> that match any of the specified[<npat>:<spat>:<ppat>...] patterns are included, where each of the patterns is a glob-style pattern. If not specified, all ports are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
  .Notes
    NAME:  Get-3parSRHistPort
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRHistPort
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$portType,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Port,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRHistPort - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRHistPort since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRHistPort since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistport "
	$3parosver = Get-3parVersion -number -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{

		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "PORT_N","PORT_S","PORT_P","PORT_TYPE","GBITPS"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($portType)
		{
			$commarr = "disk","host","iscsi","free","fs","peer","rcip","rcfc"
			$splitarr = $portType.split(",")
			foreach ($s in $splitarr){
				if($commarr -match $s.toLower())
				{				
				}
				else
				{
					return "FAILURE: Invalid port type option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -port_type $portType"	
		}		
		if($Port)
		{
				$srinfocmd += " $Port "
		}
		if($Metric_Val)
		{			
			$a = "both","time","size"
			$l=$Metric_Val
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric_Val"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-3parSRHistPort   since -option $option in incorrect "
				Return "FAILURE : Metric :- $Metric_Val is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PORT_TYPE"
			}
			Add-Content -Path $tempfile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($Result -match "FAILURE")
		{
			return $Result
		}
		if($range1 -le "")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}

}
#### End Get-3parSRHistPort ####

#### Start Get-3parSRHistVLUN ####
Function Get-3parSRHistVLUN
{
<#
  .SYNOPSIS
    Command displays historical histogram performance data reports for VLUNs. 
  .DESCRIPTION
    Command displays historical histogram performance data reports for  VLUNs.  
  .EXAMPLE
    Get-3parSRHistVLUN 
	Command displays historical histogram performance data reports for  VLUNs. 
  .EXAMPLE
    Get-3parSRHistVLUN  -option hourly -btsecs -24h
	example displays aggregate hourly histogram performance statistics for all VLUNs beginning 24 hours ago:
  .EXAMPLE
    Get-3parSRHistVLUN -btsecs -2h -host "set:hostset" -vv "set:vvset*"
	VV or host sets can be specified with patterns:
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER rw
       Specifies that the display includes separate read and write data. If notspecified, the total is displayed.
	   
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of  <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        VV_NAME   Virtual Volume name
        HOST_NAME Host name
        LUN       The LUN number for the VLUN
        HOST_WWN  The host WWN for the VLUN
        PORT_N    The node number for the VLUN  port
        PORT_S    The PCI slot number for the VLUN port
        PORT_P    The port number for the VLUN port
        VVSET_NAME    Virtual volume set name
        HOSTSET_NAME  Host set name


  .PARAMETER host
		 -host <host_name|host_set|pattern>[,<host_name|host_set|pattern>...]
        Limit the data to hosts with names that match one or more of the
        specified names or glob-style patterns. Host set name must start with
        "set:" and can also include patterns.
		
  .PARAMETER vv		
		-vv <VV_name|VV_set|pattern>[,<VV_name|VV_set|pattern>...]
        Limit the data to VVs with names that match one or more of the specified names or glob-style patterns. VV set name must be prefixed by "set:" and can also include patterns.
  .PARAMETER lun
      -lun <LUN|pattern>[,<LUN|pattern>...]
        Limit the data to LUNs that match one or more of the specified LUNs or glob-style patterns.

  .PARAMETER Port
    -port <npat>:<spat>:<ppat>[,<npat>:<spat>:<ppat>...]
        Ports with <port_n>:<port_s>:<port_p> that match any of the specified <npat>:<spat>:<ppat> patterns are included, where each of the patterns is a glob-style pattern. If not specified, all ports are included.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
  .Notes
    NAME:  Get-3parSRHistVLUN
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parSRHistVLUN
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$rw,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$groupby,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$host,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$vv,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$lun,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Port,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRHistVLUN - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRHistVLUN since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRHistVLUN since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srhistvlun "
	$3parosver = Get-3parVersion -number -SANConnection  $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($rw)
		{
			$srinfocmd +=  " -rw "
		}
		if($groupby)
		{
			$commarr =  "DOM_NAME","VV_NAME","HOST_NAME","LUN","HOST_WWN","PORT_N","PORT_S","PORT_P","VVSET_NAME","HOSTSET_NAME"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($host)
		{
			$srinfocmd +=  " -host $host "	
		}
		if($vv)
		{
			$srinfocmd +=  " -vv $vv "	
		}
		if($lun)
		{
			$srinfocmd +=  " -l $lun "	
		}		
		if($Port)
		{
				$srinfocmd += " -port $Port "
		}
		if($Metric_Val)
		{			
			$a = "both","time","size"
			$l=$Metric_Val
			if($a -eq $l)
			{
				$srinfocmd += " -metric $Metric_Val"			
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
				Return "FAILURE : Metric :- $Metric_Val is an Incorrect [ both | time | size ]  can be used only . "
			}
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "HOST_NAME"
			}
			Add-Content -Path $tempfile -Value "$optionname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
			$rangestart = "3"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes)"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		$range1  = $Result.count
		if($range1 -le "3")
		{
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRHistVLUN ####

#### Start Get-3parSRAlertCrit ####
Function Get-3parSRAlertCrit
{
<#
  .SYNOPSIS
    Shows the criteria that System Reporter evaluates to determine if a performance alert should be generated.
  
  .DESCRIPTION
    Shows the criteria that System Reporter evaluates to determine if a performance alert should be generated.
        
  .EXAMPLE
    Get-3parSRAlertCrit 
	shows the criteria that System Reporter evaluates to determine if a performance alert should be generated.
  .EXAMPLE
    Get-3parSRAlertCrit -Option daily
	Example displays all the criteria evaluated on an hourly basis:
  .EXAMPLE
	Get-3parSRAlertCrit -Option hires
	
  .PARAMETER Option
  Type must be one of the following: 

	daily
		This criterion will be evaluated on a daily basis at midnight.
	hourly
		This criterion will be evaluated on an hourly basis.
	hires
		This criterion will be evaluated on a high resolution (5 minute) basis. This is the default.
	major
		This alert should require urgent action.
	minor
		This alert should require not immediate action.
	info
		This alert is informational only. This is the default.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRAlertCrit
    LASTEDIT: 08/17/2015
    KEYWORDS: Get-3parSRAlertCrit
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Option ,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	write-DebugLog "Start: In Get-3parSRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRAlertCrit since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRAlertCrit since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	$Option = $Option.toLower()
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-3parVersion -number  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current 3par version $version1 does not support these cmdlet"
	}
	$srinfocmd = "showsralertcrit "
	$commonarray = "hourly","daily","hires","major","minor","info","enabled","disabled","critical"
	if($Option)
	{
		if($commonarray -eq $Option )
		{			
			$srinfocmd +=" -$Option"
		}
		else
		{
			return "FAILURE :  Invalid Option type, -option type must be in (  $commonarray )"
		}
	}
	#write-host "Final Command is $srinfocmd"
	write-debuglog "Get alert criteria command => $srinfocmd" "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
	if($Result -match "Invalid")
	{
		return "FAILURE : $Result"
	}
	if($Result -match "No criteria listed")
	{
		return "No srcriteria listed"
	}
	$tempFile = [IO.Path]::GetTempFileName()
	$range1 = $Result.count-3
	foreach ($s in  $Result[0..$range1] )
	{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
	}
	Import-Csv $tempFile
	del $tempFile
}
#### End Get-3parSRAlertCrit ####
#### Start Set-3parSRAlertCrit ####
Function Set-3parSRAlertCrit
{
<#
  .SYNOPSIS
    Command allows users to enable or disable a System Reporter alert criterion
  
  .DESCRIPTION
    Command allows users to enable or disable a System Reporter alert criterion
        
  .EXAMPLE
    Set-3parSRAlertCrit -Option enable -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option disable -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option daily -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option hourly -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option hires -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option count -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option critical -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option major -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option minor -Name write_port_check

  .EXAMPLE
	Set-3parSRAlertCrit -Option info -Name write_port_check

  .PARAMETER Option
	Option values should be as enable or disable
	-daily
        This criterion will be evaluated on a daily basis at midnight.

    -hourly
        This criterion will be evaluated on an hourly basis.

    -hires
        This criterion will be evaluated on a high resolution (5 minute) basis.
        This is the default.
		
    -count <number>
        The number of matching objects that must meet the criteria in order for
        the alert to be generated. Note that only one alert is generated in this
        case and not one alert per affected object.
	-critical
        This alert has the highest severity.

    -major
        This alert should require urgent action.

    -minor
        This alert should not require immediate action.

    -info
        This alert is informational only. This is the default.

    -enable
        Enables the specified criterion.

    -disable
        Disables the specified criterion.

  .PARAMETER Name
	Specifies the name of the criterion to modify.  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parSRAlertCrit
    LASTEDIT: 08/17/2015
    KEYWORDS: Set-3parSRAlertCrit
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $option,
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $Name,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
        $Number,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Set-3parSRAlertCrit - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parSRAlertCrit since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parSRAlertCrit since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$version1 = Get-3parVersion -number  -SANConnection $SANConnection
	if( $version1 -lt "3.2.1")
	{
		return "Current 3par version $version1 does not support these cmdlet"
	}
	$srinfocmd = "setsralertcrit "
	$commonarray = "enable","disable","daily","hourly","hires","count","critical","major","minor","info"
	$Option = $Option.toLower()
	if(($Option) -and ($Name))
	{
		if($commonarray -eq $Option )
		{
			$srinfocmd += " -$Option"
			if($Option -eq "count")
			{
				$srinfocmd +=" $Number"
			}
			$srinfocmd  += " $Name"
		}
		else
		{
			return "FAILURE :  Invalid Option , it must be in  (  $commonarray )"
		}
	}
	else
	{
		return "FAILURE : A change option must be specified (or) Criterion name required."
	}
	#write-host "Final Command is $srinfocmd"
	write-debuglog "Set alert crit command => $srinfocmd" "INFO:"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
	if($Result)
	{
		return "FAILURE : There is Null response from Server..."
	}
	else
	{
		if($Option -eq "enable")
		{
			return "SUCCESS : sralert $Name is enabled "
		}
		elseif($Option -eq "disable")
		{
			return "SUCCESS : sralert $Name is disabled"
		}
		else
		{
			return $Result
		}		
	}	
}
#### End Set-3parSRAlertCrit ####
#### Start Get-3parSRCPGSpace ####
Function Get-3parSRCPGSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for common provisioning groups (CPGs).
  
  .DESCRIPTION
    Command displays historical space data reports for common provisioning groups (CPGs).
	
  .EXAMPLE
    Get-3parSRCPGSpace 
	Command displays historical space data reports for common provisioning groups (CPGs).
  .EXAMPLE
    Get-3parSRCPGSpace -Option hourly -btsecs -24h fc*
	example displays aggregate hourly CPG space information for CPGs with names that match the pattern "fc*" beginning 24 hours ago:

  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and  one of the following:
        DOM_NAME  Domain name
        CPGID     Common Provisioning Group ID
        CPG_NAME  Common Provisioning Group name
        DISK_TYPE  The disktype of the PDs used by the CPG
        RAID_TYPE The RAID type of the CPG

  .PARAMETER disk_type 
        Limit the data to disks of the types specified. Allowed types are
            FC  - Fast Class
            NL  - Nearline
            SSD - Solid State Drive

  .PARAMETER raid_type
        Limit the data to RAID of the specified types. Allowed types are 0, 1, 5 and 6

		
  .PARAMETER CPG_name
        CPGs matching either the specified CPG_name or glob-style pattern are included. This specifier can be repeated to display information for multiple CPGs. If not specified, all CPGs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRCPGSpace
    LASTEDIT: 08/19/2015
    KEYWORDS: Get-3parSRCPGSpace
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DiskType,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$RaidType,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$CpgName,		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRCPGSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRCPGSpace since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRCPGSpace since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srcpgspace"
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		$tempFile = [IO.Path]::GetTempFileName()

		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","CPGID","CPGID","CPGID","RAID_TYPE"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else{
				return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"

		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}		
		if($RaidType)
		{
			$raidarray = "0","1","5","6"
			if($raidarray -eq $RaidType)
			{
				$srinfocmd += " -raid_type $RaidType"
			}
			else
			{
				return "FAILURE: Invalid raid option, it should be in ( $raidarray )"
			}			
		}
		if($DiskType)
		{
			$diskarray = "FC","NL","SSD"
			if($diskarray -eq $DiskType.toUpper()){
				$srinfocmd += " -disk_type $DiskType"			
			}
			else{
				return "FAILURE: Invalid disktype option, it should be in ( $diskarray )"
			}
		}
		if($CpgName)
		{
			$srinfocmd += " $CpgName"			
		}		
		if($attime)
		{		
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "CPG_NAME"
			}
			Add-Content -Path $tempfile -Value "$optionname,Used(MB)_Adm,Used(MB)_Snp,Used(MB)_Usr,Used(MB)_Total,Free(MB)_Adm,Free(MB)Snp,Free(MB)Usr,Free(MB)Total,Total(MB)_Adm,Total(MB)_Snp,Total(MB)_Usr,Total(MB)_Total,Growth(MB),CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
			$rangestart = "3"			
		}	
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,Used(MB)_Adm,Used(MB)_Snp,Used(MB)_Usr,Used(MB)_Total,Free(MB)_Adm,Free(MB)Snp,Free(MB)Usr,Free(MB)Total,Total(MB)_Adm,Total(MB)_Snp,Total(MB)_Usr,Total(MB)_Total,Growth(MB),CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		#write-host "count = $range1"		
		if($range1 -le "3")
		{			
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
				#write-host " s= $s"
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				Add-Content -Path $tempfile -Value  $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRCPGSpace ####
#### Start Get-3parSRLDSpace ####
Function Get-3parSRLDSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for logical disks (LDs).
  
  .DESCRIPTION
    Command displays historical space data reports for logical disks (LDs).
	
  .EXAMPLE
    Get-3parSRLDSpace 
	Command displays historical space data reports for logical disks (LDs).
  .EXAMPLE
    Get-3parSRLDSpace -raidType 5 -Option hourly -btsecs -24h -LDName fc*
	Example displays aggregate hourly LD space information for all RAID 5 LDs with names that match either "fc*" patterns beginning 24 hours ago:
	
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        CPG_NAME  Common Provisioning Group name
        LDID      Logical disk ID
        LD_NAME   Logical disk name
        DISK_TYPE  The disktype of the PDs used by the LD
        RAID_TYPE The RAID type of the LD
        SET_SIZE  The RAID set size of the LD
        STEP_SIZE The RAID step size of the LD
        ROW_SIZE  The RAID row size of the LD
        OWNER     The owner node for the LD

  .PARAMETER cpgName
     Limit the data to LDs in CPGs with names that match one or more of the specified names or glob-style pattern
  .PARAMETER disk_type 
        Limit the data to disks of the types specified. Allowed types are
            FC  - Fast Class
            NL  - Nearline
            SSD - Solid State Drive

  .PARAMETER raidtype
        Limit the data to RAID of the specified types. Allowed types are 0, 1, 5 and 6
  .PARAMETER ownernode
        Limit data to LDs owned by the specified nodes.

		
  .PARAMETER LDname
        CPGs matching either the specified CPG_name or glob-style pattern are included. This specifier can be repeated to display information for multiple CPGs. If not specified, all CPGs are included.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRLDSpace
    LASTEDIT: 08/19/2015
    KEYWORDS: Get-3parSRLDSpace
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$cpgName,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DiskType,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$RaidType,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$ownernode,		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$LDname,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Get-3parSRLDSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRLDSpace since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRLDSpace since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srldspace"
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","CPG_NAME","LDID","LD_NAME","DISK_TYPE","RAID_TYPE","SET_SIZE","STEP_SIZE","ROW_SIZE","OWNER"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower()){
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}		
		if($RaidType)
		{
			$raidarray = "0","1","5","6"
			if($raidarray -eq $RaidType)
			{
				$srinfocmd += " -raid_type $RaidType"			
			}
			else
			{
				return "FAILURE: Invalid raid option, it should be in ( $raidarray )"
			}			
		}
		if($DiskType)
		{
			$diskarray = "FC","NL","SSD"
			if($diskarray -eq $DiskType.toUpper())
			{
				$srinfocmd += " -disk_type $DiskType"			
			}
			else
			{
				return "FAILURE: Invalid disktype option, it should be in ( $diskarray )"
			}
		}
		if($cpgName)
		{
				$srinfocmd += " -cpg $cpgName"
		}
		if($ownernode)
		{
			$srinfocmd +=  " -owner $ownernode"
		}
		if($LDname)
		{
			$srinfocmd += " $LDName"			
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "LD_NAME"
			}
			Add-Content -Path $tempfile -Value "$optionname,Raw(MB),Used(MB),Free(MB),Total(MB)"
			$rangestart = "3"
		}
		else
		{
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,Raw(MB),Used(MB),Free(MB),Total(MB)"
			$rangestart = "2"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		#write-host "count = $range1"		
		if($range1 -le "3")
		{
			return "No data available"
		}		
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRLDSpace ####
#### Start Get-3parSRPDSpace ####
Function Get-3parSRPDSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for physical disks (PDs).
  
  .DESCRIPTION
    Command displays historical space data reports for physical disks (PDs).
	
  .EXAMPLE
    Get-3parSRPDSpace 
	Command displays historical space data reports for physical disks (PDs).
  .EXAMPLE
    Get-3parSRPDSpace  -hourly -btsecs -24h
	Example displays aggregate hourly PD space information for all PDs beginning 24 hours ago:
  .EXAMPLE
    Get-3parSRPDSpace -capacity -attime -diskType SSD
	Displays current system capacity values of SSD PDs:
 .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        PDID      Physical disk ID
        CAGEID    Cage ID
        CAGESIDE  Cage Side
        MAG       Disk Magazine number within the cage
        DISK      Disk position within the magazine
        DISK_TYPE The disktype of the PD
        SPEED     The disk speed

  .PARAMETER disktype 
        Limit the data to disks of the types specified. Allowed types are
            FC  - Fast Class
            NL  - Nearline
            SSD - Solid State Drive
  .PARAMETER capacity
     Display disk contributions to the system capacity categories: Allocated, Free, Failed, and Total

  .PARAMETER rpmspeed
      Limit the data to disks of the specified RPM. Allowed speeds are  7, 10, 15, 100 and 150

	
  .PARAMETER PDID
        PDs with IDs that match either the specified PDID or glob-style  pattern are included. This specifier can be repeated to include multiple PDIDs or patterns. If not specified, all PDs are included.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRPDSpace
    LASTEDIT: 08/19/2015
    KEYWORDS: Get-3parSRPDSpace
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$DiskType,
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$capacity,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$rpmspeed,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$PDID,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)
	Write-DebugLog "Start: In Get-3parSRPDSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRPDSpace since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRPDSpace since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}	
	$srinfocmd = "srpdspace"
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{		
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($groupby)
		{
			$commarr = "PDID","CAGEID","CAGESIDE","MAG","DISK","DISK_TYPE","SPEED"
			$lista = $groupby.split(",")
			foreach($suba in $lista)
			{
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option it should be in ( $commarr1 )"
			}			
		}
		if($capacity)
		{
			$srinfocmd +=  " -capacity "
		}
		if($rpmspeed)
		{
			$rpmarray = "7","10","15","100","150"
			if($rpmarray -eq $rpmspeed)
			{
				$srinfocmd += " -rpm $rpmspeed"
			}
			else
			{
				return "FAILURE: Invalid rpmspeed it should be in ( $rpmarray )"
			}			
		}
		if($DiskType)
		{
			$diskarray = "FC","NL","SSD"
			if($diskarray -eq $DiskType.toUpper())
			{
				$srinfocmd += " -disk_type $DiskType"			
			}
			else
			{
				return "FAILURE: Invalid disktype option, it should be in ( $diskarray )"
			}
		}
		if($PDID)
		{
				$srinfocmd += " $PDID "
		}
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{
			$srinfocmd += " -attime "
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			$rangenodata = "3"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "PDID"
			}
			Add-Content -Path $tempfile -Value "$optionname,Normal(Chunklets)_Used_OK,Normal(Chunklets)_Used_Fail,Normal(Chunklets)_Avail_Clean,Normal(Chunklets)_Avail_Dirty,Normal(Chunklets)_Avail_Fail,Spare(Chunklets)_Used_OK,Spare(Chunklets)_Used_Fail,Spare(Chunklets)_Avail_Clean,Spare(Chunklets)_Avail_Dirty,Spare(Chunklets)_Avail_Fail"			
			$rangestart = "3"
		}
		else
		{
			$rangenodata = "3"
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,Normal(Chunklets)_Used_OK,Normal(Chunklets)_Used_Fail,Normal(Chunklets)_Avail_Clean,Normal(Chunklets)_Avail_Dirty,Normal(Chunklets)_Avail_Fail,Spare(Chunklets)_Used_OK,Spare(Chunklets)_Used_Fail,Spare(Chunklets)_Avail_Clean,Spare(Chunklets)_Avail_Dirty,Spare(Chunklets)_Avail_Fail"
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		#write-host "count = $range1"
		if($range1 -le "3")
		{			
			return "No data available"
		}		
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRPDSpace ####
#### Start Get-3parSRVVSpace ####
Function Get-3parSRVVSpace
{
<#
  .SYNOPSIS
    Command displays historical space data reports for virtual volumes (VVs).
  
  .DESCRIPTION
    Command displays historical space data reports for virtual volumes (VVs).
	
  .EXAMPLE
    Get-3parSRVVSpace 
	Command displays historical space data reports for virtual volumes (VVs).
  .EXAMPLE
    Get-3parSRVVSpace  -option hourly -btsecs -24h -VVName dbvv*
	example displays aggregate hourly VV space information for VVs with names matching either "dbvv*"  patterns beginning 24 hours ago:
  .EXAMPLE
    Get-3parSRVVSpace -option daily -attime -groupby vv_name -vvName tp*
	 Example displays VV space information for the most recent daily sample aggregated by the VV name for VVs with names that match the pattern "tp*".
  .PARAMETER attime
	Performance is shown at a particular time interval, specified by the -etsecs option, with one row per object 	group described by the -groupby option. Without this option, performance is shown versus time with a row per time interval.
  .PARAMETER btsecs
    Select the begin time in seconds for the report.The value can be specified as either
        - The absolute epoch time (for example 1351263600).
		- A negative number indicating the number of seconds before the current time. Instead of a number representing seconds, <secs> canbe specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):        
			- For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.
  .PARAMETER etsecs
     Select the end time in seconds for the report.  If -attime is   specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent sample.
  
  .PARAMETER Option
	hires
		Select high resolution samples (5 minute intervals) for the report. This is the default setting.
	hourly
		Select hourly samples for the report.
	daily   
		Select daily samples for the report.
  .PARAMETER Groupby
        For -attime reports, generate a separate row for each combination of <groupby> items.  Each <groupby> must be different and one of the following:
        DOM_NAME  Domain name
        VVID      Virtual volume ID
        VV_NAME   Virtual volume name
        BSID      Virtual volume ID of the base virtual volume
        WWN       Virtual volume world wide name (WWN)
        SNP_CPG_NAME  Snap space Common Provisioning Group name
        USR_CPG_NAME  User space Common Provisioning Group name
        PROV_TYPE  The virtual volume provisioning type
        VV_TYPE   The type of the virtual volume
        VVSET_NAME    Virtual volume set name

  .PARAMETER usrcpg 
       Only include VVs whose usr space is mapped to a CPG whose name matches one of the specified CPG_name or glob-style patterns.

  .PARAMETER snpcpg
       Only include VVs whose snp space is mapped to a CPG whose name matches one of the specified CPG_name or glob-style patterns.


  .PARAMETER provType
      Limit the data to disks of the specified RPM. Allowed speeds are  7, 10, 15, 100 and 150

	
  .PARAMETER VVName
        PDs with IDs that match either the specified PDID or glob-style  pattern are included. This specifier can be repeated to include multiple PDIDs or patterns. If not specified, all PDs are included.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSRVVSpace
    LASTEDIT: 08/19/2015
    KEYWORDS: Get-3parSRVVSpace
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$attime,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$btsecs,
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$etsecs,
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$groupby,
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$usrcpg,		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$snpcpg,
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$provType,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$VVName,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmName,
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmHost,
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vvoLsc,
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vmId,
		[Parameter(Position=13, Mandatory=$false, ValueFromPipeline=$true)]
		[system.string]
		$vvolState,
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)
	Write-DebugLog "Start: In Get-3parSRVVSpace - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSRVVSpace since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSRVVSpace since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$srinfocmd = "srvvspace"
	$3parosver = Get-3parVersion -number  -SANConnection $SANConnection
	if($3parosver -ge "3.1.2")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		if($attime)
		{		
			$srinfocmd += " -attime "	
			write-debuglog "System reporter command => $srinfocmd" "INFO:"
			if($groupby)
			{
				$optionname = $groupby.toUpper()
			}
			else
			{
				$optionname = "VV_NAME"
			}
			$rangestart = "3"
			Add-Content -Path $tempfile -Value "$optionname,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Admin,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Admin(MB)_Used,Admin(MB)_Free,Admin(MB)_Rsvd,Admin(MB)_Vcopy,Total(MB)_VcopyTotal(MB)_Used,Total(MB)_Rsvd,Total(MB)_VirtualSize,CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
		}
		else
		{
			$rangestart = "2"
			Add-Content -Path $tempfile -Value "Date,Time,TimeZone,Secs,RawRsvd(MB)_User,RawRsvd(MB)_Snap,RawRsvd(MB)_Admin,RawRsvd(MB)_Total,User(MB)_Used,User(MB)_Free,User(MB)_Rsvd,Snap(MB)_Used,Snap(MB)_Free,Snap(MB)_Rsvd,Snap(MB)_Vcopy,Admin(MB)_Used,Admin(MB)_Free,Admin(MB)_Rsvd,Admin(MB)_Vcopy,Total(MB)_VcopyTotal(MB)_Used,Total(MB)_Rsvd,Total(MB)_VirtualSize,CapacityEfficiency_Compaction,CapacityEfficiency_Dedup"
		}
		if($btsecs)
		{
			$srinfocmd += " -btsecs $btsecs"
		}
		if($etsecs)
		{
			$srinfocmd += " -etsecs $etsecs"
		}
		if($Option)
		{
			$commarr1 = "hourly","daily","hires"
			if($commarr1 -eq $Option.toLower())
			{
				$srinfocmd += " -"
				$srinfocmd += $Option
			}
			else
			{
				return "FAILURE: Invalid Option type it should be in ( $commarr1 )"
			}			
		}
		if($groupby)
		{
			$commarr = "DOM_NAME","VVID","VV_NAME","BSID","WWN","SNP_CPG_NAME","USR_CPG_NAME","PROV_TYPE","VV_TYPE","VVSET_NAME"
			$lista = $groupby.split(",")
			foreach($suba in $lista){
				if($commarr -eq $suba.toUpper())
				{					
				}
				else
				{
					return "FAILURE: Invalid groupby option it should be in ( $commarr )"
				}
			}
			$srinfocmd += " -groupby $groupby"
		}		
		
		if($usrcpg)
		{
			$srinfocmd +=  " -usr_cpg $usrcpg "
		}
		if($snpcpg)
		{
			$srinfocmd +=  " -snp_cpg $snpcpg "
		}
		if($provType)
		{
			$provrray = "cpvv","dds","full","peer","snp","tdvv","tpsd","tpvv"
			if($provrray -eq $provType){
				$srinfocmd += " -prov $provType"
			}
			else
			{
				return "FAILURE: Invalid provType it should be in ( $provrray )"
			}			
		}
		if($VVName)
		{
			$srinfocmd += " $VVName "
		}		
        if($vmName)
		{
			$srinfocmd += " -vmname $vmName "
		}
		if($vmId)
		{
			$srinfocmd += " -vmid $vmId "
		}		
		if($vmHost)
		{
			$srinfocmd += " -vmhost $vmHost "
		}
		if($vvoLsc)
		{
			$srinfocmd += " -vvolsc $vvoLsc "
		}
		if($vvolState)
		{
			$srinfocmd += " -vvolstate $vvolState "
		}
		#write-host " cmd = $srinfocmd"
		write-debuglog "System reporter command => $srinfocmd" "INFO:"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $srinfocmd
		if($Result -contains "FAILURE")
		{
			return "FAILURE : $Result"
		}
		$range1  = $Result.count
		#write-host "count = $range1"		
		if($range1 -le "3")
		{			
			return "No data available"
		}
		foreach ($s in  $Result[$rangestart..$range1] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return "Current 3par version $3parosver does not support these cmdlet"
	}
}
#### End Get-3parSRVVSpace ####

#### End SR Commands
####################################################################################################################
## FUNCTION Find-3parCage
####################################################################################################################
Function Find-3parCage
{
<#
  .SYNOPSIS
   The Find-3parCage command allows system administrators to locate a drive cage, drive magazine, or port in the system using the devices’ blinking LEDs.
 
 .DESCRIPTION
   The Find-3parCage command allows system administrators to locate a drive cage, drive magazine, or port in the system using the devices’ blinking LEDs. 
	
	.EXAMPLE
	Find-3parCage -time 30 -CageName cage0
	
	This example causes the Fibre Channel LEDs on the drive CageName cage0 to blink for 30 seconds.
   
	.EXAMPLE  
	Find-3parCage -time 30 -CageName cage0 -mag 3
	
	This example causes the Fibre Channel LEDs on the drive CageName cage0 to blink for 30 seconds,Indicates the drive magazine by number 3.
   
	.EXAMPLE  
	Find-3parCage -time 30 -CageName cage0 -port_name demo1
	
	This example causes the Fibre Channel LEDs on the drive CageName cage0 to blink for 30 seconds, If a port is specified, the port LED will oscillate between green and off.
	
	.EXAMPLE  	
	Find-3parCage -CageName cage1 -mag 2
	
	This example causes the Fibre Channel LEDs on the drive CageName cage1 to blink, Indicates the drive magazine by number 2.
	
		
  .PARAMETER time 
	Specifies the number of seconds, from 0 through 255 seconds, to blink the LED. 
	If the argument is not specified, the option defaults to 60 seconds.
  
  .PARAMETER CageName 
	Specifies the drive cage name as shown in the Name column of List-3parCage command output.
	
  .PARAMETER mag 
	Indicates the drive magazine by number.
		• For DC1 drive cages, accepted values are 0 through 4.
		• For DC2 and DC4 drive cages, accepted values are 0 through 9.
		• For DC3 drive cages, accepted values are 0 through 15.
		
  .PARAMETER PortName  
  Indicates the port specifiers. Accepted values are A0|B0|A1|B1|A2|B2|A3|B3. 
  If a port is specified, the port LED will oscillate between green and off.
    
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
	NAME:  Find-3parCage
    LASTEDIT: 08/05/2015
    KEYWORDS: Find-3parCage
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Time,
		
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$CageName,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Mag,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$PortName,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Find-3parCage   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Find-3parCage   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Find-3parCage since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "locatecage "			
	if ($time)
	{
		$s = 0..255
		$demo = $time
		if($s -match $demo)
		{
			$str="time"
			$cmd+=" -t $time"
		}
		else
		{
			return " Error : -time $time is Not valid use seconds, from 0 through 255 Only "
		}
	}
	if ($CageName)
	{
		$cmd2="showcage "
		$Result2 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
		if($Result2 -match $CageName)
		{
			$cmd+=" $CageName"
		}
		else
		{
		Write-DebugLog "Stop: Exiting Find-3parCage $CageName Not available "
		return "FAILURE : -CageName $CageName  is Unavailable `n Try using [Get-3parCage] Command "
		}
	}
	else
	{
		Write-DebugLog "Stop: CageName is Mandate" $Debug
		return "Error :  -CageName is Mandate. "
	}	
	if ($Mag)
	{
		$a = 0..15
		$demo = $Mag
		if($a -match $demo)
		{
		$str="mag"
		$cmd +=" $Mag"
		}
		else
		{
			return "Error : -Mag $Mag is Not valid use seconds,from 0 through 15 Only"		
		}
	}	
	if ($PortName)
	{
		$s=$str
		if ($s -match "mag" )
		{
			return "FAILURE : -Mag $Mag cannot be used along with  -PortName $PortName "
		}
		else
		{	
			$a = $PortName
			$b = "A0","B0","A1","B1","A2","B2","A3","B3"
			if($b -eq $a)
			{
				$cmd +=" $PortName"
			}
			else
			{
				return "Error : -PortName $PortName is invalid use [ A0| B0 | A1 | B1 | A2 | B2 | A3 | B3 ] only  "
			}
		}	
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Find-3parCage Command , surface scans or diagnostics on physical disks with the command --> $cmd " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : Find-3parCage Command Executed Sucessfully $Result"
	}
	else
	{
		return  "FAILURE : While EXECUTING Find-3parCage `n $Result"
	} 		
}
# End Find-3parCage
####################################################################################################################
## FUNCTION Set-3parCage
####################################################################################################################
Function Set-3parCage
{
<#
  .SYNOPSIS
   The Set-3parCage command enables service personnel to set or modify parameters for a drive cage.
   
 .DESCRIPTION
  The Set-3parCage command enables service personnel to set or modify parameters for a drive cage.
  
	
	.EXAMPLE
	Set-3parCage -Position left -CageName cage1
	This example demonstrates how to assign cage1 a position description of Side Left.

	.EXAMPLE
	Set-3parCage -Position left -PSModel 1 -CageName cage1
    This  example demonstrates how to assign model names to the power supplies in cage1. Inthisexample, cage1 hastwopowersupplies(0 and 1).
				
  .PARAMETER Position  
	Sets a description for the position of the cage in the cabinet, where <position> is a description to be assigned by service personnel (for example, left-top)
  
   .PARAMETER PSModel	  
	Sets the model of a cage power supply, where <model> is a model name to be assigned to the power supply by service personnel.
	get information regarding PSModel try using  [ Get-3parCage -option d ]
	
  
  .PARAMETER CageName	 
	Indicates the name of the drive cage that is the object of the setcage operation.
	
	
  .Notes
    NAME:  Set-3parCage
    LASTEDIT: 08/05/2015
    KEYWORDS: Set-3parCage
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Position,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$PSModel,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$CageName,
			
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)	
	Write-DebugLog "Start: In Set-3parCage  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parCage   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parCage   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "setcage "
	if ($Position )
	{
		$cmd+="position $Position "
	}		
	if ($PSModel)
	{
		$cmd2="showcage -d"
		$Result2 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
		if($Result2 -match $PSModel)
		{
			$cmd+=" ps $PSModel "
		}	
		else
		{
			Write-DebugLog "Stop: Exiting  Set-3parCage -PSModel $PSModel is Not available "
			return "Failure: -PSModel $PSModel is Not available. To Find Available Model `n Try  [Get-3parCage -option d ] Command"
		}
	}		
	if ($CageName)
	{
		$cmd1="showcage"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
		if($Result1 -match $CageName)
		{
			$cmd +="$CageName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Set-3parCage -CageName $CageName is Not available "
			return "Failure:  -CageName $CageName is Not available `n Try using [ Get-3parCage ] Command to get list of Cage Name "
		}	
	}	
	else
	{
		Write-DebugLog "Stop: Exiting  Set-3parCage NO parameters is passed CageName is Mandate "
		return "ERROR: -CageName is Mandate For the Command to Execute"
	}		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Set-3parCage command enables service personnel to set or modify parameters for a drive cage --> $cmd" "INFO:" 		
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parCage Command $Result "
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parCage $Result"
	} 		
} # End Set-3parCage	
####################################################################################################################
## FUNCTION Set-3parPD
####################################################################################################################

Function Set-3parPD
{
<#
  .SYNOPSIS
   The Set-3parPD command marks a Physical Disk (PD) as allocatable or non allocatable for Logical   Disks (LDs).
   
 .DESCRIPTION
  The Set-3parPD command marks a Physical Disk (PD) as allocatable or non allocatable for Logical   Disks (LDs).
   
	
	.EXAMPLE
	Set-3parPD -Ldalloc off -PD_ID 20
	
	displays PD 20 marked as non allocatable for LDs.
   
   .EXAMPLE  
	Set-3parPD -Ldalloc on -PD_ID 25
	
	displays PD 25 marked as allocatable for LDs.
   		
  .PARAMETER ldalloc 
	Specifies that the PD, as indicated with the PD_ID specifier, is either allocatable (on) or nonallocatable for LDs (off).
  	
  .PARAMETER PD_ID 
	Specifies the PD identification using an integer.
	
     
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parPD
    LASTEDIT: 08/05/2015
    KEYWORDS: Set-3parPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Ldalloc,
		
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$PD_ID,
			
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-3parPD   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parPD   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parPD   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "setpd "	
	if ($Ldalloc)
	{
		$a = "on","off"
		$l=$Ldalloc
		if($a -eq $l)
		{
			$cmd+=" ldalloc $Ldalloc "	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Set-3parPD  since -Ldalloc in incorrect "
			return "FAILURE : -Ldalloc $Ldalloc cannot be used only [on|off] can be used . "
		}
	}
	else
	{
		Write-DebugLog "Stop: Ldalloc is Mandate" $Debug
		return "Error :  -Ldalloc is Mandate. "		
	}		
	if ($PD_ID)
	{
		$PD=$PD_ID
		if($PD -gt 4095)
		{ 
			Write-DebugLog "Stop: Exiting Set-3parPD  since  -PD_ID $PD_ID Illegal integer argument "
			return "FAILURE : -PD_ID $PD_ID Illegal integer argument . Expected range [0-4095].  "
		}
		$cmd+=" $PD_ID "
	}
	else
	{
		Write-DebugLog "Stop: PD_ID is Mandate" $Debug
		return "Error :  -PD_ID is Mandate. "		
	}		
	if ($cmd -eq "setpd ")
	{
		Write-DebugLog "FAILURE : Set-3parPD Should be used with Parameters, No parameters passed."
		return get-help  Set-3parPD 
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	
	write-debuglog "  executing Set-3parPD Physical Disk (PD) as allocatable or non allocatable for Logical Disks (LDs). with the command --> $cmd" "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parPD  $Result"
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parPD $Result "
	} 	
} # End Set-3parPD	
###################################################################################################################
## FUNCTION Get-3parCage
####################################################################################################################

Function Get-3parCage
{
<#
  .SYNOPSIS
   The Get-3parCage command displays information about drive cages.
   
 .DESCRIPTION
   The Get-3parCage command displays information about drive cages.
    
	
	.EXAMPLE
	Get-3parCage
	This examples display information for a single system’s drive cages.

   
   .EXAMPLE  
	Get-3parCage -option -d -CageName cage2
	Specifies that more detailed information about the drive cage is displayed
	
	.EXAMPLE  
	Get-3parCage -option -i -CageName cage2
	Specifies that inventory information about the drive cage is displayed. 
   		
  .PARAMETER option 
	d  Specifies that more detailed information about the drive cage is displayed. If this option is not
		used, then only summary information about the drive cages is displayed. 
		
	e  Displays error information.
	
	c  Specifies to use cached information. This option displays information faster because the cage does
		not need to be probed, however, some information might not be up-to-date without that probe.

	sfp  Specifies information about the SFP(s) attached to a cage. Currently, additional SFP information
			can only be displayed for DC2 and DC4 cages.
			
	i	Specifies that inventory information about the drive cage is displayed. If this option is not used,
		then only summary information about the drive cages is displayed.
	
	svc  Displays inventory information with HPE serial number, spare part number, and so on. it is supported only on HPE 3PAR StoreServ 7000 Storagesystems and  HPE 3PAR 8000 series systems"
  
  .PARAMETER CageName  
	Specifies a drive cage name for which information is displayed. This specifier can be repeated to display information for multiple cages
 
     
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parCage
    LASTEDIT: 08/06/2015
    KEYWORDS: Get-3parCage
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$CageName,
			
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-3parCage   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parCage   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parCage   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "showcage "
	
	if ($option)
	{
		$a = "d","e","c","sfp","i"
		$option = $option.toLower()
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
		}
		elseif($l -eq "svc" )
		{
			$cmd+=" -svc -i "	
		}
		else
		{ 
			Return "FAILURE : -option $option cannot be used only [ d | e | c | sfp | i | svc ]  can be used . "
			Write-DebugLog "Stop: Exiting Get-3parCage   since -option $option in incorrect "
		}
	}
		
	if ($CageName)
	{
		$CN=$CageName
		$pdd="showcage "
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $pdd
		if($Result1 -match $CN )
		{
			$cmd+=" $CageName "
		}
		else 	
		{ 
			Write-DebugLog "Stop: Exiting Get-3parCage  since  -CageName $CageName is not available "
			return " FAILURE :-CageName $CageName is not available `n try using only [Get-3parCage] to get the list of CageName Available. "
		}
	}			
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Get-3parCage command that displays information about drive cages. with the command --> $cmd " "INFO:" 
	if($cmd -eq "showcage ")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 
		#Write-Host " Result Count =" $Result.Count
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s
			#Write-Host	" First if statement $s"		
		}
		Import-Csv $tempFile 
		del $tempFile
		return  " SUCCESS : EXECUTING Get-3parCage"
	}
	if($Result -match "Cage" )
	{
		$result		
	} 
	else
	{
		return  " FAILURE : While EXECUTING Get-3parCage  `n	$Result"
	} 
 } # End Get-3parCage
####################################################################################################################
## FUNCTION Get-3parPD
####################################################################################################################
Function Get-3parPD
{
<#
	.SYNOPSIS
		The Get-3parPD command displays configuration information about the physical disks (PDs) on a system. 

	.DESCRIPTION
		The Get-3parPD command displays configuration information about the physical disks (PDs) on a system. 
   
	.EXAMPLE  
		get-3parPD
		This example displays configuration information about all the physical disks (PDs) on a system. 
	
	.EXAMPLE  
		get-3parPD -PD_ID 5
		This example displays configuration information about specific or given physical disks (PDs) on a system. 
	
	.EXAMPLE  
		get-3parPD -option c 
		This example displays chunklet use information for all disks. 
	
	.EXAMPLE  
		get-3parPD -option c -PD_ID 5
		This example will display chunklet use information for all disks with the physical disk ID. 	

	.EXAMPLE  
      get-3parPD -option p -pattern mg -patternValue 0
	  TThis example will display all the FC disks in magazine 0 of all cages.
	
	.PARAMETER option 
	listcols  List the columns available to be shown in the 
	
	listcols :List the columns available to be shown in the -showcols option described below (see 'clihelp -col showpd' for help on each column).
	
	-showcols <column>[,<column>...] : Explicitly select the columns to be shown using a comma-separated list of column names.
	
	i : The following columns are shown: Id, CagePos, State, Node_WWN, MFR, Model, Serial, FW_Rev, Protocol, MediaType, AdmissionTime.
	
	e :	Specifies a request for the disk environment and error information. Note that reading this information places a significant load on each disk.
	
	c : Show chunklet usage information. Any chunklet in a failed disk will be shown as "Fail".
	
	state : Shows detailed information regarding the state of each PD.
	
	s : Show detailed information regarding the state of each PD.
	
	path : 	Shows current and saved path information for disks. 
	
	space : Shows disk capacity usage information (MB).	
	
	failed : Specifies that only failed physical disks are displayed.

	degraded : Specifies that only degraded physical disks are displayed. 

	p <pattern> : Physical disks matching the specified pattern are displayed.
	
	nd <item> : Specifies one or more nodes.
	
	st <item> : Specifies one or more PCI slots. Slots are identified by one or more integers (item). 
	
	pt <item> : Specifies one or more ports. Ports are identified by one or more integers (item).
			
	cg <item> : Specifies one or more drive cages. Drive cages are identified by one or more integers (item).
			
	mg <item> : Specifies one or more drive magazines. 
	
	pn <item> : Specifies one or more disk positions within a drive magazine. 
			
	dk <item> : Specifies one or more physical disks.
			
	tc_gt <number> : Specifies that physical disks with total chunklets greater than the number specified be selected.
			
	tc_lt <number> : Specifies that physical disks with total chunklets less than the number specified be selected.
	
	fc_gt <number> : Specifies that physical disks with free chunklets greater than the number specified be selected.
	
	fc_lt <number> : Specifies that physical disks with free chunklets less than the number specified be selected.
	
	devid <model> : Specifies that physical disks identified by their models be selected.
	
	devtype <type> : Specifies that physical disks must have the specified device type(FC for Fast Class, NL for Nearline, SSD for Solid State Drive) to be used.
	
	rpm <number> : Drives must be of the specified relative performance metric, as shown in the "RPM" column of the "showpd" command.
	
	nodes <node_list> : Specifies that the display is limited to specified nodes and physical disks connected to those nodes.
	
	slots <slot_list> : Specifies that the display is limited to specified PCI slots and physical disks connected to those PCI slots.
	
	ports <port_list> : Specifies that the display is limited to specified ports and physical disks connected to those ports.
	
	.PARAMETER PD_ID
		Specifies a drive cage name for which information is displayed. This specifier can be repeated to display information for multiple cages
 
	.PARAMETER ColumnName
		Explicitly select the columns to be shown using a comma-separated list of column names.
   
	.PARAMETER.pattern
		this can be use only with Option "p". Physical disks matching the specified pattern are displayed.
   
	.PARAMETER.patternValue
		there expected values e.g. 1,2,3
   
	.PARAMETER node_list
		The node list is specified as a series of integers separated by commas (e.g. 1,2,3).
   
	.PARAMETER slot_list
		The slot list is specified as a series of integers separated by commas (e.g. 1,2,3).
   
	.PARAMETER port_list
		The port list is specified as a series of integers separated by commas (e.g. 1,2,3).   
   
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: get-3parPD
    LASTEDIT: 08/06/2015
    KEYWORDS: get-3parPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$PD_ID ,
		# if multiple values with , then put the value in semicolons like “A,b,c”
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$ColumnName ,
		
		# this is for option P pattern like "-nd,-st,-pt"
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$pattern ,
		
		# Multiple nodes are separated with a single comma(e.g. 1,2,3).
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$patternValue ,
		
		# The node list is specified as a series of integers separated by commas (e.g. 1,2,3).
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$node_list ,
		
		# The slot list is specified as a series of integers separated by commas (e.g. 1,2,3).
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$slot_list ,
		
		# The port list is specified as a series of integers separated by commas (e.g. 1,2,3).
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$port_list ,
			
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	Write-DebugLog "Start: In get-3parPD   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting get-3parPD   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting get-3parPD   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "showpd "	
	if ($option)
	{
		$a = "i","e","c","state","s","path","space","listcols","showcols","failed","degraded","p","nodes","slots","ports"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "
			if($option -eq "nodes")
			{
				$cmd+=" $node_list "
			}
			if($option -eq "slots")
			{
				$cmd+=" $slot_list "
			}
			if($option -eq "ports")
			{
				$cmd+=" $port_list "
			}
			if($option -eq "showcols")
			{
				$cmd+=" $ColumnName "
			}
			if($option -eq "p")
			{
				if ($pattern)
				{			
					$a = "nd","st","pt","cg","mg","pn","dk","tc_gt","tc_lt","fc_gt","fc_lt","devid","devtype","rpm"
					$l=$pattern
					if($a -eq $l)
					{
						$cmd+=" -$pattern "	
						
						if ($patternValue)
						{			
							$cmd+=" $patternValue"					
						}
						else
						{
							Return "FAILURE : -patternValue $patternValue is not in range or empty"
						}
					}
					else
					{ 
						Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $pattern in incorrect "
						Return "FAILURE : -pattern $pattern cannot be used only [nd | st | pt | cg | mg | pn | dk | tc_gt | tc_lt | fc_gt | fc_lt | devid | devtype | rpm]  can be used . "
					}
				}
				else
				{
					Return "FAILURE : With Option P pattern is required "
				}
			}			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [i | e | c | state | s | path | space | listcols | showcols | failed | degraded | p | nodes | slots | ports]  can be used . "
		}
	}	
	if ($PD_ID)
	{
		$PD=$PD_ID
		$pdd="showpd "
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $pdd
		if($Result1 -match $PD )
		{
			$cmd+=" $PD_ID "
		}
		else 	
		{ 
			Write-DebugLog "Stop: Exiting Get-3parPD  since  -PD_ID $PD_ID is not available "
			return " FAILURE : $PD_ID is not available try using only [Get-3parPD] to get the list of PD_ID Available. "
		}
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Get-3parCage command that displays information about drive cages. with the command --> $cmd" "INFO:" 
	#this section is for Options
	$optn = "i","e","c","state","s","path","space","degraded","p","nodes","slots","ports"
	$orgOptn=$option	
	if($optn -eq $orgOptn -Or !$option)
	{
	    #this is for option i
		if($orgOptn -eq "i" -Or $orgOptn -eq "state" -Or $orgOptn -eq "s")
		{
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count -3  
			#Write-Host " Result Count =" $Result.Count
			foreach ($s in  $Result[0..$LastItem] )
			{		
				$s= [regex]::Replace($s,"^ ","")			
				$s= [regex]::Replace($s," +",",")	
				$s= [regex]::Replace($s,"-","")
				$s= $s.Trim() 	
				Add-Content -Path $tempfile -Value $s
				#Write-Host	" First if statement $s"		
			}				
			Import-Csv $tempFile 
			del $tempFile
		}
		ElseIf($orgOptn -eq "c")
		{			
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count -3  
			$incre = "true"			
			foreach ($s in  $Result[2..$LastItem] )
			{	
				$s= [regex]::Replace($s,"^ ","")			
				$s= [regex]::Replace($s," +",",")
				$s= [regex]::Replace($s,"-","")
				$s= $s.Trim()				
				if($incre -eq "true")
				{
					$sTemp1=$s
					$sTemp = $sTemp1.Split(',')
					$sTemp[5]="OK(NormalChunklets)" 
					$sTemp[6]="Fail(NormalChunklets/Used)" 
					$sTemp[7]="Free(NormalChunklets)"
					$sTemp[8]="Uninit(NormalChunklets)"
					$sTemp[10]="Fail(NormalChunklets/UnUsed)"
					$sTemp[11]="OK(SpareChunklets)" 
					$sTemp[12]="Fail(SpareChunklets/Used)" 
					$sTemp[13]="Free(SpareChunklets)"
					$sTemp[14]="Uninit(SpareChunklets)"
					$sTemp[15]="Fail(SpareChunklets/UnUsed)"
					$newTemp= [regex]::Replace($sTemp," ",",")	
					$newTemp= $newTemp.Trim()
					$s=$newTemp
				}				
				Add-Content -Path $tempfile -Value $s
				#Write-Host	"$s"
				$incre="false"				
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		ElseIf($orgOptn -eq "e")
		{			
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count -3  
			$incre = "true"			
			foreach ($s in  $Result[1..$LastItem] )
			{	
				$s= [regex]::Replace($s,"^ ","")			
				$s= [regex]::Replace($s," +",",")
				$s= [regex]::Replace($s,"-","")
				$s= $s.Trim()				
				if($incre -eq "true")
				{
					$sTemp1=$s
					$sTemp = $sTemp1.Split(',')
					$sTemp[4]="Corr(ReadError)" 
					$sTemp[5]="UnCorr(ReadError)" 
					$sTemp[6]="Corr(WriteError)"
					$sTemp[7]="UnCorr(WriteError)"
					$newTemp= [regex]::Replace($sTemp," ",",")	
					$newTemp= $newTemp.Trim()
					$s=$newTemp
				}				
				Add-Content -Path $tempfile -Value $s
				#Write-Host	"$s"
				$incre="false"				
			}
				
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			if($Result -match "Id")
			{
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count -3  
				#Write-Host " Result Count =" $Result.Count
				foreach ($s in  $Result[1..$LastItem] )
				{		
					$s= [regex]::Replace($s,"^ ","")			
					$s= [regex]::Replace($s," +",",")
					$s= [regex]::Replace($s,"-","")
					$s= $s.Trim() 	
					Add-Content -Path $tempfile -Value $s
					#Write-Host	" only else statement"		
				}
				write-host "Column  Total and Free values are in (MiB)"	
				Import-Csv $tempFile 
				del $tempFile
			}
		}
	}		
	if($Result -match "Id" -Or $Result -match "total")
	{
		#$a = "i","e","c","state","s","path","space","listcols","showcols","failed"
		if($optn -eq $orgOptn -Or !$option)	
		{
			return  " SUCCESS : EXECUTING Get-3parPD  "
		}
		else
		{			
			return  $Result
		}
	}
	else
	{
		if($option -eq "failed")
		{
			#return  " FAILURE : While EXECUTING Get-3parPD  "
			return  $Result
		}		
		else
		{
			#return  " FAILURE : While EXECUTING Get-3parPD  "
			return $Result
		} 		
	} 	
} # End Get-3parPD
 
 ####################################################################################################################
## FUNCTION Approve-3parPD
####################################################################################################################
Function Approve-3parPD
{
<#
  .SYNOPSIS
    The Approve-3parPD command creates and admits physical disk definitions to enable the use of those disks.
  .DESCRIPTION
    The Approve-3parPD command creates and admits physical disk definitions to enable the use of those disks.
	
  .EXAMPLE
   Approve-3parPD 
   This example admits physical disks.
   
  .EXAMPLE
   Approve-3parPD -option nold
   Do not use the PD (as identified by the <world_wide_name> specifier) For logical disk allocation.
   
  .EXAMPLE
   Approve-3parPD -option nopatch
   Suppresses the check for drive table update packages for new hardware enablement.

  .EXAMPLE  	
	Approve-3parPD -option nold -wwn xyz
	Do not use the PD (as identified by the <world_wide_name> specifier) For logical disk allocation.

	
  .PARAMETER option
		takes the Options		
		-nold
			Do not use the PD (as identified by the <world_wide_name> specifier)
			for logical disk allocation.

		-nopatch
			Suppresses the check for drive table update packages for new
			hardware enablement.

  .PARAMETER wwn
		Indicates the World-Wide Name (WWN) of the physical disk to be admitted. If WWNs are
		specified, only the specified physical disk(s) are admitted.
	
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Approve-3parPD
    LASTEDIT: 08/04/2015
    KEYWORDS: Approve-3parPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
				
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$wwn,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	
	Write-DebugLog "Start: In Approve-3parPD   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Approve-3parPD   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Approve-3parPD   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "admitpd -f  "
	if ($option)
	{
		$a = "nold","nopatch"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [nold | nopatch]  can be used only . "
		}
	}	
	if($wwn)
	{
		$cmd += " $wwn"		
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Approve-3parPD command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Approve-3parPD
####################################################################################################################
## FUNCTION Test-3parPD
####################################################################################################################

Function Test-3parPD
{
<#
  .SYNOPSIS
    The Test-3parPD command executes surface scans or diagnostics on physical disks.
	
  .DESCRIPTION
    The Test-3parPD command executes surface scans or diagnostics on physical disks.
	
	
	.EXAMPLE
	Test-3parPD -specifier scrub -ch 500 -pd_ID 1
	This example Test-3parPD chunklet 500 on physical disk 1 is scanned for media defects.
   
   .EXAMPLE  
	Test-3parPD -specifier scrub -count 150 -pd_ID 1
	This example scans a number of chunklets starting from -ch 150 on physical disk 1.
   
	.EXAMPLE  
	Test-3parPD -specifier diag -path a -pd_ID 5
	This example Specifies a physical disk path as a,physical disk 5 is scanned for media defects.

		
	.EXAMPLE  	
	Test-3parPD -specifier diag -iosize 1s -pd_ID 3
	This example Specifies I/O size 1s, physical disk 3 is scanned for media defects.
	
	.EXAMPLE  	
	Test-3parPD -specifier diag -range 5m  -pd_ID 3
	This example Limits diagnostic to range 5m [mb] physical disk 3 is scanned for media defects.
		
  .PARAMETER specifier
	
	scrub - Scans one or more chunklets for media defects.
	diag - Performs read, write, or verifies test diagnostics.
  
  .PARAMETER ch
  To scan a specific chunklet rather than the entire disk.
  
  .PARAMETER count
  To scan a number of chunklets starting from -ch.
  
  .PARAMETER path
  Specifies a physical disk path as [a|b|both|system].
  
  .PARAMETER test
  Specifies [read|write|verify] test diagnostics. If no type is specified, the default is read .

  .PARAMETER iosize
  Specifies I/O size, valid ranges are from 1s to 1m. If no size is specified, the default is 128k .
	 
	.PARAMETER range
	Limits diagnostic regions to a specified size, from 2m to 2g.
	
	.PARAMETER pd_ID
	The ID of the physical disk to be checked. Only one pd_ID can be specified for the “scrub” test.
	
	.PARAMETER threads
	Specifies number of I/O threads, valid ranges are from 1 to 4. If the number of threads is not specified, the default is 1.
	
	.PARAMETER time
	Indicates the number of seconds to run, from 1 to 36000.
	
	.PARAMETER total
	Indicates total bytes to transfer per disk. If a size is not specified, the default size is 1g.
	
	.PARAMETER retry
	 Specifies the total number of retries on an I/O error.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Test-3parPD
    LASTEDIT: 08/04/2015
    KEYWORDS: Test-3parPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$specifier,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$ch,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$count,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$path,
		
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$test,
		
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$iosize,
		
		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$range,
		
		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$threads,
		
		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$time,
		
		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$total,
		
		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$retry,
		
		[Parameter(Position=7, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$pd_ID,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Test-3parPD   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Test-3parPD   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Test-3parPD   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "checkpd "	
	if ($specifier)
	{
		$spe = $specifier
		$demo = "scrub" , "diag"
		if($demo -eq $spe)
		{
			$cmd+=" $spe "
		}
		else
		{
			return " FAILURE : $spe is not a Valid specifier please use [scrub | diag] only.  "
		}
	}
	else
	{
		return " FAILURE :  -specifier is mandatory for Test-3parPD to execute  "
	}		
	if ($ch)
	{
		$a=$ch
		[int]$b=$a
		if($a -eq $b)
		{
			if($cmd -match "scrub")
			{
				$cmd +=" -ch $ch "
			}
			else
			{
				return "FAILURE : -ch $ch cannot be used with -Specification diag "
			}
		}	
		else
		{
			Return "Error :  -ch $ch Only Integers are Accepted "
	
		}
	}	
	if ($count)
	{
		$a=$count
		[int]$b=$a
		if($a -eq $b)
		{	
			if($cmd -match "scrub")
			{
				$cmd +=" -count $count "
			}
			else
			{
				return "FAILURE : -count $count cannot be used with -Specification diag "
			}
		}
		else
		{
			Return "Error :  -count $count Only Integers are Accepted "	
		}
	}		
	if ($path)
	{
		if($cmd -match "diag")
		{
			$a = $path
			$b = "a","b","both","system"
			if($b -match $a)
			{
				$cmd +=" -path $path "
			}
			else
			{
				return "FAILURE : -path $path is invalid use [a | b | both | system ] only  "
			}
		}
		else
		{
			return " FAILURE : -path $path cannot be used with -Specification scrub "
		}
	}		
	if ($test)
	{
		if($cmd -match "diag")
		{
			$a = $test 
			$b = "read","write","verify"
			if($b -eq $a)
			{
				$cmd +=" -test $test "
			}
			else
			{
				return "FAILURE : -test $test is invalid use [ read | write | verify ] only  "
			}
		}
		else
		{
			return " FAILURE : -test $test cannot be used with -Specification scrub "
		}
	}			
	if ($iosize)
	{	
		if($cmd -match "diag")
		{
			$cmd +=" -iosize $iosize "
		}
		else
		{
			return "FAILURE : -test $test cannot be used with -Specification scrub "
		}
	}			 
	if ($range )
	{
		if($cmd -match "diag")
		{
			$cmd +=" -range $range "
		}
		else
		{
			return "FAILURE : -range $range cannot be used with -Specification scrub "
		}
	}	
	if ($threads )
	{
		if($cmd -match "diag")
		{
			$cmd +=" -threads $threads "
		}
		else
		{
			return "FAILURE : -threads $threads cannot be used with -Specification scrub "
		}
	}
	if ($time )
	{
		if($cmd -match "diag")
		{
			$cmd +=" -time $time "
		}
		else
		{
			return "FAILURE : -time $time cannot be used with -Specification scrub "
		}
	}
	if ($total )
	{
		if($cmd -match "diag")
		{
			$cmd +=" -total $total "
		}
		else
		{
			return "FAILURE : -total $total cannot be used with -Specification scrub "
		}
	}
	if ($retry )
	{
		if($cmd -match "diag")
		{
			$cmd +=" -retry $retry "
		}
		else
		{
			return "FAILURE : -retry $retry cannot be used with -Specification scrub "
		}
	}
	if($pd_ID)
	{	
		$cmd += " $pd_ID "
	}
	else
	{
		return " FAILURE :  pd_ID is mandatory for Test-3parPD to execute  "
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing surface scans or diagnostics on physical disks with the command --> $cmd" "INFO:" 
	return $Result	
} # End Test-3parPD
# End
####################################################################################################################
## FUNCTION Set-3parStatpdch
#####################################################################################################################

Function Set-3parStatpdch
{
<#
  .SYNOPSIS
    The Set-3parStatpdch command starts and stops the statistics collection mode for chunklets.

  .DESCRIPTION
    The Set-3parStatpdch command starts and stops the statistics collection mode for chunklets.
 
  .EXAMPLE
   Set-3parStatpdch -option start -PD_ID 2
   This Example sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD) 2.

  
  .PARAMETER option  
    Specifies that the collection of statistics is either started or stopped for the specified Logical Disk
	(LD) and chunklet.

  .PARAMETER PD_ID   
    Specifies the PD ID.

	 .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parStatpdch
    LASTEDIT: 07/28/2015
    KEYWORDS: Set-3parStatpdch
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$PD_ID,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)			
	Write-DebugLog "Start: In Set-3parStatpdch   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parStatpdch   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parStatpdch  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd1 = "setstatpdch "
	if ($option )
	{
		$opt = $option
		$op = "start | stop"
		if($op -match $opt)
		{
			$cmd1 += "$opt"
		}
		else
		{
			Write-DebugLog "Connection object is null/empty or unavailable option "
			return "FAILURE : -option $opt is not valid only `n -option start|stop can be used "
		}		
	}
	else
	{
		write-debuglog "option parameter -option is empty. Simply return " "INFO:"
		return "Error : -option is mandatory .Command is not successful. "
	}
	if($PD_ID)
	{
		$cmd2="showpd"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
		if($Result1 -match $PD_ID)
		{
			$cmd1 += " $PD_ID "
		}
		Else
		{
			write-debuglog "PD_ID parameter $PD_ID is Unavailable. Simply return " "INFO:"
			return "Error:  PD_ID   is Invalid ."
		}		
	}
	else
	{
		write-debuglog "PD_ID parameter $PD_ID is empty. Simply return " "INFO:"
		return "Error : PD_ID is mandatory . Command is not successful "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
	write-debuglog "  The Set-3parStatpdch command starts and stops the statistics collection mode for chunklets.->$cmd" "INFO:"
	if([string]::IsNullOrEmpty($Result))
	{
		$Result
		return  "SUCCESS : EXECUTING Set-3parStatpdch 	 "
	}
	else
	{
		$Result
		return  "FAILURE : While EXECUTING Set-3parStatpdch 	"
	} 
} # End Set-3parStatpdch 
 
####################################################################################################################
## FUNCTION Set-3parstatch
####################################################################################################################
Function Set-3parstatch
{
<#
  .SYNOPSIS
    The Set-3parstatch command sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD).
  
  .DESCRIPTION
   The Set-3parstatch command sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD).
  
  .EXAMPLE 
  Set-3parstatch -option start -LDname test1 -CLnum 1
  Set-3parstatch -option stop -LDname test1 -CLnum 1
  
  This example starts and stops the statistics collection mode for chunklets.with the LD name test1.
  
	
  .PARAMETER option  
    Specifies that the collection of statistics is either started or stopped for the specified Logical Disk
	(LD) and chunklet.
  .PARAMETER LDname 	
	Specifies the name of the logical disk in which the chunklet to be configured resides.
  .PARAMETER CLnum 	
	Specifies the chunklet that is configured using the setstatch command.	
	 
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parstatch
    LASTEDIT: 07/28/2015
    KEYWORDS: Set-3parstatch
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LDname,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$CLnum,	
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-3parstatch   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parstatch   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parstatch  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd1 = "setstatch "
	if ($option)
	{
		$opt = $option
		$op = "start","stop"
		if($op -eq $opt)
		{
			$cmd1 += "$opt"
		}
		else
		{
			Write-DebugLog "Connection object is null/empty or unavailable option "
			return " FAILURE : -option $opt is not valid , only -option start|stop can be used."
		}	
	}
	
	if($LDname)
	{
		$cmd2="showld"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd2
		if($Result1 -match $LDname)
		{
			$cmd1 += " $LDname "
		}
		Else
		{
			write-debuglog "LDname parameter is Unavailable. Simply return " "INFO:"
			return "Error:  LDname  is Invalid ."
		}
	}
	else
	{
		write-debuglog "-LDname parameter  is empty. Simply return " "INFO:"
		return "Error: -LDname parameter  is mandatory ."
	}
	if($CLnum)
	{
		$cmd1+="$CLnum"
	}
	else	
	{
		write-debuglog "-CLnum parameter is Unavailable. Simply return " "INFO:"
		return "Error: -CLnum parameter  is mandatory ."
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
	write-debuglog "   The Set-3parstatch command sets the statistics collection mode for all in-use chunklets on a Physical Disk (PD).->$cmd" "INFO:"
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : Set-3parstatch $Result "
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parstatch $Result"
	} 
} # End Set-3parstatch  
# End
####################################################################################################################
## FUNCTION Get-3parHistChunklet
#####################################################################################################################

Function Get-3parHistChunklet  
{
<#
  .SYNOPSIS
    The Get-3parHistChunklet command displays a histogram of service times in a timed loop for individual chunklets
  
  .DESCRIPTION
	The Get-3parHistChunklet command displays a histogram of service times in a timed loop for individual chunklets
        
  .EXAMPLE
  
    Get-3parHistChunklet -iteration 1 
	This example displays one iteration of a histogram of service
		
  .EXAMPLE
    Get-3parHistChunklet –LDname dildil -iteration 1 
	identified by name, from which chunklet statistics are sampled.
  .EXAMPLE
	Get-3parHistChunklet -iteration 1 -option sizecols -FL_Col 1 2
	
  .PARAMETER option	
	-ld <LD_name>
        Specifies the logical disk name from which chunklet statistics are sampled.

    -ch <chunklet_num>
        Specifies that statistics are limited to only the specified chunklet, identified
        by number.

    -metric both|time|size
        Selects which metric to display. Metrics can be one of the following:
            both - (Default)Display both I/O time and I/O size histograms
            time - Display only the I/O time histogram
            size - Display only the I/O size histogram

    -timecols <fcol> <lcol>
        For the I/O time histogram, shows the columns from the first column
        <fcol> through last column <lcol>. The available columns range from 0
        through 31.

        The first column (<fcol>) must be a value greater than or equal to 0,
        but less than the value of the last column (<lcol>).

        The last column (<lcol>) must be less than or equal to 31.

        The first column includes all data accumulated for columns less than the
        first column and the last column includes accumulated data for all
        columns greater than the last column.

        The default value of <fcol> is 6.
        The default value of <lcol> is 15.
		
	-sizecols <fcol> <lcol>
        For the I/O size histogram, shows the columns from the first column
        (<fcol>) through the last column (<lcol>). Available columns range from
        0 through 15.

        The first column (<fcol>) must be a value greater than or equal to 0,
        but less than the value of the last column (<lcol>) (default value of 3).
        The last column (<lcol>) must be less than or equal to 15 (default value
        of 11).

        The default value of <fcol> is 3.
        The default value of <lcol> is 11.

    -pct
        Shows the access count in each bucket as a percentage. If this option is
        not specified, the histogram shows the access counts.

    -prev | -begin
        Histogram displays data either from a previous sample(-prev) or from
        when the system was last started(-begin). If no option is specified, the
        histogram shows data from the beginning of the command's execution.

    -rw
        Specifies that the display includes separate read and write data. If not
        specified, the total is displayed.
	
	-d <secs>
        Specifies the interval in seconds that statistics are sampled from
        using an integer from 1 through 2147483. If no count is specified, the
        command defaults to 2 seconds.

    -iter <number>
        Specifies that the histogram is to stop after the indicated number of
        iterations using an integer from 1 through 2147483647.
		
	-ni
        Specifies that histograms for only non-idle devices are displayed. This
        option is shorthand for the option -filt t,0,0.

		
  .PARAMETER iteration 
    Specifies that the histogram is to stop after the indicated number of iterations using an integer from

  .PARAMETER LDname 
    Specifies the Logical Disk (LD), identified by name, from which chunklet statistics are sampled.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parHistChunklet
    LASTEDIT: 07/21/2015
    KEYWORDS: Get-3parHistChunklet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
	
	    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$LDname,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Chunklet_num,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Metric_Val,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$FL_Col,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Secs,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$iteration,
			
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parHistChunklet - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{ 
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistChunklet since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistChunklet since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli 
	
	if($plinkresult -match "FAILURE :")	
	{
		Write-DebugLog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	
	$histchCMD = "histch"
	
	if($iteration )
	{
		$histchCMD+=" -iter $iteration"
	}
	else
	{
		return "Iteration is mandatory..."
	}
	
	if ($option)
	{
		$a = "ld","ch","metric","timecols","sizecols","pct","prev","rw","d","iter","ni"
		$l=$option
		if($a -eq $l)
		{
			$histchCMD+=" -$option "	
			if($option -eq "ld")
			{
				$histchCMD+=" $LDname"
			}   
			if($option -eq "ch")
			{
				$histchCMD+=" $Chunklet_num"
			} 
			if($option -eq "metric")
			{
				$histchCMD+=" $Metric_Val"
			}
			if($option -eq "timecols" -Or $option -eq "sizecols")
			{
				$histchCMD+=" $FL_Col"
			}
			if($option -eq "d")
			{
				$histchCMD+=" $Secs"
			}			
		}
		else
		{ 			
			Return "FAILURE : -option $option cannot be used only [ ld | ch | metric | timecols | sizecols | pct | prev | rw | d | iter | ni ]  can be used . "
		}
	}		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $histchCMD
	return $Result
	<#
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -le "5"){
		return "No data available"
	}
	Write-DebugLog " displays a histogram of service -->$histchCMD "INFO:"" 
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3
		Add-Content -Path $tempfile -Value 'Ldid,Ldname,logical_Disk_CH,Pdid,PdCh,0.5,1.0,2.0,4.0,8.0,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date'
		foreach ($s in  $Result[0..$Result.Count] )
		{
			if ($s -match "millisec"){
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "20")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	#>
}
#END Get-3parHistChunklet
####################################################################################################################
## FUNCTION Get-3parHistLD
####################################################################################################################
Function Get-3parHistLD
{
<#
  .SYNOPSIS
    The Get-3parHistLD command displays a histogram of service times for Logical Disks (LDs) in a timed
loop.
  
  .DESCRIPTION
    The Get-3parHistLD command displays a histogram of service times for Logical Disks (LDs) in a timed
loop.
        
	.EXAMPLE
    Get-3parHistLD -Iteration 1
	displays a histogram of service Iteration number of times
	
	 
	.EXAMPLE
	Get-3parHistLD -LdName abcd -Iteration 1
	displays a histogram of service linked with LD_NAME on  Iteration number of times
	
	.EXAMPLE
	Get-3parHistLD -Iteration 1 -VV_Name ZXZX
	 Shows only logical disks that are mapped to virtual volumes with names
        matching any of the names or patterns specified.
	
	.EXAMPLE
	Get-3parHistLD -Iteration 1 -Domain ZXZX
	   Shows only logical disks that are in domains with names matching any
        of the names or patterns specified.
	
	.EXAMPLE
	Get-3parHistLD -Iteration 1 -Percentage
	Shows the access count in each bucket as a percentage.
	
	.PARAMETER option
	-vv {<VV_name>|<pattern>}...
        Shows only logical disks that are mapped to virtual volumes with names
        matching any of the names or patterns specified. Multiple volumes or
        patterns can be repeated using a comma separated list.

    -domain {<domain_name>|<pattern>}...
        Shows only logical disks that are in domains with names matching any
        of the names or patterns specified. Multiple domain names or patterns
        can be repeated using a comma separated list.

    -metric both|time|size
        Selects which metric to display. Metrics can be one of the following:
            both - (Default)Display both I/O time and I/O size histograms
            time - Display only the I/O time histogram
            size - Display only the I/O size histogram

    -timecols <fcol> <lcol>
        For the I/O time histogram, shows the columns from the first column
        <fcol> through last column <lcol>. The available columns range from 0
        through 31.

        The first column (<fcol>) must be a value greater than or equal to 0,
        but less than the value of the last column (<lcol>).

        The last column (<lcol>) must be less than or equal to 31.

        The first column includes all data accumulated for columns less than the
        first column and the last column includes accumulated data for all
        columns greater than the last column.

        The default value of <fcol> is 6.
        The default value of <lcol> is 15.

	-sizecols <fcol> <lcol>
        For the I/O size histogram, shows the columns from the first column
        (<fcol>) through the last column (<lcol>). Available columns range from
        0 through 15.

        The first column (<fcol>) must be a value greater than or equal to 0,
        but less than the value of the last column (<lcol>) (default value of 3).
        The last column (<lcol>) must be less than or equal to 15 (default value
        of 11).

        The default value of <fcol> is 3.
        The default value of <lcol> is 11.

    -pct
        Shows the access count in each bucket as a percentage. If this option is
        not specified, the histogram shows the access counts.

    -prev | -begin
        Histogram displays data either from a previous sample(-prev) or from
        when the system was last started(-begin). If no option is specified, the
        histogram shows data from the beginning of the command's execution.

    -rw
        Specifies that the display includes separate read and write data. If not
        specified, the total is displayed.

    -d <secs>
        Specifies the interval in seconds that statistics are sampled from
        using an integer from 1 through 2147483. If no count is specified, the
        command defaults to 2 seconds.

    -iter <number>
        Specifies that the histogram is to stop after the indicated number of iterations using an integer from 1 through 2147483647.

    -ni
        Specifies that histograms for only non-idle devices are displayed. This
        option is shorthand for the option -filt t,0,0.	
	
	.PARAMETER Iteration 
    displays a histogram of service Iteration number of times
  
	.PARAMETER LdName 
    displays a histogram of service linked with LD_NAME
	
	.PARAMETER VV_Name {<VV_name>|<pattern>}...
        Shows only logical disks that are mapped to virtual volumes with names
        matching any of the names or patterns specified. Multiple volumes or
        patterns can be repeated using a comma separated list.

    .PARAMETER Domain {<domain_name>|<pattern>}...
        Shows only logical disks that are in domains with names matching any
        of the names or patterns specified. Multiple domain names or patterns
        can be repeated using a comma separated list.

    .PARAMETER Metric both|time|size
        Selects which metric to display. Metrics can be one of the following:
            both - (Default)Display both I/O time and I/O size histograms
            time - Display only the I/O time histogram
            size - Display only the I/O size histogram
	

    .PARAMETER Previous | Beginning
        Histogram displays data either from a previous sample(-prev) or from
        when the system was last started(-begin). If no option is specified, the
        histogram shows data from the beginning of the command's execution.
		
	.PARAMETER secs
        Specifies the interval in seconds that statistics are sampled
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parHistLD
    LASTEDIT: 07/23/2015
    KEYWORDS: Get-3parHistLD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration,	

		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$option,

		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$VV_Name,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Domain,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Matric,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$FL_Col,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Secs,
				
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$LdName,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parHistLD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistLD since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistLD since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$histldCmd = "histld "
	if ($Iteration)
	{
		$histldCmd += " -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "		
	}
	if ($option)
	{
		$a = "vv","domain","metric","timecols","sizecols","pct","prev","rw","d","iter","ni"
		$l=$option
		if($a -eq $l)
		{
			$histchCMD+=" -$option "	
			if($option -eq "vv")
			{
				$histchCMD+=" $VV_Name"
			}   
			if($option -eq "domain")
			{
				$histchCMD+=" $Domain"
			} 
			if($option -eq "metric")
			{
				$histchCMD+=" $Matric"
			}
			if($option -eq "timecols" -Or $option -eq "sizecols")
			{
				$histchCMD+=" $FL_Col"
			}
			if($option -eq "d")
			{
				$histchCMD+=" $Secs"
			}			
		}
		else
		{ 			
			Return "FAILURE : -option $option cannot be used only [ vv | domain | metric | timecols | sizecols | pct | prev | rw | d | iter | ni ]  can be used . "
		}
	}		
	if ($LdName)
	{
		#check wether ld is available or not 
		$cmd= "showld "
		$demo = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
		if($demo -match $LdName )
		{
			$histldCmd += "  $LdName"
		}
		else
		{ 
			return  "FAILURE : No LD_name $LdName found "
		}
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $histldCmd
	write-debuglog "  The Get-3parHistLD command displays a histogram of service times for Logical Disks (LDs) in a timed loop.->$cmd" "INFO:"	
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempfile -Value  'Logical_Disk_Name,0.50,1,2,4,8,16,32,64,128,256,4k,8k,16k,32k,64k,128k,256k,512k,1m,time,date' 
		foreach ($s in  $Result[0..$LastItem] )
		{			
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "-------") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				#write-host " s equal-1 $s"
				continue
			}
			#write-host "s = $s"
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
			#write-host "s final $s"
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parHistLD
# End
####################################################################################################################
## FUNCTION Get-3parHistPD
###################################################################################################################

Function Get-3parHistPD
{
<#
  .SYNOPSIS
    The Get-3parHistPD command displays a histogram of service times for Physical Disks (PDs).
  
  .DESCRIPTION
    The Get-3parHistPD command displays a histogram of service times for Physical Disks (PDs).
       
  .EXAMPLE
    Get-3parHistPD  -iteration 1 -WWN abcd
	Specifies the world wide name of the PD for which service times are displayed.
	 
  .EXAMPLE
	Get-3parHistPD -iteration 1
	The Get-3parHistPDcommand displays a histogram of service iteration number of times
	Histogram displays data from when the system was last started (–begin).
	
  .EXAMPLE	
	Get-3parHistPD -iteration 1 -Devinfo
	Indicates the device disk type and speed.
	
  .EXAMPLE	
	Get-3parHistPD -iteration 1 -Metric both
	(Default)Display both I/O time and I/O size histograms

    .PARAMETER WWN <WWN>
        Specifies the world wide name of the PD for which service times are displayed.

    .PARAMETER Nodes <node_list>
        Specifies that the display is limited to specified nodes and physical
        disks connected to those nodes. The node list is specified as a series
        of integers separated by commas (e.g. 1,2,3). The list can also consist
        of a single integer. If the node list is not specified, all disks on all
        nodes are displayed.

    .PARAMETER Slots <slot_list>
        Specifies that the display is limited to specified PCI slots and
        physical disks connected to those PCI slots. The slot list is specified
        as a series of integers separated by commas (e.g. 1,2,3). The list can
        also consist of a single integer. If the slot list is not specified, all
        disks on all slots are displayed.

    .PARAMETER Ports <port_list>
        Specifies that the display is limited to specified ports and
        physical disks connected to those ports. The port list is specified
        as a series of integers separated by commas (e.g. 1,2,3). The list can
        also consist of a single integer. If the port list is not specified, all
        disks on all ports are displayed.
		
	.PARAMETER Percentage
        Shows the access count in each bucket as a percentage. If this option is
        not specified, the histogram shows the access counts.

    .PARAMETER Previous | Beginning
        Histogram displays data either from a previous sample(-prev) or from
        when the system was last started(-begin). If no option is specified, the
        histogram shows data from the beginning of the command's execution.

   .PARAMETER Devinfo
        Indicates the device disk type and speed.

    .PARAMETER Metric both|time|size
        Selects which metric to display. Metrics can be one of the following:
            both - (Default)Display both I/O time and I/O size histograms
            time - Display only the I/O time histogram
            size - Display only the I/O size histogram
		
  .PARAMETER Iteration 
    Specifies that the histogram is to stop after the indicated number of iterations using an integer from 1 up-to 2147483647.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: List-3parhistpd
    LASTEDIT: 07/23/2015
    KEYWORDS: List-3parhistpd
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Iteration,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$WWN,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Nodes,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Slots,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Ports,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Devinfo,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Metric,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Beginning,				
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parHistPD - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistPD since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistPD since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$Cmd = "histpd "
	if($Iteration)
	{
		$Cmd += "-iter $Iteration"	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}	
		
	if ($WWN)
	{
		$Cmd += " -w $WWN"
	}
	if ($Nodes)
	{
		$Cmd += " -nodes $Nodes"
	}
	if ($Slots)
	{
		$Cmd += " -slots $Slots"
	}
	if ($Ports)
	{
		$Cmd += " -ports $Ports"
	}
	if ($Devinfo)
	{
		$Cmd += " -devinfo "
	}
	if($Metric)
	{
		$Met = $Metric
		$c = "both","time","size"
		$Metric = $metric.toLower()
		if($c -eq $Met)
		{
			$Cmd += " -metric $Metric "
		}
		else
		{
			return "FAILURE: -Metric $Metric is Invalid. Use only [ both | time | size ]."
		}
	}
	if ($Previous)
	{
		$Cmd += " -prev "
	}
	if ($Beginning)
	{
		$Cmd += " -begin "
	}
	if ($Percentage)
	{
		$Cmd += " -pct "
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd 
	write-debuglog "  The Get-3parHistPDcommand displays a histogram of service times for Physical Disks (PDs). --> $cmd" "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5")
	{
		return "No data available"
	}		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3		
		if("time" -eq $Metric.trim().tolower()){
		#write-host " in time"
			Add-Content -Path $tempfile -Value 'ID,Port,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),time,date'
			$range2 = "10"
		}
		elseif("size" -eq $Metric.trim().tolower()){
			#write-host " in size"
			Add-Content -Path $tempfile -Value 'ID,Port,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
			$range2 = "10"
		}
		else{
			Add-Content -Path $tempfile -Value  'ID,Port,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date' 
			$range2 = "20"
		}
		foreach ($s in  $Result[0..$Result.Count] )
		{
			if ($s -match "millisec"){
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "ID"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line			
			$aa=$s.split(",").length
			if ($aa -eq "20") 
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parHistPD
####################################################################################################################
## FUNCTION Get-3parHistPort
####################################################################################################################
Function Get-3parHistPort
{
<#
  .SYNOPSIS
    The Get-3parHistPort command displays a histogram of service times for ports within the system.
  
  .DESCRIPTION
   The Get-3parHistPort command displays a histogram of service times for ports within the system.
      
  .EXAMPLE
    Get-3parHistPort -iteration 1
	displays a histogram of service times with option it can be one of these [both|ctrl|data].
	 
  .EXAMPLE
	Get-3parHistPort -iteration 1 -Both
	Specifies that both control and data transfers are displayed(-both)
	
  .EXAMPLE
	Get-3parHistPort -iteration 1 -Nodes nodesxyz
	 Specifies that the display is limited to specified nodes and physical disks connected to those nodes.
	
   .EXAMPLE	
	Get-3parHistPort –Metric both -iteration 1
	displays a histogram of service times with -metric option. metric can be one of these –metric [both|time|size]
	
	.PARAMETER Both | CTL | Data
        Specifies that both control and data transfers are displayed(-both),
        only control transfers are displayed (-ctl), or only data transfers are
        displayed (-data). If this option is not specified, only data transfers
        are displayed.
	
    .PARAMETER Nodes <node_list>
        Specifies that the display is limited to specified nodes and physical
        disks connected to those nodes. The node list is specified as a series
        of integers separated by commas (e.g. 1,2,3). The list can also consist
        of a single integer. If the node list is not specified, all disks on all
        nodes are displayed.

    .PARAMETER Slots <slot_list>
        Specifies that the display is limited to specified PCI slots and
        physical disks connected to those PCI slots. The slot list is specified
        as a series of integers separated by commas (e.g. 1,2,3). The list can
        also consist of a single integer. If the slot list is not specified, all
        disks on all slots are displayed.

    .PARAMETER Ports <port_list>
        Specifies that the display is limited to specified ports and
        physical disks connected to those ports. The port list is specified
        as a series of integers separated by commas (e.g. 1,2,3). The list can
        also consist of a single integer. If the port list is not specified, all
        disks on all ports are displayed.
	
    .PARAMETER Host | Disk | RCFC | PEER
        Specifies to display only host ports (target ports), only disk ports
        (initiator ports), only Fibre Channel Remote Copy configured ports, or
        only Fibre Channel ports for Data Migration.
        If no option is specified, all ports are displayed.

    .PARAMETER Metric both|time|size
        Selects which metric to display. Metrics can be one of the following:
            both - (Default)Display both I/O time and I/O size histograms
            time - Display only the I/O time histogram
            size - Display only the I/O size histogram

	
	.PARAMETER Iteration 
    Specifies that the histogram is to stop after the indicated number of iterations using an integer from 1 up-to 2147483647.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parHistPort
    LASTEDIT: 07/24/2015
    KEYWORDS: Get-3parHistPort
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Iteration,	
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Both,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$CTL,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Data,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Nodes,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Slots,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Ports,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Host,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$PEER,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Disk,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$RCFC,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Metric,		
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Beginning,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-3parHistPort - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistPort since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistPort since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	$Cmd = "histport "
	if($Iteration)
	{	
		$Cmd +=" -iter $Iteration"
	}
	else
	{
		write-debuglog "Get-3parHistPort parameter is empty. Simply return  " "INFO:"
		return "Error: -Iteration Mandate"
	}
	if($Both)
	{	
		$Cmd +=" -both "
	}
	if($CTL)
	{	
		$Cmd +=" -ctl "
	}
	if($Data)
	{	
		$Cmd +=" -data "
	}
	if ($Nodes)
	{
		$Cmd += " -nodes $Nodes"
	}
	if ($Slots)
	{
		$Cmd += " -slots $Slots"
	}
	if ($Ports)
	{
		$Cmd += " -ports $Ports"
	}
	if($Host)
	{	
		$Cmd +=" -host "
	}
	if($Disk)
	{	
		$Cmd +=" -disk "
	}
	if($RCFC)
	{	
		$Cmd +=" -rcfc "
	}
	if($PEER)
	{	
		$Cmd +=" -peer "
	}
	if ($Metric)
	{
		$Cmd += " -metric "
		$a1="both","time","size"
		$Metric = $Metric.toLower()
		if($a1 -eq $Metric )
		{
			$Cmd += "$Metric "
		}		
		else
		{
			return "FAILURE:  -Metric $Metric  is Invalid. Only [ both | time | size ] can be used."
		}
	}	
	if ($Previous)
	{
		$Cmd += " -prev "
	}
	if ($Beginning)
	{
		$Cmd += " -begin "
	}
	if ($Percentage)
	{
		$Cmd += " -pct "
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5"){
		return "No data available"
	}		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		
		if("time" -eq $Metric.trim().tolower()){
		
		Add-Content -Path $tempfile -Value 'Port,Data/Ctrl,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),time,date'
		}
		elseif("size" -eq $Metric.trim().tolower()){
			#write-host " in size"
			Add-Content -Path $tempfile -Value 'Port,Data/Ctrl,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		else{
			#write-host " in else"
			Add-Content -Path $tempfile -Value 'Port,Data/Ctrl,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "millisec")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$s +=",$global:time1,$global:date1"	
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parHistPort
# End
####################################################################################################################
## FUNCTION Get-3parStatCMP
####################################################################################################################
Function Get-3parStatCMP
{
<#
  .SYNOPSIS
   The Get-3parStatCMP command displays Cache Memory Page (CMP) statistics by node or by Virtual Volume (VV).
   
  .DESCRIPTION
   The Get-3parStatCMP command displays Cache Memory Page (CMP) statistics by node or by Virtual Volume (VV).
  
	
	.EXAMPLE
	Get-3parStatCMP -Iteration 1
	This Example displays Cache Memory Page (CMP).
	
	.EXAMPLE
   Get-3parStatCMP -VVname Demo1 -Iteration 1
   This Example displays Cache Memory Page (CMP) statistics by node or by Virtual Volume (VV).
	
  		
  .PARAMETER VVname   
	Specifies that statistics are displayed for virtual volumes matching the specified name or pattern.
	
	.PARAMETER Domian 
	Shows VVs that are in domains with names that match one or more of the specified domains or patterns.
	
	.PARAMETER Delay  
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.
	
	.PARAMETER Iteration 
	Specifies that CMP statistics are displayed a specified number of times as indicated by the num argument using an integer
  
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parStatCMP
    LASTEDIT: 08/07/2015
    KEYWORDS: Get-3parStatCMP
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVname ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Domian ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Delay  ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parStatCMP  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatCMP  since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatCMP   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statcmp -v "	
	
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "		
	}	
	if ($option)
	{
		$a = "ni"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "				
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [ni]  can be used only . "
		}
	}
	if($VVname)	
	{
		$cmd+=" -n $VVname "
	}		
	if ($Domian)
	{
		$cmd+= " -domain $Domian "	
	}
	if($Delay)	
	{
		$cmd+=" -d $Delay"
	}	
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Get-3parStatCMP command displays Cache Memory Page (CMP) statistics. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	
	if($range1 -le "3"){
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempfile -Value "VVid,VVname,Type,Curr_Accesses,Curr_Hits,Curr_Hit%,Total_Accesses,Total_Hits,Total_Hit%,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				if ($s -match "Current"){	
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "---") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
			}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parStatCMP
# End

####################################################################################################################
## FUNCTION Get-3parHistVLUN
####################################################################################################################

Function Get-3parHistVLUN
{
<#
  .SYNOPSIS
	The Get-3parHistVLUN command displays Virtual Volume Logical Unit Number (VLUN) service time histograms.
	
  .DESCRIPTION
    The Get-3parHistVLUN command displays Virtual Volume Logical Unit Number (VLUN) service time histograms.
        
  .EXAMPLE
    Get-3parHistVLUN -iteration 1
	This example displays two iterations of a histogram of service times for all VLUNs.	
		
	.EXAMPLE	
	Get-3parHistVLUN -iteration 1 -nodes 1
	This example displays two iterations of a histogram only exports from the specified nodes.	
	
	.EXAMPLE	
	Get-3parHistVLUN -iteration 1 -domain DomainName
	Shows only VLUNs whose Virtual Volumes (VVs) are in domains with names that match one or more of the specified domain names or patterns.
	
	.EXAMPLE	
	Get-3parHistVLUN -iteration 1 -Percentage
	Shows the access count in each bucket as a percentage.
	 
	
  .PARAMETER -domain
	Shows only VLUNs whose Virtual Volumes (VVs) are in domains with names that match one or more of the specified domain names or patterns. Multiple domain names or patterns can be
	repeated using a comma-separated list.
		
  .PARAMETER -host
   Shows only VLUNs exported to the specified host(s) or pattern(s). Multiple host names or patterns
	can be repeated using a comma-separated list.
	
  .PARAMETER -vvname
  Requests that only LDs mapped to VVs that match and of the specified names or patterns be displayed. Multiple volume names or patterns can be repeated using a comma-separated list.

  .PARAMETER Nodes <node_list>
        Specifies that the display is limited to specified nodes and physical
        disks connected to those nodes. The node list is specified as a series
        of integers separated by commas (e.g. 1,2,3). The list can also consist
        of a single integer. If the node list is not specified, all disks on all
        nodes are displayed.

    .PARAMETER Slots <slot_list>
        Specifies that the display is limited to specified PCI slots and
        physical disks connected to those PCI slots. The slot list is specified
        as a series of integers separated by commas (e.g. 1,2,3). The list can
        also consist of a single integer. If the slot list is not specified, all
        disks on all slots are displayed.

    .PARAMETER Ports <port_list>
        Specifies that the display is limited to specified ports and
        physical disks connected to those ports. The port list is specified
        as a series of integers separated by commas (e.g. 1,2,3). The list can
        also consist of a single integer. If the port list is not specified, all
        disks on all ports are displayed.
		
	.PARAMETER Metric both|time|size
        Selects which metric to display. Metrics can be one of the following:
            both - (Default)Display both I/O time and I/O size histograms
            time - Display only the I/O time histogram
            size - Display only the I/O size histogram

	.PARAMETER Percentage
        Shows the access count in each bucket as a percentage. If this option is
        not specified, the histogram shows the access counts.

    .PARAMETER Previous | Beginning
        Histogram displays data either from a previous sample(-prev) or from
        when the system was last started(-begin). If no option is specified, the
        histogram shows data from the beginning of the command's execution.
  .PARAMETER -lun      
  Specifies that VLUNs with LUNs matching the specified LUN(s) or pattern(s) are displayed. Multiple LUNs or patterns can be repeated using a comma-separated list.
  
 .PARAMETER -iteration
  Specifies that the statistics are to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parHistVLUN
    LASTEDIT: 07/27/2015
    KEYWORDS: Get-3parHistVLUN
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$iteration,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$host,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$vvname,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$lun,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Nodes,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Slots,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$Ports,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,
		
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Beginning,
		
		[Parameter(Position=11, Mandatory=$false)]
		[System.String]
		$Metric,			
		
		[Parameter(Position=12, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)		
	
	Write-DebugLog "Start: In Get-3parHistVLUN - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistVLUN since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistVLUN since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$Cmd = "histvlun "
	if ($iteration)
	{ 
		$Cmd += " -iter $iteration"
	}	
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error : -Iteration is Mandate. "
	}
	if ($domain)
	{ 
		$Cmd += " -domain $domain"
	}	
	if($host)
	{
		$objType = "host"
		$objMsg  = "hosts"		
		## Check Host Name 
		if ( -not (test-3PARObject -objectType $objType -objectName $host -objectMsg $objMsg))
		{
			write-debuglog "host $host does not exist. Nothing to List" "INFO:" 
			return "FAILURE : No host $host found"
		}		
		$Cmd += " -host $host "		
	}
	if ($vvname)
	{ 
		$GetvVolumeCmd="showvv"
		$Res = Invoke-3parCLICmd -Connection $SANConnection -cmds  $GetvVolumeCmd
		if ($Res -match $vvname)
			{
				$Cmd += " -v $vvname"
			}
			else
			{ 
				write-debuglog "vvname $vvname does not exist. Nothing to List" "INFO:" 
				return "FAILURE : No vvname $vvname found"			
			}
	}	
	if ($lun)
	{ 
		$Cmd += " -l $lun"			
	}
	if ($Nodes)
	{
		$Cmd += " -nodes $Nodes"
	}
	if ($Slots)
	{
		$Cmd += " -slots $Slots"
	}
	if ($Ports)
	{
		$Cmd += " -ports $Ports"
	}	
	if($Metric)
	{
		$Met = $Metric
		$c = "both","time","size"
		$Metric = $metric.toLower()
		if($c -eq $Met)
		{
			$Cmd += " -metric $Metric "
		}
		else
		{
			return "FAILURE: -Metric $Metric is Invalid. Use only [ both | time | size ]."
		}
	}
	if ($Previous)
	{
		$Cmd += " -prev "
	}
	if ($Beginning)
	{
		$Cmd += " -begin "
	}
	if ($Percentage)
	{
		$Cmd += " -pct "
	}		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
	write-debuglog " histograms The Get-3parHistVLUN command displays Virtual Volume Logical Unit Number (VLUN)  " "INFO:" 
	$range1 = $Result.Count
	#write-host "count = $range1"
	if($range1 -le "5" )
	{
		return "No Data Available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 
		Add-Content -Path $tempfile -Value 		'Lun,VVname,Host,Port,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		
		foreach ($s in  $Result[0..$LastItem] )
		{			
			if ($s -match "millisec"){
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]

				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
				continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "20")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		return $Result
	}
} # End Get-3parHistVLUN
####################################################################################################################
## FUNCTION Get-3parHistVV
####################################################################################################################
Function Get-3parHistVV
{

<#
  .SYNOPSIS
	The Get-3parHistVV command displays Virtual Volume (VV) service time histograms in a timed loop.
	
  .DESCRIPTION
   The Get-3parHistVV command displays Virtual Volume (VV) service time histograms in a timed loop.
	      
  .EXAMPLE
    Get-3parHistVV -iteration 1
	This Example displays Virtual Volume (VV) service time histograms service iteration number of times.
	
	 
    .EXAMPLE
	Get-3parHistVV  -iteration 1 -domain domain.com
	This Example Shows only the VVs that are in domains with names that match the specified domain name(s)
	
	.EXAMPLE	
	Get-3parHistVV  -iteration 1 –Metric both
	This Example Selects which Metric to display.
	
		
	.EXAMPLE	
	Get-3parHistVV –Metric both -VVname demoVV1 -iteration 1
	This Example Selects which Metric to display. associated with Virtual Volume name.
 
	
  .PARAMETER domain
	Shows only the VVs that are in domains with names that match the specified domain name(s) .
		
  .PARAMETER Metric
  Selects which Metric to display. Metrics can be one of the following:
	1)both - (Default) Displays both I/O time and I/O size histograms.
	2)time - Displays only the I/O time histogram.
	3)size - Displays only the I/O size histogram.
	
	.PARAMETER Percentage
        Shows the access count in each bucket as a percentage. If this option is
        not specified, the histogram shows the access counts.

    .PARAMETER Previous | Beginning
        Histogram displays data either from a previous sample(-prev) or from
        when the system was last started(-begin). If no option is specified, the
        histogram shows data from the beginning of the command's execution.
	  
  .PARAMETER VVName

		Virtual Volume name
	  
 .PARAMETER Iteration
  Specifies that the statistics are to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:Get-3parHistVV
    LASTEDIT: 07/27/2015
    KEYWORDS: Get-3parHistVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$iteration,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Metric,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VVname,		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Percentage,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[Switch]
		$Previous,		
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parHistVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$Cmd = "histvv "
	if ($iteration)
	{ 
		$Cmd += " -iter $iteration "	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}
	if ($domain)
	{ 
		$Cmd += " -domain $domain "		
	}
	if($metric)
	{
		$opt="both","time","size"
		$metric = $metric.toLower()
		if ($opt -eq $metric)
		{
			$Cmd += " -metric $metric"					
		}
		else 
		{
			Write-DebugLog "Stop: Exiting Get-3parHistVV since SAN connection object values are null/empty" $Debug
			return " metrics $metric not found only [ both | time | size ] can be passed one at a time "
		}
	}
	if ($Previous)
	{
		$Cmd += " -prev "
	}	
	if ($Percentage)
	{
		$Cmd += " -pct "
	}
	if($VVname)
	{ 
		$vv=$VVname
		$Cmd1 ="showvv"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd1
		if($Result1 -match $vv)			
		{
			$cmd += " $vv "
		}
		else
		{
			Write-DebugLog " Error : No VVname Found. "
			Return "Error: -VVname $VVname is not available `n Try Using Get-3parVV to list all the VV's Available  "
		}
	}		
			
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
	write-debuglog " Get-3parHistVV command displays Virtual Volume Logical Unit Number (VLUN)  " "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -le "5"){
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		if("time" -eq $Metric.trim().tolower()){
		#write-host " in time"
			Add-Content -Path $tempfile -Value 'VVname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),time,date'
		}
		elseif("size" -eq $Metric.trim().tolower()){
			#write-host " in size"
			Add-Content -Path $tempfile -Value 'VVname,4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		else{
			Add-Content -Path $tempfile -Value 		'VVname,0.50(millisec),1(millisec),2(millisec),4(millisec),8(millisec),16(millisec),32(millisec),64(millisec),128(millisec),256(millisec),4k(bytes),8k(bytes),16k(bytes),32k(bytes),64k(bytes),128k(bytes),256k(bytes),512k(bytes),1m(bytes),time,date'
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "millisec"){
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]

				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
				continue
			}			
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line			
			$s +=",$global:time1,$global:date1"	
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parHistVV

####################################################################################################################
## FUNCTION Get-3parStatCPU
####################################################################################################################

Function Get-3parStatCPU
{
<#
  .SYNOPSIS
   The Get-3parStatCPU command displays CPU statistics for all nodes.
   
  .DESCRIPTION
   The Get-3parStatCPU command displays CPU statistics for all nodes.

    .EXAMPLE
	Get-3parStatCPU -iteration 1
	
	This Example Displays CPU statistics for all nodes.
	
	.EXAMPLE  
	Get-3parStatCPU -delay 2  -total -iteration 1
	
	This Example Show only the totals for all the CPUs on each node.
	
	  		
  .PARAMETER delay    
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through 2147483
	
	.PARAMETER total 
	Show only the totals for all the CPUs on each node.
		
	.PARAMETER Iteration 
	Specifies that CMP statistics are displayed a specified number of times as indicated by the num argument using an integer
  
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parStatCPU
    LASTEDIT: 08/07/2015
    KEYWORDS: Get-3parStatCPU
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$delay,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$total,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parStatCPU  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatCPU  since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatCPU   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd= "statcpu "
	
    if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Exiting  Get-3parStatCPU  Iteration in unavailable "
		Return "FAILURE : -Iteration  is Mandatory for Get-3parStatCPU command to execute. "
	}		
	if($delay)	
	{
		$cmd+=" -d $delay "
	}
	if ($total  )
	{
		$cmd+= " -t "	
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing  Get-3parStatCPU command displays Cache Memory Page (CMP) statistics. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5"){
		return "No data available"
	}		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3
		Add-Content -Path $tempfile -Value "node,cpu,user,sys,idle,intr/s,ctxt/s,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")
			$s= [regex]::Replace($s,"---","")
			$s= [regex]::Replace($s,"-","")  
			$a=$s.split(",")
			$c=$a.length
			$b=$a.length
			if ( 2 -eq $b )
			{
			$a=$s.split(",")
			$global:time1 = $a[0]
			$global:date1 = $a[1]
			}
			if (([string]::IsNullOrEmpty($s)) -or ($s -match "node"))
			{
			continue
			}
			if($c -eq "6"){
			$s +=",,$global:time1,$global:date1"
			}
			else{
			$s +=",$global:time1,$global:date1"
			}
			Add-Content -Path $tempfile -Value $s			
 			}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parStatCPU
# End
####################################################################################################################
## FUNCTION Get-3parStatChunklet
####################################################################################################################

Function Get-3parStatChunklet
{
<#
  .SYNOPSIS
   The Get-3parStatChunklet command displays chunklet statistics in a timed loop.
   
  .DESCRIPTION
   The Get-3parStatChunklet command displays chunklet statistics in a timed loop.
  
	
	.EXAMPLE
	Get-3parStatChunklet -Iterration 1
	This example displays chunklet statistics in a timed loop.
	
	.EXAMPLE
   Get-3parStatChunklet -option rw -Iteration 1
   This example Specifies that reads and writes are displayed separately.while displays chunklet statistics in a timed loop.
   
   	
	.EXAMPLE  
	Get-3parStatChunklet -LDname demo1 -CHnum 5 -Iterration 1 
	This example Specifies particular chunklet number & logical disk.
	
	   		
  .PARAMETER option  
	rw		-	Specifies that reads and writes are displayed separately. If this option is not used, then the total
				of reads plus writes is displayed.
				
	idlep	-	Specifies the percent of idle columns in the output.
	
	begin	-	Specifies that I/O averages are computed from the system start time. If not specified, the average
				is computed since the first iteration of the command.
				
	ni		-	Specifies that statistics for only non-idle devices are displayed
	
	.PARAMETER Delay 
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.
	
	.PARAMETER LDname 
	Specifies that statistics are restricted to chunklets from a particular logical disk.
	
	.PARAMETER CHnum  
	Specifies that statistics are restricted to a particular chunklet number.
	
	.PARAMETER Iteration 
	Specifies that CMP statistics are displayed a specified number of times as indicated by the num argument using an integer
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parStatChunklet
    LASTEDIT: 08/06/2015
    KEYWORDS: Get-3parStatChunklet
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iteration ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Delay,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$LDname ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$CHnum ,		
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parStatChunklet  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatChunklet   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatChunklet   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statch"
	if($Iteration )
	{	
		$cmd+=" -iter $Iteration "	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "		
	}
	if ($option)
	{
		$a = "rw","idlep","begin","ni"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
		}
		else
		{ 
			Return "FAILURE : -option $option cannot be used only [  rw | idlep | begin | ni  ] can be used . "
			Write-DebugLog "Stop: Exiting  Get-3parStatChunklet   since -option $option in incorrect "
		}
	}
	if($Delay)	
	{
		$cmd+=" -d $Delay"
	}
	if($LDname)	
	{
		$ld="showld"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $ld
		if($Result1 -match $LDname )
		{
			$cmd+=" -ld $LDname "
		}
		else 
		{
			Write-DebugLog "Stop: Exiting  Get-3parStatChunklet   since -LDname $LDname in unavailable "
			Return "FAILURE : -LDname $LDname is not available . "
		}
	}
	if($CHnum)
	{
		$cmd+=" -ch $CHnum "
	}
	
	#write-host "$cmd"		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Get-3parStatChunklet command displays chunklet statistics in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.Count
	if($range1 -le "5" )
	{
		return "No Data Available"
	}
	if( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		$id="idlep"
		if($id -eq $l){
		Add-Content -Path $tempfile -Value "Logical_Disk_I.D,LD_Name,Ld_Ch,Pd_id,Pd_Ch,R/W,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date" 
		}
		else {
		Add-Content -Path $tempfile -Value "Logical_Disk_I.D,LD_Name,Ld_Ch,Pd_id,Pd_Ch,R/W,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$global:time1 = $s.substring(0,8)
				$global:date1 = $s.substring(9,19)
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Qlen"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			if (($aa -eq "13") -and ("idlep" -eq $option))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		return $Result
	}	
} # End Get-3parStatChunklet
# End
####################################################################################################################
## FUNCTION Get-3parStatLD
####################################################################################################################

Function Get-3parStatLD
{
<#
  .SYNOPSIS
   The Get-3parStatLD command displays read/write (I/O) statistics about Logical Disks (LDs) in a timed loop.
   
  .DESCRIPTION
   The Get-3parStatLD command displays read/write (I/O) statistics about Logical Disks (LDs) in a timed loop.
   
	
	.EXAMPLE
	Get-3parStatLD -Iteration 1
	This example displays read/write (I/O) statistics about Logical Disks (LDs).
	
	.EXAMPLE
   Get-3parStatLD -option rw -Iteration 1
   This example displays statistics about Logical Disks (LDs).with Specification read/write
   
   .EXAMPLE  
	Get-3parStatLD -option begin -delay 2 -Iteration 1
	This example displays statistics about Logical Disks (LDs).with Specification begin & delay in execution of 2 sec.	
	
	.EXAMPLE  
	Get-3parStatLD -option begin -VVname demo1 -delay 2 -Iteration 1
	This example displays statistics about Logical Disks (LDs) Show only LDs that are mapped to Virtual Volumes (VVs)
	
	
	.EXAMPLE  
	Get-3parStatLD -option begin -LDname demoLD1 -delay 2 -Iteration 1
	This example displays statistics about Logical Disks (LDs).With Only statistics are displayed for the specified LD
	   		
  .PARAMETER option  
	rw		Specifies that reads and writes are displayed separately. If this option is not used, then the total
			of reads plus writes is displayed.
			
	begin	Specifies that I/O averages are computed from the system start time. If not specified, the average
			is computed since the first iteration of the command.
			
	idlep	Specifies the percent of idle columns in the output.
	
	.PARAMETER VVname  
	Show only LDs that are mapped to Virtual Volumes (VVs) with names matching any of names or patterns specified
	
	.PARAMETER LDname  
	Only statistics are displayed for the specified LD or pattern
	
	.PARAMETER domain
	Shows only LDs that are in domains with names matching any of the names or specified patterns.
	
	.PARAMETER Delay 
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.

	.PARAMETER Iteration 
	Specifies that I/O statistics are displayed a specified number of times as indicated by the number
	argument using an integer from 1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parStatLD
    LASTEDIT: 08/07/2015
    KEYWORDS: Get-3parStatLD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVname ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$LDname,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Delay,
				
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Iteration,
				
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parStatLD  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatLD   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatLD   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statld"	
	
	if($Iteration )
	{	
		$cmd+=" -iter $Iteration "	
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}
	if ($option)
	{
		$a = "rw","begin","idlep","ni"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "			
		}
		else
		{ 
			Return "FAILURE : -option $option cannot be used only [  rw | begin | idlep ] can be used . "
			Write-DebugLog "Stop: Exiting  Get-3parStatChunklet   since -option $option in incorrect "
		}
	}
	if($VVname)	
	{
		$ld="showvv"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $ld
		if($Result1 -match $VVname )
		{
			$cmd+=" -vv $VVname "
		}
		else 
		{
			Write-DebugLog "Stop: Exiting  Get-3parStatLD since -VVname $VVname in unavailable "
			Return "FAILURE : -VVname $VVname is not available .`n Try Using Get-3parVV to get all available VV  "
		}
	}
	if($LDname)	
	{
		if($cmd -match "-vv")
		{
			return "Stop: Executing -VVname $VVname and  -LDname $LDname cannot be done in a single Execution "
		}
		$ld="showld"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $ld		
		if($Result1 -match $LDname )
		{
			$cmd+=" $LDname "
		}
		else 
		{
			Write-DebugLog "Stop: Exiting  Get-3parStatLD since -LDname $LDname in unavailable "
			Return "FAILURE : -LDname $LDname is not available . "
		}
	}	
	if($domain)	
	{
		$cmd+=" -domain $domain "
	}	
	if($Delay)	
	{
		$cmd+=" -d $Delay "
	}		
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Get-3parStatLD command displays isplays read/write (I/O) statistics about Logical Disks (LDs) in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -le "5"){
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 1
		$id="idlep"
		if($id -eq $l){
		Add-Content -Path $tempfile -Value "Ldname,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		else {
		Add-Content -Path $tempfile -Value "Ldname,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"	
		}
		foreach ($s in  $Result[1..$LastItem] )
		{
		if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Ldname"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			if (($aa -eq "13") -and ("idlep" -eq $option))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		# 1)I/O	2)KB	3)Svt	4)IOSz
			#$s= $s.Trim() -replace 'Ldname,Cur,Avg,Max,Cur,Avg,Max,Cur,Avg,Cur,Avg,Qlen','Ldname,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen' 	
			#Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parStatLD

####################################################################################################################
## FUNCTION Get-3parStatLink
####################################################################################################################

Function Get-3parStatLink
{
<#
  .SYNOPSIS
  The Get-3parStatLink command displays statistics for link utilization for all nodes in a timed loop.
  
  .DESCRIPTION
  The Get-3parStatLink command displays statistics for link utilization for all nodes in a timed loop.
   
	
	.EXAMPLE
	Get-3parStatLink -Iteration 1
	This Example displays statistics for link utilization for all nodes in a timed loop.
		
	.EXAMPLE
	Get-3parStatLink -Delay 3 -Iteration 1 
   This Example displays statistics for link utilization for all nodes in a timed loop, with a delay of 3 sec.
     		
  
	.PARAMETER Delay 
	Specifies the interval, in seconds, that statistics are sampled using an integer from 1 through
	2147483.

	.PARAMETER Iteration 
	Specifies that I/O statistics are displayed a specified number of times as indicated by the number
	argument using an integer from 1 through 2147483647.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Get-3parStatLink
    LASTEDIT: 08/10/2015
    KEYWORDS: Get-3parStatLink
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
				
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Delay,
				
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Iteration,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-3parStatLink  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatLink   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatLink   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statlink"
	if($Iteration )
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}	
	if ($option)
	{
		$a = "d","detail"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
			if($option -eq "d")	
			{
				$cmd+=" $Delay "
			}	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [detail]  can be used only . "
		}
	}	
	
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Get-3parStatLink displays statistics for link utilization for all nodes in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "3"){
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempfile -Value "Node,Q,ToNode,XCB_Cur,XCB_Avg,XCB_Max,KB_Cur,KB_Avg,KB_Max,XCBSz_KB_Cur,XCBSz_KB_Avg,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "Local DMA 0")
			{
				$s= [regex]::Replace($s,"Local DMA 0","Local_DMA_0")			
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")
			if ($s -match "XCB_sent_per_second")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if ($s -match "Local DMA 0")
			{
			 $s= [regex]::Replace($s,"Local DMA 0","Local_DMA_0")			
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "ToNode"))
			{
			continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parStatLink
####################################################################################################################
## FUNCTION Get-3parstatPD
####################################################################################################################

Function Get-3parstatPD
{
<#
  .SYNOPSIS
   The Get-3parstatPD command displays the read/write (I/O) statistics for physical disks in a timed loop.
   
 .DESCRIPTION
    The Get-3parstatPD command displays the read/write (I/O) statistics for physical disks in a timed loop.
   
	
	.EXAMPLE
	Get-3parstatPD -option rw –Iteration 1
	This example displays one iteration of I/O statistics for all PDs.
   
   .EXAMPLE  
	Get-3parstatPD -option idlep –nodes 2 –Iteration 1
   This example displays one iteration of I/O statistics for all PDs with the specification idlep preference of node 2.
   
	.EXAMPLE  
	Get-3parstatPD -option ni -wwn 1122112211221122 –nodes 2 –Iteration 1
	This Example Specifies that statistics for a particular Physical Disk (PD) identified by World Wide Names (WWNs) and nodes


		
  .PARAMETER option  
	devinfo	:	Indicates the device disk type and speed.
	
	rw		: 	Specifies that reads and writes are displayed separately. If this option is not used, then the total
				of reads plus writes is displayed.
	begin	:	Specifies that I/O averages are computed from the system start time. If not specified, the average
				is computed since the first iteration of the command.
	idlep	:	Specifies the percent of idle columns in the output.
	
	ni		:	Specifies that statistics for only non-idle devices are displayed. This option is shorthand for the
				option
				
	
  .PARAMETER wwn 
	Specifies that statistics for a particular Physical Disk (PD) identified by World Wide Names (WWNs) are displayed.
	
  .PARAMETER nodes  
	Specifies that the display is limited to specified nodes and PDs connected to those nodes
		
  .PARAMETER ports   
	Specifies that the display is limited to specified ports and PDs connected to those ports

 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parstatPD
    LASTEDIT: 08/05/2015
    KEYWORDS: Get-3parstatPD
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$wwn ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$nodes,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$slots,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$ports ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parstatPD   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parstatPD   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parstatPD   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "statpd "	
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}
	if ($option)
	{
		$s = "devinfo","rw","begin","idlep","ni"
		$demo = $option
		if($s -eq $demo)
		{
			$cmd+=" -$option "
		}
		else
		{
			return " FAILURE : -option $option is not a Valid Option  please use[ devinfo | rw | begin	| idlep | ni] one of the following Only,  "
		}
	}
	if ($wwn)
	{
		$cmd+=" -w $wwn "
	}	
	if ($nodes)
	{
		$cmd+=" -nodes $nodes "
	}	
	if ($slots)
	{
		$cmd+=" -slots $slots "
	}	
	if ($ports )
	{
		$cmd+=" -ports $ports "
	}			
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Get-3parstatPD scommand displays the read/write (I/O) statistics for physical disks in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 3
		if("devinfo" -eq $option){
		Add-Content -Path $tempfile -Value "ID,Port,Type,K_RPM,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		else{
		Add-Content -Path $tempfile -Value "ID,Port,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]				
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Port"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "13")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
		# Replace one or more spaces with comma to build CSV line
			# 1) I/O		2)KB		3)Svt		4)IOSz		5)Idle
			#$s= $s.Trim() -replace 'ID,Port,Cur,Avg,Max,Cur,Avg,Max,Cur,Avg,Cur,Avg,Qlen,Cur,Avg','ID,Port,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg' 	
			#Add-Content -Path $tempfile -Value $s
		
		#Import-Csv $tempFile
		#del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parstatPD
####################################################################################################################
## FUNCTION Get-3parStatPort
####################################################################################################################
Function Get-3parStatPort
{
<#
  .SYNOPSIS
   The Get-3parStatPort command displays read/write (I/O) statistics for ports.
   
 .DESCRIPTION
       The Get-3parStatPort command displays read/write (I/O) statistics for ports.
	
	.EXAMPLE
	Get-3parStatPort -Iteration 1
	This example displays one iteration of I/O statistics for all ports.
   
   .EXAMPLE  
	Get-3parStatPort -option both -Iteration 1
	This example displays one iteration of I/O statistics for all ports,Show data transfers only. 
   
	.EXAMPLE  
	Get-3parStatPort -option host -nodes 2 -Iteration 1
	This example displays I/O statistics for all ports associated with node 2.
			
  .PARAMETER option  
	 both	:	Show data transfers only.
	 
	 ctl	:	Show control transfers only.
	 
	 data	:	Show both data and control transfers only.
	 
	 rcfc	:	includes only statistics for Remote Copy over Fibre Channel ports related to cached READ
				requests
	 rcip	:	Includes only statistics for Ethernet configured Remote Copy ports.
	 
	 rw		:	Specifies that the display includes separate read and write data.
	 
	 begin	:	Specifies that I/O averages are computed from the system start time
	 
	 idlep	:	Specifies the percent of idle columns in the output.
	 
	 host	:	Displays only host ports (target ports).
	 
	 disk 	:	Displays only disk ports (initiator ports).
	 
	 rcfc	:	Displays only Fibre Channel remote-copy configured ports.
	 
	 ni		:	Specifies that statistics for only non-idle devices are displayed.
				
	
    .PARAMETER nodes  
	Specifies that the display is limited to specified nodes and PDs connected to those nodes
		
  .PARAMETER ports   
	Specifies that the display is limited to specified ports and PDs connected to those ports

 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parStatPort
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parStatPort
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option ,
		
				
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$nodes,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$slots,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$ports ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parStatPort   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatPort   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatPort   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statport "
	if($Iteration)
	{	
		$cmd+=" -iter $Iteration "	
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}	
	if ($option)
	{
		$s = "both","ctl","data","rcfc","rcip","rw","fs","begin","idlep","host","disk","peer","ni"
		$demo = $option
		if($s -eq $demo)
		{
			$cmd+=" -$option "
		}
		else
		{
			return " FAILURE : -option $option is not a Valid Option `n use [  both | ctl | data | rcfc | rcip | rw | fs | begin | idlep | host | disk| rcfc | peer | ni ]one of the following Only,  "
		}
	}		
	if ($nodes)
	{
		$cmd+=" -nodes $nodes "
	}
	if ($slots)
	{
		$cmd+=" -slots $slots "
	}
	if ($ports )
	{
		$cmd+=" -ports $ports "
	}				
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Get-3parStatPort scommand displays the read/write (I/O) statistics for physical disks in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "5")
	{
		return "No data available"
	}
	if(("both" -eq $option) -And ($range -eq "6"))
	{
	return "No data available"
	}
		
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -3
		if("rcip" -eq $option)
		{
		Add-Content -Path $tempfile -Value "Port,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Errs,Drops,Time,Date"
		}
		elseif ("idlep" -eq $option)
		{
		Add-Content -Path $tempfile -Value "Port,D/C,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max, Svt_Cur, Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Idle_Cur,Idle_Avg,Time,Date"
		}
		else
		{
		Add-Content -Path $tempfile -Value "Port,D/C,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max, Svt_Cur, Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"
		}	
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Port"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if (($aa -eq "12") -or ($aa -eq "8") -or ($aa -eq "8"))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}	
	else
	{
		return $Result
	}
} # End Get-3parStatPort
#EndRegion
####################################################################################################################
## FUNCTION Get-3parStatRCVV
####################################################################################################################

Function Get-3parStatRCVV
{
<#
  .SYNOPSIS
   The Get-3parStatRCVV command displays statistics for remote-copy volumes in a timed loop.
   
 .DESCRIPTION
    The Get-3parStatRCVV command displays statistics for remote-copy volumes in a timed loop.
  
	.EXAMPLE
	Get-3parStatRCVV -Iteration 1
   This Example displays statistics for remote-copy volumes in a timed loop.
   
   
   .EXAMPLE  
	Get-3parStatRCVV -option periodic -Iteration 1
	This Example displays statistics for remote-copy volumes in a timed loop and show only volumes that are being copied in asynchronous periodic mode	
   
	.EXAMPLE  
	Get-3parStatRCVV -target demotarget1  -Iteration 1
	This Example displays statistics for remote-copy volumes in a timed loop and Show only volumes whose group is copied to the specified target name.

			
  .PARAMETER option  
	sync	:	Show only volumes that are being copied in synchronous mode.
	
	periodic	:	Show only volumes that are being copied in asynchronous periodic mode	
	
	primary		:	Show only volumes that are in the primary role.
	
	secondary	:	Show only volumes that are in the secondary role.
	
	targetsum	:	Specifies that the sums for all volumes of a target are displayed.
	
	portsum		:	Specifies that the sums for all volumes on a port are displayed.
	
	groupsum	:	Specifies that the sums for all volumes of a group are displayed.
	
	vvsum		:	Specifies that the sums for all targets and links of a volume are displayed.
	
	domainsum	:	Specifies that the sums for all volumes of a domain are displayed.
	
	ni			:	Specifies that statistics for only non-idle devices are displayed.
	
    .PARAMETER target   
	Show only volumes whose group is copied to the specified target name.
	
  .PARAMETER port    
	Show only volumes that are copied over the specified port or pattern.
	
	.PARAMETER group 
	Show only volumes whose group matches the specified group name or pattern.
	
	.PARAMETER VVname
	
	Displays statistics only for the specified virtual volume or volume name pattern.	
	
	
 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parStatRCVV
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parStatRCVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option ,
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$target ,
						
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$port,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$group ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVname  ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parStatRCVV   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatRCVV   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatRCVV   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statrcvv "	
	if ($option)
	{
		$s = "sync","periodic","primary","secondary","targetsum","portsum","groupsum","vvsum","domainsum","ni"
		$demo = $option
		if($s -eq $demo)
		{
			$cmd+=" -$option "
		}
		else
		{
			return " FAILURE : -option $option is not a Valid Option `n use [sync | periodic | primary | secondary | targetsum |  portsum | groupsum | vvsum | domainsum | ni]one of the following Only,  "
		}
	}
	if ($target)
	{
		$cmd+=" -t $target"
	}	
	if ($port)
	{
		$cmd+=" -port  $port"
	}	
	if ($VVname)
	{
		$s= get-3parvv -vvName  $VVname
		if ($s -match $VVname )
		{
			$cmd+=" $VVname"
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Get-3parStatRCVV  VVname in unavailable "
			Return "FAILURE : -VVname $VVname  is Unavailable to execute. "
		}		
	}
	if ($group)
	{
		$cmd+=" -g $group"
	}			
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "
	}
	else
	{
		Write-DebugLog "Stop: Exiting  Get-3parStatRCVV  Iteration in unavailable "
		Return "FAILURE : -Iteration  is Mandatory for Get-3parStatRCVV command to execute. "
	}	
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Get-3parStatRCVV command displays statistics for remote-copy volumes in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	if($range1 -eq "5")
	{
		return "No data available"
	}
	if( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 4
		$id="targetsum"
		if($id -eq $demo){
		Add-Content -Path $tempfile -Value "Target,Mode,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"		
		}
		elseif ("portsum" -eq $demo){
		Add-Content -Path $tempfile -Value "Link,Target,Type,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif ("groupsum" -eq $demo){
		Add-Content -Path $tempfile -Value "Group,Target,Mode,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif ("vvsum" -eq $demo){
		Add-Content -Path $tempfile -Value "VVname,RCGroup,Target,Mode,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		elseif ("-domainsum" -eq $demo){
		Add-Content -Path $tempfile -Value "Domain,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		else {		
		Add-Content -Path $tempfile -Value "VVname,RCGroup,Target,Mode,Port,Type,I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg,Time,Date"
		}
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			#$s= [regex]::Replace($s,"-+","-")
			$s= [regex]::Replace($s," +",",")			# Replace one or more spaces with comma to build CSV line
			if ($s -match "I/O")
			{
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "-------") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "Avg"))
			{
			continue
			}
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}			
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s		
			#$s= $s.Trim() -replace 'Cur,Avg,Max,Cur,Avg,Max,Cur,Avg,Cur,Avg,Cur,Avg','I/O_Cur,I/O_Avg,I/O_Max,KBytes_Cur,KBytes_Avg,KBytes_Max,Svt_Cur,Svt_Avg,Rmt_Cur,Rmt_Avg,IOSz_Cur,IOSz_Avg' 	
			#Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
	
} # End Get-3parStatRCVV
####################################################################################################################
## FUNCTION Get-3parStatVlun
####################################################################################################################
Function Get-3parStatVlun
{
<#
  .SYNOPSIS
   The Get-3parStatVlun command displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments.
   
 .DESCRIPTION
   The Get-3parStatVlun command displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments.
   
	.EXAMPLE
	Get-3parStatVlun -Iteration 1
	This example displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments.
   
   .EXAMPLE  
	Get-3parStatVlun -option vvsum -Iteration 1
	This example displays statistics for Virtual Volumes (VVs) and Specifies that sums for VLUNs of the same VV are displayed.
   
	.EXAMPLE  
	Get-3parStatVlun -VVname demovv1 -Iteration 1
	This example displays statistics for Virtual Volumes (VVs) and only Logical Disks (LDs) mapped to VVs that match any of the specified names to be displayed.
	
				
  .PARAMETER option  
  
	lw  		:	Lists the host’s World Wide Name (WWN) or iSCSI names.
	
	domainsum 	:	Specifies that sums for VLUNs are grouped by domain in the display.
	
	vvsum 		:	Specifies that sums for VLUNs of the same VV are displayed.
	
	hostsum  	:	Specifies that sums for VLUNs are grouped by host in the display.
	
	rw 			:	Specifies reads and writes to be displayed separately.
	
	begin		:	Specifies that I/O averages are computed from the system start time.
	
	idlep  		:	Includes a percent idle columns in the output.
	
	ni			:	Specifies that statistics for only nonidle devices are displayed.
	
    .PARAMETER domian    
	Shows only Virtual Volume Logical Unit Number (VLUNs) whose VVs are in domains with names that match one or more of the specified domain names or patterns.
	
  .PARAMETER VVname     
	Requests that only Logical Disks (LDs) mapped to VVs that match any of the specified names to be displayed.
	
	.PARAMETER LUN  
	Specifies that VLUNs with LUNs matching the specified LUN(s) or pattern(s) are displayed.
	
	.PARAMETER nodes
	Specifies that the display is limited to specified nodes and Physical Disks (PDs) connected to those
	nodes.
	
 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parStatVlun
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parStatVlun
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option ,
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$domian  ,
						
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$VVname ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$LUN ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$nodes,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parStatVlun  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatVlun   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatVlun   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statvlun "
	if($Iteration)
	{	
		$cmd+=" -iter $Iteration "	
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}	
	if ($option)
	{
		$s = "lw","domainsum","vvsum","hostsum","rw","begin","idlep","ni"
		$demo = $option
		if($s -eq $demo)
		{
			$cmd+=" -$option "
		}
		else
		{
			return " FAILURE : -option $option is not a Valid Option `n use [ lw | domainsum | vvsum | hostsum | rw | begin | idlep | ni ]one of the following Only,  "
		}
	}	
	if ($domian)
	{
		$cmd+=" -domain $domian"
	}	
	if ($VVname)
	{
		$s= get-3parvv -vvName  $VVname
		if ($s -match $VVname )
		{
			$cmd+=" -v $VVname"
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Get-3parStatVlun  VVname in unavailable "
			Return "FAILURE : -VVname $VVname  is Unavailable to execute. "
		}		
	}
	if ($LUN)
	{
		$cmd+=" -l $LUN"
	}	
	if ($nodes)
	{
		$cmd+=" -nodes $nodes"
	}				
		
	#write-host " $cmd"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Get-3parStatVlun command command displays statistics for Virtual Volumes (VVs) and Logical Unit Number (LUN) host attachments. with the command --> $cmd" "INFO:"
	$range1 = $Result.count
	#write-host "count = $range1"
	if($range1 -eq "4")
	{
		return "No data available"
	}	
	if(($range1 -eq "6") -and ("ni" -eq $option))
	{
		return "No data available"
	}
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count - 4
		if($option -eq "lw")
			{	
				Add-Content -Path $tempfile -Value "Lun,VVname,Host,Port,Host_WWN/iSCSI_Name,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
			}
			elseif($option -eq "domainsum")
			{
				Add-Content -Path $tempfile -Value "Domain,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date" 
			}
			elseif($option -eq "vvsum")
			{
				Add-Content -Path $tempfile -Value "VVname,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
			}
			elseif($option -eq "rw")
			{
				Add-Content -Path $tempfile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
			}
			elseif($option -eq "begin")
			{
				Add-Content -Path $tempfile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
			}
			elseif($option -eq "idlep")
			{ #IOSz
				Add-Content -Path $tempfile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,IOSz_Cur,IOSz_Avg,Time,Date"
			}
			elseif($option -eq "ni")
			{
				Add-Content -Path $tempfile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
			}
			elseif($option -eq "hostsum")
			{
				Add-Content -Path $tempfile -Value "Hostname,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date"
			}
			else
			{
				Add-Content -Path $tempfile -Value "Lun,VVname,Host,Port,r/w,r/w_Cur,r/w_Avg,r/w_Max,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,Svt_Cur,Svt_Avg,Qlen,Time,Date" 
			}
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")	
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "cur"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			if (($aa -eq "13") -And ("idlep" -eq $option))
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	else
	{
		return $Result
	}
} # End Get-3parStatVlun

####################################################################################################################
## FUNCTION Get-3parStatVV
####################################################################################################################

Function Get-3parStatVV
{
<#
  .SYNOPSIS
   The Get-3parStatVV command displays statistics for Virtual Volumes (VVs) in a timed loop.
   
 .DESCRIPTION
	The Get-3parStatVV command displays statistics for Virtual Volumes (VVs) in a timed loop.
   
	.EXAMPLE
	Get-3parStatVV -Iteration 1
   This Example displays statistics for Virtual Volumes (VVs) in a timed loop.
   
   
   .EXAMPLE  
	Get-3parStatVV -option rw -Iteration 1
   This Example displays statistics for Virtual Volumes (VVs) with specification of read/write option.
   
   EXAMPLE  
	Get-3parStatVV -option d -Seconds 2 -Iteration 1
	Specifies the interval in seconds that statistics are sampled from using an integer from 1 through 2147483.
	
	.EXAMPLE  
	Get-3parStatVV -option rw -domain dil -VVname demovv1 -Iteration 1
	This Example displays statistics for Virtual Volumes (VVs) with Only statistics are displayed for the specified VVname.
			
			
  .PARAMETER option  
  
  rw :	Specifies reads and writes to be displayed separately.
 
  d  : <Seconds> Specifies the interval in seconds that statistics are sampled from using an integer from 1 through 2147483. If no count is specified, the
        command defaults to 2 seconds.
  ni : Specifies that statistics for only non-idle devices are displayed. This option is shorthand for the option -filt curs,t,iops,0.
	
    .PARAMETER domian    
	Shows only Virtual Volume Logical Unit Number (VLUNs) whose VVs are in domains with names that match one or more of the specified domain names or patterns.
	
 .PARAMETER  Iteration
	Specifies that the histogram is to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
	
	.PARAMETER  VVname
	Only statistics are displayed for the specified VV.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parStatVV
    LASTEDIT: 08/11/2015
    KEYWORDS: Get-3parStatVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Seconds  ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$domian  ,
					
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VVname ,	
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Iteration ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-3parStatVV  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatVV   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatVV   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "statvv "
	if($Iteration)
	{
		$cmd+=" -iter $Iteration "	
	}
	else	
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "
	}	
	if ($option)
	{
		$s = "rw","d","ni"
		$demo = $option
		if($s -match $demo)
		{
			$cmd+=" -$option "
			if ($option -eq "d")
			{
				$cmd+=" $Seconds "
			}
		}
		else
		{
			return " FAILURE : -option $option is not a Valid Option  please use [$s] one of the following Only,  "
		}
	}		
	if ($domian)
	{
		$cmd+=" -domain $domian"
	}			
	if ($VVname)
	{
		$cmd+="  $VVname"
	}	
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing The Get-3parStatVV command displays statistics for Virtual Volumes (VVs) in a timed loop. with the command --> $cmd" "INFO:" 
	$range1 = $Result.count
	if($range1 -eq "4")
	{
		return "No data available"
	}	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		Add-Content -Path $tempfile -Value "VVname,r/w,I/O_Cur,I/O_Avg,I/O_Max,KB_Cur,KB_Avg,KB_Max,Svt_Cur,Svt_Avg,IOSz_Cur,IOSz_Avg,Qlen,Time,Date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			if ($s -match "r/w")
			{
				$s= [regex]::Replace($s,"^ +","")
				$s= [regex]::Replace($s," +"," ")
				$s= [regex]::Replace($s," ",",")
				$a=$s.split(",")
				$global:time1 = $a[0]
				$global:date1 = $a[1]
				continue
			}
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "VVname"))
			{
			continue
			}
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +",",")# Replace one or more spaces with comma to build CSV line
			$aa=$s.split(",").length
			if ($aa -eq "11")
			{
				continue
			}
			$s +=",$global:time1,$global:date1"
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile	
		del $tempFile
	}
	else
	{
		return $Result
	}	
} # End Get-3parStatVV
####################################################################################################################
## FUNCTION New-3parRCopyTarget
####################################################################################################################
Function New-3parRCopyTarget
{
<#
  .SYNOPSIS
   The New-3parRCopyTarget command creates a remote-copy target definition.
   
 .DESCRIPTION
    The New-3parRCopyTarget command creates a remote-copy target definition.
   
	.EXAMPLE  
	New-3parRCopyTarget -TargetName demo1 -option ip -N_S_P_IP 1:2:3:10.1.1.1
	This Example creates a remote-copy target, with option N_S_P_IP Node ,Slot ,Port and IP address. as 1:2:3:10.1.1.1 for Target Name demo1
	
	.EXAMPLE
	New-3parRCopyTarget -TargetName demo1 -option ip -N_S_P_IP "1:2:3:10.1.1.1,1:2:3:10.20.30.40"
	This Example creates a remote-copy with multiple targets
	
	.EXAMPLE 
	 New-3parRCopyTarget -TargetName demo1 -option FC -Node_WWN 1122112211221122 -N_S_P_WWN 1:2:3:1122112211221122
	This Example creates a remote-copy target, with option N_S_P_WWN Node ,Slot ,Port and WWN as 1:2:3:1122112211221122 for Target Name demo1
		
	.EXAMPLE 
	 New-3parRCopyTarget -TargetName demo1 -option FC -Node_WWN 1122112211221122 -N_S_P_WWN "1:2:3:1122112211221122,1:2:3:2244224422442244"
	This Example creates a remote-copy of FC with multiple targets
		
	.PARAMETER TargetName
	The name of the target definition to be created, specified by using up to 23 characters.
	
	.PARAMETER option
	IP	:	remote copy over IP (RCIP).
	
	FC	:	remote copy over Fibre Channel (RCFC).
		
	.PARAMETER node_WWN
	The node's World Wide Name (WWN) on the target system (Fibre Channel target only).
	
	.PARAMETER N_S_P_IP
	Node number:Slot number:Port Number:IP Address of the Target to be created.
	
	.PARAMETER N_S_P_WWN
	Node number:Slot number:Port Number:World Wide Name (WWN) address on the target system.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parRCopyTarget
    LASTEDIT: 08/25/2015
    KEYWORDS: New-3parRCopyTarget
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Node_WWN,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$N_S_P_IP,
		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$N_S_P_WWN,
				
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In New-3parRCopyTarget   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parRCopyTarget   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parRCopyTarget   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "creatercopytarget"
	if ($TargetName)	
	{	
		$cmd+=" $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: -TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}				
	if ($option)
	{
		$Res="IP"
		$Res1="FC"
		if("IP" -eq $option)
		{
			$cmd+=" IP "
		}
		elseif("FC" -eq $option)
		{
			$cmd+=" FC "
		}		
		else
		{
			Write-DebugLog "Stop: Exiting New-3parRCopyTarget $option Not available,--> New-3parRCopyTarget "
			return "FAILURE :  -option $option  is Unavailable `n only [FC | IP ] can be used.  "
		}
	}
	else
	{
		Write-DebugLog "Stop: -option is Mandate" $Debug
		return "Error :  -option is Mandate. "			
	}
	$opt1="Yes"
	if ($Node_WWN)
	{
		if($option -match "IP")
		{
			return "Error : -Node_WWN $Node_WWN cannot be used, Along with -option $option.  "
		}
		$opt1="no"
		$cmd+=" $Node_WWN "		
	}
	if($N_S_P_IP)
	{
		if($option -match "FC")
		{
			return "Error : -N_S_P_IP $N_S_P_IP cannot be used, Along with -option $option.  "
		}
		$s = $N_S_P_IP
		$s= [regex]::Replace($s,","," ")	
		$cmd+="$s"
	}		
	if ($N_S_P_WWN)
	{
		if("Yes" -eq $opt1 )
		{
			return "Error : Command Cannot be Executed with out -Node_WWN Parameters "
		}
		if($option -match "IP")
		{
			return "Error : -N_S_P_WWN $N_S_P_WWN cannot be used, Along with -option $option.  "
		}	
		$s = $N_S_P_WWN
		$s= [regex]::Replace($s,","," ")	
		$cmd+="$s"
	}	
	elseif("FC" -match $option )
	{
		return "Error : Command Cannot be Executed with out -N_S_P_WWN Parameters "
	}

	if ($cmd -eq "creatercopytarget")
	{
		write-debuglog "Error: no parameters passed "
		return get-help New-3parRCopyTarget		
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The New-3parRCopyTarget command creates a remote-copy target definition. --> $cmd " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING New-3parRCopyTarget Command "
	}
	else
	{
		return  "FAILURE : While EXECUTING New-3parRCopyTarget $Result "
	} 	
} # End New-3parRCopyTarget
####################################################################################################################
## FUNCTION New-3parRCopyGroup
###################################################################################################################

Function New-3parRCopyGroup
{
<#
  .SYNOPSIS
   The New-3parRCopyGroup command creates a remote-copy volume group.
   
 .DESCRIPTION
    The New-3parRCopyGroup command creates a remote-copy volume group.
   
	
	.EXAMPLE	
	New-3parRCopyGroup -GroupName AS_TEST -TargetName CHIMERA03 -Mode sync

	.EXAMPLE
	New-3parRCopyGroup -GroupName AS_TEST1 -TargetName CHIMERA03 -Mode async

	.EXAMPLE
	New-3parRCopyGroup -GroupName AS_TEST2 -TargetName CHIMERA03 -Mode periodic

	.EXAMPLE
	New-3parRCopyGroup -domain DEMO -GroupName AS_TEST3 -TargetName CHIMERA03 -Mode periodic
     
		
	.PARAMETER domain
	Creates the remote-copy group in the specified domain.
	
	.PARAMETER Usr_Cpg_Name
	Specify the local user CPG and target user CPG that will be used for volumes that are auto-created.
	
	.PARAMETER Target_TargetCPG
	Specify the local user CPG and target user CPG that will be used for volumes that are auto-created.
	
	.PARAMETER Snp_Cpg_Name
	 Specify the local snap CPG and target snap CPG that will be used for volumes that are auto-created.
	
	.PARAMETER Target_TargetSNP
	 Specify the local snap CPG and target snap CPG that will be used for volumes that are auto-created.
	
	.PARAMETER GroupName
	Specifies the name of the volume group, using up to 22 characters if the mirror_config policy is set, or up to 31 characters otherwise. This name is assigned with this command.	
	
	.PARAMETER TargetName	
	Specifies the target name associated with this group.
	
	.PARAMETER Mode 	
	sync—synchronous replication
	async—asynchronous streaming replication
	periodic—periodic asynchronous replication
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parRCopyGroup
    LASTEDIT: 08/26/2015
    KEYWORDS: New-3parRCopyGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$domain,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Usr_Cpg_Name,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target_TargetCPG,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Snp_Cpg_Name,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target_TargetSNP,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Mode,
				
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	Write-DebugLog "Start: In New-3parRCopyGroup   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parRCopyGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parRCopyGroup   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "creatercopygroup"	
	if ($domain)	
	{
		$cmd+=" -domain $domain"
	}
	if ($Usr_Cpg_Name)	
	{
		$cmd+=" -usr_cpg $Usr_Cpg_Name "
		if($Target_TargetCPG)
		{
			$cmd+=" $Target_TargetCPG "
		}
		else
		{
			return "Target_TargetCPG is required with Usr CPG option"
		}
	}
	if ($Snp_Cpg_Name)	
	{
		$cmd+=" -snp_cpg $Snp_Cpg_Name "
		if($Target_TargetSNP)
		{
			$cmd+=" $Target_TargetSNP "
		}
		else
		{
			return "Target_TargetSNP is required with Usr CPG option"
		}
	}
	if ($GroupName)
	{
		$cmd+=" $GroupName"
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "			
	}	
	if ($TargetName)
	{		
		$cmd+=" $TargetName"
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}
	if ($Mode)
	{		
		$a = "sync","async","periodic"
		$l=$Mode
		if($a -eq $l)
		{
			$cmd+=":$Mode "	
			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-3parRCopyGroup   since Mode $Mode in incorrect "
			Return "FAILURE : Mode :- $Mode is an Incorrect Mode  [a]  can be used only . "
		}		
	}
	else
	{
		Write-DebugLog "Stop: Mode is Mandate" $Debug
		return "Error :  -Mode is Mandate. "			
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The command creates a remote-copy volume group.. --> $cmd " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING  New-3parRCopyGroup Command $Result"
	}
	else
	{
		return  "FAILURE : While EXECUTING  New-3parRCopyGroup 	$Result "
	} 	
} # End New-3parRCopyGroup	
####################################################################################################################
## FUNCTION Sync-3parRCopy
####################################################################################################################
Function Sync-3parRCopy
{
<#
  .SYNOPSIS
   The Sync-3parRCopy command manually synchronizes remote-copy volume groups.
   
	.DESCRIPTION
    The Sync-3parRCopy command manually synchronizes remote-copy volume groups.
   
	.EXAMPLE
	Sync-3parRCopy -option pat -Target test -GroupName group1
	This example specifies that remote-copy volume group Group1 should be synchronized with its corresponding secondary volume group.
   
	   
	.EXAMPLE  
	Sync-3parRCopy -option pat -Target test -GroupName testgroup*
	This example specifies that all remote-copy volume groups that start with the name testgroup should be synchronized with their corresponding secondary volume group.
	
				
	.PARAMETER option 
	w	:	Wait for synchronization to complete before returning to a command prompt.
	
	n	:	Do not save resynchronization snapshot. This option is only relevant for asynchronous periodic mode volume groups.

	ovrd	:	Force synchronization without prompting for confirmation, even if volumes are already synchronized.
	
	pat		:	Specifies that the patterns specified are treated as glob-style patterns and all remote-copy groups matching the specified pattern will be synced.

	.PARAMETER Target
	Indicates that only the group on the specified target is started. If this option is not used, by default,  	the New-3parRcopyGroup command will affect all of a group’s targets.
	
	.PARAMETER GroupName 
	Specifies the name of the remote-copy volume group to be synchronized.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Sync-3parRCopy
    LASTEDIT: 08/22/2015
    KEYWORDS: Sync-3parRCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Sync-3parRCopy   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Sync-3parRCopy  since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Sync-3parRCopy  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "syncrcopy "
	if ($option)
	{
		$a = "w","n","ovrd","pat"
		$demo = $option
		if($a -eq $demo)
		{
			$cmd+= "-$option "
		}
		else
		{
			return "FAILURE : -option $option is invalid use only [  w | n | ovrd | pat ]"
		}
	}		
	if ($Target)
	{
		$cmd+="-t $Target  "
	}
	else
	{
		Write-DebugLog "Stop: Target is Mandate" $Debug
		return "Error :  -Target is Mandate. "			
	}		
	if ($GroupName)
	{		
		$cmd+="$GroupName "			
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "			
	}			
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The Sync-3parRCopy command manually synchronizes remote-copy volume groups.--> $cmd " "INFO:" 
	return $Result	
} # End Sync-3parRCopy
####################################################################################################################
## FUNCTION Stop-3parRCopyGroup
####################################################################################################################
Function Stop-3parRCopyGroup
{
<#
  .SYNOPSIS
   The Stop-3parRCopyGroup command stops the remote-copy functionality for the specified remote-copy volume group.
   
	.DESCRIPTION
    The Stop-3parRCopyGroup command stops the remote-copy functionality for the specified remote-copy volume group.
  
	   
	.EXAMPLE  
	Stop-3parRCopyGroup -option nosnap -GroupName Group1 
	  This Example stops remote copy for Group1.
   
	.EXAMPLE  
	Stop-3parRCopyGroup -option pat -Target Demovv1 -GroupName Group1 
	This Example stops remote-copy Demovv1 Target  of the Group Group1.
	
				
	.PARAMETER option 
	nosnap	:	In synchronous mode, this option turns off the creation of snapshots.
		
	pat		:	Specifies that specified patterns are treated as glob-style patterns and all remote-copy groups matching the specified pattern will be stopped
		 
	.PARAMETER Target
	Indicates that only the group on the specified target is started. If this option is not used, by default,  	the New-3parRcopyGroup command will affect all of a group’s targets.
	
	.PARAMETER GroupName 
	The name of the remote-copy volume group.
	
  
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Stop-3parRCopyGroup
    LASTEDIT: 08/22/2015
    KEYWORDS: Stop-3parRCopyGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,		
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	
	Write-DebugLog "Start: In Stop-3parRCopyGroup   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Stop-3parRCopyGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Stop-3parRCopyGroup   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "stoprcopygroup -f "	
	if ($option)
	{
		$a = " nosnap | pat "
		$demo = $option
		if($a -match $demo)
		{
			$cmd+= "-$option "
		}
		else
		{
			return "FAILURE : -option $option is invalid use only [ $a ]"
		}
	}	
	if ($Target)
	{
		$cmd+="-t $Target  "
	}		
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+="$GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Stop-3parRCopyGroup  GroupName in Not Available "
			Return "FAILURE : -GroupName $GroupName  is Not Available Try with a new Name. "				
		}		
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Stop-3parRCopyGroup command stops the remote-copy functionality for the specified remote-copy volume group. " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parCage Command 	$Result"
	}
	else
	{
		return 	$Result
	}
} # End Stop-3parRCopyGroup
####################################################################################################################
## FUNCTION Start-3parRcopy
####################################################################################################################
Function Start-3parRcopy
{
<#
  .SYNOPSIS
   The Start-3parRcopy command starts the Remote Copy Service.
   
  .DESCRIPTION
     The Start-3parRcopy command starts the Remote Copy Service.
   
  .EXAMPLE  
	Start-3parRcopy 
     command starts the Remote Copy Service.
				
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Start-3parRcopy
    LASTEDIT: 08/22/2015
    KEYWORDS: Start-3parRcopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(

		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)			
	Write-DebugLog "Start: In Start-3parRcopy   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Start-3parRcopy   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Start-3parRcopy  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "startrcopy "	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Start-3parRcopy command disables the remote-copy functionality for any started remote-copy " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Start-3parRcopy Command `n $Result "
	}
	else
	{
		return  "FAILURE : While EXECUTING Start-3parRcopy `n $Result "
	}
} # End Start-3parRcopy
####################################################################################################################
## FUNCTION Stop-3parRCopy
####################################################################################################################
Function Stop-3parRCopy
{
<#
  .SYNOPSIS
   The Stop-3parRCopy command disables the remote-copy functionality for any started remote-copy
   
	.DESCRIPTION
     The Stop-3parRCopy command disables the remote-copy functionality for any started remote-copy
   
	.EXAMPLE  
	Stop-3parRCopy -option stopgroups
   This example disables the remote-copy functionality of all primary remote-copy volume groups
				
	.PARAMETER Option  
	stopgroups 	:	Specifies that any started remote-copy volume groups are stopped.
	clear	:	Specifies that configuration entries affiliated with the stopped mode are deleted.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Stop-3parRCopy
    LASTEDIT: 08/22/2015
    KEYWORDS: Stop-3parRCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	Write-DebugLog "Start: In Stop-3parRCopy   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Stop-3parRCopy   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Stop-3parRCopy  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "stoprcopy -f "	
	if ($option)
	{
		$c= "stopgroups","clear"		
		if ($c -match $option)
		{
			$cmd+="-$option"
		}
		else
		{
			Write-DebugLog "Stop: Exiting Stop-3parRCopy  option  in unavailable "
			Return "FAILURE : -option  $option is Unavailable to execute use only [stopgroups | clear]. "
		}
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Stop-3parRCopy command disables the remote-copy functionality for any started remote-copy " "INFO:" 	
	if($Result -match "Remote Copy config is not started")
	{
		Return "Command Execute Successfully :- Remote Copy config is not started"
	}
	else
	{
		return $Result
	}
} # End Stop-3parRCopy
####################################################################################################################
## FUNCTION Get-3parStatRCopy
####################################################################################################################
Function Get-3parStatRCopy
{
<#
  .SYNOPSIS
   The Get-3parStatRCopy command displays statistics for remote-copy volume groups.
   
	.DESCRIPTION
       The Get-3parStatRCopy command displays statistics for remote-copy volume groups.
	
	.EXAMPLE
	Get-3parStatRCopy -HeartBeat -Iteration 1
	This example shows statistics for sending links ,Specifies that the heartbeat round-trip time.
	
	.EXAMPLE  
	Get-3parStatRCopy -Iteration 1
	This example shows statistics for sending links link0 and link1.
   
	.EXAMPLE  
	Get-3parStatRCopy -HeartBeat -Unit k -Iteration 1
	This example shows statistics for sending links ,Specifies that the heartbeat round-trip time & displays statistics as kilobytes	
			
	.PARAMETER HeartBeat  
	Specifies that the heartbeat round-trip time of the links should be displayed in addition to the link throughput.
	 
	.PARAMETER Unit
	Displays statistics as kilobytes (k), megabytes (m), or gigabytes (g). If no unit is specified, the default is kilobytes.
	
	.PARAMETER Interation 
	Specifies that I/O statistics are displayed a specified number of times as indicated by the num argument using an integer from 1 through 2147483647.
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parStatRCopy
    LASTEDIT: 08/22/2015
    KEYWORDS: Get-3parStatRCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Interval,
		
		[Parameter(Position=1, Mandatory=$false)]
		[switch]
		$HeartBeat,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Unit,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Iteration,		
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Get-3parStatRCopy   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parStatRCopy   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parStatRCopy   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "statrcopy "	
	if ($Iteration)
	{
		$cmd += " -iter $Iteration "
	}	
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "			
	}
	
	if ($Interval )
	{
		$cmd+= "-d $Interval "
	}
	if ($HeartBeat )
	{
		$cmd+= "-hb "
	}
	if ($Unit)
	{
		$c= "k","m","g"		
		if ($c -eq $Unit)
		{
			$cmd+="-u $Unit  "
		}
		else
		{
			Write-DebugLog "Stop: Exiting Get-3parStatRCopy  Unit  in unavailable "
			Return "FAILURE : -Unit  $Unit is Unavailable to execute use only [k | m | g]. "
		}
	}		
				
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The Get-3parStatRCopy command displays statistics for remote-copy volume groups. " "INFO:" 
	return  $Result
	<#
	if($Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		$incre = "true" 		
		foreach ($s in  $Result[1..$LastItem] )
		{			
			$s= [regex]::Replace($s,"^ ","")						
			$s= [regex]::Replace($s," +",",")			
			$s= [regex]::Replace($s,"-","")			
			$s= $s.Trim()			
			if($incre -eq "true")
			{		
				$sTemp1=$s				
				$sTemp = $sTemp1.Split(',')					
				$sTemp[5]="Current(Throughput)"				
				$sTemp[6]="Average(Throughput)"
				$sTemp[7]="Current(Write_Same_Zero)"				
				$sTemp[8]="Average(Writ_Same_Zero)"
				$newTemp= [regex]::Replace($sTemp,"^ ","")			
				$newTemp= [regex]::Replace($sTemp," ",",")				
				$newTemp= $newTemp.Trim()
				$s=$newTemp							
			}					
			Add-Content -Path $tempfile -Value $s	
			$incre="false"
		}			
		Import-Csv $tempFile 
		del $tempFile			
	}
	else
	{			
		return  $Result
	}	
#>	
} # End Get-3parStatRCopy
####################################################################################################################
## FUNCTION Start-3parRCopyGroup
##################################################################################################################
Function Start-3parRCopyGroup
{
<#
  .SYNOPSIS
   The Start-3parRCopyGroup command enables remote copy for the specified remote-copy volume group.
   
	.DESCRIPTION
     The Start-3parRCopyGroup command enables remote copy for the specified remote-copy volume group.
	
	.EXAMPLE
	Start-3parRCopyGroup -option nosync -GroupName Group1
	This example starts remote copy for Group1.   
	
	.EXAMPLE  	
	Start-3parRCopyGroup -option nosync -GroupName Group2 -VVnames vv1:sv1,vv2:sv2,vv3:sv3
	This Example  starts Group2, which contains 4 virtual volumes, and specify starting snapshots, with vv4 starting from a full resynchronization.
			
	.PARAMETER option 
	nosync	:	Prevents the initial synchronization and sets the virtual volumes to a synchronized state.
	
	wait	:	Specifies that the command blocks until the initial synchronization is complete. The system generates an event when the synchronization is complete.
		
	pat		:	Specifies that specified patterns are treated as glob-style patterns and that all remote-copy groups matching the specified pattern will be started.
	 
	.PARAMETER Target
	Indicates that only the group on the specified target is started. If this option is not used, by default,  	the New-3parRcopyGroup command will affect all of a group’s targets.
	
	.PARAMETER GroupName 
	The name of the remote-copy volume group.
	
   .PARAMETER VVnames 
	virtual volumes.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Start-3parRCopyGroup
    LASTEDIT: 08/22/2015
    KEYWORDS: Start-3parRCopyGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Target,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VVnames,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Start-3parRCopyGroup   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Start-3parRCopyGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Start-3parRCopyGroup   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "startrcopygroup "	
	if ($option)
	{
		$a = "nosync","wait","pat"
		$demo = $option
		if($a -eq $demo)
		{
			$cmd+= "-$option "
		}
		else
		{
			return "FAILURE : -option $option is invalid use only [  nosync | wait | pat  ]"
		}
	}
	if ($Target )
	{
		$cmd+="-t $Target  "
	}
	else
	{
		Write-DebugLog "Stop: Target is Mandate" $Debug
		return "Error :  -Target is Mandate. "
	}		
	if ($GroupName)
	{
		$cmd+="$GroupName "
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "
	}
	if ($VVnames)
	{	
		$a=$VVnames
		$s= [regex]::Replace($a,","," ")		
		$cmd+="$s "
	}
	if("startrcopygroup " -eq $cmd )
	{
		get-help Start-3parRCopyGroup
		return " "
	}	
	#write-host "$cmd"			
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The Start-3parRCopyGroup command enables remote copy for the specified remote-copy volume group.using --> $cmd " "INFO:"
	return $Result	
} # End Start-3parRCopyGroup
####################################################################################################################
## FUNCTION Get-3parRCopy
####################################################################################################################
Function Get-3parRCopy
{
<#
  .SYNOPSIS
   The Get-3parRCopy command displays details of the remote-copy configuration.
   
 .DESCRIPTION
    The Get-3parRCopy command displays details of the remote-copy configuration.
	
	.EXAMPLE
	Get-3parRCopy -option d -Links
	This Example displays details of the remote-copy configuration and Specifies all remote-copy links.   
	
	.EXAMPLE  	
	Get-3parRCopy -option d -domain PSTest -targets Demovv1
	This Example displays details of the remote-copy configuration which Specifies either all target definitions
			
	.PARAMETER option 
	d	:	Displays more detailed configuration information.
	
	qw	:	Displays additional target specific automatic transparent failover-related configuration, where applicable.
  
	 
	.PARAMETER domain
	Shows only remote-copy links whose virtual volumes are in domains with names that match one or more of the specified domain name or pattern.
	
	.PARAMETER Links
	Specifies all remote-copy links.
		
	.PARAMETER groups 
	Specifies either all remote-copy volume groups or a specific remote-copy volume group by name or by glob-style pattern.
  
   .PARAMETER targets
	Specifies either all target definitions or a specific target definition by name or by glob-style pattern.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parRCopy
    LASTEDIT: 08/22/2015
    KEYWORDS: Get-3parRCopy
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$domain,
		
		[Parameter(Position=2, Mandatory=$false)]
		[switch]
		$Links,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$groups,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$targets,
			
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Get-3parRCopy   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parRCopy   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parRCopy   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "showrcopy "	
	if ($option)
	{
		$var = "d","qw"
		$demo = $option
		if($var -eq $demo)
		{
			$cmd+= "-$option "			
		}
		else
		{
			return "FAILURE : -option $option is invalid use only [ d | qw ]"
		}
	}		
	if ($domain)
	{
		$cmd += " -domain $domain "
	}
	if ($Links)
	{
		$cmd += " links "
	}	
	if ($groups)
	{
		$cmd+="groups $groups "		
	}	
	if ($targets)
	{		
		$cmd+="targets $targets "
	}
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  The Get-3parRCopy command displays details of the remote-copy configuration. -> $cmd " "INFO:" 
	return $Result
} # End Get-3parRCopy
####################################################################################################################
## FUNCTION New-3parRCopyGroupCPG
###################################################################################################################

Function New-3parRCopyGroupCPG
{
<#
  .SYNOPSIS
   The New-3parRCopyGroupCPG command creates a remote-copy volume group.
   
 .DESCRIPTION
    The New-3parRCopyGroupCPG command creates a remote-copy volume group.
   
	
	.EXAMPLE
	New-3parRCopyGroupCPG -UsrCpgName cpg1 -TargetName_UsrCpgName target1:cpg1 -GroupName demogroup1 -TargetName_Mode "target1:sync,target2:periodic"
	This example  command creates a remote-copy User CPG with volume auto-created.
	
	.EXAMPLE  
	New-3parRCopyGroupCPG -SnpCpgName snap1 -TargetName_SnpCpgName target1:snap1 -domain demo.com -GroupName groupCpg1 -TargetName_Mode "TargetSnap1:sync"
	This example  command creates a remote-copy User CPG with Snap volume auto-created.
	
	.PARAMETER UsrCpgName
	Specifies the local user CPG and target user CPG that will be used for volumes that are auto-created.
	
	.PARAMETER TargetName_UsrCpgName
	-TargetName_UsrCpgName target:Targetcpg The local CPG will only be used after fail-over and recovery.
	
	.PARAMETER SnpCpgName
	Specifies the local snap CPG and target snap CPG that will be used for volumes that are auto-created. 
	
	.PARAMETER TargetName_SnpCpgName
	-TargetName_SnpCpgName  target:Targetcpg
		
	.PARAMETER domain
	Creates the remote-copy group in the specified domain.
	
	.PARAMETER GroupName
	Specifies the name of the volume group, using up to 22 characters if the mirror_config policy is set, or up to 31 characters otherwise. This name is assigned with this command.	
	
	.PARAMETER TargetName
	Specifies the target name associated with this group.
	
	.PARAMETER Mode 
	-----
	sync—synchronous replication
	async—asynchronous streaming replication
	periodic—periodic asynchronous replication
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  New-3parRCopyGroupCPG
    LASTEDIT: 08/26/2015
    KEYWORDS: New-3parRCopyGroupCPG
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
			
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$UsrCpgName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName_UsrCpgName,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SnpCpgName,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName_SnpCpgName,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$domain,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=9, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Mode,
				
		[Parameter(Position=10, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In New-3parRCopyGroupCPG - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parRCopyGroupCPG   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parRCopyGroupCPG   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "creatercopygroup"	
	if ($UsrCpgName)	
	{
		$cmd+=" -usr_cpg $UsrCpgName "
	}
	if ($TargetName_UsrCpgName)	
	{
		if($cmd -match "-usr_cpg")
		{
			$t1="TargetName_UsrCpgName"
			$s= [regex]::Replace($t1,","," ")
			$cmd+=" $s "
		}
		else
		{
			return "Error : -TargetName_UsrCpgName can't be used without -UsrCpgName"
		}
	}	
	if ($SnpCpgName)	
	{
		$cmd+=" -snp_cpg $SnpCpgName "
	}
	else
	{ 
		if($cmd -match "-usr_cpg"){		}
		else{	return "Error : -UsrCpgName | SnpCpgName is mandate"	}
	}
	if ($TargetName_SnpCpgName)	
	{
		if($cmd -match "-snp_cpg")
		{
		$t1="TargetName_SnpCpgName"
		$s= [regex]::Replace($t1,","," ")
		$cmd+=" $s "
		}
		else
		{
		return "Error : -TargetName_SnpCpgName can't be used without -SnpCpgName"
		}
	
	}	
	if ($domain)	
	{
		$cmd+=" -domain $domain"
	}			
	if ($GroupName)
	{
		$cmd+=" $GroupName"
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "			
	}	
	if ($TargetName)
	{		
		$cmd+=" $TargetName"
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}
	if ($Mode)
	{		
		$a = "sync","async","periodic"
		$l=$Mode
		if($a -eq $l)
		{
			$cmd+=":$Mode "	
			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  New-3parRCopyGroupCPG   since Mode $Mode in incorrect "
			Return "FAILURE : Mode :- $Mode is an Incorrect Mode  [a]  can be used only . "
		}		
	}
	else
	{
		Write-DebugLog "Stop: Mode is Mandate" $Debug
		return "Error :  -Mode is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  The command creates a remote-copy volume group.. --> $cmd " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING  New-3parRCopyGroupCPG Command $Result"
	}
	else
	{
		return  "FAILURE : While EXECUTING  New-3parRCopyGroupCPG 	$Result "
	} 	
} # End New-3parRCopyGroupCPG	

#EndRegion

####################################################################################################################
## FUNCTION Set-3parRCopyTargetName
####################################################################################################################
Function Set-3parRCopyTargetName
{
<#
  .SYNOPSIS
	The Set-3parRCopyTargetName Changes the name of the indicated target using the <NewName> specifier.
   
  .DESCRIPTION
	The Set-3parRCopyTargetName Changes the name of the indicated target using the <NewName> specifier.
  
  .EXAMPLE
	Set-3parRCopyTargetName -NewName DemoNew1  -TargetName Demo1
		This Example Changes the name of the indicated target using the -NewName demoNew1.   
	
  .PARAMETER NewName 
		The new name for the indicated target. 
 
   .PARAMETER TargetName  
		Specifies the target name for the target definition.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
	  
  .Notes
    NAME: Set-3parRCopyTargetName
    LASTEDIT: 08/25/2015
    KEYWORDS: Set-3parRCopyTargetName
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$NewName,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Set-3parRCopyTargetName  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parRCopyTargetName    since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parRCopyTargetName    since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopytarget name "
	if ($NewName)
	{
		$cmd+="$NewName "
	}
	else
	{
		Write-DebugLog "Stop: NewName is Mandate" $Debug
		return "Error :  -NewName is Mandate. "			
	}	
	if ($TargetName)
	{
		$cmd+="$TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Set-3parRCopyTargetName Changes the name of the indicated target --> $cmd " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parRCopyTargetName $Result"
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parRCopyTargetName $Result "
	} 	
} # End Set-3parRCopyTargetName 

####################################################################################################################
## FUNCTION Set-3parRCopyTarget
####################################################################################################################
Function Set-3parRCopyTarget
{
<#
  .SYNOPSIS
  The Set-3parRCopyTarget Changes the name of the indicated target using the <NewName> specifier.
   
 .DESCRIPTION
 The Set-3parRCopyTarget Changes the name of the indicated target using the <NewName> specifier.  
	
	.EXAMPLE
		Set-3parRCopyTarget -Option enable -TargetName Demo1
			This Example Enables  the targetname Demo1.
 	.EXAMPLE
		Set-3parRCopyTarget -Option disable -TargetName Demo1
			This Example disables  the targetname Demo1.  
	
	.PARAMETER Option 
		specify enable or disable 
 
   .PARAMETER TargetName  
		Specifies the target name 
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection		
  
  .Notes
    NAME: Set-3parRCopyTarget
    LASTEDIT: 08/25/2015
    KEYWORDS: Set-3parRCopyTarget
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)			
	Write-DebugLog "Start: In Set-3parRCopyTarget  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parRCopyTarget since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parRCopyTarget since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopytarget "
	if ($Option)
	{	
		$test  = "enable","disable"
		if($test -eq $Option)
		{
			$cmd += " $option"
		}
		else{
			return "Invalid parameter, specify value as [enable | disable]"
		}
	}
	else
	{
		Write-DebugLog "Stop: Option  is Mandate" $Debug
		return "Error :  -Option is Mandate. "			
	}	
	if ($TargetName)
	{
		$cmd+=" $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Set-3parRCopyTarget Changes the name of the indicated target --> $cmd " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parRCopyTarget $Result"
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parRCopyTarget $Result "
	} 	
} # End Set-3parRCopyTarget
####################################################################################################################
## FUNCTION Set-3parRCopyTargetPol
####################################################################################################################
Function Set-3parRCopyTargetPol
{
<#
  .SYNOPSIS
  The Set-3parRCopyTargetPol command Sets the policy for the specified target using the <policy> specifier
   
 .DESCRIPTION
 The Set-3parRCopyTargetPol command Sets the policy for the specified target using the <policy> specifier
 	
	.EXAMPLE
	Set-3parRCopyTargetPol -Policy mirror_config -Target vv3
	This Example sets the policy that all configuration commands,involving the specified target are duplicated for the target named vv3.	
   	
	.PARAMETER policy 
	mirror_config	:	Specifies that all configuration commands,involving the specified target are duplicated.
	
	no_mirror_config	:	If not specified, all configuration commands are duplicated.	
	
	.PARAMETER Target
  Specifies the target name for the target definition.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.PARAMETER	Note
	That the no_mirror_config specifier should only be used to allow recovery from an unusual error condition and only used after consulting your HPE representative.
  
  .Notes
    NAME: Set-3parRCopyTargetPol
    LASTEDIT: 08/24/2015
    KEYWORDS: Set-3parRCopyTargetPol
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$policy,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Set-3parRCopyTargetPol   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parRCopyTargetPol   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parRCopyTargetPol   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopytarget pol "
	if ($policy )
	{
		$s = "mirror_config","no_mirror_config" 
		$demo = $policy
		if($s -eq $demo)
		{
			$cmd+=" $policy "
		}
		else
		{
			return " FAILURE : -policy $policy is not Valid . use [ mirror_config | no_mirror_config] Only,  "
		}	
	}
	else
	{
		Write-DebugLog "Stop: policy is Mandate" $Debug
		return "Error :  -policy is Mandate. "			
	}
	if ($Target)
	{
		$cmd+="$Target "
	}
	else
	{
		Write-DebugLog "Stop: Target is Mandate" $Debug
		return "Error :  -Target is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Set-3parRCopyTargetPol Command Sets the policy for the specified target using the <policy> specifier.--> $cmd " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parRCopyTargetPol Command "
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parRCopyTargetPol $result "
	} 
} # End Set-3parRCopyTargetPol

####################################################################################################################
## FUNCTION Set-3parRCopyTargetWitness
####################################################################################################################
Function Set-3parRCopyTargetWitness
{
<#
  .SYNOPSIS
	The Set-3parRCopyTargetWitness Changes the name of the indicated target using the <NewName> specifier.
   
  .DESCRIPTION
	The Set-3parRCopyTargetWitness Changes the name of the indicated target using the <NewName> specifier.
  
  .EXAMPLE
	Set-3parRCopyTargetWitness -SubCommand create -Witness_ip 1.2.3.4 -Target TEST
		This Example Changes the name of the indicated target using the -NewName demoNew1.  
  .EXAMPLE	
	Set-3parRCopyTargetWitness -SubCommand create -Option remote -Witness_ip 1.2.3.4 -Target TEST
	
  .EXAMPLE
  Set-3parRCopyTargetWitness -SubCommand start -Target TEST
  
  .EXAMPLE
  Set-3parRCopyTargetWitness -SubCommand stop -Target TEST
  
  .EXAMPLE  
  Set-3parRCopyTargetWitness -SubCommand remove -Option remote -Target TEST
  
  .EXAMPLE  
  Set-3parRCopyTargetWitness -SubCommand check -Option node -Node_id 1 -Witness_ip 1.2.3.4
  
  .PARAMETER SubCommand 
		Sub Command like create, Start, Stop, Remove and check.				
     create
        Create an association between a synchronous target and a Quorum Witness (QW)
        as part of a Peer Persistence configuration.
     start|stop|remove
        Activate, deactivate and remove the ATF configuration.
     check
        Check connectivity to Quorum Witness.
		
 .PARAMETER Option 		
    -remote
        Used to forward a witness subcommand to the be executed on the
        remote HPE 3PAR Storage System. When used in conjunction with the
        "witness check" subcommand the target must be specified - when executing
        on the local storage system target specification is not required to check
        connectivity with the Quorum Witness.
    -node
        Used to conjunction with the "witness check" subcommand to test the
        connectivity to the Quorum Witness via the Quorum Announce process running
        on the specified node. Otherwise, the command simply verifies that there
        is at least one operational route to the witness. 
		
  .PARAMETER Witness_ip
        The IP address of the Quorum Witness (QW) application, to which the
        HPE 3PAR Storage System will connect to update its status periodically.
		
  .PARAMETER Target			
        Specifies the target name for the target definition previously created
        with the creatercopytarget command.
  
  .PARAMETER Node_id	
		Nodee id with node option
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection	
	  
  .Notes
    NAME: Set-3parRCopyTargetWitness
    LASTEDIT: 08/25/2015
    KEYWORDS: Set-3parRCopyTargetWitness
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SubCommand,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Option,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Witness_ip,
		
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Target,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$Node_id,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-3parRCopyTargetWitness  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parRCopyTargetWitness    since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parRCopyTargetWitness    since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($SubCommand)
	{
		if($SubCommand -eq "create")
		{
			if($Witness_ip -And $Target)
			{
				$cmd= "setrcopytarget witness $SubCommand"	
				if ($Option)
				{	
					$test  = "remote"
					if($test -eq $Option)
					{
						$cmd += " -$option"
					}
					else
					{
						return "Invalid parameter, specify value as [remote]"
					}
				}
				$cmd +=" $Witness_ip $Target"
				#write-host "$cmd"
				$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
				write-debuglog "  executing Set-3parRCopyTargetWitness Changes the name of the indicated target --> $cmd " "INFO:" 
				return $Result
			}		
			else
			{
				write-debugLog "witness_ip, target missing or anyone of them are missing." "ERR:" 
				return "FAILURE : witness_ip, target missing or anyone of them are missing."
			}
		}
		elseif($SubCommand -eq "start" -Or $SubCommand -eq "stop" -Or $SubCommand -eq "remove")
		{
			if($Target)
			{
				$cmd= "setrcopytarget witness $SubCommand"	
				if ($Option)
				{	
					$test  = "remote"
					if($test -eq $Option)
					{
						$cmd += " -$option"
					}
					else
					{
						return "Invalid parameter, specify value as [remote]"
					}
				}
				$cmd +=" $Target"
				#write-host "$cmd"
				$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
				write-debuglog "  executing Set-3parRCopyTargetWitness Changes the name of the indicated target --> $cmd " "INFO:" 
				return $Result
			}		
			else
			{
				write-debugLog "Target is missing." "ERR:" 
				return "FAILURE : Target is missing."
			}
		}
		elseif($SubCommand -eq "check")
		{
			if($Witness_ip)
			{
				$cmd= "setrcopytarget witness $SubCommand"	
				if ($Option)
				{	
					$test  = "remote","node"
					if($test -eq $Option)
					{
						if($Option -eq "node")
						{
							$cmd += " -$option $Node_id"
						}
						else
						{
							$cmd += " -$option"
						}
					}
					else
					{
						return "Invalid parameter, specify value as [remote | node]"
					}
				}
				$cmd +=" $Witness_ip $Target"
				#write-host "$cmd"
				$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
				write-debuglog "  executing Set-3parRCopyTargetWitness Changes the name of the indicated target --> $cmd " "INFO:" 
				return $Result
			}		
			else
			{
				write-debugLog "Witness_ip is missing." "ERR:" 
				return "FAILURE : Witness_ip is missing."
			}
		}
		else
		{
			return "Invalid Sub Command, specify value as [witness create | start | stop | remove | check]"
		}
	}
	else
	{
		return "Sub Command is missing, specify value as [witness create | start | stop | remove | check]"
	}	
} # End Set-3parRCopyTargetWitness 

####################################################################################################################
## FUNCTION Set-3parRCopyGroupPeriod
####################################################################################################################
Function Set-3parRCopyGroupPeriod
{
<#
  .SYNOPSIS
  Sets a resynchronization period for volume groups in asynchronous periodic mode.
   
 .DESCRIPTION
Sets a resynchronization period for volume groups in asynchronous periodic mode.
    
	
	.EXAMPLE
	Set-3parRCopyGroupPeriod -Period 10m -TargetName CHIMERA03 -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPeriod -Period 10m -Force -TargetName CHIMERA03 -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPeriod -Period 10m -T 1 -TargetName CHIMERA03 -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPeriod -Period 10m -Stopgroups -TargetName CHIMERA03 -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPeriod -Period 10m -Local -TargetName CHIMERA03 -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPeriod -Period 10m -Natural -TargetName CHIMERA03 -GroupName AS_TEST	
  
	.PARAMETER Period
	Specifies the time period in units of seconds (s), minutes (m), hours (h), or days (d), for automatic resynchronization (for example, 14h for 14 hours).
	
	
	.PARAMETER TargetName
	Specifies the target name for the target definition
	
	.PARAMETER GroupName
	Specifies the name of the volume group whose policy is set, or whose target direction is switched.
	
	.PARAMETER T <tname>
        When used with <dr_operation> subcommands, specifies the target to which
        the <dr_operation> command applies to.  This is optional for single
        target groups, but is required for multi-target groups. If no groups are
        specified, it applies to all relevant groups. When used with the pol subcommand,
        specified for a group with multiple targets then the command only applies to
        that target, otherwise it will be applied to all targets.

        NOTE: The -t option without the groups listed in the command, will only work
        in a unidirectional configuration. For bidirectional configurations, the -t
        option must be used along with the groups listed in the command.

    .PARAMETER Force
        Does not ask for confirmation for disaster recovery commands.
	
	 .PARAMETER Stopgroups
        Specifies that groups are stopped before running the reverse subcommand.

    .PARAMETER Local
        When issuing the command with the reverse specifier, only the group's
        direction is changed on the system where the command is issued.

    .PARAMETER Natural
        When issuing the -natural option with the reverse specifier, only the natural
        direction of data flow between the specified volume group and its target
        group is reversed. The roles of the volume groups do not change.
		
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parRCopyGroupPeriod
    LASTEDIT: 08/24/2015
    KEYWORDS: Set-3parRCopyGroupPeriod
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Period,
		
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$Force,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$T,	
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Stopgroups,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Local,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Natural,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)			
	Write-DebugLog "Start: In Set-3parRCopyGroupPeriod   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parRCopyGroupPeriod   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parRCopyGroupPeriod   since SAN connection object values are null/empty"
			}
		}
	}
	
	#setrcopygroup period [option] [<pattern>] <period_value> <target_name> [<group_name>]

	
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "setrcopygroup period "	
	if ($Period)
	{
		$p=$Period[-1]
		$s = " s | m | h |  d "	 			
		if($s -match $p)
		{
			$cmd+=" $Period "
		}
		else
		{
			return " ERROR : -Period $Period is not Valid . use [ s | m | h |  d ] Only, Ex: -Period 10s "	
		}
	}
	else
	{
		Write-DebugLog "Stop: Period is Mandate" $Debug
		return "Error :  -Period is Mandate. "			
	}
	if($Force)
	{
		$cmd+= " -f "
	}
	if($T)
	{
		$cmd+= " -t $T "
	}
	if($Stopgroups)
	{
		$cmd+= " -stopgroups "
	}
	if($Local)
	{
		$cmd+= " -local "
	}
	if($Natural)
	{
		$cmd+= " -natural "
	}
	if ($TargetName)
	{
		$cmd+= " $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "
	}	
	if ($GroupName)
	{
		$cmd+= " $GroupName "
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "
	}		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Set-3parRCopyGroupPeriod using cmd --> $cmd " "INFO:" 
	if([string]::IsNullOrEmpty($Result))
	{
			return  "SUCCESS : EXECUTING Set-3parRCopyGroupPeriod Command "
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parRCopyGroupPeriod  $Result"
	} 
} # End Set-3parRCopyGroupPeriod
####################################################################################################################
## FUNCTION Set-3parRCopyGroupPol
####################################################################################################################
Function Set-3parRCopyGroupPol
{
<#
  .SYNOPSIS
  Sets the policy of the remote-copy volume group for dealing with I/O failure and error handling.
   
 .DESCRIPTION
 Sets the policy of the remote-copy volume group for dealing with I/O failure and error handling.
    
	.EXAMPLE	
	Set-3parRCopyGroupPol -policy test -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -policy auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -Force -policy auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -T 1 -policy auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -Stopgroups -policy auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -Local -policy auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -Natural -policy auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -policy no_auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -Force -policy no_auto_failover -GroupName AS_TEST

	.EXAMPLE
	Set-3parRCopyGroupPol -T 1 -policy no_auto_failover -GroupName AS_TEST
	
	.PARAMETER T <tname>
        When used with <dr_operation> subcommands, specifies the target to which
        the <dr_operation> command applies to.  This is optional for single
        target groups, but is required for multi-target groups. If no groups are
        specified, it applies to all relevant groups. When used with the pol subcommand,
        specified for a group with multiple targets then the command only applies to
        that target, otherwise it will be applied to all targets.

        NOTE: The -t option without the groups listed in the command, will only work
        in a unidirectional configuration. For bidirectional configurations, the -t
        option must be used along with the groups listed in the command.

    .PARAMETER Force
        Does not ask for confirmation for disaster recovery commands.
	
	 .PARAMETER Stopgroups
        Specifies that groups are stopped before running the reverse subcommand.

    .PARAMETER Local
        When issuing the command with the reverse specifier, only the group's
        direction is changed on the system where the command is issued.

    .PARAMETER Natural
        When issuing the -natural option with the reverse specifier, only the natural
        direction of data flow between the specified volume group and its target
        group is reversed. The roles of the volume groups do not change.
   
	.PARAMETER policy 
	auto_failover	:	Configure automatic failover on a remote-copy group.
	
	no_auto_failover	:	Remote-copy groups will not be subject to automatic fail-over (default).
	
	auto_recover	:	Specifies that if the remote copy is stopped as a result of the remote-copy links going down,	the group is restarted automatically after the links come back up.
	
	no_auto_recover	:	Specifies that if the remote copy is stopped as a result of the remote-copy links going down, the group must be restarted manually after the links come back up (default).
		
	over_per_alert	:	If a synchronization of a periodic remote-copy group takes longer to complete than its synchronization period then an alert will be generated.
	
	no_over_per_alert 	:	If a synchronization of a periodic remote-copy group takes longer to complete than its synchronization period then an alert will not be generated.
	
	path_management	:	Volumes in the specified group will be enabled to support ALUA.
	
	no_path_management	:	ALUA behaviour will be disabled for volumes in the group.
	
	
	.PARAMETER GroupName
  Specifies the name of the volume group whose policy is set, or whose target direction is switched.
  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3parRCopyGroupPol
    LASTEDIT: 08/24/2015
    KEYWORDS: Set-3parRCopyGroupPol
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$Force,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$T,	
		
		[Parameter(Position=2, Mandatory=$false)]
		[Switch]
		$Stopgroups,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Local,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Natural,
		
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$policy,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$GroupName,
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-3parRCopyGroupPol   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3parRCopyGroupPol   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3parRCopyGroupPol   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "setrcopygroup pol "
	if($Force)
	{
		$cmd+= " -f "
	}
	if($T)
	{
		$cmd+= " -t $T "
	}
	if($Stopgroups)
	{
		$cmd+= " -stopgroups "
	}
	if($Local)
	{
		$cmd+= " -local "
	}
	if($Natural)
	{
		$cmd+= " -natural "
	}
	if ($policy )
	{
		$s = " auto_failover | no_auto_failover | auto_recover | no_auto_recover | over_per_alert | no_over_per_alert | path_management	| no_path_management "
	 	$demo = $policy
		if($s -match $demo)
		{
			$cmd+=" $policy "
		}
		else
		{
			return " FAILURE : -policy $policy is not Valid . use [$s] Only.  "	
		}
	}
	else
	{
		Write-DebugLog "Stop: policy is Mandate" $Debug
		return "Error :  -policy is Mandate. "
	}
	if ($GroupName)
	{		
		$cmd+="$GroupName "			
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Set-3parRCopyGroupPol using cmd --> $cmd  " "INFO:"	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : EXECUTING Set-3parRCopyGroupPol Command "
	}
	else
	{
		return  "FAILURE : While EXECUTING Set-3parRCopyGroupPol $Result "
	} 	
} # End Set-3parRCopyGroupPol
####################################################################################################################
## FUNCTION Remove-3parRCopyTarget
####################################################################################################################
Function Remove-3parRCopyTarget
{
<#
  .SYNOPSIS
   The Remove-3parRCopyTarget command command removes target designation from a remote-copy system and removes all links affiliated with that target definition.   
   
 .DESCRIPTION
   The Remove-3parRCopyTarget command command removes target designation from a remote-copy system and removes all links affiliated with that target definition.   

   
   .EXAMPLE  
	Remove-3parRCopyTarget -option cleargroups -TargetName demovv1
    This Example removes target designation from a remote-copy system & Remove all groups.
		
	.PARAMETER option
	
	cleargroups :	Remove all groups that have no other targets or dismiss this target from groups with additional targets.
		
  .PARAMETER TargetName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parRCopyTarget
    LASTEDIT: 08/21/2015
    KEYWORDS: Remove-3parRCopyTarget
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$TargetName,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Remove-3parRCopyTarget  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parRCopyTarget   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parRCopyTarget  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "removercopytarget -f "
	if ($option)
	{
		$a = "cleargroups"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Remove-3parRCopyTarget   since -option $option in invalid "
			return " FAILURE : -option $option is not Valid . use [$a] Only.  "
		}
	}
	else
	{
		Write-DebugLog "Stop: option is Mandate" $Debug
		return "Error :  -option is Mandate. "	
	}	
	if ($TargetName)
	{
		$cmd+=" $TargetName "	
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Remove-3parRCopyTarget  command removes target designation from a remote-copy system and removes all links affiliated with that target definitionusing. cmd --> $cmd " "INFO:" 	
	if([string]::IsNullOrEmpty($Result))
	{
		return  "SUCCESS : Remove-3parRCopyTarget   "
	}
	else
	{
		return  "FAILURE : While EXECUTING Remove-3parRCopyTarget $Result  "
	} 
} # End Remove-3parRCopyTarget
#EndRegion
####################################################################################################################
## FUNCTION Remove-3parRCopyGroup
###################################################################################################################
Function Remove-3parRCopyGroup
{
<#
  .SYNOPSIS
   The Remove-3parRCopyGroup command removes a remote-copy volume group or multiple remote-copy groups that match a given pattern.
   
 .DESCRIPTION
    The Remove-3parRCopyGroup command removes a remote-copy volume group or multiple remote-copy groups that match a given pattern.	
   
   .EXAMPLE  
	Remove-3parRCopyGroup -option pat -GroupName testgroup*
	
	This example Removes remote-copy groups that start with the name testgroup	
   
	.EXAMPLE  
	Remove-3parRCopyGroup -option keepsnap -GroupName group1
	
	This example Removes the remote-copy group (group1) and retains the resync snapshots associated with each volume
		
	.PARAMETER option
		
	pat		:	Specifies that specified patterns are treated as glob-style patterns and that all remote-copy groups matching the specified pattern will be removed.
				
	keepsnap	:	Specifies that the local volume's resync snapshot should be retained.
	
	removevv	:	Remove remote sides' volumes.
	
	
  .PARAMETER GroupName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parRCopyGroup
    LASTEDIT: 08/21/2015
    KEYWORDS: Remove-3parRCopyGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Remove-3parRCopyGroup  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parRCopyGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parRCopyGroup  since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "removercopygroup -f "	
	if ($option)
	{
		$a = "pat","keepsnap","removevv"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Remove-3parRCopyGroup   since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [  pat | keepsnap | removevv  ]  can be used . "
		}
	}	
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+=" $GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Remove-3parRCopyGroup  GroupName in unavailable "
			Return "FAILURE : -GroupName $GroupName  is Unavailable . "
		}		
	}		
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "			
	}		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog "  executing Remove-3parRCopyGroup  command removes a remote-copy volume group or multiple remote-copy groups that match a given pattern." "INFO:" 	
	if($Result -match "deleted")
	{
		return  "SUCCESS : Remove-3parRCopyGroup Command `n $Result  "
	}
	else
	{
		return  "FAILURE : While EXECUTING DRemove-3parRCopyGroup `n $Result "
	} 	
} # End Remove-3parRCopyGroup
#EndRegion
####################################################################################################################
## FUNCTION Remove-3parRCopyVVFromGroup
####################################################################################################################
Function Remove-3parRCopyVVFromGroup
{
<#
  .SYNOPSIS
   The Remove-3parRCopyVVFromGroup command removes a virtual volume from a remote-copy volume group.
   
 .DESCRIPTION
   The Remove-3parRCopyVVFromGroup command removes a virtual volume from a remote-copy volume group.
   
	.EXAMPLE
	Remove-3parRCopyVVFromGroup -option f -VV_name vv1 -group_name Group1
   dismisses virtual volume vv1 from Group1:
   
   .EXAMPLE  
	Remove-3parRCopyVVFromGroup -option pat -VV_name testvv* -group_name Group1
	dismisses all virtual volumes that start with the name testvv from Group1:
   
	.EXAMPLE  
	Remove-3parRCopyVVFromGroup -option keepsnap -VV_name vv1 -group_name Group1
	dismisses volume vv1 from Group1 and removes the corresponding volumes of vv1 on all the target systems of Group1.
	
	.EXAMPLE 
	Remove-3parRCopyVVFromGroup -option removevv -VV_name vv2 -group_name Group1
	dismisses volume vv2 from Group2 and retains the resync snapshot associated with vv2 for this group.
	
	.PARAMETER option
	pat		:	Specifies that specified patterns are treated as glob-style patterns and that all remote-copy volumes
				matching the specified pattern will be dismissed from the remote-copy group.
				
	keepsnap	:	Specifies that the local volume's resync snapshot should be retained.
	
	removevv	:	Remove remote sides' volumes.
	
	    	
	.PARAMETER VVname
	The name of the volume to be removed. Volumes are added to a group with the admitrcopyvv command.	
	
  .PARAMETER GroupName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parRCopyVVFromGroup
    LASTEDIT: 08/21/2015
    KEYWORDS: Remove-3parRCopyVVFromGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVname,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-3parRCopyVVFromGroup  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parRCopyVVFromGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parRCopyVVFromGroup   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopyvv -f "	
	if ($option)
	{
		$a = "pat","keepsnap","removevv"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting Remove-3parRCopyVVFromGroup   since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [  pat | keepsnap | removevv ]  can be used . "
		}
	}
	if ($VVname)
	{
		$cmd+=" $VVname "
	}
	else
	{
		Write-DebugLog "Stop: VVname is Mandate" $Debug
		return "Error :  -VVname is Mandate. "
	}
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+=" $GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Remove-3parRCopyVVFromGroup  GroupName in unavailable "
			Return "FAILURE : -GroupName $GroupName  is Unavailable to execute. "
		}	
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "		
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Remove-3parRCopyVVFromGroup  command removes a virtual volume from a remote-copy volume group.using cmd --> $cmd " "INFO:" 
	return "$Result"
} # End Remove-3parRCopyVVFromGroup 
#EndRegion
####################################################################################################################
## FUNCTION Remove-3parRCopyTargetFromGroup
####################################################################################################################
Function Remove-3parRCopyTargetFromGroup
{
<#
  .SYNOPSIS
   The Remove-3parRCopyTargetFromGroup removes a remote-copy target from a remote-copy volume group.
   
 .DESCRIPTION
   The Remove-3parRCopyTargetFromGroup removes a remote-copy target from a remote-copy volume group.
   
	.EXAMPLE
	Remove-3parRCopyTargetFromGroup -TargetName target1 -GroupName group1
   The following example removes target Target1 from Group1.
	
 .PARAMETER TargetName     
	The name of the target to be removed.
	
  .PARAMETER GroupName      
	The name of the group that currently includes the target.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Remove-3parRCopyTargetFromGroup
    LASTEDIT: 08/19/2015
    KEYWORDS: Remove-3parRCopyTargetFromGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$GroupName,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	Write-DebugLog "Start: In Remove-3parRCopyTargetFromGroup  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Remove-3parRCopyTargetFromGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Remove-3parRCopyTargetFromGroup   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopytarget -f "	
	if ($TargetName)
	{		
		$cmd+=" $TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "		
	}
	if ($GroupName)
	{
		$cmd1= "showrcopy"
		$Result1 = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd1
		if ($Result1 -match $GroupName )
		{
			$cmd+=" $GroupName "
		}
		else
		{
			Write-DebugLog "Stop: Exiting  Remove-3parRCopyTargetFromGroup  GroupName in unavailable "
			Return "FAILURE : -GroupName $GroupName  is Unavailable to execute. "
		}
	}
	else
	{
		Write-DebugLog "Stop: GroupName is Mandate" $Debug
		return "Error :  -GroupName is Mandate. "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Remove-3parRCopyTargetFromGroup removes a remote-copy target from a remote-copy volume group.using cmd --> $cmd " "INFO:" 
	return  "$Result"
} # End Remove-3parRCopyTargetFromGroup
####################################################################################################################
## FUNCTION Approve-3parRCopyLink 
###################################################################################################################
Function Approve-3parRCopyLink
{
<#
  .SYNOPSIS
    The  command adds one or more links (connections) to a remote-copy target system.
	
  .DESCRIPTION
    The  command adds one or more links (connections) to a remote-copy target system.  
  
  .EXAMPLE
  Approve-3parRCopyLink  -TargetName demo1 -N_S_P_IP 1:2:1:193.1.2.11
  This Example adds a link on System2 using the node, slot, and port information of node 1, slot 2, port 1 of the Ethernet port on the primary system. The IP address 193.1.2.11 specifies the address on the target system:
  
  .EXAMPLE
  Approve-3parRCopyLink  -TargetName System2 -N_S_P_WWN 5:3:2:1122112211221122
  This Example WWN creates an RCFC link to target System2, which connects to the local 5:3:2 (N:S:P) in the target system.
  
	
  .PARAMETER TargetName 
    Specify name of the TargetName to be updated.

  .PARAMETER N_S_P_IP
	Node number:Slot number:Port Number:IP Address of the Target to be created.
	
   .PARAMETER N_S_P_WWN
	Node number:Slot number:Port Number:World Wide Name (WWN) address on the target system.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Approve-3parRCopyLink   
    LASTEDIT: 07/22/2015
    KEYWORDS: Approve-3parRCopyLink 
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$TargetName,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$N_S_P_IP,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$N_S_P_WWN,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Approve-3parRCopyLink    - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Approve-3parRCopyLink    since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Approve-3parRCopyLink   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd = "admitrcopylink "
	if ($TargetName)
	{
		$cmd += "$TargetName "
	}
	else
	{
		Write-DebugLog "Stop: TargetName is Mandate" $Debug
		return "Error :  -TargetName is Mandate. "			
	}	
	if($N_S_P_IP)
	{
		if ($N_S_P_WWN)
		{
			return "Error : -N_S_P_WWN and -N_S_P_IP cannot be used simultaneously.  "
		}
		$s = $N_S_P_IP
		$s= [regex]::Replace($s,","," ")
		$cmd+="$s"
		$cmd1="yes"
	}
	if ($N_S_P_WWN)
	{
		if("yes" -eq $cmd1)
		{
			return "Error : -N_S_P_WWN and -N_S_P_IP cannot be used simultaneously.  "
		}
		$s = $N_S_P_WWN
		$s= [regex]::Replace($s,","," ")
		$cmd+="$s"	
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "Approve-3parRCopyLink  command adds one or more links (connections) to a remote-copy target system. cmd --> $cmd " "INFO:" 	
	return $Result	
} # End Approve-3parRCopyLink  
####################################################################################################################
## FUNCTION Get-3parHistRCopyVV
###################################################################################################################
Function Get-3parHistRCopyVV
{
<#
  .SYNOPSIS
   The Get-3parHistRCopyVV command shows a histogram of total remote-copy service times and backup system remote-copy service times in a timed loop.
	
  .DESCRIPTION
     The Get-3parHistRCopyVV command shows a histogram of total remote-copy service times and backup system 	remote-copy service times in a timed loop        
  
  .EXAMPLE
	Get-3parHistRCopyVV -iteration 1
		The Get-3parHistRCopyVV command shows a histogram of total remote-copy service iteration number of times
  
  .EXAMPLE
  Get-3parHistRCopyVV -option sync -iteration 1
	The Get-3parHistRCopyVV command shows a histogram of total remote-copy service iteration number of times
	with option sync
	
	.EXAMPLE	
	Get-3parHistRCopyVV -target name_vv1 -iteration 1
	The Get-3parHistRCopyVV command shows a histogram of total remote-copy service with specified target name.
	
	.EXAMPLE	
	Get-3parHistRCopyVV -group groupvv_1 -iteration   
	The Get-3parHistRCopyVV command shows a histogram of total remote-copy service with specified Group name.
	
  .PARAMETER option
		sync - Show only volumes that are being copied in synchronous mode.
		periodic- Show only volumes which are being copied in asynchronous periodic mode.
		primary - Show only virtual volumes in the primary role.
		secondary - Show only virtual volumes in the secondary role.
		targetsum - Displays the sums for all volumes of a target.
		portsum - Displays the sums for all volumes on a port.
		groupsum - Displays the sums for all volumes of a volume group.
		vvsum - Displays the sums for all targets and links of a virtual volume.
		domainsum - Displays the sums for all volumes of a domain.

 .PARAMETER interval 
    <secs>  Specifies the interval in seconds that statistics are sampled from using an integer from 1 through 2147483. If no count is specified, the  command defaults to 2 seconds. 
  .PARAMETER domain
	Shows only the virtual volumes that are in domains with names that match the specified domain name(s) or pattern(s).
	
  .PARAMETER target
   Shows only volumes whose group is copied to the specified target name or pattern. Multiple target names or patterns may be specified using a comma-separated list.
   
  .PARAMETER group
  Shows only volumes whose volume group matches the specified group name or pattern of names.
	Multiple group names or patterns may be specified using a comma-separated list.
  
 .PARAMETER iteration
  Specifies that the statistics are to stop after the indicated number of iterations using an integer from
	1 through 2147483647.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parHistRCopyVV
    LASTEDIT: 05/08/2015
    KEYWORDS: Get-3parHistRCopyVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,

		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VV_Name,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$interval,	
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$domain,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$group,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$target,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$iteration,		
		
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)	
	Write-DebugLog "Start: In Get-3parHistRCopyVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parHistRCopyVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parHistRCopyVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$Cmd = "histrcvv "
	if($option)	
	{
		$opt="async","sync","periodic","primary","secondary","targetsum","portsum","groupsum","vvsum","domainsum"
		$option = $option.toLower()
		if ($opt -eq $option)
		{
			$Cmd += " -$option "
		}
		else
		{
			return " FAILURE : -option $option is Not valid use [sync | periodic | primary | secondary | targetsum | portsum | groupsum | vvsum | domainsum ]  Only,  "
		}
	}
	if($interval)
	{
		$Cmd += " -d $interval"
	}
	if ($domain)
	{ 
		$Cmd += " -domain  $domain"
	}
	if ($group)
	{ 
		$Cmd += " -g $group"			
	}
	if ($target)
	{ 
		$Cmd += " -t $target"			
	}
	if ($VV_Name)
	{ 
		$Cmd += " $VV_Name"			
	}
	if ($iteration)
	{ 
		$Cmd += " -iter $iteration "			
	}	
	else
	{
		Write-DebugLog "Stop: Iteration is Mandate" $Debug
		return "Error :  -Iteration is Mandate. "		
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $Cmd
	write-debuglog " histograms sums for all synchronous remote - copy volumes $Cmd " "INFO:" 
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count
		if("vvsum" -eq $option){
		Add-Content -Path $tempfile -Value "VVname,RCGroup,Target,Mode,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date" 
		}
		elseif ("portsum" -eq $option) {
		Add-Content -Path $tempfile -Value "Link,Target,Type,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date"
		}
		elseif ("groupsum" -eq $option) {
		Add-Content -Path $tempfile -Value "Group,Target,Mode,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date"
		}
		elseif ("targetsum" -eq $option){
		Add-Content -Path $tempfile -Value "Target,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date"
		}
		elseif ("domainsum" -eq $option){
		Add-Content -Path $tempfile -Value "Domain,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date"
		}
		else {
		Add-Content -Path $tempfile -Value "VVname,RCGroup,Target,Mode,Port,Type,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date"
		}

		Add-Content -Path $tempfile -Value "VVname,RCGroup,Target,Mode,Port,Type,Svt_0.50,Svt_1,Svt_2,Svt_4,Svt_8,Svt_16,Svt_32,Svt_64,Svt_128,Svt_256,Rmt_0.50,Rmt_1,Rmt_2,Rmt_4,Rmt_8,Rmt_16,Rmt_32,Rmt_64,Rmt_128,Rmt_256,time,date"
		foreach ($s in  $Result[0..$LastItem] )
		{
			$s= [regex]::Replace($s,"^ +","")
			$s= [regex]::Replace($s," +"," ")
			$s= [regex]::Replace($s," ",",")
			if ($s -match "millisec"){
				$split1=$s.split(",")
				$global:time1 = $split1[0]
				$global:date1 = $split1[1]
				continue
			}
			$aa=$s.split(",").length
			write-host "value in aa $aa"
			$var2 = $aa[0]
			if ( "total" -eq $var2)
			{
				continue
			}	
			if (($s -match "----") -or ([string]::IsNullOrEmpty($s)) -or ($s -match "RCGroup"))
			{
				continue
			}	
			
			# Replace one or more spaces with comma to build CSV line
			$s +=",$global:time1,$global:date1"	
			Add-Content -Path $tempfile -Value $s
		}
		Import-Csv $tempFile
		del $tempFile
	}
	elseif($Result -match "No virtual volume")
	{ 
		Return "No data available"
	}
	else
	{
		return $Result
	}
} # End Get-3parHistRCopyVV

#####################################################################################
#   Function   UnProtect-String
#####################################################################################
function UnProtect-String($Encrypted)
{
[Byte[]] $key = (3,4,5,7,2,5,30,40,50,70,20,50,20,60,60,20)
$stringPASS=$Encrypted | ConvertTo-SecureString -Key $key
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($stringPASS)
$Pwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
return $pwd
 }
##end of Function  UnProtect-String


#####################################################################################
#   Function   Set-3parPoshSshConnectionUsingPasswordFile
#####################################################################################
Function Set-3parPoshSshConnectionUsingPasswordFile
{
<#
  .SYNOPSIS
    Creates a SAN Connection object using Encrypted password file
  
  .DESCRIPTION
	Creates a SAN Connection object using Encrypted password file.
    No connection is made by this cmdlet call, it merely builds the connection object. 
        
  .EXAMPLE
    Set-3parPoshSshConnectionUsingPasswordFile  -SANIPAddress 10.1.1.1 -SANUserName "3parUser" -epwdFile "C:\HP3PARepwdlogin.txt"
		Creates a SAN Connection object with the specified SANIPAddress and password file
		
  .PARAMETER SANIPAddress 
    Specify the SAN IP address.
    
  .PARAMETER SANUserName
  Specify the SAN UserName.
  
  .PARAMETER epwdFile 
    Specify the encrypted password file location , example “c:\hp3parstoreserv244.txt” To create encrypted password file use “New-3parSSHCONNECTION_PassFile” cmdlet           
	
  .Notes
    NAME:  Set-3parPoshSshConnectionUsingPasswordFile
    EDIT:0/06/2016
	LASTEDIT: 04/10/2017
    KEYWORDS: Set-3parPoshSshConnectionUsingPasswordFile
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #Requires HPE3par cli.exe 
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $SANIPAddress=$null,
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $SANUserName,
		[Parameter(Position=2, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile        
	) 
					
		try{			
			if( -not (Test-Path $epwdFile))
			{
				Write-DebugLog "Running: Path for HP3PAR encrypted password file  was not found. Now created new epwd file." "INFO:"
				return " Encrypted password file does not exist , create encrypted password file using 'Set-3parSSHConnectionPasswordFile' "
			}	
			
			Write-DebugLog "Running: Patch for HP3PAR encrypted password file ." "INFO:"
			
			$tempFile=$epwdFile			
			$Temp=import-CliXml $tempFile
			$pass=$temp[0]
			$ip=$temp[1]
			$user=$temp[2]
			if($ip -eq $SANIPAddress)  
			{
				if($user -eq $SANUserName)
				{
					$Passs = UnProtect-String $pass 
					#New-3parSSHConnection -SANUserName $SANUserName  -SANPassword $Passs -SANIPAddress $SANIPAddress -SSHDir "C:\plink"
					New-3ParPoshSshConnection -SANIPAddress $SANIPAddress -SANUserName $SANUserName -SANPassword $Passs

				}
				else
				{ 
					Return "Password file SANUserName $user and entered SANUserName $SANUserName dose not match  . "
					Write-DebugLog "Running: Password file SANUserName $user and entered SANUserName $SANUserName dose not match ." "INFO:"
				}
			}
			else 
			{
				Return  "Password file ip $ip and entered ip $SANIPAddress dose not match"
				Write-DebugLog "Password file ip $ip and entered ip $SANIPAddress dose not match." "INFO:"
			}
		}
		catch 
		{	
			$msg = "In function Set-3parPoshSshConnectionUsingPasswordFile. "
			$msg+= $_.Exception.ToString()	
			# Write-Exception function is used for exception logging so that it creates a separate exception log file.
			Write-Exception $msg -error		
			return "FAILURE : $msg"
		}
} #End Function   Set-3parPoshSshConnectionUsingPasswordFile

 
#####################################################################################
#   Function   Protect-String
#####################################################################################

Function Protect-String($String) 
{ 
    [Byte[]] $key = (3,4,5,7,2,5,30,40,50,70,20,50,20,60,60,20)
	$Password = $String | ConvertTo-SecureString -AsPlainText -Force
    return $Password | ConvertFrom-SecureString -key $Key 
} ## end of Function   Protect-String

######################################################################################################################
## FUNCTION Set-3parPoshSshConnectionPasswordFile
######################################################################################################################
Function Set-3parPoshSshConnectionPasswordFile
{
<#
  .SYNOPSIS
   Creates a encrypted password file on client machine to be used by "Set-3parPoshSshConnectionUsingPasswordFile"
  
  .DESCRIPTION
	Creates an encrypted password file on client machine
        
  .EXAMPLE
   Set-3parPoshSshConnectionPasswordFile -SANIPAddress "15.1.1.1" -SANUserName "3parDemoUser"  -$SANPassword "demoPass1"  -epwdFile "C:\hp3paradmepwd.txt"
	
	This examples stores the encrypted password file hp3paradmepwd.txt on client machine c:\ drive, subsequent commands uses this encryped password file ,
	This example authenticates the entered credentials if correct creates the password file.
  
  .PARAMETER SANUserName 
    Specify the SAN SANUserName .
    
  .PARAMETER SANIPAddress 
    Specify the SAN IP address.
    
  .PARAMETER SANPassword 
    Specify the Password with the Linked IP
  
  .PARAMETER epwdFile 
    Specify the file location to create encrypted password file
	
  .Notes
    NAME:   Set-3parPoshSshConnectionPasswordFile
    EDIT: 06/03/2016
	LASTEDIT: 04/10/2017
    KEYWORDS:  Set-3parPoshSshConnectionPasswordFile
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 2.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $SANIPAddress=$null,
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
		$SANUserName=$null,
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
		[System.String]
		$SANPassword=$null,
		
		[Parameter(Position=3, Mandatory=$true, ValueFromPipeline=$true)]
		[System.String]
        $epwdFile=$null
       
	)			
		# Check IP Address Format
		if(-not (Test-IPFormat $SANIPAddress))		
		{
			Write-DebugLog "Stop: Invalid IP Address $SANIPAddress" "ERR:"
			return "FAILURE : Invalid IP Address $SANIPAddress"
		}		
		
		Write-DebugLog "Running: Completed validating IP address format." $Debug		
		Write-DebugLog "Running: Authenticating credentials - for user $SANUserName and SANIP= $SANIPAddress" $Debug
		
		# Authenticate
		try
		{
			if(!($SANPassword))
			{				
				$securePasswordStr = Read-Host "SANPassword" -AsSecureString				
				$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $securePasswordStr)
				
				$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePasswordStr)
				$tempPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
			}
			else
			{				
				$tempstring  = convertto-securestring $SANPassword -asplaintext -force				
				$mycreds = New-Object System.Management.Automation.PSCredential ($SANUserName, $tempstring)	

				$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tempstring)
				$tempPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
			}			
			
			#$Session = New-SSHSession -ComputerName $SANIPAddress -Credential (Get-Credential $SANUserName)				
			$Session = New-SSHSession -ComputerName $SANIPAddress -Credential $mycreds		
			
			Write-DebugLog "Running: Executed . Check on PS console if there are any errors reported" $Debug
			if (!$Session)
			{
				return "FAILURE : In function Set-3parPoshSshConnectionPasswordFile."
			}
			else
			{
				$RemveResult = Remove-SSHSession -Index $Session.SessionId
			}
			
			$Enc_Pass = Protect-String $tempPwd 
			$Enc_Pass,$SANIPAddress,$SANUserName | Export-CliXml $epwdFile	
		}
		catch 
		{	
			$msg = "In function Set-3parPoshSshConnectionPasswordFile. "
			$msg+= $_.Exception.ToString()	
			
			Write-Exception $msg -error		
			return "FAILURE : $msg `n credentials incorrect"
		}

		Write-DebugLog "Running: HP3PAR System's encrypted password file has been created successfully and the file location is $epwdFile " "INFO:"
		return "`n SUCCESS : HP3PAR System's encrypted SANPassword file has been created successfully and the file location : $epwdFile"	

} #  End-of  Set-3parPoshSshConnectionPasswordFile

####################################################################################################################
## FUNCTION Update-3parVV
####################################################################################################################
Function Update-3parVV
{
<#
  .SYNOPSIS
   The Update-3parVV command increases the size of a virtual volume.
   
  .DESCRIPTION
   The Update-3parVV command increases the size of a virtual volume.
   
  .EXAMPLE
	Update-3parVV -VVname XYZ -Size 1g
	
  .PARAMETER VVname     
	The name of the volume to be grown.
	
  .PARAMETER Size       
	Specifies the size in MB to be added to the volume user space. The size must be an integer in the range from 1 to 16T.

  .PARAMETER Option       
	Suppresses the requested confirmation before growing a virtual volume size from under 2 T to over2 T.
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Update-3parVV
    LASTEDIT: 10/15/2015
    KEYWORDS: Update-3parVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVname ,		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Size ,						
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       )		
	Write-DebugLog "Start: In Update-3parVV  - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Update-3parVV   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Update-3parVV   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "growvv"
	if ($Option)
	{	
		$opt="f"
		$Option = $Option.toLower()
		if ($opt -eq $Option)
		{
			$cmd+=" -f "
		}
		else
		{
			return " FAILURE : -option $option is Not valid use [-f]  Only,  "
		}
	}
	if ($VVname)
	{		
		$cmd+=" $VVname "
	}
	else
	{
		Write-DebugLog "Stop: VVname  is Mandate" $Debug
		return "Error :  -VVname  is Mandate. "		
	}
	if ($Size)
	{
		$demo=$Size[-1]
		$de=" g | G | t | T "
		if($de -match $demo)
		{
			$cmd+=" $Size "
		}
		else
		{
			return "Error: -Size $Size is Invalid Try eg: 2G  "
		}
	}
	else
	{
		Write-DebugLog "Stop: Size  is Mandate" $Debug
		return "Error :  -Size  is Mandate. "
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Update-3parVV command increases the size of a virtual volume.--> $cmd " "INFO:" 
	return  $Result
} #End FUNCTION Update-3parVV


######################################################################################################################
## FUNCTION Compress-3parVV
######################################################################################################################
Function Compress-3parVV
{
<#
	.SYNOPSIS   
		The Compress-3parVV command is used to change the properties of a virtual volume that
    was created with the createvv command by associating it with a different CPG.
	
	.DESCRIPTION  
		The Compress-3parVV command is used to change the properties of a virtual volume that
    was created with the createvv command by associating it with a different CPG.
	
	.EXAMPLE	
		Compress-3parVV -SUBCommand usr_cpg -CPGName XYZ
	.EXAMPLE
		Compress-3parVV -SUBCommand usr_cpg -CPGName XYZ -VVName XYZ
	
	.EXAMPLE
		Compress-3parVV -SUBCommand usr_cpg -CPGName XYZ -Option XYZ -VVName XYZ
	
	.EXAMPLE
		Compress-3parVV -SUBCommand usr_cpg -CPGName XYZ -Option keepvv -KeepVVName XYZ -VVName XYZ
		
	.EXAMPLE
		Compress-3parVV -SUBCommand snp_cpg -CPGName XYZ -VVName XYZ
		
	.EXAMPLE
		Compress-3parVV -SUBCommand restart -Option XYZ -VVName XYZ
		
	.EXAMPLE
		Compress-3parVV -SUBCommand rollback -Option XYZ -VVName XYZ
		
	.PARAMETER Option 
		"waittask","dr","tpvv","tdvv","dedup","full","compr","keepvv","src_cpg","slth","slsz"
	
	.PARAMETER SUBCommand
			usr_cpg <cpg>
				Moves the logical disks being used for user space to the specified CPG.
			snp_cpg <cpg>
				Moves the logical disks being used for snapshot space to the specified
				CPG.
			restart
				Restarts a tunevv command call that was previously interrupted because
				of component failure, or because of user initiated cancellation. This
				cannot be used on TPVVs or TDVVs.
			rollback
				Returns to a previously issued tunevv operation call that was
				interrupted. The canceltask command needs to run before the rollback.
				This cannot be used on TPVVs or TDVVs.
	
	.PARAMETER CPGName
		 Indicates that only regions of the VV which are part of the the specified
        CPG should be tuned to the destination USR or SNP CPG.
	
	.PARAMETER VVName
		 Specifies the name of the existing virtual volume.
	
	.PARAMETER KeepVVName
		Indicates that the original logical disks should be saved under a new
        virtual volume with the given name.
	
	.PARAMETER Src_CpgName
		Indicates that only regions of the VV which are part of the the specified
        CPG should be tuned to the destination USR or SNP CPG.
	
	.PARAMETER ThreshoID
		 Slice threshold. Volumes above this size will be tuned in slices.
        <threshold> must be in multiples of 128GiB. Minimum is 128GiB.
        Default is 16TiB. Maximum is 16TiB.
	
	.PARAMETER Size
		 Slice size. Size of slice to use when volume size is greater than
        <threshold>. <size> must be in multiples of 128GiB. Minimum is 128GiB.
         Default is 2TiB. Maximum is 16TiB.
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Compress-3parVV
		LASTEDIT: 01/03/2017
		KEYWORDS: Compress-3parVV
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$SUBCommand ,		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
        $CPGName ,		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Option ,		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VVName ,	
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$KeepVVName ,
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
        $Src_CpgName ,
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
        $ThreshoID ,
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
        $Size ,
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Compress-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
         
	if ($SUBCommand)
	{
		if($SUBCommand -eq "usr_cpg")
		{	
			if ($CPGName)
			{	
				$cmd = "tunevv usr_cpg"			
				$cmd += " $CPGName"
				$cmd += " -f"
                
                if($Option)	
				{
					$opt="waittask","dr","tpvv","tdvv","dedup","full","compr","keepvv","src_cpg","slth","slsz"
					$Option = $Option.toLower()
					if ($opt -eq $Option)
					{
						$Cmd += " -$Option"
						if($Option -eq "keepvv")
						{
							$cmd += " $KeepVVName"
						}
						if($Option -eq "src_cpg")
						{
							$cmd += " $Src_CpgName"
						}
						if($Option -eq "slth")
						{
							$cmd += " $ThreshoID"
						}
						if($Option -eq "slsz")
						{
							$cmd += " $Size"
						}
					}
					else
					{
						return " FAILURE : -option $option is Not valid use [waittask | dr | tpvv | tdvv | dedup | full | compr | keepvv | src_cpg | slth | slsz]  Only,  "
					}
				}											
				if($VVName)
				{					
					$cmd += " $VVName"					
					$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
					write-debuglog "  executing Compress-3parVV for tuning virtual volume.--> $cmd " "INFO:" 
					return  "$Result"
				}
				else
				{
					write-debugLog "No VV Name specified for tuning virtual volume. Skip tuning virtual volume" "ERR:" 
					return "FAILURE : No VV name specified"
				}				
			}
			else
			{
				write-debugLog "No CPG Name specified for tune virtual volume. Skip tuning virtual volume" "ERR:" 
				return "FAILURE : No CPG name specified"
			}			
		}
        elseif($SUBCommand -eq "snp_cpg")
        {
            if ($CPGName)
			    {	
				    $cmd = "tunevv snp_cpg"			
				    $cmd += " $CPGName"
				    $cmd += " -f"
                
                    if($Option)	
	                    {
		                    $opt="waittask","dr","tpvv","tdvv","dedup","full","compr","keepvv","src_cpg","slth","slsz"
		                    $Option = $Option.toLower()
		                    if ($opt -eq $Option)
		                    {
			                    $Cmd += " -$Option"
								if($Option -eq "keepvv")
								{
									$cmd += " $KeepVVName"
								}
								if($Option -eq "src_cpg")
								{
									$cmd += " $Src_CpgName"
								}
								if($Option -eq "slth")
								{
									$cmd += " $ThreshoID"
								}
								if($Option -eq "slsz")
								{
									$cmd += " $Size"
								}
		                    }
		                    else
		                    {
			                    return " FAILURE : -option $option is Not valid use [waittask | dr | tpvv | tdvv | dedup | full | compr | keepvv | src_cpg | slth | slsz]  Only,  "
		                    }
	                    }	
							
				    if($VVName)
				    {					
					    $cmd += " $VVName"
					
					    $Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
					    write-debuglog "  executing Compress-3parVV for tuning virtual volume.--> $cmd " "INFO:" 
					    return  "$Result"
				    }
				    else
				    {
					    write-debugLog "No VV Name specified for tuning virtual volume. Skip tuning virtual volume" "ERR:" 
					    return "FAILURE : No VV name specified"
				    }				
			    }
			    else
			    {
				    write-debugLog "No CPG Name specified for tune virtual volume. Skip tuning virtual volume" "ERR:" 
				    return "FAILURE : No CPG name specified"
			    }
        }
		elseif($SUBCommand -eq "restart")
        {   
			if($VVName)
			{		
				$cmd = "tunevv restart"	
				$cmd += " -f"
			
				if($Option)	
					{
						$opt="waittask","dr"
						$Option = $Option.toLower()
						if ($opt -eq $Option)
						{
							$Cmd += " -$Option"
						}
						else
						{
							return " FAILURE : -option $option is Not valid use [waittask | dr]  Only,  "
						}
					}				
					$cmd += " $VVName"
				
					$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
					write-debuglog "  executing Compress-3parVV for tuning virtual volume.--> $cmd " "INFO:" 
					return  "$Result"
			}
			else
			{
				write-debugLog "No VV Name specified for tuning virtual volume. Skip tuning virtual volume" "ERR:" 
				return "FAILURE : No VV name specified"
			}	
        }
		elseif($SUBCommand -eq "rollback")
        {   
			if($VVName)
			{		
				$cmd = "tunevv rollback"	
				$cmd += " -f"
			
				if($Option)	
					{
						$opt="waittask","dr"
						$Option = $Option.toLower()
						if ($opt -eq $Option)
						{
							$Cmd += " -$Option"
						}
						else
						{
							return " FAILURE : -option $option is Not valid use [waittask | dr]  Only,  "
						}
					}				
					$cmd += " $VVName"
				
					$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
					write-debuglog "  executing Compress-3parVV for tuning virtual volume.--> $cmd " "INFO:" 
					return  "$Result"
			}
			else
			{
				write-debugLog "No VV Name specified for tuning virtual volume. Skip tuning virtual volume" "ERR:" 
				return "FAILURE : No VV name specified"
			}	
        }
		else		
		{
			return "FAILURE : Sub Command should be [usr_cpg | snp_cpg | restart | rollback]"
		}
	}
	else
	{
		write-debugLog "Sub Command is missing. Skip tuning virtual volume" "ERR:"
		Get-help Compress-3parVV
		return	
	}

} ##  End-of  Compress-3parVV 

######################################################################################################################
## FUNCTION Test-3parVV
######################################################################################################################
Function Test-3parVV
{
<#
  .SYNOPSIS
	The checkvv command executes validity checks of VV administration information in the event of an uncontrolled system shutdown and optionally repairs corrupted virtual volumes.   
   
  .DESCRIPTION
	The checkvv command executes validity checks of VV administration information in the event of an uncontrolled system shutdown
    and optionally repairs corrupted virtual volumes.
   
  .EXAMPLE
	Test-3parVV -VVName XYZ

  .EXAMPLE
	Test-3parVV -Option XYZ -VVName XYZ
	
  .PARAMETER Option 

    -y|-n
        Specifies that if errors are found they are either modified so they are valid (-y) or left unmodified (-n). If not specified, errors are left
        unmodified (-n).

    -offline
        Specifies that VVs specified by <VV_name> be offlined before validating the VV administration information. The entire VV tree will be
        offlined if this option is specified.

    -f
        Specifies that the command is forced. If this option is not used, the
        command requires confirmation before proceeding with its operation.

    -dedup_dryrun
        Launches a dedup ratio calculation task in the background that analyzes
        the potential space savings with HPE 3PAR Deduplication technology if the
        VVs specified were in a same deduplication group. The VVs specified
        can be TPVVs, compressed VVs and fully provisioned volumes.

    -compr_dryrun
        Launches a compression ratio calculation task in the background that analyzes
        the potential space savings with HPE 3PAR Compression technology of specified
        VVs. Specified volumes can be TPVVs, TDVVs, fully provisioned volumes
        and snapshots.

    -dedup_compr_dryrun
        Launches background space estimation task that analyzes the overall
        savings of converting the specified VVs into a compressed TDVVs.
        Specified volumes can be TPVVs, TDVVs, compressed TPVVs, fully
        provisioned volumes, and snapshots.

        This task will display compression and total savings ratios on a per-VV
        basis, and the dedup ratio will be calculated on a group basis of input VVs.  
	
	
  .PARAMETER VVName       
		Requests that the integrity of the specified VV is checked. This
        specifier can be repeated to execute validity checks on multiple VVs.
        Only base VVs are allowed.

	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: Test-3parVV  
    LASTEDIT: 05/01/2017
    KEYWORDS: Test-3parVV 
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,	
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$VVName ,	
		
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Test-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($VVName)
	{		
		$cmd = "checkvv"	
			
		if($Option)	
			{
				$opt="y","n","offline","f","dedup_dryrun","compr_dryrun","dedup_compr_dryrun"
				$Option = $Option.toLower()
				if ($opt -eq $Option)
				{
					$Cmd += " -$Option"
					if($Option -eq "dedup_dryrun" -Or $Option -eq "compr_dryrun" -Or $Option -eq "dedup_compr_dryrun")
					{
						$Cmd+= " -f"						
					}
				}
				else
				{
					return " FAILURE : -option $option is Not valid use [y | n | offline | f | dedup_dryrun | compr_dryrun | dedup_compr_dryrun]  Only,"
				}
			}			
		$cmd += " $VVName"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
		write-debuglog "  executing Test-3parVV Command.--> $cmd " "INFO:" 
		return  "$Result"
	}
	else
	{
		write-debugLog "No VV Name specified ." "ERR:" 
		return "FAILURE : No VV name specified"
	}       
	

} ##  End-of  Test-3parVV

######################################################################################################################
## FUNCTION Add-3parVV
######################################################################################################################
Function Add-3parVV
{
<#
  .SYNOPSIS
   The Add-3parVV command creates and admits remotely exported virtual volume definitions to enable the migration of these volumes. The newly created
   volume will have the WWN of the underlying remote volume.
   
  .DESCRIPTION
   The Add-3parVV command creates and admits remotely exported virtual volume definitions to enable the migration of these volumes. The newly created
   volume will have the WWN of the underlying remote volume.
   
  .EXAMPLE
	Add-3parVV -VV_WWN XYZ
	Specifies the World Wide Name (WWN) of the remote volumes to be admitted.

  .EXAMPLE
	Add-3parVV -Option XYZ -DomainName XYZ -VV_WWN XYZ
	 Create the admitted volume in the specified domain. The default is to create it in the current domain, or no domain if the current domain is not set.
	
  .PARAMETER Option	
	DomainName
	
  .PARAMETER DomainName
	Create the admitted volume in the specified domain   

  .PARAMETER VV_WWN
	Specifies the World Wide Name (WWN) of the remote volumes to be admitted.

  .PARAMETER VV_WWN_NewWWN 
	 Specifies the World Wide Name (WWN) for the local copy of the remote volume. If the keyword "auto" is specified the system automatically generates a WWN for the virtual volume
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Add-3parVV
    LASTEDIT: 1/1/2017
    KEYWORDS: Add-3parVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$DomainName ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$VV_WWN ,

		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$VV_WWN_NewWWN ,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Add-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($VV_WWN -Or $VV_WWN_NewWWN)
	{		
		$cmd = "admitvv"			
		if($Option)	
		{
			$opt="domain"
			$Option = $Option.toLower()
			if ($opt -eq $Option)
			{
				$Cmd += " -$Option"
				if($DomainName)
				{
					$Cmd+= " $DomainName"						
				}
			}
			else
			{
				return " FAILURE : Invalid option $option Please use [domain] Only,"
			}
		}
		if($VV_WWN)	
		{
			$cmd += " $VV_WWN"
			$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
			write-debuglog "  executing Add-3parVV Command.--> $cmd " "INFO:" 
			return  "$Result"
		}
		if($VV_WWN_NewWWN)	
		{
			$cmd += " $VV_WWN_NewWWN"
			$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
			write-debuglog "  executing Add-3parVV Command.--> $cmd " "INFO:" 
			return  "$Result"
		}		
	}
	else
	{
		write-debugLog "No VV_WWN Name specified ." "ERR:" 
		return "FAILURE : No VV_WWN name specified"
	}
} ##  End-of  Add-3parVV 
######################################################################################################################
## FUNCTION New-3parFed
######################################################################################################################
Function New-3parFed
{
<#
  .SYNOPSIS
   The createfed command generates a UUID for the named Federation and makes the StoreServ system a member of that Federation.
   
  .DESCRIPTION
   The createfed command generates a UUID for the named Federation
    and makes the StoreServ system a member of that Federation.
   
  .EXAMPLE
	New-3parFed -Fedname XYZ
	
  .EXAMPLE
	New-3parFed -Option comment – CommentString XYZ -Fedname XYZ
	
  .EXAMPLE
	New-3parFed -Option setkv -KeyValue TETS -Fedname XYZ

  .EXAMPLE
	New-3parFed -Option setkvifnotset -KeyValue TETS -Fedname XYZ
	
  .PARAMETER Option 
	-comment <comment string>
        Specifies any additional textual information.

    -setkv <key>=<value>[,<key>=<value>...]
        Sets or resets key/value pairs on the federation.
        <key> is a string of alphanumeric characters.
        <value> is a string of characters other than "=", "," or ".".

        This option may be repeated on the command line.

    -setkvifnotset <key>=<value>[,<key>=<value>...]
        Sets key/value pairs on the federation if not already set.
        A key/value pair is not reset on a federation if it already
        exists.
		
	.PARAMETER CommentString
		Specifies any additional textual information
		
	.PARAMETER KeyValue
		Sets or resets key/value pairs on the federation.
		
	.PARAMETER Fedname
		Specifies the name of the Federation to be created.
        The name must be between 1 and 31 characters in length
        and must contain only letters, digits, or punctuation
        characters '_', '-', or '.'
	
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME: New-3parFed  
    LASTEDIT: 01/03/2017
    KEYWORDS: New-3parFed 
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$CommentString ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$KeyValue ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Fedname ,
				
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In New-3parFed - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($Fedname)
	{		
		$cmd = "createfed"			
		if($Option)	
		{
			$opt="comment","setkv","setkvifnotset"
			$Option = $Option.toLower()
			if ($opt -eq $Option)
			{
				$Cmd += " -$Option"
				if($CommentString)
				{
					$Cmd+= " $CommentString"						
				}
				if($KeyValue)
				{
					$Cmd+= " $KeyValue"						
				}
			}
			else
			{
				return " FAILURE : Invalid option $option ,Please use [comment | setkv | setkvifnotset] Only,"
			}
		}
		
		$cmd += " $Fedname"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
		write-debuglog "  executing New-3parFed Command.--> $cmd " "INFO:" 
		return  "$Result"				
	}
	else
	{
		write-debugLog "No Federation Name specified ." "ERR:" 
		return "FAILURE : No Federation name specified"
	}
} ##  End-of  New-3parFed 

######################################################################################################################
## FUNCTION Join-3parFed
######################################################################################################################
Function Join-3parFed
{
<#
	.SYNOPSIS  
		The joinfed command makes the StoreServ system a member of the Federation identified by the specified name and UUID.
   
	.DESCRIPTION
		The joinfed command makes the StoreServ system a member
    of the Federation identified by the specified name and UUID.
   
	.EXAMPLE
		Join-3parFed -FedName test -UUID 12345
	
	.EXAMPLE
		Join-3parFed -Option comment  -CommentString hello -UUID 12345
		
	.EXAMPLE
		Join-3parFed -Option comment  -CommentString hello -UUID 12345 -FedName test
		
	.EXAMPLE
		Join-3parFed -Option setkv  -KeyValue 12  -UUID 12345 -FedName test
		
	.EXAMPLE
		Join-3parFed -Option setkvifnotset  -KeyValue 12  -UUID 12345 -FedName test
			
	.PARAMETER Option 
		 -comment <comment string>
        Specifies any additional textual information.

		-setkv <key>=<value>[,<key>=<value>...]
        Sets or resets key/value pairs on the federation.
        <key> is a string of alphanumeric characters.
        <value> is a string of characters other than "=", "," or ".".

        This option may be repeated on the command line.

		-setkvifnotset <key>=<value>[,<key>=<value>...]
        Sets key/value pairs on the federation if not already set.
        A key/value pair is not reset on a federation if it already
        exists.  If a key already exists, it is not treated as an error
        and the value is left as it is.

	.PARAMETER UUID
		Specifies the UUID of the Federation to be joined.

	.PARAMETER FedName
		Specifies the name of the Federation to be joined.

	.PARAMETER CommentString
		Specifies any additional textual information.

	.PARAMETER KeyValue
		Sets key/value pairs on the federation if not already set.
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Join-3parFed  
		LASTEDIT: 01/03/2017
		KEYWORDS: Join-3parFed
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$UUID ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$FedName ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$CommentString ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$KeyValue ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Join-3parFed - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($FedName -Or $UUID)
	{		
		$cmd = "joinfed"			
		if($Option)	
		{
			$opt="comment","setkv","setkvifnotset"
			$Option = $Option.toLower()
			if ($opt -eq $Option)
			{
				$Cmd += " -$Option"
				if($opt -eq "comment")
				{
					$Cmd+= " $CommentString"						
				}
				if($opt -eq "setkv" )
				{
					$Cmd+= " $KeyValue"						
				}
				if($opt -eq "setkvifnotset")
				{
					$Cmd+= " $KeyValue"
				}
			}
			else
			{
				return " FAILURE : Invalid option $option ,Please use [comment | setkv | setkvifnotset] Only,"
			}
		}		
		$cmd += " $FedName $UUID"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
		write-debuglog "  executing Join-3parFed Command.--> $cmd " "INFO:" 
		return  "$Result"				
	}
	else
	{
		write-debugLog "No Federation Name or UUID specified ." "ERR:" 
		return "FAILURE : No Federation name specified"
	}
} ##  End-of  Join-3parFed 

######################################################################################################################
## FUNCTION Set-3parFed
######################################################################################################################
Function Set-3parFed
{
<#
	.SYNOPSIS
		 The Set-3parFed command modifies name, comment, or key/value attributes of the Federation of which the StoreServ system is member.
   
	.DESCRIPTION 
		 The Set-3parFed command modifies name, comment, or key/value attributes of the Federation of which the StoreServ system is member.
   
	.EXAMPLE
		Set-3parFed -Option name -FedName test
	
	.EXAMPLE
		Set-3parFed -Option comment -CommentString hello
		
	.EXAMPLE
		Set-3parFed -Option setkv -KeyValue test
	
	.EXAMPLE
		Set-3parFed -Option clrkey -Key 1
		
	.PARAMETER Option 
	
		-name <fedname>
			Specifies the new name of the Federation.
			The name must be between 1 and 31 characters in length
			and must contain only letters, digits, or punctuation
			characters '_', '-', or '.'

		-comment <comment string>
			Specifies any additional textual information.

		-setkv <key>=<value>[,<key>=<value>...]
			Sets or resets key/value pairs on the federation.
			<key> is a string of alphanumeric characters.
			<value> is a string of characters other than "=", "," or ".".

			This option may be repeated on the command line.

		-setkvifnotset <key>=<value>[,<key>=<value>...]
			Sets key/value pairs on the federation if not already set.
			A key/value pair is not reset on a federation if it already
			exists.  If a key already exists, it is not treated as an error
			and the value is left as it is.

			This option may be repeated on the command line.

		-clrallkeys
			Clears all key/value pairs on the federation.

		-clrkey <key>[,<key>...]
			Clears key/value pairs, regardless of the value.
			If a specified key does not exist, this is not
			treated as an error.

			This option may be repeated on the command line.

		-clrkv <key>=<value>[,<key>=<value>...]
			Clears key/value pairs only if the value matches the given key.
			Mismatches or keys that do not exist are not treated as errors.

			This option may be repeated on the command line.

		-ifkv <key>=<value>[,<key>=<value>...]
			Checks whether given key/value pairs exist. If not, any subsequent
			key/value options on the command line will be ignored for the
			federation.
			
	.PARAMETER FedName
		 Specifies the new name of the Federation.

	.PARAMETER CommentString
		 Specifies any additional textual information.

	.PARAMETER KeyValue
		 Sets or resets key/value pairs on the federation.
		 
	.PARAMETER Key
		 Clears key/value pairs, regardless of the value.
		 
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Set-3parFed  
		LASTEDIT: 01/03/2017
		KEYWORDS: Set-3parFed
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$FedName ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$CommentString ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$KeyValue ,	
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$Key ,
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Set-3parFed - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	if($Option)	
	{
		$cmd = "setfed"		
		$opt="name","comment","setkv","setkvifnotset","clrallkeys","clrkey","clrkv","ifkv"
		$Option = $Option.toLower()
		if ($opt -eq $Option)
		{
			$Cmd += " -$Option"
			if($Option -eq "name")
			{
				$Cmd+= " $FedName"						
			}
			if($Option -eq "comment")
			{
				$Cmd+= " $CommentString"						
			}
			if($Option -eq "setkv" -Or $Option -eq "setkvifnotset" -Or $Option -eq "clrkv" -Or $Option -eq "ifkv")
			{
				$Cmd+= " $KeyValue"						
			}
			if($Option -eq "clrkey")
			{
				$Cmd+= " $Key"						
			}
		}
		else
		{
			return " FAILURE : Invalid option $option ,Please use [name | comment | setkv | setkvifnotset | clrallkeys | clrkey | clrkv | ifkv] Only,"
		}
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
		write-debuglog "  executing Set-3parFed Command.--> $cmd " "INFO:" 
		return  $Result
	}
	else
	{
		write-debugLog "At least one option must be specified ." "ERR:" 
		return "FAILURE : At least one option must be specified"
	}
} ##  End-of  Set-3parFed 


######################################################################################################################
## FUNCTION Remove-3parFed
######################################################################################################################
Function Remove-3parFed
{
<#
	.SYNOPSIS
			The removefed command removes the StoreServ system from Federation membership.
   
	.DESCRIPTION 
		The removefed command removes the StoreServ system from Federation membership.
   
	.EXAMPLE	
		Remove-3parFed	
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Remove-3parFed  
		LASTEDIT: 01/03/2017
		KEYWORDS: Remove-3parFed
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Remove-3parFed - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd = " removefed -f"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Remove-3parFed Command.--> $cmd " "INFO:" 
	return  "$Result"				
	
} ##  End-of  Remove-3parFed 

######################################################################################################################
## FUNCTION Show-3parFed
######################################################################################################################
Function Show-3parFed
{
<#
	.SYNOPSIS 
		The showfed command displays the name, UUID, and comment of the Federation of which the StoreServ system is member.
   
	.DESCRIPTION 
		The showfed command displays the name, UUID, and comment
    of the Federation of which the StoreServ system is member.
   
	.EXAMPLE	
		Show-3parFed	
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parFed  
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parFed
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Show-3parFed - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd = " showfed"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Show-3parFed Command.--> $cmd " "INFO:"
	$tempFile = [IO.Path]::GetTempFileName()
	$LastItem = $Result.Count  
	#Write-Host " Result Count =" $Result.Count
	foreach ($s in  $Result[0..$LastItem] )
	{		
		$s= [regex]::Replace($s,"^ ","")			
		$s= [regex]::Replace($s," +",",")	
		$s= [regex]::Replace($s,"-","")
		$s= $s.Trim() 	
		Add-Content -Path $tempfile -Value $s
		#Write-Host	" First if statement $s"		
	}
	Import-Csv $tempFile 
	del $tempFile
	if($Result -match "Name")
	{	
		return  " SUCCESS : EXECUTING Show-3parFed "		
	}
	else
	{
		return $Result		 		
	}		
	
} ##  End-of  Show-3parFed 

######################################################################################################################
## FUNCTION Show-3parPeer
######################################################################################################################
Function Show-3parPeer
{
<#
	.SYNOPSIS   
		The Show-3parPeer command displays the arrays connected through the host ports or peer ports over the same fabric.
		
	.DESCRIPTION  
		The Show-3parPeer command displays the arrays connected through the
    host ports or peer ports over the same fabric. The Type field
    specifies the connectivity type with the array. The Type value
    of Slave means the array is acting as a source, the Type value
    of Master means the array is acting as a destination, the type
    value of Peer means the array is acting as both source and
    destination.
   
	.EXAMPLE	
		Show-3parPeer
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parPeer
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parPeer
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Show-3parPeer - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd = " showpeer"
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing Show-3parPeer Command.--> $cmd " "INFO:"
	if($Result -match "No peers")
	{
		return $Result
	}
	else
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count  
		#Write-Host " Result Count =" $Result.Count
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")	
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s
			#Write-Host	" First if statement $s"		
		}
		Import-Csv $tempFile 
		del $tempFile
	}
	if($Result -match "No peers")
	{	
		return $Result			
	}
	else
	{
		return  " SUCCESS : EXECUTING Show-3parPeer "			 		
	}		
	
} ##  End-of  Show-3parPeer 

######################################################################################################################
## FUNCTION Import-3parVV
######################################################################################################################
Function Import-3parVV
{
<#
	.SYNOPSIS
		The importvv command starts migrating the data from a remote LUN to the local HPE 3PAR Storage System. The remote LUN should have been prepared using the
     admitvv command.
   
	.DESCRIPTION  
		The importvv command starts migrating the data from a remote LUN to the local HPE 3PAR Storage System. The remote LUN should have been prepared using the
     admitvv command.
   
	.EXAMPLE
		Import-3parVV -Usrcpg XYZ
	
	.EXAMPLE
		Import-3parVV -Usrcpg XYZ -VVName XYZ
		
	.EXAMPLE
		Import-3parVV -Option XYZ -Usrcpg XYZ -VVName XYZ
		
	.EXAMPLE
		Import-3parVV -Option XYZ -Snapname XYZ -Usrcpg XYZ -VVName XYZ
	
	.EXAMPLE
		Import-3parVV -Option XYZ -High_Med_Low XYZ -Usrcpg XYZ -VVName XYZ
		
	.EXAMPLE
		Import-3parVV -Option XYZ -Job_ID XYZ -Usrcpg XYZ -VVName XYZ
		
	.PARAMETER Option 
		Supported Options are "snap","snp_cpg","nocons","pri","jobid","notask","clrsrc","tpvv","tdvv","dedup","compr","minalloc"
		
		-snap <snapname>
        Create a snapshot of the volume at the end of the import phase.
		
		-snp_cpg <snp_cpg>
        Specifies the name of the CPG from which the snapshot space will be
        allocated.
		
		-nocons
        Any VV sets specified will not be imported as consistent groups.
        Allows multiple VV sets to be specified.

        If the VV set contains any VV members that in a previous import
        attempt were imported consistently, they will continue to get
        imported consistently.

    -pri <high|med|low>
        Specifies the priority of migration of a volume or a volume set. If
        this option is not specified, the default priority will be medium.
        The volumes with priority set to high will migrate faster than other
        volumes with medium and low priority.

    -jobid <Job_ID>
        Specifies the Job ID up to 511 characters for the volume. The Job ID
        will be tagged in the events that are posted during volume migration.
        Use -jobid "" to remove the Job ID.

    -notask
        Performs import related pre-processing which results in transitioning
        the volume to exclusive state and setting up of the "consistent" flag
        on the volume if importing consistently. The import task will not be
        created, and hence volume migration will not happen. The "importvv"
        command should be rerun on the volume at a later point of time without
        specifying the -notask option to initiate the actual migration of the
        volume. With the -notask option, other options namely -tpvv, -dedup,
        -compr, -snp_cpg, -snap, -clrsrc, -jobid and -pri cannot be specified.

    -clrsrc
        Performs cleanup on source array after successful migration of the
        volume. As part of the cleanup, any exports of the source volume will be
        removed, the source volume will be removed from all of the VV sets it
        is member of, the VV sets will be removed if the source volume is their
        only member, all of the snapshots of source volume will be removed,
        and finally the source volume itself will be removed. The -clrsrc
        option is valid only when the source array is running HPE 3PAR OS release
        3.2.2 or higher. The cleanup will not be performed if the source volume
        has any snapshots that have VLUN exports.

    The following options can be used when creating thinly provisioned volumes:

    -tpvv
        Import the VV into a thinly provisioned space in the CPG specified
        in the command line. The import will enable zero detect for the duration
        of import so that the data blocks containing zero do not occupy
        space on the new array.

    -tdvv
        This option is deprecated, see -dedup.

    -dedup
        Import the VV into a thinly provisioned space in the CPG specified in
        the command line. This volume will share logical disk space with other
        instances of this volume type created from the same CPG to store
        identical data blocks for space saving.

    -compr
        Import the VV into a compressed virtual volume in the CPG specified
        in the command line.

    -minalloc <size>
        This option specifies the default allocation size (in MB) to be set for TPVVs and TDVVs.


	.PARAMETER Snapname
		 Create a snapshot of the volume at the end of the import phase

	.PARAMETER Snp_cpg
		 Specifies the name of the CPG from which the snapshot space will be allocated.
		 
	.PARAMETER Usrcpg
		 Specifies the name of the CPG from which the volume user space will be allocated.

	.PARAMETER High_Med_Low
		Specifies the priority of migration of a volume or a volume set.

	.PARAMETER Job_ID
		Specifies the Job ID up to 511 characters for the volume.
		
	.PARAMETER VVName
		 Specifies the VVs with the specified name 
		 
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Import-3parVV  
		LASTEDIT: 01/03/2017
		KEYWORDS: Import-3parVV 
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option ,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Snapname ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Snp_cpg ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$Usrcpg ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$High_Med_Low ,
		
		[Parameter(Position=5, Mandatory=$false)]
		[System.String]
		$Job_ID ,
		
		[Parameter(Position=6, Mandatory=$false)]
		[System.String]
		$Size ,
		
		[Parameter(Position=7, Mandatory=$false)]
		[System.String]
		$VVName ,
				
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection        
	)		
	
	Write-DebugLog "Start: In Import-3parVV - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting New-3parVV since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting New-3parVV since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli -SANConnection $SANConnection
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}
	if($Usrcpg)
	{		
		$cmd = "importvv -f"			
		if($Option)	
		{
			$opt="snap","snp_cpg","nocons","pri","jobid","notask","clrsrc","tpvv","tdvv","dedup","compr","minalloc"
			$Option = $Option.toLower()
			if ($opt -eq $Option)
			{
				$Cmd += " -$Option"
				if($Option -eq "snap")
				{
					$Cmd+= " $Snapname"						
				}	
				if($Option -eq "snp_cpg")
				{
					$Cmd+= " $Snp_cpg"						
				}
				if($Option -eq "pri")
				{
					$Cmd+= " $High_Med_Low"						
				}
				if($Option -eq "jobid")
				{
					$Cmd+= " $Job_ID"						
				}
				if($Option -eq "minalloc")
				{
					$Cmd+= " $Size"						
				}
			}
			else
			{
				return " FAILURE : Invalid option $option ,Please use [snap | snp_cpg | nocons | pri | jobid | notask | clrsrc | tpvv | tdvv | dedup | compr | minalloc] Only,"
			}
		}		
		$cmd += " $Usrcpg"
		if($VVName)
		{
			$cmd += " $VVName"
		}
		#write-host "$cmd"
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
		write-debuglog "  executing Import-3parVV Command.--> $cmd " "INFO:" 
		return  "$Result"				
	}
	else
	{
		write-debugLog "No CPG Name specified ." "ERR:" 
		return "FAILURE : No CPG Name specified ."
	}
} ##  End-of  Import-3parVV 

######################################################################################################################
## FUNCTION Close-3PARConnection
######################################################################################################################
Function Close-3PARConnection
{
<#
  .SYNOPSIS   
   Session Management Command to close the connection
   
  .DESCRIPTION
   Session Management Command to close the connection
   
  .EXAMPLE
	Close-3PARConnection
		
  .Notes
    NAME: Close-3PARConnection  
    LASTEDIT: 05/01/2017
    KEYWORDS: Close-3PARConnection 
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
	$global:SANConnection = $null
	#write-host "$global:SANConnection"
	$SANConnection = $global:SANConnection
	#write-host "$SANConnection"
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		#write-host "$Validate1"
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			#write-host "$Validate2"
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parUserConnection since SAN connection object values are null/empty" $Debug
				return "Success : Exiting SAN connection session End"
			}
		}
	}	
} # End Function Close-3PARConnection

####################################################################################################################
## FUNCTION Show-3parISCSISession
####################################################################################################################
Function Show-3parISCSISession
{
<#
	.SYNOPSIS
		 The showiscsisession command shows the iSCSI sessions.
   
	.DESCRIPTION  
		 The showiscsisession command shows the iSCSI sessions.
   
	.EXAMPLE
		Show-3parISCSISession
		
	.EXAMPLE
		Show-3parISCSISession -NSP 1:2:1
		
	.EXAMPLE
		Show-3parISCSISession -option d -NSP 1:2:1
		
	.PARAMETER Option 
		-d
        Specifies that more detailed information about the iSCSI session is
        displayed. If this option is not used, then only summary information
        about the iSCSI session is displayed.

        -state
        Specifies the connection state of current iSCSI sessions.
        If this option is not used, then only summary information about
        the iSCSI session is displayed.
	
	.PARAMETER NSP
		Requests that information for a specified port is displayed.
	 
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parISCSISession
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parISCSISession
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,

		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$NSP ,
			
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3parISCSISession   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3parISCSISession   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3parISCSISession   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "showiscsisession "	
	if ($option)
	{
		$a = "d","state"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Show-3parISCSISession   since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [d | state]  can be used . "
		}
	}
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3parISCSISession command that displays iSCSI ports in the system --> $cmd" "INFO:"
	if($Result -match "total")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -2 		
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s
			#Write-Host	" only else statement"		
		}			
		Import-Csv $tempFile 
		del $tempFile
	}
	if($Result -match "total")	
	{
		return  " SUCCESS : EXECUTING Show-3parISCSISession"
	}
	else
	{			
		return  $Result
	}
	
} # End Show-3parISCSISession

####################################################################################################################
## FUNCTION Show-3parPortARP
####################################################################################################################
Function Show-3parPortARP
{
<#
	.SYNOPSIS   
		The Show-3parPortARP command shows the ARP table for iSCSI ports in the system.
		
	.DESCRIPTION  
		The Show-3parPortARP command shows the ARP table for iSCSI ports in the system.
		
	.EXAMPLE
		Show-3parPortARP 
		
	.EXAMPLE
		Show-3parPortARP -NSP 1:2:3
		
	.PARAMETER NSP
		Specifies the port for which information about devices on that port are displayed.

	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parPortARP
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parPortARP
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$NSP ,
			
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3parPortARP   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3parPortARP   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3parPortARP   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "showportarp "	
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3parPortARP command that displays information ARP table for iSCSI ports in the system --> $cmd" "INFO:"
	if($Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 		
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s				
		}			
		Import-Csv $tempFile 
		del $tempFile
	}	
	else
	{
		return $Result
	}
	if($Result.Count -gt 1)
	{
		return  " SUCCESS : EXECUTING Show-3parPortARP"				
	}
	else
	{			
		return  $Result
	}
	
} # End Show-3parPortARP

####################################################################################################################
## FUNCTION Show-3parPortISNS
####################################################################################################################
Function Show-3parPortISNS
{
<#
	.SYNOPSIS   
		The Show-3parPortISNS command shows iSNS host information for iSCSI ports in the system.
		
	.DESCRIPTION 
		The Show-3parPortISNS command shows iSNS host information for iSCSI ports in the
    system.
   
	.EXAMPLE	
		Show-3parPortISNS
		
	.EXAMPLE	
		Show-3parPortISNS -NSP 1:2:3
		
	.PARAMETER NSP
		 Specifies the port for which information about devices on that port are
        displayed.
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parPortISNS
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parPortISNS
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$NSP ,
			
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3parPortISNS   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3parPortISNS   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3parPortISNS   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "showportisns "	
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3parPortISNS command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"
	if($Result -match "N:S:P")
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -2 		
		foreach ($s in  $Result[0..$LastItem] )
		{		
			$s= [regex]::Replace($s,"^ ","")			
			$s= [regex]::Replace($s," +",",")
			$s= [regex]::Replace($s,"-","")
			$s= $s.Trim() 	
			Add-Content -Path $tempfile -Value $s				
		}			
		Import-Csv $tempFile 
		del $tempFile
	}
	if($Result -match "N:S:P")
	{
		return  " SUCCESS : EXECUTING Show-3parPortISNS"
	}
	else
	{			
		return  $Result
	}
	
} # End Show-3parPortISNS

####################################################################################################################
## FUNCTION Start-3parFSNDMP
####################################################################################################################
Function Start-3parFSNDMP
{
<#
	.SYNOPSIS   
		The Start-3parFSNDMP command is used to start both NDMP service and ISCSI
    service. 
	
	.DESCRIPTION  
		The Start-3parFSNDMP command is used to start both NDMP service and ISCSI
    service.
	
	.EXAMPLE	
		Start-3parFSNDMP
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Start-3parFSNDMP
		LASTEDIT: 01/03/2017
		KEYWORDS: Start-3parFSNDMP
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
			
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Start-3parFSNDMP   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Start-3parFSNDMP   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Start-3parFSNDMP   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "startfsndmp "	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Start-3parFSNDMP command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"	
	if($Result)
	{
		return  " SUCCESS : EXECUTING Start-3parFSNDMP"		
	}
	else
	{
		return "FAILURE : While Executing Start-3parFSNDMP $Result"
	}
	
} # End Start-3parFSNDMP

####################################################################################################################
## FUNCTION Stop-3parFSNDMP
####################################################################################################################
Function Stop-3parFSNDMP
{
<#
	.SYNOPSIS   
		The Stop-3parFSNDMP command is used to stop both NDMP service and ISCSI
    service.
	
	.DESCRIPTION  
		The Stop-3parFSNDMP command is used to stop both NDMP service and ISCSI
    service.
	
	.EXAMPLE	
		Stop-3parFSNDMP	
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Stop-3parFSNDMP
		LASTEDIT: 01/03/2017
		KEYWORDS: Stop-3parFSNDMP
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(	
			
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Stop-3parFSNDMP   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Stop-3parFSNDMP   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Stop-3parFSNDMP   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "stopfsndmp "	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Stop-3parFSNDMP command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"	
	if($Result)
	{
		return  " SUCCESS : EXECUTING Stop-3parFSNDMP"		
	}
	else
	{
		return "FAILURE : While Executing Stop-3parFSNDMP $Result"
	}
	
} # End Stop-3parFSNDMP

####################################################################################################################
## FUNCTION Show-3parSRSTATISCSISession
####################################################################################################################
Function Show-3parSRSTATISCSISession
{
<#
	.SYNOPSIS   
		The Show-3parSRSTATISCSISession command displays historical performance data reports for
    iSCSI sessions.
	
	.DESCRIPTION  
		The Show-3parSRSTATISCSISession command displays historical performance data reports for
    iSCSI sessions.
	
	.EXAMPLE	
		Show-3parSRSTATISCSISession
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option attime
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option attime -NSP 0:2:1
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option summary -SummaryType min -NSP 0:2:1
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option btsecs -Secs 1 -NSP 0:2:1
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option hourly -NSP 0:2:1
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option daily
	
	.EXAMPLE
		Show-3parSRSTATISCSISession -option groupby -GroupbyValue PORT_N
			
	.PARAMETER Option 
		 -attime
        Performance is shown at a particular time interval, specified by the
        -etsecs option, with one row per object group described by the
        -groupby option. Without this option performance is shown versus time,
        with a row per time interval.

		-btsecs <secs>
			Select the begin time in seconds for the report.
			The value can be specified as either
			- The absolute epoch time (for example 1351263600).
			- The absolute time as a text string in one of the following formats:
				- Full time string including time zone: "2012-10-26 11:00:00 PDT"
				- Full time string excluding time zone: "2012-10-26 11:00:00"
				- Date string: "2012-10-26" or 2012-10-26
				- Time string: "11:00:00" or 11:00:00
			- A negative number indicating the number of seconds before the
			  current time. Instead of a number representing seconds, <secs> can
			  be specified with a suffix of m, h or d to represent time in minutes
			  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
			If it is not specified then the time at which the report begins depends
			on the sample category (-hires, -hourly, -daily):
				- For hires, the default begin time is 12 hours ago (-btsecs -12h).
				- For hourly, the default begin time is 7 days ago (-btsecs -7d).
				- For daily, the default begin time is 90 days ago (-btsecs -90d).
			If begin time and sample category are not specified then the time
			the report begins is 12 hours ago and the default sample category is hires.
			If -btsecs 0 is specified then the report begins at the earliest sample.

		-etsecs <secs>
			Select the end time in seconds for the report.  If -attime is
			specified, select the time for the report.
			The value can be specified as either
			- The absolute epoch time (for example 1351263600).
			- The absolute time as a text string in one of the following formats:
				- Full time string including time zone: "2012-10-26 11:00:00 PDT"
				- Full time string excluding time zone: "2012-10-26 11:00:00"
				- Date string: "2012-10-26" or 2012-10-26
				- Time string: "11:00:00" or 11:00:00
			- A negative number indicating the number of seconds before the
			  current time. Instead of a number representing seconds, <secs> can
			  be specified with a suffix of m, h or d to represent time in minutes
			  (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
			If it is not specified then the report ends with the most recent
			sample.

		-hires
			Select high resolution samples (5 minute intervals) for the report.
			This is the default.

		-hourly
			Select hourly samples for the report.

		-daily
			Select daily samples for the report.

		-summary <type>[,<type>]...
			Summarize performance across requested objects and time range.
			The possible summary types are:
				"min" (minimum), "avg" (average), "max" (maximum), and "detail"
			The "detail" type causes the individual performance records to be
			presented along with the summary type(s) requested. One or more of these
			summary types may be specified.

		-groupby <groupby>[,<groupby>...]
			For -attime reports, generate a separate row for each combination of
			<groupby> items.  Each <groupby> must be different and
			one of the following:
			PORT_N      The node number for the session
			PORT_S      The PCI slot number for the session
			PORT_P      The port number for the session
			ISCSI_NAME  The iSCSI name for the session
			TPGT        The TPGT ID for the session
	
	.PARAMETER SummaryType
		Summarize performance across requested objects and time range.
		
	.PARAMETER Secs
		Select the begin time in seconds for the report.
		
	.PARAMETER GroupbyValue
		 For -attime reports, generate a separate row for each combination of
        <groupby> items.  Each <groupby> must be different and
        one of the following:
        PORT_N      The node number for the session
        PORT_S      The PCI slot number for the session
        PORT_P      The port number for the session
        ISCSI_NAME  The iSCSI name for the session
        TPGT        The TPGT ID for the session

	.PARAMETER NSP
		Node Sloat Poart Value 1:2:3
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parSRSTATISCSISession
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parSRSTATISCSISession
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$SummaryType ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Secs ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$GroupbyValue ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$NSP ,		
			
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3parSRSTATISCSISession   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3parSRSTATISCSISession   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3parSRSTATISCSISession   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "srstatiscsisession "	
	if ($option)
	{
		$a = "attime","summary","btsecs","etsecs","hires","hourly","daily","groupby"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
			if($option -eq "summary")
			{
				$cmd+=" $SummaryType"
			}
            if($option -eq "btsecs" -Or $option -eq "etsecs")
			{
				$cmd+=" $Secs"
			}
			if($option -eq "groupby")
			{
				$gbVal="PORT_N","PORT_S","PORT_P","ISCSI_NAME","TPGT"
				$gbl=$GroupbyValue
				if($gbVal -eq $gbl)
				{
					$cmd+=" $GroupbyValue"
				}
				else
				{
					Return "FAILURE : Invalid -Group-by option: $GroupbyValue cannot be used only [PORT_N | PORT_S | PORT_P | ISCSI_NAME | TPGT] "
				}				
			}			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Show-3parISCSISession   since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [ attime | summary | btsecs | etsecs | hires | hourly | daily | groupby]  can be used . "
		}
	}	
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3parSRSTATISCSISession command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"
	if($option -eq "attime")
	{
		if($Result -match "Time")
		{
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[2..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')					
					$sTemp[3]="Total(PDUs/s)"				
					$sTemp[6]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$s=$s.Substring(1)
				}			
				Add-Content -Path $tempfile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}
	elseif($option -eq "summary")
	{
		if($Result -match "Time")
		{			
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[3..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')					
					$sTemp[3]="Total(PDUs/s)"				
					$sTemp[6]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$s=$s.Substring(1)
				}			
				Add-Content -Path $tempfile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}
	elseif($option -eq "groupby")
	{
		write-host "Groupby"
		if($Result -match "Time")
		{			
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[1..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim() -replace 'Time','Date,Time,Zone'				
				if($incre -eq "true")
				{
					$sTemp1=$s.Substring(1)					
					$sTemp2=$sTemp1.Substring(0,$sTemp1.Length - 17)
					$sTemp2 +="TimeOut"					
					$sTemp = $sTemp2.Split(',')					
					$sTemp[7]="Total(PDUs/s)"				
					$sTemp[10]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}							
				Add-Content -Path $tempfile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}
	else
	{
		if($Result -match "Time")
		{			
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[1..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()					
				if($incre -eq "true")
				{
					$s=$s.Substring(1)								
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')							
					$sTemp[4]="Total(PDUs/s)"				
					$sTemp[7]="Total(KBytes/s)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$sTemp1=$s
					$sTemp = $sTemp1.Split(',')	
					$sTemp2=$sTemp[0]+"-"+$sTemp[1]+"-"+$sTemp[2]
					$sTemp[0]=$sTemp2				
					$sTemp[1]=$sTemp[3]
					$sTemp[2]=$sTemp[4]
					$sTemp[3]=$sTemp[5]
					$sTemp[4]=$sTemp[6]
					$sTemp[5]=$sTemp[7]
					$sTemp[6]=$sTemp[8]
					$sTemp[7]=$sTemp[9]
					$sTemp[8]=$sTemp[10]
					$sTemp[9]=$sTemp[11]
					$sTemp[10]=""
					$sTemp[11]=""				
					$newTemp= [regex]::Replace($sTemp," ",",")	
					$newTemp= $newTemp.Trim()
					$s=$newTemp				
				}
				Add-Content -Path $tempfile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}	
	if($Result -match "Time")
	{
		return  " SUCCESS : EXECUTING Show-3parSRSTATISCSISession"
	}
	else
	{			
		return  $Result
	}
	
} # End Show-3parSRSTATISCSISession

####################################################################################################################
## FUNCTION Show-3pariSCSIStatistics
####################################################################################################################
Function Show-3pariSCSIStatistics
{
<#
	.SYNOPSIS  
		The Show-3pariSCSIStatistics command displays the iSCSI statistics.
   
	.DESCRIPTION  
		The Show-3pariSCSIStatistics command displays the iSCSI statistics.
   
	.EXAMPLE
		Show-3pariSCSIStatistics
	
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -Delay 2
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -NodeList 1
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -SlotList 1
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -PortList 1
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -Fullcounts
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -Prev
		
	.EXAMPLE
		Show-3pariSCSIStatistics -Iterations 1 -Begin
		
	.PARAMETER Iterations 
		 The command stops after a user-defined <number> of iterations.
	.PARAMETER Delay
		 Looping delay in seconds <secs>. The default is 2.
	
	.PARAMETER NodeList
		List of nodes for which the ports are included.
	
	.PARAMETER SlotList
		List of PCI slots for which the ports are included.

	.PARAMETER PortList
		List of ports for which the ports are included. Lists are specified
        in a comma-separated manner such as: -ports 1,2 or -ports 1.
		
	.PARAMETER Fullcounts
		Shows the values for the full list of counters instead of the default
        packets and KBytes for the specified protocols. The values are shown in
        three columns:

          o Current   - Counts since the last sample.
          o CmdStart  - Counts since the start of the command.
          o Begin     - Counts since the port was reset.

        This option cannot be used with the -prot option. If the -fullcounts
        option is not specified, the metrics from the start of the command are
        displayed.
		
	.PARAMETER Prev
		Shows the differences from the previous sample.
		
	.PARAMETER Begin
		Shows the values from when the system was last initiated.

	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3pariSCSIStatistics
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3pariSCSIStatistics
		
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iterations,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Delay,		
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$NodeList,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$SlotList,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$PortList,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Fullcounts,
		
		[Parameter(Position=6, Mandatory=$false)]
		[Switch]
		$Prev,
		
		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Begin,
			
		[Parameter(Position=8, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3pariSCSIStatistics   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3pariSCSIStatistics   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3pariSCSIStatistics   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	
	$cmd= " statiscsi "	
	if($Iterations)
	{
		$cmd+=" -iter $Iterations "
	}
	else
	{
		return " Iterations is mandatory "
	}
	if($Delay)
	{
		$cmd+=" -d $Delay "
	}	
	if($NodeList)
	{
		$cmd+=" -nodes $NodeList "
	}
	if($SlotList)
	{
		$cmd+=" -slots $SlotList "
	}
	if($PortList)
	{
		$cmd+=" -ports $PortList "
	}
	if($Fullcounts)
	{
		$cmd+=" -fullcounts "
	}
	if($Prev)
	{
		$cmd+=" -prev "
	}
	if($Begin)
	{
		$cmd+=" -begin "
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3pariSCSIStatistics command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"	
	if($Result -match "Total" -or $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 
		$Flag = "False"
		$Loop_Cnt = 2	
		if($Fullcounts)
		{
			$Loop_Cnt = 1
		}		
		foreach ($s in  $Result[$Loop_Cnt..$LastItem] )
		{			
		    if($Flag -eq "true")
			{
				if(($s -match "From start of statiscsi command") -or ($s -match "----Receive---- ---Transmit---- -----Total-----") -or ($s -match "port    Protocol Pkts/s KBytes/s Pkts/s KBytes/s Pkts/s KBytes/s Errs/") -or ($s -match "Counts/sec") -or ($s -match "Port Counter                             Current CmdStart   Begin"))
				{
					if(($s -match "port    Protocol Pkts/s KBytes/s Pkts/s KBytes/s Pkts/s KBytes/s Errs/") -or ($s -match "Port Counter                             Current CmdStart   Begin"))
					{
						$temp="=============================="
						Add-Content -Path $tempfile -Value $temp
					}
				}
				else
				{
					$s= [regex]::Replace($s,"^ ","")			
					$s= [regex]::Replace($s," +",",")	
					$s= [regex]::Replace($s,"-","")
					$s= $s.Trim() -replace 'Pkts/s,KBytes/s,Pkts/s,KBytes/s,Pkts/s,KBytes/s','Pkts/s(Receive),KBytes/s(Receive),Pkts/s(Transmit),KBytes/s(Transmit),Pkts/s(Total),KBytes/s(Total)' 	
					if($s.length -ne 0)
					{
						$s=$s.Substring(1)					
					}				
					Add-Content -Path $tempfile -Value $s	
				}
			}
			else
			{
				$s= [regex]::Replace($s,"^ ","")			
				$s= [regex]::Replace($s," +",",")	
				$s= [regex]::Replace($s,"-","")
				$s= $s.Trim() -replace 'Pkts/s,KBytes/s,Pkts/s,KBytes/s,Pkts/s,KBytes/s','Pkts/s(Receive),KBytes/s(Receive),Pkts/s(Transmit),KBytes/s(Transmit),Pkts/s(Total),KBytes/s(Total)' 	
				if($s.length -ne 0)
				{
					$s=$s.Substring(1)					
				}				
				Add-Content -Path $tempfile -Value $s	
			}
			$Flag = "true"			
		}
		Import-Csv $tempFile 
		del $tempFile
	}
	else
	{
		return  $Result
	}
} # End Show-3pariSCSIStatistics

####################################################################################################################
## FUNCTION Show-3pariSCSISessionStatistics
####################################################################################################################
Function Show-3pariSCSISessionStatistics
{
<#
	.SYNOPSIS  
		The Show-3pariSCSISessionStatistics command displays the iSCSI session statistics.
   
	.DESCRIPTION  
		The Show-3pariSCSISessionStatistics command displays the iSCSI session statistics.
   
	.EXAMPLE
		Show-3pariSCSISessionStatistics
	
	.EXAMPLE
		Show-3pariSCSISessionStatistics -Iterations 1
		
	.EXAMPLE
		Show-3pariSCSISessionStatistics -Iterations 1 -Delay 2
		
	.EXAMPLE
		Show-3pariSCSISessionStatistics -Iterations 1 -NodeList 1
		
	.EXAMPLE
		Show-3pariSCSISessionStatistics -Iterations 1 -SlotList 1
		
	.EXAMPLE
		Show-3pariSCSISessionStatistics -Iterations 1 -PortList 1
		
	.EXAMPLE
		Show-3pariSCSISessionStatistics -Iterations 1 -Prev
		
	.PARAMETER Iterations 
		 The command stops after a user-defined <number> of iterations.
	.PARAMETER Delay
		 Looping delay in seconds <secs>. The default is 2.
	
	.PARAMETER NodeList
		List of nodes for which the ports are included.
	
	.PARAMETER SlotList
		List of PCI slots for which the ports are included.

	.PARAMETER PortList
		List of ports for which the ports are included. Lists are specified
        in a comma-separated manner such as: -ports 1,2 or -ports 1.

	.PARAMETER Prev
		Shows the differences from the previous sample.

	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3pariSCSISessionStatistics
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3pariSCSISessionStatistics
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Iterations,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Delay,		
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$NodeList,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$SlotList,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$PortList,		
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Prev,	
			
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3pariSCSISessionStatistics   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3pariSCSISessionStatistics   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3pariSCSISessionStatistics   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "statiscsisession "	
	
	if($Iterations)
	{
		$cmd+=" -iter $Iterations "
	}
	else
	{
		return " Iterations is mandatory "
	}
	if($Delay)
	{
		$cmd+=" -d $Delay "
	}	
	if($NodeList)
	{
		$cmd+=" -nodes $NodeList "
	}
	if($SlotList)
	{
		$cmd+=" -slots $SlotList "
	}
	if($PortList)
	{
		$cmd+=" -ports $PortList "
	}	
	if($Prev)
	{
		$cmd+=" -prev "
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3pariSCSISessionStatistics command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"	
	if($Result -match "Total" -or $Result.Count -gt 5)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count 
		$Flag = "False"
		$Loop_Cnt = 2	
		if($Fullcounts)
		{
			$Loop_Cnt = 1
		}		
		foreach ($s in  $Result[$Loop_Cnt..$LastItem] )
		{			
		    if($Flag -eq "true")
			{
				if(($s -match "statiscsisession") -or ($s -match "----PDUs/s---- --KBytes/s--- ----Errs/s----") -or ($s -match " port -------------iSCSI_Name-------------- TPGT Cmd Resp Total  Tx  Rx Total Digest TimeOut VLAN") -or ($s -match " port -iSCSI_Name- TPGT Cmd Resp Total  Tx  Rx Total Digest TimeOut VLAN"))
				{
					if(($s -match " port -------------iSCSI_Name-------------- TPGT Cmd Resp Total  Tx  Rx Total Digest TimeOut VLAN") -or ($s -match " port -iSCSI_Name- TPGT Cmd Resp Total  Tx  Rx Total Digest TimeOut VLAN"))
					{
						$temp="=============================="
						Add-Content -Path $tempfile -Value $temp
					}
				}
				else
				{
					$s= [regex]::Replace($s,"^ ","")			
					$s= [regex]::Replace($s," +",",")	
					$s= [regex]::Replace($s,"-","")
					$s= $s.Trim()					
					if($s.length -ne 0)
					{
						$sTemp1=$s				
						$sTemp = $sTemp1.Split(',')							
						$sTemp[5]="Total(PDUs/s)"				
						$sTemp[8]="Total(KBytes/s)"
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp
					}					
					Add-Content -Path $tempfile -Value $s	
				}
			}
			else
			{
				$s= [regex]::Replace($s,"^ ","")			
				$s= [regex]::Replace($s," +",",")	
				$s= [regex]::Replace($s,"-","")
				$s= $s.Trim()				
				$sTemp1=$s				
				$sTemp = $sTemp1.Split(',')							
				$sTemp[5]="Total(PDUs/s)"				
				$sTemp[8]="Total(KBytes/s)"
				$newTemp= [regex]::Replace($sTemp,"^ ","")			
				$newTemp= [regex]::Replace($sTemp," ",",")				
				$newTemp= $newTemp.Trim()
				$s=$newTemp							
				
				Add-Content -Path $tempfile -Value $s	
			}
			$Flag = "true"			
		}
		Import-Csv $tempFile 
		del $tempFile
	}
	if($Result -match "Total" -or $Result.Count -gt 5)
	{
		return  " SUCCESS : EXECUTING Show-3pariSCSISessionStatistics"
	}
	else
	{
		return  $Result	
	}
	
} # End Show-3pariSCSISessionStatistics

####################################################################################################################
## FUNCTION Show-3parSRStatIscsi
####################################################################################################################
Function Show-3parSRStatIscsi
{
<#
	.SYNOPSIS   
		The Show-3parSRStatIscsi command displays historical performance data reports for
    iSCSI ports.

	.DESCRIPTION  
		The Show-3parSRStatIscsi command displays historical performance data reports for
    iSCSI ports.

	.EXAMPLE	
		Show-3parSRStatIscsi
	
	.EXAMPLE
		Show-3parSRStatIscsi -option attime
	
	.EXAMPLE
		Show-3parSRStatIscsi -option attime -NSP 0:2:1
	
	.EXAMPLE
		Show-3parSRStatIscsi -option summary -SummaryType min
	
	.EXAMPLE
		Show-3parSRStatIscsi -option summary -SummaryType min -NSP 0:2:1
	
	.EXAMPLE
		Show-3parSRStatIscsi -option btsecs -Secs 1
	
	.EXAMPLE
		Show-3parSRStatIscsi -option groupby -GroupbyValue PORT_N
		
	.PARAMETER Option 
		 -attime
        Performance is shown at a particular time interval, specified by the
        -etsecs option, with one row per object group described by the
        -groupby option. Without this option performance is shown versus time,
        with a row per time interval.

    -btsecs <secs>
        Select the begin time in seconds for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - The absolute time as a text string in one of the following formats:
            - Full time string including time zone: "2012-10-26 11:00:00 PDT"
            - Full time string excluding time zone: "2012-10-26 11:00:00"
            - Date string: "2012-10-26" or 2012-10-26
            - Time string: "11:00:00" or 11:00:00
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins depends
        on the sample category (-hires, -hourly, -daily):
            - For hires, the default begin time is 12 hours ago (-btsecs -12h).
            - For hourly, the default begin time is 7 days ago (-btsecs -7d).
            - For daily, the default begin time is 90 days ago (-btsecs -90d).
        If begin time and sample category are not specified then the time
        the report begins is 12 hours ago and the default sample category is hires.
        If -btsecs 0 is specified then the report begins at the earliest sample.

    -etsecs <secs>
        Select the end time in seconds for the report.  If -attime is
        specified, select the time for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - The absolute time as a text string in one of the following formats:
            - Full time string including time zone: "2012-10-26 11:00:00 PDT"
            - Full time string excluding time zone: "2012-10-26 11:00:00"
            - Date string: "2012-10-26" or 2012-10-26
            - Time string: "11:00:00" or 11:00:00
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent
        sample.

    -hires
        Select high resolution samples (5 minute intervals) for the report.
        This is the default.

    -hourly
        Select hourly samples for the report.

    -daily
        Select daily samples for the report.

    -summary <type>[,<type>]...
        Summarize performance across requested objects and time range.
        The possible summary types are:
            "min" (minimum), "avg" (average), "max" (maximum), and "detail"
        The "detail" type causes the individual performance records to be
        presented along with the summary type(s) requested. One or more of these
        summary types may be specified.

    -groupby <groupby>[,<groupby>...]
        For -attime reports, generate a separate row for each combination of
        <groupby> items.  Each <groupby> must be different and
        one of the following:
        PORT_N      The node number for the port
        PORT_S      The PCI slot number for the port
        PORT_P      The port number for the port
        PROTOCOL    The protocol type for the port
	
	.PARAMETER SummaryType
		 Summarize performance across requested objects and time range.
		 
	.PARAMETER Secs
		 Select the end time in seconds for the report.
		 
	.PARAMETER GroupbyValue
		For -attime reports, generate a separate row for each combination of
        <groupby> items.  Each <groupby> must be different and
        one of the following:
        PORT_N      The node number for the port
        PORT_S      The PCI slot number for the port
        PORT_P      The port number for the port
        PROTOCOL    The protocol type for the port
		
	.PARAMETER NSP
		Dode Sloat Port Value 1:2:3
	
	.PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
	.Notes
		NAME: Show-3parSRStatIscsi
		LASTEDIT: 01/03/2017
		KEYWORDS: Show-3parSRStatIscsi
   
	.Link
		Http://www.hpe.com
 
 #Requires PS -Version 3.0
 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$SummaryType ,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$Secs ,
		
		[Parameter(Position=3, Mandatory=$false)]
		[System.String]
		$GroupbyValue ,
		
		[Parameter(Position=4, Mandatory=$false)]
		[System.String]
		$NSP ,		
			
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	Write-DebugLog "Start: In Show-3parSRStatIscsi   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3parSRStatIscsi   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3parSRStatIscsi   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}	
	$cmd= "srstatiscsi "	
	if ($option)
	{
		$a = "attime","summary","btsecs","etsecs","hires","hourly","daily","groupby"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "	
			if($option -eq "summary")
			{
				$cmd+=" $SummaryType"
			}
            if($option -eq "btsecs" -Or $option -eq "etsecs")
			{
				$cmd+=" $Secs"
			}
			if($option -eq "groupby")
			{
				$gbVal="PORT_N","PORT_S","PORT_P","PROTOCOL"
				$gbl=$GroupbyValue
				if($gbVal -eq $gbl)
				{
					$cmd+=" $GroupbyValue"
				}
				else
				{
					Return "FAILURE : Invalid -Group-by option: $GroupbyValue cannot be used only [PORT_N | PORT_S | PORT_P | PROTOCOL] "
				}				
			}			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Show-3parISCSISession   since -option $option in incorrect "
			Return "FAILURE : -option $option cannot be used only [ attime | summary | btsecs | etsecs | hires | hourly | daily | groupby]  can be used . "
		}
	}	
	if ($NSP)
	{
		$cmd+=" $NSP "
	}
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog "  executing  Show-3parSRStatIscsi command that displays information iSNS table for iSCSI ports in the system --> $cmd" "INFO:"
	$Flag="True"
	if($option -eq "attime" -or $option -eq "summary")
	{
		$Flag="Fals"
		if($Result -match "Time")
		{
			$count=2
			if($option -eq "summary")
			{
				$count=3
			}
			$tempFile = [IO.Path]::GetTempFileName()
			$LastItem = $Result.Count
			$incre = "true" 		
			foreach ($s in  $Result[$count..$LastItem] )
			{			
				$s= [regex]::Replace($s,"^ ","")						
				$s= [regex]::Replace($s," +",",")			
				$s= [regex]::Replace($s,"-","")			
				$s= $s.Trim()			
				if($incre -eq "true")
				{		
					$sTemp1=$s				
					$sTemp = $sTemp1.Split(',')							
					$sTemp[1]="Pkts/s(Receive)"				
					$sTemp[2]="KBytes/s(Receive)"
					$sTemp[3]="Pkts/s(Transmit)"				
					$sTemp[4]="Kytes/s(Transmit)"
					$sTemp[5]="Pkts/s(Total)"				
					$sTemp[6]="Kytes/s(Total)"
					$newTemp= [regex]::Replace($sTemp,"^ ","")			
					$newTemp= [regex]::Replace($sTemp," ",",")				
					$newTemp= $newTemp.Trim()
					$s=$newTemp							
				}
				if($incre -eq "false")
				{
					$s=$s.Substring(1)
				}			
				Add-Content -Path $tempfile -Value $s	
				$incre="false"
			}			
			Import-Csv $tempFile 
			del $tempFile
		}
		else
		{
			return $Result
		}
	}	
	else
	{	
		if($Flag -eq "True")
		{
			if($Result -match "Time")
			{			
				$tempFile = [IO.Path]::GetTempFileName()
				$LastItem = $Result.Count
				$incre = "true" 		
				foreach ($s in  $Result[1..$LastItem] )
				{			
					$s= [regex]::Replace($s,"^ ","")						
					$s= [regex]::Replace($s," +",",")			
					$s= [regex]::Replace($s,"-","")			
					$s= $s.Trim() -replace 'Time','Date,Time,Zone' 						
					if($incre -eq "true")
					{
						$s=$s.Substring(1)
						$sTemp1=$s				
						$sTemp = $sTemp1.Split(',')							
						$sTemp[4]="Pkts/s(Receive)"				
						$sTemp[5]="KBytes/s(Receive)"
						$sTemp[6]="Pkts/s(Transmit)"				
						$sTemp[7]="Kytes/s(Transmit)"
						$sTemp[8]="Pkts/s(Total)"				
						$sTemp[9]="Kytes/s(Total)"
						$newTemp= [regex]::Replace($sTemp,"^ ","")			
						$newTemp= [regex]::Replace($sTemp," ",",")				
						$newTemp= $newTemp.Trim()
						$s=$newTemp
					}				
					Add-Content -Path $tempfile -Value $s	
					$incre="false"
				}			
				Import-Csv $tempFile 
				del $tempFile
			}
			else
			{
				return $Result
			}
		}
	}	
	if($Result -match "Time")
	{
		return  " SUCCESS : EXECUTING Show-3parSRStatIscsi"
	}
	else
	{			
		return  $Result
	}
	
} # End Show-3parSRStatIscsi

#######################################################################################################
## FUNCTION Get-3parSystemInformation
########################################################################################################
Function Get-3parSystemInformation
{
<#
  .SYNOPSIS
    Command displays the 3PAR Storage system information. 
  
  .DESCRIPTION
    Command displays the 3PAR Storage system information.
        
  .EXAMPLE
    Get-3parSystemInformation 
	Command displays the 3PAR Storage system information.such as system name, model, serial number, and system capacity information.
  .EXAMPLE
    Get-3parSystemInformation -Option space
	Lists 3PAR Storage system space information in MB(1024^2 bytes)
  	
  .PARAMETER Option
	space 
    Displays the system capacity information in MB (1024^2 bytes)
    domainspace 
    Displays the system capacity information broken down by domain in MB(1024^2 bytes)	
    fan 
    Displays the system fan information.
    date	
	command displays the date and time for each system node
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSystemInformation
    LASTEDIT: 01/23/2017
    KEYWORDS: Get-3parSystemInformation
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Option,
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	$Option = $Option.toLower()
	Write-DebugLog "Start: In Get-3parSystemInformation - validating input values" $Debug 

	#check if connection object contents are null/empty
	if(!$SANConnection)
	{				
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSystemInformation since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSystemInformation since SAN connection object values are null/empty"
			}
		}
	}
	$cliresult1 = Test-PARCli -SANConnection $SANConnection
	if(($cliresult1 -match "FAILURE :"))
	{
		write-debuglog "$cliresult1" "ERR:" 
		return $cliresult1
	}
	$sysinfocmd = "showsys "
	
	if ($Option)
	{
		$a = "d","param","fan","space","vvspace","domainspace","desc","devtype","date"
		$l=$Option
		if($a -eq $l)
		{
			$sysinfocmd+=" -$option "
			if($Option -eq "date")
			{
				$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  "showdate"
				write-debuglog "Get 3par system date information " "INFO:"
				write-debuglog "Get 3par system fan information cmd -> showdate " "INFO:"
				$tempFile = [IO.Path]::GetTempFileName()
				Add-Content -Path $tempfile -Value "Node,Date"
				foreach ($s in  $Result[1..$Result.Count] )
				{
				$splits = $s.split(" ")
				$var1 = $splits[0].trim()
				#write-host "var1 = $var1"
				$var2 = ""
				foreach ($t in $splits[1..$splits.Count])
				{
					#write-host "t = $t"
					if(-not $t)
					{
						continue
					}
					$var2 += $t+" "
					
					#write-host "var2 $var2"
				}
				$var3 = $var1+","+$var2
				Add-Content -Path $tempfile -Value $var3
				}
				Import-Csv $tempFile
				return
			}	
			else
			{
				$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysinfocmd
				return $Result
			}
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [d,param,fan,space,vvspace,domainspace,desc,devtype]  can be used only . "
		}
	}
	else
	{	
		$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $sysinfocmd
		return $Result 
	}		
}
##### END Get-3parSystemInformation #####
####################################################################################################################
## FUNCTION Add-3parRcopytarget
####################################################################################################################
Function Add-3parRcopytarget
{
<#
  .SYNOPSIS
    The Add-3parRcopytarget command adds a target to a remote-copy volume group.
  .DESCRIPTION
    The Add-3parRcopytarget command adds a target to a remote-copy volume group.
	
  .EXAMPLE
   Add-3parRcopytarget -Target_name XYZ -Mode sync -Group_name test
   This example admits physical disks.
  
  .PARAMETER Target_name 
	 Specifies the name of the target that was previously created with the creatercopytarget command.
	 
  .PARAMETER Mode 
	Specifies the mode of the target as either synchronous (sync), asynchronous periodic (periodic), or asynchronous streaming (async).
	
  .PARAMETER Group_name 
	  Specifies the name of the existing remote copy volume group created with the creatercopygroup command to which the target will be added.
	  
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Add-3parRcopytarget
    LASTEDIT: 03/03/2017
    KEYWORDS: Add-3parRcopytarget
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Mode,
		
		[Parameter(Position=2, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
		)	
	
	Write-DebugLog "Start: In Add-3parRcopytarget   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Add-3parRcopytarget   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Add-3parRcopytarget   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "admitrcopytarget "
	if ($Target_name)
	{		
		$cmd+=" $Target_name "			
	}
	else
	{
		return " FAILURE :  Target_name is mandatory for to execute  "
	}
	if ($Mode)
	{	
		$a = "sync","periodic","async"
		$l=$Mode
		if($a -eq $l)
		{
			$cmd+=" $Mode "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting    Add-3parRcopytarget since -Mode $Mode in incorrect "
			Return "FAILURE : -Mode :- $Mode is an Incorrect Mode  [sync | periodic | async]  can be used only . "
		}
					
	}
	else
	{
		return " FAILURE :  Mode is mandatory for to execute  "
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "			
	}
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd	
	write-debuglog " The Add-3parRcopytarget command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Add-3parRcopytarget

####################################################################################################################
## FUNCTION Add-3parRcopyVV
####################################################################################################################
Function Add-3parRcopyVV
{
<#
  .SYNOPSIS
    The Add-3parRcopyVV command adds an existing virtual volume to an existing remote copy
    volume group.

  .DESCRIPTION
    The Add-3parRcopyVV command adds an existing virtual volume to an existing remote copy
    volume group.
	
  .EXAMPLE
   Add-3parRcopyVV  -VV_name vv1 -Group_name Group1 -Target_name System2 -Sec_VV_name vv1_remote
   
   .EXAMPLE
   Add-3parRcopyVV  -VV_name vv1 -Snapname test -Group_name Group1 -Target_name System2 -Sec_VV_name vv1_remote
   
  .EXAMPLE
   Add-3parRcopyVV -option pat -VV_name vv1 -Group_name Group1 -Target_name System2 -Sec_VV_name vv1_remote
  
  .PARAMETER option
  
	-pat
        Specifies that the <VV_name> is treated as a glob-style pattern and that
        all remote copy volumes matching the specified pattern are admitted to the
        remote copy group. When this option is used the <sec_VV_name> and
        <snapname> (if specified) are also treated as patterns. It is required
        that the secondary volume names and snapshot names can be derived from the
        local volume name by adding a prefix, suffix or both. <snapname> and
        <sec_VV_name> should take the form prefix@vvname@suffix, where @vvname@
        resolves to the name of each volume that matches the <VV_name> pattern.

    -createvv
        Specifies that the secondary volumes should be created automatically. This
        specifier cannot be used when starting snapshots (<VV_name>:<snapname>) are
        specified.

    -nowwn
        When used with -createvv, it ensures a different WWN is
        used on the secondary volume. Without this option -createvv will use the same
        WWN for both primary and secondary volumes.

    -nosync
        Specifies that the volume should skip the initial sync. This is for the
        admission of volumes that have been pre-synced with the target volume.
        This specifier cannot be used when starting snapshots (<VV_name>:<snapname>)
        are specified.
  
  .PARAMETER VV_name
		Specifies the name of the existing virtual volume to be admitted to an
        existing remote copy volume group that was created with the
        creatercopygroup command.
  
  .PARAMETER Snapname
		An optional read-only snapshot <snapname> can be specified along with
        the virtual volume name <VV_name>.
		
  .PARAMETER Group_name
		Specifies the name of the existing remote copy volume group created with
        the creatercopygroup command, to which the volume will be added.
  
  .PARAMETER Target_name
		The target name associated with this group, as set with the
        creatercopygroup command. The target is created with the
        creatercopytarget command.
  
  .PARAMETER Sec_VV_name
		The target name associated with this group, as set with the
        creatercopygroup command. The target is created with the
        creatercopytarget command. <sec_VV_name> specifies the name of the
        secondary volume on the target system.  One <target_name>:<sec_VV_name>
        must be specified for each target of the group.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Add-3parRcopyVV
    LASTEDIT: 03/03/2017
    KEYWORDS: Add-3parRcopyVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,		
		
		[Parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$SourceVolumeName,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Snapname,
		
		[Parameter(Position=3, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
		
		[Parameter(Position=4, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=5, Mandatory=$true,ValueFromPipeline=$true)]
		[System.String]
		$TargetVolumeName,		
				
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Add-3parRcopyVV   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Add-3parRcopyVV   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Add-3parRcopyVV   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "admitrcopyvv "
	if ($option)
	{
		$a = "pat","createvv","nowwn","nosync"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [pat | createvv | nowwn | nosync]  can be used only . "
		}
	}
	if ($SourceVolumeName)
	{		
		$cmd+=" $SourceVolumeName"	
	}	
	else
	{
		return " FAILURE :  SourceVolumeName is mandatory for to execute  "
	}
	if ($Snapname)
	{		
		$cmd+=":$Snapname "	
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
	if ($Target_name)
	{		
		$cmd+=" $Target_name"	
	}	
	else
	{
		return " FAILURE :  Target_name is mandatory for to execute  "
	}
	if ($TargetVolumeName)
	{		
		$cmd+=":$TargetVolumeName "	
	}	
	else
	{
		return " FAILURE :  TargetVolumeName is mandatory for to execute  "
	}
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Add-3parRcopyVV command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Add-3parRcopyVV
####################################################################################################################
## FUNCTION Test-3parRcopyLink
####################################################################################################################
Function Test-3parRcopyLink
{
<#checkrclink
  .SYNOPSIS
    The Test-3parRcopyLink command performs a connectivity, latency, and throughput test between two connected HPE 3PAR storage systems.

  .DESCRIPTION
    The Test-3parRcopyLink command performs a connectivity, latency, and throughput
    test between two connected HPE 3PAR storage systems.
	
  .EXAMPLE
   Test-3parRcopyLink -Subcommand startclient -option time -Duration 400 -NSP 0:5:4 -Dest_IP_Addr 1.1.1.2 -Time 20 

  .EXAMPLE
   Test-3parRcopyLink -Subcommand startclient -option fcip -NSP 0:5:4 -Dest_IP_Addr 1.1.1.2 -Time 20 
   
   EXAMPLE
   Test-3parRcopyLink -Subcommand stopclient -NSP 0:5:4
   
   .EXAMPLE
   Test-3parRcopyLink -Subcommand startserver -option time -Duration 400 -NSP 0:5:4 -Dest_IP_Addr 1.1.1.2 
   
   .EXAMPLE
   Test-3parRcopyLink -Subcommand startserver -option fcip -NSP 0:5:4 -Dest_IP_Addr 1.1.1.2 
   
   .EXAMPLE
   Test-3parRcopyLink -Subcommand stopserver -NSP 0:5:4
   
   .EXAMPLE
   Test-3parRcopyLink -Subcommand portconn -NSP 0:5:4
  
  .PARAMETER option
  
	 -time <secs>
    Specifies the number of seconds for the test to run using an integer
    from 300 to 172800.  If not specified this defaults to 172800
    seconds (48 hours).

    -fcip
    Specifies if the link is running over fcip.
    Should only be supplied for FC interfaces.

  
  .PARAMETER Subcommand
		checkrclink startclient [options] <N:S:P> <dest_addr> <time> [<port>]
		checkrclink stopclient  <N:S:P>
		checkrclink startserver [options] <N:S:P> [<dest_addr>] [<port>]
		checkrclink stopserver  <N:S:P>
		checkrclink portconn    <N:S:P>

		startclient: start the link test
		stopclient:  stop the link test
		startserver: start the server
		stopserver:  stop the server
		portconn:    Uses the Cisco Discovery Protocol Reporter to show display information about devices that are connected to network ports.
        Note: Requires CDP to be enabled on the router.
  
  .PARAMETER NSP
		 Specifies the interface from which to check the link, expressed as
        node:slot:port.
		
  .PARAMETER Dest_IP_Addr
		Specifies the address of the target system (for example, the IP
        address).
  
  .PARAMETER Time
		Specifies the test duration in seconds.
        Specifies the number of seconds for the test to run using an integer
        from 300 to 172800.
  
  .PARAMETER Port
		Specifies the port on which to run the test. If this specifier is not
        used, the test automatically runs on port 3492.
		
  .PARAMETER Duration
		Specifies the number of seconds for the test to run using an integer
		from 300 to 172800. 
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Test-3parRcopyLink
    LASTEDIT: 03/03/2017
    KEYWORDS: Test-3parRcopyLink
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Subcommand,
	
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$option,		
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$NSP,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Dest_IP_Addr,
		
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Time,
		
		[Parameter(Position=5, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Port,

		[Parameter(Position=6, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Duration,
				
		[Parameter(Position=7, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Test-3parRcopyLink   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Test-3parRcopyLink   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Test-3parRcopyLink   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "checkrclink "
	if ($Subcommand)
	{	
		$a = "startclient","stopclient","startserver","stopserver","portconn"
		$l=$Subcommand
		if($a -eq $l)
		{
			$cmd+=" $Subcommand "							
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Test-3parRcopyLink   since -Subcommand $Subcommand in incorrect "
			Return "FAILURE : -Subcommand :- $Subcommand is an Incorrect Subcommand  [$Subcommand]  can be used only . "
		}		
	}	
	else
	{
		return " FAILURE :  Subcommand is mandatory for to Execute  "
	}
	if ($option)
	{
		if($Subcommand -eq "startclient" -or $Subcommand -eq "startserver")
		{
			$a = "time","fcip"
			$l=$option
			if($a -eq $l)
			{
				$cmd+=" -$option "	
				if($option -eq "time")
				{ 
					if($Duration)
					{
						$cmd+=" $Duration "
					}
					else
					{
						return "If Time Option is selected then Duration is mentadory "
					}				
				}					
			}
			else
			{ 
				Write-DebugLog "Stop: Exiting  Test-3parRcopyLink   since -option $option in incorrect "
				Return "FAILURE : -option :- $option is an Incorrect option  [time | fcip ]  can be used only . "
			}
		}
		else
		{
			return "Option is work only with startclient and startserver Subcommand"
		}
		
	}
	if($Subcommand -eq "startclient")
	{
		if ($NSP)
		{		
			$cmd+=" $NSP "	
		}	
		else
		{
			return " FAILURE :  NSP is mandatory for to execute  "
		}
		if ($Dest_IP_Addr)
		{		
			$cmd+=" $Dest_IP_Addr "	
		}	
		else
		{
			return " FAILURE :  Dest_IP_Addr is mandatory for to execute  "
		}
		if ($Time)
		{		
			$cmd+=" $Time "	
		}	
		else
		{
			return " FAILURE :  Time is mandatory for to execute  "
		}
		if ($Port)
		{		
			$cmd+=" $Port "	
		}
	}
	elseif($Subcommand -eq "startserver")
	{
		if ($NSP)
		{		
			$cmd+=" $NSP "	
		}	
		else
		{
			return " FAILURE :  NSP is mandatory for to execute  "
		}
		if ($Dest_IP_Addr)
		{		
			$cmd+=" $Dest_IP_Addr "	
		}	
		else
		{
			return " FAILURE :  Dest_IP_Addr is mandatory for to execute  "
		}		
		if ($Port)
		{		
			$cmd+=" $Port "	
		}
	}
	else
	{
		if ($NSP)
		{		
			$cmd+=" $NSP "	
		}	
		else
		{
			return " FAILURE :  NSP is mandatory for to execute  "
		}
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Test-3parRcopyLink command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Test-3parRcopyLink
####################################################################################################################
## FUNCTION Sync-Recover3ParDRRcopyGroup
####################################################################################################################
Function Sync-Recover3ParDRRcopyGroup
{
<#
  .SYNOPSIS
    The Sync-Recover3ParDRRcopyGroup command performs the following actions:

    Performs data synchronization from primary remote copy volume groups to secondary remote copy volume groups.

    Performs the complete recovery operation (synchronization and storage failover operation which performs role reversal to make secondary volumes as primary which becomes read-write) for the remote copy volume group in both planned migration and disaster scenarios.


  .DESCRIPTION
    The Sync-Recover3ParDRRcopyGroup command performs the following actions:

    Performs data synchronization from primary remote copy volume groups to secondary remote copy volume groups.

    Performs the complete recovery operation (synchronization and storage failover operation which performs role reversal to make secondary volumes as primary which becomes read-write) for the remote copy volume group in both planned migration and disaster scenarios.
	
  .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Target_name test -Group_name Grp1

  .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand recovery -Target_name test -Group_name Grp1
   
   EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Force -Group_name Grp1
   
   .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Nowaitonsync -Group_name Grp1
   
   .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Nosyncbeforerecovery -Group_name Grp1
   
   .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Nofailoveronlinkdown -Group_name Grp1
   
   .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Forceassecondary -Group_name Grp1
   
   .EXAMPLE
   Sync-Recover3ParDRRcopyGroup  -Subcommand sync -Waittime 60 -Group_name Grp1
   
  
  .PARAMETER option
  
	 -time <secs>
    Specifies the number of seconds for the test to run using an integer
    from 300 to 172800.  If not specified this defaults to 172800
    seconds (48 hours).

    -fcip
    Specifies if the link is running over fcip.
    Should only be supplied for FC interfaces.

  
  .PARAMETER Subcommand
		sync
        Performs the data synchronization from primary remote copy volume
        group to secondary remote copy volume group.
		
		recovery
        Performs complete recovery operation for the remote copy volume
        group in both planned migration and disaster scenarios.
		
   .PARAMETER Target_name <target_name>
        Specifies the target for the subcommand. This is optional for
        single target groups but is required for multi-target groups.
		
   .PARAMETER Force
        Does not ask for confirmation for this command.

   .PARAMETER Nowaitonsync
        Specifies that this command should not wait for data synchronization
        from primary remote copy volume groups to secondary remote copy
        volume groups.
        This option is valid only for the sync subcommand.

   .PARAMETER Nosyncbeforerecovery
        Specifies that this command should not perform data synchronization
        before the storage failover operation (performing role reversal to
        make secondary volumes as primary which becomes read-write). This
        option can be used if data synchronization is already done outside
        of this command and it is required to do only storage failover
        operation (performing role reversal to make secondary volumes as
        primary which becomes read-write).
        This option is valid only for the recovery subcommand.

   .PARAMETER Nofailoveronlinkdown
        Specifies that this command should not perform storage failover
        operation (performing role reversal to make secondary volumes as
        primary which becomes read-write) when the remote copy link is down.
        This option is valid only for the recovery subcommand.

    .PARAMETER Forceasprimary
        Specifies that this command does the storage failover operation
        (performing role reversal to make secondary volumes as primary
        which becomes read-write) and forces secondary role as primary
        irrespective of whether the data is current or not.
        This option is valid only for the recovery subcommand.
        The successful execution of this command must be immediately
        followed by the execution of the recovery subcommand with
        forceassecondary option on the other array. The incorrect use
        of this option can lead to the primary secondary volumes not
        being consistent. see the notes section for additional details.

    .PARAMETER Forceassecondary
        This option must be used after successful execution of recovery subcommand with forceasprimary option on the other array.
        Specifies that this changes the primary volume groups to secondary
        volume groups. The incorrect use of this option can lead to the
        primary secondary volumes not being consistent.
        This option is valid only for the recovery subcommand.

    .PARAMETER Nostart
        Specifies that this command does not start the group after storage failover operation is complete.
        This option is valid only for the recovery subcommand.

    .PARAMETER Waittime <timeout_value>
        Specifies the timeout value for this command.
        Specify the time in the format <time>{s|S|m|M}. Value is a positive
        integer with a range of 1 to 720 minutes (12 Hours).
        Default time is 720 minutes. 
		
    .PARAMETER Group_name
		Name of the Group
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Sync-Recover3ParDRRcopyGroup
    LASTEDIT: 03/03/2017
    KEYWORDS: Sync-Recover3ParDRRcopyGroup
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$Subcommand,
	
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=3, Mandatory=$false)]
		[Switch]
		$Nowaitonsync,
		
		[Parameter(Position=4, Mandatory=$false)]
		[Switch]
		$Nosyncbeforerecovery,
		
		[Parameter(Position=5, Mandatory=$false)]
		[Switch]
		$Nofailoveronlinkdown,

		[Parameter(Position=7, Mandatory=$false)]
		[Switch]
		$Forceasprimary,
		
		[Parameter(Position=8, Mandatory=$false)]
		[Switch]
		$Nostart,
		
		[Parameter(Position=9, Mandatory=$false)]
		[System.String]
		$Waittime,
		
		[Parameter(Position=10, Mandatory=$false)]
		[System.String]
		$Group_name,		
				
		[Parameter(Position=11, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Sync-Recover3ParDRRcopyGroup   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Sync-Recover3ParDRRcopyGroup   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Sync-Recover3ParDRRcopyGroup   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "controldrrcopygroup "
	if ($Subcommand)
	{	
		$a = "sync","recovery"
		$l=$Subcommand
		if($a -eq $l)
		{
			$cmd+=" $Subcommand -f"							
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Sync-Recover3ParDRRcopyGroup   since -Subcommand $Subcommand in incorrect "
			Return "FAILURE : -Subcommand :- $Subcommand is an Incorrect Subcommand  [$Subcommand]  can be used only . "
		}		
	}	
	else
	{
		return " FAILURE :  Subcommand is mandatory for to Execute  "
	}
	if ($Target_name)
	{		
		$cmd+=" -target $Target_name "	
	}	
	if ($Nowaitonsync)
	{		
		$cmd+=" -nowaitonsync "	
	}
	if ($Nosyncbeforerecovery)
	{		
		$cmd+=" -nosyncbeforerecovery "	
	}
	if ($Nofailoveronlinkdown)
	{		
		$cmd+=" -nofailoveronlinkdown "	
	}
	if ($Forceasprimary)
	{		
		$cmd+=" -forceasprimary "	
	}
	if ($Nostart)
	{		
		$cmd+=" -nostart "	
	}
	if ($Waittime)
	{		
		$cmd+=" -waittime $Waittime "	
	}	
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory to execute Sync-Recover3ParDRRcopyGroup command "
	}	
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Sync-Recover3ParDRRcopyGroup command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Sync-Recover3ParDRRcopyGroup
####################################################################################################################
## FUNCTION Disable-3ParRcopylink
####################################################################################################################
Function Disable-3ParRcopylink
{
<#
  .SYNOPSIS
    The Disable-3ParRcopylink command removes one or more links (connections)
    created with the admitrcopylink command to a target system.

  .DESCRIPTION
    The Disable-3ParRcopylink command removes one or more links (connections)
    created with the admitrcopylink command to a target system.
	
  .EXAMPLE
   Disable-3ParRcopylink -RCIP -Target_name test -NSP_IP_address 1.1.1.1

  .EXAMPLE
   Disable-3ParRcopylink -RCFC -Target_name test -NSP_WWN 1245
      
  .PARAMETER RCIP  
	Syntax for remote copy over IP (RCIP)
	
  .PARAMETER RCFC
	Syntax for remote copy over FC (RCFC)
		
  .PARAMETER Target_name	
	The target name, as specified with the creatercopytarget command.
	
  .PARAMETER NSP_IP_address		
	Specifies the node, slot, and port of the Ethernet port on the local system and an IP address of the peer port on the target system.

  .PARAMETER NSP_WWN
	Specifies the node, slot, and port of the Fibre Channel port on the local system and World Wide Name (WWN) of the peer port on the target system.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Disable-3ParRcopylink
    LASTEDIT: 03/03/2017
    KEYWORDS: Disable-3ParRcopylink
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[Switch]
		$RCIP,
	
		[Parameter(Position=1, Mandatory=$false)]
		[Switch]
		$RCFC,

		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=3, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$NSP_IP_address,
		
		[Parameter(Position=4, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$NSP_WWN,		
				
		[Parameter(Position=5, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Disable-3ParRcopylink   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Disable-3ParRcopylink   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Disable-3ParRcopylink   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopylink "
	if($RCFC -or $RCIP)
	{
		if($RCFC)
		{
			if($RCIP)
			{
			 return "Please select only one RCFC -or RCIP"
			}
			else
			{
				if ($Target_name)
				{		
					$cmd+=" $Target_name "	
				}	
				else
				{
					return " FAILURE :  Target_name is mandatory to execute  "
				}
				if ($NSP_IP_address)
				{		
					$cmd+=" $NSP_IP_address "	
				}	
				else
				{
					return " FAILURE :  NSP_IP_address is mandatory to execute  "
				}
			}
		}
		if($RCIP)
		{
			if($RCFC)
			{
				return "Please select only one RCFC -or RCIP"
			}
			else
			{
				if ($Target_name)
				{		
					$cmd+=" $Target_name "	
				}	
				else
				{
					return " FAILURE :  Target_name is mandatory for to execute  "
				}
				if ($NSP_WWN)
				{		
					$cmd+=" $NSP_WWN "	
				}	
				else
				{
					return " FAILURE :  NSP_WWN is mandatory for to execute  "
				}
			}
		}
	}
	else
	{
		return "Please Select at-list any one from RCFC -or RCIP to execute Disable-3ParRcopylink command"
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Disable-3ParRcopylink command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Disable-3ParRcopylink
####################################################################################################################
## FUNCTION Disable-3ParRcopytarget
####################################################################################################################
Function Disable-3ParRcopytarget
{
<#
  .SYNOPSIS
    The Disable-3ParRcopytarget command removes a remote copy target from a
    remote copy volume group.

  .DESCRIPTION
    The Disable-3ParRcopytarget command removes a remote copy target from a
    remote copy volume group.
	
  .EXAMPLE
   Disable-3ParRcopytarget -Target_name Test -Group_name Test2
     		
  .PARAMETER Target_name	
	The name of the target to be removed.
	
  .PARAMETER Group_name		
	 The name of the group that currently includes the target.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Disable-3ParRcopytarget
    LASTEDIT: 03/03/2017
    KEYWORDS: Disable-3ParRcopytarget
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(		

		[Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Target_name,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Disable-3ParRcopytarget   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Disable-3ParRcopytarget   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Disable-3ParRcopytarget   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopytarget -f "
	if ($Target_name)
	{		
		$cmd+=" $Target_name "	
	}	
	else
	{
		return " FAILURE :  Target_name is mandatory for to execute  "
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Disable-3ParRcopytarget command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Disable-3ParRcopytarget
####################################################################################################################
## FUNCTION Disable-3ParRcopyVV
####################################################################################################################
Function Disable-3ParRcopyVV
{
<#
  .SYNOPSIS
    The Disable-3ParRcopyVV command removes a virtual volume from a remote copy volume
    group.

  .DESCRIPTION
    The Disable-3ParRcopyVV command removes a virtual volume from a remote copy volume
    group.
	
  .EXAMPLE
   Disable-3ParRcopyVV -VV_name XYZ -Group_name XYZ
   
   .EXAMPLE
   Disable-3ParRcopyVV -option pat -VV_name XYZ -Group_name XYZ
   
   .EXAMPLE
   Disable-3ParRcopyVV -option keepsnap -VV_name XYZ -Group_name XYZ
   
   .EXAMPLE
   Disable-3ParRcopyVV -option removevv -VV_name XYZ -Group_name XYZ
    
  .PARAMETER option
  
    -pat
        Specifies that specified patterns are treated as glob-style patterns
        and all remote copy volumes matching the specified pattern will be
        dismissed from the remote copy group. This option must be used
        if the <pattern> specifier is used.

    -keepsnap
        Specifies that the local volume's resync snapshot should be retained.
        The retained snapshot will reflect the state of the secondary volume
        and might be used as the starting snapshot if the volume is readmitted
        to a remote copy group. The snapshot name will begin with "sv.rcpy"

    -removevv
        Remove remote sides' volumes.
  
  .PARAMETER VV_name	
	The name of the volume to be removed. Volumes are added to a group with the admitrcopyvv command.
	  	
  .PARAMETER Group_name		
	 The name of the group that currently includes the target.
	 
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Disable-3ParRcopyVV
    LASTEDIT: 03/03/2017
    KEYWORDS: Disable-3ParRcopyVV
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(	
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,

		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$VV_name,
		
		[Parameter(Position=2, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$Group_name,
				
		[Parameter(Position=3, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Disable-3ParRcopyVV   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Disable-3ParRcopyVV   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Disable-3ParRcopyVV   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "dismissrcopyvv -f "
	
	if($option)
	{
		$a = "pat","keepsnap","removevv"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "								
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Disable-3ParRcopyVV   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [$a]  can be used only . "
		}
	}
	if ($VV_name)
	{		
		$cmd+=" $VV_name "	
	}	
	else
	{
		return " FAILURE :  VV_name is mandatory for to execute  "
	}
	if ($Group_name)
	{		
		$cmd+=" $Group_name "	
	}	
	else
	{
		return " FAILURE :  Group_name is mandatory for to execute  "
	}
		
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Disable-3ParRcopyVV command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Disable-3ParRcopyVV
####################################################################################################################
## FUNCTION Show-3ParRcopyTransport
####################################################################################################################
Function Show-3ParRcopyTransport
{
<#
  .SYNOPSIS
    The Show-3ParRcopyTransport command shows status and information about end-to-end transport for Remote Copy in the system.

  .DESCRIPTION
    The Show-3ParRcopyTransport command shows status and information about end-to-end
    transport for Remote Copy in the system.
	
  .EXAMPLE
   Show-3ParRcopyTransport - option rcip
 
  .EXAMPLE
   Show-3ParRcopyTransport - option rcfc
   
  .PARAMETER option
  
    -rcip
        Show information about Ethernet end-to-end transport.

    -rcfc
        Show information about Fibre Channel end-to-end transport.
    
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Show-3ParRcopyTransport
    LASTEDIT: 08/04/2015
    KEYWORDS: Show-3ParRcopyTransport
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(	
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
						
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
		)	
	
	Write-DebugLog "Start: In Show-3ParRcopyTransport   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3ParRcopyTransport   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3ParRcopyTransport   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "showrctransport "
	
	if($option)
	{
		$a = "rcip","rcfc"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "								
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Show-3ParRcopyTransport   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [$a]  can be used only . "
		}
	}
			
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Show-3ParRcopyTransport command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Show-3ParRcopyTransport

####################################################################################################################
## FUNCTION Get-3ParSRAOMoves
####################################################################################################################
Function Get-3ParSRAOMoves
{
<#
  .SYNOPSIS
    The Get-3ParSRAOMoves command shows the space that AO has moved between tiers.
	
  .DESCRIPTION
    The Get-3ParSRAOMoves command shows the space that AO has moved between tiers.
	
  .EXAMPLE
   Get-3ParSRAOMoves -btsecs 7200
   
   .EXAMPLE
   Get-3ParSRAOMoves -etsecs 7200
   
   .EXAMPLE
   Get-3ParSRAOMoves -oneline 
   
   .EXAMPLE
   Get-3ParSRAOMoves -withvv 
   
   .EXAMPLE
   Get-3ParSRAOMoves -VV_name XYZ
  
  .PARAMETER 
  	.PARAMETER btsecs 
        Select the begin time in seconds for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - The absolute time as a text string in one of the following formats:
            - Full time string including time zone: "2012-10-26 11:00:00 PDT"
            - Full time string excluding time zone: "2012-10-26 11:00:00"
            - Date string: "2012-10-26" or 2012-10-26
            - Time string: "11:00:00" or 11:00:00
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the time at which the report begins is 12 ho                                                          urs ago.
        If -btsecs 0 is specified then the report begins at the earliest sample.

    .PARAMETER etsecs 
        Select the end time in seconds for the report.
        The value can be specified as either
        - The absolute epoch time (for example 1351263600).
        - The absolute time as a text string in one of the following formats:
            - Full time string including time zone: "2012-10-26 11:00:00 PDT"
            - Full time string excluding time zone: "2012-10-26 11:00:00"
            - Date string: "2012-10-26" or 2012-10-26
            - Time string: "11:00:00" or 11:00:00
        - A negative number indicating the number of seconds before the
          current time. Instead of a number representing seconds, <secs> can
          be specified with a suffix of m, h or d to represent time in minutes
          (e.g. -30m), hours (e.g. -1.5h) or days (e.g. -7d).
        If it is not specified then the report ends with the most recent
        sample.

    .PARAMETER oneline
        Show data in simplified format with one line per AOCFG.

    .PARAMETER VV_name
        Limit the analysis to VVs with names that match one or more of
        the specified names or glob-style patterns. VV set names must be
        prefixed by "set:".  Note that snapshot VVs will not be considered
        since only base VVs have region space.

    .PARAMETER withvv
        Show the data for each VV.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3ParSRAOMoves
    LASTEDIT: 03/08/2017
    KEYWORDS: Get-3ParSRAOMoves
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$btsecs,
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$etsecs,
		
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$oneline,
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$VV_name,
		
		[Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
		[switch]
		$withvv,
		
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Get-3ParSRAOMoves   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3ParSRAOMoves   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3ParSRAOMoves   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "sraomoves "
	
	if ($btsecs)
	{		
		$cmd+=" -btsecs $btsecs "	
	}	
	if ($etsecs)
	{		
		$cmd+=" -etsecs $etsecs "	
	}
	if ($oneline)
	{		
		$cmd+=" -oneline "	
	}
	if ($VV_name)
	{		
		$cmd+=" -vv $VV_name "	
	}
	if ($withvv)
	{		
		$cmd+=" -withvv "	
	}	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Get-3ParSRAOMoves command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Get-3ParSRAOMoves
####################################################################################################################
## FUNCTION Show-3ParVVolum
####################################################################################################################
Function Show-3ParVVolum
{
<#
  .SYNOPSIS
    The Show-3ParVVolum command displays information about all virtual machines
    (VVol-based) or a specific virtual machine in a system.  This command
    can be used to determine the association between virtual machines and
    their associated virtual volumes. showvvolvm will also show the
    accumulation of space usage information for a virtual machine.

  .DESCRIPTION
    The Show-3ParVVolum command displays information about all virtual machines
    (VVol-based) or a specific virtual machine in a system.  This command
    can be used to determine the association between virtual machines and
    their associated virtual volumes. showvvolvm will also show the
    accumulation of space usage information for a virtual machine.

  .EXAMPLE
	Show-3ParVVolum -container_name XYZ -option listcols 
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option d 
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option sp 
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option summary 
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option binding
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option vv
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option rcopy
	
	.EXAMPLE
	Show-3ParVVolum -container_name XYZ -option autodismissed
	
  .PARAMETER container_name
    The name of the virtual volume storage container. May be "sys:all" to display all VMs.
	
  .PARAMETER option  
	-listcols
        List the columns available to be shown in the -showcols option
        below (see "clihelp -col showvvolvm" for help on each column).

        By default with mandatory option -sc, (if none of the information selection options
        below are specified) the following columns are shown:
        VM_Name GuestOS VM_State Num_vv Physical Logical
    
    -d
        Displays detailed information about the VMs. The following columns are shown:
        VM_Name UUID Num_vv Num_snap Physical Logical GuestOS VM_State UsrCPG SnpCPG Container CreationTime

    -sp
        Shows the storage profiles with constraints associated with the VM.
        Often, all VVols associated with a VM will use the same storage profile.
        However, if vSphere has provisioned different VMDK volumes with different
        storage profiles, only the storage profile for the first virtual disk
        (VMDK) VVol will be displayed. In this case, use the -vv option to display
        storage profiles for individual volumes associated with the VM. Without
        the -vv option, the following columns are shown:
        VM_Name SP_Name SP_Constraint_List

    -summary
        Shows the summary of virtual machines (VM) in the system, including
        the total number of the following: VMs, VVs, and total physical and
        exported space used. The following columns are shown:
        Num_vm Num_vv Physical Logical

    -binding
        Shows the detailed binding information for the VMs. The binding could
        be PoweredOn, Bound (exported), or Unbound. When it is bound,
        showvvolvm displays host names to which it is bound. When it is bound
        and -vv option is used, showvvolvm displays the exported LUN templates
        for each volume, and the state for actively bound VVols. PoweredOn
        means the VM is powered on. Bound means the VM is not powered on,
        but either being created, modified, queried or changing powered state
        from on to off or off to on. Unbound means the VM is powered off.
        The following columns are shown:
        VM_Name VM_State Last_Host Last_State_Time Last_Pwr_Time

        With the -vv option, the following columns are shown:
        VM_Name VVol_Name VVol_Type VVol_State VVol_LunId Bind_Host Last_State_Time

    -vv
        Shows all the VVs (Virtual Volumes) associated with the VM.
        The following columns are shown:
        VM_Name VV_ID VVol_Name VVol_Type Prov Physical Logical

        The columns displayed can change when used with other options.
        See the -binding option above.

    -rcopy
        Shows the remote copy group name, sync status, role, and last sync time of the
        volumes associated with a VM. Note that if a VM does not report as synced, the
        last sync time for the VM DOES NOT represent a consistency point. True
        consistency points are only represented by the showrcopy LastSyncTime. This
        option may be combined with the -vv, -binding, -d, and -sp options.

    -autodismissed
        Shows only VMs containing automatically dismissed volumes. Shows only
        automatically dismissed volumes when combined with the -vv option.
		
  .PARAMETER VM_name 
        Specifies the VMs with the specified name (up to 80 characters in length).
        This specifier can be repeated to display information about multiple VMs.
        This specifier is not required. If not specified, showvvolvm displays
        information for all VMs in the specified storage container.
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Show-3ParVVolum
    LASTEDIT: 03/08/2017
    KEYWORDS: Show-3ParVVolum
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(
	
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$container_name,	

		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false,ValueFromPipeline=$true)]
		[System.String]
		$VM_name,
				
		[Parameter(Position=6, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Show-3ParVVolum   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Show-3ParVVolum   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Show-3ParVVolum   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "showvvolvm -sc "
	
	if ($container_name)
	{		
		$cmd+=" $container_name "	
	}	
	else
	{
		return " FAILURE :  container_name is mandatory to execute Show-3ParVVolum command "
	}	
	if ($option)
	{
		$a = "listcols","d","sp","summary","binding","rcopy","vv","autodismissed"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [$a]  can be used only . "
		}
	}	
	if ($VM_name)
	{		
		$cmd+=" $VM_name "	
	}	
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Show-3ParVVolum command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Show-3ParVVolum
####################################################################################################################
## FUNCTION Set-3ParVVolSC
####################################################################################################################
Function Set-3ParVVolSC
{
<#
  .SYNOPSIS
    Set-3ParVVolSC can be used to create and remove storage containers for VMware Virtual Volumes (VVols).

    VVols are managed by the vSphere environment, and storage containers are
    used to maintain a logical collection of them. No physical space is
    pre-allocated for a storage container. In the HPE 3PAR OS, special
    VV sets (see showvvset) are used to manage VVol storage containers.

  .DESCRIPTION
    Set-3ParVVolSC can be used to create and remove storage containers for
    VMware Virtual Volumes (VVols).

    VVols are managed by the vSphere environment, and storage containers are
    used to maintain a logical collection of them. No physical space is
    pre-allocated for a storage container. In the HPE 3PAR OS, special
    VV sets (see showvvset) are used to manage VVol storage containers.

  .EXAMPLE
	Set-3ParVVolSC -vvset XYZ (Note: set: already include in code please dont add with vvset)
	
  .PARAMETER option
	-create
        An empty existing <vvset> not already marked as a VVol Storage
        Container will be updated. The VV set should not contain any
        existing volumes (see -keep option below), must not be already
        marked as a storage container, nor may it be in use for other
        services, such as for remote copy groups, QoS, etc.

    -remove
        If the specified VV set is a VVol storage container, this option will remove the VV set storage container and remove all of the associated volumes. The user will be asked to confirm that the associated volumes
        in this storage container should be removed.

    -keep
        Used only with the -create option. If specified, allows a VV set with existing volumes to be marked as a VVol storage container.  However,
        this option should only be used if the existing volumes in the VV set
        are VVols.
	
  .PARAMETER vvset
	The Virtual Volume set (VV set) name, which is used, or to be used, as a VVol storage container.

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Set-3ParVVolSC
    LASTEDIT: 03/08/2017
    KEYWORDS: Set-3ParVVolSC
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(			
		
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$vvset,
		
		[Parameter(Position=2, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=3, Mandatory=$false)]
		[switch]
		$keep,
		
		[Parameter(Position=4, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Set-3ParVVolSC   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Set-3ParVVolSC   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Set-3ParVVolSC   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= " setvvolsc -f"
			
	if ($option)
	{
		$a = "create","remove"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [$a]  can be used only . "
		}
	}	
	else
	{
		return " FAILURE :  option is mandatory to execute Set-3ParVVolSC command "
	}
	if($keep)
	{
		if($option -eq "create")
		{
			$cmd+=" -keep "
		}
		else
		{
			return  "Used keep only with the -create option."
		}
	}
	if ($vvset)
	{		
		$cmd+="  set:$vvset "	
	}	
	else
	{
		return " FAILURE :  vvset is mandatory to execute Set-3ParVVolSC command"
	}
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Set-3ParVVolSC command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Set-3ParVVolSC
####################################################################################################################
## FUNCTION Get-3ParVVolSC
####################################################################################################################
Function Get-3ParVVolSC
{
<#
  .SYNOPSIS
     The Get-3ParVVolSC command displays VVol storage containers, used to contain
    VMware Volumes for Virtual Machines (VVols).

  .DESCRIPTION
     The Get-3ParVVolSC command displays VVol storage containers, used to contain
    VMware Volumes for Virtual Machines (VVols).

  .EXAMPLE
	Get-3ParVVolSC 
	
  .EXAMPLE
	Get-3ParVVolSC -option d -SC_name test
	
  .PARAMETER option  
	-d
        Displays detailed information about the storage containers, including any
        VVols that have been auto-dismissed by remote copy DR operations.
		
  .PARAMETER SC_name  
		Storage Container
  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3ParVVolSC
    LASTEDIT: 03/08/2017
    KEYWORDS: Get-3ParVVolSC
   
  .Link
     Http://www.hpe.com
 
 #Requires PS -Version 3.0

 #>
[CmdletBinding()]
	param(			

		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$option,
		
		[Parameter(Position=1, Mandatory=$false)]
		[System.String]
		$SC_name,
				
		[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection       
	)	
	
	Write-DebugLog "Start: In Get-3ParVVolSC   - validating input values" $Debug 
	#check if connection object contents are null/empty
	if(!$SANConnection)
	{		
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3ParVVolSC   since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3ParVVolSC   since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult = Test-PARCli
	if($plinkresult -match "FAILURE :")
	{
		write-debuglog "$plinkresult" "ERR:" 
		return $plinkresult
	}		
	$cmd= "showvvolsc "	
		
	if ($option)
	{
		$a = "d","listcols"
		$l=$option
		if($a -eq $l)
		{
			$cmd+=" -$option "			
		}
		else
		{ 
			Write-DebugLog "Stop: Exiting  Get-3parPD   since -option $option in incorrect "
			Return "FAILURE : -option :- $option is an Incorrect option  [$a]  can be used only . "
		}
	}	
	if ($SC_name)
	{		
		$cmd+=" $SC_name "	
	}	
	
	$Result = Invoke-3parCLICmd -Connection $SANConnection -cmds  $cmd
	write-debuglog " The Get-3ParVVolSC command creates and admits physical disk definitions to enable the use of those disks --> $cmd" "INFO:" 
	return 	$Result	
} # End Get-3ParVVolSC

Export-ModuleMember Get-ConnectedSession , Invoke-3parCLICmd , Set-3parPoshSshConnectionPasswordFile ,Set-3parPoshSshConnectionUsingPasswordFile , New-3ParPoshSshConnection , Ping-3parRCIPPorts , Get-3ParVVolSC , Set-3ParVVolSC , Show-3ParVVolum , Get-3ParSRAOMoves , Add-3parRcopytarget , Add-3parRcopyVV , Test-3parRcopyLink , Sync-Recover3ParDRRcopyGroup , Disable-3ParRcopylink , Disable-3ParRcopytarget , Disable-3ParRcopyVV , Show-3ParRcopyTransport , Approve-3parRCopyLink , Get-3parSystemInformation ,Show-3parSRStatIscsi , Show-3pariSCSISessionStatistics , Show-3pariSCSIStatistics , Show-3parSRSTATISCSISession ,  Start-3parFSNDMP , Stop-3parFSNDMP , Show-3parPortARP , Show-3parPortISNS , Show-3parISCSISession , Close-3PARConnection , Set-3parRCopyTargetWitness , Test-3parVV , Add-3parVV , New-3parFed, Join-3parFed, Set-3parFed , Remove-3parFed , Show-3parFed, Show-3parPeer , Import-3parVV , Compress-3parVV , Get-3parHistRCopyVV , New-3parRCopyGroupCPG , Set-3parRCopyTarget, Remove-3parRCopyVVFromGroup , Remove-3parRCopyTarget , Remove-3parRCopyGroup , Set-3parRCopyGroupPeriod , Remove-3parRCopyTargetFromGroup , Set-3parRCopyGroupPol , Set-3parRCopyTargetPol , Set-3parRCopyTargetName , Start-3parRCopyGroup ,Start-3parRcopy, Get-3parRCopy , Get-3parStatRCopy , Stop-3parRCopy , Stop-3parRCopyGroup , Sync-3parRCopy , New-3parRCopyGroup , New-3parRCopyTarget , Get-3parstatPD , Get-3parStatVlun , Get-3parStatVV , Get-3parStatRCVV , Get-3parStatPort , Get-3parStatChunklet, Get-3parStatLink , Get-3parStatLD , Get-3parStatCPU , Get-3parHistChunklet , Get-3parHistVV , Get-3parHistVLUN , Get-3parStatCMP , Get-3parHistPort , Get-3parHistLD , Get-3parHistPD, Test-3parPD , Set-3parstatch , Set-3parstatch  , Set-3parStatpdch , Approve-3parPD , Get-3parPD , Get-3parCage , Set-3parCage , Set-3parPD , Find-3parCage , Get-3parHostPorts , Get-3parFCPorts , Get-3parFCPortsToCSV ,Set-3parFCPorts,  New-3parCLIConnection , Set-3parHostPorts , New-3parCPG, New-3parVVSet, New-Volume, Export-Volume, New-3parVV,New-3parVLUN, Get-3parVLUN, Remove-3parVLUN, Get-3parVV, Remove-3parVV, New-3parHost, Set-3parHost, New-3parHostSet, Get-3parHost, Remove-3parHost, Get-3parHostSet, Get-3parVVSet, Get-3parCPG, Remove-3parHostSet, Remove-3parVVSet, Remove-3parCPG, Get-3parCmdList,Get-3parVersion, Get-3parTask, New-3parVVCopy, New-3parGroupVVCopy, Set-3parVV, Push-3parVVCopy, New-3parSnapVolume, Push-3parSnapVolume, New-3parGroupSnapVolume, Push-3parGroupSnapVolume, Get-3parVVList, Get-3parSystem, Get-3parSpare, Remove-3parSpare, Get-3parSpace, New-3parSpare,Push-3parChunklet, Push-3parChunkletToSpare, Push-3parPdToSpare, Push-3parPd,Push-3parRelocPD,Get-3parSR,Start-3parSR, Stop-3parSR,Get-3parSRStatCPU, Get-3parSRHistLd, Get-3parSRHistPD, Get-3parSRHistPort, Get-3parSRHistVLUN,  Get-3parSRAlertCrit, Set-3parSRAlertCrit, Get-3parSRStatCMP, Get-3parSRStatCache, Get-3parSRStatLD, Get-3parSRStatPD, Get-3parSRStatPort, Get-3parSRStatVLUN, Get-3parSRCPGSpace , Get-3parSRLDSpace, Get-3parSRPDSpace, Get-3parSRVVSpace , Get-3parSRAOMoves,Set-3parPassword,Get-3parUserConnection, New-3parSRAlertCrit, Remove-3parSRAlertCrit,Update-3parVV