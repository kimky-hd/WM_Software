import 'package:flutter/material.dart';
import '../../models/note_status.dart';
import '../../models/outbound_note_model.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';

class OutboundNoteFormScreen extends StatefulWidget {
  final OutboundNoteModel? existing;

  const OutboundNoteFormScreen({super.key, this.existing});

  @override
  State<OutboundNoteFormScreen> createState() => _OutboundNoteFormScreenState();
}

class _RequestRow {
  String? productId;
  final quantityController = TextEditingController();

  _RequestRow();
}

class _OutboundNoteFormScreenState extends State<OutboundNoteFormScreen> {
  final _repo = WarehouseRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final List<_RequestRow> _rows = [];
  bool get _readOnly => widget.existing != null && !NoteStatus.isEditable(widget.existing!.status);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _purposeController.text = existing.purpose;
      // Gộp các dòng chi tiết đã lưu theo sản phẩm để hiển thị lại số lượng yêu cầu.
      final byProduct = <String, int>{};
      for (final d in existing.details) {
        byProduct[d.productId] = (byProduct[d.productId] ?? 0) + d.quantity;
      }
      byProduct.forEach((productId, qty) {
        final row = _RequestRow()..productId = productId;
        row.quantityController.text = qty.toString();
        _rows.add(row);
      });
    } else {
      _rows.add(_RequestRow());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final details = <OutboundNoteDetail>[];
    final shortages = <String>[];
    for (final row in _rows) {
      final requestedQty = int.parse(row.quantityController.text.trim());
      final allocations = _repo.suggestFefoAllocation(row.productId!, requestedQty);
      final allocatedQty = allocations.fold<int>(0, (sum, a) => sum + a.quantity);
      if (allocatedQty < requestedQty) {
        final product = _repo.findProduct(row.productId!);
        shortages.add('${product?.name ?? row.productId}: thiếu ${requestedQty - allocatedQty}');
      }
      for (final alloc in allocations) {
        details.add(OutboundNoteDetail(
          productId: row.productId!,
          batchId: alloc.batch.id,
          quantity: alloc.quantity,
          unit: _repo.findProduct(row.productId!)?.unit ?? '',
        ));
      }
    }

    if (shortages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không đủ tồn kho cho: ${shortages.join('; ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final note = OutboundNoteModel(
      id: widget.existing?.id ?? _repo.newId(),
      code: widget.existing?.code ?? _repo.generateNoteCode('PX'),
      createdDate: widget.existing?.createdDate ?? DateTime.now(),
      createdBy: widget.existing?.createdBy ?? WarehouseRepository.currentStaffName,
      purpose: _purposeController.text.trim(),
      status: widget.existing?.status ?? NoteStatus.pending,
      details: details,
    );
    await _repo.saveOutboundNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu phiếu xuất kho (gợi ý FEFO)'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.getProducts();

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Tạo phiếu xuất kho' : 'Phiếu xuất kho')),
      body: AbsorbPointer(
        absorbing: _readOnly,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'Mục đích xuất kho',
                  prefixIcon: const Icon(Icons.assignment_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),
              const Text('Hàng cần xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final requestedQty = int.tryParse(row.quantityController.text.trim()) ?? 0;
                final allocations = row.productId != null && requestedQty > 0
                    ? _repo.suggestFefoAllocation(row.productId!, requestedQty)
                    : <FefoAllocationLine>[];
                final allocatedQty = allocations.fold<int>(0, (sum, a) => sum + a.quantity);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: row.productId,
                                decoration: InputDecoration(
                                  labelText: 'Sản phẩm',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: products
                                    .map((p) => DropdownMenuItem(
                                        value: p.id, child: Text('${p.name} (tồn ${_repo.getStockQuantity(p.id)})')))
                                    .toList(),
                                onChanged: (v) => setState(() => row.productId = v),
                                validator: (v) => v == null ? 'Chọn SP' : null,
                              ),
                            ),
                            if (_rows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => setState(() => _rows.removeAt(i)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: row.quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Số lượng cần xuất',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Số lượng không hợp lệ';
                            return null;
                          },
                        ),
                        if (row.productId != null && requestedQty > 0) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Gợi ý FEFO (lô hết hạn sớm nhất trước):',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ),
                          ...allocations.map((a) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.qr_code_2, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Lô ${a.batch.batchCode} (HSD ${formatDate(a.batch.expiryDate)}): lấy ${a.quantity}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (allocatedQty < requestedQty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Không đủ tồn: chỉ gợi ý được $allocatedQty/$requestedQty',
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm dòng hàng'),
                onPressed: () => setState(() => _rows.add(_RequestRow())),
              ),
              const SizedBox(height: 24),
              if (!_readOnly)
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu phiếu'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
