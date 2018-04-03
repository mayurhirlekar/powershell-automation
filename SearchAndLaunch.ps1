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

    #iDev Specific
    $ConfigFile= '\web\web.config'
    $webConfigPath = Join-Path -ChildPath $ConfigFile -Path $siteObj.LocalPath
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


    #Kentico Specific
    $ConfigFile= '\CMS\web.config'
    $webConfigPath = Join-Path -ChildPath $ConfigFile -Path $siteObj.LocalPath
     if( -not [bool]($siteObj.PSobject.Properties.name -match "Database") ){
        
        if(Test-path $webConfigPath){
                [xml] $dbObj = Get-Content $webConfigPath 
                $dbConnectionString = $dbObj.configuration.connectionStrings.add.connectionString
            
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
    $selectedSite | Format-List -Property Option,SiteName,LocalPath,UpdatePath,DBServer,Database   
           
    $launchSite = Read-Host -Prompt "Enter Option (* Comma Seperated)"

    
    if([string]::IsNullOrEmpty($launchSite)){
         Write-Host "No option provided.. Back to search"
         Write-Host "`n"      
         Search-And-Launch
         return;
      }
      
    $notInOptions = $launchSite.Split(',') | Where-Object -FilterScript {[int32]$_ -ge $counter -or $_ -eq 0}

    if($notInOptions){
         Write-Host "Invalid option number.. Exiting Shell"         
         return;
      }
      

    $optionSelected  = -1
    do {    
    Show-OptionList
    $optionSelected = Read-Host -Prompt "Choice"
     
     switch ($optionSelected.ToCharArray())
     { 
        1{
        Write-Host "`n" 
        Write-Host "IIS EXPRESS :"
         $isIISActive =  ps | where {$_.Name -eq "iisexpress"} | select -First 1
         if($isIISActive) {
             kill -name $isIISActive.ProcessName
             Write-Host "Restarting IIS Express"
         }         
                  
         foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}  
                if( Test-Path $launchSiteOption.LocalPath) {                              
                Launch-IISExpress -siteId $launchSiteOption.SiteId -message "Launching IISExpress for....$($launchSiteOption.SiteName)" 
                }else{
                 Write-Host "Invalid Path $($launchSiteOption.LocalPath)"
                }
                sleep -Milliseconds 10
            }           
        }

        2{
        Write-Host "`n" 
        Write-Host "Visual Studio Solutions :"
             foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}                  
                Open-Solution -path $launchSiteOption.LocalPath -message "Opening solution for....$($launchSiteOption.SiteName)"
                sleep -Milliseconds 10
           }            
                      
         }
                 
        3{         
        Write-Host "`n" 
        Write-Host "Current List :"          
            $selectedSite | Format-List -Property Option,SiteName,LocalPath,UpdatePath,DBServer,Database
         }
        4{
            foreach($site in $launchSite.Split(',')){
                $launchSiteOption = $selectedSite | where {$_.Option -eq $site.Trim()}  
                if( Test-Path $launchSiteOption.LocalPath) {                              
                Open-Folder -folderPath $launchSiteOption.LocalPath  
                }else{
                 Write-Host "Invalid Path $($launchSiteOption.LocalPath)"
                }
                sleep -Milliseconds 5
            } 
         }
        5{        
            $optionSelected = -1
         }
        0{            
            Write-Host "`n"        
            Write-Host "Good Bye...."
             $optionSelected = [Int32]::MinValue
         }        
     }
    } while($optionSelected -gt 0)      
   
   if( $optionSelected -eq -1){
    Write-Host "`n" 
    Search-And-Launch
   }

  } else {
    Write-host "No Site with " $SiteToSearch " name found"
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
   Write-Host "Invalid Path: $($path)"
  }  
    
}

function Launch-IISExpress([string] $siteId,[string] $message){    
    $iisArgument = "/siteid:$($siteId) /systray:false /trace:n"
    Write-Host $message 
    start 'C:\Program Files\IIS Express\iisexpress.exe' -ArgumentList $iisArgument
}

function Open-Folder([string] $folderPath){        
    Write-Host "Opening path ..$($folderPath)"
    start 'C:\Windows\explorer.exe' -ArgumentList $($folderPath)
}

function Show-OptionList(){
    Write-Host "`n"    
    Write-Host "Options Available (*eg: 120 : Launch,Open solution,exit)"   
    Write-Host "1 -> Launch/Restart IISExpress"
    Write-Host "2 -> Open solution"    
    Write-Host "3 -> See List"
    Write-Host "4 -> Open Local Folder"
    Write-Host "5 -> Search Again"
    Write-Host "Hit Enter or 0 to Exit"   
    Write-Host "`n"  
}

Search-And-Launch