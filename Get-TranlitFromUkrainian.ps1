$string = "Згодина Ярослав Євгенієвич"
$dict = @{
            "а" = "a";
            "б" = "b";
            "в" = "v";
            "г" = "h";
            "ґ" = "g";
            "д" = "d";
            "е" = "e";
            "є" = "ie";
            "ж" = "zh";
            "з" = "z";
            "и" = "y";
            "і" = "i";
            "ї" = "i";
            "й" = "i";
            "к" = "k";
            "л" = "l";
            "м" = "m";
            "н" = "n";
            "о" = "o";
            "п" = "p";
            "р" = "r";
            "с" = "s";
            "т" = "t";
            "у" = "u";
            "ф" = "f";
            "х" = "kh";
            "ц" = "ts";
            "ч" = "ch";
            "ш" = "sh";
            "щ" = "shch";
            "ю" = "iu";
            "я" = "ia";
            " " = " "
        }

$2SoundsDict = @{
            "ю" = "yu";
            "я" = "ya";
            "є" = "ye";
            "ї" = "yi";
            "й" = "y"
            }


$wordArray = @()
$charSet = @("","","")


$wordArray = $string -split " "
for ($i = 0; $i -lt $wordArray.count; $i++)
{
    $charArray = @($wordArray[$i] -split "")
    for ($j=0; $j -lt $charArray.Count; $j++) {
        if ($j -eq 1) {
            if ($charArray[1] -in $2SoundsDict.Keys) {
                $charSet[$i] += $2SoundsDict[$charArray[1]]
                $j++
                }
            }
        if ($charArray[$j] -eq 'г') {
            if ($charArray[$j -1] -eq 'з') {
                $charSet[$i] += "gh"
                $J++
            }
        }
        $charSet[$i] += $dict[$charArray[$j]]
    }
}

$translatedString = (Get-Culture).TextInfo.ToTitleCase($charSet -join " ")
$translatedString

#(Get-Culture)

#cls