 Function Get-Updated-File-List() {

param(
 [Parameter(Mandatory=$false)][string]$UpdatesPath
 ,[Parameter(Mandatory=$false)][string]$NumberOfDays
)
 
 if(!$UpdatesPath){
    $UpdatesPath = Read-Host -Prompt 'Please enter folder path'
 }

 if(!$NumberOfDays){
     $NumberOfDays = Read-Host -Prompt 'Number of Days before today to check'
 }
 
 $EXCLUDE_FOLDERS = @("tempiis",".git",".vs","fckeditor","ckeditor","aspnet_client","ftp","logs","obj")
 $TEMP_FILE_PATH =  ($env:TEMP + '\file.txt')
 $CURRENT_TIME = Get-Date
 
 $UpdatesPath = $UpdatesPath.TrimEnd('\')
 
 if(Test-Path $UpdatesPath) 
 { 

    $changedFiles = @()

   ls -Path $UpdatesPath -File -Recurse |
    % -Process { 

        $DirectoryName =  $_.FullName.Replace($UpdatesPath,"").TrimStart('\').Split('\')[0].ToLower()

        if( !$EXCLUDE_FOLDERS.Contains($DirectoryName)) {
            if (($CURRENT_TIME - $_.LastWriteTime).TotalDays -lt $NumberOfDays) 
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
            Write-Output "Folder Path: $UpdatesPath" 
            Write-Output " "
         }

         if($prevDirectory -ne $currentDirectoryName)
         {           
            $prevDirectory = $currentDirectoryName 
            Write-Output " "
         }

        Write-Output $_.FullName.Replace($UpdatesPath,"")

     }| Out-File  $TEMP_FILE_PATH
 
     Notepad $TEMP_FILE_PATH  
 } 
 else
 {
     Write-Host "Path is invalid"
 }

}
