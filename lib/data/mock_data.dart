import '../models/batch.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/unit.dart';
import '../models/user.dart';
import '../models/enums.dart';

/// Dữ liệu mẫu để khởi tạo ứng dụng lần đầu (seed).
class MockData {
  /// 3 tài khoản demo (mỗi role 1 tài khoản) - đăng nhập bằng email + mật khẩu bên dưới.
  static final List<AppUser> users = [
    const AppUser(
      id: 'u-admin',
      name: 'Trần Văn Admin',
      email: 'admin@wm.local',
      password: 'admin123',
      role: UserRole.admin,
    ),
    const AppUser(
      id: 'u-manager',
      name: 'Nguyễn Thị Quản Lý',
      email: 'manager@wm.local',
      password: 'manager123',
      role: UserRole.warehouseManager,
    ),
    const AppUser(
      id: 'u-staff',
      name: 'Lê Văn Nhân Viên',
      email: 'staff@wm.local',
      password: 'staff123',
      role: UserRole.warehouseStaff,
    ),
  ];

  static final List<UnitOfMeasure> units = [
    const UnitOfMeasure(id: 'unit-kg', name: 'kg', conversionFactor: 1),
    const UnitOfMeasure(id: 'unit-bao', name: 'Bao (25kg)', conversionFactor: 25),
    const UnitOfMeasure(id: 'unit-tan', name: 'Tấn', conversionFactor: 1000),
    const UnitOfMeasure(id: 'unit-goi', name: 'Gói (0.5kg)', conversionFactor: 0.5),
  ];

  static final List<Supplier> suppliers = [
    const Supplier(id: 'sup-01', name: 'NCC Nông Sản Miền Tây', contact: '0909 111 222', taxCode: '0301122334'),
    const Supplier(id: 'sup-02', name: 'NCC Ngũ Cốc Tây Nguyên', contact: '0908 333 444', taxCode: '0301445566'),
    const Supplier(id: 'sup-03', name: 'NCC Đồ Khô Việt', contact: '0907 555 666', taxCode: '0301778899'),
  ];

  static final List<Product> products = [
    const Product(
      id: 'p-01',
      code: 'GAO-ST25',
      name: 'Gạo ST25',
      category: 'Ngũ cốc',
      baseUnitId: 'unit-kg',
      minStock: 100,
      defaultExpiryDays: 365,
    ),
    const Product(
      id: 'p-02',
      code: 'DAU-XANH',
      name: 'Đậu xanh',
      category: 'Hạt',
      baseUnitId: 'unit-kg',
      minStock: 50,
      defaultExpiryDays: 270,
    ),
    const Product(
      id: 'p-03',
      code: 'HAT-DIEU',
      name: 'Hạt điều rang',
      category: 'Hạt',
      baseUnitId: 'unit-kg',
      minStock: 30,
      defaultExpiryDays: 180,
    ),
    const Product(
      id: 'p-04',
      code: 'YEN-MACH',
      name: 'Yến mạch',
      category: 'Ngũ cốc',
      baseUnitId: 'unit-kg',
      minStock: 40,
      defaultExpiryDays: 300,
    ),
    const Product(
      id: 'p-05',
      code: 'DUONG-TRANG',
      name: 'Đường trắng',
      category: 'Đồ khô',
      baseUnitId: 'unit-kg',
      minStock: 60,
      defaultExpiryDays: 720,
    ),
  ];

  static List<Batch> seedBatches() {
    final now = DateTime.now();
    return [
      Batch(
        id: 'b-01',
        productId: 'p-01',
        batchCode: 'LOT-GAO-0001',
        manufactureDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(const Duration(days: 335)),
        quantityIn: 500,
        quantityRemaining: 320,
      ),
      Batch(
        id: 'b-02',
        productId: 'p-01',
        batchCode: 'LOT-GAO-0002',
        manufactureDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.add(const Duration(days: 355)),
        quantityIn: 300,
        quantityRemaining: 300,
      ),
      Batch(
        id: 'b-03',
        productId: 'p-02',
        batchCode: 'LOT-DAUXANH-0001',
        manufactureDate: now.subtract(const Duration(days: 60)),
        expiryDate: now.add(const Duration(days: 5)),
        quantityIn: 100,
        quantityRemaining: 42,
      ),
      Batch(
        id: 'b-04',
        productId: 'p-03',
        batchCode: 'LOT-HATDIEU-0001',
        manufactureDate: now.subtract(const Duration(days: 20)),
        expiryDate: now.add(const Duration(days: 160)),
        quantityIn: 80,
        quantityRemaining: 25,
      ),
      Batch(
        id: 'b-05',
        productId: 'p-04',
        batchCode: 'LOT-YENMACH-0001',
        manufactureDate: now.subtract(const Duration(days: 5)),
        expiryDate: now.add(const Duration(days: 295)),
        quantityIn: 60,
        quantityRemaining: 60,
      ),
      Batch(
        id: 'b-06',
        productId: 'p-05',
        batchCode: 'LOT-DUONG-0001',
        manufactureDate: now.subtract(const Duration(days: 90)),
        expiryDate: now.subtract(const Duration(days: 2)),
        quantityIn: 200,
        quantityRemaining: 15,
      ),
    ];
  }
}
