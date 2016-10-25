<# .SYNOPSIS This script registers an event in PowerShell that monitors the source folder on the file share #>
#This script uses the .NET FileSystemWatcher class to monitor file events in folder(s).
#Values for most variables are derived from the ConfigSettings.xml file

[CmdletBinding()] param ()

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# unregister the event every time this script is run
Unregister-Event FileCreated -ErrorAction SilentlyContinue 

#Unregister the specified event if the administrator has turned off the directory monitoring in the configSettings file; otherwise make sure that the monitor event is working}
if ($management["enableALL"]-eq "OFF")
{
Unregister-Event FileCreated -ErrorAction SilentlyContinue 
Exit
}


#The -Action parameter can contain any valid Powershell commands. 

$folder = $appSettings["monitordirectory"]
$filter = $appSettings["filter"]
$subdirectories = $appSettings["subdirectories"]


<#This script uses the .NET FileSystemWatcher class to monitor file events in folder(s) and subfolders.
It then creates an instance of a Microsoft .NET Framework.
An argument list is provided that determines the behaviour of the event.
It specifies a list of arguments to pass to the constructor of the .NET Framework class. 
Separate elements in the list by using commas (,).

    FileSystemWatcher.Filter Property* - Gets or sets the filter string used to determine what files are monitored in a directory.

It also contains a -property argument
The value of the Property parameter is a hash table containing:

    FileSystemWatcher.IncludeSubdirectories Property  --> Gets or sets a value indicating whether subdirectories within the specified path should be monitored.
    FileSystemWatcher.NotifyFilter Property  --> Gets or sets the type of changes to watch for.

Changes to the values of the arguements should be made in the ConfigSettings.xml file.
Here is a listing of the arguments in the list:

   #>

$file_watcher = New-Object IO.FileSystemWatcher -ArgumentList $folder, $filter -Property @{IncludeSubdirectories = $subdirectories;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}
 
 
Register-ObjectEvent $file_watcher  Created -SourceIdentifier FileCreated -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 
Write-Host "The file '$name' was $changeType at $timeStamp" -fore green 
Out-File -FilePath c:\mytemp\outlog.txt -Append -InputObject "The file '$name' was $changeType at $timeStamp"} 
 
