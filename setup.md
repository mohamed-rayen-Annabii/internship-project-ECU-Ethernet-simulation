# ECU Simulation Environment Setup

This document describes how to simulate basic ECU-to-ECU communication using Linux network namespaces and virtual Ethernet interfaces.

## Requirements

- Linux (Ubuntu/Debian)
- `iproute2`, `net-tools`, `ping`, `git`
  
Install if needed:
```bash
sudo apt update
sudo apt install -y iproute2 net-tools iputils-ping git
