import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

/// Detects the device's LAN IP address.
class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the Wi-Fi IP address. Returns null if unavailable.
  Future<String?> getWifiIP() async {
    // Strategy 1: Use network_info_plus (works when permission is granted)
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != '0.0.0.0') {
        return wifiIP;
      }
    } catch (_) {}

    // Strategy 2: Scan network interfaces, prefer wlan/Wi-Fi interfaces
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // First pass: look for typical Wi-Fi interface names
      final wifiNames = ['wlan', 'wifi', 'wl', 'en0', 'en1', 'swlan'];
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (wifiNames.any((w) => name.contains(w))) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback && _isPrivateIP(addr.address)) {
              return addr.address;
            }
          }
        }
      }

      // Second pass: look for common LAN IP ranges (192.168.x.x, 172.x.x.x)
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && _isPrivateIP(addr.address)) {
            // Skip emulator/Docker/VPN ranges
            if (addr.address.startsWith('10.0.2.') ||
                addr.address.startsWith('172.17.') ||
                addr.address.startsWith('172.18.')) {
              continue;
            }
            return addr.address;
          }
        }
      }

      // Third pass: any non-loopback private IP
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && _isPrivateIP(addr.address)) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Check if an IP is in a private range.
  bool _isPrivateIP(String ip) {
    return ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        ip.startsWith('172.');
  }

  /// Construct the join URL.
  String getJoinUrl(String ip, int port) {
    return 'http://$ip:$port';
  }
}
