#!/bin/bash
set -e
LOG="test/delay.log"
IFACE_OPT=${1:-"both"} # Default to both if no argument provided

apply_delay() {
    local IFACE=$1
    echo "[+] Injecting 300ms delay on $IFACE..."
    sudo tc qdisc del dev $IFACE root 2>/dev/null || true
    sudo tc qdisc add dev $IFACE root netem delay 300ms
}

case "$IFACE_OPT" in
    veth1-br)
        apply_delay "veth1-br"
        echo "PASSED: 300ms delay injected on veth1-br" > "$LOG"
        ;;
    veth2-br)
        apply_delay "veth2-br"
        echo "PASSED: 300ms delay injected on veth2-br" > "$LOG"
        ;;
    both)
        apply_delay "veth1-br"
        apply_delay "veth2-br"
        echo "PASSED: 300ms delay injected on both veth1-br and veth2-br" > "$LOG"
        ;;
    *)
        echo "[!] Invalid interface option: $IFACE_OPT. Use veth1-br, veth2-br, or both."
        exit 1
        ;;
esac

echo "delay" > test/delay.flag
echo "[✓] Delay injected on $IFACE_OPT."

