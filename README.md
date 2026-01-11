# 简单部署流程

- [简单部署流程](#简单部署流程)
  - [特色](#特色)
  - [效果图](#效果图)
  - [前提条件](#前提条件)
    - [\[必需\] 1. 拥有 **任意** 1台有公网IP的VPS，部署脚本命令只需要在这台VPS上执行。](#必需-1-拥有-任意-1台有公网ip的vps部署脚本命令只需要在这台vps上执行)
    - [\[可选\] 2. Cloudflare固定隧道模式，需要1个可以在Zero Trust创建隧道的Cloudflare账号](#可选-2-cloudflare固定隧道模式需要1个可以在zero-trust创建隧道的cloudflare账号)
  - [准备工作](#准备工作)
    - [\[必需\] 1.注册 icmp9.com 账号，获取API KEY](#必需-1注册-icmp9com-账号获取api-key)
    - [\[必需\] 2.放行VPS的IP地址：单栈VPS仅需放行对应的单个IP地址；双栈VPS需同时放行IPv4和IPv6两个IP地址](#必需-2放行vps的ip地址单栈vps仅需放行对应的单个ip地址双栈vps需同时放行ipv4和ipv6两个ip地址)
    - [\[可选\] 3.使用cloudflare固定隧道模式](#可选-3使用cloudflare固定隧道模式)
    - [\[可选\] 4.设置swap虚拟内存, 适用于低配置VPS](#可选-4设置swap虚拟内存-适用于低配置vps)
  - [部署方式（二选一）](#部署方式二选一)
    - [🅰️ 5.Docker方式](#️-5docker方式)
      - [方式1：使用一键交互脚本部署（推荐 🔥）](#方式1使用一键交互脚本部署推荐-)
      - [方式2：Docker compose 方式](#方式2docker-compose-方式)
      - [方式3：Docker run 方式](#方式3docker-run-方式)
    - [🅱️ 6.VPS原生方式](#️-6vps原生方式)
    - [\[可选\] 7.获取节点订阅地址](#可选-7获取节点订阅地址)
    - [\[可选\] 8.节点不通时自助排查方法](#可选-8节点不通时自助排查方法)
      - [1.确认icmp9.com放行的IP地址已生效](#1确认icmp9com放行的ip地址已生效)
      - [2.固定隧道模式下，确认cloudflared tunnel是正常状态](#2固定隧道模式下确认cloudflared-tunnel是正常状态)
      - [3.已安装warp服务VPS核对默认优先出站IP地址与icmp9.com填写的放行IP地址一致](#3已安装warp服务vps核对默认优先出站ip地址与icmp9com填写的放行ip地址一致)
      - [4.确认优选域名在本地可以正常连通访问](#4确认优选域名在本地可以正常连通访问)
      - [5.核对VPS系统时间和本地环境时间一致](#5核对vps系统时间和本地环境时间一致)
    - [\[可选\] 9.一键卸载](#可选-9一键卸载)
  - [感谢](#感谢)
  - [免责](#免责)
  
---

## 特色

利用 [icmp9.com](https://icmp9.com/proxy) 提供的免费代理网络，借助1台VPS实现落地全球多个国家的网络节点。

## 效果图
<img height="300" alt="image" src="https://github.com/user-attachments/assets/3ab617cf-94e4-46fb-ae15-ed219f2a5896" />

<img height="300" alt="image" src="https://github.com/user-attachments/assets/b90eb30c-44f6-42f2-bcc0-a30d737d14ae" />

## 前提条件

### [必需] 1. 拥有 **任意** 1台有公网IP的VPS，部署脚本命令只需要在这台VPS上执行。
   - VPS系统：支持Debian、Ubuntu、Alpine
   - VPS类型：支持独立VPS、NAT
   - VPS网络：支持IP双栈，支持IPv4或IPv6任意IP单栈
   - VPS配置要求：

|       系统       | 部署方式 |   CPU   |  内存  | 配置SWAP(虚拟内存) | 硬盘 |
| :---: | :---: | :---: | :---: | :---: | :---: |
|      **Alpine**      |  Docker  | >=0.5核 | >=256M |    内存=256M时     | >=2G |
|      **Alpine**      | VPS原生  | >=0.5核 | >=128M |         --         | >=1G |
| **Debian / Ubuntu** |  Docker  |  >=1核  | >=512M |    内存=512M时     | >=3G |
| **Debian / Ubuntu** | VPS原生  | >=0.5核 | >=256M |         --         | >=1G |

### [可选] 2. Cloudflare固定隧道模式，需要1个可以在Zero Trust创建隧道的Cloudflare账号

<img height="350" alt="image" src="https://github.com/user-attachments/assets/8c9e051a-2286-4d37-bb43-919f57177193" /><br />

## 准备工作

### [必需] 1.注册 [icmp9.com](https://icmp9.com/user/register?invite=TO2H1GXu) 账号，获取API KEY

![获取获取API KEYl 设置](https://github.com/user-attachments/assets/e55908be-f4e3-4294-aaee-4855fca2f3ec)

### [必需] 2.放行VPS的IP地址：单栈VPS仅需放行对应的单个IP地址；双栈VPS需同时放行IPv4和IPv6两个IP地址

![放行部署VPS的IP地址](https://github.com/user-attachments/assets/ceb9037d-3bdd-4789-9f71-207e6bc2c094)

### [可选] 3.使用cloudflare固定隧道模式

**获取隧道token，格式： eyJhIjoiZmJ****OayJ9**

![获取隧道token](https://github.com/user-attachments/assets/7ed6e80e-e71b-4008-b77f-5522d789654d)

**配置隧道服务： http://localhost:58080**

- ⚠️ 服务端口号必须是58080

![Cloudflare Tunnel 设置](https://github.com/user-attachments/assets/06f93523-145f-445f-98ea-22a253b85b15)

### [可选] 4.设置swap虚拟内存, 适用于低配置VPS

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/main/swap.sh)
```

- ⚠️ 设置swap成功后需要重启VPS才能生效
- 从icmp9.com官方领取的256m内存的虚机，Docker方式部署，请务必先设置1G swap虚拟内存,再部署一键脚本

<img height="350" alt="image" src="https://github.com/user-attachments/assets/fe436d79-25b0-4276-81b3-c4c2265fa35d" /><br /> 

## 部署方式（二选一）

请在 **Docker 方式** 或 **原生方式** 中选择一种进行部署

### 🅰️ 5.Docker方式

#### 方式1：使用一键交互脚本部署（推荐 🔥）

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/main/install_docker.sh)  
```

**采用cloudflare临时隧道模式执行日志**

<img height="600" alt="image" src="https://github.com/user-attachments/assets/75562fb9-c507-4e30-a221-563da827b54f" /><br />

**采用cloudflare固定隧道模式执行日志**

<img height="600" src="https://github.com/user-attachments/assets/39492198-1853-45f3-97b9-e2a4f7f82d92" /><br />

#### 方式2：Docker compose 方式

```yaml
services:
  icmp9:
    image: nap0o/icmp9:latest
    container_name: icmp9
    restart: always
    network_mode: host
    environment:      
      # [必填] icmp9 提供的 API KEY
      - ICMP9_API_KEY=
      # [选填] Cloudflared Tunnel 域名
      - ICMP9_CLOUDFLARED_DOMAIN=
      # [选填] Cloudflare Tunnel Token
      - ICMP9_CLOUDFLARED_TOKEN=
      # [选填] VPS 是否 IPv6 Only (True/False)，默认为 False
      - ICMP9_IPV6_ONLY=False
      # [选填] Cloudflare CDN 优选IP或域名，不填默认使用 ICMP9_CLOUDFLARED_DOMAIN
      - ICMP9_CDN_DOMAIN=icook.tw
      # [选填] Xray服务监听起始端口，默认 39001
      - ICMP9_START_PORT=39001
      # [选填] 节点标识，默认 ICMP9
      - ICMP9_NODE_TAG=ICMP9     
    volumes:
      - ./data/subscribe:/root/subscribe
```

#### 方式3：Docker run 方式

```yaml
docker run -d \
  --name icmp9 \
  --restart always \
  --network host \
  -e ICMP9_API_KEY="[必填] icmp9 提供的 API KEY" \
  -e ICMP9_CLOUDFLARED_DOMAIN="[选填] Cloudflared Tunnel 域名" \
  -e ICMP9_CLOUDFLARED_TOKEN="[选填] Cloudflare Tunnel Token" \
  -e ICMP9_IPV6_ONLY=False \
  -e ICMP9_CDN_DOMAIN=icook.tw \
  -e ICMP9_START_PORT=39001 \
  -e ICMP9_NODE_TAG=ICMP9 \
  -v "$(pwd)/data/subscribe:/root/subscribe" \
  nap0o/icmp9:latest
```

### 🅱️ 6.VPS原生方式

**⚠️  警告: 谨慎操作**

- 将修改VPS配置的Nginx,Xray,Cloudflared原有服务，原配置会失效
- 建议在纯净服务器上运行
- 作者不对因使用本脚本造成的任何数据丢失负责

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/main/install_native.sh)  
```

### [可选] 7.获取节点订阅地址

**方法1：通过docker日志获取**

```
docker logs icmp9
```

<img src="https://github.com/user-attachments/assets/843a42f5-5245-4d6b-817b-17464f26c8fa" height="222"><br />


**方法2：手动拼接（不支持cloudflare临时隧道方式部署）**

```html
https://{ICMP9_CLOUDFLARED_DOMAIN}/{ICMP9_API_KEY}
```

**其中**

- {ICMP9_CLOUDFLARED_DOMAIN} 为 Cloudflare 隧道域名
- {ICMP9_API_KEY} 为从 https://icmp9.com/user/dashboard 获取的 API KEY
- 格式如： https://icmp9.nezha.pp.ua/b58828c1-4df5-4156-ee77-a889968533ae 


### [可选] 8.节点不通时自助排查方法

#### 1.确认icmp9.com放行的IP地址已生效

在部署脚本的VPS执行以下命令

```bash
curl -v https://tunnel.icmp9.com/af
```

生效状态，返回 **400**

<img height="350" src="https://github.com/user-attachments/assets/a3e13c7c-7d33-4938-866a-d76a3ff2eb7f" /><br />

未生效状态，返回 **403**

<img height="350" alt="image" src="https://github.com/user-attachments/assets/2ff5064e-40ee-4959-a794-f97d6e7f2e6c" /><br />

#### 2.固定隧道模式下，确认cloudflared tunnel是正常状态

<img height="300" alt="image" src="https://github.com/user-attachments/assets/1d37656d-d923-4d1f-8e63-dae405ffb6f6" /> <br>

**还需要在浏览器访问隧道域名，检查一下是否能正常打开**

<img height="300" src="https://github.com/user-attachments/assets/b1f67880-c479-48d0-a637-e23cf77f91be" /><br />

#### 3.已安装warp服务VPS核对默认优先出站IP地址与icmp9.com填写的放行IP地址一致

在部署脚本的VPS执行以下命令获取默认优先出站ip地址

```bash
curl ip.sb
```

如果与放行IP地址不一致，用以下方法调整

- 方法1. 用warp脚本调整vps的默认出站IP和icmp9.com放行IP地址一致
- 方法2. 直接卸载掉warp服务

#### 4.确认优选域名在本地可以正常连通访问

如填写的优选域名或IP在本地网络不能连通，重走步骤流程，更换其他优选域名或IP

#### 5.核对VPS系统时间和本地环境时间一致

检查VPS时间是否正确，如果误差超过30秒，节点会出错

```bash
date
```
修正方法：问AI关键词 “linux同步系统时间的shell命令”


### [可选] 9.一键卸载

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/main/uninstall.sh)  
```

## 感谢

- https://github.com/fscarmen/ArgoX
- https://github.com/fscarmen/client_template
- https://github.com/fscarmen2/Cloudflare-Accel
- https://github.com/crazypeace/ghproxy

## 免责

- 本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
- 使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。