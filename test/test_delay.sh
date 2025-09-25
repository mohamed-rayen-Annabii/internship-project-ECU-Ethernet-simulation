#!/bin/bash
set -e

echo "[*] Testing: Delay packets from ECU1..."

sudo ./setup_netns.sh
make

sudo ./run_ecu2.sh > ecu2_output.txt &
ECU2_PID=$!
sleep 1

sudo ./faults/delay.sh

sudo ./run_ecu1.sh &
ECU1_PID=$!
sleep 5

sudo kill $ECU1_PID $ECU2_PID || true

count=$(grep -c "status OK" ecu2_output.txt)
echo "[i] Messages received with delay: $count"

if [ "$count" -ge 3 ] && [ "$count" -le 6 ]; then
  echo " Delay fault PASSED"
  exit 0
else
  echo " Delay fault FAILED"
  exit 1
fi
