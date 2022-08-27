# Get-AzStorageFileRecommendationforAVD.ps1

## .SYNOPSIS
Gives loose recommendation for how much a Premium Azure File Share storage quota (which correlates with IOPS) to get for your AVD/FSLogix environment by inputting user session information.
    This script was created based on a need for a clear way to determine File storage quota need based on number of user sessions, the most practical input.
    We want to make sure we give (Capacity and IOPS) head room to guarantee a good customer experience. This tool was created to assist with that.
## .DESCRIPTION
Script takes input of number of users in your environment, number of estimated concurrent users, estimated number of unique users, and estimated average profile size (VHD/VHDX size) in GiB. 
It takes the inputs you give and calculates recommendations based on Microsoft's scalability and performace targets for how IOPS (Burst and Stable) scales as you provision more storage: https://docs.microsoft.com/en-us/azure/storage/files/storage-files-scale-targets.
IOPS needed is determined by Azure Academy's recommendation of 50 IOPS for burst, and 10 IOPS for stable per user: https://youtu.be/tXVxuDbbNi4.
## .PARAMETER Path
Enter path and file name with either .html or .csv. Not required. If you do not use this parameter the output will pass thru to the console.
## .PARAMETER NumberofUsers
Enter the number of users in environment that may use the service. Factors into calculations. Required.
## .PARAMETER NumberofConcurrentUsers
Enter the number of concurrent users that will use AVD at any given time. Factors into calculations. Required.
## .PARAMETER NumberofUniqueUsers
Enter the number of users that will use AVD at least once in the long term. This will likely be much higher than the amount of concurrent users count because some people sign in, but don't use it much. Factors into calculations. Required.
## .PARAMETER AverageStorageGiBperUser
Enter the number of estimated average user profile size (GiB). Factors into calculations. Required.
## .INPUTS
You can pipe into the command with parameter names.
## .OUTPUTS
This script outputs returned data to the console, but you may output to a file. There is no logging or log file at this time, since this script is just doing calculations.
## .NOTES
Version:        1.0
Author:         Jesse Corbin
Creation Date:  August 27th 2022
Purpose/Change: Initial script development
    
## .EXAMPLE
    Get-AzStorageFileRecommendationforAVD
    
## .EXAMPLE
    Get-AzStorageFileRecommendationforAVD -NumberofUsers 27000 -NumberofConcurrentUsers 2700 -NumberofUniqueUsers 10000 -AverageStorageGiBperUser 5
    
## .EXAMPLE
    Get-AzStorageFileRecommendationforAVD -NumberofUsers 27000 -NumberofConcurrentUsers 2700 -NumberofUniqueUsers 10000 -AverageStorageGiBperUser 5 -Path AzStorageFileRecommendation.html
    
## .EXAMPLE
    Get-AzStorageFileRecommendationforAVD -NumberofUsers 27000 -NumberofConcurrentUsers 2700 -NumberofUniqueUsers 10000 -AverageStorageGiBperUser 5 -Path AzStorageFileRecommendation.csv
