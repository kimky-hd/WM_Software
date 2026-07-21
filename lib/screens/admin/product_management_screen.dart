import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String _searchQuery = '';

  final List<String> _categories = ['Đồ khô', 'Ngũ cốc', 'Gia vị', 'Hạt', 'Khác'];

  void _showProductDialog([Product? product]) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name);
    final codeController = TextEditingController(text: product?.code);
    final minStockController = TextEditingController(text: product?.minStock.toStringAsFixed(0));
    final expiryDaysController = TextEditingController(text: product?.defaultExpiryDays.toString());

    String selectedCategory = product?.category ?? _categories.first;
    final store = context.read<WarehouseStore>();
    // Lấy tên unit mặc định
    String selectedUnitId = product?.baseUnitId ?? (store.units.isNotEmpty ? store.units.first.id : '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = Theme.of(context).colorScheme.primary;
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEditing ? 'Sửa Sản phẩm' : 'Thêm Sản phẩm', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Mã sản phẩm',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập mã SP' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên sản phẩm',
                          prefixIcon: const Icon(Icons.inventory_2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên SP' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedUnitId.isNotEmpty ? selectedUnitId : null,
                        decoration: InputDecoration(
                          labelText: 'Đơn vị tính',
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: store.units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedUnitId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: minStockController,
                              decoration: InputDecoration(
                                labelText: 'Tồn tối thiểu',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) => val == null || val.isEmpty ? 'Nhập số' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: expiryDaysController,
                              decoration: InputDecoration(
                                labelText: 'HSD (ngày)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) => val == null || val.isEmpty ? 'Nhập số' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newProduct = Product(
                        id: product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        code: codeController.text,
                        name: nameController.text,
                        category: selectedCategory,
                        baseUnitId: selectedUnitId,
                        minStock: double.tryParse(minStockController.text) ?? 0,
                        defaultExpiryDays: int.tryParse(expiryDaysController.text) ?? 365,
                      );

                      if (isEditing) {
                        store.products = store.products.map((p) => p.id == product.id ? newProduct : p).toList();
                        store.addLog(
                          actorId: context.read<AuthStore>().currentUser!.id,
                          actorName: context.read<AuthStore>().currentUser!.name,
                          action: 'Cập nhật sản phẩm',
                          targetCode: newProduct.code,
                        );
                      } else {
                        store.products = [...store.products, newProduct];
                        store.addLog(
                          actorId: context.read<AuthStore>().currentUser!.id,
                          actorName: context.read<AuthStore>().currentUser!.name,
                          action: 'Thêm sản phẩm mới',
                          targetCode: newProduct.code,
                        );
                      }
                      // Lưu vào SharedPreferences thông qua AppStorage
                      await store.persistProducts();

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Cập nhật thành công!' : 'Thêm mới thành công!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProduct(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final store = context.read<WarehouseStore>();
              final p = store.products.firstWhere((p) => p.id == id);
              store.products = store.products.where((p) => p.id != id).toList();
              store.addLog(
                actorId: context.read<AuthStore>().currentUser!.id,
                actorName: context.read<AuthStore>().currentUser!.name,
                action: 'Xóa sản phẩm',
                targetCode: p.code,
              );
              await store.persistProducts();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa sản phẩm'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final store = context.watch<WarehouseStore>();
    final products = store.products;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: store.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildSearchBar(primaryColor),
                Expanded(
                  child: products.isEmpty
                      ? _buildEmptyState()
                      : _buildListView(primaryColor, products),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Chưa có sản phẩm nào trong kho', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildListView(Color primaryColor, List<Product> products) {
    final filteredList = products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery) ||
             p.code.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả'));
    }

    final store = context.read<WarehouseStore>();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final product = filteredList[index];
        final unitName = store.unitById(product.baseUnitId)?.name ?? product.baseUnitId;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.inventory, color: primaryColor),
            ),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(product.category, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ),
                    const SizedBox(width: 8),
                    Text('Mã: ${product.code}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.scale, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Đơn vị: $unitName', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('Min: ${product.minStock.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (value) {
                if (value == 'edit') _showProductDialog(product);
                if (value == 'delete') _deleteProduct(product.id);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }
}
