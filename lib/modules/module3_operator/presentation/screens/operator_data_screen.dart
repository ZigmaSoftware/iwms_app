// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:iwms_citizen_app/router/route_observer.dart';
// import 'package:iwms_citizen_app/modules/module3_operator/services/bluetooth_service.dart';
// import 'package:iwms_citizen_app/modules/module3_operator/services/image_compress_service.dart';
// import 'package:iwms_citizen_app/modules/module3_operator/services/unique_id_service.dart';

// class OperatorDataScreen extends StatefulWidget {
//   final String customerId;
//   final String customerName;
//   final String contactNo;
//   final String latitude;
//   final String longitude;

//   const OperatorDataScreen({
//     super.key,
//     required this.customerId,
//     required this.customerName,
//     required this.contactNo,
//     required this.latitude,
//     required this.longitude,
//   });

//   @override
//   State<OperatorDataScreen> createState() => _OperatorDataScreenState();
// }

// class _OperatorDataScreenState extends State<OperatorDataScreen>
//     with WidgetsBindingObserver, RouteAware {
//   final ImagePicker _picker = ImagePicker();
//   late String screenUniqueId;

//   final OperatorBluetoothService bluetooth = OperatorBluetoothService();
//   bool connected = false;
//   String latestWeight = "--";
//   bool _isSubmitting = false;
//   bool _isInitializingBluetooth = false;
//   BluetoothConnection? _connection;
//   String? activeType;
//   String? _bluetoothError;

//   List<Map<String, dynamic>> wasteTypes = [];
//   Map<String, Map<String, dynamic>> _wasteData = {};

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     screenUniqueId = OperatorUniqueIdService.generateScreenId();
//     _wasteData.clear();
//     latestWeight = "--";

//     _prepareBluetoothHardware();

//     _fetchWasteTypes();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
//   }

//   @override
//   void dispose() {
//     routeObserver.unsubscribe(this);
//     WidgetsBinding.instance.removeObserver(this);
//     _connection?.dispose();
//     super.dispose();
//   }

//   @override
//   void didPopNext() {
//     _reconnectBluetoothWithRetry();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed && !connected) {
//       _initBluetooth();
//     }
//   }

//   Future<void> _resetBluetooth() async {
//     try {
//       await _connection?.close();
//       _connection = null;
//       connected = false;
//     } catch (_) {}
//   }

//   Future<void> _prepareBluetoothHardware() async {
//     if (!mounted) return;
//     setState(() {
//       _isInitializingBluetooth = true;
//       _bluetoothError = null;
//     });

//     try {
//       await FlutterBluetoothSerial.instance.cancelDiscovery();
//       await FlutterBluetoothSerial.instance.requestEnable();
//       await _resetBluetooth();
//       await _initBluetooth();
//     } on PlatformException catch (e) {
//       _handleBluetoothError(
//         e.message ?? 'Bluetooth not available on this device.',
//       );
//     } catch (e) {
//       _handleBluetoothError('Unable to initialize Bluetooth: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isInitializingBluetooth = false);
//       }
//     }
//   }

//   void _handleBluetoothError(String message) {
//     if (!mounted) return;
//     _showSnack(message);
//     setState(() => _bluetoothError = message);
//   }

//   Future<bool> _ensureBluetoothPermissions() async {
//     final Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetooth,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.bluetoothAdvertise,
//       Permission.locationWhenInUse,
//     ].request();

//     final deniedEntries =
//         statuses.entries.where((entry) => !entry.value.isGranted).toList();

//     if (deniedEntries.isEmpty) {
//       return true;
//     }

//     final permanentlyDenied =
//         deniedEntries.any((entry) => entry.value.isPermanentlyDenied);

//     final message = permanentlyDenied
//         ? 'Bluetooth permissions are permanently denied. Enable them in Settings to continue.'
//         : 'Bluetooth permissions are required to connect to the weighing scale.';

//     _handleBluetoothError(message);

//     if (permanentlyDenied) {
//       await openAppSettings();
//     }

//     return false;
//   }

//   Future<void> _reconnectBluetoothWithRetry({int retries = 3}) async {
//     for (int i = 0; i < retries; i++) {
//       await Future.delayed(const Duration(seconds: 2));
//       try {
//         await _resetBluetooth();
//         await _initBluetooth();
//         if (connected) {
//           return;
//         }
//       } catch (_) {}
//     }
//   }

//   Future<void> _fetchWasteTypes() async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://zigma.in/iwms_app/api/waste/get_waste_type.php'),
//       );
//       final data = json.decode(response.body);

//       if (data['status'] == 'success') {
//         setState(() {
//           wasteTypes = List<Map<String, dynamic>>.from(data['data']);
//           _wasteData = {
//             for (var item in wasteTypes)
//               item['waste_type_name'].toString().toLowerCase(): {
//                 'waste_type_id': item['id'],
//                 'unique_id': null,
//                 'image': null,
//                 'weight': '--',
//                 'finalWeight': null,
//                 'isAdded': false,
//               }
//           };
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching waste types: $e');
//     }
//   }

//   Future<File?> _captureImage(String type) async {
//     final picked = await _picker.pickImage(source: ImageSource.camera);
//     if (picked == null) return null;

//     final original = File(picked.path);
//     final compressed = await OperatorImageCompressService.compress(original);

//     setState(() {
//       activeType = type;
//       final updated = Map<String, dynamic>.from(_wasteData[type]!);
//       updated['image'] = compressed;
//       updated['weight'] = latestWeight;
//       _wasteData = {
//         ..._wasteData,
//         type: updated,
//       };
//     });

//     return compressed;
//   }

//   Future<void> _fetchWasteRecord(String type) async {
//     try {
//       final uri =
//           Uri.parse('https://zigma.in/iwms_app/api/waste/get_saved_waste.php');
//       final response = await http.post(uri, body: {
//         'screen_unique_id': screenUniqueId,
//         'customer_id': widget.customerId,
//         'waste_type': _wasteData[type]!['waste_type_id'].toString(),
//       });

//       final data = json.decode(response.body);
//       if (data['status'] == 'success' && data['data'] != null) {
//         final record = data['data'];
//         setState(() {
//           final updated = Map<String, dynamic>.from(_wasteData[type]!);
//           updated['unique_id'] = record['unique_id'];
//           updated['waste_type_id'] = _wasteData[type]!['waste_type_id'];
//           updated['weight'] = record['weight'] ?? '--';
//           updated['finalWeight'] = record['weight'] ?? '--';
//           updated['isAdded'] = true;
//           _wasteData = {..._wasteData, type: updated};
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching record for $type: $e');
//     }
//   }

//   Future<void> _handleAdd(String type) async {
//     final data = _wasteData[type]!;

//     if (data['image'] == null) {
//       _showSnack('Capture image for $type first');
//       return;
//     }

//     if (latestWeight == "--") {
//       _showSnack('Please ensure weight is recorded for $type');
//       return;
//     }

//     final currentWeight = latestWeight;
//     setState(() => _isSubmitting = true);

//     try {
//       final image = data['image'] as File;
//       final bool isUpdate = data['isAdded'] == true;
//       final uri = Uri.parse(
//         isUpdate
//             ? 'https://zigma.in/iwms_app/api/waste/update_waste_sub.php'
//             : 'https://zigma.in/iwms_app/api/waste/insert_waste_sub.php',
//       );

//       final request = http.MultipartRequest('POST', uri)
//         ..fields['screen_unique_id'] = screenUniqueId
//         ..fields['customer_id'] = widget.customerId
//         ..fields['waste_type'] = _wasteData[type]!['waste_type_id'].toString()
//         ..fields['weight'] = currentWeight
//         ..fields['latitude'] = widget.latitude
//         ..fields['longitude'] = widget.longitude;

//       if (isUpdate && data['unique_id'] != null) {
//         request.fields['id'] = data['unique_id'].toString();
//       } else if (isUpdate && data['id'] != null) {
//         request.fields['id'] = data['id'].toString();
//       }

//       request.files.add(await http.MultipartFile.fromPath('image', image.path));

//       final response = await request.send();
//       final resBody = await http.Response.fromStream(response);
//       final result = json.decode(resBody.body);

//       if (result['status'] == 'success') {
//         await _fetchWasteRecord(type);
//         setState(() {
//           activeType = null;
//         });
//         _showSnack(
//           isUpdate
//               ? '$type waste updated successfully'
//               : '$type waste added successfully',
//         );
//       } else {
//         throw Exception(result['message'] ?? 'Failed to save $type');
//       }
//     } catch (e) {
//       _showSnack('Error saving $type: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   Future<void> _submitForm() async {
//     setState(() => _isSubmitting = true);

//     try {
//       final uri = Uri.parse(
//           'https://zigma.in/iwms_app/api/waste/insert_waste_main.php');
//       final request = http.MultipartRequest('POST', uri)
//         ..fields['screen_unique_id'] = screenUniqueId
//         ..fields['customer_id'] = widget.customerId
//         ..fields['entry_type'] = 'app'
//         ..fields['total_waste_collected'] =
//             _wasteData.values.fold<double>(0, (sum, e) {
//           final w = double.tryParse(
//                   e['finalWeight']?.toString() ?? e['weight'].toString()) ??
//               0;
//           return sum + w;
//         }).toString();

//       final response = await request.send();
//       final resBody = await http.Response.fromStream(response);
//       final result = json.decode(resBody.body);

//       if (result['status'] == 'success') {
//         await _resetBluetooth();
//         await Future.delayed(const Duration(milliseconds: 500));
//         await _initBluetooth();

//         setState(() {
//           _wasteData.clear();
//           latestWeight = "--";
//           screenUniqueId = OperatorUniqueIdService.generateScreenId();
//         });

//         _showDialog('Success', 'Main record submitted successfully!');
//       } else {
//         throw Exception(result['message'] ?? 'Failed to submit main record');
//       }
//     } catch (e) {
//       _showDialog('Error', 'Submission failed: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   void _showDialog(String title, String message) {
//     showDialog<void>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSnack(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   Widget _buildCustomerInfo() {
//     return Card(
//       color: Colors.white,
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(4),
//         side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _infoTile('Customer Name', widget.customerName),
//           _infoTile('Customer ID', widget.customerId),
//           _infoTile('Contact No', widget.contactNo),
//         ],
//       ),
//     );
//   }

//   Widget _infoTile(String label, String value) {
//     return ListTile(
//       title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//       subtitle: Text(value, style: const TextStyle(fontSize: 16)),
//     );
//   }

//   Widget _buildWasteSection(String type, String displayName) {
//     final data = _wasteData[type]!;
//     final image = data['image'] as File?;
//     final isAdded = data['isAdded'] as bool;
//     final displayWeight = data['finalWeight'] ?? data['weight'];

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//         side: BorderSide(
//           color: (type == activeType) ? Colors.blueAccent : Colors.black12,
//           width: (type == activeType) ? 2 : 1,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               displayName,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             if (image != null)
//               GestureDetector(
//                 onTap: () => _showPreview(image),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.file(
//                     image,
//                     width: double.infinity,
//                     height: 180,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 height: 180,
//                 width: double.infinity,
//                 color: Colors.grey[200],
//                 child: const Icon(
//                   Icons.camera_alt_outlined,
//                   size: 50,
//                   color: Colors.grey,
//                 ),
//               ),
//             const SizedBox(height: 10),
//             Text(
//               "Weight: ${displayWeight == '--' ? '--' : '$displayWeight kg'}",
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 OutlinedButton.icon(
//                   onPressed: () async {
//                     final file = await _captureImage(type);
//                     if (file != null) {
//                       setState(() {
//                         data['image'] = file;
//                         data['weight'] = latestWeight;
//                       });
//                     }
//                   },
//                   icon: const Icon(Icons.camera_alt),
//                   label: const Text("Capture"),
//                 ),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: isAdded
//                         ? Colors.orange.shade600
//                         : Colors.green.shade700,
//                   ),
//                   onPressed: () => _handleAdd(type),
//                   icon: Icon(isAdded ? Icons.refresh : Icons.add),
//                   label: Text(isAdded ? "Update" : "Add"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showPreview(File image) {
//     showDialog<void>(
//       context: context,
//       builder: (ctx) => Dialog(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.file(image),
//             TextButton(
//               onPressed: () => Navigator.of(ctx).pop(),
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromRGBO(0, 61, 125, 0.8),
//         title: const Text("Customer Details"),
//       ),
//       body: _bluetoothError != null
//           ? _BluetoothErrorView(
//               message: _bluetoothError!,
//               isBusy: _isInitializingBluetooth,
//               onRetry: _prepareBluetoothHardware,
//             )
//           : wasteTypes.isEmpty
//               ? const Center(child: CircularProgressIndicator())
//               : Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       color: Colors.blueGrey.shade50,
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 12, horizontal: 16),
//                       child: Text(
//                         "Live Weight: ${latestWeight == '--' ? '--' : '$latestWeight kg'}",
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           children: [
//                             _buildCustomerInfo(),
//                             const SizedBox(height: 15),
//                             ...wasteTypes.map((w) {
//                               final type = w['waste_type_name']
//                                   .toString()
//                                   .toLowerCase();
//                               final name = w['waste_type_name'];
//                               return _buildWasteSection(type, name);
//                             }),
//                             const SizedBox(height: 25),
//                             _isSubmitting
//                                 ? const CircularProgressIndicator()
//                                 : ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromRGBO(
//                                           0, 61, 125, 0.8),
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 40,
//                                         vertical: 12,
//                                       ),
//                                     ),
//                                     onPressed: _submitForm,
//                                     child: const Text(
//                                       'Submit',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                   ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//     );
//   }

//   Future<void> _initBluetooth() async {
//     if (connected) return;

//     final hasPermissions = await _ensureBluetoothPermissions();
//     if (!hasPermissions) {
//       return;
//     }

//     List<BluetoothDevice> devices;
//     try {
//       devices = await FlutterBluetoothSerial.instance.getBondedDevices();
//     } on PlatformException catch (e) {
//       _handleBluetoothError(
//         e.message ?? 'Unable to read paired Bluetooth devices.',
//       );
//       return;
//     } catch (e) {
//       _handleBluetoothError('Unable to read paired Bluetooth devices: $e');
//       return;
//     }

//     if (devices.isEmpty) {
//       _handleBluetoothError(
//         'No paired Bluetooth devices found. Pair the weighing scale first.',
//       );
//       return;
//     }

//     final hc05 = devices.firstWhere(
//       (d) => (d.name ?? '').toUpperCase().contains('HC'),
//       orElse: () => devices.first,
//     );

//     try {
//       final conn = await BluetoothConnection.toAddress(hc05.address);
//       setState(() {
//         _connection = conn;
//         connected = true;
//       });

//       String buffer = "";
//       conn.input?.listen((Uint8List data) {
//         final text = utf8.decode(data);
//         buffer += text;
//         if (buffer.contains('\n')) {
//           final parts = buffer.split('\n');
//           for (var line in parts.take(parts.length - 1)) {
//             final trimmed = line.trim();
//             if (trimmed.isEmpty) continue;

//             bluetooth.updateWeight(trimmed);

//             setState(() {
//               latestWeight = trimmed;

//               if (activeType != null && _wasteData.containsKey(activeType)) {
//                 final current = _wasteData[activeType!]!;
//                 if (current['isAdded'] == false) {
//                   final updated = Map<String, dynamic>.from(current);
//                   updated['weight'] = trimmed;
//                   _wasteData = {
//                     ..._wasteData,
//                     activeType!: updated,
//                   };
//                 }
//               }
//             });
//           }
//           buffer = parts.last;
//         }
//       }).onDone(() {
//         setState(() => connected = false);
//       });
//     } catch (e) {
//       _handleBluetoothError('Bluetooth connection error: $e');
//     }
//   }

// }

// class _BluetoothErrorView extends StatelessWidget {
//   const _BluetoothErrorView({
//     required this.message,
//     required this.isBusy,
//     required this.onRetry,
//   });

//   final String message;
//   final bool isBusy;
//   final Future<void> Function() onRetry;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme.error;
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.bluetooth_disabled, size: 58, color: color),
//             const SizedBox(height: 16),
//             Text(
//               'Bluetooth unavailable',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               message,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color:
//                     theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             if (isBusy)
//               const CircularProgressIndicator()
//             else
//               ElevatedButton.icon(
//                 onPressed: () => onRetry(),
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Retry'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:iwms_citizen_app/modules/module3_operator/services/bluetooth_service.dart';
import 'package:iwms_citizen_app/modules/module3_operator/services/image_compress_service.dart';
import 'package:iwms_citizen_app/modules/module3_operator/services/unique_id_service.dart';

class OperatorDataScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String contactNo;
  final String latitude;
  final String longitude;

  const OperatorDataScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.contactNo,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<OperatorDataScreen> createState() => _OperatorDataScreenState();
}

class _OperatorDataScreenState extends State<OperatorDataScreen> {
  final ImagePicker _picker = ImagePicker();
  late String screenUniqueId;

  final OperatorBluetoothService bluetooth = OperatorBluetoothService();
  bool connected = false;
  String latestWeight = "--";
  bool _isSubmitting = false;
  bool _isInitializingBluetooth = false;
  BluetoothConnection? _connection;
  String? activeType;
  String? _bluetoothError;
bool _btEnableRequested = false;

  List<Map<String, dynamic>> wasteTypes = [];
  Map<String, Map<String, dynamic>> _wasteData = {};

  @override
  void initState() {
    super.initState();

    screenUniqueId = OperatorUniqueIdService.generateScreenId();
    _wasteData.clear();
    latestWeight = "--";

    _prepareBluetoothHardware();
    _fetchWasteTypes();
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  // ----------------- BLUETOOTH BOOTSTRAP -----------------

  Future<void> _resetBluetooth() async {
    try {
      await _connection?.close();
      _connection = null;
      connected = false;
    } catch (_) {}
  }

  Future<void> _prepareBluetoothHardware() async {
    if (!mounted) return;
    setState(() {
      _isInitializingBluetooth = true;
      _bluetoothError = null;
    });

    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      // await FlutterBluetoothSerial.instance.requestEnable();
      await _resetBluetooth();
      await _initBluetooth();
    } on PlatformException catch (e) {
      _handleBluetoothError(
        e.message ?? 'Bluetooth not available on this device.',
      );
    } catch (e) {
      _handleBluetoothError('Unable to initialize Bluetooth: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializingBluetooth = false);
      }
    }
  }

  void _handleBluetoothError(String message) {
    if (!mounted) return;
    _showSnack(message);
    setState(() => _bluetoothError = message);
  }

  Future<bool> _ensureBluetoothPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    final deniedEntries =
        statuses.entries.where((entry) => !entry.value.isGranted).toList();

    if (deniedEntries.isEmpty) {
      return true;
    }

    final permanentlyDenied =
        deniedEntries.any((entry) => entry.value.isPermanentlyDenied);

    final message = permanentlyDenied
        ? 'Bluetooth permissions are permanently denied. Enable them in Settings to continue.'
        : 'Bluetooth permissions are required to connect to the weighing scale.';

    _handleBluetoothError(message);

    if (permanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  Future<void> _initBluetooth() async {
    if (connected) return;

    final hasPermissions = await _ensureBluetoothPermissions();
    if (!hasPermissions) {
      return;
    }

    List<BluetoothDevice> devices;
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } on PlatformException catch (e) {
      _handleBluetoothError(
        e.message ?? 'Unable to read paired Bluetooth devices.',
      );
      return;
    } catch (e) {
      _handleBluetoothError('Unable to read paired Bluetooth devices: $e');
      return;
    }

    if (devices.isEmpty) {
      _handleBluetoothError(
        'No paired Bluetooth devices found. Pair the weighing scale first.',
      );
      return;
    }

    final hc05 = devices.firstWhere(
      (d) => (d.name ?? '').toUpperCase().contains('HC'),
      orElse: () => devices.first,
    );

    try {
      final conn = await BluetoothConnection.toAddress(hc05.address);
      if (!mounted) return;

      setState(() {
        _connection = conn;
        connected = true;
      });

      String buffer = "";
      conn.input?.listen((Uint8List data) {
        final text = utf8.decode(data);
        buffer += text;

        if (buffer.contains('\n')) {
          final parts = buffer.split('\n');

          for (var line in parts.take(parts.length - 1)) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            bluetooth.updateWeight(trimmed);

            if (!mounted) return;

            setState(() {
              latestWeight = trimmed;

              if (activeType != null && _wasteData.containsKey(activeType)) {
                final current = _wasteData[activeType!]!;
                if (current['isAdded'] == false) {
                  final updated = Map<String, dynamic>.from(current);
                  updated['weight'] = trimmed;
                  _wasteData = {
                    ..._wasteData,
                    activeType!: updated,
                  };
                }
              }
            });
          }

          buffer = parts.last;
        }
      }).onDone(() {
        if (!mounted) return;
        setState(() => connected = false);
      });
    } catch (e) {
      _handleBluetoothError('Bluetooth connection error: $e');
    }
  }

  // ----------------- API – WASTE TYPES -----------------

  Future<void> _fetchWasteTypes() async {
    try {
      final response = await http.get(
        Uri.parse('https://zigma.in/iwms_app/api/waste/get_waste_type.php'),
      );
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          wasteTypes = List<Map<String, dynamic>>.from(data['data']);
          _wasteData = {
            for (var item in wasteTypes)
              item['waste_type_name'].toString().toLowerCase(): {
                'waste_type_id': item['id'],
                'unique_id': null,
                'image': null,
                'weight': '--',
                'finalWeight': null,
                'isAdded': false,
              }
          };
        });
      }
    } catch (e) {
      debugPrint('Error fetching waste types: $e');
    }
  }

  // ----------------- IMAGE + SUB ENTRY -----------------

  Future<File?> _captureImage(String type) async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;

    final original = File(picked.path);
    final compressed = await OperatorImageCompressService.compress(original);

    if (!mounted) return compressed;

    setState(() {
      activeType = type;
      final updated = Map<String, dynamic>.from(_wasteData[type]!);
      updated['image'] = compressed;
      updated['weight'] = latestWeight;
      _wasteData = {
        ..._wasteData,
        type: updated,
      };
    });

    return compressed;
  }

  Future<void> _fetchWasteRecord(String type) async {
    try {
      final uri =
          Uri.parse('https://zigma.in/iwms_app/api/waste/get_saved_waste.php');
      final response = await http.post(uri, body: {
        'screen_unique_id': screenUniqueId,
        'customer_id': widget.customerId,
        'waste_type': _wasteData[type]!['waste_type_id'].toString(),
      });

      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        final record = data['data'];
        if (!mounted) return;
        setState(() {
          final updated = Map<String, dynamic>.from(_wasteData[type]!);
          updated['unique_id'] = record['unique_id'];
          updated['waste_type_id'] = _wasteData[type]!['waste_type_id'];
          updated['weight'] = record['weight'] ?? '--';
          updated['finalWeight'] = record['weight'] ?? '--';
          updated['isAdded'] = true;
          _wasteData = {..._wasteData, type: updated};
        });
      }
    } catch (e) {
      debugPrint('Error fetching record for $type: $e');
    }
  }

  Future<void> _handleAdd(String type) async {
    final data = _wasteData[type]!;

    if (data['image'] == null) {
      _showSnack('Capture image for $type first');
      return;
    }

    if (latestWeight == "--") {
      _showSnack('Please ensure weight is recorded for $type');
      return;
    }

    final currentWeight = latestWeight;
    setState(() => _isSubmitting = true);

    try {
      final image = data['image'] as File;
      final bool isUpdate = data['isAdded'] == true;
      final uri = Uri.parse(
        isUpdate
            ? 'https://zigma.in/iwms_app/api/waste/update_waste_sub.php'
            : 'https://zigma.in/iwms_app/api/waste/insert_waste_sub.php',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['screen_unique_id'] = screenUniqueId
        ..fields['customer_id'] = widget.customerId
        ..fields['waste_type'] = _wasteData[type]!['waste_type_id'].toString()
        ..fields['weight'] = currentWeight
        ..fields['latitude'] = widget.latitude
        ..fields['longitude'] = widget.longitude;

      if (isUpdate && data['unique_id'] != null) {
        request.fields['id'] = data['unique_id'].toString();
      } else if (isUpdate && data['id'] != null) {
        request.fields['id'] = data['id'].toString();
      }

      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final resBody = await http.Response.fromStream(response);
      final result = json.decode(resBody.body);

      if (result['status'] == 'success') {
        await _fetchWasteRecord(type);
        if (!mounted) return;
        setState(() {
          activeType = null;
        });
        _showSnack(
          isUpdate
              ? '$type waste updated successfully'
              : '$type waste added successfully',
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to save $type');
      }
    } catch (e) {
      _showSnack('Error saving $type: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ----------------- MAIN SUBMIT -----------------

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse(
          'https://zigma.in/iwms_app/api/waste/insert_waste_main.php');
      final request = http.MultipartRequest('POST', uri)
        ..fields['screen_unique_id'] = screenUniqueId
        ..fields['customer_id'] = widget.customerId
        ..fields['entry_type'] = 'app'
        ..fields['total_waste_collected'] =
            _wasteData.values.fold<double>(0, (sum, e) {
          final w = double.tryParse(
                  e['finalWeight']?.toString() ?? e['weight'].toString()) ??
              0;
          return sum + w;
        }).toString();

      final response = await request.send();
      final resBody = await http.Response.fromStream(response);
      final result = json.decode(resBody.body);

      if (result['status'] == 'success') {
        await _resetBluetooth();
        await Future.delayed(const Duration(milliseconds: 500));
        await _initBluetooth();

        if (!mounted) return;
        setState(() {
          _wasteData.clear();
          latestWeight = "--";
          screenUniqueId = OperatorUniqueIdService.generateScreenId();
        });

        _showDialog('Success', 'Main record submitted successfully!');
      } else {
        throw Exception(result['message'] ?? 'Failed to submit main record');
      }
    } catch (e) {
      _showDialog('Error', 'Submission failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ----------------- UI HELPERS -----------------

  void _showDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoTile('Customer Name', widget.customerName),
          _infoTile('Customer ID', widget.customerId),
          _infoTile('Contact No', widget.contactNo),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildWasteSection(String type, String displayName) {
    final data = _wasteData[type]!;
    final image = data['image'] as File?;
    final isAdded = data['isAdded'] as bool;
    final displayWeight = data['finalWeight'] ?? data['weight'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: (type == activeType) ? Colors.blueAccent : Colors.black12,
          width: (type == activeType) ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (image != null)
              GestureDetector(
                onTap: () => _showPreview(image),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              "Weight: ${displayWeight == '--' ? '--' : '$displayWeight kg'}",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await _captureImage(type);
                    if (file != null && mounted) {
                      setState(() {
                        data['image'] = file;
                        data['weight'] = latestWeight;
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdded
                        ? Colors.orange.shade600
                        : Colors.green.shade700,
                  ),
                  onPressed: () => _handleAdd(type),
                  icon: Icon(isAdded ? Icons.refresh : Icons.add),
                  label: Text(isAdded ? "Update" : "Add"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(File image) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- BUILD -----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 61, 125, 0.8),
        title: const Text("Customer Details"),
      ),
      body: _bluetoothError != null
          ? _BluetoothErrorView(
              message: _bluetoothError!,
              isBusy: _isInitializingBluetooth,
              onRetry: _prepareBluetoothHardware,
            )
          : wasteTypes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.blueGrey.shade50,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Text(
                        "Live Weight: ${latestWeight == '--' ? '--' : '$latestWeight kg'}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildCustomerInfo(),
                            const SizedBox(height: 15),
                            ...wasteTypes.map((w) {
                              final type = w['waste_type_name']
                                  .toString()
                                  .toLowerCase();
                              final name = w['waste_type_name'];
                              return _buildWasteSection(type, name);
                            }),
                            const SizedBox(height: 25),
                            _isSubmitting
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromRGBO(
                                          0, 61, 125, 0.8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _submitForm,
                                    child: const Text(
                                      'Submit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _BluetoothErrorView extends StatelessWidget {
  const _BluetoothErrorView({
    required this.message,
    required this.isBusy,
    required this.onRetry,
  });

  final String message;
  final bool isBusy;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 58, color: color),
            const SizedBox(height: 16),
            Text(
              'Bluetooth unavailable',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isBusy)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
