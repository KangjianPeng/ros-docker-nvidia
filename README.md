# ros-docker-nvidia

## Intro

构建带图形界面支持的 ROS 开发镜像，目标是在 Arch Linux 宿主机上通过 Docker 和 Distrobox 快速启动可用的 ROS 环境。
当前提供同一份 `Dockerfile` 对 `ROS1 Noetic` 和 `ROS2 Humble` 的支持，并包含 NVIDIA 显卡透传、Xwayland 兼容和一些常用开发工具配置。

## 第 1 步：确保已安装正确的 NVIDIA 闭源驱动

由于 Linux 内核更新频繁，在 Arch 上推荐使用 dkms 版本的显卡驱动
打开Host主机终端，执行：

```bash
# 安装基础驱动、DKMS 模块以及工具包
sudo pacman -S nvidia-dkms nvidia-utils linux-headers
```

> 需要确保Host主机的nvidia驱动调用正常

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

安装 nvidia-container-toolkit。

```bash
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

在跑 ROS 之前，测试 Docker 能不能正常读取到显卡。
在终端运行：

```bash
docker run --rm --runtime=nvidia --gpus all osrf/ros:noetic-desktop-full nvidia-smi
```

如果终端打印出了你熟悉的 NVIDIA-SMI 表格（包含你的显卡型号、显存等信息），运行正常

## 1. 首先，手动构建镜像

在 Dockerfile 所在目录执行。这个 Dockerfile 现在同时支持 `ROS1 Noetic` 和 `ROS2 Humble` 以及其他发行版，通过 `ROS_DISTRO` 切换：

### ROS1 Noetic

```bash
docker build --build-arg ROS_DISTRO=noetic -t ros-noetic .
```

### ROS2 Humble

```bash
docker build --build-arg ROS_DISTRO=humble -t ros-humble .
```

## 2. 使用 Distrobox 创建容器（必须加 --nvidia 参数）

### ROS1 Noetic

```bash
distrobox create --name ros-noetic-env --image ros-noetic --nvidia
```

### ROS2 Humble

```bash
distrobox create --name ros-humble-env --image ros-humble --nvidia
```

## 3. 进入并开发

### ROS1 Noetic

```bash
distrobox enter ros-noetic-env
```

### ROS2 Humble

```bash
distrobox enter ros-humble-env
```
