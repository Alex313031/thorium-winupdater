Write-Output "Creating scheduled task for Thorium WinUpdater..."
$Title = "Thorium WinUpdater"
$Host.UI.RawUI.WindowTitle = $Title
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Output "Requesting administrator privileges"
  $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $UserName = [Environment]::UserName
  $Script = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs "-ExecutionPolicy RemoteSigned -File `"$PSCommandPath`" `"${User}`" `"${UserName}`""
  Exit
}

$Action   = New-ScheduledTaskAction -Execute "Thorium-WinUpdater.exe" -Argument "/Scheduled" -WorkingDirectory "$PSScriptRoot"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
$Paramswin7  = @{
"Once"  = $true
"At" = (Get-Date -Minute 0 -Second 0).AddHours(1)
"RepetitionInterval" = (New-TimeSpan -Hours 24) 
"RepetitionDuration" = ([TimeSpan]::MaxValue)
}
$Paramswin10  = @{
"Once"  = $true
"At" = (Get-Date -Minute 0 -Second 0).AddHours(1)
"RepetitionInterval" = (New-TimeSpan -Hours 24)
}
if([environment]::OSVersion.Version.Major -le 6) {$Params = $Paramswin7}
if([environment]::OSVersion.Version.Major -eq 10) {$Params = $Paramswin10}

$24Hours = New-ScheduledTaskTrigger @Params
$AtLogon  = New-ScheduledTaskTrigger -AtLogOn
if ([environment]::OSVersion.Version.Major -le 6) {
$AtLogon.RandomDelay = New-TimeSpan -Minutes 1
} else {
$AtLogon.Delay = 'PT1M'
}
$User     = If ($Args[0]) {$Args[0]} Else {[System.Security.Principal.WindowsIdentity]::GetCurrent().Name}
$UserName = If ($Args[1]) {$Args[1]} Else {[Environment]::UserName}

Register-ScheduledTask -TaskName "$Title ($UserName)" -Action $Action -Settings $Settings -Trigger $24Hours,$AtLogon -User $User -RunLevel Highest -Force
Write-Output "Done. Press any key to close this window."
[Console]::ReadKey()
