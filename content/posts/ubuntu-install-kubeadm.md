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


