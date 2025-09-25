

/*
#include <iostream>
#include <fstream>
#include <chrono>
#include <ctime>
#include <iomanip>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <csignal>

using namespace std;
using namespace std::chrono;

const char* LOG_FILE = "logs/ecu1.log";
const int TIMEOUT_SEC = 2;
const double MAX_RTT_THRESHOLD_MS = 250.0;

bool running = true;

void signal_handler(int signum) {
    running = false;
}

string current_timestamp() {
    auto now = system_clock::now();
    time_t t = system_clock::to_time_t(now);
    tm local_tm = *localtime(&t);
    stringstream ss;
    ss << put_time(&local_tm, "[%Y-%m-%d %H:%M:%S]");
    return ss.str();
}

uint16_t calculate_checksum(const string& data) {
    uint16_t checksum = 0;
    for (char c : data)
        checksum += static_cast<uint8_t>(c);
    return checksum;
}

void log_both(ofstream& log, const string& message) {
    cout << message << endl;
    log << message << endl;
    log.flush();
}

int main() {
    signal(SIGINT, signal_handler);  // Ctrl+C handler

    ofstream log(LOG_FILE, ios::out | ios::trunc);
    if (!log) {
        cerr << "Failed to open log file.\n";
        return 1;
    }

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("socket failed");
        return 1;
    }

    struct sockaddr_in ecu2_addr{};
    ecu2_addr.sin_family = AF_INET;
    ecu2_addr.sin_port = htons(6000);
    inet_pton(AF_INET, "10.0.0.2", &ecu2_addr.sin_addr);

    struct timeval tv{};
    tv.tv_sec = TIMEOUT_SEC;
    tv.tv_usec = 0;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));

    char buffer[1024];
    int msg_counter = 0;

    while (running) {
        int rpm = 1000 + rand() % 5000;
        int gear = 1 + rand() % 5;
        int torque = 100 + rand() % 300;

        auto send_time_point = high_resolution_clock::now();
        long long send_timestamp_ms = duration_cast<milliseconds>(send_time_point.time_since_epoch()).count();

        string payload = "MSG " + to_string(msg_counter) +
                         " RPM=" + to_string(rpm) +
                         " GEAR=" + to_string(gear) +
                         " TORQUE=" + to_string(torque) +
                         " TS=" + to_string(send_timestamp_ms);
        uint16_t checksum = calculate_checksum(payload);
        payload += "|CK=" + to_string(checksum);

        string timestamp_log = current_timestamp();
        log_both(log, timestamp_log + " ECU1 | Sent: " + payload);

        sendto(sock, payload.c_str(), payload.size(), 0,
               (struct sockaddr*)&ecu2_addr, sizeof(ecu2_addr));

        socklen_t len = sizeof(ecu2_addr);
        ssize_t recv_len = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                                    (struct sockaddr*)&ecu2_addr, &len);
        auto recv_time = high_resolution_clock::now();

        if (recv_len < 0) {
            log_both(log, timestamp_log + " ECU1 | [!] No ACK received (timeout). Moving to next.");
        } else {
            buffer[recv_len] = '\0';
            double rtt_ms = duration<double, milli>(recv_time - send_time_point).count();

            string rtt_log = timestamp_log + " ECU1 | MSG " + to_string(msg_counter) +
                             " ACK received | RTT=" + to_string(rtt_ms) + " ms";
            log_both(log, rtt_log);

            if (rtt_ms > MAX_RTT_THRESHOLD_MS) {
                log_both(log, timestamp_log + " ECU1 | ! Delayed ACK detected");
            }
        }

        msg_counter++;
        sleep(1);
    }

    close(sock);
    string end_msg = current_timestamp() + " ECU1 | Stopped by user.";
    log_both(log, end_msg);
    log.close();
    return 0;
}
*/


#include <iostream>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>
#include <sstream>

#define PORT 5000
#define BUFFER_SIZE 1024

int main() {
    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);
    char buffer[BUFFER_SIZE];

    // Create UDP socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("Socket creation failed");
        return 1;
    }

    // Bind socket to ECU1 address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        return 1;
    }

    std::cout << "[ECU1] Listening for requests..." << std::endl;

    int last_request_id = 0;

    while (true) {
        // Receive request from ECU2
        int n = recvfrom(sockfd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&client_addr, &addr_len);
        if (n < 0) {
            perror("Receive failed");
            continue;
        }

        buffer[n] = '\0';
        std::string request(buffer);
        std::cout << "[ECU1] Request received: " << request << std::endl;

        // Parse the request format: "REQ SPEED <id>"
        std::istringstream iss(request);
        std::string req_label, req_type;
        int req_id;
        if (!(iss >> req_label >> req_type >> req_id) || req_label != "REQ" || req_type != "SPEED") {
            std::cout << "[ECU1] Invalid request format" << std::endl;
            continue;
        }

        // Drop old or duplicate requests
        if (req_id <= last_request_id) {
            std::cout << "[ECU1] Ignored duplicate or delayed request ID: " << req_id << std::endl;
            continue;
        }

        // Update last request ID
        last_request_id = req_id;

        // Build response message
        std::ostringstream response;
        response << "MSG " << req_id << " SPEED=80 TORQUE=120 GEAR=3";

        // Send response to ECU2
        sendto(sockfd, response.str().c_str(), response.str().size(), 0, (struct sockaddr*)&client_addr, addr_len);
        std::cout << "[ECU1] Sent: " << response.str() << std::endl;
    }

    close(sockfd);
    return 0;
}




