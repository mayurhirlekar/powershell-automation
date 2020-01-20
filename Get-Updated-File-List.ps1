 Function Get-File-Differences() {
param(
 [Parameter(Mandatory=$true)][string]$LocalPath
 ,[Parameter(Mandatory=$true)][string]$RemotePath
)
 
 if([string]::IsNullOrEmpty($LocalPath)){
    $LocalPath = Read-Host -Prompt 'Please enter folder path'
 }

 if([string]::IsNullOrEmpty($RemotePath)){
    $RemotePath = Read-Host -Prompt 'Please enter folder path'
 }

 if(!(Test-Path $LocalPath))
  { 
    Write-Warning 'Invalid Path :' + $LocalPath
  }

  if(!(Test-Path $RemotePath))
  { 
    Write-Warning 'Invalid Path :' + $RemotePath
  }
 
 
 [string[]]$EXCLUDE_FOLDERS = @("*tempiis*","*assets*","*.git*","*.vs*","*fckeditor*","*ckeditor*","*aspnet_client*","*ftp*","*logs*","*obj*")

 $TEMP_FILE_PATH =  ($env:TEMP + '\fileDiff.txt')
 $CURRENT_TIME = Get-Date

 $localFileCollection = Get-File-Hashes -Path $LocalPath -ExcludeFolders $EXCLUDE_FOLDERS
 $remoteFileCollection = Get-File-Hashes -Path $RemotePath -ExcludeFolders $EXCLUDE_FOLDERS


    
  $changedFiles = (Compare-Object -ReferenceObject $localFileCollection -DifferenceObject $remoteFileCollection  -Property hash -PassThru).Path | Where-Object -FilterScript { $_.contains($RemotePath)}
    
  $prevDirectory = [string]::Empty
   
   $changedFiles |    
    % -Process {
       
        $currentFileName = Get-Item $_
     
        $currentDirectoryName = $currentFileName.Directory.FullName.ToLower()

        if([string]::IsNullOrEmpty($prevDirectory))
         {
            $prevDirectory = $currentDirectoryName
            Write-Output "Folder Path: $RemotePath" 
            Write-Output " "
         }

         if($prevDirectory -ne $currentDirectoryName)
         {           
            $prevDirectory = $currentDirectoryName 
            Write-Output " "
         }

        Write-Output $currentFileName.FullName.Replace($RemotePath,"")

     }| Out-File  $TEMP_FILE_PATH
 
     Notepad $TEMP_FILE_PATH  
 } 





function Get-File-Hashes() {
param(
 [Parameter(Mandatory=$true)][string]$Path
 ,[Parameter(Mandatory=$false)][string[]]$ExcludeFolders
)

$files = Get-ChildItem -Path $Path -File -Recurse -Exclude $ExcludeFolders | ForEach-Object -Process { 
  
  $allowed = $true
  
  foreach ($exclude in $ExcludeFolders) { 
    
    if ((Split-Path -Path $_.FullName -Parent) -ilike $exclude) { 
      
      $allowed = $false
      
      break
    
    }
  
  }
  
  if ($allowed) {
    $_
  }

}

$files | % { Get-FileHash  $_ }

}
