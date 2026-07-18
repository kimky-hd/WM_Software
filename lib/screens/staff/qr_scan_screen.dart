import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/batch.dart';
import '../../models/product.dart';
import '../../state/warehouse_store.dart';

/// Quét mã QR/Barcode để tra cứu nhanh sản phẩm/lô hàng.
///
/// Ghi chú: đây là bản demo dùng nhập mã thủ công / chọn nhanh, chưa tích hợp
/// camera thực tế (cần thêm package quét mã + cấu hình quyền camera từng nền tảng).
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _codeController = TextEditingController();
  Batch? _foundBatch;
  Product? _foundProduct;
  bool _notFound = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _lookup(String rawCode) {
    final code = rawCode.trim();
    final store = context.read<WarehouseStore>();
    if (code.isEmpty) return;

    final batch = store.batches.where((b) => b.batchCode.toLowerCase() == code.toLowerCase()).firstOrNullX;
    if (batch != null) {
      setState(() {
        _foundBatch = batch;
        _foundProduct = store.productById(batch.productId);
        _notFound = false;
      });
      return;
    }

    final product = store.products.where((p) => p.code.toLowerCase() == code.toLowerCase()).firstOrNullX;
    if (product != null) {
      setState(() {
        _foundProduct = product;
        _foundBatch = null;
        _notFound = false;
      });
      return;
    }

    setState(() {
      _foundBatch = null;
      _foundProduct = null;
      _notFound = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR/Barcode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white54, size: 48),
                  SizedBox(height: 8),
                  Text('Khung camera quét mã (demo)', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Nhập mã sản phẩm hoặc mã lô',
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _lookup(_codeController.text),
              ),
            ),
            onSubmitted: _lookup,
          ),
          const SizedBox(height: 16),
          if (_notFound)
            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Không tìm thấy sản phẩm hoặc lô hàng với mã này.'),
              ),
            ),
          if (_foundProduct != null) _ResultCard(product: _foundProduct!, batch: _foundBatch, store: store, dateFmt: dateFmt),
          const SizedBox(height: 20),
          Text('Chọn nhanh để thử (mã lô có sẵn):', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: store.batches
                .map((b) => ActionChip(
                      label: Text(b.batchCode),
                      onPressed: () {
                        _codeController.text = b.batchCode;
                        _lookup(b.batchCode);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.product, required this.batch, required this.store, required this.dateFmt});

  final Product product;
  final Batch? batch;
  final WarehouseStore store;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final total = store.totalStockForProduct(product.id);
    final unit = store.unitById(product.baseUnitId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.amber.shade100, child: const Icon(Icons.inventory_2_outlined, color: Colors.brown)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${product.code} • ${product.category}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(label: 'Tổng tồn kho', value: '${total.toStringAsFixed(0)} ${unit?.name.split(' ').first ?? ''}'),
            _InfoRow(label: 'Mức tồn tối thiểu', value: '${product.minStock.toStringAsFixed(0)} kg'),
            if (batch != null) ...[
              _InfoRow(label: 'Mã lô', value: batch!.batchCode),
              _InfoRow(label: 'Ngày sản xuất', value: dateFmt.format(batch!.manufactureDate)),
              _InfoRow(label: 'Hạn sử dụng', value: dateFmt.format(batch!.expiryDate)),
              _InfoRow(label: 'Còn lại trong lô', value: '${batch!.quantityRemaining.toStringAsFixed(0)} kg'),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
