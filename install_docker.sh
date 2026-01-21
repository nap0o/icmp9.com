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

# 注册清理函数：脚本退出或中断时自动清理临时文件
cleanup() {
    rm -f /tmp/icmp9_ap_list.txt /tmp/icmp9_regions.json /tmp/icmp9_endpoints.txt
}
trap cleanup EXIT

printf "${GREEN}=============================================${NC}\n"
printf "${GREEN}      ICMP9全球落地聚合节点部署脚本              ${NC}\n"
printf "${GREEN}      支持 Debian / Ubuntu / Alpine           ${NC}\n"
printf "${GREEN}=============================================${NC}\n"

# 0. 检查是否为 Root 用户
if [ "$(id -u)" != "0" ]; then
    error "❌ 请使用 Root 用户运行此脚本！(输入 'sudo -i' 切换)"
    exit 1
fi

# 确保 curl 已安装
if ! command -v curl >/dev/null 2>&1; then
    warn "⚠️ 检测到未安装 curl，正在安装..."
    if [ -f /etc/alpine-release ]; then
        apk add --no-cache curl
    else
        apt-get update >/dev/null 2>&1 && apt-get install -y curl >/dev/null 2>&1
    fi
fi

# 确保 jq 已安装
if ! command -v jq >/dev/null 2>&1; then
    warn "⚠️ 检测到未安装 jq，正在安装..."
    if [ -f /etc/alpine-release ]; then
        apk add --no-cache jq
    else
        apt-get update >/dev/null 2>&1 && apt-get install -y jq >/dev/null 2>&1
    fi
fi

# ----------------------------------------------------------------
# 1. ICMP9 API 连通性预检测
# ----------------------------------------------------------------

# 1.1 检查 ICMP9 网络接入点 API
info "📡 正在检查 ICMP9 可用网络接入点 API 连接状态..."
AP_URL="https://icmp9.b.4.8.f.0.7.4.0.1.0.0.2.ip6.arpa/endpoints.php"
AP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -A "Mozilla/5.0" "$AP_URL")

if [ "$AP_CODE" = "200" ]; then
    info "✅ ICMP9 可用网络接入点 API 连接正常，准备开始部署..."
else
    error "❌ ICMP9 可用网络接入点 API 连接检查未通过！"
    error "⛔️ 脚本已停止运行。"
    exit 1
fi

# 1.2 检查 ICMP9 可用落地节点 API
info "📡 正在检查 ICMP9 可用落地节点 API 连接状态..."
ONLINE_URL="https://api.icmp9.com/online.php"
ONLINE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -A "Mozilla/5.0" "$ONLINE_URL")

if [ "$ONLINE_CODE" = "200" ]; then
    info "✅ 可用落地节点 API 连接正常..."
else
    error "❌ 可用落地节点 API 连接检查未通过！"
    error "⛔️ 脚本已停止运行。"
    exit 1
fi

# ----------------------------------------------------------------
# 2. 环境检测与 Docker 安装
# ----------------------------------------------------------------
# 1. 环境检测与 Docker 安装
# 刷新命令缓存
hash -r >/dev/null 2>&1

if ! command -v docker >/dev/null 2>&1; then
    warn "⚠️ 未检测到 Docker，正在识别系统并安装..."
    
    if [ -f /etc/alpine-release ]; then
        # Alpine Linux
        apk update
        apk add docker docker-cli-compose
        rc-update add docker default
        rc-service docker start
    else
        # Debian / Ubuntu
        if ! command -v curl >/dev/null 2>&1; then
            apt-get update && apt-get install -y curl
        fi
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi

    # --- 安装后再次检测 ---
    hash -r >/dev/null 2>&1
    if ! command -v docker >/dev/null 2>&1; then
        error "❌ Docker 自动安装失败！"
        warn "请尝试手动执行安装命令: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    info "✅ Docker 安装成功"
fi

# 等待 Docker 服务就绪
info "⏳ 等待检查 Docker 服务启动状态..."
for i in $(seq 1 15); do
    if docker info >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

if ! docker info >/dev/null 2>&1; then
    error "❌ Docker 服务未就绪，请稍后重试"
    exit 1
else
    info "✅ Docker 服务已就绪"
fi

# 检查 Docker Compose
if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
    warn "⚠️ 未检测到 Docker Compose，正在安装..."
    
    if [ -f /etc/alpine-release ]; then
        apk add docker-cli-compose
    else
        # 尝试安装插件版
        apt-get update && apt-get install -y docker-compose-plugin || \
        # 如果 apt 失败，尝试作为 python 包或二进制
        warn "尝试通过包管理器安装插件失败，尝试依赖 Docker CLI 插件..."
    fi
    
    # 再次检查
    if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
        error "❌ Docker Compose 安装失败！"
        exit 1
    fi
    info "✅ Docker Compose 安装成功"
fi

# ----------------------------------------------------------------
# 3. 收集用户输入
# ----------------------------------------------------------------
printf "\n${YELLOW}>>> 请输入配置参数 <<<${NC}\n"

# API_KEY (UUID) - 必填
while [ -z "$API_KEY" ]; do
    printf "1. 请输入 ICMP9_API_KEY (UUID格式, 必填): "
    read -r API_KEY
done

# ICMP9 网络接入点选择
printf "\n2. 请选择 ICMP9 网络接入点:\n"
info "📥 正在获取ICMP9最新网络接入点列表..."

# 获取数据
AP_JSON=$(curl -s --max-time 15 "$AP_URL")

if [ -z "$AP_JSON" ]; then
    error "❌ 获取 ICMP9 网络接入点数据为空！"
    error "⛔️ 脚本已停止运行。"
    exit 1
fi

# 预处理
echo "$AP_JSON" | jq -c '.data.regions[]' > /tmp/icmp9_regions.json

if [ ! -s /tmp/icmp9_regions.json ]; then
    error "❌ 未找到任何区域数据！请检查 API 返回结构。"
    error "⛔️ 脚本已停止运行。"
    exit 1
fi

# 清理并初始化
rm -f /tmp/icmp9_endpoints.txt
touch /tmp/icmp9_endpoints.txt

# 遍历每个区域对象
while read -r REGION_JSON; do
    # 提取区域元数据
    REGION_CODE=$(echo "$REGION_JSON" | jq -r '.code' | tr '[:lower:]' '[:upper:]')
    REGION_NAME=$(echo "$REGION_JSON" | jq -r '.name')
    
    # 提取该区域下的 endpoints
    NODES=$(echo "$REGION_JSON" | jq -r '.endpoints[] | "\(.name)|\(.domain)"')
    
    if [ -z "$NODES" ]; then continue; fi

    printf "\n   ${CYAN}>>> 处理区域: %s ...${NC}\n" "$REGION_NAME"

    # 统计节点数量
    NODE_COUNT=$(echo "$NODES" | wc -l)
    
    SELECTED_DOMAIN=""
    SELECTED_NAME=""

    # === 智能分支 ===
    if [ "$NODE_COUNT" -eq 1 ]; then
        # 自动选择
        SELECTED_NAME=$(echo "$NODES" | cut -d '|' -f 1)
        SELECTED_DOMAIN=$(echo "$NODES" | cut -d '|' -f 2)
        printf "   ✅ 仅发现一个活跃节点，已自动选择: %s\n" "$SELECTED_NAME"
    else
        # 手动选择
        printf "   ⚠️  存在 %s 个活跃节点，请手动指定:\n" "$NODE_COUNT"
        
        echo "$NODES" > /tmp/icmp9_ap_list.txt
        
        i=1
        while IFS='|' read -r NAME DOMAIN; do
            printf "      [%d] %s\n" "$i" "$NAME"
            i=$((i+1))
        done < /tmp/icmp9_ap_list.txt
        
        TOTAL_COUNT=$((i-1))
        
        while [ -z "$SELECTED_DOMAIN" ]; do
            printf "      请选择 [1-%d]: " "$TOTAL_COUNT"
            # 强制从终端读取
            read -r SEL < /dev/tty
            
            case "$SEL" in
                ''|*[!0-9]*) 
                    warn "输入无效，请重新输入" 
                    ;;
                *)
                    if [ "$SEL" -ge 1 ] && [ "$SEL" -le "$TOTAL_COUNT" ]; then
                        LINE=$(sed -n "${SEL}p" /tmp/icmp9_ap_list.txt)
                        SELECTED_NAME=$(echo "$LINE" | cut -d '|' -f 1)
                        SELECTED_DOMAIN=$(echo "$LINE" | cut -d '|' -f 2)
                        printf "      -> 已手动设置: %s\n" "$SELECTED_NAME"
                    else
                        warn "选项超出范围"
                    fi
                    ;;
            esac
        done
        rm -f /tmp/icmp9_ap_list.txt
    fi

    # 变量记录
    ENV_VAR_NAME="ICMP9_TUNNEL_ENDPOINT_${REGION_CODE}"
    ENV_VAR_NAME=$(echo "$ENV_VAR_NAME" | tr ' ' '_')
    
    echo "      - ${ENV_VAR_NAME}=${SELECTED_DOMAIN}" >> /tmp/icmp9_endpoints.txt

done < /tmp/icmp9_regions.json

# 读取环境变量片段
if [ -f /tmp/icmp9_endpoints.txt ]; then
    DOCKER_ENV_EXTRA=$(cat /tmp/icmp9_endpoints.txt)
    info "✅ 网络接入点所有地区配置完成。"
else
    error "❌ 未能生成任何网络接入点配置！"
    exit 1
fi
# ------------------------------------

# 选择隧道模式
printf "\n3. 请选择 Cloudflare 隧道模式:\n"
printf "   [1] 临时隧道 (随机域名，无需配置)\n"
printf "   [2] 固定隧道 (需要自备域名和Token)\n"
printf "   请选择 [1/2] (默认: 1): "
read -r MODE_INPUT
[ -z "$MODE_INPUT" ] && MODE_INPUT="1"

if [ "$MODE_INPUT" = "2" ]; then
    # --- 固定隧道模式 ---
    TUNNEL_MODE="fixed"
    while [ -z "$CLOUDFLARED_DOMAIN" ]; do
        printf "   -> 请输入绑定域名 (CLOUDFLARED_DOMAIN) (必填): "
        read -r CLOUDFLARED_DOMAIN
    done

    while [ -z "$TOKEN" ]; do
        printf "   -> 请输入 Cloudflare Tunnel Token (必填): "
        read -r TOKEN
    done
else
    # --- 临时隧道模式 ---
    TUNNEL_MODE="temp"
    CLOUDFLARED_DOMAIN=""
    TOKEN=""
    info "   -> 已选择临时隧道，域名将在启动后自动生成。"
fi

# IPv6 设置 (忽略大小写)
printf "\n4. VPS是否IPv6 Only (True/False) [默认: False]: "
read -r IPV6_INPUT
IPV6_ONLY=$(echo "${IPV6_INPUT:-false}" | tr '[:upper:]' '[:lower:]')

# CDN 设置
printf "5. 请输入Cloudflare CDN优选IP或域名 [默认: icook.tw]: "
read -r CDN_INPUT
[ -z "$CDN_INPUT" ] && CDN_DOMAIN="icook.tw" || CDN_DOMAIN=$CDN_INPUT

# 节点标识设置
printf "6. 请输入节点标识 [默认: ICMP9]: "
read -r NODE_TAG_INPUT
[ -z "$NODE_TAG_INPUT" ] && NODE_TAG="ICMP9" || NODE_TAG=$NODE_TAG_INPUT

# ----------------------------------------------------------------
# 4. 创建目录与生成配置
# ----------------------------------------------------------------
WORK_DIR=${ICMP9_WORK_DIR:-/root}
[ ! -d "$WORK_DIR/icmp9" ] && mkdir -p "$WORK_DIR/icmp9"
cd "$WORK_DIR/icmp9" || exit

# 4. 生成 docker-compose.yml
info "⏳ 正在生成 docker-compose.yml..."

cat > ${WORK_DIR}/icmp9/docker-compose.yml <<EOF
services:
  icmp9:
    image: nap0o/icmp9:nginx
    container_name: icmp9
    restart: always
    network_mode: host
    environment:
      - ICMP9_API_KEY=${API_KEY}
      - ICMP9_CLOUDFLARED_DOMAIN=${CLOUDFLARED_DOMAIN}
      - ICMP9_CLOUDFLARED_TOKEN=${TOKEN}
      - ICMP9_IPV6_ONLY=${IPV6_ONLY}
      - ICMP9_CDN_DOMAIN=${CDN_DOMAIN}
      - ICMP9_NODE_TAG=${NODE_TAG}
$(echo "$DOCKER_ENV_EXTRA")
    volumes:
      - ./data/subscribe:${WORK_DIR}/subscribe
EOF

# 5. 确定 Docker Compose 命令
# 再次动态检测，防止安装后变量未更新
DOCKER_COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    error "❌ 无法找到 docker compose 或 docker-compose 命令，请检查安装。"
    exit 1
fi

# 6. 启动服务
printf "\n是否立即启动容器？(y/n) [默认: y]: "
read -r START_NOW
[ -z "$START_NOW" ] && START_NOW="y"

if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
    
    # --- 1: 清理旧容器 ---
    # 检查是否有名为 icmp9 的容器（运行中或停止状态）
    if [ -n "$(docker ps -aq -f name="^/icmp9$")" ]; then
        warn "⚠️ 检测到已存在 icmp9 容器，正在停止并删除..."
        
        # 尝试删除，并捕获返回值
        if docker rm -f icmp9 >/dev/null 2>&1; then
            info "✅ 旧容器已清理"
        else
            error "❌ 旧容器清理失败！请检查 Docker 权限或手动执行 'docker rm -f icmp9'"
            exit 1
        fi
    fi

    # --- 强制更新 ---
    info "⬇️ 正在拉取最新镜像..."
    if ! $DOCKER_COMPOSE_CMD pull; then
        error "❌ 镜像拉取失败，请检查网络或 Docker 配置。"
        exit 1
    fi
    
    # --- 启动 ---
    info "🚀 正在启动容器..."
    if ! $DOCKER_COMPOSE_CMD up -d; then
        error "❌ 容器启动命令执行失败。"
        exit 1
    fi
    
    # 成功判断
    printf "\n${GREEN}✅ ICMP9 部署成功！${NC}\n"
    
    if [ "$TUNNEL_MODE" = "fixed" ]; then
        # --- 固定隧道 ---
        SUBSCRIBE_URL="https://${CLOUDFLARED_DOMAIN}/${API_KEY}"

        printf "\n${GREEN}✈️ 节点订阅地址:${NC}\n"
        printf "${YELLOW}%s${NC}\n\n" "${SUBSCRIBE_URL}"

        printf "${GREEN}📱 正在生成节点订阅二维码...${NC}\n"
        docker exec icmp9 qrencode -t ANSIUTF8 -m 1 -l H "${SUBSCRIBE_URL}" || {
            printf "\n${YELLOW}⚠️ 二维码生成失败${NC}\n"
        }

    else
        # --- 临时隧道 ---
        printf "\n${CYAN}⏳ 正在等待 Cloudflare 分配临时域名 (超时60秒)...${NC}\n"
        printf "${CYAN}   (请稍候，系统正在从日志中抓取订阅链接)${NC}\n"
        
        TIMEOUT=60
        INTERVAL=3
        ELAPSED=0
        FOUND_URL=""

        while [ $ELAPSED -lt $TIMEOUT ]; do
            # 抓取日志
            LOG_URL=$(docker logs icmp9 2>&1 | grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com/${API_KEY}" | tail -n 1)
            
            if [ -n "$LOG_URL" ]; then
                FOUND_URL="$LOG_URL"
                break
            fi
            
            printf "."
            sleep $INTERVAL
            ELAPSED=$((ELAPSED + INTERVAL))
        done
        
        echo ""

        if [ -n "$FOUND_URL" ]; then
            printf "\n${GREEN}✅ 临时域名获取成功！${NC}\n\n"
            printf "${GREEN}✈️ 节点订阅地址:${NC}\n"
            printf "${YELLOW}%s${NC}\n\n" "$FOUND_URL"
            printf "${GREEN}📱 正在生成节点订阅二维码...${NC}\n"
            docker exec icmp9 qrencode -t ANSIUTF8 -m 1 -l H "$FOUND_URL" || {
                printf "\n${YELLOW}⚠️ 二维码生成失败。${NC}\n"
            }
        else
            printf "\n${YELLOW}⚠️ 自动获取超时 (网络可能较慢)。${NC}\n"
            printf "ℹ️ 请稍后手动执行此命令查看地址：\n"
            printf "${CYAN}docker logs icmp9${NC}\n\n"
        fi
    fi

else
    warn "ℹ️ 已取消启动。您可以稍后运行 '$DOCKER_COMPOSE_CMD up -d' 启动。"
fi