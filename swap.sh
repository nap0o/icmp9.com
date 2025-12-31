#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# fonts color
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
# fonts color


#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error:This script must be run as root!${Font}"
        exit 1
    fi
}

#检测ovz
ovz_no(){
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}Your VPS is based on OpenVZ，not supported!${Font}"
        exit 1
    fi
}

add_swap(){
echo -e "${Green}请输入需要添加的 Swap 值,单位为 MB ,建议为内存的 2 倍.(例如输入:4096)${Font}"
read -p "请输入 Swap 数值:" swapsize

#检查是否存在swapfile
grep -q "swap" /etc/fstab

#如果不存在将为其创建swap
if [ $? -ne 0 ]; then
        echo -e "${Green}swapfile 未发现，正在为其创建 swapfile${Font}"
    dd if=/dev/zero of=/swapfile bs=1M count=${swapsize}
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
         echo -e "${Green}swap 创建成功，并查看信息：${Font}"
         cat /proc/swaps
         cat /proc/meminfo | grep Swap
else
        echo -e "${Red}swapfile 已存在，swap 设置失败，请先运行脚本删除 swap 后重新设置！${Font}"
fi
}

del_swap(){
#检查是否存在swapfile
grep -q "swap" /etc/fstab

#如果存在就将其移除
if [ $? -eq 0 ]; then
        echo -e "${Green}swapfile 已发现，正在将其移除...${Font}"
        sed -i '/swap/d' /etc/fstab
        echo "3" > /proc/sys/vm/drop_caches
        swapoff -a
        rm -f /swapfile
    echo -e "${Green}swap 已删除！${Font}"
else
        echo -e "${Red}swapfile 未发现，swap 删除失败！${Font}"
fi
}

#开始菜单
main(){
root_need
ovz_no
clear
echo -e "———————————————————————————————————————"
echo -e "${Green}一键添加/删除swap脚本${Font}"
echo -e "${Green}1、添加swap${Font}"
echo -e "${Green}2、删除swap${Font}"
echo -e "———————————————————————————————————————"
read -p "请输入数字 [1-2]:" num
case "$num" in
    1)
    add_swap
    ;;
    2)
    del_swap
    ;;
    *)
    clear
    echo -e "${Green}请输入正确数字 [1-2]${Font}"
    sleep 2s
    main
    ;;
    esac
}
main