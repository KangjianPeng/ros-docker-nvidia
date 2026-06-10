ARG ROS_DISTRO=noetic

# 1. 基于官方桌面完整版镜像，可通过 --build-arg ROS_DISTRO=noetic|humble 切换
FROM osrf/ros:${ROS_DISTRO}-desktop-full

ARG ROS_DISTRO
ENV ROS_DISTRO=${ROS_DISTRO}

# 2. 安装 NVIDIA 驱动所需的基础库、X11 测试工具和常用开发工具
RUN apt-get update && apt-get install -y \
    libglvnd0 libgl1 libglx0 libegl1 mesa-utils x11-apps \
    git fzf curl wget neovim less build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. 开启 NVIDIA 容器透传能力
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute,display

# 4. 强制 Qt/RViz 走 Xwayland，防止和纯 Wayland 冲突导致宿主机 KDE 崩溃
ENV QT_QPA_PLATFORM=xcb

# 5. 强制 3D 渲染请求发送给 NVIDIA 库，防止回退到 Mesa
ENV __NV_PRIME_RENDER_OFFLOAD=1
ENV __GLX_VENDOR_LIBRARY_NAME=nvidia

# Gaboze和IGN的地址设置
ENV IGN_IP=127.0.0.1
ENV GZ_IP=127.0.0.1
ENV IGN_IPCS_DISABLE=1

# 6. 通过 profile.d 给登录 shell 自动初始化 ROS 环境
RUN printf '%s\n' \
    '#!/bin/sh' \
    'if [ -z "${ROS_ENV_INITIALIZED:-}" ] && [ -n "${ROS_DISTRO:-}" ]; then' \
    '    if [ -n "${BASH_VERSION:-}" ] && [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then' \
    '        . "/opt/ros/${ROS_DISTRO}/setup.bash"' \
    '        export ROS_ENV_INITIALIZED=1' \
    '    elif [ -f "/opt/ros/${ROS_DISTRO}/setup.sh" ]; then' \
    '        . "/opt/ros/${ROS_DISTRO}/setup.sh"' \
    '        export ROS_ENV_INITIALIZED=1' \
    '    fi' \
    'fi' \
    > /etc/profile.d/ros_setup.sh \
    && chmod +x /etc/profile.d/ros_setup.sh
