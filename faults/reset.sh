#!/bin/bash
IFACE_OPT=${1:-"both"} # Default to both if no argument provided

echo "[*] Resetting fault injections on $IFACE_OPT..."

case "$IFACE_OPT" in
    veth1-br)
        sudo tc qdisc del dev veth1-br root 2>/dev/null || true
        ;;
    veth2-br)
        sudo tc qdisc del dev veth2-br root 2>/dev/null || true
        ;;
    both)
        for IFACE in veth1-br veth2-br; do
            sudo tc qdisc del dev $IFACE root 2>/dev/null || true
        done
        ;;
    *)
        echo "[!] Invalid interface option: $IFACE_OPT. Use veth1-br, veth2-br, or both."
        exit 1
        ;;
esac

ip netns exec ecu1 iptables -F OUTPUT || true
ip netns exec ecu2 iptables -F OUTPUT || true

echo "[✓] All faults reset on $IFACE_OPT."

