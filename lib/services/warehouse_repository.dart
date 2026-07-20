import '../models/adjustment_note_model.dart';
import '../models/batch_model.dart';
import '../models/damage_note_model.dart';
import '../models/inbound_note_model.dart';
import '../models/outbound_note_model.dart';
import '../models/product_model.dart';
import '../models/return_supplier_note_model.dart';
import '../models/stock_check_note_model.dart';
import '../models/supplier_model.dart';
import '../models/unit_model.dart';
import 'shared_prefs_service.dart';

/// Kết quả gợi ý phân bổ lô theo nguyên tắc FEFO (First Expired, First Out)
/// cho 1 dòng sản phẩm trên phiếu xuất kho.
class FefoAllocationLine {
  final BatchModel batch;
  final int quantity;

  FefoAllocationLine({required this.batch, required this.quantity});
}

/// Tầng dữ liệu (repository) dùng chung cho các màn hình nghiệp vụ kho,
/// bọc quanh [SharedPrefsService] để tránh lặp code đọc/ghi ở từng màn hình.
class WarehouseRepository {
  WarehouseRepository._privateConstructor();
  static final WarehouseRepository instance = WarehouseRepository._privateConstructor();

  static const String currentStaffName = 'Trần Văn Nhân viên';

  static const _keyProducts = 'products';
  static const _keySuppliers = 'suppliers';
  static const _keyUnits = 'units';
  static const _keyBatches = 'batches';
  static const _keyInboundNotes = 'inbound_notes';
  static const _keyOutboundNotes = 'outbound_notes';
  static const _keyStockCheckNotes = 'stock_check_notes';
  static const _keyAdjustmentNotes = 'adjustment_notes';
  static const _keyReturnNotes = 'return_supplier_notes';
  static const _keyDamageNotes = 'damage_notes';

  final SharedPrefsService _prefs = SharedPrefsService.instance;

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  String generateNoteCode(String prefix) {
    final now = DateTime.now();
    return '$prefix${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 100000}';
  }

  // ---------------- Danh mục dùng chung ----------------

  List<ProductModel> getProducts() => _prefs.getDataList(_keyProducts, ProductModel.fromJson);

  List<SupplierModel> getSuppliers() => _prefs.getDataList(_keySuppliers, SupplierModel.fromJson);

  List<UnitModel> getUnits() => _prefs.getDataList(_keyUnits, UnitModel.fromJson);

  ProductModel? findProduct(String productId) {
    final list = getProducts();
    for (final p in list) {
      if (p.id == productId) return p;
    }
    return null;
  }

  SupplierModel? findSupplier(String supplierId) {
    final list = getSuppliers();
    for (final s in list) {
      if (s.id == supplierId) return s;
    }
    return null;
  }

  // ---------------- Lô hàng (Batch) ----------------

  List<BatchModel> getBatches() => _prefs.getDataList(_keyBatches, BatchModel.fromJson);

  Future<bool> saveBatches(List<BatchModel> batches) =>
      _prefs.saveDataList(_keyBatches, batches, (b) => b.toJson());

  List<BatchModel> getBatchesForProduct(String productId) {
    return getBatches().where((b) => b.productId == productId).toList();
  }

  /// Các lô còn hàng, sắp xếp theo HSD tăng dần (lô hết hạn sớm nhất trước).
  List<BatchModel> getAvailableBatches(String productId) {
    final batches = getBatchesForProduct(productId).where((b) => b.quantityRemaining > 0).toList();
    batches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return batches;
  }

  int getStockQuantity(String productId) {
    return getBatchesForProduct(productId).fold(0, (sum, b) => sum + b.quantityRemaining);
  }

  BatchModel? findBatch(String batchId) {
    for (final b in getBatches()) {
      if (b.id == batchId) return b;
    }
    return null;
  }

  Future<void> addBatchFromInbound(InboundNoteDetail detail) async {
    final batches = getBatches();
    batches.add(BatchModel(
      id: _generateId(),
      productId: detail.productId,
      batchCode: detail.batchCode,
      manufactureDate: detail.manufactureDate,
      expiryDate: detail.expiryDate,
      quantityImported: detail.quantity,
      quantityRemaining: detail.quantity,
    ));
    await saveBatches(batches);
  }

  /// Gợi ý phân bổ lô theo FEFO cho 1 sản phẩm + số lượng cần xuất.
  /// Có thể không đủ hàng — phần thiếu sẽ không được phân bổ.
  List<FefoAllocationLine> suggestFefoAllocation(String productId, int requestedQty) {
    final result = <FefoAllocationLine>[];
    var remaining = requestedQty;
    for (final batch in getAvailableBatches(productId)) {
      if (remaining <= 0) break;
      final take = remaining < batch.quantityRemaining ? remaining : batch.quantityRemaining;
      if (take > 0) {
        result.add(FefoAllocationLine(batch: batch, quantity: take));
        remaining -= take;
      }
    }
    return result;
  }

  // ---------------- Phiếu nhập kho ----------------

  List<InboundNoteModel> getInboundNotes() =>
      _prefs.getDataList(_keyInboundNotes, InboundNoteModel.fromJson);

  Future<void> saveInboundNote(InboundNoteModel note) async {
    final notes = getInboundNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await _prefs.saveDataList(_keyInboundNotes, notes, (n) => n.toJson());
  }

  Future<void> deleteInboundNote(String id) async {
    final notes = getInboundNotes()..removeWhere((n) => n.id == id);
    await _prefs.saveDataList(_keyInboundNotes, notes, (n) => n.toJson());
  }

  // ---------------- Phiếu xuất kho ----------------

  List<OutboundNoteModel> getOutboundNotes() =>
      _prefs.getDataList(_keyOutboundNotes, OutboundNoteModel.fromJson);

  Future<void> saveOutboundNote(OutboundNoteModel note) async {
    final notes = getOutboundNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await _prefs.saveDataList(_keyOutboundNotes, notes, (n) => n.toJson());
  }

  Future<void> deleteOutboundNote(String id) async {
    final notes = getOutboundNotes()..removeWhere((n) => n.id == id);
    await _prefs.saveDataList(_keyOutboundNotes, notes, (n) => n.toJson());
  }

  // ---------------- Phiếu kiểm kê ----------------

  List<StockCheckNoteModel> getStockCheckNotes() =>
      _prefs.getDataList(_keyStockCheckNotes, StockCheckNoteModel.fromJson);

  Future<void> saveStockCheckNote(StockCheckNoteModel note) async {
    final notes = getStockCheckNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await _prefs.saveDataList(_keyStockCheckNotes, notes, (n) => n.toJson());
  }

  Future<void> deleteStockCheckNote(String id) async {
    final notes = getStockCheckNotes()..removeWhere((n) => n.id == id);
    await _prefs.saveDataList(_keyStockCheckNotes, notes, (n) => n.toJson());
  }

  // ---------------- Đề xuất điều chỉnh tồn ----------------

  List<AdjustmentNoteModel> getAdjustmentNotes() =>
      _prefs.getDataList(_keyAdjustmentNotes, AdjustmentNoteModel.fromJson);

  Future<void> saveAdjustmentNote(AdjustmentNoteModel note) async {
    final notes = getAdjustmentNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await _prefs.saveDataList(_keyAdjustmentNotes, notes, (n) => n.toJson());
  }

  Future<void> deleteAdjustmentNote(String id) async {
    final notes = getAdjustmentNotes()..removeWhere((n) => n.id == id);
    await _prefs.saveDataList(_keyAdjustmentNotes, notes, (n) => n.toJson());
  }

  // ---------------- Phiếu trả hàng NCC ----------------

  List<ReturnSupplierNoteModel> getReturnNotes() =>
      _prefs.getDataList(_keyReturnNotes, ReturnSupplierNoteModel.fromJson);

  Future<void> saveReturnNote(ReturnSupplierNoteModel note) async {
    final notes = getReturnNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await _prefs.saveDataList(_keyReturnNotes, notes, (n) => n.toJson());
  }

  Future<void> deleteReturnNote(String id) async {
    final notes = getReturnNotes()..removeWhere((n) => n.id == id);
    await _prefs.saveDataList(_keyReturnNotes, notes, (n) => n.toJson());
  }

  // ---------------- Phiếu hàng hỏng/hết hạn ----------------

  List<DamageNoteModel> getDamageNotes() => _prefs.getDataList(_keyDamageNotes, DamageNoteModel.fromJson);

  Future<void> saveDamageNote(DamageNoteModel note) async {
    final notes = getDamageNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await _prefs.saveDataList(_keyDamageNotes, notes, (n) => n.toJson());
  }

  Future<void> deleteDamageNote(String id) async {
    final notes = getDamageNotes()..removeWhere((n) => n.id == id);
    await _prefs.saveDataList(_keyDamageNotes, notes, (n) => n.toJson());
  }

  // ---------------- ID sinh mới cho phiếu/chi tiết dùng ở UI ----------------

  String newId() => _generateId();

  // ---------------- Seed dữ liệu mẫu ----------------

  Future<void> seedSampleDataIfEmpty() async {
    if (getProducts().isNotEmpty) return;

    final units = [
      UnitModel(id: 'u1', unitName: 'kg', conversionFactor: 1),
      UnitModel(id: 'u2', unitName: 'bao (25kg)', conversionFactor: 25),
      UnitModel(id: 'u3', unitName: 'tấn', conversionFactor: 1000),
    ];
    await _prefs.saveDataList(_keyUnits, units, (u) => u.toJson());

    final suppliers = [
      SupplierModel(id: 's1', name: 'Công ty TNHH Nông sản Miền Tây', contact: '0901 234 567', taxCode: '0301234567'),
      SupplierModel(id: 's2', name: 'HTX Ngũ cốc An Giang', contact: '0912 345 678', taxCode: '1600987654'),
    ];
    await _prefs.saveDataList(_keySuppliers, suppliers, (s) => s.toJson());

    final products = [
      ProductModel(id: 'p1', productCode: 'SP001', name: 'Gạo ST25', category: 'Gạo', unit: 'kg', minStockLevel: 200),
      ProductModel(id: 'p2', productCode: 'SP002', name: 'Đậu xanh', category: 'Đồ khô', unit: 'kg', minStockLevel: 100),
      ProductModel(id: 'p3', productCode: 'SP003', name: 'Yến mạch', category: 'Ngũ cốc', unit: 'kg', minStockLevel: 150),
      ProductModel(id: 'p4', productCode: 'SP004', name: 'Hạt điều rang muối', category: 'Hạt', unit: 'kg', minStockLevel: 50),
      ProductModel(id: 'p5', productCode: 'SP005', name: 'Đường trắng', category: 'Đồ khô', unit: 'kg', minStockLevel: 300),
    ];
    await _prefs.saveDataList(_keyProducts, products, (p) => p.toJson());

    final now = DateTime.now();
    final batches = [
      BatchModel(
        id: 'b1',
        productId: 'p1',
        batchCode: 'LOT-P1-01',
        manufactureDate: now.subtract(const Duration(days: 60)),
        expiryDate: now.add(const Duration(days: 10)),
        quantityImported: 300,
        quantityRemaining: 120,
      ),
      BatchModel(
        id: 'b2',
        productId: 'p1',
        batchCode: 'LOT-P1-02',
        manufactureDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.add(const Duration(days: 180)),
        quantityImported: 400,
        quantityRemaining: 400,
      ),
      BatchModel(
        id: 'b3',
        productId: 'p2',
        batchCode: 'LOT-P2-01',
        manufactureDate: now.subtract(const Duration(days: 20)),
        expiryDate: now.add(const Duration(days: 5)),
        quantityImported: 80,
        quantityRemaining: 40,
      ),
      BatchModel(
        id: 'b4',
        productId: 'p3',
        batchCode: 'LOT-P3-01',
        manufactureDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(const Duration(days: 90)),
        quantityImported: 200,
        quantityRemaining: 180,
      ),
      BatchModel(
        id: 'b5',
        productId: 'p4',
        batchCode: 'LOT-P4-01',
        manufactureDate: now.subtract(const Duration(days: 5)),
        expiryDate: now.add(const Duration(days: 200)),
        quantityImported: 60,
        quantityRemaining: 20,
      ),
      BatchModel(
        id: 'b6',
        productId: 'p5',
        batchCode: 'LOT-P5-01',
        manufactureDate: now.subtract(const Duration(days: 15)),
        expiryDate: now.add(const Duration(days: 365)),
        quantityImported: 500,
        quantityRemaining: 500,
      ),
    ];
    await saveBatches(batches);
  }
}
