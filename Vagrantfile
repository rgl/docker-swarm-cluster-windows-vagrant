# to make sure the master node is created before the other nodes, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

require 'ipaddr'

number_of_nodes = 3
first_node_ip = '10.10.1.201'
node_ip_addr = IPAddr.new first_node_ip

Vagrant.configure('2') do |config|
  config.vm.box = 'windows-2019-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    # lv.nested = true
    lv.keymap = 'pt'
    lv.random :model => 'random'
    # replace the default synced_folder with something that works in the base box.
    # NB for some reason, this does not work when placed in the base box Vagrantfile.
    config.vm.synced_folder '.', '/vagrant', type: 'smb', smb_username: ENV['USER'], smb_password: ENV['VAGRANT_SMB_PASSWORD']
  end

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
  end

  (1..number_of_nodes).each do |n|
    name = "dw#{n}"
    fqdn = "#{name}.example.com"
    ip = node_ip_addr.to_s; node_ip_addr = node_ip_addr.succ

    config.vm.define name do |config|
      config.vm.hostname = name
      config.vm.network :private_network, ip: ip, libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
      config.vm.provision :shell, inline: "$env:chocolateyVersion='0.10.13'; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex", name: "Install Chocolatey"
      config.vm.provision :shell, path: 'ps.ps1', args: 'provision-containers-feature.ps1'
      config.vm.provision "shell", inline: "echo 'Rebooting...'", reboot: true
      config.vm.provision :shell, path: 'ps.ps1', args: 'provision-base.ps1'
      config.vm.provision :shell, path: 'ps.ps1', args: 'provision-docker-ce.ps1'
      # config.vm.provision :shell, path: 'ps.ps1', args: 'provision-docker-ee.ps1'
      config.vm.provision :shell, path: 'ps.ps1', args: 'provision-docker-reg.ps1'
      config.vm.provision :shell, path: 'provision-docker-swarm-prepare-network.ps1', reboot: true
      config.vm.provision :shell, path: 'ps.ps1', args: ['provision-docker-swarm.ps1', ip, first_node_ip]
    end
  end
end
