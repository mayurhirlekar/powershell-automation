
Function Clone-Git-Solution() {
param(
 [Parameter(Mandatory=$false)][string]$cloneUrl,
 [Parameter(Mandatory=$false)][string]$folderName
)


$DEFAULT_PATH = 'C:\inetpub\wwwroot'

$appCmd = 'C:\Program Files\IIS Express\appcmd.exe'

if(!$cloneUrl){
    $cloneUrl = Read-Host -Prompt 'TFS Clone Url'
}

if(!$folderName){
 $folderName = Read-Host -Prompt 'Local Site Folder Name' 
}

if(!$cloneUrl){
  Write-Warning "No clone url provided"
  return
}


#Check User permission
try{
  $CURRENT_USERNAME = $env:UserName
  $testFilePath = Join-Path -ChildPath 'permissions.txt' -Path $DEFAULT_PATH 
  "Checking permissions for " + $CURRENT_USERNAME > $testFilePath
  Remove-Item $testFilePath
  $hasPermissions = "YES"
}
catch{
 Write-Warning "Please submit ticket to servers for folder permissions"
 $hasPermissions = "NO";
}

#Check if folder exists
try{
  $actualFolderPath = Join-Path -ChildPath $folderName -Path $DEFAULT_PATH 
  Write-Host $actualFolderPath

  if(Test-path $actualFolderPath){
  $hasPermissions = "NO";
  }

  if( $hasPermissions -match "NO"){
   Write-Host ' ' + $folderName + ' exists. Please delete the existing folder and restart the setup process'
  }

}
catch{
 Write-Warning "Please submit ticket to servers for folder permissions. test"
 
}

if([bool] ($hasPermissions -match "NO")){
 exit "No Folder Permission Issue : " + $DEFAULT_PATH
}

if(($folderName -contains ' ')){
  Write-Warning 'Folder name contains spaces ' + $folderName
  $folderName = $folderName.Replace(' ', '-')
  Write-Information 'Using Name --> ' + $folderName
}

#Switch to root directory
Set-Location -Path $DEFAULT_PATH


#Download the solution
git clone $cloneUrl $folderName

$folderPath = Join-Path -Path $DEFAULT_PATH -ChildPath $folderName

Set-Location -Path $folderPath

#Applies to Project
#$doesDevelopBranchExist = "NO"
#git branch -a | % { if($_.ToLower().Trim() -like '*develop') { $doesDevelopBranchExist = "YES" } }
#if($doesDevelopBranchExist -match "NO"){
#    try{
#    Write-Host -ForegroundColor Green 'develop branch missing trying to initialize git flow'
#       git flow init
#     }
#     catch{
#      Write-Warning 'git flow plugin missing. please consider to installing it.'
#     }
# 
#}else{ 
# git checkout -b develop
#
#}

git branch -a

Write-Host "Opening path ..$($folderPath)" -ForegroundColor Yellow
start 'C:\Windows\explorer.exe' -ArgumentList $($folderPath)

}

