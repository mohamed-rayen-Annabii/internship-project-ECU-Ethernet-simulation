#!/bin/bash
set -e
LOG="test/loss.log"
IFACE_OPT=${1:-"both"} # Default to both if no argument provided

apply_loss() {
    local IFACE=$1
    echo "[+] Injecting 20% packet loss on $IFACE..."
    sudo tc qdisc del dev $IFACE root 2>/dev/null || true
    sudo tc qdisc add dev $IFACE root netem loss 20%
}

case "$IFACE_OPT" in
    veth1-br)
        apply_loss "veth1-br"
        echo "PASSED: 20% packet loss injected on veth1-br" > "$LOG"
        ;;
    veth2-br)
        apply_loss "veth2-br"
        echo "PASSED: 20% packet loss injected on veth2-br" > "$LOG"
        ;;
    both)
        apply_loss "veth1-br"
        apply_loss "veth2-br"
        echo "PASSED: 20% packet loss injected on both veth1-br and veth2-br" > "$LOG"
        ;;
    *)
        echo "[!] Invalid interface option: $IFACE_OPT. Use veth1-br, veth2-br, or both."
        exit 1
        ;;
esac

echo "loss" > test/loss.flag
echo "[✓] Packet loss injected on $IFACE_OPT."

