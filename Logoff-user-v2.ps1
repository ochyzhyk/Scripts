[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$main_form = New-Object System.Windows.Forms.Form
$main_form.StartPosition  = "CenterScreen"
$main_form.Text ='USER KILL'
$main_form.Width = 300
$main_form.Height = 200
$main_form.AutoSize = $True

$main_form.KeyPreview = $True
$main_form.Add_KeyDown({if ($_.KeyCode -eq "Enter")
    {$button1.Click}})
$main_form.Add_KeyDown({if ($_.KeyCode -eq "Escape")
    {$main_form.Close()}})

#------------------- Блок "Отключение пользователя" --#
$GroupBox2 = New-Object System.Windows.Forms.GroupBox
$GroupBox2.AutoSize = $True
$GroupBox2.Location  = New-Object System.Drawing.Point(5,0)

$TabLabel1 = New-Object System.Windows.Forms.Label
$TabLabel1.Text = "Для отключения пользователя `nВведите имя."
$TabLabel1.Font = New-Object System.Drawing.Font("Times New Roman",12)
$TabLabel1.Location = New-Object System.Drawing.Point(20,10)
$TabLabel1.AutoSize = $true
$GroupBox2.Controls.Add($TabLabel1)

$TabLabel2 = New-Object System.Windows.Forms.Label
$TabLabel2.Text = ""
$TabLabel2.Location = New-Object System.Drawing.Point(20,82)
$TabLabel2.AutoSize = $true
$GroupBox2.Controls.Add($TabLabel2)

$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Location  = New-Object System.Drawing.Point(20,55)
$TextBox1.Size = New-Object System.Drawing.Size(100,25)
$GroupBox2.Controls.Add($TextBox1)

$DropDownBox = New-Object System.Windows.Forms.ComboBox
$DropDownBox.Location = New-Object System.Drawing.Size(20,100) 
$DropDownBox.Size = New-Object System.Drawing.Size(180,20) 
$DropDownBox.DropDownHeight = 200 
$GroupBox2.Controls.Add($DropDownBox) 

$CollList=@("Collection1","Collection2",..."CollectionN")

foreach ($Coll in $CollList) {
                      $DropDownBox.Items.Add($Coll)
                              } #end foreach


#$Collection=$DropDownBox.SelectedItem.ToString()  

#------------------- Поиск пользователя --#
function GetUser {
		if ($TextBox1.Text -ne "") {$LoginUser = $TextBox1.Text
        $Collection=$DropDownBox.SelectedItem.ToString()
		#$TabLabel2.Text = "Поиск..."
#        $colls = Get-RDSessionCollection
#        foreach ($coll in $colls) {
        $TabLabel2.Text = "Поиск..."
		$a = Get-RDUserSession -connectionbroker "srvCB.dc.local" -CollectionName $Collection | ? {$_.UserName -eq "$LoginUser"} |Select-Object UserName, SessionId, ServerName, SessionState
		$TabLabel2.Text = "Пользователь не найден $Collection"
			foreach ($item in $a){
			$ID = $item.SessionId
			$UserName = $item.UserName
			$ServerName = $item.ServerName
			$Status = $item.SessionState
			Confirm
			}
#            }
		}
	else {
	$TabLabel2.Text = "Введите имя!"
	}
}
#------------------- Конец (Поиск пользователя) --#

#------------------- Подтверждение отключения пользователя --#
Function Confirm {
	$TabLabel2.Text = "Ожидание подтверждения"
        $ConfirmWin = New-Object System.Windows.Forms.Form
        $ConfirmWin.StartPosition  = "CenterScreen"
        $ConfirmWin.Text = "Подтверждение отключения"
        $ConfirmWin.Width = 300
        $ConfirmWin.Height = 140
		$ConfirmWin.AutoSize = $True
        $ConfirmWin.ControlBox = 0

        $ConfirmWinCanButton = New-Object System.Windows.Forms.Button
        $ConfirmWinCanButton.add_click({$ConfirmWin.Close();$TabLabel2.Text = ""})
        $ConfirmWinCanButton.Text = "Нет"
        $ConfirmWinCanButton.AutoSize = 1
        $ConfirmWinCanButton.Location = New-Object System.Drawing.Point(100,55)
        $ConfirmWin.Controls.Add($ConfirmWinCanButton)
		
        $ConfirmWinOKButton = New-Object System.Windows.Forms.Button
        $ConfirmWinOKButton.add_click({
			Get-RDUserSession -connectionbroker "srvCB.dc.local" -CollectionName $Collection | ? {$_.UserName -eq "$UserName"} | Invoke-RDUserLogoff -Force
			$TabLabel2.Text = ""
			$ConfirmWin.Close()
			})
        $ConfirmWinOKButton.Text = "Да"
        $ConfirmWinOKButton.AutoSize = 1
        $ConfirmWinOKButton.Location = New-Object System.Drawing.Point(200,55)
		$ConfirmWin.Controls.Add($ConfirmWinOKButton)

        $ConfirmLabel = New-Object System.Windows.Forms.Label
        $ConfirmLabel.Text = "Отключить пользователя $UserName от сервера $ServerName`nСессия №$ID $Status"
        $ConfirmLabel.AutoSize = 1
        $ConfirmLabel.Location = New-Object System.Drawing.Point(10,10)
        $ConfirmWin.Controls.Add($ConfirmLabel)

		[void] $ConfirmWin.ShowDialog()
    }
#------------------- Конец (Подтверждение отключения пользователя) --#

$button2 = New-Object System.Windows.Forms.Button
$button2.add_click({GetUser})
$button2.Text = "Отключение"
$button2.Size = New-Object System.Drawing.Size(85,23)
$button2.Location = New-Object System.Drawing.Point(123,53)
$GroupBox2.Controls.Add($button2)

$main_form.AcceptButton = $button2

$main_form.Controls.Add($GroupBox2)
#------------------- Конец (Блок "Отключение пользователя") --#

[void] $Main_Form.ShowDialog()