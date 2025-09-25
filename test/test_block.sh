#!/bin/bash
set -e

LOG_ECU1="test/ecu1_output_block.txt"
LOG_ECU2="test/ecu2_output_block.txt"
LOG_RESULT="test/block.log"

echo "[*] Testing: Block ECU1 from sending..."

# Clean any existing simulation
sudo ./cleanup.sh > /dev/null 2>&1 || true
sudo pkill -f 'ip netns exec ecu1' > /dev/null 2>&1 || true
sudo pkill -f 'ip netns exec ecu2' > /dev/null 2>&1 || true
rm -f "$LOG_ECU1" "$LOG_ECU2" "$LOG_RESULT"

# Setup fresh environment
sudo ./setup_netns.sh > /dev/null
make > /dev/null

# Start ECU2
sudo ./run_ecu2.sh > "$LOG_ECU2" 2>&1 &
PID_ECU2=$!
sleep 1

# Start ECU1
sudo ./run_ecu1.sh > "$LOG_ECU1" 2>&1 &
PID_ECU1=$!
sleep 1

# Inject block fault
echo "[*] Injecting fault: Block ECU1 from sending..."
sudo ./faults/block.sh > /dev/null

# Let ECUs run a bit
sleep 3

# Kill ECU processes
sudo pkill -f 'ip netns exec ecu1' > /dev/null 2>&1 || true
sudo pkill -f 'ip netns exec ecu2' > /dev/null 2>&1 || true

# Show output cleanly
echo -e "\n--- ECU1 Output (last 5 lines) ---"
tail -n 5 "$LOG_ECU1"

echo -e "\n--- ECU2 Output (last 5 lines) ---"
tail -n 5 "$LOG_ECU2"

# Evaluate result
if grep -q "status OK" "$LOG_ECU2"; then
    echo "✗ Block fault FAILED: Data was received." | tee "$LOG_RESULT"
else
    echo "+ Block fault PASSED: No data received." | tee "$LOG_RESULT"
fi

# Reset network setup
sudo ./faults/reset.sh > /dev/null

