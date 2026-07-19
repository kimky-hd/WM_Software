import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';

/// Danh mục sản phẩm - Quản lý kho chỉ được Xem và đề xuất sửa (Admin mới có
/// toàn quyền chỉnh sửa danh mục, theo ma trận phân quyền).
class ProductCatalogScreen extends StatelessWidget {
  const ProductCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final products = store.products;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh mục sản phẩm')),
      body: products.isEmpty
          ? const EmptyState(icon: Icons.inventory_2_outlined, message: 'Chưa có sản phẩm nào')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final unit = store.unitById(product.baseUnitId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${product.code} • ${product.category} • ĐVT: ${unit?.name ?? ''}\n'
                      'Tồn tối thiểu: ${product.minStock.toStringAsFixed(0)} • HSD mặc định: ${product.defaultExpiryDays} ngày',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Đề xuất sửa',
                      icon: const Icon(Icons.rate_review_outlined),
                      onPressed: () => _proposeEdit(context, product),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _proposeEdit(BuildContext context, Product product) async {
    final controller = TextEditingController();
    final suggestion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Đề xuất sửa "${product.name}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Nội dung đề xuất', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Huỷ bỏ')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(dialogContext).pop(text);
            },
            child: const Text('Gửi đề xuất'),
          ),
        ],
      ),
    );
    if (suggestion == null || !context.mounted) return;

    final store = context.read<WarehouseStore>();
    final actor = context.read<AuthStore>().currentUser!;
    await store.proposeProductEdit(product, actor: actor, suggestion: suggestion);
    if (!context.mounted) return;
    showAppSnackBar(context, 'Đã gửi đề xuất, xem lại trong Nhật ký hoạt động');
  }
}
