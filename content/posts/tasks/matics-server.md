---
title: "kubernetes安装matics server"
date: 2019-06-15
draft: false
tags: ["kubernetes", "mastics"]
---

# Metrics Server安装

下载部署的yaml文件，
https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy/1.8%2B

修改matrics-server-deployment.yaml文件,在deployment的containers目录下添加command命令。
```
    containers:
    - name: metrics-server
    image: k8s.gcr.io/metrics-server-amd64:v0.3.3
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: tmp-dir
        mountPath: /tmp
    command:    #后面为添加内容
    - /metrics-server
    - --kubelet-insecure-tls #访问跳过证书认证
    - --kubelet-preferred-address-types=InternalIP #使用api可以通过coreDNS访问Node节点端口
```
<!--more-->

验证Metrics Server,报错如下

    kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
    Error from server (ServiceUnavailable): the server is currently unable to handle the request

## 添加Metrics Server的IP到kube-apiserver.yaml的no_proxy中

SOLUTION (if you are behind Corporate Proxy) Kube apiserver使用代理的方式：

获取Cluster-IP 

    kubectl get services -n kube-system
添加Cluster-IP到/etc/kubernetes/manifests/kube-apiserver.yaml的no-proxy变量中

    - name: no_proxy
      value: localhost,172.16.0.0/16,192.168.0.0/16.,127.0.0.1,10.10.0.0/16,10.109.35.40
重启kubelet

    systemctl daemon-reload && systemctl restart kubelet
验证是否生效

    kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"

    kubectl get apiservice
    #结果包含：
    v1beta1.metrics.k8s.io                 kube-system/metrics-server   True

# 参考文献
https://stackoverflow.com/questions/53954995/kubernetes-metrics-server-error-from-server-serviceunavailable-the-server-is

https://github.com/kubernetes-incubator/metrics-server/issues/45

https://github.com/kubernetes-incubator/metrics-server/issues/188