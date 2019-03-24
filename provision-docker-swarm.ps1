param(
    [string]$ip,
    [string]$firstNodeIp
)

$taskName = 'provision-docker-swarm-prepare-network'
$transcriptPath = "C:\tmp\$taskName.log"

Write-Output 'Scheduled Task output:'
Get-Content -ErrorAction SilentlyContinue $transcriptPath
Remove-Item $transcriptPath

Write-Host 'Creating the firewall rule to allow inbound TCP/IP access to the Docker Engine Swarm port 2377...'
New-NetFirewallRule `
    -Name 'Docker-Engine-Swarm-In-TCP' `
    -DisplayName 'Docker Engine Swarm (TCP-In)' `
    -Direction Inbound `
    -Enabled True `
    -Protocol TCP `
    -LocalPort 2377 `
    | Out-Null

Write-Title 'Current IP Addresses'
Get-NetIPAddress | Sort-Object -Property InterfaceAlias | Format-Table -Property InterfaceAlias,IPAddress

# if this is the first node, init the swarm, otherwise, join it.
if ($ip -eq $firstNodeIp) {
    # remove previous join tokens (in case they exist).
    Remove-Item -ErrorAction SilentlyContinue -Force C:\vagrant\shared\docker-swarm-join-token-*

    # init the swarm.
    # NB this will create the ingress overlay network connected to the created vEthernet (Ethernet 3) vSwitch.
    Write-Host 'Initializing the docker swarm...'
    docker swarm init `
        --data-path-addr $ip `
        --listen-addr "$($ip):2377" `
        --advertise-addr "$($ip):2377"

    # save the swarm join tokens into the shared folder.
    mkdir -Force C:\vagrant\shared | Out-Null
    docker swarm join-token manager -q | Out-File C:\vagrant\shared\docker-swarm-join-token-manager.txt -Encoding ascii
    docker swarm join-token worker -q | Out-File C:\vagrant\shared\docker-swarm-join-token-worker.txt -Encoding ascii
} else {
    # join the swarm as a manager.
    Write-Host 'Joining the docker swarm...'
    docker swarm join `
        --token (Get-Content C:\vagrant\shared\docker-swarm-join-token-manager.txt) `
        --data-path-addr $ip `
        --listen-addr "$($ip):2377" `
        --advertise-addr "$($ip):2377" `
        "$($firstNodeIp):2377"
}

# kick the tires.
docker version
docker info
docker network ls
docker node ls
#docker node inspect self
