#!/bin/bash
set -e

LOG=test/corrupt.log
> "$LOG"

echo "[*] Test packet corruption fault injection" | tee -a "$LOG"

sudo ./faults/reset.sh >> "$LOG" 2>&1
sudo ./cleanup.sh >> "$LOG" 2>&1 || true
sudo ./setup_netns.sh >> "$LOG" 2>&1

sudo ip netns exec ecu2 ./build/ecu2 > ecu2_output.txt 2>&1 &
ECU2_PID=$!
sudo ip netns exec ecu1 ./build/ecu1 > ecu1_output.txt 2>&1 &
ECU1_PID=$!

sleep 3

echo "[*] Inject corruption fault" | tee -a "$LOG"
sudo ./faults/corrupt.sh >> "$LOG" 2>&1

sleep 7

# On cherche des anomalies dans les messages reçus par ecu2 (ex : caractères non-ASCII, mots-clés)
CORRUPT_FOUND=$(grep -E "[^[:print:][:space:]]" ecu2_output.txt || true)

if [ -n "$CORRUPT_FOUND" ]; then
  echo "PASS: Corruption detected in messages." | tee -a "$LOG"
else
  # Alternative: on peut chercher un mot clé "CORRUPT" si script corrupt.sh l'injecte dans message
  CORRUPT_KEYWORD=$(grep -i "CORRUPT" ecu2_output.txt || true)
  if [ -n "$CORRUPT_KEYWORD" ]; then
    echo "PASS: Corruption keyword detected." | tee -a "$LOG"
  else
    echo "FAIL: No corruption detected in received messages." | tee -a "$LOG"
    exit 1
  fi
fi

sudo ./faults/reset.sh >> "$LOG" 2>&1
sudo kill $ECU1_PID $ECU2_PID
sudo ./cleanup.sh >> "$LOG" 2>&1

exit 0

