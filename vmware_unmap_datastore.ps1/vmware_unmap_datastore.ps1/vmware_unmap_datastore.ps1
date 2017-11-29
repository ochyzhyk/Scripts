Clear-Host
$ErrorActionPreference = "Continue"
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

@"
## vmware_unmap_datastore.ps1 #################################################
Usage:        powershell -ExecutionPolicy Bypass -File ./vmware_unmap_datastore.ps1

Purpose:      Dumps Datastore (in GB): Capacity, Free, and Uncommitted space to
              to CSV and runs ESXCli command 'unmap' to retrieve unused space
              on Thin Provisioned LUNs.

Requirements: Windows Powershell and VI Toolkit

Assumptions:  1MB block sizes

Created By:   lars.bjerke@augustschell.com
History:      06/20/2014  -  Created
              07/17/2014  -  Modified by Matthew McDonald (matthew@matthewmcdonald.net)
                             to take into consideration single vCenter with multiple 
                             Datacenters/Hosts that have unique datastores (not accessible
                             to all hosts).
              03/05/2015  -  Modified by Christopher Harding (charding@dai-coar.com) to
                             remove assumtions that all hosts have access to all datastores,
                             even inside the same cluster without re-processing datastores.
                             Addionally, variablized the unmap block count to 0.5% of the
                             free blocks for significantly decreased procesing time.
###############################################################################
"@

## Prompt Administrator for vCenter Server ####################################
# Comments have been placed around the static assignments, uncomment and adjust
# to use as a scheduled task. Make sure to comment the input box option to use
# this method.
###############################################################################
# $VCServer = @(
#     "VCEN-001.DOMAIN.COM",
#     "VCEN-002.DOMAIN.COM"
# );
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$VCServer = [Microsoft.VisualBasic.Interaction]::InputBox(
                "vCenter Server FQDN or IP",
                "PowerCLI Prompt: vCenter Server Query",
                "VCEN-001.TEST.DEV.DOMAIN.COM")


## Filename and path to save the CSV ##########################################
###############################################################################
$datestamp = $(((get-date).ToUniversalTime()).ToString("yyyyMMdd"))
$timestamp = $(((get-date).ToUniversalTime()).ToString("hhmmss"))
#$output_path = [Environment]::GetFolderPath("mydocuments")
$output_path = "C:\Temp"
$output_file = $output_path + "\datastore_info-" + $datestamp + "-" + $timestamp + " .csv"

## Ensure VMware Automation Core Snap In is loaded ############################
###############################################################################
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) {
     Add-PSSnapin VMware.VimAutomation.Core      }

## Unmap can take hour+ per data store on first run, remove timeout ###########
###############################################################################
Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

## Ignore Certificates Warning ################################################
###############################################################################
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

## Connect to vCenter Server ##################################################
# Prompt user for vCenter creds every time unless creds are stored using:
###############################################################################
# New-VICredentialStoreItem -Host $VIServer -User "AD\user" -Password 'pass'
$VC = Connect-VIServer $VCServer
Write-verbose "Connected to '$($VC.Name):$($VC.port)' as '$($VC.User)'"


## Establish structure to store CSV data ######################################
# Create a CSV to store data
###############################################################################
$report = @()

## Establish structure to remove datastores from processing ###################
# Create a master list of datastores that have been processed already
###############################################################################
$dsmasterlist = @()

## CSV Collect Data ###########################################################
# Function to collect datastore usage information to be stored in CSV
###############################################################################
function get_datastore_usage {
    Write-Verbose "[ $($dsv.Name) ] - Gathering statistics..."
    $row = "" |select TIMESTAMP, DATASTORE, CAPACITY_GB, FREE_GB, UNCOMMITED_GB
    $row.TIMESTAMP = $(((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmssZ"))
    $row.DATASTORE = $ds.Name
    $row.CAPACITY_GB = [int]($ds.CapacityGB)
    $row.FREE_GB = [int]($ds.FreeSpaceGB)
    $row.UNCOMMITED_GB = [int]($dsv.Summary.Uncommitted / (1024 * 1024 * 1024))
    return $row
    }

## Unmap ######################################################################
# Natively, unmap creates a maximum of 200 (changable) 1MB files at a time to
# 100%. To decrease processing time, this has been variablized to being 0.5% of
# the free space in MB.
###############################################################################
function reclaim_datastore_used_space {
    Write-Verbose "[ $($dsv.Name) ] - Running unmap with a block count of $unmapSize - can take 30 minutes before failure"
    try {
        $RETVAL = $ESXCLI.storage.vmfs.unmap($unmapSize, $ds.Name, $null)
        }
    catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViError]{
        Write-Verbose $_.Exception.Message
        }
    }

# The sorting below does nothing for procesing time, but creates a more logical
# run path, for those running this script interactively.

ForEach ($VMDatacenter in (Get-Datacenter | Sort)) {
	ForEach ($VMCluster in ($VMDatacenter | Get-Cluster | Sort)) {
        ForEach ($ESXiHost in ($VMCluster | Get-VMHost | Sort)) {
            $ESXCLI = Get-EsxCli -VMHost $ESXiHost
		    Write-Verbose "Using ESXi host '($ESXiHost)' for CLI"
		
		    ## Loop through datastores ####################################################
		    # Loops through all datastores seen by vCenter.  If the datastore is accessible
		    # and capable of thinprovisioning: Gathers datastore usage data, runs unmap
		    ###############################################################################
		    [System.Collections.ArrayList]$dslist = @()
            $dslist = Get-Datastore -VMHost $ESXiHost | Sort
            ForEach ($dsml in $dsmasterlist) {
                $dslist.Remove($dsml)
            }
            foreach ($ds in $dslist) {
                $dsmasterlist += $ds
			    "Datastore: $ds"
			    $dsv = $ds | Get-View
			    if ($dsv.Summary.accessible -and $dsv.Capability.PerFileThinProvisioningSupported) {
				    Write-Verbose "[ $($dsv.Name) ] - Refreshing Datastore Data..."
				    $dsv.RefreshDatastore()
				    $dsv.RefreshDatastoreStorageInfo()
                    
                    [decimal]$freeDSSpace = $ds.FreeSpaceMB
                    $unmapSize = [MATH]::round($freeDSSpace*.005)

				    $report += get_datastore_usage
				    reclaim_datastore_used_space
			    }
		    }
	    }
    }
}

## Write CSV data to file #####################################################
###############################################################################
$report |Export-Csv $output_file -NoTypeInformation

## Open CSV file using Notepad ################################################
###############################################################################
Start-Process notepad -ArgumentList $output_file

## Properly disconnect from vCenter Server ####################################
###############################################################################
Disconnect-VIServer $VC -Confirm:$false