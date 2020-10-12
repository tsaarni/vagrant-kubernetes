#!/bin/bash -ex
#
# Install kubernetes with containerd
#
# References
# * https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#

# configure repos
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable > /etc/apt/sources.list.d/docker.list

curl -fsSl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update

# install dependencies
apt-get install -y conntrack

# disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab


# prerequisites
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# install containerd
apt-get install -y containerd.io

# configure containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's!systemd_cgroup = false!systemd_cgroup = true!g' /etc/containerd/config.toml
systemctl restart containerd

# install kubernetes
kubernetes_version=1.19
kubernetes_deb_version=$(apt-cache madison kubelet | grep $kubernetes_version | head -1 | awk '{print $3}')
apt-get install -y kubeadm=$kubernetes_deb_version kubelet=$kubernetes_deb_version kubectl=$kubernetes_deb_version

# intialize kubernetes master
kubeadm init --config /vagrant/configs/kubeadm-config.yaml

export KUBECONFIG=/etc/kubernetes/admin.conf

# install CNI networking plugin
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/manifests/calico.yaml

# allow scheduling of pods on master node
kubectl taint nodes --all node-role.kubernetes.io/master-

# make kubernetes admin.conf available for host machine and for vagrant-user
cp /etc/kubernetes/admin.conf /vagrant
mkdir ~vagrant/.kube
cp /etc/kubernetes/admin.conf ~vagrant/.kube/config
chown -R vagrant:vagrant ~vagrant/.kube

# replace internal kubernetes api server address with localhost, so it can be accessed via virtualbox port forward
sed -i 's!server: .*!server: https://127.0.0.1:6443!g' /vagrant/admin.conf

# wait for the node to come up
set +x  # disable bash trace
while true; do
    status=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes -o jsonpath='{.items[*].status.conditions[?($.status == "True")].status}')
    if [[ $status == "True" ]]; then
        break
    fi
    echo "Running 'kubectl get nodes' and waiting for the nodes to come up..."
    sleep 3
done
set -x
