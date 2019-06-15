---
title: "Assign Memory Resources to Containers and Pods"
date: 2019-06-15
draft: false
tags: ["kubernetes","memory"]
---

# 创建namespace
    kubectl create namespace mem-example
# 添加内存请求和内存限制

`resource requests`表示最小资源需求 `resource limit`表示资源需求上限。

创建memory-demo.yaml文件
```
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```
`args`表示Containers启动时提供的参数。`"--vm-bytes", "150M"`申请150M内存资源。

创建Pod

    kubectl apply -f memory-demo.yaml -n mem-example
看一下Pod状态

    kubectl get po -n mem-example

查看一下yaml描述文件

    kubectl get po memory-demo --output=yaml -n mem-example

    ···
    resources:
      limits:
        memory: 200Mi
      requests:
        memory: 100Mi
    ···

查看一下Pod的资源占用指标

    kubectl top po memory-demo -n mem-example

    NAME          CPU(cores)   MEMORY(bytes)   
    memory-demo   129m         150Mi 


# 参考文献
https://stackoverflow.com/questions/53954995/kubernetes-metrics-server-error-from-server-serviceunavailable-the-server-is

https://github.com/kubernetes-incubator/metrics-server/issues/45

https://github.com/kubernetes-incubator/metrics-server/issues/188