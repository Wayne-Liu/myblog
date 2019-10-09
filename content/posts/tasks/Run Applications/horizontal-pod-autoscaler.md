---
title: "HPApod自动伸缩"
date: 2019-10-08
draft: false
tags: ["kubernetes", "hpa"]
---

# Pod自动伸缩

HPA能根据负载的CPU使用量自动的增减RC，deployment，replica的数量，也可以基于custom指标或者其他根据应用定义的指标。HPA不能对有状态的应用自动伸缩，比如DaemonSet。

HPA是k8s定义的一种资源类型，有资源定义控制器的行为，控制器根据用户定义的CPU使用量的期望值来调整RC或者deployment的副本数。

![HPA](../../img/hpa.jpg)

HPA通过循环控制来实现，通过controller manager的`--horizontal-pod-autoscaler-sync-period`参数调整循环时间，默认值是15秒。

每隔一段时间，controller manager查询资源的实际使用量来和HorizontalPodAutoscaler定义的指标比对，controller manager通过资源指标API或者客户定义指标API获取定义指标。

    对于每一个pod资源定义例如CPU，通过HorizontalPodAutoscaler标识的需要指标的pod，控制器从资源指标API中获取指标。如果设置了目标原始值，则直接使用原始指标值。然后控制器将所有目标pod的使用率或者原始值（取决于制定的目标类型）取平均值，并产生一个用于缩放所需副本数量的比率。

请注意如果pod的容器没有设定目标值，CPU使用率不会被定义，自动伸缩不会生效。

    对于单个pod自定义指标，控制器的功能类似于按单价资源指标，不同之处在于它适用于原始值而非利用率值。
    对于对象指标或者外部指标，将获取单个指标，该指标描述了所讨论的对象。该指标与目标值进行对比，产生上述比率。在autoscaling/v2beta2API版本中，可以选择在进行比较之前将该值除以pod的数量。

HorizontalPodAutoscaler 通常从一系列聚合的API（metrics.k8s.io, custom.metrics.k8s.io和 external.metrics.k8s.io）中获取指标，metrics.k8s.io API通常由metics-server提供，需要单独启动。有关说明请参见metrics-server。

## 算法详情

HPA最基本的功能是控制器以所需度量值与当前度量值之间的比率运行：

所需副本数 = 单元[当前副本数 * （当前度量值 / 所需度量值）]

例如，如果当前指标是200m，所需指标是100m，则副本数会增加一倍，因为200/100==2.0如果当前值是50m,副本数量会减半,因为50.0/100.0 == 0.5. 如果比例足够接近1.0(在全局可配置公差范围内 --horizontal-pod-autoscaler-tolerance参数,默认是0.1)我们将跳过缩放.

当指定了targetAverageValue或targetAverageUtilization时，currentMetricValue的计算方法是对HorizontalPodAutoscaler缩放目标中所有Pod的给定指标取平均值。 但是，在检查公差并确定最终值之前，我们会考虑pod准备情况和缺少的指标。

设置了删除时间戳记的所有Pod（即处于关闭状态的Pod）和所有失败的Pod将被丢弃。

如果特定Pod缺少指标，则将其保留以备后用； 缺少指标的Pod将用于调整最终缩放比例。

在CPU上扩展时，如果尚未准备好任何Pod（即它仍在初始化），或者Pod的最新度量值是在准备就绪之前，那么该Pod也将被保留。

由于技术限制，在确定是否预留某些CPU指标时，Horizo​​ntalPodAutoscaler控制器无法准确确定Pod第一次准备就绪。取而代之的是，如果Pod尚未就绪，并且在启动后的短短可配置时间内过渡为就绪，则认为Pod尚未就绪。使用--horizo​​ntal-pod-autoscaler-initial-readiness-delay参数配置此值，其默认值为30秒。Pod准备就绪后，如果它在自启动以来的较长的可配置时间内发生，则将任何准备就绪的转换视为第一次。使用--horizo​​ntal-pod-autoscaler-cpu-initialization-period标志配置此值，其默认值为5分钟。

然后，使用未预留或未从上方丢弃的其余Pod计算currentMetricValue / desireMetricValue基本比例比率。

如果有任何缺失的指标，我们会更保守地重新计算平均值，假设在缩小的情况下，这些Pods消耗了期望值的100％，在放大的情况下消耗了0％。这抑制了任何潜在标度的大小。

此外，如果存在任何尚未准备就绪的pods，并且我们会在不考虑缺少指标或尚未准备就绪的pods的情况下进行扩展，则可以保守地假设尚未准备就绪的pods正在消耗所需指标的0％ ，进一步抑制放大的幅度。

在考虑尚未准备就绪的pods和缺少的指标后，我们重新计算使用率。如果新比例颠倒了缩放方向，或者在公差范围内，我们将跳过缩放。否则，我们将使用新比例进行缩放。

请注意，即使使用新的使用率，平均利用率的原始值也会通过Horizo​​ntalPodAutoscaler状态报告回来，而不会考虑尚未准备就绪的pods或缺少的度量标准。

如果在Horizo​​ntalPodAutoscaler中指定了多个指标，则将对每个指标进行此计算，然后选择所需副本数中的最大值。如果这些指标中的任何一个都不能转换为所需的副本计数（例如，由于从指标API提取指标时出错），并且可以获取的指标建议按比例缩小，则跳过按比例缩小。这意味着，如果一个或多个度量提供的期望重复数大于当前值，则HPA仍能够进行扩展。

最后，在HPA缩放目标之前，就记录了缩放建议。控制器考虑可配置窗口中的所有建议，从该窗口中选择最高建议。可以使用--horizo​​ntal-pod-autoscaler-downscale-stabilization标志（默认为5分钟）来配置此值。这意味着缩减将逐渐发生，以消除快速波动的度量值的影响。