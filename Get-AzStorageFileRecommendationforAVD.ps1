
<#
    .SYNOPSIS
    Gives loose recommendation for how much a Premium Azure File Share storage quota (which correlates with IOPS) to get for your AVD/FSLogix environment by inputting user session information.
    This script was created based on a need for a clear way to determine File storage quota need based on number of user sessions, the most practical input.
    We want to make sure we give (Capacity and IOPS) head room to guarantee a good customer experience. This tool was created to assist with that.

    .DESCRIPTION
    Script takes input of number of users in your environment, number of estimated concurrent users, estimated number of unique users, and estimated average profile size (VHD/VHDX size) in GiB. 
    It takes the inputs you give and calculates recommendations based on Microsoft's scalability and performace targets for how IOPS (Burst and Stable) scales as you provision more storage: https://docs.microsoft.com/en-us/azure/storage/files/storage-files-scale-targets.
    IOPS needed is determined by Azure Academy's recommendation of 50 IOPS for burst, and 10 IOPS for stable per user: https://youtu.be/tXVxuDbbNi4.

    .PARAMETER Path
    Enter path and file name with either .html or .csv. Not required. If you do not use this parameter the output will pass thru to the console.

    .PARAMETER NumberofUsers
    Enter the number of users in environment that may use the service. Factors into calculations.

    .PARAMETER NumberofConcurrentUsers
    Enter the number of concurrent users that will use AVD at any given time. Factors into calculations.

    .PARAMETER NumberofUniqueUsers
    Enter the number of users that will use AVD at least once in the long term. This will likely be much higher than the amount of concurrent users count because some people sign in, but don't use it much. Factors into calculations.

    .PARAMETER AverageStorageGiBperUser
    Enter the number of estimated average user profile size (GiB). Factors into calculations.

    .INPUTS
    You can pipe into the command with parameter names.

    .OUTPUTS
    This script outputs returned data to the console, but you may output to a file. There is no logging or log file at this time, since this script is just doing calculations.

    .NOTES
    Version:        1.0
    Author:         Jesse Corbin
    Creation Date:  August 27th 2022
    Purpose/Change: Initial script development
    
    .EXAMPLE
    Get-AzStorageFileRecommendationforAVD
    
    .EXAMPLE
    Get-AzStorageFileRecommendationforAVD -NumberofUsers 27000 -NumberofConcurrentUsers 2700 -NumberofUniqueUsers 10000 -AverageStorageGiBperUser 5
    
    .EXAMPLE
    Get-AzStorageFileRecommendationforAVD -NumberofUsers 27000 -NumberofConcurrentUsers 2700 -NumberofUniqueUsers 10000 -AverageStorageGiBperUser 5 -Path AzStorageFileRecommendation.html
    
    .EXAMPLE
    Get-AzStorageFileRecommendationforAVD -NumberofUsers 27000 -NumberofConcurrentUsers 2700 -NumberofUniqueUsers 10000 -AverageStorageGiBperUser 5 -Path AzStorageFileRecommendation.csv

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

[CmdletBinding()]

Param (

    [Parameter(
    ValuefromPipelineByPropertyName = $true,
    Mandatory = $true)]
    [Int]$NumberofUsers,

    [Parameter(
    ValuefromPipelineByPropertyName = $true,
    Mandatory = $true)]
    [Int]$NumberofConcurrentUsers,

    [Parameter(
    ValuefromPipelineByPropertyName = $true,
    Mandatory = $true)]
    [Int]$NumberofUniqueUsers,

    [Parameter(
    ValuefromPipelineByPropertyName = $true,
    Mandatory = $true)]
    [Int]$AverageStorageGiBperUser,

    [Parameter(
    ValuefromPipelineByPropertyName = $true)]
    [System.IO.FileInfo]$Path,

    [Parameter(
    ValuefromPipelineByPropertyName = $true)]
    [switch]$PassThru
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Get-AzStorageFileRecommendationforAVD {

    # Variables
    $BurstIOPSNeed = 50
    $StableIOPSNeed = 10

    # Calculations
    $TotalGibRecommendationforStorage = $NumberofUniqueUsers * $AverageStorageGiBperUser
    $TotalIOPSNeededforBurst = $NumberofConcurrentUsers * $BurstIOPSNeed
    $TotalIOPSNeededforStable = $NumberofConcurrentUsers * $StableIOPSNeed
    $TotalGibRecommendationforBurstIOPS = ($TotalIOPSNeededforBurst - 10000) / 3
    $TotalGibRecommendationforStableIOPS = $TotalIOPSNeededforStable - 3000
    $LargestofThreeGibRecommendations = ($TotalGibRecommendationforBurstIOPS,$TotalGibRecommendationforStableIOPS,$TotalGibRecommendationforStorage | Measure-Object -Maximum).Maximum
    $ResultingThroughput = 100 + (0.04 * $LargestofThreeGibRecommendations) + (0.06 * $LargestofThreeGibRecommendations)

    if ($TotalGibRecommendationforBurstIOPS -lt 1) {$TotalGibRecommendationforBurstIOPS = 1}
    if ($TotalGibRecommendationforStableIOPS -lt 1) {$TotalGibRecommendationforStableIOPS = 1}

    # Creating output table
    $Table = [PSCustomObject]@{
        NumberofUsers = $NumberofUsers
        NumberofConcurrentUsers = $NumberofConcurrentUsers
        NumberofUniqueUsers = $NumberofUniqueUsers
        AverageStorageGiBperUser = $AverageStorageGiBperUser

        TotalIOPSNeededforBurst = $TotalIOPSNeededforBurst
        TotalIOPSNeededforStable = $TotalIOPSNeededforStable

        TotalGibRecommendationforStorage = $TotalGibRecommendationforStorage
        TotalGibRecommendationforBurstIOPS = [Math]::Ceiling($TotalGibRecommendationforBurstIOPS)
        TotalGibRecommendationforStableIOPS = [Math]::Ceiling($TotalGibRecommendationforStableIOPS)
        ResultingThroughput = [Math]::Ceiling($ResultingThroughput)

    }
    return $Table
}

function Out-RecommendationFile {
    
    if ($Path -like "*.html") {
        $Table | ConvertTo-Html | Out-File -FilePath $Path
        Start-Process $Path    
    }

    if ($Path -like "*.csv") {
        $Table | ConvertTo-Csv | Out-File -FilePath $Path
        Start-Process $Path   
    }

    if (!$Path) { Write-Output $Table }
    #if ($PassThru) { Write-Output $Table }

}

#-----------------------------------------------------------[Execution]------------------------------------------------------------


$Table = Get-AzStorageFileRecommendationforAVD 

Out-RecommendationFile


