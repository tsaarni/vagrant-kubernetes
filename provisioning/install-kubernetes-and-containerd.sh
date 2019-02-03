#!/bin/bash -ex
#
# Install kubernetes with containerd
#
# References
# * https://kubernetes.io/blog/2017/11/containerd-container-runtime-options-kubernetes
# * https://github.com/containerd/cri/blob/master/docs/installation.md
# * https://kubernetes.io/docs/setup/independent/install-kubeadm/
# * https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
#

# configure repos
curl -fsSl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update

# install dependencies
apt-get install -y conntrack

# enable ip forwarding
sysctl -w net.ipv4.ip_forward=1
sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.conf

# install containerd
#containerd_release_version=$(curl -s https://storage.googleapis.com/cri-containerd-release/latest)
containerd_release_version=1.1.0-rc.0
curl -fsSl https://storage.googleapis.com/cri-containerd-release/cri-containerd-${containerd_release_version}.linux-amd64.tar.gz > /tmp/cri-containerd.tar.gz
tar xvf /tmp/cri-containerd.tar.gz -C /
systemctl enable containerd
systemctl start containerd

# install kubernetes
kubernetes_version=$(apt-cache madison kubelet | grep 1.12 | head -1 | awk '{print $3}')
kubernetes_cni_version=$(apt-cache madison kubernetes-cni | grep 0.6 | head -1 | awk '{print $3}')
apt-get install -y kubeadm=$kubernetes_version kubelet=$kubernetes_version kubectl=$kubernetes_version kubernetes-cni=$kubernetes_cni_version

# configure kubelet to be used with containerd
cat > /etc/systemd/system/kubelet.service.d/0-containerd.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF
systemctl daemon-reload

# intialize kubernetes master
#   --skip-preflight-checks is needed since kubeadm checks for existence of docker
#   --apiserver-cert-extra-sans is needed since we want to use kubectl with virtualbox NAT port forward
kubeadm init --ignore-preflight-errors=all --apiserver-cert-extra-sans 127.0.0.1

export KUBECONFIG=/etc/kubernetes/admin.conf

# install CNI networking plugin
kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml

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