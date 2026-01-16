# 简单部署流程

## 特色

利用 [icmp9.com](https://icmp9.com/proxy) 提供的免费代理网络，借助1台VPS实现落地全球多个国家的网络节点。

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
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/nginx/swap.sh)
```

- ⚠️ 设置swap成功后需要重启VPS才能生效
- 从icmp9.com官方领取的256m内存的虚机，Docker方式部署，请务必先设置1G swap虚拟内存,再部署一键脚本

<img height="350" alt="image" src="https://github.com/user-attachments/assets/fe436d79-25b0-4276-81b3-c4c2265fa35d" /><br /> 

## 部署方式（二选一）

请在 **Docker 方式** 或 **原生方式** 中选择一种进行部署

### 🅰️ 5.Docker方式

#### 方式1：使用一键交互脚本部署（推荐 🔥）

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/nginx/install_docker.sh)  
```

#### 方式2：Docker compose 方式

```yaml
services:
  icmp9:
    image: nap0o/icmp9:nginx
    container_name: icmp9
    restart: always
    network_mode: host
    environment:      
      # [必填] icmp9 提供的 API KEY
      - ICMP9_API_KEY=
      # [必填] icmp9 提供的网络接入点
      - ICMP9_TUNNEL_ENDPOINT=tunnel-as.8443.buzz
      # [选填] Cloudflared Tunnel 域名
      - ICMP9_CLOUDFLARED_DOMAIN=
      # [选填] Cloudflare Tunnel Token
      - ICMP9_CLOUDFLARED_TOKEN=
      # [选填] VPS 是否 IPv6 Only (True/False)，默认为 False
      - ICMP9_IPV6_ONLY=False
      # [选填] Cloudflare CDN 优选IP或域名，不填默认使用 ICMP9_CLOUDFLARED_DOMAIN
      - ICMP9_CDN_DOMAIN=icook.tw
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
  -e ICMP9_TUNNEL_ENDPOINT="[必填] icmp9 提供的网络接入点,格式如 tunnel-as.8443.buzz" \
  -e ICMP9_CLOUDFLARED_DOMAIN="[选填] Cloudflared Tunnel 域名" \
  -e ICMP9_CLOUDFLARED_TOKEN="[选填] Cloudflare Tunnel Token" \
  -e ICMP9_IPV6_ONLY=False \
  -e ICMP9_CDN_DOMAIN=icook.tw \
  -e ICMP9_NODE_TAG=ICMP9 \
  -v "$(pwd)/data/subscribe:/root/subscribe" \
  nap0o/icmp9:nginx
```

### 🅱️ 6.VPS原生方式

**⚠️  警告: 谨慎操作**

- 将修改VPS配置的Nginx,Cloudflared原有服务，原配置会失效
- 建议在纯净服务器上运行
- 作者不对因使用本脚本造成的任何数据丢失负责

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/nginx/install_native.sh)  
```

### [可选] 7.一键卸载

```bash
bash <(wget -qO- https://o0o.net2ftp.pp.ua/https://raw.githubusercontent.com/nap0o/icmp9.com/nginx/uninstall.sh)  
```

## 感谢

- https://github.com/fscarmen/ArgoX
- https://github.com/fscarmen/client_template
- https://github.com/fscarmen2/Cloudflare-Accel
- https://github.com/crazypeace/ghproxy

## 免责

- 本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
- 使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。