#!/bin/bash

# Exit on any error
set -e

# Clean up existing namespaces and interfaces if they exist
ip netns del ecu3 2>/dev/null || true
ip netns del ecu4 2>/dev/null || true
ip link del veth-ecu3 2>/dev/null || true

# Create network namespaces
ip netns add ecu3
ip netns add ecu4

# Create virtual Ethernet pair
ip link add veth-ecu3 type veth peer name veth-ecu4

# Assign veth interfaces to namespaces
ip link set veth-ecu3 netns ecu3
ip link set veth-ecu4 netns ecu4

# Assign IP addresses
ip netns exec ecu3 ip addr add 192.168.1.1/24 dev veth-ecu3
ip netns exec ecu4 ip addr add 192.168.1.2/24 dev veth-ecu4

# Bring interfaces up
ip netns exec ecu3 ip link set veth-ecu3 up
ip netns exec ecu4 ip link set veth-ecu4 up

# Enable loopback interfaces in namespaces
ip netns exec ecu3 ip link set lo up
ip netns exec ecu4 ip link set lo up

# Inject corruption on ecu3's veth interface (10% packet corruption)
ip netns exec ecu3 tc qdisc add dev veth-ecu3 root netem corrupt 10%

# Test connectivity with ping from ecu3 to ecu4
echo "Testing connectivity from ecu3 to ecu4 with corruption..."
ip netns exec ecu3 ping -c 5 192.168.1.2

# Remove corruption for comparison
echo "Removing corruption for comparison..."
ip netns exec ecu3 tc qdisc del dev veth-ecu3 root
ip netns exec ecu3 ping -c 5 192.168.1.2

# Cleanup (uncomment to delete namespaces after testing)
# ip netns exec ecu3 ip link del veth-ecu3
# ip netns del ecu3
# ip netns del ecu4

echo "Setup complete. Use 'ip netns exec ecu3' or 'ip netns exec ecu4' to interact with namespaces."
