// ecu2.cpp
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

    sockaddr_in localAddr{};
    localAddr.sin_family = AF_INET;
    localAddr.sin_port = htons(9090);
    inet_pton(AF_INET, "10.0.0.2", &localAddr.sin_addr);

    if (bind(sock, (sockaddr*)&localAddr, sizeof(localAddr)) < 0) {
        perror("Bind failed");
        return 1;
    }

    char buffer[1024];
    for (int i = 0; i < 5; ++i) {
        sockaddr_in senderAddr{};
        socklen_t addrLen = sizeof(senderAddr);
        ssize_t recvLen = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                                   (sockaddr*)&senderAddr, &addrLen);
        if (recvLen > 0) {
            buffer[recvLen] = '\0';
            std::cout << "Received: " << buffer << std::endl;
        } else {
            perror("Receive failed");
        }
    }

    close(sock);
    return 0;
}
