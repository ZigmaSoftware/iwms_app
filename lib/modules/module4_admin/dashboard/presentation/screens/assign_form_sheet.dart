import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iwms_citizen_app/core/api_config.dart';

const Color _primaryGreen = Color(0xFF2E7D32);

class _IdName {
  final String id;
  final String name;
  const _IdName(this.id, this.name);
}

class AssignFormSheet extends StatefulWidget {
  const AssignFormSheet({super.key});

  @override
  State<AssignFormSheet> createState() => _AssignFormSheetState();
}

class _AssignFormSheetState extends State<AssignFormSheet> {
  List<_IdName> wards = [];
  List<_IdName> customers = [];
  List<_IdName> drivers = [];
  List<_IdName> operators = [];

  String? wardId;
  String? customerId;
  String? driverId;
  String? operatorId;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final fetchedWards = await _fetchList('${ApiConfig.desktopBase}wards/');
      final fetchedDrivers = await _fetchList(
        '${ApiConfig.desktopBase}user/?user_type=driver',
        staffRoleFilter: 'driver',
      );
      final fetchedOperators = await _fetchList(
        '${ApiConfig.desktopBase}user/?user_type=operator',
        staffRoleFilter: 'operator',
      );
      setState(() {
        wards = fetchedWards;
        drivers = fetchedDrivers;
        operators = fetchedOperators;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Unable to load assignment data';
      });
    }
  }

  List<_IdName> _decodeIdNames(
    dynamic decoded, {
    List<String> idKeys = const [
      'unique_id',
      'id',
      'pk',
      'customer_id',
      'staff_id'
    ],
    List<String> nameKeys = const [
      'staff_name',
      'employee_name',
      'name',
      'customer_name',
      'customer_id',
      'unique_id',
      'ward_name',
      'zone_name',
      'user_type_name',
      'property_name',
      'sub_property_name',
      'city_name',
      'district_name'
    ],
  }) {
    final items = _extractItems(decoded);

    String pick(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final val = map[key];
        if (val != null && val.toString().trim().isNotEmpty)
          return val.toString();
      }
      return '';
    }

    return items
        .map((m) => _IdName(
              pick(m, idKeys),
              pick(m, nameKeys),
            ))
        .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _extractItems(dynamic decoded) {
    final items = <Map<String, dynamic>>[];
    if (decoded is List) {
      items.addAll(
          decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    } else if (decoded is Map) {
      if (decoded['results'] is List) {
        items.addAll((decoded['results'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
      } else if (decoded['data'] is List) {
        items.addAll((decoded['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
      }
    }
    return items;
  }

  Future<List<_IdName>> _fetchList(
    String url, {
    String? staffRoleFilter,
  }) async {
    final resp =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return [];
    final decoded = jsonDecode(resp.body);
    final rawItems = _extractItems(decoded);
    final items = _decodeIdNames(decoded);
    if (staffRoleFilter == null) return items;
    final role = staffRoleFilter.toLowerCase();
    final filteredIds = rawItems
        .where((m) =>
            (m['staffusertype_name'] ?? m['staffusertype'] ?? '')
                .toString()
                .toLowerCase() ==
            role)
        .map((m) => (m['unique_id'] ?? m['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (filteredIds.isEmpty) return items;
    return items.where((e) => filteredIds.contains(e.id)).toList();
  }

  Future<void> _loadCustomersForWard(String ward) async {
    setState(() {
      customerId = null;
      customers = [];
      loading = true;
    });
    try {
      final resp = await http
          .get(Uri.parse(
              '${ApiConfig.desktopBase}customercreations/?ward=$ward'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = _decodeIdNames(
          decoded,
          idKeys: const ['unique_id', 'id', 'pk'],
          nameKeys: const ['customer_name', 'name', 'unique_id'],
        );
        setState(() {
          customers = list;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<bool> _postAssignment() async {
    final payload = {
      'ward': wardId,
      'customer': customerId,
      'driver': driverId,
      'operator': operatorId,
    };

    try {
      final resp = await http
          .post(
            Uri.parse(ApiConfig.assignments),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      print("POST PAYLOAD: $payload");
      print("RESPONSE: ${resp.statusCode} ${resp.body}");

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      print("ASSIGNMENT POST FAILED: $e");
      return false;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: _primaryGreen, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _primaryGreen.withOpacity(0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _primaryGreen, width: 1.4),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: loading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Assign Driver & Operator',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('Select Ward'),
                  items: wards
                      .map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(
                              w.name,
                              style: const TextStyle(color: _primaryGreen),
                            ),
                          ))
                      .toList(),
                  value: wardId,
                  onChanged: (val) {
                    setState(() {
                      wardId = val;
                    });
                    if (val != null) {
                      _loadCustomersForWard(val);
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('Select Citizen (optional)'),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(color: _primaryGreen),
                            ),
                          ))
                      .toList(),
                  value: customerId,
                  onChanged: customers.isEmpty
                      ? null
                      : (val) => setState(() => customerId = val),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('Select Driver'),
                  items: drivers
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              d.name,
                              style: const TextStyle(color: _primaryGreen),
                            ),
                          ))
                      .toList(),
                  value: driverId,
                  onChanged: (val) => setState(() => driverId = val),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('Select Operator'),
                  items: operators
                      .map((o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              o.name,
                              style: const TextStyle(color: _primaryGreen),
                            ),
                          ))
                      .toList(),
                  value: operatorId,
                  onChanged: (val) => setState(() => operatorId = val),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (wardId != null &&
                            driverId != null &&
                            operatorId != null)
                        ? () async {
                            final success = await _postAssignment();
                            if (!mounted) return;
                            if (success) {
                              Navigator.of(context).maybePop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Assignment saved and shared with driver/operator'),
                                  backgroundColor: _primaryGreen,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Failed to assign. Please retry.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Assign'),
                  ),
                ),
              ],
            ),
    );
  }
}
