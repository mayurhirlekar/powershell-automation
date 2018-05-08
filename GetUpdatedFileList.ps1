 Function Get-Updated-File-List() {

param(
 [Parameter(Mandatory=$false)][string]$updatesPath
 ,[Parameter(Mandatory=$false)][string]$numberOfDays
)
 
 if(!$updatesPath){
    $updatesPath = Read-Host -Prompt 'Please enter updates path'
 }

 if(!$numberOfDays){
     $numberOfDays = Read-Host -Prompt 'Number of Days before today to check'
 }
 
 $EXCLUDE_FOLDERS = "tempIIS","assets",".git",".vs","FCKeditor","ckeditor","aspnet_client","ftp","_ignorethisfolder"
 $TEMP_FILE_PATH =  ($env:TEMP + '\file.txt')
 $CURRENT_TIME = Get-Date
 
 
 if(Test-Path $updatesPath) 
 { 

    $changedFiles = @()

   ls -Path $updatesPath -File -Recurse |
    % -Process { 

        $DirectoryName =  Split-Path $_.Directory -Leaf

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
        if([string]::IsNullOrEmpty($prevDirectory))
         {
            $prevDirectory = $_.DirectoryName.ToString()
         }

         if($prevDirectory -ne $_.DirectoryName.ToString())
         {
            Write-Output " "
         }

        Write-Output $_.FullName

     } | Out-File  $TEMP_FILE_PATH
 
     Notepad $TEMP_FILE_PATH  
 } 
 else
 {
     Write-Host "Path is invalid"
 }

}

Get-Updated-File-List