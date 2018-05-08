 Function Get-Updated-File-List() {

param(
 [Parameter(Mandatory=$false)][string]$updatesPath
 ,[Parameter(Mandatory=$false)][string]$numberOfDays
)
 
 if(!$updatesPath){
    $updatesPath = Read-Host -Prompt 'Please enter folder path'
 }

 if(!$numberOfDays){
     $numberOfDays = Read-Host -Prompt 'Number of Days before today to check'
 }
 
 $EXCLUDE_FOLDERS = @("tempiis",".git",".vs","fckeditor","ckeditor","aspnet_client","ftp","logs")
 $TEMP_FILE_PATH =  ($env:TEMP + '\file.txt')
 $CURRENT_TIME = Get-Date
 
 
 if(Test-Path $updatesPath) 
 { 

    $changedFiles = @()

   ls -Path $updatesPath -File -Recurse |
    % -Process { 

        $DirectoryName =  (Split-Path $_.FullName -Parent | Split-Path -Leaf).ToLower()

        if( !$EXCLUDE_FOLDERS.Contains($DirectoryName)) {
            if (($CURRENT_TIME - $_.LastWriteTime).TotalDays -lt $numberOfDays) 
            { 
             $changedFiles += $_
            }
         } 
    }  


    

    $prevDirectory = [string]::Empty
    $changedFiles | 
    Sort-Object -Property DirectoryName  | 
    % -Process {

        $currentDirectoryName = (Split-Path $_.FullName -Parent | Split-Path -Leaf).ToLower()  

        if([string]::IsNullOrEmpty($prevDirectory))
         {
            $prevDirectory = $currentDirectoryName
            Write-Output "Folder Path: $updatesPath" 
            Write-Output " "
         }

         if($prevDirectory -ne $currentDirectoryName)
         {           
            $prevDirectory = $currentDirectoryName 
            Write-Output " "
         }

        Write-Output $_.FullName.Replace($updatesPath,"")

     }| Out-File  $TEMP_FILE_PATH
 
     Notepad $TEMP_FILE_PATH  
 } 
 else
 {
     Write-Host "Path is invalid"
 }

}

Get-Updated-File-List