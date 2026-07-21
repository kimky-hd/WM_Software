import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/user.dart';
import '../../state/auth_store.dart';
import '../../state/warehouse_store.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';

  final List<UserRole> _roles = [
    UserRole.admin,
    UserRole.warehouseManager,
    UserRole.warehouseStaff,
  ];
  
  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Quản trị viên';
      case UserRole.warehouseManager: return 'Quản lý kho';
      case UserRole.warehouseStaff: return 'Nhân viên kho';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return Colors.red;
      case UserRole.warehouseManager: return Colors.blue;
      case UserRole.warehouseStaff: return Colors.orange;
    }
  }

  void _showUserDialog([AppUser? user]) {
    final isEditing = user != null;
    
    // Không cho phép sửa tài khoản Admin gốc (u-admin) qua form này
    if (isEditing && user.id == 'u-admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chỉnh sửa tài khoản Admin gốc')),
      );
      return;
    }

    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController(text: user?.password);
    
    UserRole selectedRole = user?.role ?? UserRole.warehouseStaff;
    bool isActive = user?.active ?? true;
    bool obscurePassword = true;

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
              title: Text(isEditing ? 'Sửa Tài khoản' : 'Thêm Nhân sự mới', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email đăng nhập',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập email';
                          if (!val.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setDialogState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Vai trò (Role)',
                          prefixIcon: const Icon(Icons.manage_accounts),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(_getRoleName(r)))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Trạng thái hoạt động', style: TextStyle(color: Colors.grey.shade700)),
                            Switch(
                              value: isActive,
                              activeColor: Colors.green,
                              onChanged: (val) {
                                setDialogState(() => isActive = val);
                              },
                            ),
                          ],
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final authStore = context.read<AuthStore>();
                      final warehouseStore = context.read<WarehouseStore>();
                      final currentUser = authStore.currentUser!;
                      
                      if (!isEditing) {
                        // Check duplicate email
                        if (authStore.allUsers.any((u) => u.email.toLowerCase() == emailController.text.trim().toLowerCase())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email này đã tồn tại!'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                      }

                      final newUser = AppUser(
                        id: user?.id ?? 'u-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        role: selectedRole,
                        active: isActive,
                      );

                      if (isEditing) {
                        await authStore.updateUser(newUser);
                        warehouseStore.addLog(
                          actorId: currentUser.id,
                          actorName: currentUser.name,
                          action: 'Cập nhật tài khoản',
                          targetCode: newUser.email,
                        );
                      } else {
                        await authStore.addUser(newUser);
                        warehouseStore.addLog(
                          actorId: currentUser.id,
                          actorName: currentUser.name,
                          action: 'Tạo tài khoản mới',
                          targetCode: newUser.email,
                          note: 'Role: ${_getRoleName(selectedRole)}',
                        );
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Cập nhật thành công!' : 'Tạo tài khoản thành công!'),
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

  void _toggleUserStatus(AppUser user, bool isActive) {
    if (user.id == 'u-admin') return; // Cannot lock admin

    final authStore = context.read<AuthStore>();
    final warehouseStore = context.read<WarehouseStore>();
    final currentUser = authStore.currentUser!;
    final updatedUser = AppUser(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
      role: user.role,
      active: isActive,
    );
    
    authStore.updateUser(updatedUser);
    warehouseStore.addLog(
      actorId: currentUser.id,
      actorName: currentUser.name,
      action: isActive ? 'Mở khoá tài khoản' : 'Khoá tài khoản',
      targetCode: user.email,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isActive ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản'),
        backgroundColor: isActive ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final authStore = context.watch<AuthStore>();
    final users = authStore.allUsers;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: authStore.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: users.isEmpty
                      ? const Center(child: Text('Chưa có tài khoản nào'))
                      : _buildListView(primaryColor, users),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Cấp tài khoản'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm nhân sự...',
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

  Widget _buildListView(Color primaryColor, List<AppUser> users) {
    final filteredList = users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery) ||
             u.email.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final user = filteredList[index];
        final isActive = user.active;
        final isAdmin = user.id == 'u-admin'; // Chỉ admin gốc mới được bảo vệ

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
              backgroundColor: isActive ? _getRoleColor(user.role).withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              child: Icon(Icons.person, color: isActive ? _getRoleColor(user.role) : Colors.grey),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.black87 : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isActive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Đã Khóa', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(user.email, style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getRoleColor(user.role).withOpacity(0.5)),
                  ),
                  child: Text(
                    _getRoleName(user.role), 
                    style: TextStyle(fontSize: 12, color: _getRoleColor(user.role), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            trailing: isAdmin ? const SizedBox.shrink() : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isActive,
                  activeColor: Colors.green,
                  onChanged: (val) => _toggleUserStatus(user, val),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showUserDialog(user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
