import 'package:flutter/material.dart';

import 'product_catalog_screen.dart';
import 'supplier_list_screen.dart';
import 'unit_catalog_screen.dart';

/// Danh mục dùng chung, theo đúng quyền hạn Quản lý kho trong ma trận phân quyền:
/// Nhà cung cấp (Thêm/sửa), Sản phẩm (Xem, đề xuất sửa), Đơn vị tính (Xem).
class ManagerCatalogScreen extends StatelessWidget {
  const ManagerCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_CatalogEntry>[
      _CatalogEntry(
        title: 'Nhà cung cấp',
        subtitle: 'Xem, thêm mới, chỉnh sửa',
        icon: Icons.local_shipping_outlined,
        builder: (_) => const SupplierListScreen(),
      ),
      _CatalogEntry(
        title: 'Danh mục sản phẩm',
        subtitle: 'Xem, đề xuất sửa gửi Admin',
        icon: Icons.inventory_2_outlined,
        builder: (_) => const ProductCatalogScreen(),
      ),
      _CatalogEntry(
        title: 'Đơn vị tính & quy đổi',
        subtitle: 'Xem hệ số quy đổi',
        icon: Icons.straighten_outlined,
        builder: (_) => const UnitCatalogScreen(),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: Icon(item.icon, color: Colors.amber.shade800),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: item.builder)),
          ),
        );
      },
    );
  }
}

class _CatalogEntry {
  const _CatalogEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}
