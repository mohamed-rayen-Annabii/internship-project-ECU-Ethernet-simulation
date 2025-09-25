#ifndef FAULT_INJECTOR_H
#define FAULT_INJECTOR_H

#include <arpa/inet.h>
#include <string>
#include <random>
#include <iostream>
#include <unistd.h>

class FaultInjector {
private:
    double block_prob;
    double corrupt_prob;
    double delay_prob;
    double loss_prob;
    std::random_device rd;
    std::mt19937 gen;
    std::uniform_real_distribution<> dis;

public:
    FaultInjector(double block, double corrupt, double delay, double loss)
        : block_prob(block), corrupt_prob(corrupt), delay_prob(delay), loss_prob(loss), gen(rd()), dis(0.0, 1.0) {}

    void injectFault(int sock, const char* message, size_t len, const sockaddr_in& destAddr, socklen_t addrLen) {
        double rand = dis(gen);
        double cumulative = 0.0;

        // Loss fault
        cumulative += loss_prob;
        if (rand < cumulative) {
            std::cout << "Fault: Message lost\n";
            return;
        }

        // Block fault
        cumulative += block_prob;
        if (rand < cumulative) {
            std::cout << "Fault: Message blocked\n";
            return;
        }

        // Delay fault
        cumulative += delay_prob;
        if (rand < cumulative) {
            int delay_ms Time_ms = static_cast<int>(dis(gen) * 1000); // Up to 1 second delay
            std::cout << "Fault: Delaying message by " << delay_ms << " ms\n";
            usleep(delay_ms * 1000);
        }

        // Corrupt fault
        cumulative += corrupt_prob;
        if (rand < cumulative) {
            std::string corrupted = std::string(message);
            if (!corrupted.empty()) {
                size_t pos = static_cast<size_t>(dis(gen) * corrupted.length());
                corrupted[pos] = corrupted[pos] ^ 0xFF; // Flip bits of one character
                std::cout << "Fault: Message corrupted to: " << corrupted << std::endl;
                sendto(sock, corrupted.c_str(), corrupted.length(), 0, (sockaddr*)&destAddr, addrLen);
                return;
            }
        }

        // Normal send
        sendto(sock, message, len, 0, (sockaddr*)&destAddr, addrLen);
        std::cout << "Sent reply: " << message << std::endl;
    }
};

#endif
