// ecu1.cpp
#include <iostream>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("Socket creation failed");
        return 1;
    }

    // Optional: bind to 10.0.0.1 explicitly if needed
    sockaddr_in localAddr{};
    localAddr.sin_family = AF_INET;
    localAddr.sin_port = htons(0); // ephemeral port
    inet_pton(AF_INET, "10.0.0.1", &localAddr.sin_addr);
    bind(sock, (sockaddr*)&localAddr, sizeof(localAddr));

    sockaddr_in destAddr{};
    destAddr.sin_family = AF_INET;
    destAddr.sin_port = htons(9090);
    inet_pton(AF_INET, "10.0.0.2", &destAddr.sin_addr); // ECU2

    const char* message = "ECU1: status OK";

    for (int i = 0; i < 5; ++i) {
        ssize_t sent = sendto(sock, message, strlen(message), 0,
                              (sockaddr*)&destAddr, sizeof(destAddr));
        if (sent < 0) {
            perror("Send failed");
        } else {
            std::cout << "Message sent\n";
        }
        sleep(1);
    }

    close(sock);
    return 0;
}

