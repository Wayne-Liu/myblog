---
title: "centos7安装kvm并安装ubuntu"
date: 2019-06-03
draft: false
tags: ["linux","kvm"]
---

# 检查是否支持kvm
```
cat /proc/cpuinfo | egrep 'vmx|svm'

flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb cat_l3 cdp_l3 intel_ppin intel_pt tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm rdt_a rdseed adx smap xsaveopt cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local dtherm ida arat pln pts
```
关闭selinux 将/etc/sysconfig/selinux中的 SELinux=enforcing修改为SELinux=disabled

```
vi /etc/sysconfig/selinux
```
# 安装 KVM 环境
通过 yum 安装 kvm 基础包和管理工具 kvm相关安装包及其作用:

    qemu-kvm 主要的KVM程序包
    python-virtinst 创建虚拟机所需要的命令行工具和程序库
    virt-manager GUI虚拟机管理工具
    virt-top 虚拟机统计命令
    virt-viewer GUI连接程序，连接到已配置好的虚拟机
    libvirt C语言工具包，提供libvirt服务
    libvirt-client 为虚拟客户机提供的C语言工具包
    virt-install 基于libvirt服务的虚拟机创建命令
    bridge-utils 创建和管理桥接设备的工具
```
# 配置yum源
cd /etc/yum.repos.d/
mkdir bak
mv CentOS-Base.repo bak/
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
# 安装 kvm 
# ------------------------
# yum -y install qemu-kvm python-virtinst libvirt libvirt-python virt-manager libguestfs-tools bridge-utils virt-install
 
yum -y install qemu-kvm libvirt virt-install bridge-utils 
 
# 重启宿主机，以便加载 kvm 模块
# ------------------------
reboot
 
# 查看KVM模块是否被正确加载
# ------------------------
lsmod | grep kvm
 
kvm_intel             162153  0
kvm                   525259  1 kvm_intel
 
```
开启kvm服务，并且设置其开机自动启动 

```
systemctl start libvirtd
systemctl enable libvirtd
```
查看状态操作结果，如Active: active (running)，说明运行情况良好 

```
systemctl status libvirtd
systemctl is-enabled libvirtd
 
● libvirtd.service - Virtualization daemon
   Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
   Active: active (running) since 二 2001-01-02 11:29:53 CST; 1h 41min ago
     Docs: man:libvirtd(8)
           http://libvirt.org
```

# 配置网卡（桥接模式）
```
ifconfig
#查看网卡。记住前地址的网卡名如eno1
eno1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.110.25.103  netmask 255.255.255.0  broadcast 10.110.25.255
        inet6 fe80::c56:643c:7fdd:8c26  prefixlen 64  scopeid 0x20<link>
        ether 6c:92:bf:74:40:0a  txqueuelen 1000  (Ethernet)
        RX packets 54703323  bytes 40077305479 (37.3 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 47351690  bytes 25724616215 (23.9 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device memory 0xc7020000-c703ffff
#备份
cd /etc/sysconfig/network-scripts/
mkdir bak
cp ifcfg-eno1 bak/
#编辑网桥配置
vi ifcfg-br0
#ip netmask等来自于ifcfg-eno1
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=br0
UUID=242b3d4d-37a5-4f46-b072-55554c185ecf
DEVICE=br0
ONBOOT=yes
TYPE=bridge
PREFIX=24
IPADDR=10.110.25.104 #宿主机ip
NETMASK=255.255.255.0
GATEWAY=10.110.25.254
DNS1=223.5.5.5
#编辑网卡
vi ifcfg-eno1
#在文件最后追加
BRIDGE=br0
#激活网卡
ifup eno1
#激活网桥
ifup br0
#重启网络
service network restart
#查看是否生效 可以看到br0网卡，地址为之前eno1的地址即为生效
ifconfig
br0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.110.25.103  netmask 255.255.255.0  broadcast 10.110.25.255
        inet6 fe80::6e92:bfff:fe74:400a  prefixlen 64  scopeid 0x20<link>
        ether 6c:92:bf:74:40:0a  txqueuelen 1000  (Ethernet)
        RX packets 7064  bytes 5688983 (5.4 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5834  bytes 2240978 (2.1 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
 ```
 # 安装虚拟机
 ```
 #下载镜像
mkdir /home/kvm
wget -O /home/kvm/ubuntu-18.04.1-server-amd64.iso http://101.110.118.67/cdimage.ubuntu.com/releases/18.04.1/release/ubuntu-18.04.1-server-amd64.iso
#安装
virt-install --virt-type=kvm --name=icp-103-183 --vcpus=8 --memory=65536 --cdrom /home/kvm/ubuntu-18.04.1-server-amd64.iso --disk path=/home/kvm/icp-103-183.qcow2,size=300,format=qcow2 --network bridge=br0   --force --vnc --vncport=5910 --vnclisten=0.0.0.0
 
下载vnc viewer
进入vnc viewer连接到虚拟机
file->new connection
 vnc server为10.110.25.103:5910(宿主机ip:virt-install时设定的vncport) 

 select a language : English
select your location : other->asia->china->United States
configure the keyboard : no -> Englis(US) -> Englis(US)
configure the network : configure network manually
ip : 10.110.25.183
netmask : 255.255.255.0 (与br0网卡对应)
gateway : 10.110.25.254 (与br0网卡对应)
name server addresses : 10.100.1.58(dns 8.8.8.8)
hostname : icp-103-183 (机器名)
domain name : （空）
full name : icp
username : icp
password : ********
Partition disks : guided - use entire disk and set up LVM
select disk to partition: SCSI1（默认）-> yes ->yes -> continue -> finish partitioning and write changes to disk -> yes
HTTP proxy : (空)
configuring tasksel : no automatic updates
software selection : openssh server(根据需求。按空格选定 回车继续)
install grub boot : yes
finish the installation : continue
在终端中 ssh icp@10.110.25.183输入密码 登陆成功

 ```
# 修改dns：
```
 
sudo vim /etc/netplan/01-netcfg.yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
version: 2
renderer: networkd
ethernets:
ens3:
addresses: [ 10.110.25.183/24 ]
gateway4: 10.110.25.254
nameservers:
addresses:
- "10.100.1.58"

# 修改namespace
 
sudo netplan apply
```
# 修改镜像源
```
sudo vim /etc/apt/sources.list
#内容修改为如下
deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
sudo apt-get update
```
# 修改root密码，以root登陆
```
sudo passwd root
```
# 添加网卡
```
virsh attach-interface icp-104-186 --type bridge --source br1#开机情况下（临时）
virsh attach-interface icp-104-186 --type bridge --source br1 --config #直接添加到xml 需要重新define
virsh domiflist icp-104-186 #查看
```
# 设置开机启动
```
virsh autostart icp-103-183 
```