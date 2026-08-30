import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // باز کردن باکس‌های مورد نیاز
  await Hive.openBox('workerBox');
  await Hive.openBox('inventoryBox');
  await Hive.openBox('usageBox'); // باکس جدید برای گزارش‌ها
  
  runApp(const MyApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // باز کردن باکس‌های اصلی
  await Hive.openBox('inventoryBox'); // ذخیره کالاها
  await Hive.openBox('workerBox');     // ذخیره کارگران
  await Hive.openBox('transactionBox'); // ذخیره گزارش کارکرد و مصرف کالا

  runApp(const BuildingApp());
}

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
class LaborManagementScreen extends StatefulWidget {
  const LaborManagementScreen({super.key});

  @override
  State<LaborManagementScreen> createState() => _LaborManagementScreenState();
}

class _LaborManagementScreenState extends State<LaborManagementScreen> {
  final Box workerBox = Hive.box('workerBox');

  // تابع ثبت کارگر جدید
  void _addNewWorker(String name, String job, double rate) {
    workerBox.put(name, {
      'name': name,
      'job': job,
      'rate': rate,
      'days': 0.0,
      'paid': 0.0,
    });
    setState(() {});
  }

  // تابع اضافه کردن روزکرد
  void _addWorkDay(String name, double days) {
    var data = Map<String, dynamic>.from(workerBox.get(name));
    data['days'] += days;
    workerBox.put(name, data);
    setState(() {});
  }

  // تابع ثبت پرداخت
  void _makePayment(String name, double amount) {
    var data = Map<String, dynamic>.from(workerBox.get(name));
    data['paid'] += amount;
    workerBox.put(name, data);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت نیروها')),
      body: ListView.builder(
        itemCount: workerBox.length,
        itemBuilder: (context, index) {
          final key = workerBox.keyAt(index);
          final data = Map<String, dynamic>.from(workerBox.get(key));
          double totalOwed = (data['days'] * data['rate']) - data['paid'];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(data['name']),
              subtitle: Text('${data['job']} | طلب: $totalOwed تومان'),
              children: [
                ListTile(
                  title: Text('روزکرد فعلی: ${data['days']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _addWorkDay(key, 1.0),
                  ),
                ),
                ListTile(
                  title: const Text('پرداخت حقوق'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // اینجا یک دیالوگ ساده برای وارد کردن مبلغ پرداخت باز می‌شود
                      _showPaymentDialog(key);
                    },
                    child: const Text('ثبت پرداخت'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkerDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // دیالوگ ثبت کارگر جدید
  void _showAddWorkerDialog() {
    final nameCtrl = TextEditingController();
    final jobCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ثبت نیروی جدید'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام کارگر')),
          TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'شغل (بنا/...)')),
          TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'دستمزد روزانه'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              _addNewWorker(nameCtrl.text, jobCtrl.text, double.tryParse(rateCtrl.text) ?? 0);
              Navigator.pop(context);
            },
            child: const Text('ذخیره'),
          )
        ],
      ),
    );
  }

  // دیالوگ ثبت پرداخت
  void _showPaymentDialog(String name) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ثبت پرداختی'),
        content: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ پرداختی')),
        actions: [
          ElevatedButton(
            onPressed: () {
              _makePayment(name, double.tryParse(amountCtrl.text) ?? 0);
              Navigator.pop(context);
            },
            child: const Text('تایید'),
          )
        ],
      ),
    );
  }
}
