#!/bin/sh

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 辅助函数
info() { printf "${GREEN}%s${NC}\n" "$1"; }
warn() { printf "${YELLOW}%s${NC}\n" "$1"; }
error() { printf "${RED}%s${NC}\n" "$1"; }

printf "${GREEN}=============================================${NC}\n"
printf "${GREEN}        ICMP9聚合落地节点部署脚本                ${NC}\n"
printf "${GREEN}     (支持 Debian / Ubuntu / Alpine)          ${NC}\n"
printf "${GREEN}=============================================${NC}\n"

# 1. 环境检测与 Docker 安装
if ! command -v docker >/dev/null 2>&1; then
    warn "⚠️ 未检测到 Docker，正在识别系统并安装..."
    if [ -f /etc/alpine-release ]; then
        apk update
        apk add docker docker-cli-compose
        addgroup root docker >/dev/null 2>&1
        rc-service docker start
        rc-update add docker default
    else
        apt-get update
        apt-get install -y curl
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
fi

# 检查 Docker Compose
if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
    warn "⚠️ 未检测到 Docker Compose，正在安装..."
    if [ -f /etc/alpine-release ]; then
        apk add docker-cli-compose
    else
        apt-get update
        apt-get install -y docker-compose-plugin
    fi
fi

# 2. 创建工作目录
WORK_DIR="icmp9"
[ ! -d "$WORK_DIR" ] && mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# 3. 收集用户输入
printf "\n${YELLOW}>>> 请输入配置参数 <<<${NC}\n"

# API_KEY (UUID) - 必填
while [ -z "$API_KEY" ]; do
    printf "1. 请输入 ICMP9_API_KEY (用户UUID, 必填): "
    read -r API_KEY
done

# 选择隧道模式
printf "\n2. 请选择 Cloudflare 隧道模式:\n"
printf "   [1] 临时隧道 (随机域名，无需配置)\n"
printf "   [2] 固定隧道 (需要自备域名和Token)\n"
printf "   请选择 [1/2] (默认: 1): "
read -r MODE_INPUT
[ -z "$MODE_INPUT" ] && MODE_INPUT="1"

if [ "$MODE_INPUT" = "2" ]; then
    # --- 固定隧道模式 (选项2) ---
    TUNNEL_MODE="fixed"
    while [ -z "$SERVER_HOST" ]; do
        printf "   -> 请输入绑定域名 (SERVER_HOST) (必填): "
        read -r SERVER_HOST
    done

    while [ -z "$TOKEN" ]; do
        printf "   -> 请输入 Cloudflare Tunnel Token (必填): "
        read -r TOKEN
    done
else
    # --- 临时隧道模式 (选项1或默认) ---
    TUNNEL_MODE="temp"
    SERVER_HOST="" # 留空
    TOKEN=""       # 留空
    info "   -> 已选择临时隧道，域名将在启动后自动生成。"
fi

# IPv6 设置
printf "\n3. 是否仅 IPv6 (True/False) [默认: False]: "
read -r IPV6_INPUT
IPV6_ONLY=$(echo "${IPV6_INPUT:-false}" | tr '[:upper:]' '[:lower:]')

# CDN 设置
printf "4. 请输入 CDN 优选 IP 或域名 [默认: icook.tw]: "
read -r CDN_INPUT
[ -z "$CDN_INPUT" ] && CDN_DOMAIN="icook.tw" || CDN_DOMAIN=$CDN_INPUT

# 端口设置
printf "5. 请输入本地监听起始端口 [默认: 39001]: "
read -r PORT_INPUT
[ -z "$PORT_INPUT" ] && START_PORT="39001" || START_PORT=$PORT_INPUT

# 4. 生成 docker-compose.yml
info "⏳ 正在生成 docker-compose.yml..."

cat > docker-compose.yml <<EOF
services:
  icmp9:
    image: nap0o/icmp9:latest
    container_name: icmp9
    restart: always
    network_mode: "host"
    environment:
      - ICMP9_API_KEY=${API_KEY}
      - ICMP9_SERVER_HOST=${SERVER_HOST}
      - ICMP9_CLOUDFLARED_TOKEN=${TOKEN}
      - ICMP9_IPV6_ONLY=${IPV6_ONLY}
      - ICMP9_CDN_DOMAIN=${CDN_DOMAIN}
      - ICMP9_START_PORT=${START_PORT}
    volumes:
      - ./data/subscribe:/root/subscribe
EOF

# 5. 启动服务
DOCKER_COMPOSE_CMD="docker compose"
if ! docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
fi

printf "\n是否立即启动容器？(y/n) [默认: y]: "
read -r START_NOW
[ -z "$START_NOW" ] && START_NOW="y"

if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
    
    # --- 1: 清理旧容器 ---
    # 检查是否有名为 icmp9 的容器（运行中或停止状态）
    if docker ps -a --format '{{.Names}}' | grep -q "^icmp9$"; then
        warn "⚠️ 检测到已存在 icmp9 容器，正在停止并删除..."
        docker rm -f icmp9 >/dev/null 2>&1
        info "✅ 旧容器已清理"
    fi

    # --- 2: 强制拉取最新镜像 ---
    info "⬇️ 正在拉取最新镜像 (nap0o/icmp9:latest)..."
    $DOCKER_COMPOSE_CMD pull
    
    info "🚀 正在启动容器..."
    $DOCKER_COMPOSE_CMD up -d
    
    if [ $? -eq 0 ]; then
        printf "\n${GREEN}✅ ICMP9 部署成功！${NC}\n"
        
        if [ "$TUNNEL_MODE" = "fixed" ]; then
            # --- 固定隧道：直接显示 ---
            printf "\n${GREEN}✈️  节点订阅地址:${NC}\n"
            printf "${YELLOW}https://${SERVER_HOST}/${API_KEY}${NC}\n\n"
        else
            # --- 临时隧道：自动轮询等待日志 ---
            printf "\n${CYAN}⏳ 正在等待 Cloudflare 分配临时域名 (超时60秒)...${NC}\n"
            printf "${CYAN}   (请稍候，系统正在从日志中抓取订阅链接)${NC}\n"
            
            TIMEOUT=60
            INTERVAL=3
            ELAPSED=0
            FOUND_URL=""

            while [ $ELAPSED -lt $TIMEOUT ]; do
                # 尝试从日志中提取包含 trycloudflare.com 的 URL
                # 使用 grep -oE 精确提取 URL 部分
                LOG_URL=$(docker logs icmp9 2>&1 | grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com/${API_KEY}" | tail -n 1)
                
                if [ -n "$LOG_URL" ]; then
                    FOUND_URL="$LOG_URL"
                    break
                fi
                
                # 打印进度点
                printf "."
                sleep $INTERVAL
                ELAPSED=$((ELAPSED + INTERVAL))
            done
            
            # 换行
            echo ""

            if [ -n "$FOUND_URL" ]; then
                printf "\n${GREEN}临时域名获取成功！${NC}\n"
                printf "${GREEN}✅ 节点订阅地址:${NC}\n"
                printf "${YELLOW}%s${NC}\n\n" "$FOUND_URL"
            else
                printf "\n${YELLOW}⚠️  自动获取超时 (网络可能较慢)。${NC}\n"
                printf "请稍后手动执行此命令查看地址：\n"
                printf "${CYAN}docker logs icmp9 | grep 'https://'${NC}\n\n"
            fi
        fi
    else
        error "❌ 启动失败。"
    fi
else
    warn "已取消启动。您可以稍后运行 'docker compose up -d' 启动。"
fi