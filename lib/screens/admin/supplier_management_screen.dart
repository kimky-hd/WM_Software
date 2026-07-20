import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supplier.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  String _searchQuery = '';

  void _showSupplierDialog([Supplier? supplier]) {
    final isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name);
    final contactController = TextEditingController(text: supplier?.contact);
    final taxCodeController = TextEditingController(text: supplier?.taxCode);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Sửa Nhà cung cấp' : 'Thêm Nhà cung cấp',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên nhà cung cấp',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText: 'Liên hệ (SĐT)',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập MST' : null,
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
                  final store = context.read<WarehouseStore>();
                  final newSupplier = Supplier(
                    id: supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    contact: contactController.text,
                    taxCode: taxCodeController.text,
                  );

                  if (isEditing) {
                    store.suppliers = store.suppliers.map((s) => s.id == supplier.id ? newSupplier : s).toList();
                    store.addLog(
                      actorId: context.read<AuthStore>().currentUser!.id,
                      actorName: context.read<AuthStore>().currentUser!.name,
                      action: 'Cập nhật đối tác',
                      targetCode: newSupplier.taxCode,
                    );
                  } else {
                    store.suppliers = [...store.suppliers, newSupplier];
                    store.addLog(
                      actorId: context.read<AuthStore>().currentUser!.id,
                      actorName: context.read<AuthStore>().currentUser!.name,
                      action: 'Thêm đối tác mới',
                      targetCode: newSupplier.taxCode,
                    );
                  }
                  await store.persistSuppliers();

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
  }

  void _deleteSupplier(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa nhà cung cấp này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final store = context.read<WarehouseStore>();
              final s = store.suppliers.firstWhere((s) => s.id == id);
              store.suppliers = store.suppliers.where((s) => s.id != id).toList();
              store.addLog(
                actorId: context.read<AuthStore>().currentUser!.id,
                actorName: context.read<AuthStore>().currentUser!.name,
                action: 'Xóa đối tác',
                targetCode: s.taxCode,
              );
              await store.persistSuppliers();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa nhà cung cấp'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
    final suppliers = store.suppliers;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: store.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: suppliers.isEmpty
                      ? _buildEmptyState()
                      : _buildListView(primaryColor, suppliers),
                ),
              ],
            ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm đối tác...',
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

  Widget _buildListView(Color primaryColor, List<Supplier> suppliers) {
    final filteredList = suppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery) ||
             s.contact.toLowerCase().contains(_searchQuery) ||
             s.taxCode.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final supplier = filteredList[index];
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
              child: Icon(Icons.local_shipping, color: primaryColor),
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
                    Text(supplier.contact, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('MST: ${supplier.taxCode}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
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
