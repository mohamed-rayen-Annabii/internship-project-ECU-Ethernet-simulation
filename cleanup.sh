#!/bin/bash

echo "[+] Cleaning up ECU simulation..."

for ns in ecu1 ecu2; do
    ip netns del "$ns" 2>/dev/null && echo "  - Deleted namespace: $ns"
done

for intf in veth1 veth2 veth1-br veth2-br br0; do
    ip link del "$intf" 2>/dev/null && echo "  - Deleted interface: $intf"
done

echo "[✓] Cleanup complete."

