#
# Script.ps1
#
[int []] $a = 333, 11, 26, 79, 15647
[int []] $b = 2, 3, 5, 7

foreach ( $i in $a )
{
    [string] $result = ""
    foreach ($j in $b)
    {
        [int] $c = $i % $j
        $result = $result + [Convert]::ToString($c)
    }
    if (!$result.Contains("0"))
        {
         "{0} is simple integer" -f $i
        }
} 