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

Connect-VIServer -Server vCenterServer



$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$excelWB = $excel.Workbooks.Add()
$excelWS = $excel.Worksheets.Item(1)
$excelWS.Rows(1).RowHeight = 50
$excelWS.Rows(1).VerticalAlignment = -4108
$excelWS.Rows(1).HorizontalAlignment = -4108

#$excelWS.Cells | gm -Force
#$excel
[string []] $properties = @("Кластер","Группа","Дисковая полка","Наименование сервера","Проект","Суб Проект","vCPU","RAM","HDD")
for ([int]$i=1; $i -le ([string []] $properties).Count; $i++)
{
    $excelWS.Cells.Item(1,$i) = "{0}" -f $properties[$i-1]
    $excelWS.Cells.Item(1,$i).Interior.ColorIndex = 15
    $excelWS.Cells.Item(1,$i).Borders.linestyle = 1
    $excelWS.Cells.Item(1,$i).Borders.Weight = 2
}



$vms = @(Get-VM)
[int]$n = 2
$vms.ForEach({
    $cl = $_ | Get-Cluster
    $ds = $_ | Get-Datastore
    if (!$cl) 
    {
        $cl = $_ | Get-VMHost
    }
    $vmProperties = @($cl.Name,$_.vapp,$ds.Name,$_.name,"0","0",$_.numcpu,[Convert]::ToInt32($_.MemoryGb),[Convert]::ToInt32($_.ProvisionedSpaceGB))
    for ([int]$k=1; $k -le ([string []] $vmProperties).Count; $k++)
    {        
        $excelWS.Cells.Item($n,$k) = "{0}" -f $vmProperties[$k-1]
        $excelWS.Columns($k).Autofit() 
    }
    $n++
})

$excel

#$ExcelWS.SaveAs('D:\ServicesStatusReport.xlsx')
#$Excel.Quit()



#$vms | Get-Datastore  gm -Force
#$_ 
#$cl = Get-Cluster -VM "vm"
#$cl | gm -Force
#Get-VM -Location

#$vms | Get-VMHost