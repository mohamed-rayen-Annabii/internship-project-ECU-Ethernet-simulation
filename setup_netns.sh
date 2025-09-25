#!/bin/bash

# Clean previous bridge if exists
ip link del br0 2>/dev/null || true

# Create namespaces
ip netns add ecu1
ip netns add ecu2

# Create veth pairs
ip link add veth1-br type veth peer name veth1
ip link add veth2-br type veth peer name veth2

# Attach one side to namespaces
ip link set veth1 netns ecu1
ip link set veth2 netns ecu2

# Create bridge
ip link add name br0 type bridge
ip link set br0 up

# Attach host-side veths to bridge
ip link set veth1-br master br0
ip link set veth2-br master br0
ip link set veth1-br up
ip link set veth2-br up

# Inside namespace: assign IPs
ip netns exec ecu1 ip addr add 10.0.0.1/24 dev veth1
ip netns exec ecu1 ip link set veth1 up
ip netns exec ecu1 ip link set lo up

ip netns exec ecu2 ip addr add 10.0.0.2/24 dev veth2
ip netns exec ecu2 ip link set veth2 up
ip netns exec ecu2 ip link set lo up

# Test communication
echo "Pinging ECU2 from ECU1..."
ip netns exec ecu1 ping -c 3 10.0.0.2

echo "Setup complete."

