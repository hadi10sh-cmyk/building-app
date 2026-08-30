import 'package:flutter/material.dart';

void main() => runApp(const ContractorProApp());

class ContractorProApp extends StatelessWidget {
  const ContractorProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blueGrey, useMaterial3: true),
      home: const WarehouseScreen(),
    );
  }
}

// مدل کالای انبار
class InventoryItem {
  String name;
  int quantity;
  String unit; // مثلا: کیسه، متر مکعب، عدد

  InventoryItem(this.name, this.quantity, this.unit);
}

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  // لیست واقعی انبار (در حافظه موقت)
  final List<InventoryItem> _inventory = [
    InventoryItem('سیمان', 50, 'کیسه'),
    InventoryItem('آجر', 1000, 'عدد'),
  ];

  // کنترلرها برای گرفتن متن از کاربر
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  // تابع برای اضافه کردن کالا (ورودی انبار)
  void _addItem(bool isIncoming) {
    final String name = _nameController.text;
    final int? qty = int.tryParse(_qtyController.text);

    if (name.isNotEmpty && qty != null) {
      setState(() {
        // پیدا کردن کالای موجود در لیست
        int existingIndex = _inventory.indexWhere((item) => item.name == name);

        if (existingIndex != -1) {
          // اگر کالا بود، مقدار را کم یا زیاد کن
          if (isIncoming) {
            _inventory[existingIndex].quantity += qty;
          } else {
            _inventory[existingIndex].quantity -= qty;
          }
        } else {
          // اگر کالا نبود، کالای جدید بساز
          _inventory.add(InventoryItem(name, qty, 'واحد'));
        }
      });
      _nameController.clear();
      _qtyController.clear();
      Navigator.pop(context); // بستن پنجره فرم
    }
  }

  // نمایش پنجره فرم ثبت کالا
  void _showForm(bool isIncoming) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isIncoming ? 'ورود به انبار' : 'خروج از انبار', 
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'نام کالا (مثلا سیمان)')),
            TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'مقدار'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addItem(isIncoming),
              child: Text(isIncoming ? 'ثبت ورود' : 'ثبت خروج'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت انبار پیمانکاری')),
      body: ListView.builder(
        itemCount: _inventory.length,
        itemBuilder: (context, index) {
          final item = _inventory[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('موجودی: ${item.quantity} ${item.unit}'),
            trailing: Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
        },
      ),
      // دکمه ورود کالا
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'in',
            onPressed: () => _showForm(true),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_box, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // دکته خروج کالا
          FloatingActionButton(
            heroTag: 'out',
            onPressed: () => _showForm(false),
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove_box, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
