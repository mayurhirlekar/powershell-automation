Function Add-Site-to-IISExpress-Config(){
param(
 [Parameter(Mandatory=$false)][string]$siteBasePath,
 [Parameter(Mandatory=$false)][string]$updateSitePath
)

$appExeFolder = 'C:\Program Files\IIS Express\' 

if([string]::IsNullOrEmpty($siteBasePath) -or -not (Test-Path $siteBasePath)){
    Write-Warning 'local site path e.g: C:\inetpub\wwwroot\fullcirclepadding.com'  
    $siteBasePath =  Read-Host -Prompt 'Local site path'
}

if([string]::IsNullOrEmpty($updateSitePath) -or -not (Test-Path $updateSitePath)){
    Write-Warning 'Update site path e.g: C:\inetpub\wwwroot\fullcirclepadding.com'  
    $updateSitePath =  Read-Host -Prompt 'Update/design site path'
}

$maxSiteId = GetNewSiteIdForRegistration;

$siteName =  Read-Host -Prompt 'Enter site name';

$currentDirectory = $PWD.Path;

cd $appExeFolder

try{
    $basewebsitePath = Join-Path -Path $siteBasePath -ChildPath "\web\"    
    $command =  " add site /name:$siteName /id:$maxSiteId /bindings:http/*:80:localhost /physicalPath:$basewebsitePath /applicationDefaults.applicationPool:Clr4IntegratedAppPool" 
    start .\appcmd.exe -ArgumentList $command
    Start-Sleep -Seconds 1

    $ckEditorPath = Join-Path -Path $updateSitePath -ChildPath "\ckeditor"
    if(Test-Path $ckEditorPath){
    $ckeditorVirtualPath =  " add vdir /app.name:$siteName/ /path:/ckeditor /physicalPath:$ckEditorPath"
    start .\appcmd.exe -ArgumentList $ckeditorVirtualPath
    }
    Start-Sleep -Seconds 1

    $assetsPath = Join-Path -Path $updateSitePath -ChildPath "\web\assets\"
    if(Test-Path $assetsPath){
    $assetVirtualPath = " add vdir /app.name:$siteName/ /path:/assets /physicalPath:$assetsPath"
     start .\appcmd.exe -ArgumentList $assetVirtualPath
    }
    Start-Sleep -Seconds 1

    $imagesPath = Join-Path -Path $updateSitePath -ChildPath "\web\cms\images\"
    if(Test-Path $imagesPath){
    $imagesVirtualPath = " add vdir /app.name:$siteName/ /path:/images /physicalPath:$imagesPath"
     start .\appcmd.exe -ArgumentList $imagesVirtualPath
    }
    Start-Sleep -Seconds 1

    Write-Host 'Copy Registry key file to your desktop and install the registry key'
    $registryfolderPath = 'M:\_Programming\_registry keys'
    start 'C:\Windows\explorer.exe' -ArgumentList $($registryfolderPath)
        
}
catch {
 Write-Error 'Error occured :('  
    }
    
  cd $currentDirectory
}


function GetNewSiteIdForRegistration(){
$configPath = [Environment]::GetFolderPath("MyDocuments") + "\IISExpress\config\applicationhost.config"
[xml] $con = Get-Content $configPath
$maxSiteId = 0
foreach($site in $con.configuration.'system.applicationHost'.sites.site){
    $maxSiteId = [Math]::Max($maxSiteId,$site.id)
}
return $maxSiteId + 1

}
