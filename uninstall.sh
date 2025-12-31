#!/bin/sh

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 辅助函数 ---
info() { printf "${GREEN}[INFO] %s${NC}\n" "$1"; }
warn() { printf "${YELLOW}[WARN] %s${NC}\n" "$1"; }
error() { printf "${RED}[ERROR] %s${NC}\n" "$1"; }

# --- 0. Root 检查 ---
if [ "$(id -u)" != "0" ]; then
    error "❌ 请使用 Root 用户运行此脚本！"
    exit 1
fi

printf "${GREEN}=============================================${NC}\n"
printf "${GREEN}      ICMP9 聚合节点一键卸载/清理脚本            ${NC}\n"
printf "${GREEN}=============================================${NC}\n"

printf "\n${RED}⚠️  警告：此操作将执行以下动作：${NC}\n"
printf "1. 停止并删除 icmp9 相关 Docker 容器\n"
printf "2. 停止 Cloudflared 服务\n"
printf "3. 智能检测 Nginx：仅当配置被修改过时才停止并卸载\n"
printf "4. 清理相关文件和目录\n"
printf "\n确认要执行卸载吗？ [y/N]: "
read -r CONFIRM
case "$CONFIRM" in
    [yY][eE][sS]|[yY]) 
        printf "${GREEN}>>> 开始执行卸载...${NC}\n"
        ;;
    *)
        printf "${YELLOW}>>> 已取消。${NC}\n"
        exit 1
        ;;
esac

# --- 1. 清理 Docker 部署 (独立模块) ---
if command -v docker >/dev/null 2>&1; then
    info "🐳 检测 Docker 环境是否启动 icmp9 相关容器..."
    if [ -n "$(docker ps -aq -f name="^/icmp9$")" ]; then
        docker stop icmp9 >/dev/null 2>&1
        docker rm -f icmp9 >/dev/null 2>&1
        info "✅ 已成功删除 icmp9 容器"
    else
        info "ℹ️ 未检测到 icmp9 容器，跳过删除操作"
    fi
    if [ -n "$(docker images -q nap0o/icmp9)" ]; then
        docker rmi -f nap0o/icmp9:nginx >/dev/null 2>&1
        info "✅ 已成功删除 nap0o/icmp9:nginx 镜像"
    fi
fi

# --- 2. 清理核心业务服务 (Cloudflared/icmp9) ---
info "ℹ️ 正在清理核心业务服务 (Cloudflared/icmp9)..."

kill_process() { pkill -f "$1" >/dev/null 2>&1; }

# --- 1. 停止并清理服务 ---
if [ -f /etc/alpine-release ]; then
    # === Alpine (OpenRC) ===
    # 清理 Cloudflared
    if [ -f "/etc/init.d/cloudflared" ]; then
        rc-service cloudflared stop >/dev/null 2>&1
        rc-update del cloudflared default >/dev/null 2>&1
        rm -f /etc/init.d/cloudflared
        info "✅ Cloudflared 服务已停止并移除"
    fi

else
    # === Debian/Ubuntu (Systemd) ===
    # 清理 Cloudflared
    if [ -f "/etc/systemd/system/cloudflared.service" ]; then
        systemctl stop cloudflared >/dev/null 2>&1
        systemctl disable cloudflared >/dev/null 2>&1
        rm -f /etc/systemd/system/cloudflared.service
        info "✅ Cloudflared 服务已停止并移除"
    fi
    
    systemctl daemon-reload >/dev/null 2>&1
fi

# 强杀残留进程 (双重保险，不依赖服务文件)
kill_process "cloudflared tunnel"
kill_process "icmp9"

# --- 3. 清理文件与目录 ---

# 清理工作目录
if [ -d "/root/icmp9" ]; then
    rm -rf "/root/icmp9"
    info "✅ 已删除工作目录 /root/icmp9"
fi

# 清理 icmp9 二进制
if [ -f "/usr/bin/icmp9" ]; then
    rm -f "/usr/bin/icmp9"
    info "✅ 已删除 icmp9 二进制文件"
fi

# 清理 cloudflared 二进制
if [ -f "/usr/bin/cloudflared" ]; then
    rm -f "/usr/bin/cloudflared"
    info "✅ 已删除 Cloudflared 二进制文件"
fi

info "✅ 完成清理核心业务服务"

# --- 4. 智能处理 Nginx ---
NGINX_CONF="/etc/nginx/nginx.conf"
info "🔍 正在检查 Nginx 配置文件状态..."

if [ -f "$NGINX_CONF" ]; then
    # 检查特征码
    if  grep -q "/root/icmp9/subscribe" "$NGINX_CONF" || grep -q "/root/subscribe" "$NGINX_CONF"; then
        warn "ℹ️ 检测到 /etc/nginx/nginx.conf 包含 ICMP9 配置特征。"
        info "ℹ️ 正在停止 Nginx 服务并执行彻底卸载..."
        
        if [ -f /etc/alpine-release ]; then
            # Alpine 操作
            rc-service nginx stop >/dev/null 2>&1
            rc-update del nginx default >/dev/null 2>&1
            apk del nginx >/dev/null 2>&1
            rm -rf /etc/nginx >/dev/null 2>&1
            info "✅ Nginx 已停止并卸载 (Alpine)"
        else
            # Debian/Ubuntu 操作
            systemctl stop nginx >/dev/null 2>&1
            systemctl disable nginx >/dev/null 2>&1
            apt-get purge -y nginx nginx-common nginx-full >/dev/null 2>&1
            apt-get autoremove -y >/dev/null 2>&1
            rm -rf /etc/nginx >/dev/null 2>&1
            info "✅ Nginx 已停止并卸载 (Debian/Ubuntu)"
        fi
    else
        info "ℹ️ 检测到 Nginx 配置文件未包含 ICMP9 特征，跳过 Nginx 清理操作"
    fi
else
    info "ℹ️ 未检测到配置文件，跳过 Nginx 清理操作。"
fi

# --- 5. 完成 ---
printf "\n${GREEN}✅ ICMP聚合节点脚本卸载完成！${NC}\n\n"
