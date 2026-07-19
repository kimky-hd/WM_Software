import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/supplier.dart';
import '../../state/warehouse_store.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/empty_state.dart';

/// Quản lý nhà cung cấp - Quản lý kho có quyền Thêm/sửa (Admin mới có toàn quyền,
/// bao gồm cả xoá).
class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WarehouseStore>();
    final suppliers = store.suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhà cung cấp')),
      body: suppliers.isEmpty
          ? const EmptyState(icon: Icons.local_shipping_outlined, message: 'Chưa có nhà cung cấp nào')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(Icons.local_shipping_outlined, color: Colors.amber.shade800),
                    ),
                    title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${supplier.contact} • MST: ${supplier.taxCode}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showSupplierForm(context, supplier: supplier),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm NCC'),
      ),
    );
  }

  void _showSupplierForm(BuildContext context, {Supplier? supplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SupplierForm(supplier: supplier),
    );
  }
}

class _SupplierForm extends StatefulWidget {
  const _SupplierForm({this.supplier});

  final Supplier? supplier;

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.supplier?.name);
  late final _contactController = TextEditingController(text: widget.supplier?.contact);
  late final _taxCodeController = TextEditingController(text: widget.supplier?.taxCode);
  bool _submitting = false;

  bool get _isEditing => widget.supplier != null;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<WarehouseStore>();
    final supplier = Supplier(
      id: widget.supplier?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      contact: _contactController.text.trim(),
      taxCode: _taxCodeController.text.trim(),
    );

    setState(() => _submitting = true);
    if (_isEditing) {
      await store.updateSupplier(supplier);
    } else {
      await store.addSupplier(supplier);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(context, _isEditing ? 'Đã cập nhật nhà cung cấp' : 'Đã thêm nhà cung cấp mới');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isEditing ? 'Sửa nhà cung cấp' : 'Thêm nhà cung cấp', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên nhà cung cấp', prefixIcon: Icon(Icons.business_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên nhà cung cấp' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Liên hệ', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập thông tin liên hệ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxCodeController,
                decoration: const InputDecoration(labelText: 'Mã số thuế', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mã số thuế' : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm mới'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
