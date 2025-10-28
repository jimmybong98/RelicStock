import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://localhost:8000';

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<InventorySnapshot> fetchSnapshot() async {
    final response = await _client.get(_uri('/snapshot'));
    _throwIfNeeded(response);
    return InventorySnapshot.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Item>> fetchItems() async {
    final response = await _client.get(_uri('/items'));
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((dynamic item) => Item.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Item> createItem({
    required String name,
    required String sku,
    required int quantity,
    required int minimumQuantity,
    String? description,
    int? lockerId,
    bool isSupply = false,
    int? maxReturnTimeHours,
  }) async {
    final body = jsonEncode({
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'minimum_quantity': minimumQuantity,
      'description': description,
      'locker_id': lockerId,
      'is_supply': isSupply,
      'max_return_time_hours': maxReturnTimeHours,
    });
    final response = await _client.post(
      _uri('/items'),
      headers: _jsonHeaders,
      body: body,
    );
    _throwIfNeeded(response);
    return Item.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> registerMovement({
    required int itemId,
    required int quantity,
    required String movementType,
    String? note,
  }) async {
    final response = await _client.post(
      _uri('/items/$itemId/movements'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'item_id': itemId,
        'quantity': quantity,
        'movement_type': movementType,
        'note': note,
      }),
    );
    _throwIfNeeded(response);
  }

  Future<List<InventoryMovement>> fetchMovements(int itemId) async {
    final response = await _client.get(_uri('/items/$itemId/movements'));
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((dynamic movement) =>
            InventoryMovement.fromJson(movement as Map<String, dynamic>))
        .toList();
  }

  Future<List<Locker>> fetchLockers() async {
    final response = await _client.get(_uri('/lockers'));
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((dynamic locker) => Locker.fromJson(locker as Map<String, dynamic>))
        .toList();
  }

  Future<Locker> createLocker({required String code, String? description}) async {
    final response = await _client.post(
      _uri('/lockers'),
      headers: _jsonHeaders,
      body: jsonEncode({'code': code, 'description': description}),
    );
    _throwIfNeeded(response);
    return Locker.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<PurchaseRequest>> fetchPurchaseRequests() async {
    final response = await _client.get(_uri('/purchase-requests'));
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((dynamic request) =>
            PurchaseRequest.fromJson(request as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseRequest> createPurchaseRequest({
    int? itemId,
    required String itemName,
    required int quantity,
    String? requestedBy,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/purchase-requests'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'requested_by': requestedBy,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return PurchaseRequest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<PurchaseRequest> updatePurchaseRequest({
    required int requestId,
    String? status,
    String? notes,
  }) async {
    final response = await _client.patch(
      _uri('/purchase-requests/$requestId'),
      headers: _jsonHeaders,
      body: jsonEncode({
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return PurchaseRequest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<String> fetchItemQrCode(int itemId) async {
    final response = await _client.get(_uri('/items/$itemId/qrcode'));
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['base64_data'] as String;
  }

  Future<List<SupplyWithdrawal>> fetchSupplyWithdrawals({bool pendingOnly = true}) async {
    final response = await _client.get(
      _uri('/supply-withdrawals', {'pending_only': pendingOnly.toString()}),
    );
    _throwIfNeeded(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((dynamic withdrawal) =>
            SupplyWithdrawal.fromJson(withdrawal as Map<String, dynamic>))
        .toList();
  }

  Future<SupplyWithdrawal> returnSupplyWithdrawal({
    required int withdrawalId,
    required int quantity,
    String? note,
  }) async {
    final response = await _client.post(
      _uri('/supply-withdrawals/$withdrawalId/return'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'quantity': quantity,
        if (note != null) 'note': note,
      }),
    );
    _throwIfNeeded(response);
    return SupplyWithdrawal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        response.body.isEmpty
            ? 'Erro ao comunicar com o servidor'
            : response.body,
      );
    }
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
