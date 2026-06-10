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

# 6. 配置入口脚本，每次启动自动加载对应 ROS 发行版环境变量
RUN echo '#!/bin/bash\nset -e\nsource /opt/ros/${ROS_DISTRO}/setup.bash\nexec "$@"' > /entrypoint.sh \
    && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
