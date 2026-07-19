import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../services/shared_prefs_service.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  final Color primaryColor = const Color(0xFF512DA8);
  List<SupplierModel> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    // Giả lập độ trễ mạng để hiển thị UX Loading
    await Future.delayed(const Duration(milliseconds: 300));
    final data = SharedPrefsService.instance.getDataList('suppliers', SupplierModel.fromJson);
    setState(() {
      _suppliers = data;
      _isLoading = false;
    });
  }

  Future<void> _saveSuppliers() async {
    await SharedPrefsService.instance.saveDataList('suppliers', _suppliers, (s) => s.toJson());
  }

  void _showSupplierDialog([SupplierModel? supplier]) {
    final isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name);
    final contactController = TextEditingController(text: supplier?.contact);
    final taxCodeController = TextEditingController(text: supplier?.taxCode);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Sửa Đối tác' : 'Thêm Đối tác', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên đối tác',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập SĐT' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: taxCodeController,
                    decoration: InputDecoration(
                      labelText: 'Mã số thuế',
                      prefixIcon: const Icon(Icons.receipt_long),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
                      if (index != -1) {
                        _suppliers[index] = SupplierModel(
                          id: supplier.id,
                          name: nameController.text,
                          contact: contactController.text,
                          taxCode: taxCodeController.text,
                        );
                      }
                    } else {
                      _suppliers.add(SupplierModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        contact: contactController.text,
                        taxCode: taxCodeController.text,
                      ));
                    }
                  });
                  _saveSuppliers();
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
  }

  void _deleteSupplier(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đối tác này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              setState(() {
                _suppliers.removeWhere((s) => s.id == id);
              });
              _saveSuppliers();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa đối tác'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _suppliers.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showSupplierDialog(),
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
          Icon(Icons.storefront, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Chưa có nhà cung cấp nào', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final supplier = _suppliers[index];
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
              child: Icon(Icons.store, color: primaryColor),
            ),
            title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(supplier.contact, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
                if (supplier.taxCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('MST: ${supplier.taxCode}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ]
              ],
            ),
            trailing: PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (value) {
                if (value == 'edit') _showSupplierDialog(supplier);
                if (value == 'delete') _deleteSupplier(supplier.id);
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
