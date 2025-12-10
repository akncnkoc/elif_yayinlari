#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2bth.h>
#include <windows.h>
#include <bluetoothapis.h>
#include <rpc.h>
#include <iostream>
#include <string>
#include <vector>
#include <thread>
#include <atomic>
#include <mutex>
#include <sstream>
#include <map>
#include <cmath>

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "Bthprops.lib")
#pragma comment(lib, "Rpcrt4.lib")

// Simple JSON parser for our message format
std::map<std::string, std::string> parseJson(const std::string& json) {
    std::map<std::string, std::string> result;

    size_t pos = 0;
    while (pos < json.length()) {
        // Find key
        size_t keyStart = json.find('"', pos);
        if (keyStart == std::string::npos) break;
        keyStart++;

        size_t keyEnd = json.find('"', keyStart);
        if (keyEnd == std::string::npos) break;

        std::string key = json.substr(keyStart, keyEnd - keyStart);

        // Find value
        size_t colonPos = json.find(':', keyEnd);
        if (colonPos == std::string::npos) break;

        size_t valueStart = colonPos + 1;
        while (valueStart < json.length() && (json[valueStart] == ' ' || json[valueStart] == '"')) valueStart++;

        size_t valueEnd = valueStart;
        while (valueEnd < json.length() && json[valueEnd] != ',' && json[valueEnd] != '}' && json[valueEnd] != '"') valueEnd++;

        std::string value = json.substr(valueStart, valueEnd - valueStart);
        result[key] = value;

        pos = valueEnd + 1;
    }

    return result;
}

// Handle input events from remote control
void handleInputEvent(const std::string& message) {
    auto data = parseJson(message);

    std::string type = data["type"];

    if (type == "mousedelta") {
        // Relative mouse movement
        double deltaX = std::stod(data["deltaX"]);
        double deltaY = std::stod(data["deltaY"]);

        // Get current cursor position
        POINT currentPos;
        GetCursorPos(&currentPos);

        // Calculate new position
        int newX = currentPos.x + static_cast<int>(deltaX);
        int newY = currentPos.y + static_cast<int>(deltaY);

        // Move cursor to new position
        SetCursorPos(newX, newY);
    }
    else if (type == "mousedown") {
        int button = std::stoi(data["button"]);

        INPUT input = {};
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = (button == 0) ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_RIGHTDOWN;

        SendInput(1, &input, sizeof(INPUT));
    }
    else if (type == "mouseup") {
        int button = std::stoi(data["button"]);

        INPUT input = {};
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = (button == 0) ? MOUSEEVENTF_LEFTUP : MOUSEEVENTF_RIGHTUP;

        SendInput(1, &input, sizeof(INPUT));
    }
    else if (type == "keydown") {
        std::string key = data["key"];
        WORD vk = 0;

        if (key == "c" || key == "C") vk = 'C';
        else if (key == "z" || key == "Z") vk = 'Z';
        else if (key == "e" || key == "E") vk = 'E';
        else if (key == "q" || key == "Q") vk = 'Q';

        if (vk != 0) {
            INPUT input = {};
            input.type = INPUT_KEYBOARD;
            input.ki.wVk = vk;

            SendInput(1, &input, sizeof(INPUT));
        }
    }
    else if (type == "keyup") {
        std::string key = data["key"];
        WORD vk = 0;

        if (key == "c" || key == "C") vk = 'C';
        else if (key == "z" || key == "Z") vk = 'Z';
        else if (key == "e" || key == "E") vk = 'E';
        else if (key == "q" || key == "Q") vk = 'Q';

        if (vk != 0) {
            INPUT input = {};
            input.type = INPUT_KEYBOARD;
            input.ki.wVk = vk;
            input.ki.dwFlags = KEYEVENTF_KEYUP;

            SendInput(1, &input, sizeof(INPUT));
        }
    }
}

class BluetoothServer {
private:
    std::atomic<bool> running_{false};
    std::atomic<bool> should_stop_{false};
    SOCKET server_socket_{INVALID_SOCKET};
    std::vector<SOCKET> client_sockets_;
    std::mutex clients_mutex_;
    std::thread server_thread_;
    std::string service_name_;
    std::string service_uuid_;

public:
    bool Start(const std::string& service_name, const std::string& service_uuid) {
        if (running_) {
            std::cout << "ERROR:Server already running" << std::endl;
            return false;
        }

        service_name_ = service_name;
        service_uuid_ = service_uuid;

        // Initialize Winsock
        WSADATA wsa_data;
        if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
            std::cout << "ERROR:Failed to initialize Winsock" << std::endl;
            return false;
        }

        // Create Bluetooth RFCOMM socket
        server_socket_ = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
        if (server_socket_ == INVALID_SOCKET) {
            std::cout << "ERROR:Failed to create socket" << std::endl;
            WSACleanup();
            return false;
        }

        // Bind to any available Bluetooth adapter
        SOCKADDR_BTH bind_addr = {};
        bind_addr.addressFamily = AF_BTH;
        bind_addr.btAddr = 0; // BDADDR_ANY
        bind_addr.port = BT_PORT_ANY;

        if (bind(server_socket_, (SOCKADDR*)&bind_addr, sizeof(bind_addr)) == SOCKET_ERROR) {
            std::cout << "ERROR:Failed to bind socket" << std::endl;
            closesocket(server_socket_);
            server_socket_ = INVALID_SOCKET;
            WSACleanup();
            return false;
        }

        // Get the assigned port
        int addr_len = sizeof(bind_addr);
        if (getsockname(server_socket_, (SOCKADDR*)&bind_addr, &addr_len) == SOCKET_ERROR) {
            std::cout << "ERROR:Failed to get socket name" << std::endl;
            closesocket(server_socket_);
            server_socket_ = INVALID_SOCKET;
            WSACleanup();
            return false;
        }

        // Listen for connections
        if (listen(server_socket_, SOMAXCONN) == SOCKET_ERROR) {
            std::cout << "ERROR:Failed to listen on socket" << std::endl;
            closesocket(server_socket_);
            server_socket_ = INVALID_SOCKET;
            WSACleanup();
            return false;
        }

        // Register SDP service so it's discoverable
        WSAQUERYSET service = {};
        GUID service_guid;
        UuidFromStringA((RPC_CSTR)service_uuid.c_str(), &service_guid);

        // Convert service name to wide string
        int len = MultiByteToWideChar(CP_UTF8, 0, service_name.c_str(), -1, nullptr, 0);
        std::vector<wchar_t> wide_name(len);
        MultiByteToWideChar(CP_UTF8, 0, service_name.c_str(), -1, wide_name.data(), len);

        service.dwSize = sizeof(service);
        service.lpServiceClassId = &service_guid;
        service.lpszServiceInstanceName = wide_name.data();
        service.dwNameSpace = NS_BTH;
        service.dwNumberOfCsAddrs = 1;

        SOCKADDR_BTH service_addr = {};
        service_addr.addressFamily = AF_BTH;
        service_addr.btAddr = 0; // Local adapter
        service_addr.port = bind_addr.port;
        service_addr.serviceClassId = service_guid;

        CSADDR_INFO csai = {};
        csai.LocalAddr.lpSockaddr = (SOCKADDR*)&service_addr;
        csai.LocalAddr.iSockaddrLength = sizeof(service_addr);
        csai.iSocketType = SOCK_STREAM;
        csai.iProtocol = BTHPROTO_RFCOMM;

        service.lpcsaBuffer = &csai;

        // Set comment
        std::wstring comment = L"Remote control for Drawing Pen";
        service.lpszComment = const_cast<wchar_t*>(comment.c_str());

        DWORD result = WSASetService(&service, RNRSERVICE_REGISTER, 0);
        if (result == SOCKET_ERROR) {
            DWORD error = WSAGetLastError();
            std::cout << "WARNING:Failed to register SDP service. Error: " << error << std::endl;

            if (error == WSASERVICE_NOT_FOUND) {
                std::cout << "INFO:Service not found - This is normal for first registration" << std::endl;
            } else if (error == WSAEACCES) {
                std::cout << "ERROR:Access denied. Run as Administrator?" << std::endl;
            }
            // Non-fatal, continue anyway
        } else {
            std::cout << "SDP_REGISTERED:Drawing Pen Remote on Port " << bind_addr.port << std::endl;
        }

        // Print local Bluetooth adapter info
        std::cout << "INFO:Make sure PC Bluetooth is discoverable" << std::endl;
        std::cout << "INFO:Check: Settings > Bluetooth > Allow devices to find this PC" << std::endl;

        std::cout << "SERVER_STARTED:Port " << bind_addr.port << std::endl;

        // Start server thread
        should_stop_ = false;
        running_ = true;
        server_thread_ = std::thread(&BluetoothServer::ServerLoop, this);

        return true;
    }

    void Stop() {
        if (!running_) return;

        should_stop_ = true;
        running_ = false;

        // Unregister SDP service
        if (!service_uuid_.empty()) {
            WSAQUERYSET service = {};
            GUID service_guid;
            UuidFromStringA((RPC_CSTR)service_uuid_.c_str(), &service_guid);

            service.dwSize = sizeof(service);
            service.lpServiceClassId = &service_guid;
            service.dwNameSpace = NS_BTH;

            WSASetService(&service, RNRSERVICE_DELETE, 0);
        }

        // Close all client sockets
        {
            std::lock_guard<std::mutex> lock(clients_mutex_);
            for (auto socket : client_sockets_) {
                closesocket(socket);
            }
            client_sockets_.clear();
        }

        // Close server socket
        if (server_socket_ != INVALID_SOCKET) {
            closesocket(server_socket_);
            server_socket_ = INVALID_SOCKET;
        }

        // Wait for server thread
        if (server_thread_.joinable()) {
            server_thread_.join();
        }

        WSACleanup();
        std::cout << "SERVER_STOPPED" << std::endl;
    }

private:
    void ServerLoop() {
        while (!should_stop_ && server_socket_ != INVALID_SOCKET) {
            SOCKADDR_BTH client_addr = {};
            int addr_len = sizeof(client_addr);

            // Accept with timeout
            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(server_socket_, &read_fds);

            timeval timeout;
            timeout.tv_sec = 1;
            timeout.tv_usec = 0;

            int select_result = select(0, &read_fds, nullptr, nullptr, &timeout);
            if (select_result == SOCKET_ERROR || !FD_ISSET(server_socket_, &read_fds)) {
                continue;
            }

            SOCKET client_socket = accept(server_socket_, (SOCKADDR*)&client_addr, &addr_len);
            if (client_socket == INVALID_SOCKET) {
                continue;
            }

            {
                std::lock_guard<std::mutex> lock(clients_mutex_);
                client_sockets_.push_back(client_socket);
            }

            std::cout << "CLIENT_CONNECTED:" << client_socket << std::endl;

            // Handle client in separate thread
            std::thread(&BluetoothServer::ClientHandler, this, client_socket).detach();
        }
    }

    void ClientHandler(SOCKET client_socket) {
        char buffer[4096];
        std::string accumulated;

        while (!should_stop_) {
            int bytes_received = recv(client_socket, buffer, sizeof(buffer) - 1, 0);

            if (bytes_received > 0) {
                buffer[bytes_received] = '\0';
                accumulated += buffer;

                // Process complete messages (messages end with newline)
                size_t pos;
                while ((pos = accumulated.find('\n')) != std::string::npos) {
                    std::string message = accumulated.substr(0, pos);
                    accumulated = accumulated.substr(pos + 1);

                    if (!message.empty()) {
                        std::cout << "MESSAGE_RECEIVED:" << message << std::endl;

                        // Handle the input event
                        try {
                            handleInputEvent(message);
                        } catch (const std::exception& e) {
                            std::cout << "ERROR:Failed to handle event: " << e.what() << std::endl;
                        }
                    }
                }
            } else if (bytes_received == 0 || bytes_received == SOCKET_ERROR) {
                break;
            }
        }

        // Remove from client list
        {
            std::lock_guard<std::mutex> lock(clients_mutex_);
            client_sockets_.erase(
                std::remove(client_sockets_.begin(), client_sockets_.end(), client_socket),
                client_sockets_.end());
        }

        closesocket(client_socket);
        std::cout << "CLIENT_DISCONNECTED:" << client_socket << std::endl;
    }
};

int main(int argc, char* argv[]) {
    BluetoothServer server;

    std::string service_name = "Drawing Pen Remote";
    std::string service_uuid = "00001101-0000-1000-8000-00805F9B34FB";

    if (!server.Start(service_name, service_uuid)) {
        return 1;
    }

    std::cout << "READY" << std::endl;

    // Keep running and handle commands from stdin
    std::string line;
    while (std::getline(std::cin, line)) {
        if (line == "STOP") {
            break;
        } else if (line.find("SEND:") == 0) {
            // TODO: Send message to clients
            std::string message = line.substr(5);
            std::cout << "SENT:" << message << std::endl;
        }
    }

    server.Stop();
    return 0;
}
