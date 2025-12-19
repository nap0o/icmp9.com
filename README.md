#  简单部署流程

## 准备

### 1.注册icmp9.com 账号，获取API KEY

![获取获取API KEYl 设置](https://github.com/user-attachments/assets/e55908be-f4e3-4294-aaee-4855fca2f3ec)

### 2.放行部署VPS的IP地址，双栈IP的VPS，IPv4和IPv6地址都要放行
![放行部署VPS的IP地址](https://github.com/user-attachments/assets/ceb9037d-3bdd-4789-9f71-207e6bc2c094)

### 3.Cloudflare隧道相关

**获取隧道token**
![获取隧道token](https://github.com/user-attachments/assets/7ed6e80e-e71b-4008-b77f-5522d789654d)

**配置隧道**
![Cloudflare Tunnel 设置](https://github.com/user-attachments/assets/06f93523-145f-445f-98ea-22a253b85b15)

### 4. 部署仅支持docker方式

**Docker run方式**

```yaml
docker run -d \
  --name icmp9 \
  --restart always \
  --network host \
  -e ICMP9_API_KEY="[必填] icmp9 提供的 API KEY" \
  -e ICMP9_SERVER_HOST=" [必填] Cloudflared Tunnel 域名" \
  -e ICMP9_CLOUDFLARED_TOKEN="[必填] Cloudflare Tunnel Token" \
  -e ICMP9_IPV6_ONLY=False \
  -e ICMP9_CDN_DOMAIN=ip.sb \
  -e ICMP9_START_PORT=39001 \
  -v "$(pwd)/data/subscribe:/root/subscribe" \
  nap0o/icmp9:latest
```


**Docker compose方式**

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
      # [选填] 是否仅 IPv6 (True/False)，默认为 False
      - ICMP9_IPV6_ONLY=False
      # [选填] CDN 优选 IP 或域名，不填默认使用 ICMP9_SERVER_HOST
      - ICMP9_CDN_DOMAIN=ip.sb
      # [选填] 起始端口，默认 39001
      - ICMP9_START_PORT=39001
    volumes:
      - ./data/subscribe:/root/subscribe
```

## 节点订阅地址

https://{ICMP9_SERVER_HOST}/{ICMP9_API_KEY}

**其中**
- {ICMP9_SERVER_HOST} 为 Cloudflare 隧道域名
- {ICMP9_API_KEY} 为从 https://icmp9.com/user/dashboard 获取的 API KEY

格式如： https://icmp9.nezha.pp.ua/b58828c1-4df5-4156-ee77-a889968533ae