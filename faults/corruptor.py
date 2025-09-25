import socket
import random
import time

LISTEN_PORT = 5000
FORWARD_PORT = 6000
FORWARD_IP = "10.0.0.2"  # ECU2

CORRUPTION_RATE = 0.1  # 10%

def corrupt_payload(data: bytes) -> bytes:
    data = bytearray(data)
    if len(data) > 0:
        index = random.randint(0, len(data) - 1)
        data[index] ^= 0xFF  # Flip bits
    return bytes(data)

sock_recv = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock_recv.bind(("0.0.0.0", LISTEN_PORT))

sock_send = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

print(f"[Corruptor] Listening on port {LISTEN_PORT}, forwarding to {FORWARD_IP}:{FORWARD_PORT}")

while True:
    data, addr = sock_recv.recvfrom(1024)
    if random.random() < CORRUPTION_RATE:
        corrupted = corrupt_payload(data)
        print(f"[Corruptor] Corrupted packet: {data} -> {corrupted}")
        sock_send.sendto(corrupted, (FORWARD_IP, FORWARD_PORT))
    else:
        print(f"[Corruptor] Forwarding clean packet: {data}")
        sock_send.sendto(data, (FORWARD_IP, FORWARD_PORT))
