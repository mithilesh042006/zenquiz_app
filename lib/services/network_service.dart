import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

/// Detects the device's LAN IP address.
class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the Wi-Fi IP address. Returns null if unavailable.
  Future<String?> getWifiIP() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      // Fallback: try to find a non-loopback IPv4 address
      return await _getFallbackIP();
    }
  }

  /// Fallback IP detection using dart:io.
  Future<String?> _getFallbackIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Construct the join URL.
  String getJoinUrl(String ip, int port) {
    return 'http://$ip:$port';
  }
}
