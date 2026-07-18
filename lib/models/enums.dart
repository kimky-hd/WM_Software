/// Vai trò người dùng trong hệ thống (theo ma trận phân quyền README).
enum UserRole {
  admin,
  warehouseManager,
  warehouseStaff;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.warehouseManager:
        return 'Quản lý kho';
      case UserRole.warehouseStaff:
        return 'Nhân viên kho';
    }
  }
}

/// Trạng thái chứng từ: Nháp -> Chờ duyệt -> Đã duyệt -> Hoàn thành, hoặc Từ chối.
enum DocumentStatus {
  draft,
  pendingApproval,
  approved,
  completed,
  rejected;

  String get label {
    switch (this) {
      case DocumentStatus.draft:
        return 'Nháp';
      case DocumentStatus.pendingApproval:
        return 'Chờ duyệt';
      case DocumentStatus.approved:
        return 'Đã duyệt';
      case DocumentStatus.completed:
        return 'Hoàn thành';
      case DocumentStatus.rejected:
        return 'Từ chối';
    }
  }
}

/// Loại phiếu hàng hỏng/hết hạn.
enum DamageType {
  damaged,
  expired;

  String get label => this == DamageType.damaged ? 'Hàng hỏng' : 'Hết hạn';
}
