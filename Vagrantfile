# -*- mode: ruby -*-

Vagrant.configure("2") do |config|

  # bento project https://github.com/chef/bento
  # publishes images with working vbox guest additions
  config.vm.box = "bento/ubuntu-16.04"

  config.vm.network "forwarded_port", guest: 6443, host: 6443, host_ip: "127.0.0.1" # kubernetes
  config.vm.network "forwarded_port", guest: 2375, host: 2375, host_ip: "127.0.0.1" # docker
  config.vm.network "private_network", ip: "192.168.195.15" # vbox host-only network

  # for virtualbox
  # export VAGRANT_DEFAULT_PROVIDER=virtualbox
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048  # 2GB is the minimum amount of memory for master
    v.cpus = 2       # 2 vCPUs is the minimum number of CPUs for master
  end

  # for qemu
  # export VAGRANT_DEFAULT_PROVIDER=libvirt
  #config.vm.provider "libvirt" do |v|
  #  v.memory = 2048
  #  v.cpus = 2
  #  config.vm.synced_folder './', '/vagrant', type: '9p', disabled: false
  #end


  config.vm.provision "shell", path: "provisioning/install-kubernetes-and-docker.sh"
  #config.vm.provision "shell", path: "provisioning/install-kubernetes-and-containerd.sh"
  config.vm.provision "shell", path: "provisioning/install-additions.sh"
  #config.vm.provision "shell", path: "provisioning/external-exposure.sh"
end
