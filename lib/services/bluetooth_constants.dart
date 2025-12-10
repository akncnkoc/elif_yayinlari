// Windows Bluetooth constants
const int AF_BTH = 32; // Bluetooth address family
const int BTHPROTO_RFCOMM = 0x0003; // RFCOMM protocol
const int BT_PORT_ANY = 0; // Any available port
const int SOMAXCONN = 0x7fffffff;
const int INVALID_SOCKET = -1;
const int SOCKET_ERROR = -1;

// Socket types
const int SOCK_STREAM = 1;

// Winsock functions
int MAKEWORD(int low, int high) => (low & 0xFF) | ((high & 0xFF) << 8);
