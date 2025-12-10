cmake_minimum_required(VERSION 3.14)
project(bluetooth_server_standalone)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create executable
add_executable(bluetooth_server_standalone
    bluetooth_server_standalone.cpp
)

# Link Winsock and Bluetooth libraries
target_link_libraries(bluetooth_server_standalone
    ws2_32.lib
    Bthprops.lib
)

# Set output directory
set_target_properties(bluetooth_server_standalone PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bluetooth_server"
)
