function Get-GitCommit-FileList(){
[CmdletBinding()]
 param(
 [Parameter(Mandatory=$false)][string]$fromCommit = "HEAD~0",
 [Parameter(Mandatory=$false)][string]$toCommit,
 [Parameter(Mandatory=$false)][int]$lastNumberOfCommits = 0,
 [Parameter(Mandatory=$false)][string]$commitRange
)
    $TEMP_GIT_FILE_PATH =  ($env:TEMP + '\CheckedOutGitfile.txt')

    #Check if Range was provided. If it was provide lets split and assign values to fromCommit and toCommit params
    if(-not ([string]::IsNullOrEmpty($commitRange)))
    {
      $commitRange = $commitRange.Replace("..",".");
      $rangeSplit = $commitRange.Split(".");
      $fromCommit = $rangeSplit[0];
      $toCommit = $rangeSplit[1];
    }

    
    # Check if Start commit was provided. If not use default Head value
    if(-not ([string]::IsNullOrEmpty($fromCommit)))
    {
      Write-Host "Start Commit Details"
      git log -1 $fromCommit
    }
    $commitOption = "$fromCommit"    

    # Check if end commit was provided.
    if(-not ([string]::IsNullOrEmpty($toCommit)))
    {
     Write-Host "End Commit Details"
     git log -1 $toCommit
     $commitOption = "$fromCommit..$toCommit"
    }
    
    # Check if Number of commit was provided. Use it to build out the range
    if($lastNumberOfCommits -gt 0)
    {
     Write-Host "$lastNumberOfCommits Commit Details"
     git log -$lastNumberOfCommits
     $commitOption = "$fromCommit..HEAD~$lastNumberOfCommits"
    }
    
    git diff --name-only $commitOption | Out-File $TEMP_GIT_FILE_PATH
    NotePad $TEMP_GIT_FILE_PATH                                  
}

