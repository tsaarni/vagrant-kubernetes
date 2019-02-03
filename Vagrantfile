# -*- mode: ruby -*-

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest: 6443, host: 6443, host_ip: "127.0.0.1" # kubernetes
  config.vm.network "forwarded_port", guest: 2375, host: 2375, host_ip: "127.0.0.1" # docker

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048  # 2GB is the minimum amount of memory for master
    v.cpus = 2       # 2 vCPUs is the minimum number of CPUs for master
  end

  config.vm.provision "shell", path: "provisioning/install-kubernetes-and-docker.sh"
  #config.vm.provision "shell", path: "provisioning/install-kubernetes-and-containerd.sh"
  config.vm.provision "shell", path: "provisioning/install-additions.sh"

end
