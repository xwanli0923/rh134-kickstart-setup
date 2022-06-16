# rh134-kickstart-setup

#### 介绍
For Red Hat Enterprise Linux 8  RH134 (Red Hat System Administration II) Chapter 12

#### 软件架构
X86_64


#### 课程版本
RH134-RHEL8
#### 安装教程

1.  将课程切换到`RH134`或者`RH199`
2.  重置 `servera` 节点
3.  将 `lab-pxekickstart.tar.gz` 复制到 `servera` 并使用脚本 `deploy-pxe-server.sh` 部署服务
4.  在 `foundation0` 使用 `root` 账户运行 `virsh-install-serverc.sh` 脚本

#### 使用说明

1.  重置 `servera`
```bash
$ rht-vmctl reset servera
```
2.  将 `lab-pxekickstart.tar.gz` 复制到`servera`
```bash
cd rh134-kickstart-setup/
scp lab-pxekickstart.tar.gz root@servera:~
```
3. 在 `servera` 部署服务器
```bash
tar -xf lab-pxekickstart.tar.gz
cd lab-pxekickstart/
./deploy-pxe-server.sh
```
4. 回退到 `foundation`,创建新的虚拟机`serverc`
 ```bash
 # 执行 virt-install-server*.sh 之前，请删除目录下的`.git`
 ./virt-install-serverc.sh
 ```
 在打开的 `console` 中，选择 **Install serverc.lab.example.com**

#### 作者
**邢万里 | Augus_Hsing**
**Email**: <a href="mailto:wanly0923@qq.com">wanly0923@qq.com</a>
