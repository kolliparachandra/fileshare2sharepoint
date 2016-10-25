#extract path to source code directory for future reference
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Function Initialize-SharepointPublisher
{
#[CmdletBinding()]
#param ()

<# 
 .Synopsis
  SharepointPublisher

 .Description
    The purpose of this module is to automatically move files from a network files share to a Sharepoint library that meets some pre-determined naming requirement(s).  
    A file system process monitors the creation of new files that are placed within a specific directory. 
    Files meeting these criteria are either moved or copied to the destination Sharepoint library. 
    Optionally, the module can configure Sharepoint alerts for all users of a specific group.  
    Members of this group would then be notified of the creation of new items in the SharePoint library or list.
    This function is simply run whenever the configuration file is modified so that the new settings can take effect.

 .Example

    Running this command will create a new file-monitoring process and perform the required file copies/moves.
    The output shown below indicated that the new process was started and that two (2) new files were found and successfully copied to the destination site.
    
    POSH>  Initiate-SharepointPublisher

        Id     Name            PSJobTypeName   State         HasMoreData     Location             Command                  
        --     ----            -------------   -----         -----------     --------             -------                  
        6      FileCreated                     NotStarted    False                                 ...                     
        Copying file  16-1234-1234.12.12-b88116MyTestFiled - Copy.pdf  to  /personal/ront/Documents/TPS Rocks ...
        Successful copy of file .. 16-1234-1234.12.12-b88116MyTestFiled - Copy.pdf
        Copying file  16-1234-1234.12.12-b88116MyTestFiled.pdf  to  /personal/ront/Documents/TPS Rocks ...
        Successful copy of file .. 16-1234-1234.12.12-b88116MyTestFiled.pdf
     
#>

# module MUST be available to the script
# MUST be run on a SharePoint server

if((Get-PSSnapin "Microsoft.SharePoint.PowerShell") -eq $null)
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

#extract path to source code directory for future reference
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path


#read all configuration settins into their variables <nodes> for use by this script

Invoke-Expression "$myDir\settings.ps1 .\ConfigSettings.xml"

#call the script that sets up event monitoring

Invoke-Expression $myDir\DirMonitor.ps1


$str = "*" * 35
add-content -value "`n $str  S h a r e p o i n t  P u b l i s h e r $str `n"  -path $logging["auditlog"]
    
function set-alerts {

#$SPgroup = $SPweb.Groups["SharePoint Owners"]
#$SPlist = $SPweb.Lists["Shared Documents"]



#This is code that will set SharePoint alerts for everyone in the specifieded group
#Turning this component off once alerts have been set up does NOT remove users alerts. It just stops running the code
#Users who no longer want to receive alerts will need to turn them off manually.
# All users will receive the same settings, so you may have to create a new group for this purpose and only include those that want an alert set up for them.
 
$SPweb = Get-SPWeb $appSettings["webURL"]
$SPgroup = $SPweb.Groups[$alerts["group"]]
$SPlist = $SPweb.Lists[$Appsettings["documentlibrary"]]
foreach ($SPuser in $SPgroup.Users){
     # don't create duplicate alerts on this library
     if ((($SPweb.Alerts| where-object {$_.user -match $SPuser}).count -eq 0) -and $SPuser.userlogin -ne "SHAREPOINT\system")
    {
     $alert = $SPuser.Alerts.Add()
     $alert.Title = $alerts.title
     $alert.AlertType = $alerts.AlertType
     $alert.List = $SPlist
     $alert.DeliveryChannels = $alerts.DeliveryChannels
     $alert.EventType = $alerts.EventType
     $alert.AlertFrequency = $alerts.AlertFrequency
     $alert.Update()
  
     add-content -value "Setting SharePoint alert for $($SPuser.DisplayName) " -path $logging["auditlog"]
    }
}
# Remind SHarePoint administrator to turn Alerts["EnableAlerts"] OFF once the alerts have been set for the group.
Write-host "Reminder:  Consider turning off Alerts in configuration file so that alerts are not re-created for users who have turned them off manually." -foregroundcolor Magenta
add-content -value "Reminder:  Consider turning off Alerts in configuration file so that alerts are not re-created for users who have turned them off manually." -path $logging["auditlog"]
$SPweb.Dispose()


}

If ($Alerts["enableAlerts"] -eq "ON")
{
set-alerts
}


# Write all configurable variables to the audit log to aid in troubleshooting and or auditing

add-content -value "The following lists all of the variables and their values as of $(get-date)"  -path $logging["auditlog"]
out-File -append -FilePath $logging["auditlog"] -InputObject $allSettings -Encoding ASCII -Width 130




 # Import email settings from config file
[xml]$ConfigFile = Get-Content "$MyDir\ConfigSettings.xml"

    #load necessary variables from configuration file

    $webUrl =$appSettings["webURL"]
    $docLibraryName = $appSettings["documentLibrary"]
    $docLibraryUrlName = $appSettings["documentLibraryURL"]
    $localFolderPath = $appSettings["monitordirectory"]

    #Open web and library

    $web = Get-SPWeb $webUrl
    $docLibrary = $web.Lists[$docLibraryName]

    # needed to check if file exists in Sharepoint library
    $mySiteHostSite = Get-SPSite $webUrl
    $mySiteHostWeb = $mySiteHostSite.OpenWeb()
    
    #set $filter variable to contain the designated string that determines whether the file will be copied or not
   
    $filter = $appsettings["filter"]
   

    $files = ([System.IO.DirectoryInfo] (Get-Item $localFolderPath)).GetFiles()

    # write-host $files

    ForEach($file in $files)
    {

# only choose those files that meet the configured filter specification

if($file.name -match $filter)
{
    #write-host $file
    $fileowner = (Get-Acl ($appsettings.monitordirectory+"\"+$file) | Select Path, Owner).owner
    $datestamp = get-Date
    $loggedOnUser = [Environment]::UserName

        #Open file
        try
        {
        $fileStream = ([System.IO.FileInfo] (Get-Item $file.FullName)).OpenRead()

        #Add file
        $folder =  $web.getfolder($docLibraryUrlName)

        $destinationPath = "$weburl/$doclibraryUrlName/$file"
        $destinationpath = [uri]::EscapeURIString($destinationPath)
        #check to see if file exists
        # or whether OVERWRITE is set to ON - NOT IMPLEMENTED!  This would allow members to make modifications to documents that have already been published.
         if ((!$mySiteHostWeb.GetFile($destinationpath).Exists)) {
  

switch ($appsettings["action"]) 
    { 
        "Copy"        
        {

        
        write-host "Copying file " $file.Name " to " $folder.ServerRelativeUrl "..."
        $spFile = $folder.Files.Add($folder.Url + "/" + $file.Name,[System.IO.Stream]$fileStream, $true)
         write-host "Successful copy of file .." $file.Name 
         add-content -value "File $($file.name) belonging to $fileowner was COPIED by $loggedOnUser to $destinationpath on $datestamp" -path $logging["auditlog"]
         }
         
         
        "Move"
        { 
         write-host "Moving file " $file.Name " to " $folder.ServerRelativeUrl "..."
        $spFile = $folder.Files.Add($folder.Url + "/" + $file.Name,[System.IO.Stream]$fileStream, $true)
        write-host "Successful move of file .." $file.Name 
        add-content -value "Moved file $file.Name belonging to $fileowner was moved by $loggedOnUser on $datestamp" -path $logging["auditlog"] 
        }
        default {"Must be either Copy or Move."}
    }  
    }  

        #Close file stream
        $fileStream.Close();
        }
        catch
        {
        Write "Error: $file.name: $_" >> $logging["errorlog"]
            continue;
        }
        }
        
}

    

    #Dispose web

    $web.Dispose()


}
