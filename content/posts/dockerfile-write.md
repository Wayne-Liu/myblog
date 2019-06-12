---
title: "编写Dockerfile的规范"
date: 2019-06-12
draft: false
tags: ["linux","Dockerfile"]
---

# Dcokerfile样例

```
FROM store/oracle/serverjre:8

RUN yum install -y zlib-devel bzip2-devel openssl-devel \
    ncurses-devel gcc perl-ExtUtils-MakeMaker package \


ADD git-2.9.0.tar.gz apache-maven-3.6.1-bin.tar.gz /usr/share

RUN ln -s /usr/share/apache-maven-3.6.1/bin/mvn /usr/bin/mvn && \
    cd /usr/share/git-2.9.0 && make prefix=/usr/local all && make prefix=/usr/local install

```

`store/oracle/serverjre:8` 镜像是oracle Jdk的官方镜像，在Docker Hub搜到后需要点击右边`Proceed to Checkout`按钮，填写注册信息后，才能允许下载，需要先用Docker Hub账号登录。

    在本地docker client端登录
    # docker login
    Username: <docker>
    Password: <docker>
    Login successful.

    然后执行
    docker pull store/oracle/serverjre:8

ADD 命令会讲压缩包传输到制定位置，并且自动解压。

执行Make命令编译git程序并且安装到制定目录。

