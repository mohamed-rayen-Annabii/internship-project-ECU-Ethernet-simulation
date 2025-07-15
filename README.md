# ECU Simulation Environment

This project simulates communication between two ECUs using Linux namespaces and virtual Ethernet pairs.

## Structure
- `setup_netns.sh`: Automates network namespace setup
- `setup.md`: Manual setup guide
- `.gitlab-ci.yml`: CI/CD pipeline for testing setup

## Requirements
- Linux system with `iproute2`, `ping`, and `sudo` privileges
