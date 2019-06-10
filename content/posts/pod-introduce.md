---
title: "Pod基本概念介绍"
date: 2019-06-05
draft: false
tags: ["kubernetes","Pod"]
---

# Pod的设计

控制器模式：

    一种API对象（Deployment）管理另外一种API对象（Pod)的方式
    Deployment扮演者Pod的控制器的角色

Metadata字段是API的标识。
    
    Labels就是一组Key-Value字段，从kubernetes中过滤去被控制对象。

<!--more-->