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
<!--more-->
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

# 执行超过内存限制启动命令

```
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-2
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-2-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
```
验证Pod

    kubectl get pod memory-demo-2 --namespace=mem-example

    NAME          READY   STATUS      RESTARTS   AGE
    memory-demo   0/1     OOMKilled   3          83s

    kubectl get po memory-demo -n mem-example -o yaml

    lastState:
      terminated:
        containerID: docker://21a99696eb167a67583974031d51db190daeac103aa33734d3bcbef87bf34c70
        exitCode: 1
        finishedAt: 2019-06-15T07:36:52Z
        reason: OOMKilled

# Memory资源申请大于Node节点资源

```
pods/resource/memory-request-limit-3.yaml 

apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-3
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-3-ctr
    image: polinux/stress
    resources:
      limits:
        memory: "1000Gi"
      requests:
        memory: "1000Gi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```
部署验证结果

    kubectl get pod memory-demo-2 -n mem-example

    NAME            READY   STATUS    RESTARTS   AGE
    memory-demo-2   0/1     Pending   0          29s

    kubectl describe po memory-demo-2 -n mem-example

    Events:
    Type     Reason            Age                     From               Message
    ----     ------            ----                    ----               -------
    Warning  FailedScheduling  2m24s (x25 over 3m40s)  default-scheduler  0/3 nodes are available: 3 Insufficient memory.



# 参考文献

https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

