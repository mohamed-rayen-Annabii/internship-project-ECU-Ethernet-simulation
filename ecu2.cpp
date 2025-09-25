

#include <iostream>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>
#include <chrono>
#include <thread>
#include <sstream>
#include <iomanip>
#include <fstream>
#include <vector>

#define SERVER_IP "10.0.0.1"
#define PORT 5000
#define BUFFER_SIZE 1024
#define REQUEST_INTERVAL_MS 1000  // 1 second between requests
#define TIMEOUT_MS 300            // socket receive timeout
#define DELAY_THRESHOLD_MS 250    // RTT threshold for "delayed" detection

// Utility: get current timestamp
std::string currentTimestamp() {
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::tm tm = *std::localtime(&t);
    std::ostringstream oss;
    oss << "[" << std::put_time(&tm, "%Y-%m-%d %H:%M:%S") << "]";
    return oss.str();
}

int main() {
    int sockfd;
    struct sockaddr_in server_addr;
    socklen_t addr_len = sizeof(server_addr);
    char buffer[BUFFER_SIZE];

    // Create socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("Socket creation failed");
        return 1;
    }

    // Configure server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr);

    // Set socket timeout for recvfrom
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = TIMEOUT_MS * 1000;
    setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    int expected_msg = 1;

    std::cout << currentTimestamp() << " [ECU2] Starting message requests..." << std::endl;
    int total_messages = 0;
    int received_count = 0;
    int not_received_count = 0;
    std::vector<std::string> message_status;

    while (true) {
        // Build request with expected message ID
        std::ostringstream req;
        req << "REQ SPEED " << expected_msg;

        // Send request
        sendto(sockfd, req.str().c_str(), req.str().size(), 0, (struct sockaddr*)&server_addr, addr_len);
        std::cout << currentTimestamp() << " [ECU2] Sent request for message " << expected_msg << std::endl;

        // Record request send time
        auto send_time = std::chrono::steady_clock::now();
        int msg_num = 0;
        double rtt = 0.0;

        // Receive response
        int n = recvfrom(sockfd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&server_addr, &addr_len);

        if (n > 0) {
    auto recv_time = std::chrono::steady_clock::now();
    rtt = std::chrono::duration_cast<std::chrono::microseconds>(recv_time - send_time).count() / 1000.0;

    buffer[n] = '\0';
    std::string response(buffer);

    // Extract message number from "MSG X ..."
    std::istringstream iss(response);
    std::string label;
    iss >> label >> msg_num;

            if (msg_num == expected_msg) {
                if (rtt > DELAY_THRESHOLD_MS) {
                    std::cout << currentTimestamp() << " [ECU2] Message " << expected_msg
          << ": ! not received (delayed!) | RTT=" << std::fixed << std::setprecision(2) << rtt << " ms" << std::endl;
                } else {
                    std::cout << currentTimestamp() << " [ECU2] Message " << expected_msg
          << ": received (MSG " << msg_num << " SPEED=80 TORQUE=120 GEAR=3) | RTT="
          << std::fixed << std::setprecision(2) << rtt << " ms" << std::endl;
                }
            } else {
                // Wrong message received (out of order)
                std::cout << currentTimestamp() << " [ECU2] Message " << expected_msg
                          << ": ! not received (delayed or mismatch) | got MSG " << msg_num << std::endl;
            }
        } else {
            // Timeout → message not received
            std::cout << currentTimestamp() << " [ECU2] Message " << expected_msg << ": ! not received (timeout!)" << std::endl;
        }
        
        total_messages++;
std::ostringstream log_entry;
log_entry << "Message " << expected_msg << ": ";

if (n > 0) {
    if (msg_num == expected_msg) {
        if (rtt > DELAY_THRESHOLD_MS) {
            log_entry << "not received (delayed, RTT=" << std::fixed << std::setprecision(2) << rtt << " ms)";
            not_received_count++;
        } else {
            log_entry << "received (RTT=" << std::fixed << std::setprecision(2) << rtt << " ms)";
            received_count++;
        }
    } else {
        log_entry << "not received (mismatch, got MSG " << msg_num << ")";
        not_received_count++;
    }
} else {
    log_entry << "not received (timeout)";
    not_received_count++;
}

message_status.push_back(log_entry.str());

// Write to fault_summary.txt
std::ofstream log_file("fault_summary.txt", std::ios::trunc);
log_file << "ECU2 Fault Summary\n==================\n";
log_file << "Total messages: " << total_messages << "\n";
log_file << "Received: " << received_count << "\n";
log_file << "Not Received: " << not_received_count << "\n\n";
for (const auto& status : message_status) {
    log_file << status << "\n";
}
log_file.close();

        expected_msg++; // Always increment expected message
        std::this_thread::sleep_for(std::chrono::milliseconds(REQUEST_INTERVAL_MS));
    }

    close(sockfd);
    return 0;
}



 /*
 #include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include <ctime>
#include <chrono>
#include <arpa/inet.h>
#include <unistd.h>
#include <map>
#include <random>

#define ECU_ID "ECU2"
#define LISTEN_PORT 6000
#define MAX_DELAY_THRESHOLD_MS 500
#define PACKET_LOSS_PERCENTAGE 10 // 10% packet loss
#define ARTIFICIAL_DELAY_MS 600 // Artificial delay for some messages

std::ofstream logFile;
int lastMsgId = -1;
std::map<int, long long> receivedMessages;

// Random number generator
std::default_random_engine generator(std::chrono::system_clock::now().time_since_epoch().count());
std::uniform_int_distribution<int> loss_distribution(1, 100);
std::uniform_int_distribution<int> delay_distribution(1, 100);

std::string timestamp() {
    auto now = std::time(nullptr);
    char buf[64];
    std::strftime(buf, sizeof(buf), "%F %T", std::localtime(&now));
    return std::string(buf);
}

long long current_timestamp_ms() {
    auto now = std::chrono::high_resolution_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
}

uint16_t checksum(const std::string& msg) {
    uint16_t sum = 0;
    for (char c : msg) sum += static_cast<uint8_t>(c);
    return sum;
}

void log(const std::string& line) {
    std::string full = "[" + timestamp() + "] " + ECU_ID + " | " + line;
    std::cout << full << std::endl;
    logFile << full << std::endl;
    logFile.flush();
}

int extractMsgId(const std::string& msg) {
    size_t msgPos = msg.find("MSG ");
    if (msgPos == std::string::npos) return -1;
    
    size_t start = msgPos + 4;
    size_t end = msg.find(" ", start);
    if (end == std::string::npos) return -1;
    
    try {
        return std::stoi(msg.substr(start, end - start));
    } catch (...) {
        return -1;
    }
}

long long extractTimestamp(const std::string& msg) {
    size_t tsPos = msg.find(" TS=");
    if (tsPos == std::string::npos) return -1;
    
    size_t start = tsPos + 4;
    size_t end = msg.find("|", start);
    if (end == std::string::npos) return -1;
    
    try {
        return std::stoll(msg.substr(start, end - start));
    } catch (...) {
        return -1;
    }
}

void checkForLostMessages(int currentMsgId) {
    if (lastMsgId != -1) {
        for (int i = lastMsgId + 1; i < currentMsgId; i++) {
            if (receivedMessages.find(i) == receivedMessages.end()) {
                log("! LOST MESSAGE detected: MSG " + std::to_string(i));
            }
        }
    }
}

int main() {
    logFile.open("logs/ecu2.log");
    if (!logFile) {
        std::cerr << "Failed to open ecu2.log" << std::endl;
        return 1;
    }

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in myAddr{}, cliAddr{};
    myAddr.sin_family = AF_INET;
    myAddr.sin_port = htons(LISTEN_PORT);
    inet_pton(AF_INET, "10.0.0.2", &myAddr.sin_addr);

    if (bind(sock, (struct sockaddr*)&myAddr, sizeof(myAddr)) < 0) {
        log("Failed to bind socket");
        return 1;
    }

    log("ECU2 started, listening on port " + std::to_string(LISTEN_PORT));

    char buf[256];
    socklen_t addrLen = sizeof(cliAddr);

    while(true) {
        int len = recvfrom(sock, buf, sizeof(buf) - 1, 0, (struct sockaddr*)&cliAddr, &addrLen);
        if (len <= 0) continue;
        buf[len] = 0;
        std::string msg(buf);

        // Simulate packet loss
        if (loss_distribution(generator) <= PACKET_LOSS_PERCENTAGE) {
            log("Simulating packet loss for: " + msg);
            continue; // Drop the packet
        }

        // Simulate artificial delay
        if (delay_distribution(generator) <= 20) { // 20% chance of delay
            usleep(ARTIFICIAL_DELAY_MS * 1000); // usleep takes microseconds
            log("Simulating artificial delay for: " + msg);
        }

        long long receiveTime = current_timestamp_ms();

        std::ostringstream oss;
        oss << "Received [" << len << " bytes]: " << msg;

        // Extract message ID
        int msgId = extractMsgId(msg);
        if (msgId == -1) {
            log("! Invalid message format (no MSG ID) | " + oss.str());
            sendto(sock, "NAK", 3, 0, (struct sockaddr*)&cliAddr, addrLen);
            continue;
        }

        // Check for lost messages
        checkForLostMessages(msgId);
        
        // Record this message
        receivedMessages[msgId] = receiveTime;
        if (msgId > lastMsgId) {
            lastMsgId = msgId;
        }

        // Extract and check timestamp for delay detection
        long long sendTimestamp = extractTimestamp(msg);
        if (sendTimestamp != -1) {
            long long delay = receiveTime - sendTimestamp;
            if (delay > MAX_DELAY_THRESHOLD_MS) {
                log("! DELAYED MESSAGE detected: MSG " + std::to_string(msgId) + 
                    " | Delay=" + std::to_string(delay) + " ms");
            }
        }

        size_t ckPos = msg.find("|CK=");
        if (ckPos == std::string::npos) {
            log("! Invalid format (no checksum) | " + oss.str());
            sendto(sock, "NAK", 3, 0, (struct sockaddr*)&cliAddr, addrLen);
            continue;
        }

        std::string data = msg.substr(0, ckPos);
        uint16_t receivedCK = std::stoi(msg.substr(ckPos + 4));
        uint16_t calcCK = checksum(data);

        if (receivedCK != calcCK) {
            log("! CKSUM MISMATCH | " + oss.str());
            sendto(sock, "NAK", 3, 0, (struct sockaddr*)&cliAddr, addrLen);
        } else {
            log("Valid MSG " + std::to_string(msgId) + " | " + oss.str());
            sendto(sock, "ACK", 3, 0, (struct sockaddr*)&cliAddr, addrLen);
        }
    }

    log("Stopped listening.");
    close(sock);
    logFile.close();
    return 0;
} */

