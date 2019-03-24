param(
    [switch]$RunningAsScheduledTask = $false
)

# because setting up the docker network messes up the vagrant connection
# we have to workaround that with these steps.
#       1. schedule a task to create the network
#       2. disable the winrm service from automatically start
#       3. reboot the machine
#       4. create the network from the scheduled task
#       5. enable the winrm service and reboot the machine

Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host
    Write-Host "ERROR: $_"
    Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}

$taskName = 'provision-docker-swarm-prepare-network'
$transcriptPath = "C:\tmp\$taskName.log"

if ($RunningAsScheduledTask) {
    Start-Transcript $transcriptPath

    # create a first network to prevent docker swarm init from using the vagrant nat interface.
    # NB docker swarm init (or something down that rabbit hole) will use the first interface that is not yet attached to a vSwitch.
    # NB to use a specific interface we could also use -o "com.docker.network.windowsshim.interface=Ethernet 2"
    Write-Host 'Creating the vagrant docker network...'
    docker network create `
        -d transparent `
        vagrant

    Write-Host 'Unregistering Scheduled Task...'
    Unregister-ScheduledTask `
        -TaskName $taskName `
        -Confirm:$false

    Write-Host 'Enabling the WinRM service...'
    $result = sc.exe config WinRM start= auto
    if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
        throw "sc.exe config failed with $result"
    }
    Start-Service -Name WinRM
} else {
    Write-Host "Registering the Scheduled Task $taskName to run $PSCommandPath..."
    $action = New-ScheduledTaskAction `
        -Execute 'PowerShell.exe' `
        -Argument "-NoProfile -ExecutionPolicy Bypass $PSCommandPath -RunningAsScheduledTask"
    $trigger = New-ScheduledTaskTrigger `
        -AtStartup `
        -RandomDelay 00:00:15
    Register-ScheduledTask `
        -TaskName $taskName `
        -Trigger $trigger `
        -Action $action `
        -User 'SYSTEM' `
        | Out-Null
    Write-Host 'Disabling the WinRM service...'
    Set-Service -Name WinRM -StartupType Disabled
}
