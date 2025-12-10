#ifndef BLUETOOTH_SERVER_PLUGIN_H_
#define BLUETOOTH_SERVER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

// Define WIN32_LEAN_AND_MEAN to exclude rarely-used services from Windows headers
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

// winsock2.h must be included before windows.h to avoid conflicts
#include <winsock2.h>
#include <ws2bth.h>
#include <windows.h>
#include <bluetoothapis.h>
#include <rpc.h>
#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <queue>

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "Bthprops.lib")

namespace bluetooth_server {

class BluetoothServerPlugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  BluetoothServerPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~BluetoothServerPlugin();

  // Disallow copy and assign.
  BluetoothServerPlugin(const BluetoothServerPlugin&) = delete;
  BluetoothServerPlugin& operator=(const BluetoothServerPlugin&) = delete;

 private:
  // MethodChannel handler
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Bluetooth server methods
  bool StartServer(const std::string& service_name, const std::string& service_uuid);
  void StopServer();
  bool SendMessage(const std::string& message);
  void DisconnectClients();
  bool IsBluetoothAvailable();
  bool IsBluetoothEnabled();

  // Server thread functions
  void ServerThread();
  void ClientHandlerThread(SOCKET client_socket, std::string client_address);

  // Event sending
  void SendEvent(const std::string& type,
                 const std::string& client_address = "",
                 const std::string& client_name = "",
                 const std::string& message = "",
                 const std::string& error = "");

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  // Bluetooth state
  std::atomic<bool> server_running_;
  std::atomic<bool> should_stop_;
  SOCKET server_socket_;
  std::vector<SOCKET> client_sockets_;
  std::mutex clients_mutex_;
  std::thread server_thread_;

  std::string service_name_;
  std::string service_uuid_;
};

}  // namespace bluetooth_server

#endif  // BLUETOOTH_SERVER_PLUGIN_H_
