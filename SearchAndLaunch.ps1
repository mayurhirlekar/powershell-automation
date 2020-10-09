Import-Module .\GetUpdatedFileList.ps1
Import-Module .\Solution-SetUp.ps1
Import-Module .\AddSiteToApplicationHostFile.ps1
Import-Module .\Get-GitCommit-FileList.ps1
Import-Module posh-git

Function Search-And-Launch() {
param(
 [Parameter(Mandatory=$false)][string]$SiteToSearch
)

if(!$SiteToSearch){
Write-Host "Hit Enter to exit"
$SiteToSearch = Read-Host -Prompt 'Site name to search'
}
if($SiteToSearch.Length -eq 0){
   Write-Host "Exiting Shell..."
   return
}

$SearchAndLaunchConfigFilePath = [string]::concat($PSScriptRoot,'\','SearchAndLaunch.config')
$configPath = [Environment]::GetFolderPath("MyDocuments") + "\IISExpress\config\applicationhost.config"
[xml] $con = Get-Content $configPath
$selectedSite = @()
$counter = 1
$con.configuration.'system.applicationHost'.sites.site | where {$_.name -match $SiteToSearch} | 
% {
    $siteObj = new-object psobject
    Add-Member -InputObject $siteObj -MemberType NoteProperty -Name Option -Value $counter
    Add-Member -InputObject $siteObj -MemberType NoteProperty -Name SiteName -Value $_.name
    Add-Member -InputObject $siteObj -MemberType NoteProperty -Name SiteId -Value $_.id 
    
    
    $bindingObject = $_.bindings.binding | Select-Object -First 1
    $bindingInformationArray = $bindingObject.bindingInformation.ToString().Split(':')
    $urlBuild = [string]::Format("{0}://{1}:{2}",$bindingObject.protocol,$bindingInformationArray[$bindingInformationArray.Length-1],$bindingInformationArray[$bindingInformationArray.Length-2]) -replace ":80",""
        

    Add-Member -InputObject $siteObj -MemberType NoteProperty -Name DefaultUrl -Value $urlBuild
    
    $localPath  = $_.application.VirtualDirectory | where { $_.physicalpath -match "C:"} | Select-Object physicalpath -First 1
    $localWebIndex = if($localPath) {
    if($localPath.physicalPath.EndsWith('\')){
    $localPath.physicalPath.Substring(0,$localPath.physicalPath.LastIndexOf('\')).LastIndexOf('\')
    } else{
        $localPath.physicalPath.ToLower().LastIndexOf('\') 
    }
    
    } else { 0  }     
    
    $templocalPath = $localPath.physicalPath.Substring(0,$localWebIndex)    
    
    if($localPath -and $templocalPath){      
      Add-Member -InputObject $siteObj -MemberType NoteProperty -Name LocalPath -Value $templocalPath
      }else{
      Add-Member -InputObject $siteObj -MemberType NoteProperty -Name LocalPath -Value $localPath.physicalPath
      }

    #Site's web folder
    Add-Member -InputObject $siteObj -MemberType NoteProperty -Name WebFolder -Value $localPath.physicalPath

    #iDev Specific
    $ConfigFile= '\web.config'
    $webConfigPath = Join-Path -ChildPath $ConfigFile -Path $siteObj.WebFolder
    if(Test-path $webConfigPath){
            [xml] $dbObj = Get-Content $webConfigPath 
            $dbConnectionString = $dbObj.configuration.appSettings.add | where {$_.key -eq 'MasterConnectionString'} | Select value
            
            if($dbConnectionString){
                foreach( $stuff in $dbConnectionString.value.split(';')) {
                if($stuff -match 'Source=' ) {
                 Add-Member -InputObject $siteObj -MemberType NoteProperty -Name DBServer -Value $stuff.Split('=')[1]
                }
                if($stuff -match 'Catalog=') {
                 Add-Member -InputObject $siteObj -MemberType NoteProperty -Name Database -Value $stuff.Split('=')[1]
                }                

                }
            }else {
            #old idev
            $dbConnectionString = $dbObj.configuration.appSettings.add | where {$_.key.ToLower() -eq 'connectionstring'} | Select value
            if($dbConnectionString) {
            foreach( $stuff in $dbConnectionString.value.split(';')) {
                if($stuff -match 'Source=' ) {
                 Add-Member -InputObject $siteObj -MemberType NoteProperty -Name DBServer -Value $stuff.Split('=')[1]
                }
                if($stuff -match 'Catalog=') {
                 Add-Member -InputObject $siteObj -MemberType NoteProperty -Name Database -Value $stuff.Split('=')[1]
                }    
                }
              }
            }
     }

         
  
    #Kentico Specific
    $ConfigFile= '\web.config'
    $webConfigPath = Join-Path -ChildPath $ConfigFile -Path $siteObj.WebFolder
     if( -not [bool]($siteObj.PSobject.Properties.name -match "Database") ){
        
        if(Test-path $webConfigPath){
                [xml] $dbObj = Get-Content $webConfigPath 
                $dbConnectionString = $dbObj.configuration.connectionStrings.add | Select -First 1
            
                if($dbConnectionString){
                    foreach( $stuff in $dbConnectionString.connectionString.split(';')) {
                    if($stuff.ToLower()  -match 'source=' -or $stuff.ToLower() -match 'server=' ) {
                     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name DBServer -Value $stuff.Split('=')[1]
                    }
                    if($stuff -match 'catalog=' -or $stuff.ToLower() -match 'database=') {
                     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name Database -Value $stuff.Split('=')[1]
                    }                

                    }
                }
         }
     }

    #Sitefinity Specific  
    $ConfigFile= '\App_Data\Sitefinity\Configuration\DataConfig.config'
    $webConfigPath = Join-Path -ChildPath $ConfigFile -Path $siteObj.WebFolder
     if( -not [bool]($siteObj.PSobject.Properties.name -match "Database") ){
        
        if(Test-path $webConfigPath){
                [xml] $dbObj = Get-Content $webConfigPath 
                $dbConnectionString = $dbObj.dataConfig.connectionStrings.add.connectionString
            
                if($dbConnectionString){
                    foreach( $stuff in $dbConnectionString.split(';')) {
                    if($stuff.ToLower()  -match 'source=' -or $stuff.ToLower() -match 'server=' ) {
                     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name DBServer -Value $stuff.Split('=')[1]
                    }
                    if($stuff -match 'catalog=' -or $stuff.ToLower() -match 'database=') {
                     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name Database -Value $stuff.Split('=')[1]
                    }                

                    }
                }
         }
     }


    #ROC Specific  
    $ConfigFile= '\Config\ConnectionStrings.config'
    $webConfigPath = Join-Path -ChildPath $ConfigFile -Path $siteObj.WebFolder
     if( -not [bool]($siteObj.PSobject.Properties.name -match "Database") ){
        
        if(Test-path $webConfigPath){
                [xml] $dbObj = Get-Content $webConfigPath 
                $dbConnectionString = $dbObj.connectionStrings.add.connectionString
            
                if($dbConnectionString){
                    foreach( $stuff in $dbConnectionString.split(';')) {
                    if($stuff.ToLower()  -match 'source=' -or $stuff.ToLower() -match 'server=' ) {
                     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name DBServer -Value $stuff.Split('=')[1]
                    }
                    if($stuff -match 'catalog=' -or $stuff.ToLower() -match 'database=') {
                     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name Database -Value $stuff.Split('=')[1]
                    }                

                    }
                }
         }
     }

          
    $updatePath = $_.application.VirtualDirectory | where { $_.path -match "assets" } | Select-Object physicalpath -First 1
    $updatePathWebIndex = if($updatePath) {$updatePath.physicalPath.LastIndexOf("\web") } else { 0 } 

     if($updatePath -and $updatePathWebIndex -gt 0){ 
     Add-Member -InputObject $siteObj -MemberType NoteProperty -Name UpdatePath -Value $updatePath.physicalPath.Substring(0,$updatePathWebIndex) 
      }

    $selectedSite += $siteObj
    $counter += 1
  } 
  
  If($counter -gt 1){
    $selectedSite| Format-List -Property Option,SiteName,LocalPath,UpdatePath,DBServer,Database | Format-Color @{'Option' = 'Green'} 
        
    Write-Host "Option Number: " -ForegroundColor Green -NoNewline    
    $launchSite = Read-Host

    
    if([string]::IsNullOrEmpty($launchSite)){
         Write-Host "No option provided.. Back to search"
         Write-Host "`n"      
         Search-And-Launch
         return;
      }
    

    try
    {  
        $notInOptions = $launchSite.Split(',') | Where-Object -FilterScript {[int32]$_ -ge $counter -or [int32]$_ -eq 0 }

        if(-not [string]::IsNullOrEmpty($notInOptions)){        
            Write-Warning "Please provide valid option number"
            Write-Host "`n"      
            Search-And-Launch $SiteToSearch
            return;
        }
    }
    catch
    {
         Write-Warning "Please provide valid option number"
         Write-Host "`n"      
         Search-And-Launch $SiteToSearch
         return;
    }
      

    $optionSelected  = -1
    do {    
    
    Show-OptionList 
    $optionSelected = Read-Host
        

     switch ($optionSelected.ToCharArray())
     { 
        1{
        Write-Host "`n" 
        Write-Host "IIS EXPRESS :"
         $isIISActive =  ps | where {$_.Name -eq "iisexpress"} | select -First 1
         $launchBrowser = "n" 

         if($isIISActive) {
             kill -name $isIISActive.ProcessName
             Write-Host "Restarting IIS Express" -ForegroundColor Yellow
           $launchBrowser =  Read-Host -Prompt "Launch Private Browser Window (y/n) "
         }         
                  
         foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}  
                if( Test-Path $launchSiteOption.LocalPath) {                              
                Launch-IISExpress -siteId $launchSiteOption.SiteId -message "Launching IISExpress for....$($launchSiteOption.SiteName)"                 

                }else{
                 Write-Warning "Invalid Path $($launchSiteOption.LocalPath)"
                }

                if( $launchSiteOption.UpdatePath -is [String] -and !(Test-Path $launchSiteOption.UpdatePath)) {                              
                    Write-Warning "Invalid remote path $($launchSiteOption.UpdatePath)"
                    Write-Warning "JavasScript and css file might not load properly" 
                }
                
                Start-Sleep -Seconds 2

                if( $launchBrowser -eq "y" -and $launchSiteOption.DefaultUrl -is [String]){                     
                    $defaultBrowser = (Get-ItemProperty HKCU:\Software\Microsoft\windows\Shell\Associations\UrlAssociations\http\UserChoice).Progid                   

                    Write-Host "Opening in private window .. $($launchSiteOption.DefaultUrl) in $($defaultBrowser)"

                    switch -Regex ($defaultBrowser){
                     '^firefox'{
                      Start-Process firefox "-private-window $($launchSiteOption.DefaultUrl)"
                      }
                     '^chrome'{ 
                     Start-Process chrome "$($launchSiteOption.DefaultUrl) -incognito" 
                     }
                     default{ Start $launchSiteOption.DefaultUrl -ArgumentList }
                    }
                    
                }
            }           
        }

        2{
        Write-Host "`n" 
        Write-Host "Visual Studio Solutions :" -ForegroundColor Yellow
             foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}                  
                Open-Solution -path $launchSiteOption.LocalPath -message "Opening solution for....$($launchSiteOption.SiteName)";
                Start-Sleep -Seconds 2;
                cd $launchSiteOption.LocalPath;
           }            
                      
         }
                 
        3{         
        Write-Host "`n" 
        Write-Host "Selected site option :" -ForegroundColor Yellow          
            $selectedSite | Where-Object { $_.Option -in $launchSite.Split(',') } | Format-List -Property Option,SiteName,LocalPath,UpdatePath,DBServer,Database
         }
        4{
            foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}  
                if( Test-Path $launchSiteOption.LocalPath) {                              
                Open-Folder -folderPath $launchSiteOption.LocalPath  
                }else{
                 Write-Warning "Invalid Path $($launchSiteOption.LocalPath)"
                }
                sleep -Milliseconds 5
            } 
         }
        5{        
            $optionSelected = -1
         }
        6{
            foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}  
                if($launchSiteOption.UpdatePath -is [String] -and (Test-Path $launchSiteOption.UpdatePath)) {                              
                Open-Folder -folderPath $launchSiteOption.UpdatePath  
                }else{
                  if($launchSiteOption.UpdatePath -is [String]){
                    Write-Warning "Invalid Path $($launchSiteOption.UpdatePath)"
                  }else{
                    Write-Warning "Update path  missing from config for $($launchSiteOption.SiteName)"
                  }                 
                }
                sleep -Milliseconds 5
            } 
         }
        7{            
            Write-Host "`n"    
            Write-Host "Options Available"   
            Write-Host "1 -> Remote"
            Write-Host "2 -> Local"    
            Write-Host "3 -> Custom"
            Write-Host "`n" 
            Write-Host "What Now: " -ForegroundColor Green -NoNewline
            $fileListOption = Read-Host
            Write-Host "`n" 
            Write-Warning "This might take couple of minutes"
            Write-Host "`n"
             foreach($site in $launchSite.Split(',')){
                    $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()} 
                         switch ($fileListOption.ToCharArray())
                            {
                                1{                                     
                                     if($launchSiteOption.UpdatePath -is [String] -and (Test-Path $launchSiteOption.UpdatePath)) { 
                                        
                                        Get-Updated-File-List -UpdatesPath $launchSiteOption.UpdatePath -NumberOfDays 1
                                    }else {
                                         Write-Warning "Update path missing from config for $($launchSiteOption.SiteName)"
                                    }
                                 }
                                2{
                                     if($launchSiteOption.LocalPath -is [String] -and (Test-Path $launchSiteOption.LocalPath)) { 
                                        
                                        Get-Updated-File-List -UpdatesPath $launchSiteOption.LocalPath -NumberOfDays 1
                                    }else {
                                         Write-Warning "Local path missing from config for $($launchSiteOption.SiteName)"
                                    }
                                 }
                                3{                                       
                                        Get-Updated-File-List
                                 }
                            }
             }

         }
        8{
           foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}  
                if($launchSiteOption.DBServer -is [String] -and $launchSiteOption.Database -is [String])
                {
                 Open-Database -SiteName $launchSiteOption.SiteName -DBServer $launchSiteOption.DBServer -Database $launchSiteOption.Database
                } else {
                 Write-Warning "Database Config missing for $($launchSiteOption.SiteName)"
                } 
                
                sleep -Milliseconds 50
            } 
         }
        9{           
           foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}                
                if($launchSiteOption.UpdatePath -is [String] -and (Test-Path $launchSiteOption.UpdatePath)) {                                         
                     Open-SynchronizationTool -ConfigFile $SearchAndLaunchConfigFilePath -LocalPath $launchSiteOption.LocalPath -RemotePath $launchSiteOption.UpdatePath 
                }else{
                       Write-Warning "Remote server path missing from config for $($launchSiteOption.SiteName)"                                    
               }                  
                               
                sleep -Milliseconds 50
            } 
         }  
        0{            
            Write-Host "`n"        
            Write-Host "Good Bye...." -ForegroundColor Green
            $optionSelected = [Int32]::MinValue
         }
        b{
            if (Get-Module -ListAvailable -Name Invoke-MsBuild) {
                Write-Host "`n" 
                Write-Host "Building Solution :" -ForegroundColor Yellow
                foreach($site in $launchSite.Split(',')){
                    $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}                  
                    BuildSolution -solutionFolder $launchSiteOption.LocalPath -message "Building solution for....$($launchSiteOption.SiteName)"
                    Start-Sleep -Seconds 2
                } 
            } 
            else {
                Write-Host "Module does not exist Please install Invoke-MsBuild module for powershell"
                Write-Host "Command : Install-Module -Name Invoke-MsBuild "
            }

                   
                      
         }
         r{
                     
                Write-Host "`n" 
                Write-Host "Resetting readonly flag for solution :" -ForegroundColor Yellow
                foreach($site in $launchSite.Split(',')){
                    $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}                  
                    ResetReadOnlyOnBinFolder -solutionFolder $launchSiteOption.LocalPath -message "Please try to build the solution now"
                    Start-Sleep -Seconds 2            
                 }   
         }
         c{
                     
                Write-Host "`n" 
                Write-Host "Clone Solution :" -ForegroundColor Yellow
                Clone-Git-Solution
                Start-Sleep -Seconds 2
         }
         s{
                Write-Host "`n" 
                Write-Host "Adding site to IIS Express Config :" -ForegroundColor Yellow
                Add-Site-to-IISExpress-Config
                Start-Sleep -Seconds 2
          }
         l{            
            Write-Host "`n"    
            Write-Host "Options Available"   
            Write-Host "1 -> TFS"
            Write-Host "2 -> GIT"    
            Write-Host "0 -> Exit"
            Write-Host "`n" 
            Write-Host "What Now: " -ForegroundColor Green -NoNewline
            $commitOption = Read-Host
            Write-Host "`n" 
             foreach($site in $launchSite.Split(',')){
                    $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()} 
                     cd $launchSiteOption.LocalPath
                         switch ($commitOption.ToCharArray())
                            {
                                1{      
                                   $tfsResult = & tf stat . /recursive
                                   $results =  $tfsResult | Select-String '.[:].*[\n\r]?' -AllMatches 
                                   $TEMP_TFS_FILE_PATH =  ($env:TEMP + '\CheckedOutTfsfile.txt')                                   
                                   $results.Matches.Value | Out-File $TEMP_TFS_FILE_PATH
                                   NotePad $TEMP_TFS_FILE_PATH                                                                                    
                                 }
                                2{
                                    Write-Host "You can provide commit range as well e.g.: 81b541cb..bdcf4c2c OR HEAD~0..HEAD~7 OR HEAD~0"
                                    Write-Host "Commit: " -ForegroundColor Green -NoNewline
                                    $commitOption = Read-Host     
                                    
                                    if($commitOption -match ".") 
                                    {
                                        Get-GitCommit-FileList -commitRange $commitOption
                                    }
                                    else 
                                    {
                                        Get-GitCommit-FileList -fromCommit $commitOption
                                    }                                                                   
                                    
                                 }
                                0{                                       
                                    $optionSelected = 3;
                                 }
                            }
             }

         }
        default{
            Write-Host "`n"        
            Write-Host "Please provide proper option...." -ForegroundColor Red
        }        
     }
    } while($optionSelected -gt 0)      
   
   if( $optionSelected -eq -1){
    Write-Host "`n" 
    Search-And-Launch
   }

  } else {
    Write-host "No Site with " $SiteToSearch " name found" -ForegroundColor Red
    Search-And-Launch
}

}

function Open-Solution( [string]$path,[string] $message) {  

  if(Test-Path $path){
    $solutionFile = Get-ChildItem -Path $path -Filter *.sln | Select-Object -First 1

   $solutionName = $solutionFile.ToString().Split(".")[0]

   $IsOpenSolution = Get-Process devenv -ErrorAction SilentlyContinue | where {$_.MainWindowTitle -match $solutionName } | select

   if(!$IsOpenSolution){
    $fullpath = Join-Path -Path $path -ChildPath $solutionFile      
    Write-Host $message 
   Start-Process  $fullpath  -WindowStyle Normal
   } else{
        Write-Host "Solution is already open $($solutionFile)"
   }
  }else{
   Write-Warning "Invalid Path: $($path)"
  }  
    
}

function Launch-IISExpress([string] $siteId,[string] $message){    
    $iisArgument = "/siteid:$($siteId) /systray:false /trace:n"
    Write-Host $message -ForegroundColor Yellow
    start 'C:\Program Files\IIS Express\iisexpress.exe' -ArgumentList $iisArgument    
}

function Open-Folder([string] $folderPath){        
    Write-Host "Opening path ..$($folderPath)" -ForegroundColor Yellow
    start 'C:\Windows\explorer.exe' -ArgumentList $($folderPath)
}

function Open-Database([string] $SiteName, [string] $DBServer, [string] $Database ){        
    Write-Host "Opening SQL Management Studio for ..$($SiteName)" -ForegroundColor Yellow
    $args = "-S $($DBServer) -d $($Database) -E -nosplash"
    start 'Ssms' -ArgumentList $args
}

function Open-SynchronizationTool($ConfigFile, [string] $LocalPath, [string] $RemotePath){  
  [xml] $configObj = Get-Content $ConfigFile
  $defaultSyncTool = $configObj.settings.synctools.add | where-object {$_.name -match 'primary'} | Select-Object -First 1
  $toolName = $defaultSyncTool.value
  $toolPath = $defaultSyncTool.path
  switch ($toolName)
     { 
        "SynchronizeIt"{
          Open-SynchronizeIt -folderPath1 $LocalPath -folderPath2 $RemotePath -path $toolPath
        }
        "Winmerge"{          
          Open-Winmerge -folderPath1 $LocalPath -folderPath2 $RemotePath -path $toolPath
        }        
        "BeyondCompare4"{
          Open-BeyondCompare -folderPath1 $LocalPath -folderPath2 $RemotePath -path $toolPath
        }
   }

}

function Open-SynchronizeIt([string] $folderPath1, [string] $folderPath2 , [string] $path){ 
    if([System.IO.File]::Exists($path)){ 
      Write-Host "Opening path SynchronizeIt" -ForegroundColor Yellow
      $args = [string]::concat($($folderPath1)," ",$($folderPath2))   
      start $path -ArgumentList $args 
    }else{
      Write-Warning "Sorry .. tool was not able to find the file path for SynchronizeIt. Please update settings in config file"      
    }
}

function Open-Winmerge([string] $folderPath1, [string] $folderPath2,[string] $path){     
    if([System.IO.File]::Exists($path)){ 
      Write-Host "Opening path Winmerge" -ForegroundColor Yellow
      $args = [string]::concat("-u -e ", $($folderPath1)," ",$($folderPath2))  
      start $path -ArgumentList $args 
    }else{
      Write-Warning "Sorry .. tool was not able to find the file path for Winmerge. Please update settings in config file"      
    }
}

function Open-BeyondCompare([string] $folderPath1, [string] $folderPath2,[string] $path){     
    if([System.IO.File]::Exists($path)){ 
      Write-Host "Opening path Beyond Compare 4" -ForegroundColor Yellow
      $args = [string]::concat("/nobackups /ro " ,$($folderPath1)," ",$($folderPath2))  
      start $path -ArgumentList $args 
    }else{
      Write-Warning "Sorry .. tool was not able to find the file path for Beyond Compare 4. Please update settings in config file"
  }
}

function Show-OptionList(){
    Write-Host "`n"    
    Write-Host "Options Available (*eg: 120 will Launch IISExpress and Open website, Open solution and exit)" 
    Write-Host "1 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Launch/Restart IISExpress"
    Write-Host "2 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Open solution"  
    Write-Host "3 " -ForegroundColor Green -NoNewline    
    Write-Host "-> Selected option/s"
    Write-Host "4 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Open Local Folder"
    Write-Host "5 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Search Again"
    Write-Host "6 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Open Remote Folder"
    Write-Host "7 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Get Modified File List"
    Write-Host "8 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Connect To Database" 
    Write-Host "9 " -ForegroundColor Green -NoNewline  
    Write-Host "-> Open Synchronization Tool"     
    Write-Host "b " -ForegroundColor Green -NoNewline  
    Write-Host "-> Build the solution"
    Write-Host "r " -ForegroundColor Green -NoNewline  
    Write-Host "-> Reset read only flag for all bin folders"
    Write-Host "c " -ForegroundColor Green -NoNewline  
    Write-Host "-> Clone a git repo" 
    Write-Host "s " -ForegroundColor Green -NoNewline  
    Write-Host "-> Add new site to IIS Configuration"  
    Write-Host "l " -ForegroundColor Green -NoNewline  
    Write-Host "-> Get Checked out/committed file list"         
    Write-Host "Hit Enter or 0 to Exit" -ForegroundColor Yellow  
    Write-Host "`n"
    Write-Host "What Now: " -ForegroundColor Green -NoNewline  
}

function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
	$lines = ($input | Out-String) -replace "`r", "" -split "`n"
	foreach($line in $lines) {
		$color = ''
		foreach($pattern in $Colors.Keys){
			if(!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
			elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
		}
		if($color) {
			Write-Host -ForegroundColor $color $line
		} else {
			Write-Host $line
		}
	}
}


function BuildSolution($solutionFolder, $message) {

$solutionFile = (Get-ChildItem -Path $solutionFolder -Filter *.sln | Select-Object -First 1).FullName

$buildLogFolder = [string]::concat($($solutionFolder),'\BuildLogs')

 if(!(Test-path $buildLogFolder)){
    New-Item -ItemType Directory -Force -Path $buildLogFolder
      Write-Output ("Creating build log folder")
 }
 
Write-Host $message 

$buildResult = Invoke-MsBuild -Path $solutionFile -MsBuildParameters "/target:Clean;Build /p:Configuration=Debug /m /v:m /preprocess:importedFiles.txt;" -ShowBuildOutputInNewWindow -BuildLogDirectoryPath $buildLogFolder -KeepBuildLogOnSuccessfulBuilds -AutoLaunchBuildErrorsLogOnFailure

        if ($buildResult.BuildSucceeded -eq $true)
        {
	        Write-Output ("Build completed successfully in {0:N1} seconds." -f $buildResult.BuildDuration.TotalSeconds)
        }
        elseif ($buildResult.BuildSucceeded -eq $false)
        {
	        Write-Output ("Build failed after {0:N1} seconds. Check the build log file '$($buildResult.BuildLogFilePath)' for errors." -f $buildResult.BuildDuration.TotalSeconds)
        }
        elseif ($null -eq $buildResult.BuildSucceeded)
        {
	        Write-Output "Unsure if build passed or failed: $($buildResult.Message)"
        }

}

function ResetReadOnlyOnBinFolder($solutionFolder,$message){
    Get-ChildItem -Path $solutionFolder -Directory -Recurse -Filter "*bin*" | %{ Get-ChildItem -Path $_.FullName -Recurse -File | %{ $_.IsReadOnly = $False }}
    Write-Host $message 
}