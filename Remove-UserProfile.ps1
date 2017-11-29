#PowerShell Script Containing Function Used to Remove User Profiles & Additional Remnants of C:\Users Directory
#Developer: Andrew Saraceni (saraceni@wharton.upenn.edu)
#Date: 12/22/14

#Requires -Version 2.0

function Remove-UserProfile
{
    <#
    .SYNOPSIS
    Removes user profiles and additional contents of the C:\Users 
    directory if specified.
    .DESCRIPTION
    Gathers a list of profiles to be removed from the local computer, 
    passing on exceptions noted via the Exclude parameter and/or 
    profiles newer than the date specified via the Before parameter.  
    If desired, additional files and folders within C:\Users can also 
    be removed via use of the DirectoryCleanup parameter.

    Once gathered, miscellaneous items are first removed from the 
    C:\Users directory if specified, followed by the profile objects 
    themselves and all associated registry keys per profile.  A listing 
    of current items within the C:\Users directory is returned 
    following the profile removal process.
    .PARAMETER Exclude
    Specifies one or more profile names to exclude from the removal 
    process.
    .PARAMETER Before
    Specifies a date from which to remove profiles before that haven't 
    been accessed since that date.
    .PARAMETER DirectoryCleanup
    Removes additional files/folders (i.e. non-profiles) within the 
    C:\Users directory.
    .EXAMPLE
    Remove-UserProfile
    Remove all non-active and non-system designated user profiles 
    from the local computer.
    .EXAMPLE
    Remove-UserProfile -Before (Get-Date).AddMonths(-1) -Verbose
    Remove all non-active and non-system designated user profiles 
    not used within the past month, displaying verbose output as well.
    .EXAMPLE
    Remove-UserProfile -Exclude @("labadmin", "desktopuser") -DirectoryCleanup
    Remove all non-active and non-system designated user profiles 
    except "labadmin" and "desktopuser", and remove additional 
    non-profile files/folders within C:\Users as well.
    .NOTES
    Even when not specifying the Exclude parameter, the following 
    profiles are not removed when utilizing this cmdlet:
    C:\Windows\ServiceProfiles\NetworkService 
    C:\Windows\ServiceProfiles\LocalService 
    C:\Windows\system32\config\systemprofile 
    C:\Users\Public
    C:\Users\Default

    Aside from the original profile directory (within C:\Users) 
    itself, the following registry items are also cleared upon 
    profile removal via WMI:
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\{SID of User}"
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGuid\{GUID}" SidString = {SID of User}
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\{SID of User}"

    Additionally, any currently loaded/in use profiles will not be 
    removed.  Regarding miscellaneous non-profile items, hidden items 
    are not enumerated or removed from C:\Users during this process.

    This cmdlet requires adminisrative privileges to run effectively.
      
    This cmdlet is not intended to be used on Virtual Desktop 
    Infrastructure (VDI) environments or others which utilize 
    persistent storage on alternate disks, or any configurations 
    which utilize another directory other than C:\Users to store 
    user profiles.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$false)]
        [String[]]$Exclude,
        [Parameter(Position=1,Mandatory=$false)]
        [DateTime]$Before,
        [Parameter(Position=2,Mandatory=$false)]
        [Switch]$DirectoryCleanup
    )

    Write-Verbose "Gathering List of Profiles on $env:COMPUTERNAME to Remove..."

    $userProfileFilter = "Loaded = 'False' AND Special = 'False'"
    $cleanupExclusions = @("Public", "Default")

    if ($Exclude)
    {
        foreach ($exclusion in $Exclude)
        {
            $userProfileFilter += "AND NOT LocalPath LIKE '%$exclusion'"
            $cleanupExclusions += $exclusion
        }
    }

    if ($Before)
    {
        $userProfileFilter += "AND LastUseTime < '$Before'"

        $keepUserProfileFilter = "Special = 'False' AND LastUseTime >= '$Before'"
        $profilesToKeep = Get-WmiObject -Class Win32_UserProfile -Filter $keepUserProfileFilter -ErrorAction Stop

        foreach ($profileToKeep in $profilesToKeep)
        {
            try
            {
                $userSID = New-Object -TypeName System.Security.Principal.SecurityIdentifier($($profileToKeep.SID))
                $userName = $userSID.Translate([System.Security.Principal.NTAccount])
                
                $keepUserName = $userName.Value -replace ".*\\", ""
                $cleanupExclusions += $keepUserName
            }
            catch [System.Security.Principal.IdentityNotMappedException]
            {
                Write-Warning "Cannot Translate SID to UserName - Not Adding Value to Exceptions List"
            }
        }
    }

    $profilesToDelete = Get-WmiObject -Class Win32_UserProfile -Filter $userProfileFilter -ErrorAction Stop

    if ($DirectoryCleanup)
    {
        $usersChildItem = Get-ChildItem -Path "C:\Users" -Exclude $cleanupExclusions

        foreach ($usersChild in $usersChildItem)
        {
            if ($profilesToDelete.LocalPath -notcontains $usersChild.FullName)
            {    
                try
                {
                    Write-Verbose "Additional Directory Cleanup - Removing $($usersChild.Name) on $env:COMPUTERNAME..."
                    
                    Remove-Item -Path $($usersChild.FullName) -Recurse -Force -ErrorAction Stop
                }
                catch [System.InvalidOperationException]
                {
                    Write-Verbose "Skipping Removal of $($usersChild.Name) on $env:COMPUTERNAME as Item is Currently In Use..."
                }
            }
        }
    }

    foreach ($profileToDelete in $profilesToDelete)
    {
        Write-Verbose "Removing Profile $($profileToDelete.LocalPath) & Associated Registry Keys on $env:COMPUTERNAME..."
                
        Remove-WmiObject -InputObject $profileToDelete -ErrorAction Stop
    }

    $finalChildItem = Get-ChildItem -Path "C:\Users" | Select-Object -Property Name, FullName, LastWriteTime
                
    return $finalChildItem
}