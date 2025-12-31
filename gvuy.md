# GV.UY VPS 部署 ICMP9 节点指南 (IPv6 Only 模式)

> ⚠️ **警告：高风险操作**
>
> 在执行以下操作前，请务必确认你正在使用 **IPv6 地址** 或 **VNC 控制台** 连接服务器。
> 因为我们将禁用 IPv4，一旦重启网络，**原本的 IPv4 SSH 连接会立即断开且无法恢复**。

---

## 第一步：核对IPv6地址是否一致

在VPS上执行以下命令，记录下返回的IPv6地址

```bash
curl ip.sb -6
```

**核对记录的IPv6地址**
- 与 GV.UY 后台给VPS提供的IPv6地址一致
- 与 icmp9.com 放行的 IPv6地址一致

## 第二步：停用 IPv4 并配置 IPv6 环境

请直接复制以下整段代码，在 VPS 终端中执行。这段代码会自动处理 DNS、网卡配置、清理残留进程并重启网络。

```bash
# 1. 设置 IPv6 DNS
printf "nameserver 2001:4860:4860::8888\nnameserver 2606:4700:4700::1111\n" > /etc/resolv.conf

# 2. 修改网卡配置文件 (禁用 IPv4 DHCP，启用 IPv6 Auto)
cat > /etc/network/interfaces <<EOF
auto eth0
iface eth0 inet manual
iface eth0 inet6 auto
hostname \$(hostname)
EOF

# 3. 清理 Cloud-init 网络配置
rm -f /etc/network/interfaces.d/50-cloud-init.cfg

# 4. 彻底清理 IPv4 进程与地址
# 强制杀死后台的 DHCP 客户端，防止它再次获取 IPv4
pkill udhcpc

# 立即清除网卡上的残留 IPv4 地址
# ip addr flush dev eth0

# 5. 重启网络服务使配置生效
/etc/init.d/networking restart
```


## 第三步：执行原生部署脚本

**注意：一键脚本中的 VPS IPv6 Only 系统参数务必设置为 True**

```bash
bash <(wget -qO- https://ghproxy.lvedong.eu.org/https://raw.githubusercontent.com/nap0o/icmp9.com/main/install_native.sh)  
```
