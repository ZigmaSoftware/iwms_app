import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:iwms_citizen_app/router/route_observer.dart';
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

class _OperatorDataScreenState extends State<OperatorDataScreen>
    with WidgetsBindingObserver, RouteAware {
  final ImagePicker _picker = ImagePicker();
  final OperatorBluetoothService bluetooth = OperatorBluetoothService();

  late String screenUniqueId;
  BluetoothConnection? _connection;
  bool connected = false;
  bool _isSubmitting = false;
  String latestWeight = "--";
  String? activeType;

  List<Map<String, dynamic>> wasteTypes = [];
  Map<String, Map<String, dynamic>> _wasteData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    screenUniqueId = OperatorUniqueIdService.generateScreenId();
    _wasteData.clear();
    latestWeight = "--";

    Future.delayed(const Duration(seconds: 1), () async {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      await FlutterBluetoothSerial.instance.requestEnable();
      await _resetBluetooth();
      await _initBluetooth();
    });

    _fetchWasteTypes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _connection?.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _reconnectBluetoothWithRetry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !connected) {
      _initBluetooth();
    }
  }

  Future<void> _resetBluetooth() async {
    try {
      await _connection?.close();
      _connection = null;
      connected = false;
    } catch (_) {}
  }

  Future<void> _reconnectBluetoothWithRetry({int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        await _resetBluetooth();
        await _initBluetooth();
        if (connected) {
          return;
        }
      } catch (e) {
        debugPrint('Retry ${i + 1} failed: $e');
      }
    }
  }

  Future<void> _initBluetooth() async {
    if (connected) return;

    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    if (devices.isEmpty) {
      debugPrint('No bonded Bluetooth devices found.');
      return;
    }

    final hc05 = devices.firstWhere(
      (d) => (d.name ?? '').toUpperCase().contains('AEBT'),
      orElse: () => devices.first,
    );

    try {
      debugPrint('Connecting to ${hc05.name}...');
      final conn = await BluetoothConnection.toAddress(hc05.address);
      if (!mounted) return;

      setState(() {
        _connection = conn;
        connected = true;
      });

      String buffer = '';
      conn.input?.listen((Uint8List data) {
        final text = utf8.decode(data);
        buffer += text;
        if (buffer.contains('\n')) {
          final parts = buffer.split('\n');
          for (final line in parts.take(parts.length - 1)) {
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
      debugPrint('Bluetooth connection error: $e');
    }
  }

  Future<void> _fetchWasteTypes() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.4.75:8000/get-waste-types/'));
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        if (!mounted) return;
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
          latestWeight = "--";
          screenUniqueId = OperatorUniqueIdService.generateScreenId();
        });
      }
    } catch (e) {
      debugPrint('Error fetching waste types: $e');
    }
  }

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
      final uri = Uri.parse('http://192.168.4.75:8000/get-latest-waste/');
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

        debugPrint('Backend weight for $type: ${record['weight']}');
      } else {
        debugPrint('No record found for $type: ${data['message']}');
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
            ? 'http://192.168.4.75:8000/update-waste-sub/'
            : 'http://192.168.4.75:8000/insert-waste-sub/',
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

      dynamic result;
      try {
        result = json.decode(resBody.body);
      } catch (_) {
        _showSnack('Invalid JSON from server');
        setState(() => _isSubmitting = false);
        return;
      }

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
      debugPrint('Error saving $type: $e');
      if (mounted) {
        _showSnack('Error saving $type: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('http://192.168.4.75:8000/finalize-waste/');
      final request = http.MultipartRequest('POST', uri)
        ..fields['screen_unique_id'] = screenUniqueId
        ..fields['customer_id'] = widget.customerId
        ..fields['entry_type'] = 'app'
        ..fields['collected_date_time'] = DateTime.now().toIso8601String()
        ..fields['total_waste_collected'] =
            _wasteData.values.fold<double>(0, (sum, e) {
          final weightValue = double.tryParse(
                  e['finalWeight']?.toString() ?? e['weight'].toString()) ??
              0;
          return sum + weightValue;
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

  void _showDialog(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
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

  Widget _buildCustomerInfo() => Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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

  Widget _infoTile(String label, String value) => ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      );

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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 61, 125, 0.8),
        title: const Text("Customer Details"),
      ),
      body: wasteTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.blueGrey.shade50,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                          final type =
                              w['waste_type_name'].toString().toLowerCase();
                          final name = w['waste_type_name'];
                          return _buildWasteSection(type, name);
                        }),
                        const SizedBox(height: 25),
                        _isSubmitting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(0, 61, 125, 0.8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 12),
                                ),
                                onPressed: _submitForm,
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
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
