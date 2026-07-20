import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/app_storage.dart';
import '../data/mock_data.dart';
import '../models/adjustment_note.dart';
import '../models/audit_log.dart';
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
import '../models/user.dart';

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
  List<AuditLogEntry> auditLogs = [];

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

  // ---------- Cảnh báo (tồn kho thấp / sắp hết hạn / hết hạn) ----------

  /// Sản phẩm có tổng tồn dưới mức tối thiểu.
  List<Product> get lowStockProducts =>
      products.where((p) => totalStockForProduct(p.id) < p.minStock).toList();

  /// Lô còn hàng, sắp hết hạn trong [withinDays] ngày tới (chưa hết hạn).
  List<Batch> expiringSoonBatches({int withinDays = 7}) => batches
      .where((b) => b.quantityRemaining > 0 && !b.isExpired && b.daysToExpiry <= withinDays)
      .toList()
    ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

  /// Lô còn hàng nhưng đã quá hạn sử dụng, chưa được xử lý (hàng hỏng/hết hạn).
  List<Batch> get expiredBatches =>
      batches.where((b) => b.quantityRemaining > 0 && b.isExpired).toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

  /// Tổng số phiếu đang chờ Quản lý kho duyệt (dùng cho dashboard & badge).
  int get pendingApprovalCount =>
      inboundNotes.where((n) => n.status == DocumentStatus.pendingApproval).length +
      outboundNotes.where((n) => n.status == DocumentStatus.pendingApproval).length +
      stockCheckNotes.where((n) => n.status == DocumentStatus.pendingApproval).length +
      adjustmentNotes.where((n) => n.status == DocumentStatus.pendingApproval).length +
      returnSupplierNotes.where((n) => n.status == DocumentStatus.pendingApproval).length +
      damageExpiredNotes.where((n) => n.status == DocumentStatus.pendingApproval).length;

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

  // ---------- Nhà cung cấp (Quản lý kho: Thêm/sửa) ----------

  Future<void> addSupplier(Supplier supplier) async {
    suppliers = [...suppliers, supplier];
    await _persist(StorageKeys.suppliers, suppliers.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    suppliers = suppliers.map((s) => s.id == supplier.id ? supplier : s).toList();
    await _persist(StorageKeys.suppliers, suppliers.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  /// Quản lý kho chỉ được "đề xuất sửa" danh mục sản phẩm (Admin mới có toàn quyền
  /// sửa) - đề xuất được ghi vào Audit Log để Admin xem xét sau.
  Future<void> proposeProductEdit(Product product, {required AppUser actor, required String suggestion}) async {
    await addLog(
      actorId: actor.id,
      actorName: actor.name,
      action: 'Đề xuất sửa sản phẩm',
      targetCode: product.code,
      note: suggestion,
    );
    notifyListeners();
  }

  // ---------- Nhật ký hoạt động (Audit Log) ----------

  Future<void> addLog({
    required String actorId,
    required String actorName,
    required String action,
    required String targetCode,
    String? note,
  }) async {
    final entry = AuditLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      actorId: actorId,
      actorName: actorName,
      action: action,
      targetCode: targetCode,
      note: note,
    );
    auditLogs = [entry, ...auditLogs];
    await _persist(StorageKeys.auditLogs, auditLogs.map((e) => e.toJson()).toList());
  }

  Batch _updateBatchQty(String batchId, double delta) {
    Batch? updated;
    batches = batches.map((b) {
      if (b.id != batchId) return b;
      updated = b.copyWith(quantityRemaining: (b.quantityRemaining + delta).clamp(0, double.infinity));
      return updated!;
    }).toList();
    return updated!;
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

  // ---------- Duyệt / Từ chối / Huỷ (Quản lý kho) ----------
  // Trả về null nếu thành công, ngược lại là thông báo lỗi để hiển thị cho người dùng.

  Future<String?> approveInboundNote(InboundNote note, {required AppUser approver}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    final newBatches = note.details
        .map((d) => Batch(
              id: _uuid.v4(),
              productId: d.productId,
              batchCode: d.batchCode,
              manufactureDate: d.manufactureDate,
              expiryDate: d.expiryDate,
              quantityIn: d.quantity,
              quantityRemaining: d.quantity,
              sourceNoteId: note.id,
            ))
        .toList();
    batches = [...batches, ...newBatches];
    inboundNotes = inboundNotes
        .map((n) => n.id == note.id ? n.copyWith(status: DocumentStatus.approved, approvedBy: approver.id) : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.inboundNotes, inboundNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Duyệt phiếu nhập kho',
      targetCode: note.code,
    );
    notifyListeners();
    return null;
  }

  Future<String?> rejectInboundNote(InboundNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    inboundNotes = inboundNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.rejected, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.inboundNotes, inboundNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Từ chối phiếu nhập kho',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> cancelInboundNote(InboundNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.approved) return 'Chỉ có thể huỷ phiếu đã duyệt';

    batches = batches
        .map((b) => b.sourceNoteId == note.id ? b.copyWith(quantityRemaining: 0) : b)
        .toList();
    inboundNotes = inboundNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.cancelled, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.inboundNotes, inboundNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Huỷ phiếu nhập kho',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> approveOutboundNote(OutboundNote note, {required AppUser approver}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    for (final d in note.details) {
      final batch = batchById(d.batchId);
      if (batch == null || batch.quantityRemaining < d.quantity) {
        return 'Lô hàng cho "${productById(d.productId)?.name ?? d.productId}" không còn đủ tồn để duyệt phiếu này';
      }
    }
    for (final d in note.details) {
      _updateBatchQty(d.batchId, -d.quantity);
    }
    outboundNotes = outboundNotes
        .map((n) => n.id == note.id ? n.copyWith(status: DocumentStatus.approved, approvedBy: approver.id) : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.outboundNotes, outboundNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Duyệt phiếu xuất kho',
      targetCode: note.code,
    );
    notifyListeners();
    return null;
  }

  Future<String?> rejectOutboundNote(OutboundNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    outboundNotes = outboundNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.rejected, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.outboundNotes, outboundNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Từ chối phiếu xuất kho',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> cancelOutboundNote(OutboundNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.approved) return 'Chỉ có thể huỷ phiếu đã duyệt';

    for (final d in note.details) {
      _updateBatchQty(d.batchId, d.quantity);
    }
    outboundNotes = outboundNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.cancelled, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.outboundNotes, outboundNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Huỷ phiếu xuất kho',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  /// Kiểm kê chỉ ghi nhận chênh lệch - không tự sửa tồn kho (việc sửa tồn thực hiện
  /// qua Phiếu điều chỉnh riêng theo đúng luồng nghiệp vụ trong README).
  Future<String?> approveStockCheckNote(StockCheckNote note, {required AppUser approver}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    stockCheckNotes = stockCheckNotes
        .map((n) => n.id == note.id ? n.copyWith(status: DocumentStatus.approved, approvedBy: approver.id) : n)
        .toList();
    await _persist(StorageKeys.stockCheckNotes, stockCheckNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Duyệt phiếu kiểm kê',
      targetCode: note.code,
    );
    notifyListeners();
    return null;
  }

  Future<String?> rejectStockCheckNote(StockCheckNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    stockCheckNotes = stockCheckNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.rejected, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.stockCheckNotes, stockCheckNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Từ chối phiếu kiểm kê',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> cancelStockCheckNote(StockCheckNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.approved) return 'Chỉ có thể huỷ phiếu đã duyệt';

    stockCheckNotes = stockCheckNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.cancelled, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.stockCheckNotes, stockCheckNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Huỷ phiếu kiểm kê',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  /// Chọn lô để áp dụng điều chỉnh khi phiếu không chỉ định sẵn: ưu tiên lô hết hạn
  /// gần nhất còn hàng (FEFO); nếu tăng tồn mà chưa có lô nào thì bỏ qua bước trừ/cộng.
  String? _resolveAdjustmentBatchId(AdjustmentNote note) {
    if (note.batchId != null) return note.batchId;
    final candidates = availableBatchesForProduct(note.productId);
    return candidates.isEmpty ? null : candidates.first.id;
  }

  Future<String?> approveAdjustmentNote(AdjustmentNote note, {required AppUser approver}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    final resolvedBatchId = _resolveAdjustmentBatchId(note);
    if (resolvedBatchId == null) {
      return 'Không có lô hàng nào của sản phẩm này để áp dụng điều chỉnh';
    }
    final batch = batchById(resolvedBatchId)!;
    if (note.adjustQty < 0 && batch.quantityRemaining < -note.adjustQty) {
      return 'Lô ${batch.batchCode} chỉ còn ${batch.quantityRemaining.toStringAsFixed(0)}, không đủ để giảm';
    }

    _updateBatchQty(resolvedBatchId, note.adjustQty);
    adjustmentNotes = adjustmentNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.approved, approvedBy: approver.id, batchId: resolvedBatchId)
            : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.adjustmentNotes, adjustmentNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Duyệt phiếu điều chỉnh tồn',
      targetCode: note.code,
    );
    notifyListeners();
    return null;
  }

  Future<String?> rejectAdjustmentNote(AdjustmentNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    adjustmentNotes = adjustmentNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.rejected, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.adjustmentNotes, adjustmentNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Từ chối phiếu điều chỉnh tồn',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> cancelAdjustmentNote(AdjustmentNote note, {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.approved) return 'Chỉ có thể huỷ phiếu đã duyệt';

    if (note.batchId != null) {
      _updateBatchQty(note.batchId!, -note.adjustQty);
    }
    adjustmentNotes = adjustmentNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.cancelled, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.adjustmentNotes, adjustmentNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Huỷ phiếu điều chỉnh tồn',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> approveReturnSupplierNote(ReturnSupplierNote note, {required AppUser approver}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    final batch = batchById(note.batchId);
    if (batch == null || batch.quantityRemaining < note.quantity) {
      return 'Lô hàng không còn đủ tồn để duyệt phiếu trả hàng này';
    }
    _updateBatchQty(note.batchId, -note.quantity);
    returnSupplierNotes = returnSupplierNotes
        .map((n) => n.id == note.id ? n.copyWith(status: DocumentStatus.approved, approvedBy: approver.id) : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.returnSupplierNotes, returnSupplierNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Duyệt phiếu trả hàng NCC',
      targetCode: note.code,
    );
    notifyListeners();
    return null;
  }

  Future<String?> rejectReturnSupplierNote(ReturnSupplierNote note,
      {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    returnSupplierNotes = returnSupplierNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.rejected, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.returnSupplierNotes, returnSupplierNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Từ chối phiếu trả hàng NCC',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> cancelReturnSupplierNote(ReturnSupplierNote note,
      {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.approved) return 'Chỉ có thể huỷ phiếu đã duyệt';

    _updateBatchQty(note.batchId, note.quantity);
    returnSupplierNotes = returnSupplierNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.cancelled, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.returnSupplierNotes, returnSupplierNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Huỷ phiếu trả hàng NCC',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> approveDamageExpiredNote(DamageExpiredNote note, {required AppUser approver}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    final batch = batchById(note.batchId);
    if (batch == null || batch.quantityRemaining < note.quantity) {
      return 'Lô hàng không còn đủ tồn để duyệt phiếu này';
    }
    _updateBatchQty(note.batchId, -note.quantity);
    damageExpiredNotes = damageExpiredNotes
        .map((n) => n.id == note.id ? n.copyWith(status: DocumentStatus.approved, approvedBy: approver.id) : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.damageExpiredNotes, damageExpiredNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Duyệt phiếu hàng hỏng/hết hạn',
      targetCode: note.code,
    );
    notifyListeners();
    return null;
  }

  Future<String?> rejectDamageExpiredNote(DamageExpiredNote note,
      {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.pendingApproval) return 'Phiếu không ở trạng thái chờ duyệt';

    damageExpiredNotes = damageExpiredNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.rejected, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();
    await _persist(StorageKeys.damageExpiredNotes, damageExpiredNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Từ chối phiếu hàng hỏng/hết hạn',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  Future<String?> cancelDamageExpiredNote(DamageExpiredNote note,
      {required AppUser approver, required String reason}) async {
    if (note.status != DocumentStatus.approved) return 'Chỉ có thể huỷ phiếu đã duyệt';

    _updateBatchQty(note.batchId, note.quantity);
    damageExpiredNotes = damageExpiredNotes
        .map((n) => n.id == note.id
            ? n.copyWith(status: DocumentStatus.cancelled, approvedBy: approver.id, rejectReason: reason)
            : n)
        .toList();

    await _persist(StorageKeys.batches, batches.map((e) => e.toJson()).toList());
    await _persist(StorageKeys.damageExpiredNotes, damageExpiredNotes.map((e) => e.toJson()).toList());
    await addLog(
      actorId: approver.id,
      actorName: approver.name,
      action: 'Huỷ phiếu hàng hỏng/hết hạn',
      targetCode: note.code,
      note: reason,
    );
    notifyListeners();
    return null;
  }

  // ---------- Persistence ----------

  /// Public methods cho Admin screens gọi khi CRUD sản phẩm/nhà cung cấp
  Future<void> persistProducts() async {
    await _persist(StorageKeys.products, products.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> persistSuppliers() async {
    await _persist(StorageKeys.suppliers, suppliers.map((e) => e.toJson()).toList());
    notifyListeners();
  }

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
    await _persist(StorageKeys.auditLogs, auditLogs.map((e) => e.toJson()).toList());
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
    auditLogs = (await _storage.loadList(StorageKeys.auditLogs)).map(AuditLogEntry.fromJson).toList();
  }
}

extension FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNullX => isEmpty ? null : first;
}
