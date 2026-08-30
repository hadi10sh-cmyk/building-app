import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // ۱. مقداردهی اولیه Hive برای ذخیره‌سازی دائمی
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('inventoryBox');
  
  runApp(const BuildingManagerApp());
}

class BuildingManagerApp extends StatelessWidget {
  const BuildingManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت پیمانکاری',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InventoryScreen(),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Box inventoryBox;

  @override
  void initState() {
    super.initState();
    inventoryBox = Hive.box('inventoryBox');
  }

  // تابع کمکی برای اضافه یا کم کردن موجودی
  void _updateStock(String itemName, int amount) {
    final currentStock = inventoryBox.get(itemName, defaultValue: 0) as int;
    final newStock = currentStock + amount;
    
    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موجودی نمی‌تواند منفی باشد!')),
      );
      return;
    }

    inventoryBox.put(itemName, newStock);
    setState(() {}); // به‌روزرسانی صفحه
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ثبت کالا/تراکنش'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام کالا')),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'تعداد'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                _updateStock(nameController.text, int.parse(qtyController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('تایید'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // خواندن تمام کلیدها (نام کالاها) از Hive
    final keys = inventoryBox.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('انبار مدیریت پروژه'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: keys.isEmpty
          ? const Center(child: Text('هیچ کالایی در انبار نیست.'))
          : ListView.builder(
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final name = keys[index] as String;
                final stock = inventoryBox.get(name) as int;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('موجودی فعلی: $stock'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // دکمه ورود کالا (سبز)
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => _updateStock(name, 1),
                        ),
                        // دکمه خروج کالا (قرمز)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _updateStock(name, -1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'افزودن کالا جدید',
        child: const Icon(Icons.add),
      ),
    );
  }
}
