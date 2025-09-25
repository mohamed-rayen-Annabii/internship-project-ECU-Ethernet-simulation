#!/bin/bash
set -e
LOG="test/corrupt.log"
IFACE_OPT=${1:-"both"} # Default to both if no argument provided

apply_corruption() {
    local IFACE=$1
    echo "[+] Injecting 10% corruption on $IFACE..."
    sudo tc qdisc del dev $IFACE root 2>/dev/null || true
    sudo tc qdisc add dev $IFACE root netem corrupt 10%
}

case "$IFACE_OPT" in
    veth1-br)
        apply_corruption "veth1-br"
        echo "PASSED: 10% corruption injected on veth1-br" > "$LOG"
        ;;
    veth2-br)
        apply_corruption "veth2-br"
        echo "PASSED: 10% corruption injected on veth2-br" > "$LOG"
        ;;
    both)
        apply_corruption "veth1-br"
        apply_corruption "veth2-br"
        echo "PASSED: 10% corruption injected on both veth1-br and veth2-br" > "$LOG"
        ;;
    *)
        echo "[!] Invalid interface option: $IFACE_OPT. Use veth1-br, veth2-br, or both."
        exit 1
        ;;
esac

echo "corrupt" > test/corrupt.flag
echo "[✓] Corruption injected on $IFACE_OPT."

