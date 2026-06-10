# 宿主机前置准备：Arch Linux + NVIDIA + Docker 引擎打通

## 第 1 步：确保已安装正确的 NVIDIA 闭源驱动

由于 Linux 内核更新频繁，在 Arch 上极其推荐使用 dkms 版本的显卡驱动，防止内核升级后驱动失效。
打开宿主机终端，执行：

```bash
# 安装基础驱动、DKMS 模块以及工具包
sudo pacman -S nvidia-dkms nvidia-utils linux-headers
```

> （注：由于你已经在运行纯 Wayland 的 KDE Plasma，你需要确保你的内核启动参数中已经添加了 nvidia_drm.modeset=1，这是 NVIDIA 在 Wayland 下正常工作的基础。一般在 /etc/default/grub 的 GRUB_CMDLINE_LINUX_DEFAULT 中设置，并执行了 sudo grub-mkconfig -o /boot/grub/grub.cfg）

## 第 2 步：安装 Docker 及其依赖

安装 Docker 本身，并且确保你的当前用户被加入了 docker 用户组（这样以后运行 docker 命令就不需要每次都敲 sudo 了）：

```bash
# 1. 安装 docker
sudo pacman -S docker distrobox

# 2. 启动并设置开机自启
sudo systemctl enable --now docker

# 3. 将当前用户加入 docker 组（注意：执行完这句后，需要重启电脑或注销重新登录才能生效）
sudo usermod -aG docker $USER
```

## 第 3 步：安装 NVIDIA 容器工具（最核心的桥梁）

这一步是告诉容器如何合法调用宿主机的显卡。以前的老教程会让你装 nvidia-docker2（已废弃），现在的官方标准做法是安装 nvidia-container-toolkit。

```bash
# Arch 官方仓库已经收录了这个包，直接 pacman 安装
sudo pacman -S nvidia-container-toolkit
```

## 第 4 步：将 NVIDIA Runtime 注入 Docker 配置

解决 unknown or invalid runtime name: nvidia 报错的关键
需要让 NVIDIA 工具自动修改 Docker 的配置文件 /etc/docker/daemon.json。

```bash
# 自动配置 Docker 引擎
sudo nvidia-ctk runtime configure --runtime=docker

# 配置完成后，必须重启 Docker 服务让其重新读取配置
sudo systemctl restart docker
```

## 第 5 步：快速验证宿主机通道是否打通（可选但推荐）

在跑 ROS 之前，我们先用一个极其轻量级的官方测试镜像，看看 Docker 能不能正常读取到显卡。
在终端运行：

```bash
docker run --rm --runtime=nvidia --gpus all osrf/ros:noetic-desktop-full nvidia-smi
```

如果终端打印出了你熟悉的 NVIDIA-SMI 表格（包含你的显卡型号、显存等信息），那么恭喜你！宿主机的底层配置已经完美无瑕！

## 1. 首先，手动用上面的 Dockerfile 构建一次基础镜像：

在 Dockerfile 所在目录执行：

```bash
docker build -t ros-noetic .
```

## 2. 使用 Distrobox 创建容器（必须加 --nvidia 参数）：

```bash
distrobox create --name ros-env --image ros-noetic-wayland-base --nvidia
```

## 3. 随时进入并开发：

```bash
distrobox enter ros-env
```
