 $tempFilePath =  ($env:TEMP + '\file.txt')
 $updatesPath = Read-Host -Prompt 'Please enter updates path'
 $numberOfDays = Read-Host -Prompt 'Number of Days before today to check'
 $excludeFolder = 'tempIIS','assets'
 if(Test-Path $updatesPath) { 
 Get-ChildItem -Path $updatesPath -Exclude $excludeFolder -Recurse $fList -File  |
  % -Process { $nowTime = Get-Date; if (($nowTime - $_.LastWriteTime).TotalDays -lt $numberOfDays) { $_.FullName}} |
   Out-File $tempFilePath 
 Notepad $tempFilePath } else {
  Write-Host "Path is invalid"
 }



