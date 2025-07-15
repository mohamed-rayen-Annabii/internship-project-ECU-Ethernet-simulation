# ECU Simulation Setup

This simulates communication between two ECUs using Linux namespaces and virtual ethernet (veth).

## Files

- `ecu1.cpp`: UDP client sending "status OK" every second.
- `ecu2.cpp`: UDP server receiving messages on port 9090.
- `setup.sh`: Sets up namespaces, veth pairs, assigns IPs.
- `cleanup.sh`: Tears down the simulation cleanly.
- `Makefile`: For compiling both ECUs.
- `run_ecu1.sh`, `run_ecu2.sh`: Start ECU programs in their namespaces.

## Setup

```bash
sudo ./setup.sh
make
sudo ./run_ecu2.sh   # In one terminal
sudo ./run_ecu1.sh   # In another
