
function FilesForWebApp() {
param(
 [Parameter(Mandatory=$true)][string]$workingDirectory,
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

            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name ClassNameWithNamespace -Value $classNameWithNamespace
     
            $namespace = $classNameWithNamespace.Substring(0, $classNameWithNamespace.LastIndexOf("."))
            Add-Member -InputObject $fileChange -MemberType NoteProperty -Name Namespace -Value $namespace
        
    
            $className = $classNameWithNamespace.Substring($classNameWithNamespace.LastIndexOf(".") + 1)

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

                  Add-Member -InputObject $fileChange -MemberType NoteProperty -Name CurrentClassName -Value $classNameToReplace 

                  $replaceCodeFileWithCodeBehind = $replaceCodeFileWithCodeBehind.Replace($classNameToReplace, $classNameWithNamespace) 
         

                  Add-Member -InputObject $fileChange -MemberType NoteProperty -Name ReplacedLineWithText -Value $replaceCodeFileWithCodeBehind

                  $ChangeList += $fileChange

                  break
                }
              }
            }
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



        # Update VB Files with NameSpace and Class name
        $ChangeList | % {

            $lastImportLineText = ""
            $filePathVB = $_.Path + ".vb"
      
   
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
                    $fileContent = $fileContent.Replace($_.CurrentClassName, $_.ClassName).Replace($lastImportLineText, $lastImportLineText + "`r`n`r`nNamespace " + $_.Namespace ) + "`r`n`r`nEnd Namespace" 
                   [System.IO.File]::WriteAllLines($filePathVB,$fileContent)
                } elseif ($fileContent -notcontains "End Namespace"){
                   # No import statement found :(  
                   $fileContent = "`r`n`r`nNamespace " + $_.Namespace + "`r`n`r`n" + $fileContent.Replace($_.CurrentClassName, $_.ClassName) + "`r`n`r`nEnd Namespace" 
                   [System.IO.File]::WriteAllLines($filePathVB,$fileContent)                      
                }
            }
            catch
            {
                Write-Warning $filePathVB
            }

            $fileContent  = ""
            $filePathVB = ""
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