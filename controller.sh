#!/bin/bash
set -e

# Paths and Configs
FAULT_SCRIPT_DIR="./faults"
ECU1="./build/ecu1"
ECU2="./build/ecu2"
LOG_DIR="./logs"
FLAG_DIR="./test"
mkdir -p "$LOG_DIR" "$FLAG_DIR"

# Colors
# Colors (ANSI codes)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ------------------------
# Functions
# ------------------------

function start_simulation() {
    echo -e "${YELLOW}[*] Setting up ECU network simulation...${NC}"
    sudo ./cleanup.sh || true
    sudo ./setup_netns.sh
    echo -e "${GREEN}[+] Network simulation started.${NC}"
}

function run_ecus() {
    echo -e "${YELLOW}[*] Running ECU programs...${NC}"

    # Check and install \'unbuffer\' if missing
    if ! command -v unbuffer &> /dev/null; then
        echo "[!] \'unbuffer\' not found. Installing..."
        sudo apt install -y expect
    fi

    # Launch ECU1 and ECU2 in their namespaces, pipe output to log files
    sudo ip netns exec ecu1 unbuffer "$ECU1" | tee "$LOG_DIR/ecu1.log" &
    ECU1_PID=$!
    sudo ip netns exec ecu2 unbuffer "$ECU2" | tee "$LOG_DIR/ecu2.log" &
    ECU2_PID=$!

    echo $ECU1_PID > .ecu1_pid
    echo $ECU2_PID > .ecu2_pid

    echo -e "${GREEN}[+] ECU1 PID: $ECU1_PID | ECU2 PID: $ECU2_PID${NC}"
}

function inject_fault() {
    FAULT_TYPE=$1
    IFACE_OPT=$2 # New argument for interface option
    echo -e "${YELLOW}[*] Injecting fault: $FAULT_TYPE on $IFACE_OPT${NC}"
    case "$FAULT_TYPE" in
        loss|delay|corruption|corrupt|block)
            sudo "$FAULT_SCRIPT_DIR/$FAULT_TYPE.sh" "$IFACE_OPT"
            ;;
        *)
            echo -e "${RED}[!] Unknown fault type: $FAULT_TYPE${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}[✓] Fault \'$FAULT_TYPE\' injected on $IFACE_OPT.${NC}"
}

function inject_faults() {
    FAULT_TYPES=()
    IFACE_OPT="both" # Default interface option

    # Parse arguments for fault types and interface option
    for arg in "$@"; do
        if [[ "$arg" == "--iface="* ]]; then
            IFACE_OPT="${arg#*--iface=}"
        else
            FAULT_TYPES+=("$arg")
        fi
    done

    # Remove the first element (the 'inject' command itself)
    FAULT_TYPES=("${FAULT_TYPES[@]:1}")

    if [ ${#FAULT_TYPES[@]} -eq 0 ]; then
        echo -e "${RED}[!] No fault types specified for injection.${NC}"
        exit 1
    fi

    if [ ${#FAULT_TYPES[@]} -eq 1 ]; then
        # Single fault: use existing fault script
        inject_fault "${FAULT_TYPES[0]}" "$IFACE_OPT"
    else
        # Multiple faults: use inject_combo.sh
        COMBO=$(IFS=+; echo "${FAULT_TYPES[@]}")
        echo -e "${YELLOW}[*] Injecting combined faults: $COMBO on $IFACE_OPT${NC}"
        sudo "./inject_combo.sh" "$IFACE_OPT" "${FAULT_TYPES[@]}"
        echo -e "${GREEN}[✓] Combined faults injected: $COMBO on $IFACE_OPT.${NC}"
    fi
}

function reset_faults() {
    IFACE_OPT=$1 # Optional argument for interface option
    echo -e "${YELLOW}[*] Resetting all fault injections on $IFACE_OPT...${NC}"
    sudo "$FAULT_SCRIPT_DIR/reset.sh" "$IFACE_OPT"
    echo -e "${GREEN}[✓] Faults reset on $IFACE_OPT.${NC}"
}

function stop_simulation() {
    echo -e "${YELLOW}[*] Cleaning up simulation...${NC}"

    # Kill ECU1 and ECU2 if running
    if [[ -f .ecu1_pid ]]; then
        kill -9 $(cat .ecu1_pid) 2>/dev/null || true
        rm -f .ecu1_pid
    fi
    if [[ -f .ecu2_pid ]]; then
        kill -9 $(cat .ecu2_pid) 2>/dev/null || true
        rm -f .ecu2_pid
    fi

    # Force kill in case PID files were stale or missing
    sudo pkill -f ./build/ecu1 || true
    sudo pkill -f ./build/ecu2 || true

    sudo "$FAULT_SCRIPT_DIR/reset.sh" "both"
    sudo ./cleanup.sh

    echo -e "${GREEN}[+] Simulation stopped.${NC}"
    echo -e "${YELLOW}[*] Generating test summary...${NC}"
    ./test/generate_summary.sh
    rm -f "$FLAG_DIR"/*.flag
    echo -e "${GREEN}[+] Summary written to test/results.md${NC}"
}

function help_menu() {
    echo -e "${YELLOW}ECU Simulation Controller${NC}"
    echo "Usage: $0 {start|run|inject [--iface=<veth1-br|veth2-br|both>] <types...>|reset [--iface=<veth1-br|veth2-br|both>]|stop}"
    echo ""
    echo "  start           Setup the simulation environment"
    echo "  run             Run ECU programs and log output"
    echo "  inject <types>  Inject one or more faults (space-separated):"
    echo "                  loss, delay, corruption, block"
    echo "                  Optional: --iface=<veth1-br|veth2-br|both> (default: both)"
    echo "  reset           Reset all injected faults (calls reset.sh)"
    echo "                  Optional: --iface=<veth1-br|veth2-br|both> (default: both)"
    echo "  stop            Stop ECU processes and clean everything"
}

# Main Entry Point
case "$1" in
    start)
        start_simulation
        ;;
    run)
        run_ecus
        ;;
    inject)
        inject_faults "$@"
        ;;
    reset)
        reset_faults "$2"
        ;;
    stop)
        stop_simulation
        ;;
    *)
        help_menu
        ;;
esac


