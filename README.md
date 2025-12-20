# 简单部署流程

### 特色

利用 [icmp9.com](https://icmp9.com/proxy) 提供的免费代理网络，借助1台vps实现落地全球多个国家的网络节点。

### 效果图
<img height="300" alt="image" src="https://github.com/user-attachments/assets/3ab617cf-94e4-46fb-ae15-ed219f2a5896" />

<img height="300" alt="image" src="https://github.com/user-attachments/assets/b90eb30c-44f6-42f2-bcc0-a30d737d14ae" />

### 前提条件

1. 拥有任意1台有公网IP的VPS，可以是icmp9送的虚机，也可以是其他的， VPS可以是IP双栈，也可以是任意IP单栈(也就是只有ipv4或ipv6都可以)。以下所有脚本命令只需要在这台vps上执行即可
2. [可选] Cloudflare固定隧道模式，需要1个可以在Zero Trust创建隧道的Cloudflare账号

---

## 部署步骤

**🍺 快速体验，可略过以下 [可选] 部署步骤！**

### [必需] 1.注册icmp9.com 账号，获取API KEY

![获取获取API KEYl 设置](https://github.com/user-attachments/assets/e55908be-f4e3-4294-aaee-4855fca2f3ec)

### [必需] 2.放行VPS的IP地址，双栈IP的VPS，IPv4和IPv6地址都要放行
![放行部署VPS的IP地址](https://github.com/user-attachments/assets/ceb9037d-3bdd-4789-9f71-207e6bc2c094)

### [可选] 3.使用cloudflare固定隧道模式

**获取隧道token，格式： eyJhIjoiZmJ****OayJ9**

![获取隧道token](https://github.com/user-attachments/assets/7ed6e80e-e71b-4008-b77f-5522d789654d)

**配置隧道服务： http://localhost:58080**

![Cloudflare Tunnel 设置](https://github.com/user-attachments/assets/06f93523-145f-445f-98ea-22a253b85b15)

### [可选] 4.设置swap虚拟内存, 适用于低配置VPS(CPU小于1核，内存小于1G，剩余硬盘空间大于5G)

⚠️ 设置swap成功后需要重启VPS才能生效

```bash
bash <(wget -qO- https://ghproxy.lvedong.eu.org/https://raw.githubusercontent.com/nap0o/icmp9.com/main/swap.sh)
```

- icmp9.com送的虚机,请务必先设置1G swap虚拟内存,再部署一键脚本

<img height="350" alt="image" src="https://github.com/user-attachments/assets/fe436d79-25b0-4276-81b3-c4c2265fa35d" /><br /> 

### [必需] 5.部署仅支持docker方式，请从以下3个部署方式选择

#### [推荐] 🔥🔥方式1：使用一键交互脚本部署

```bash
bash <(wget -qO- https://ghproxy.lvedong.eu.org/https://raw.githubusercontent.com/nap0o/icmp9.com/main/install.sh)  
```

**cloudflare临时隧道模式执行日志**

<img height="600" alt="image" src="https://github.com/user-attachments/assets/75562fb9-c507-4e30-a221-563da827b54f" /><br />

**cloudflare固定隧道模式执行日志**

<img height="600" src="https://github.com/user-attachments/assets/39492198-1853-45f3-97b9-e2a4f7f82d92" /><br />

#### 方式2：Docker run方式

```yaml
docker run -d \
  --name icmp9 \
  --restart always \
  --network host \
  -e ICMP9_API_KEY="[必填] icmp9 提供的 API KEY" \
  -e ICMP9_SERVER_HOST="[必填] Cloudflared Tunnel 域名" \
  -e ICMP9_CLOUDFLARED_TOKEN="[必填] Cloudflare Tunnel Token" \
  -e ICMP9_IPV6_ONLY=False \
  -e ICMP9_CDN_DOMAIN=icook.tw \
  -e ICMP9_START_PORT=39001 \
  -v "$(pwd)/data/subscribe:/root/subscribe" \
  nap0o/icmp9:latest
```

#### 方式3：Docker compose方式

```yaml
services:
  icmp9:
    image: nap0o/icmp9:latest
    container_name: icmp9
    restart: always
    network_mode: "host"
    environment:      
      # [必填] icmp9 提供的 API KEY
      - ICMP9_API_KEY=
      # [必填] Cloudflared Tunnel 域名
      - ICMP9_SERVER_HOST=
      # [必填] Cloudflare Tunnel Token
      - ICMP9_CLOUDFLARED_TOKEN=
      # [选填] VPS 是否 IPv6 Only (True/False)，默认为 False
      - ICMP9_IPV6_ONLY=False
      # [选填] CDN 优选 IP 或域名，不填默认使用 ICMP9_SERVER_HOST
      - ICMP9_CDN_DOMAIN=icook.tw
      # [选填] 起始端口，默认 39001
      - ICMP9_START_PORT=39001
    volumes:
      - ./data/subscribe:/root/subscribe
```

### [可选] 6.节点订阅地址

**方法1：通过docker日志获取**

```
docker logs icmp9
```

<img src="https://github.com/user-attachments/assets/843a42f5-5245-4d6b-817b-17464f26c8fa" height="222"><br />


**方法2：手动拼接**

```html
https://{ICMP9_SERVER_HOST}/{ICMP9_API_KEY}
```

**其中**

- {ICMP9_SERVER_HOST} 为 Cloudflare 隧道域名
- {ICMP9_API_KEY} 为从 https://icmp9.com/user/dashboard 获取的 API KEY
- 格式如： https://icmp9.nezha.pp.ua/b58828c1-4df5-4156-ee77-a889968533ae 


### [可选] 7.节点不通的自助排查步骤

**1. 检查VPS时间是否正确，如果误差超过30秒，节点会出错**

```bash
date

```
- 修正方法：问ai关键词 “linux同步系统时间的shell命令”

**2. 确认cloudflared tunnel是正常状态**

<img height="300" alt="image" src="https://github.com/user-attachments/assets/1d37656d-d923-4d1f-8e63-dae405ffb6f6" /> <br>

- 还需要在浏览器访问隧道域名，检查一下是否能正常打开

<img height="300" src="https://github.com/user-attachments/assets/b1f67880-c479-48d0-a637-e23cf77f91be" /><br />

**3. 确认icmp9.com放行的IP地址已生效，在部署脚本的VPS执行以下命令**

```bash
curl -v https://tunnel.icmp9.com/af
```

- 生效状态，返回400

<img height="350" src="https://github.com/user-attachments/assets/a3e13c7c-7d33-4938-866a-d76a3ff2eb7f" /><br />

- 未生效状态，返回403

<img height="350" alt="image" src="https://github.com/user-attachments/assets/2ff5064e-40ee-4959-a794-f97d6e7f2e6c" /><br />

**4. 已安装warp服务VPS检查默认优先出站ip地址是否和icmp9.com填写的放行IP地址一致，在部署脚本的VPS执行以下命令**

```bash
curl ip.sb
```

**如果IP地址不一致，用以下方法调整**

- 方法1. 用warp脚本调整vps的默认出站IP和icmp9.com放行IP地址一致
- 方法2. 直接卸载掉warp服务

**5. 填写的优选域名或IP在本地网络不能连通，重走步骤流程，更换其他优选域名或IP**

### 感谢

- https://github.com/fscarmen/ArgoX

- https://github.com/fscarmen/client_template

