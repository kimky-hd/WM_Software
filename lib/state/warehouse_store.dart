import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/app_storage.dart';
import '../data/mock_data.dart';
import '../models/adjustment_note.dart';
import '../models/batch.dart';
import '../models/damage_expired_note.dart';
import '../models/enums.dart';
import '../models/inbound_note.dart';
import '../models/outbound_note.dart';
import '../models/product.dart';
import '../models/return_supplier_note.dart';
import '../models/stock_check_note.dart';
import '../models/supplier.dart';
import '../models/unit.dart';

/// Một phần đề xuất xuất kho từ 1 lô cụ thể, dùng cho gợi ý FEFO.
class BatchAllocation {
  final Batch batch;
  final double quantity;

  const BatchAllocation({required this.batch, required this.quantity});
}

/// Store trung tâm cho nghiệp vụ kho: danh mục dùng chung + toàn bộ chứng từ.
/// Dữ liệu được lưu tạm thời bằng SharedPreferences (theo README).
class WarehouseStore extends ChangeNotifier {
  WarehouseStore(this._storage);

  final AppStorage _storage;
  final _uuid = const Uuid();
  bool _isLoading = true;

  List<Product> products = [];
  List<UnitOfMeasure> units = [];
  List<Supplier> suppliers = [];
  List<Batch> batches = [];
  List<InboundNote> inboundNotes = [];
  List<OutboundNote> outboundNotes = [];
  List<StockCheckNote> stockCheckNotes = [];
  List<AdjustmentNote> adjustmentNotes = [];
  List<ReturnSupplierNote> returnSupplierNotes = [];
  List<DamageExpiredNote> damageExpiredNotes = [];

  bool get isLoading => _isLoading;

  Future<void> init() async {
    final seeded = await _storage.isSeeded();
    if (!seeded) {
      products = MockData.products;
      units = MockData.units;
      suppliers = MockData.suppliers;
      batches = MockData.seedBatches();
      await _persistAll();
      await _storage.markSeeded();
    } else {
      await _loadAll();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---------- Lookups ----------

  Product? productById(String id) => products.where((p) => p.id == id).firstOrNullX;

  UnitOfMeasure? unitById(String id) => units.where((u) => u.id == id).firstOrNullX;

  Supplier? supplierById(String id) => suppliers.where((s) => s.id == id).firstOrNullX;

  Batch? batchById(String id) => batches.where((b) => b.id == id).firstOrNullX;

  double totalStockForProduct(String productId) => batches
      .where((b) => b.productId == productId)
      .fold(0.0, (sum, b) => sum + b.quantityRemaining);

  /// Các lô còn hàng của 1 sản phẩm, sắp xếp theo HSD gần nhất trước (FEFO).
  List<Batch> availableBatchesForProduct(String productId) {
    final list = batches.where((b) => b.productId == productId && b.quantityRemaining > 0).toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  /// Gợi ý phân bổ xuất kho theo FEFO cho 1 số lượng cần xuất.
  List<BatchAllocation> suggestFefoAllocation(String productId, double requestedQty) {
    final result = <BatchAllocation>[];
    var remaining = requestedQty;
    for (final batch in availableBatchesForProduct(productId)) {
      if (remaining <= 0) break;
      final take = remaining < batch.quantityRemaining ? remaining : batch.quantityRemaining;
      result.add(BatchAllocation(batch: batch, quantity: take));
      remaining -= take;
    }
    return result;
  }

  String _generateCode(String prefix, int existingCount) {
    final now = DateTime.now();
    final ymd = '${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final seq = (existingCount + 1).toString().padLeft(3, '0');
    return '$prefix-$ymd-$seq';
  }

  // ---------- Tạo phiếu (Nhân viên kho) ----------

  Future<InboundNote> createInboundNote({
    required String supplierId,
    required String createdBy,
    required List<InboundNoteDetail> details,
  }) async {
    final note = InboundNote(
      id: _uuid.v4(),
      code: _generateCode('PN', inboundNotes.length),
      createdAt: DateTime.now(),
      createdBy: createdBy,
      status: DocumentStatus.pendingApproval,
      supplierId: supplierId,
      details: details,
    );
    inboundNotes = [note, ...inboundNotes];
    await _persist(StorageKeys.inboundNotes, inboundNotes.map((e) => e.toJson()).toList());
    notifyListeners();
    return note;
  }

  Future<OutboundNote> createOutboundNote({
    required String purpose,
    required String createdBy,
    required List<OutboundNoteDetail> details,
  }) async {
    final note = OutboundNote(
      id: _uuid.v4(),
      code: _generateCode('PX', outboundNotes.length),
      createdAt: DateTime.now(),
      createdBy: createdBy,
      status: DocumentStatus.pendingApproval,
      purpose: purpose,
      details: details,
    );
    outboundNotes = [note, ...outboundNotes];
    await _persist(StorageKeys.outboundNotes, outboundNotes.map((e) => e.toJson()).toList());
    notifyListeners();
    return note;
  }

  Future<StockCheckNote> createStockCheckNote({
    required String performedBy,
    required List<StockCheckDetail> details,
  }) async {
    final note = StockCheckNote(
      id: _uuid.v4(),
      code: _generateCode('KK', stockCheckNotes.length),
      checkDate: DateTime.now(),
      performedBy: performedBy,
      status: DocumentStatus.pendingApproval,
      details: details,
    );
    stockCheckNotes = [note, ...stockCheckNotes];
    await _persist(StorageKeys.stockCheckNotes, stockCheckNotes.map((e) => e.toJson()).toList());
    notifyListeners();
    return note;
  }

  Future<AdjustmentNote> createAdjustmentNote({
    required String productId,
    String? batchId,
    required double adjustQty,
    required String reason,
    required String proposedBy,
  }) async {
    final note = AdjustmentNote(
      id: _uuid.v4(),
      code: _generateCode('DC', adjustmentNotes.length),
      createdAt: DateTime.now(),
      productId: productId,
      batchId: batchId,
      adjustQty: adjustQty,
      reason: reason,
      proposedBy: proposedBy,
      status: DocumentStatus.pendingApproval,
    );
    adjustmentNotes = [note, ...adjustmentNotes];
    await _persist(StorageKeys.adjustmentNotes, adjustmentNotes.map((e) => e.toJson()).toList());
    notifyListeners();
    return note;
  }

  Future<ReturnSupplierNote> createReturnSupplierNote({
    required String supplierId,
    required String batchId,
    required double quantity,
    required String reason,
    required String createdBy,
  }) async {
    final note = ReturnSupplierNote(
      id: _uuid.v4(),
      code: _generateCode('TH', returnSupplierNotes.length),
      createdAt: DateTime.now(),
      supplierId: supplierId,
      batchId: batchId,
      quantity: quantity,
      reason: reason,
      createdBy: createdBy,
      status: DocumentStatus.pendingApproval,
    );
    returnSupplierNotes = [note, ...returnSupplierNotes];
    await _persist(StorageKeys.returnSupplierNotes, returnSupplierNotes.map((e) => e.toJson()).toList());
    notifyListeners();
    return note;
  }

  Future<DamageExpiredNote> createDamageExpiredNote({
    required String batchId,
    required double quantity,
    required DamageType type,
    required String reason,
    required String createdBy,
  }) async {
    final note = DamageExpiredNote(
      id: _uuid.v4(),
      code: _generateCode('HH', damageExpiredNotes.length),
      createdAt: DateTime.now(),
      batchId: batchId,
      quantity: quantity,
      type: type,
      reason: reason,
      createdBy: createdBy,
      status: DocumentStatus.pendingApproval,
    );
    damageExpiredNotes = [note, ...damageExpiredNotes];
    await _persist(StorageKeys.damageExpiredNotes, damageExpiredNotes.map((e) => e.toJson()).toList());
    notifyListeners();
    return note;
  }

  // ---------- Persistence ----------

  Future<void> _persist(String key, List<Map<String, dynamic>> data) => _storage.saveList(key, data);

  Future<void> _persistAll() async {
    await _persist(StorageKeys.products, products.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.units, units.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.suppliers, suppliers.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.inboundNotes, inboundNotes.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.outboundNotes, outboundNotes.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.stockCheckNotes, stockCheckNotes.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.adjustmentNotes, adjustmentNotes.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.returnSupplierNotes, returnSupplierNotes.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.damageExpiredNotes, damageExpiredNotes.map((e) => e.toJson()).toList());
  }

  Future<void> _loadAll() async {
    products = (await _storage.loadList(StorageKeys.products)).map(Product.fromJson).toList();
    units = (await _storage.loadList(StorageKeys.units)).map(UnitOfMeasure.fromJson).toList();
    suppliers = (await _storage.loadList(StorageKeys.suppliers)).map(Supplier.fromJson).toList();
    batches = (await _storage.loadList(StorageKeys.batches)).map(Batch.fromJson).toList();
    inboundNotes = (await _storage.loadList(StorageKeys.inboundNotes)).map(InboundNote.fromJson).toList();
    outboundNotes = (await _storage.loadList(StorageKeys.outboundNotes)).map(OutboundNote.fromJson).toList();
    stockCheckNotes =
        (await _storage.loadList(StorageKeys.stockCheckNotes)).map(StockCheckNote.fromJson).toList();
    adjustmentNotes =
        (await _storage.loadList(StorageKeys.adjustmentNotes)).map(AdjustmentNote.fromJson).toList();
    returnSupplierNotes = (await _storage.loadList(StorageKeys.returnSupplierNotes))
        .map(ReturnSupplierNote.fromJson)
        .toList();
    damageExpiredNotes = (await _storage.loadList(StorageKeys.damageExpiredNotes))
        .map(DamageExpiredNote.fromJson)
        .toList();
  }
}

extension FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNullX => isEmpty ? null : first;
}
