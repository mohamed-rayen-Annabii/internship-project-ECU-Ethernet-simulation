#!/bin/bash
set -e

IFACE_OPT=$1
shift # Remove the interface option from arguments

FLAG_DIR="test"
LOG_DIR="test"
mkdir -p "$FLAG_DIR" "$LOG_DIR"

TC_CMD_VETH1="sudo tc qdisc add dev veth1-br root netem"
TC_CMD_VETH2="sudo tc qdisc add dev veth2-br root netem"
BLOCK_CMD=""
COMBO=$(IFS=+; echo "$*")
details=()
tc_needed=false

for arg in "$@"; do
    case "$arg" in
        delay)
            TC_CMD_VETH1="$TC_CMD_VETH1 delay 300ms"
            TC_CMD_VETH2="$TC_CMD_VETH2 delay 300ms"
            details+=("300ms delay injected")
            tc_needed=true
            ;;
        loss)
            TC_CMD_VETH1="$TC_CMD_VETH1 loss 10%"
            TC_CMD_VETH2="$TC_CMD_VETH2 loss 10%"
            details+=("10% packet loss injected")
            tc_needed=true
            ;;
        corrupt|corruption)
            TC_CMD_VETH1="$TC_CMD_VETH1 corrupt 30%"
            TC_CMD_VETH2="$TC_CMD_VETH2 corrupt 30%"
            details+=("30% corruption injected")
            tc_needed=true
            ;;
        block)
            BLOCK_CMD="sudo ip netns exec ecu1 iptables -A OUTPUT -d 10.0.0.2 -j DROP"
            details+=("ECU1 blocked")
            ;;
        *)
            echo "[!] Unknown fault type: $arg"
            exit 1
            ;;
    esac
done

if $tc_needed; then
    case "$IFACE_OPT" in
        veth1-br)
            sudo tc qdisc del dev veth1-br root 2>/dev/null || true
            echo "[*] Applying netem: $TC_CMD_VETH1 on veth1-br"
            eval "$TC_CMD_VETH1"
            ;;
        veth2-br)
            sudo tc qdisc del dev veth2-br root 2>/dev/null || true
            echo "[*] Applying netem: $TC_CMD_VETH2 on veth2-br"
            eval "$TC_CMD_VETH2"
            ;;
        both)
            sudo tc qdisc del dev veth1-br root 2>/dev/null || true
            sudo tc qdisc del dev veth2-br root 2>/dev/null || true
            echo "[*] Applying netem: $TC_CMD_VETH1 on veth1-br"
            eval "$TC_CMD_VETH1"
            echo "[*] Applying netem: $TC_CMD_VETH2 on veth2-br"
            eval "$TC_CMD_VETH2"
            ;;
        *)
            echo "[!] Invalid interface option for combo: $IFACE_OPT. Use veth1-br, veth2-br, or both."
            exit 1
            ;;
    esac
fi

if [[ -n "$BLOCK_CMD" ]]; then
    sudo ip netns exec ecu1 iptables -F OUTPUT 2>/dev/null || true
    echo "[*] Applying block: $BLOCK_CMD"
    eval "$BLOCK_CMD"
fi

FLAG_FILE="$FLAG_DIR/$COMBO.flag"
touch "$FLAG_FILE"

LOG_FILE="$LOG_DIR/$COMBO.log"
detail=$(IFS=", "; echo "${details[*]}")
echo "PASSED: $detail on $IFACE_OPT" > "$LOG_FILE"

