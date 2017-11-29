################### Load PowerCli modules ###################
$moduleList = @(
    "VMware.VimAutomation.Core",
    "VMware.VimAutomation.Vds",
    "VMware.VimAutomation.Cloud",
    "VMware.VimAutomation.PCloud",
    "VMware.VimAutomation.Cis.Core",
    "VMware.VimAutomation.Storage",
    "VMware.VimAutomation.HorizonView",
    "VMware.VimAutomation.HA",
    "VMware.VimAutomation.vROps",
    "VMware.VumAutomation",
    "VMware.DeployAutomation",
    "VMware.ImageBuilder",
    "VMware.VimAutomation.License"
    )

$productName = "PowerCLI"
$productShortName = "PowerCLI"

$loadingActivity = "Loading $productName"
$script:completedActivities = 0
$script:percentComplete = 0
$script:currentActivity = ""
$script:totalActivities = `
   $moduleList.Count + 1

function ReportStartOfActivity($activity) {
   $script:currentActivity = $activity
   Write-Progress -Activity $loadingActivity -CurrentOperation $script:currentActivity -PercentComplete $script:percentComplete
}
function ReportFinishedActivity() {
   $script:completedActivities++
   $script:percentComplete = (100.0 / $totalActivities) * $script:completedActivities
   $script:percentComplete = [Math]::Min(99, $percentComplete)
   
   Write-Progress -Activity $loadingActivity -CurrentOperation $script:currentActivity -PercentComplete $script:percentComplete
}

function LoadModules(){
   ReportStartOfActivity "Searching for $productShortName module components..."
   
   $loaded = Get-Module -Name $moduleList -ErrorAction Ignore | % {$_.Name}
   $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction Ignore | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}
   
   ReportFinishedActivity
   
   foreach ($module in $registered) {
      if ($loaded -notcontains $module) {
		 ReportStartOfActivity "Loading module $module"
         
		 Import-Module $module
		 
		 ReportFinishedActivity
      }
   }
}

LoadModules


################### End Load PowerCli modules ###################



Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

########### ReadMe #############
#
# Меняем имя vCenter сервера, ставим тот в котором будет выполнятся поиск.
# Задаём сеть, меняем переменную $network 
# В екселе значения в колонке device, ставим так как в таблице в nets.ulf.local
#
########### End ReadMe #############

Connect-VIServer -Server vCenterServer

$network = "10.9.9*"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$excelWB = $excel.Workbooks.Open("D:\scripts\phpipam_template_2017-11-08.xls")
$excelWS = $excel.Worksheets.Item("template")
#$excelWS.Rows(1).RowHeight = 50
#$excelWS.Rows(1).VerticalAlignment = -4108
#$excelWS.Rows(1).HorizontalAlignment = -4108

$vms = @(Get-VM)
[int] $n = 3
$vms.ForEach({
    $vmg = $_ | Get-VMGuest
    $vm = $_
    [string []]$ipvm = @(($vmg).IPAddress -like $network)
    if ($ipvm) {
        $ipvm.foreach({
        $ipoct = @(($_).Split("."))
        if ([Convert]::ToInt32($ipoct[3]) -gt 3) {
            $properties = @($_,"",$vm.Name,($vmg).HostName,"","","",($vmg).OSFullName)
            for ([int]$k=1; $k -le ([string []] $properties).Count; $k++)
                { 
                $excelWS.Cells.Item($n,$k) = "{0}" -f $Properties[$k-1]
                $excelWS.Columns($k).Autofit()
                }
            $n++
            #"{0},{1},{2},{3},{4}" -f  $_,$vm.Name,($vmg).HostName,"",($vmg).OSFullName
            }
        }) 
    }
})

