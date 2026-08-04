#!/usr/bin/env bash
#
# TurtleBot 4 PC development environment
# Target: Ubuntu 22.04 (Jammy) + ROS 2 Humble
#
# Installs:
#   - ROS 2 Humble Desktop / RViz
#   - TurtleBot 4 desktop packages
#   - Nav2 + SLAM Toolbox
#   - Keyboard teleoperation
#   - ROS 2 build/dependency tools
#   - Message/TF packages used by the custom frontier exploration node
#   - NumPy/Pandas/Matplotlib used by topic-frequency/CSV analysis scripts
#
# Usage:
#   chmod +x install_turtlebot4_pc_humble.sh
#   ./install_turtlebot4_pc_humble.sh
#
# Optional configuration:
#   TB4_DOMAIN_ID=0 \
#   TB4_RMW=rmw_fastrtps_cpp \
#   TB4_WS="$HOME/turtlebot4_ws" \
#   ./install_turtlebot4_pc_humble.sh
#
# To avoid editing ~/.bashrc:
#   SKIP_BASHRC=1 ./install_turtlebot4_pc_humble.sh
#
set -Eeuo pipefail

readonly ROS_DISTRO="humble"
readonly REQUIRED_UBUNTU_CODENAME="jammy"

TB4_DOMAIN_ID="${TB4_DOMAIN_ID:-0}"
TB4_RMW="${TB4_RMW:-rmw_fastrtps_cpp}"
TB4_WS="${TB4_WS:-$HOME/turtlebot4_ws}"
SKIP_BASHRC="${SKIP_BASHRC:-0}"

log() {
    printf '\n\033[1;34m[TB4 ENV]\033[0m %s\n' "$*"
}

warn() {
    printf '\n\033[1;33m[WARNING]\033[0m %s\n' "$*" >&2
}

die() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
    exit 1
}

on_error() {
    local exit_code=$?
    printf '\n\033[1;31m[ERROR]\033[0m Installation failed at line %s (exit %s).\n' \
        "${BASH_LINENO[0]}" "$exit_code" >&2
    exit "$exit_code"
}
trap on_error ERR

if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this script with sudo. Run it as a normal user; the script invokes sudo when needed."
fi

[[ -r /etc/os-release ]] || die "Cannot read /etc/os-release."
# shellcheck disable=SC1091
source /etc/os-release

UBUNTU_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"

if [[ "${ID:-}" != "ubuntu" ]]; then
    die "This script only supports Ubuntu. Detected: ${PRETTY_NAME:-unknown}."
fi

if [[ "$UBUNTU_CODENAME" != "$REQUIRED_UBUNTU_CODENAME" ]]; then
    die "Ubuntu 22.04 (jammy) is required for ROS 2 Humble. Detected: ${PRETTY_NAME:-unknown}."
fi

case "$TB4_RMW" in
    rmw_fastrtps_cpp|rmw_cyclonedds_cpp)
        ;;
    *)
        die "TB4_RMW must be rmw_fastrtps_cpp or rmw_cyclonedds_cpp."
        ;;
esac

if ! [[ "$TB4_DOMAIN_ID" =~ ^[0-9]+$ ]] || (( TB4_DOMAIN_ID < 0 || TB4_DOMAIN_ID > 232 )); then
    die "TB4_DOMAIN_ID must be an integer from 0 to 232."
fi

log "Ubuntu check passed: ${PRETTY_NAME}"
log "ROS distribution: ${ROS_DISTRO}"
log "ROS_DOMAIN_ID: ${TB4_DOMAIN_ID}"
log "RMW implementation: ${TB4_RMW}"
log "Workspace: ${TB4_WS}"

log "Installing locale and repository prerequisites..."
sudo apt-get update
sudo apt-get install -y \
    locales \
    software-properties-common \
    curl \
    ca-certificates \
    gnupg \
    lsb-release

sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

sudo add-apt-repository universe -y

log "Configuring the official ROS 2 apt repository..."
if dpkg-query -W -f='${Status}' ros2-apt-source 2>/dev/null | grep -q "install ok installed"; then
    log "ros2-apt-source is already installed."
elif grep -RqsE 'packages\.ros\.org/ros2/ubuntu|packages\.ros\.org/ros2-testing/ubuntu' \
    /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    # A working ROS 2 repository is already configured, so do not replace it.
    # This also supports machines that installed ROS 2 before ros2-apt-source
    # became the recommended repository configuration package.
    log "An existing ROS 2 apt repository was detected; keeping it unchanged."
else
    RELEASE_JSON="$(mktemp /tmp/ros-apt-source-release.XXXXXX.json)"
    ROS_APT_SOURCE_DEB="$(mktemp /tmp/ros2-apt-source.XXXXXX.deb)"

    # Download first, then parse the local file. Do not use curl | awk here:
    # with `set -o pipefail`, awk may exit after the first match and cause curl
    # to report error 23 because the pipe was closed early.
    curl -fsSL \
        -o "$RELEASE_JSON" \
        https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest

    ROS_APT_SOURCE_VERSION="$(
        awk -F'"' '/"tag_name"/ {print $4; exit}' "$RELEASE_JSON"
    )"

    [[ -n "$ROS_APT_SOURCE_VERSION" ]] \
        || die "Could not determine the latest ros2-apt-source release."

    curl -fL \
        -o "$ROS_APT_SOURCE_DEB" \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CODENAME}_all.deb"

    sudo apt-get install -y "$ROS_APT_SOURCE_DEB"
    rm -f "$RELEASE_JSON" "$ROS_APT_SOURCE_DEB"
fi

sudo apt-get update

log "Installing ROS 2 Humble and TurtleBot 4 packages..."
sudo apt-get install -y \
    ros-humble-desktop \
    ros-dev-tools \
    ros-humble-turtlebot4-desktop \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-slam-toolbox \
    ros-humble-teleop-twist-keyboard \
    ros-humble-tf2-tools \
    ros-humble-tf2-ros \
    ros-humble-tf2-geometry-msgs \
    ros-humble-nav2-msgs \
    ros-humble-nav-msgs \
    ros-humble-sensor-msgs \
    ros-humble-geometry-msgs \
    ros-humble-visualization-msgs \
    ros-humble-std-msgs \
    ros-humble-rmw-fastrtps-cpp \
    ros-humble-rmw-cyclonedds-cpp

log "Installing development and data-analysis tools..."
sudo apt-get install -y \
    build-essential \
    git \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    python3-colcon-common-extensions \
    python3-numpy \
    python3-pandas \
    python3-matplotlib

log "Initializing rosdep..."
if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    sudo rosdep init
else
    log "rosdep is already initialized."
fi
rosdep update

log "Creating the ROS 2 workspace..."
mkdir -p "${TB4_WS}/src"

if [[ "$SKIP_BASHRC" != "1" ]]; then
    log "Writing an idempotent TurtleBot 4 environment block to ~/.bashrc..."

    BASHRC="${HOME}/.bashrc"
    START_MARKER="# >>> turtlebot4 development environment >>>"
    END_MARKER="# <<< turtlebot4 development environment <<<"

    touch "$BASHRC"

    # Remove an older copy of this managed block, if present.
    sed -i "\|${START_MARKER}|,\|${END_MARKER}|d" "$BASHRC"

    cat >> "$BASHRC" <<EOF

${START_MARKER}
source /opt/ros/${ROS_DISTRO}/setup.bash

# These values must match the TurtleBot 4 Raspberry Pi/Create 3 setup.
export ROS_DOMAIN_ID=${TB4_DOMAIN_ID}
export RMW_IMPLEMENTATION=${TB4_RMW}

# Source the local workspace only after it has been built.
if [ -f "${TB4_WS}/install/setup.bash" ]; then
    source "${TB4_WS}/install/setup.bash"
fi
${END_MARKER}
EOF
else
    warn "SKIP_BASHRC=1: ~/.bashrc was not modified."
fi

log "Verifying the installation..."
# shellcheck disable=SC1091
source "/opt/ros/${ROS_DISTRO}/setup.bash"

command -v ros2 >/dev/null
ros2 pkg prefix turtlebot4_viz >/dev/null
ros2 pkg prefix nav2_bringup >/dev/null
ros2 pkg prefix slam_toolbox >/dev/null

cat <<EOF

Installation completed.

Open a new terminal, or run:
  source ~/.bashrc

Build your own workspace:
  cd "${TB4_WS}"
  rosdep install --from-paths src --ignore-src -r -y
  colcon build --symlink-install
  source install/setup.bash

Basic checks after the robot and PC are on the same network:
  ros2 topic list
  ros2 topic hz /scan
  ros2 topic echo /odom --once
  ros2 launch turtlebot4_viz view_robot.launch.py

Keyboard control:
  ros2 run teleop_twist_keyboard teleop_twist_keyboard

Mapping components:
  ros2 launch slam_toolbox online_async_launch.py
  ros2 launch nav2_bringup navigation_launch.py

Important:
  ROS_DOMAIN_ID and RMW_IMPLEMENTATION must match the robot.
  For the most reproducible setup, the PC and Raspberry Pi should use matching
  Ubuntu/ROS 2 versions.
EOF
