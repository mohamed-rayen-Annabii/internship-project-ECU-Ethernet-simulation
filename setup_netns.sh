#!/bin/bash

# Create network namespaces for ECU1 and ECU2
ip netns add ecu1
ip netns add ecu2

# Create a virtual Ethernet pair (veth1 <-> veth2)
ip link add veth1 type veth peer name veth2

# Assign each veth interface to a namespace
ip link set veth1 netns ecu1
ip link set veth2 netns ecu2

# Configure ECU1 interface
ip netns exec ecu1 ip addr add 10.0.0.1/24 dev veth1
ip netns exec ecu1 ip link set veth1 up
ip netns exec ecu1 ip link set lo up

# Configure ECU2 interface
ip netns exec ecu2 ip addr add 10.0.0.2/24 dev veth2
ip netns exec ecu2 ip link set veth2 up
ip netns exec ecu2 ip link set lo up

# Optional: test communication
echo "Pinging ECU2 from ECU1..."
ip netns exec ecu1 ping -c 3 10.0.0.2

echo "Setup complete."
