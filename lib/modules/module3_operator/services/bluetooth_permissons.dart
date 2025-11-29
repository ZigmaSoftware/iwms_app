import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissions {
  static Future<bool> requestAll() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final location = await Permission.location.request(); // for older BT APIs

    return scan.isGranted && connect.isGranted && location.isGranted;
  }

  static Future<bool> isGranted() async {
    return await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted;
  }
}
