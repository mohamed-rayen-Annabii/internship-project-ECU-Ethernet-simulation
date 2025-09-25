#!/bin/bash
set -e

LOG=test/loss.log
> "$LOG"

echo "[*] Test packet loss fault injection" | tee -a "$LOG"

sudo ./faults/reset.sh >> "$LOG" 2>&1
sudo ./cleanup.sh >> "$LOG" 2>&1 || true
sudo ./setup_netns.sh >> "$LOG" 2>&1

sudo ip netns exec ecu2 ./build/ecu2 > ecu2_output.txt 2>&1 &
ECU2_PID=$!
sudo ip netns exec ecu1 ./build/ecu1 > ecu1_output.txt 2>&1 &
ECU1_PID=$!

sleep 3

echo "[*] Inject packet loss fault" | tee -a "$LOG"
sudo ./faults/loss.sh >> "$LOG" 2>&1

sleep 7

# On compare le nombre de messages envoyés et reçus
SENT_COUNT=$(grep -c "Sent: ECM" ecu1_output.txt)
RECV_COUNT=$(grep -c "Received" ecu2_output.txt)

LOSS_PERCENTAGE=$(( (SENT_COUNT - RECV_COUNT) * 100 / SENT_COUNT ))

echo "Sent messages: $SENT_COUNT, Received messages: $RECV_COUNT, Loss: $LOSS_PERCENTAGE%" | tee -a "$LOG"

if [ "$LOSS_PERCENTAGE" -ge 10 ]; then
  echo "PASS: Packet loss injected, lost at least 10% messages." | tee -a "$LOG"
else
  echo "FAIL: Packet loss not effective enough." | tee -a "$LOG"
  exit 1
fi

sudo ./faults/reset.sh >> "$LOG" 2>&1
sudo kill $ECU1_PID $ECU2_PID
sudo ./cleanup.sh >> "$LOG" 2>&1

exit 0

