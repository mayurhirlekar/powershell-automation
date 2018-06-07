Import-Module .\GetUpdatedFileList.ps1
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
         if($isIISActive) {
             kill -name $isIISActive.ProcessName
             Write-Host "Restarting IIS Express" -ForegroundColor Yellow
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

                if( $launchSiteOption.DefaultUrl -is [String]){                     
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
                Open-Solution -path $launchSiteOption.LocalPath -message "Opening solution for....$($launchSiteOption.SiteName)"
                 Start-Sleep -Seconds 2
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
        0{            
            Write-Host "`n"        
            Write-Host "Good Bye...." -ForegroundColor Green
            $optionSelected = [Int32]::MinValue
         }
        default{
            Write-Host "`n"        
            Write-Host "Please provide proper number...." -ForegroundColor Red
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
