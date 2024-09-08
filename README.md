# h3c-cas-infracode

Simple Infrastructure as Code scripts for H3C CAS system virtual machine deployment.

本方案参考了 [VMware vSphere 系统虚拟机自动化部署](https://segmentfault.com/a/1190000042686820)，不同的是采用 Shell 脚本执行 [HTTPie](https://httpie.io/) 命令来调用 H3C CAS RESTFul Web Services API。

## 操作流程

首先执行：

```
./cas-clitool.sh template_list
```

确定模版的的 `id` 和 `name`，参考 `vm-config/vm-config.cfg.template` 文件编辑虚拟机的配置文件，然后执行如下命令部署虚拟机：

```
./cas-delpoy.sh vm-config/vm-name.cfg
```

等待几分钟，虚拟机制备完毕后通过如下命令获得虚拟机的 `id`：

```
./cas-clitool.sh vm_find_id <name>
```

然后通过如下命令启动虚拟机：

```
./cas-clitool.sh vm_start <id>
```

虚拟机第一次启动后，需要等待几分钟才能把初始化的配置做完，然后就可以正常使用了。

## 模版制备

### Linux 

- CAS 管理界面中增加虚拟机。
	- 显示名称建议按照操作系统及版本命名，例如 centos7。
	- 硬件信息中，磁盘的存储池和网络的虚拟交换机一定要根据系统情况配置。
	- 光驱要选择正确的操作系统镜像文件。
- 操作系统安装
	- 启用网络但不要修改配置。
	- 分区需要根据需求调整。
	- Ubuntu 系统时区需要安装后如下命令调整：
		- `sudo timedatectl set-timezone Asia/Shanghai`
- 操作系统安装完毕后需要安装 CAStools。
	- 多数发行版都需要安装 `net-tools` 包。
	- 对于 Ubuntu 还需要安装 `libpcre3` 包。
	- 对于 AnolisOS 8 还需要安装 `python39` 包。
	- 修改虚拟机光驱配置，选择 castools.iso 光盘镜像。
	- 在操作系统中执行 `sudo mount /dev/cdrom /media` 命令挂载光盘镜像。
	- `sudo` 执行光盘中安装脚本完成安装。
	- 操作系统中执行 `sudo umount /media` 卸载光驱。
	- 在CAS 管理界面中清理虚拟机光驱配置。
- 清理虚拟机操作系统。
	- CAS 管理界面中修改虚拟机网络配置，手工配置 IP 地址。
	- 上传 `linux-virt-sysprep.sh` 脚本。
	- CAS 管理界面中修改虚拟机网络配置，==将网络恢复到 DHCP 模式==。
	- 通过命令  `sudo ./linux-virt-sysprep.sh` 运行脚本清理系统。
	- ==删除 `linux-virt-sysprep.sh` 脚本。==
	- 执行 `rm -f ~/.bash_history; history -c; exit` 清理命令记录并退出系统。
- 在 CAS 管理界面中安全关闭虚拟机。
- CAS 管理界面中将虚拟机换为模版。
	- 建议模版名称选择 centos7-template 这种形式。
	- 注意正确选择模版存储和所有者。

### Windows

- CAS 管理界面中增加虚拟机。
	- 显示名称建议按照操作系统及版本命名，例如 windows2019。
	- 硬件信息中，磁盘的存储池和网络的虚拟交换机一定要根据系统情况配置。
	- 光驱要选择正确的操作系统镜像文件。
- 操作系统安装
	- 安装 Standard 桌面体验版本。
	- 需要加载 A 盘的全部驱动程序。
- 操作系统安装完毕后需要安装 CAStools。
	- 修改虚拟机光驱配置，选择 castools.iso 光盘镜像。
	- 在操作系统中安装 CAStools。
	- 在CAS 管理界面中清理虚拟机光驱配置。
- 开启远程桌面
	- 选择 开始 => 设置 => 系统 => 远程桌面 => 启用远程桌面。
- 清理虚拟机操作系统。
	- 通过图形界面操作 Sysprep 程序或执行如下命令，并等待系统自动关机。
		- `C:\Windows\System32\Sysprep\sysprep.exe /generalize /shutdown /oobe` 
- CAS 管理界面中将虚拟机换为模版。
	- 建议模版名称选择 windows2019-template 这种形式。
	- 注意正确选择模版存储和所有者。

## 已知问题

### 欧拉安装

openEuler 24.03 LTS 根本无法安装，直接 Kernel Panic 挂掉，22.03版本可以正常安装。

### 龙蜥部署

Anolis 8.9 安装后，CAStools 工作不正常，利用其修改地址后需要重新启动才能生效，所以在通过模版部署系统后，需要重启两次系统，新生成的虚拟机才能正常工作。

### 文档错误

在 Windows 虚拟机模版部署时，需要利用 `sysprep` 来配置系统，必须进行“完全初始化”。但是，在 H3C CAS RESTFul Web Services API 文档“部署虚拟机” 接口的描述中，缺少 `osInfo` 下 `regOrGroup` 参数的内容。只能通过浏览器开发者工具，找到通过模版部署虚拟机时的请求细节，才能发现这参数。请求参数类似如下：

```json
"osInfo": [
    {
        "initType": 1,
        "localgroup": "Administrators",
        "loginAccount": "administrator",
        "loginPassword": "******",
        "pwdConfirm": "******",
        "regOrGroup": "WORKGROUP",
        "regOrGroupType": 2,
        "sysName": "just-test",
        "timezone": 210
    }
],
```

排错时可以查看管理节点调用 sysprep 的日志：

```shell-session
[root@cvknode01 ~]# grep -A 15 sysprep.pyc /var/lib/tomcat8/logs/cas.log
2024-09-07 05:49:36 [ERROR] [Domain Request Processor Manager 4] [com.virtual.plat.server.vm.vmm.SshHostTool::configSysPrep] sysprep execCmd : python /opt/bin/sysprep.pyc  '<sysprep>
    <name>test-49-232</name>
    <hostName>test-49-232</hostName>
    <interface>
        <ip>192.168.19.232</ip>
        <mask>255.255.255.0</mask>
        <mac>0c-da-41-1d-bf-49</mac>
        <gateway>192.168.19.254</gateway>
        <dns>192.168.18.252</dns>
        <dns>192.168.19.252</dns>
    </interface>
    <userName>Administrator</userName>
    <password>******</password>
    <localGroup>Administrators</localGroup>
    <passwdmode>noexpired</passwdmode>
</sysprep>' ; echo $?
...
```

虚拟机宿主机上 sysprep 执行的日志：

```shell-session
[root@cvknode06 ~]# tail -20 /var/log/sysprep.log
2024-09-07 18:11:36,334 INFO/400L/51148: <sysprep>
    <name>test-49-232</name>
    <hostName>test-49-232</hostName>
    <interface>
        <ip>192.168.19.232</ip>
        <mask>255.255.255.0</mask>
        <mac>0c-da-41-1d-31-6c</mac>
        <gateway>192.168.19.254</gateway>
        <dns>192.168.18.252</dns>
        <dns>192.168.19.252</dns>
    </interface>
    <workGroup>WORKGROUP</workGroup>
    <userName>Administrator</userName>
    <password>******</password>
    <localGroup>Administrators</localGroup>
    <enableAutoLogon>false</enableAutoLogon>
    <passwdmode>noexpired</passwdmode>
</sysprep>
2024-09-07 18:11:36,366 INFO/423L/51148: check type: file
2024-09-07 18:11:39,156 INFO/897L/51148: SUCESS
```

