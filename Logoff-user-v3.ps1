[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$main_form = New-Object System.Windows.Forms.Form
$main_form.StartPosition  = "CenterScreen"
$main_form.Text ='USER KILL'
$main_form.Width = 300
$main_form.Height = 250
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
$TabLabel1.Text = "Для отключения пользователя `nВыберите коллекцию и логин."
$TabLabel1.Font = New-Object System.Drawing.Font("Times New Roman",12)
$TabLabel1.Location = New-Object System.Drawing.Point(20,10)
$TabLabel1.AutoSize = $true
$GroupBox2.Controls.Add($TabLabel1)

$TabLabel2 = New-Object System.Windows.Forms.Label
$TabLabel2.Text = ""
$TabLabel2.Location = New-Object System.Drawing.Point(20,170)
$TabLabel2.AutoSize = $true
$GroupBox2.Controls.Add($TabLabel2)

$TabLabel3 = New-Object System.Windows.Forms.Label
$TabLabel3.Text = "Логин:"
$TabLabel3.Location = New-Object System.Drawing.Point(20,110)
$TabLabel3.AutoSize = $true
$GroupBox2.Controls.Add($TabLabel3)

$TabLabel4 = New-Object System.Windows.Forms.Label
$TabLabel4.Text = "Коллекция:"
$TabLabel4.Location = New-Object System.Drawing.Point(20,55)
$TabLabel4.AutoSize = $true
$GroupBox2.Controls.Add($TabLabel4)

$DropDownBox = New-Object System.Windows.Forms.ComboBox
$DropDownBox.Location = New-Object System.Drawing.Size(20,75) 
$DropDownBox.Size = New-Object System.Drawing.Size(120,25) 
$DropDownBox.DropDownHeight = 200 
$GroupBox2.Controls.Add($DropDownBox) 

$CollList=@("DC-03 (Itilium)", "DC-04", "1C TЄП", "Directum_TEST", "Tetra", "Казначейство-Test", "Directum", "NSI", "1С УАХ", "1С Райз", "1C UMAP", "1c UMAP+SmartMap", "1С Казначейство", "1С Мясо", "1c Audit", "Medoc", "1C Treasury AVG", "Liga", "1c distributions")

foreach ($Coll in $CollList) {
                      $DropDownBox.Items.Add($Coll)
                              } #end foreach

$DropDownBoxU = New-Object System.Windows.Forms.ComboBox
$DropDownBoxU.Location = New-Object System.Drawing.Size(20,130) 
$DropDownBoxU.Size = New-Object System.Drawing.Size(100,25) 
$DropDownBoxU.DropDownHeight = 200 
$GroupBox2.Controls.Add($DropDownBoxU)


#------------------- Отключение пользователя --#
function GetUser {
		if ($DropDownBoxU.SelectedItem.ToString()) {$LoginUser = $DropDownBoxU.SelectedItem.ToString()
        $Collection=$DropDownBox.SelectedItem.ToString()
        $FullName=Get-ADUser -Filter {SamAccountName -eq $LoginUser}
			foreach ($item in $FullName){
            $Name=$Item.Name
	      	$UserName = $Item.SamAccountName

			Confirm
			}
		}
	else {
	$TabLabel2.Text = "Введите имя!"
	}
}
#------------------- Конец (Отключение пользователя) --#

#------------------- Поиск пользователя в коллекции--#

function SearchUser {
        if ($DropDownBox.SelectedItem.ToString()) {
        $Collection=$DropDownBox.SelectedItem.ToString()
        $TabLabel2.Text = "Поиск..."
        $UserList=@(Get-RDUserSession -ConnectionBroker srv-rds100.ulf.local -CollectionName $Collection | Sort-Object UserName )
            foreach ($user in $UserList) {
            $DropDownBoxU.Items.Add($User.UserName) 
            }
        $TabLabel2.Text = "Поиск выполнен!"
        }
        else {
	    $TabLabel2.Text = "Введите имя коллекции!"
        }
}

#------------------- Конец (Поиск пользователя в коллекции)--#

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
        $ConfirmWinCanButton.Location = New-Object System.Drawing.Point(200,55)
        $ConfirmWin.Controls.Add($ConfirmWinCanButton)
		
        $ConfirmWinOKButton = New-Object System.Windows.Forms.Button
        $ConfirmWinOKButton.add_click({
			Get-RDUserSession -connectionbroker "srv-rds100.ulf.local" -CollectionName $Collection | ? {$_.UserName -eq "$UserName"} | Invoke-RDUserLogoff -Force
			$TabLabel2.Text = ""
			$ConfirmWin.Close()
			})
        $ConfirmWinOKButton.Text = "Да"
        $ConfirmWinOKButton.AutoSize = 1
        $ConfirmWinOKButton.Location = New-Object System.Drawing.Point(100,55)
		$ConfirmWin.Controls.Add($ConfirmWinOKButton)

        $ConfirmLabel = New-Object System.Windows.Forms.Label
        $ConfirmLabel.Text = "Подтверждение отключения пользователя: $Name `nЛогин: $UserName"
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
$button2.Location = New-Object System.Drawing.Point(125,129)
$GroupBox2.Controls.Add($button2)

$main_form.AcceptButton = $button2

$main_form.Controls.Add($GroupBox2)

$button2 = New-Object System.Windows.Forms.Button
$button2.add_click({SearchUser})
$button2.Text = "Поиск"
$button2.Size = New-Object System.Drawing.Size(85,23)
$button2.Location = New-Object System.Drawing.Point(145,74)
$GroupBox2.Controls.Add($button2)

$main_form.AcceptButton = $button2

$main_form.Controls.Add($GroupBox2)
#------------------- Конец (Блок "Отключение пользователя") --#

[void] $Main_Form.ShowDialog()