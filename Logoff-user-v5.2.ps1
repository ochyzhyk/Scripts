#$syncHash = [hashtable]::Synchronized(@{})
#$newRunspace =[runspacefactory]::CreateRunspace()
#$newRunspace.ApartmentState = "STA"
#$newRunspace.ThreadOptions = "ReuseThread"         
#$newRunspace.Open()
#$newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)          
#$psCmd = [PowerShell]::Create().AddScript({   

#-----------Begin code---------------

#ERASE ALL THIS AND PUT XAML BELOW between the @" "@
$inputXML = @"
<Window x:Name="MyWindow" x:Class="WpfApplication1.TestWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication1"
        mc:Ignorable="d"
        Title="Logoff RD Users" HorizontalAlignment="Left" Height="350" Width="400">
    <Grid Margin="0,0,2,-2">
        <Button x:Name="button" Content="Поиск" HorizontalAlignment="Left" Margin="290,20,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="button1" Content="Отключить" HorizontalAlignment="Left" Margin="290,67,0,0" VerticalAlignment="Top" Width="75"/>
        <ListBox x:Name="listBox" HorizontalAlignment="Left" Height="200" Margin="99,67,0,0" VerticalAlignment="Top" Width="160"/>
        <ComboBox x:Name="comboBox" Margin="79,20,0,0" Height="23" HorizontalAlignment="Left" VerticalAlignment="Top" Width="180" IsDropDownOpen="False" IsEditable="True"/>
        
        <TextBlock x:Name="textBlock" HorizontalAlignment="Left" Margin="99,280,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Height="21" Width="204"/>
        <Label x:Name="label" Content="Логин" HorizontalAlignment="Left" Margin="23,20,0,0" VerticalAlignment="Top"/>
        <Label x:Name="label1" Content="Коллекции" HorizontalAlignment="Left" Margin="23,77,0,0" VerticalAlignment="Top"/>

    </Grid>
</Window>
"@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
 
#===========================================================================
# Actually make the objects work
#===========================================================================

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$WPFtextBlock.Text = "Введите логин и нажмите ""Поиск"""


$Collection=$WPFlistbox.SelectedItem
$WPFbutton.Background = "White"
$WPFbutton1.Background = "White"

function Invoke-SQL {
    param(
        [string] $column,
        [string] $pattern
    )

    [string] $dataSource = "srvdb.dc.local"
    [string] $database = "RDS"
    [string] $sqlCommand = "select * from rds.dbo.[searchUsersSession] where {0} LIKE '{1}%'" -f $column,$pattern
    $connectionString = "Data Source=$dataSource; " +
            "User ID= rdsview; " +
            "Password= rdsview;" +
            "Initial Catalog=$database"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    $dataSet.Tables
}

Function Confirm-Message{
    param(
    $UserName = $WPFcomboBox.Text,
    $Collection=$WPFlistbox.SelectedItem,
    $oReturn=[System.Windows.Forms.MessageBox]::Show("Пользователь: $UserName будет отключен от $Collection","Подтверждение",[System.Windows.Forms.MessageBoxButtons]::OKCancel)
    )
    switch ($oReturn){
	    "OK" {
		    Logoff-user
		    
	    } 
	    "Cancel" {
		   $WPFtextBlock.Text = "Отключение отменено"
	    } 
    }
}

Function Logoff-user {
    param(
    $UserName = $WPFcomboBox.Text,
    $Collection=$WPFlistbox.SelectedItem
    )
    $a = (Invoke-SQL ("CollectionName") $Collection) | ? {$_.UserName -eq "$UserName"}
    $cmd = "logoff /SERVER:{0} {1}" -f $a.ServerName, $a.SessionId
    Invoke-Expression -Command $cmd
    $WPFtextBlock.Text = "Отключение завершено"
 }

Function Get-Collection {
    param(
    $UserName = $WPFcomboBox.Text
    )
    if ($WPFcomboBox.Text -eq "") {
    $WPFtextBlock.Text = "Введите имя пользователя"
    } else {
    $WPFlistbox.Items.Clear()
    $CollList=@((Invoke-SQL ("UserName") $UserName))
            foreach ($Collection in $CollList) {
            $WPFlistbox.Items.Add($Collection.CollectionName) 
            }
    $WPFtextBlock.Text = "Поиск для $UserName завершен"
    }
}

#$WPFcomboBox | gm -Force | where name -like "*drop*"

$WPFcomboBox.add_DropDownOpened({
    $UserName = $WPFcomboBox.Text
    $cmdlets = @((Invoke-SQL ("UserName") $UserName).username | sort -Unique)
    $WPFcomboBox.itemsSource = $cmdlets
})

$WPFbutton.Add_Click({
    $WPFtextBlock.Text = "Поиск..."
    Get-Collection
})

$WPFbutton1.Add_Click({
    $WPFtextBlock.Text = "Отключение пользователя..."
    Confirm-Message
})




#Sample entry of how to add data to a field
 
#$vmpicklistView.items.Add([pscustomobject]@{'VMName'=($_).Name;Status=$_.Status;Other="Yes"})
 
#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | out-null

#----------End code ------------------
#})
#$psCmd.Runspace = $newRunspace
#$data = $psCmd.BeginInvoke()