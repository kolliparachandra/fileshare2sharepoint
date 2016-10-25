# This script parses/reads in the ConfigSettings.xml file so that the settings/variables are easily configurable by the administrator without touching the code
# These variables are then available to all of the script files contained in the module
param($path = $(throw "Please include config file"))

#global parameters <xml nodes>
$global:appSettings = @{}
$global:management = @{}
$global:logging = @{}
$global:alerts = @{}


$config = [xml](get-content $path)

#appsettings node
foreach ($addNode in $config.configurations.appsettings.setting) {
# in order to allow for multi-valued values for the Appsettings keys but still work for a Regular expression that contains a comma i.e. d{3,5}, an exception is made here for the filter Value
# if multiple filter strings are required, this code will need to be amended appropriately
 if ($addNode.Value.Contains(‘,’) -and ($addNode.key -ne ‘filter’)) {
  $value = $addNode.Value.Split(‘,’)
  for ($i = 0; $i -lt $value.length; $i++) {
   $value[$i] = $value[$i].Trim() 
  }
 }
 else {
   $value = $addNode.Value
 }
 
 $global:appSettings[$addNode.Key] = $value
 }

#management node
foreach ($addNode in $config.configurations.management.component) {
 if ($addNode.Value.Contains(‘,’)) {
  $value = $addNode.Value.Split(‘,’)
  for ($i = 0; $i -lt $value.length; $i++) {
    $value[$i] = $value[$i].Trim() 
  }
 }
 else {
   $value = $addNode.Value
 }
 $global:management[$addNode.Key] = $value
}
#logging node
foreach ($addNode in $config.configurations.logging.log) {
 if ($addNode.Value.Contains(‘,’)) {
  $value = $addNode.Value.Split(‘,’)
  for ($i = 0; $i -lt $value.length; $i++) {
    $value[$i] = $value[$i].Trim() 
  }
 }
 else {
   $value = $addNode.Value
 }
 $global:logging[$addNode.Key] = $value
}
#alerts node
foreach ($addNode in $config.configurations.alerts.alert) {
 if ($addNode.Value.Contains(‘,’)) {
  $value = $addNode.Value.Split(‘,’)
  for ($i = 0; $i -lt $value.length; $i++) {
    $value[$i] = $value[$i].Trim() 
  }
 }
 else {
   $value = $addNode.Value
 }
 $global:alerts[$addNode.Key] = $value
}
#combine all global configuration nodes into a single variable for ease of use
$global:allsettings = $global:appSettings + $global:management  + $global:logging + $global:alerts