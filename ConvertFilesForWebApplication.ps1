
function FilesForWebApp() {
param(
 [Parameter(Mandatory=$true)][string]$workingDirectory,
<<<<<<< HEAD
 [Parameter(Mandatory=$true)][string]$copyFromDirectory
)      

        Get-ChildItem -Path $copyFromDirectory | Copy-Item -Destination $workingDirectory -Recurse -Force


        #Create Designer file
        ls -Path $workingDirectory -Recurse -Include  *.ascx.vb,*.aspx.vb | %{

            $designerFileName = $_.FullName.Replace(".vb",".designer.vb ")

            if (!(Test-Path $designerFileName)) {
                #Copy-Item -Path $_.FullName -Destination $designerFileName 
                echo $null >> $designerFileName
            }       
 
         }

        $ChangeList = @()

        ls -Path $workingDirectory -Recurse -Include *.ascx,*.aspx | % {
    
            $fileChange = New-Object psobject    
            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name Path -Value $_.fullName
    

            $filePathString = $_.FullName.Replace($workingDirectory,"").Trim("\").Replace(".ascx","").Replace(".aspx","").Replace("\"," ").Trim()

            $classNameWithNamespace = GetFullInNamePascalCase($filePathString) 

            $classNameWithNamespace = $classNameWithNamespace.Replace(" ",".") 
=======
 [Parameter(Mandatory=$true)][string]$copyFromDirectory,
 [Parameter(Mandatory=$true)][string]$topLevelDefaultNamespace,
 [Parameter(Mandatory=$false)][bool]$forceTopLevelNamespaceOnAll = $false,
 [Parameter(Mandatory=$false)][bool]$changeFileNametoLowerCase = $false
)      

        CopyFilesToWorkingDirectory -copyFrom $copyFromDirectory -copyTo $workingDirectory              
                
        CreateDesignerFiles -workingPath $workingDirectory 
      
        $ChangeList = @()

        ls -Path $workingDirectory -Recurse -Include *.ascx,*.aspx | % { $ChangeList += BuildObjectWithDetailsForFilesChanges -currentFile $_ }
        
        # Update ASPX & ASCX Files
        $ChangeList | ForEach-Object { UpdateFrontEndFile -path $_.Path  }


        # Update VB Files with NameSpace and Class name
        $ChangeList | ForEach-Object { UpdateCodeFileClassNameAndNamespace -obj $_ }

        if($changeFileNametoLowerCase)
        {
         ChangeFileNameToLowerCase -baseDirectory $workingDirectory 
        }
}



function GetFullInNamePascalCase([string] $inStr){
  $outString = ""
  $conn = ""
  $inStr.Split(" ") | %{  
      $tempString = ChangeFirstletterToUpperCase -inputString $_
      $outString +=  $conn + $tempString
      $conn = " "   
  } 
  return $outString
}


function ChangeFirstletterToUpperCase([string] $inputString) {
    return ($inputString.substring(0,1).toupper() + $inputString.substring(1)).Trim()
}


function ChangeFileNameToLowerCase($baseDirectory){
    dir $baseDirectory -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }   
}

function CopyFilesToWorkingDirectory($copyFrom , $copyTo ){
    Get-ChildItem -Path $copyFrom | Copy-Item -Destination $copyTo -Recurse -Force
}

function CreateDesignerFiles($workingPath) {
   
   ls -Path $workingPath -Recurse -Include  *.ascx.vb,*.aspx.vb | %{

            $designerFileName = $_.FullName.Replace(".vb",".designer.vb ")
            if (!(Test-Path $designerFileName)) {
                #Copy-Item -Path $_.FullName -Destination $designerFileName 
                echo $null >> $designerFileName
            }  
         }

}

function UpdateFrontEndFile($path) {
            $filePathASCX = $path           
            $readerASCX  = [System.IO.File]::OpenText($filePathASCX)
            try 
            {
              $fileContentASCX = $readerASCX.ReadToEnd()       
              $fileContentASCX = $fileContentASCX.Replace($_.LineToBeReplaced, $_.ReplacedLineWithText)
            }
            finally 
            {
                #Making Sure File is closed 
                $readerASCX.Close()
            }
    
            [System.IO.File]::WriteAllLines($filePathASCX,$fileContentASCX)
    
            $fileContentASCX  = ""
            $filePathASCX = ""
        }      

 function BuildObjectWithDetailsForFilesChanges($currentFile) {
            $fileChange = New-Object psobject    
            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name Path -Value $currentFile.fullName

            $filePathString = $fileChange.Path.Replace($workingDirectory,"").Trim("\").Replace(".ascx","").Replace(".aspx","").Replace("\"," ").Trim()

            $classNameWithNamespace = GetFullInNamePascalCase -inStr $filePathString.Replace('default','index').Replace('Default','Index')

            $classNameWithNamespace = $classNameWithNamespace.Replace(" ",".") 
            

            if($forceTopLevelNamespaceOnAll){

                $classNameWithNamespace = $topLevelDefaultNamespace + "."  + $classNameWithNamespace                
                
            }
            else { 
            
            #if no namepace make sure to add default namespace
                if($classNameWithNamespace.LastIndexOf(".") -le 0){
                        $classNameWithNamespace = $topLevelDefaultNamespace + "."  + $classNameWithNamespace
                  }                
            }

>>>>>>> dev

            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name ClassNameWithNamespace -Value $classNameWithNamespace
     
            $namespace = $classNameWithNamespace.Substring(0, $classNameWithNamespace.LastIndexOf("."))
<<<<<<< HEAD
            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name Namespace -Value $namespace
        
    
            $className = $classNameWithNamespace.Substring($classNameWithNamespace.LastIndexOf(".") + 1)
=======
                        
            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name Namespace -Value $namespace
                               
    
            $className = GetFullInNamePascalCase -inStr $classNameWithNamespace.Substring($classNameWithNamespace.LastIndexOf(".") + 1).Trim()
>>>>>>> dev

            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name ClassName -Value  $className  


            $reader = [System.IO.File]::OpenText($_.FullName)
            try 
            {
                while($null -ne ($line = $reader.ReadLine())) {
                 
                  if( $line.StartsWith("<%@ Control") -or $line.StartsWith("<%@ Page")){
        
                  Add-Member -InputObject $fileChange -MemberType NoteProperty -Name LineToBeReplaced -Value $line          

                  $replaceCodeFileWithCodeBehind = $line.Replace("CodeFile=","CodeBehind=")

                  $test = $replaceCodeFileWithCodeBehind.Substring($replaceCodeFileWithCodeBehind.IndexOf("Inherits="))

                  $test = $test.Substring($test.IndexOf(""""))

                  $classNameToReplace  = $test.Substring(1,$test.IndexOf("""",1) - 1)

<<<<<<< HEAD
=======
                  if ($classNameToReplace -contains 'ajax') {
                  Write-Host $classNameToReplace

                   }

>>>>>>> dev
                  Add-Member -InputObject $fileChange -MemberType NoteProperty -Name CurrentClassName -Value $classNameToReplace 

                  $replaceCodeFileWithCodeBehind = $replaceCodeFileWithCodeBehind.Replace($classNameToReplace, $classNameWithNamespace) 
         

<<<<<<< HEAD
                  Add-Member -InputObject $fileChange -MemberType NoteProperty -Name ReplacedLineWithText -Value $replaceCodeFileWithCodeBehind

                  $ChangeList += $fileChange
=======
                  Add-Member -InputObject $fileChange -MemberType NoteProperty -Name ReplacedLineWithText -Value $replaceCodeFileWithCodeBehind                 
>>>>>>> dev

                  break
                }
              }
            }
<<<<<<< HEAD
            finally 
            {
                #Making Sure File is closed 
                $reader.Close()
            }
   
   
        }

        #Just To check the list
        #$ChangeList | Format-List


        # Update ASCX Files
        $ChangeList | % {
    
            $filePathASCX = $_.Path            
            $readerASCX  = [System.IO.File]::OpenText($filePathASCX)
            try 
            {
              $fileContentASCX = $readerASCX.ReadToEnd()       
              $fileContentASCX = $fileContentASCX.Replace($_.LineToBeReplaced, $_.ReplacedLineWithText)
=======
            catch
            {
                Write-Warning $_.FullName
>>>>>>> dev
            }
            finally 
            {
                #Making Sure File is closed 
<<<<<<< HEAD
                $readerASCX.Close()
            }
    
            [System.IO.File]::WriteAllLines($filePathASCX,$fileContentASCX)
    
            $fileContentASCX  = ""
            $filePathASCX = ""
        }



        # Update VB Files with NameSpace and Class name
        $ChangeList | % {

            $lastImportLineText = ""
            $filePathVB = $_.Path + ".vb"
      
=======
                $reader.Close()
            }
            return $fileChange
    }

function UpdateCodeFileClassNameAndNamespace($obj){
    
      $lastImportLineText = ""
            $filePathVB = $obj.Path + ".vb"     
>>>>>>> dev
   
            $reader = [System.IO.File]::OpenText($filePathVB)
            try 
            {
                while($null -ne ($line = $reader.ReadLine())) {
                 
                if( $line.StartsWith("Imports")){        
                  $lastImportLineText = $line
                }
              }      

      
            }
            finally 
            {
                #Making Sure File is closed 
                $reader.Close()
            }


            #I Know!!!
            $reader = [System.IO.File]::OpenText($filePathVB)
            try 
            {        
              $fileContent = $reader.ReadToEnd()
            }
            finally 
            {
                #Making Sure File is closed 
                $reader.Close()
            }

   
            try 
            {
   
               #Skip file, if file has namespace 
                if($fileContent -notcontains "End Namespace" -and -not [String]::IsNullOrEmpty($lastImportLineText)) {     
<<<<<<< HEAD
                    $fileContent = $fileContent.Replace($_.CurrentClassName, $_.ClassName).Replace($lastImportLineText, $lastImportLineText + "`r`n`r`nNamespace " + $_.Namespace ) + "`r`n`r`nEnd Namespace" 
                   [System.IO.File]::WriteAllLines($filePathVB,$fileContent)
                } elseif ($fileContent -notcontains "End Namespace"){
                   # No import statement found :(  
                   $fileContent = "`r`n`r`nNamespace " + $_.Namespace + "`r`n`r`n" + $fileContent.Replace($_.CurrentClassName, $_.ClassName) + "`r`n`r`nEnd Namespace" 
                   [System.IO.File]::WriteAllLines($filePathVB,$fileContent)                      
                }
            }
            catch
=======
                    $fileContent = $fileContent.Replace($obj.CurrentClassName, $obj.ClassName).Replace($lastImportLineText, $lastImportLineText + "`r`n`r`nNamespace " + $obj.Namespace + "`r`n`r`n`r`n`r`n" ) + "`r`n`r`nEnd Namespace" 
                   [System.IO.File]::WriteAllLines($filePathVB,$fileContent)
                } elseif ($fileContent -notcontains "End Namespace"){
                   # No import statement found :(  
                   if($filePathVB -contains "default.aspx.vb"){
                    $fileContent = "`r`n`r`nNamespace " + $obj.Namespace + "`r`n`r`n`r`n`r`n" + $fileContent + "`r`n`r`n`r`n`r`nEnd Namespace"                    
                   }else{                   
                    $fileContent = "`r`n`r`nNamespace " + $obj.Namespace + "`r`n`r`n`r`n`r`n" + $fileContent.Replace($obj.CurrentClassName,$obj.ClassName) + "`r`n`r`n`r`n`r`nEnd Namespace"                    
                   }
                   
                   [System.IO.File]::WriteAllLines($filePathVB,$fileContent)                      
                }
            }
            catch 
>>>>>>> dev
            {
                Write-Warning $filePathVB
            }

            $fileContent  = ""
            $filePathVB = ""
<<<<<<< HEAD
        }

}

function GetFullInNamePascalCase([string] $inStr){
  $outString = ""
  $conn = ""

  $inStr.Split(" ") | %{ 
 
  $tempString = ChangeFirstletterToUpperCase($_)
  $outString +=  $conn + $tempString
  $conn = " "
    
  }

  return $outString
}



function ChangeFirstletterToUpperCase([string] $inString) {

 return ($inString.substring(0,1).toupper() + $inString.substring(1)).Trim()
}
=======
            $obj = ""

}
   
  
>>>>>>> dev
