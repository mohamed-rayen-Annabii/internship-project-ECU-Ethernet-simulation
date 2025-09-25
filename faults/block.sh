#!/bin/bash
set -e
LOG="test/block.log"
IFACE_OPT=${1:-"both"} # Default to both if no argument provided

echo "[*] Blocking ECU1 from sending packets to ECU2..." | tee -a "$LOG"

# Block uses iptables in ecu1 namespace, interface option doesn't affect this
# but we keep the parameter for consistency
ip netns exec ecu1 iptables -A OUTPUT -d 10.0.0.2 -j DROP

echo "PASSED: ECU1 blocked (interface option: $IFACE_OPT)" > "$LOG"
echo "block" > test/block.flag
echo "[✓] Block injected (interface option: $IFACE_OPT)."

