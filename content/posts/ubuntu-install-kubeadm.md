---
title: "ubuntu安装kubeadm"
date: 2019-06-05
draft: false
tags: ["linux","kubeadm"]
---

# kubeadm查看需要镜像列表
```
kubeadm config images list

k8s.gcr.io/kube-apiserver:v1.14.2
k8s.gcr.io/kube-controller-manager:v1.14.2
k8s.gcr.io/kube-scheduler:v1.14.2
k8s.gcr.io/kube-proxy:v1.14.2
k8s.gcr.io/pause:3.1  # 作为容器运行，启动命名空间作用
k8s.gcr.io/etcd:3.3.10
k8s.gcr.io/coredns:1.3.1
```

<!--more-->

# ubuntu安装docker
kubernetes为了运行Pod中的container，需要安装Container Runtime。

需要先安装docker。
```
# Install Docker CE
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
apt-get update && apt-get install apt-transport-https ca-certificates curl software-properties-common

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add Docker apt repository.
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install Docker CE.
apt-get update && apt-get install docker-ce=18.06.2~ce~3-0~ubuntu

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
```
# ubuntu安装kubeadm和kubelet和kubectl

## 配置kubernetes源,更新系统
```
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
 
sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
 
sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF
 
sudo apt-get update
```
## 安装软件并且保证组件不更新
```
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet && sudo systemctl start kubelet
```
## 查看需要的镜像
    kubeadm config images list

## 查看默认的kubeadm配置

    kubeadm config print init-defaults

