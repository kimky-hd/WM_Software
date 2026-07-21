import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/stock_check_note.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';

class StockCheckFormScreen extends StatefulWidget {
  const StockCheckFormScreen({super.key});

  @override
  State<StockCheckFormScreen> createState() => _StockCheckFormScreenState();
}

class _StockCheckFormScreenState extends State<StockCheckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;

  TextEditingController _controllerFor(String productId, double systemQty) {
    return _controllers.putIfAbsent(
      productId,
      () => TextEditingController(text: systemQty.toStringAsFixed(0)),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(WarehouseStore store) async {
    if (!_formKey.currentState!.validate()) return;
    final details = <StockCheckDetail>[];
    for (final product in store.products) {
      final systemQty = store.totalStockForProduct(product.id);
      final controller = _controllers[product.id];
      final actualQty = double.tryParse(controller?.text.trim() ?? '') ?? systemQty;
      details.add(StockCheckDetail(productId: product.id, systemQty: systemQty, actualQty: actualQty));
    }

    final user = context.read<AuthStore>().currentUser!;
    setState(() => _submitting = true);
    await store.createStockCheckNote(performedBy: user.id, details: details);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, 'Đã gửi phiếu kiểm kê, chờ Quản lý kho duyệt kết quả');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm kê thực tế')),
      body: Form(
        key: _formKey,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            'Nhập số lượng đếm thực tế cho từng sản phẩm. Mặc định bằng tồn hệ thống nếu không đổi.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ...store.products.map((product) {
            final systemQty = store.totalStockForProduct(product.id);
            final controller = _controllerFor(product.id, systemQty);
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Hệ thống: ${systemQty.toStringAsFixed(0)} kg',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: controller,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(labelText: 'Thực tế', isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null) return 'Số không hợp lệ';
                          if (n < 0) return 'Không được âm';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _submitting ? null : () => _submit(store),
            icon: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: const Text('Gửi duyệt'),
          ),
        ),
      ),
    );
  }
}
