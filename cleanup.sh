#!/bin/bash

# Script to clean up ECU simulation setup

echo "[+] Cleaning up ECU simulation..."

# Check and delete namespaces if they exist
for ns in ecu1 ecu2; do
    if ip netns list | grep -q "$ns"; then
        echo "    - Deleting namespace: $ns"
        ip netns del "$ns"
    else
        echo "    - Namespace $ns does not exist, skipping."
    fi
done

# Check and delete veth interfaces if still on host (optional safety)
for veth in veth1 veth2; do
    if ip link show | grep -q "$veth"; then
        echo "    - Deleting veth interface: $veth"
        ip link delete "$veth"
    fi
done

echo "[✓] Cleanup complete."
