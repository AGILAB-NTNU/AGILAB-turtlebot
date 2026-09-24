# [Project Name]

[繁體中文](README_zh.md) | English

> **Note**: This repository was bootstrapped with the [AGILAB Software Template](https://github.com/AGILAB-NTNU/SoftwareTemplate).

## Overview

This project provides the ROS 2 environment, communication demos, LiDAR control, SLAM, navigation, and autonomous exploration for TurtleBot 4.

## Installation

### Prerequisites

- Ubuntu 22.04
- ROS 2 Humble
- TurtleBot 4

### Setup Instructions

1. **Clone the repository:**

   ```bash
   git clone https://github.com/AGILAB-NTNU/AGILAB-turtlebot.git
   cd AGILAB-turtlebot
   ```

2. **Set up the TurtleBot 4 environment:**

   ```bash
   cd scripts
   chmod +x turtlebot_env.sh
   ./turtlebot_env.sh
   ```

   The `docs/` folder contains the detailed TurtleBot 4 environment setup guide.

3. **Install pre-commit hooks (Optional):**

   ```bash
   pre-commit install
   ```

## Project Structure

```text
.
├── configs/                    # Configuration files
├── data/                       # Datasets and logs
├── docker/                     # Docker configurations
├── docs/                       # Documentation
├── notebooks/                  # Jupyter Notebooks
├── ros2_ws/
│   └── turtlebot4_control/     # TurtleBot 4 ROS 2 workspace
├── scripts/                    # Environment setup scripts
├── src/                        # Core Python package
└── tests/                      # Automated tests
```

## Usage

### Build Control Workspace

```bash
cd ros2_ws/turtlebot4_control
colcon build
source install/setup.bash
```

### Topic Demo

Run in two terminals:

```bash
ros2 run ros2_comm_demo topic_subscriber
ros2 run ros2_comm_demo topic_publisher
```

### Service Demo

Run in two terminals:

```bash
ros2 run ros2_comm_demo service_server
ros2 run ros2_comm_demo service_client
```

### Action Demo

Run in two terminals:

```bash
ros2 run ros2_comm_demo action_server
ros2 run ros2_comm_demo action_client
```

### LiDAR Control Demo

```bash
ros2 run tb4_lidar_control forward_stop_beep_node
```

### SLAM, Navigation and AFE Demo

Run in four terminals:

```bash
ros2 launch turtlebot4_navigation slam.launch.py
```

```bash
ros2 launch turtlebot4_navigation nav2.launch.py
```

```bash
ros2 launch turtlebot4_viz view_robot.launch.py
```

```bash
ros2 run autonomous_exploration control_tb4
```

## Contributing

This project follows the unified AGILAB development workflow. Before contributing, please refer to the [AGILAB Software Lab Guide](https://agilab-ntnu.github.io/AGILAB_Software_Lab_Guide/en/contributing/) for branching strategies and coding standards.

## Citation

If you use this work in your research, please cite it as follows:

```bibtex
@article{author_year_title,
  author = {Author, First and Author, Second},
  title = {Project Title},
  journal = {Journal or Conference Name},
  year = {2026},
  url = {https://github.com/AGILAB-NTNU/AGILAB-turtlebot}
}
```

## License

*(Add your license information here)*
