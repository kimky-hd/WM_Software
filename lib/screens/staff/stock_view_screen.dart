import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/warehouse_repository.dart';
import '../../utils/date_formatter.dart';

class StockViewScreen extends StatefulWidget {
  const StockViewScreen({super.key});

  @override
  State<StockViewScreen> createState() => _StockViewScreenState();
}

class _StockViewScreenState extends State<StockViewScreen> {
  final _repo = WarehouseRepository.instance;
  final _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.getProducts().where((p) {
      if (_keyword.isEmpty) return true;
      final k = _keyword.toLowerCase();
      return p.name.toLowerCase().contains(k) || p.productCode.toLowerCase().contains(k);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _keyword = v),
            decoration: InputDecoration(
              labelText: 'Quét mã / Tìm sản phẩm',
              hintText: 'Nhập mã SP hoặc tên sản phẩm...',
              prefixIcon: const Icon(Icons.qr_code_scanner),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('Không tìm thấy sản phẩm', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _ProductStockCard(product: products[index]),
                ),
        ),
      ],
    );
  }
}

class _ProductStockCard extends StatelessWidget {
  final ProductModel product;

  const _ProductStockCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final repo = WarehouseRepository.instance;
    final stock = repo.getStockQuantity(product.id);
    final isLow = stock < product.minStockLevel;
    final batches = repo.getBatchesForProduct(product.id)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(
          backgroundColor: (isLow ? Colors.red : Colors.green).withValues(alpha: 0.15),
          child: Icon(Icons.inventory_2, color: isLow ? Colors.red : Colors.green),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${product.productCode} • ${product.category}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$stock ${product.unit}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: isLow ? Colors.red : Colors.black87)),
            Text('Tối thiểu: ${product.minStockLevel}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        children: batches.isEmpty
            ? const [Padding(padding: EdgeInsets.all(12), child: Text('Chưa có lô hàng nào'))]
            : batches
                .map((b) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.qr_code_2, size: 18),
                      title: Text('Lô ${b.batchCode}'),
                      subtitle: Text('SX: ${formatDate(b.manufactureDate)}  •  HSD: ${formatDate(b.expiryDate)}'),
                      trailing: Text('${b.quantityRemaining}/${b.quantityImported}'),
                    ))
                .toList(),
      ),
    );
  }
}
