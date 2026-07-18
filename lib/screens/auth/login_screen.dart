import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../state/auth_store.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warehouse_rounded, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    'Quản lý kho đồ khô, ngũ cốc',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn vai trò để đăng nhập',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  _RoleTile(
                    role: UserRole.warehouseStaff,
                    icon: Icons.inventory_2_outlined,
                    subtitle: 'Tạo phiếu nhập/xuất, kiểm kê, xem tồn kho',
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  _RoleTile(
                    role: UserRole.warehouseManager,
                    icon: Icons.fact_check_outlined,
                    subtitle: 'Sắp ra mắt',
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  _RoleTile(
                    role: UserRole.admin,
                    icon: Icons.admin_panel_settings_outlined,
                    subtitle: 'Sắp ra mắt',
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.icon,
    required this.subtitle,
    required this.enabled,
  });

  final UserRole role;
  final IconData icon;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: enabled ? Colors.amber.shade100 : Colors.grey.shade200,
          child: Icon(icon, color: enabled ? Colors.amber.shade800 : Colors.grey),
        ),
        title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: enabled ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        enabled: enabled,
        onTap: enabled ? () => context.read<AuthStore>().loginAs(role) : null,
      ),
    );
  }
}
