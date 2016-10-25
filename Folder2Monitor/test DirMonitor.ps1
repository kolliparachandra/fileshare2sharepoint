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
$filter = $appSettings["filter"][0]
$subdirectories = $appSettings

# In the following line, you can change 'IncludeSubdirectories to $true if required. 
$file_watcher = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}


#This script uses the .NET FileSystemWatcher class to monitor file events in folder(s). 

# In the following line, you can change 'IncludeSubdirectories to $true if required.                           
$file_watcher = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 
 
# Here, all three events are registerd.  You need only subscribe to events that you need: 
 
Register-ObjectEvent $file_watcher  Created -SourceIdentifier FileCreated -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 
Write-Host "The file '$name' was $changeType at $timeStamp" -fore green 
Out-File -FilePath c:\mytemp\outlog.txt -Append -InputObject "The file '$name' was $changeType at $timeStamp"} 
 
