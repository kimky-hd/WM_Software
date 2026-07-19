import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/shared_prefs_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  final List<String> _categories = ['Đồ khô', 'Ngũ cốc', 'Gia vị', 'Khác'];
  final List<String> _units = ['Kg', 'Bao', 'Tấn', 'Thùng', 'Gói'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final data = SharedPrefsService.instance.getDataList('products', ProductModel.fromJson);
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  Future<void> _saveProducts() async {
    await SharedPrefsService.instance.saveDataList('products', _products, (p) => p.toJson());
  }

  void _showProductDialog([ProductModel? product]) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name);
    final codeController = TextEditingController(text: product?.productCode);
    final minStockController = TextEditingController(text: product?.minStockLevel.toString());
    
    String selectedCategory = product?.category ?? _categories.first;
    String selectedUnit = product?.unit ?? _units.first;

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
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUnit,
                              decoration: InputDecoration(
                                labelText: 'Đơn vị tính',
                                prefixIcon: const Icon(Icons.scale),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedUnit = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
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
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        if (isEditing) {
                          final index = _products.indexWhere((p) => p.id == product.id);
                          if (index != -1) {
                            _products[index] = ProductModel(
                              id: product.id,
                              productCode: codeController.text,
                              name: nameController.text,
                              category: selectedCategory,
                              unit: selectedUnit,
                              minStockLevel: int.tryParse(minStockController.text) ?? 0,
                            );
                          }
                        } else {
                          _products.add(ProductModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            productCode: codeController.text,
                            name: nameController.text,
                            category: selectedCategory,
                            unit: selectedUnit,
                            minStockLevel: int.tryParse(minStockController.text) ?? 0,
                          ));
                        }
                      });
                      _saveProducts();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Cập nhật thành công!' : 'Thêm mới thành công!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
            onPressed: () {
              setState(() {
                _products.removeWhere((p) => p.id == id);
              });
              _saveProducts();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa sản phẩm'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,),
              );
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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _products.isEmpty
              ? _buildEmptyState()
              : _buildListView(primaryColor),
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

  Widget _buildListView(Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
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
                    Text('Mã: ${product.productCode}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.scale, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Đơn vị: ${product.unit}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('Min: ${product.minStockLevel}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
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
