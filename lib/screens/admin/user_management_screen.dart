import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/shared_prefs_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final List<String> _roles = ['MANAGER', 'STAFF'];
  
  String _getRoleName(String roleCode) {
    switch (roleCode) {
      case 'ADMIN': return 'Quản trị viên';
      case 'MANAGER': return 'Quản lý kho';
      case 'STAFF': return 'Nhân viên kho';
      default: return roleCode;
    }
  }

  Color _getRoleColor(String roleCode) {
    switch (roleCode) {
      case 'ADMIN': return Colors.red;
      case 'MANAGER': return Colors.blue;
      case 'STAFF': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final data = SharedPrefsService.instance.getDataList('users', UserModel.fromJson);
    
    // Tạo 1 tài khoản Admin ảo nếu chưa có ai (để không bị trống trơn)
    if (data.isEmpty) {
      data.add(UserModel(
        id: 'admin_01', 
        fullName: 'Admin Tổng', 
        email: 'admin@warehouse.com', 
        password: 'admin', 
        role: 'ADMIN', 
        status: 'ACTIVE'
      ));
      await SharedPrefsService.instance.saveDataList('users', data, (u) => u.toJson());
    }
    
    setState(() {
      _users = data;
      _isLoading = false;
    });
  }

  Future<void> _saveUsers() async {
    await SharedPrefsService.instance.saveDataList('users', _users, (u) => u.toJson());
  }

  void _showUserDialog([UserModel? user]) {
    final isEditing = user != null;
    
    // Không cho phép sửa tài khoản Admin mặc định qua form này
    if (isEditing && user.role == 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chỉnh sửa tài khoản Admin gốc')),
      );
      return;
    }

    final nameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController(text: user?.password);
    
    String selectedRole = user?.role ?? _roles.first;
    bool isActive = (user?.status ?? 'ACTIVE') == 'ACTIVE';
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
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
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
                              activeThumbColor: Colors.green,
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
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        if (isEditing) {
                          final index = _users.indexWhere((u) => u.id == user.id);
                          if (index != -1) {
                            _users[index] = UserModel(
                              id: user.id,
                              fullName: nameController.text,
                              email: emailController.text,
                              password: passwordController.text,
                              role: selectedRole,
                              status: isActive ? 'ACTIVE' : 'LOCKED',
                            );
                          }
                        } else {
                          // Check duplicate email
                          if (_users.any((u) => u.email == emailController.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email này đã tồn tại!'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          
                          _users.add(UserModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            fullName: nameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            role: selectedRole,
                            status: isActive ? 'ACTIVE' : 'LOCKED',
                          ));
                        }
                      });
                      _saveUsers();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Cập nhật thành công!' : 'Tạo tài khoản thành công!'),
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

  void _toggleUserStatus(UserModel user, bool isActive) {
    if (user.role == 'ADMIN') return; // Cannot lock admin

    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = UserModel(
          id: user.id,
          fullName: user.fullName,
          email: user.email,
          password: user.password,
          role: user.role,
          status: isActive ? 'ACTIVE' : 'LOCKED',
        );
      }
    });
    _saveUsers();
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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text('Chưa có tài khoản nào'))
                      : _buildListView(primaryColor),
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

  Widget _buildListView(Color primaryColor) {
    final filteredList = _users.where((u) {
      return u.fullName.toLowerCase().contains(_searchQuery) ||
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
        final isActive = user.status == 'ACTIVE';
        final isAdmin = user.role == 'ADMIN';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isActive ? _getRoleColor(user.role).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: isActive ? _getRoleColor(user.role) : Colors.grey),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.fullName, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.black87 : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isActive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
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
                    color: _getRoleColor(user.role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getRoleColor(user.role).withValues(alpha: 0.5)),
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
                  activeThumbColor: Colors.green,
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
