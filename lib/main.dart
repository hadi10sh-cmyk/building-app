import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // مقداردهی اولیه برای دیتابیس‌های مختلف
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // باز کردن باکس‌ها (اگر باز نباشند، در اولین اجرا ایجاد می‌شوند)
  await Hive.openBox('inventoryBox');
  await Hive.openBox('laborBox');

  runApp(const BuildingApp());
}

class BuildingApp extends StatelessWidget {
  const BuildingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت پیمانکاری ساختمانی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        fontFamily: 'sans-serif', // در صورت داشتن فونت فارسی، نام آن را اینجا بگذار
      ),
      home: const MainDashboard(),
    );
  }
}

// -----------------------------------------------------------------------------
// ۱. منوی اصلی (Dashboard)
// -----------------------------------------------------------------------------
class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت پیمانکاری'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 40),
            _buildMenuButton(
              context,
              title: 'مدیریت انبار کالا',
              icon: Icons.inventory,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InventoryScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context,
              title: 'مدیریت نیروی انسانی',
              icon: Icons.people,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LaborManagementScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28, color: Colors.white),
        label: Text(title, style: const TextStyle(fontSize: 20, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ۲. بخش انبارداری (Inventory)
// -----------------------------------------------------------------------------
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

  void _updateStock(String itemName, int amount) {
    final currentStock = inventoryBox.get(itemName, defaultValue: 0) as int;
    final newStock = currentStock + amount;
    if (newStock < 0) return;
    inventoryBox.put(itemName, newStock);
    setState(() {});
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن کالای جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام کالا')),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'مقدار اولیه'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _updateStock(nameController.text, int.tryParse(qtyController.text) ?? 0);
                Navigator.pop(context);
              }
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = inventoryBox.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('انبارداری')),
      body: ListView.builder(
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final name = keys[index] as String;
          final stock = inventoryBox.get(name) as int;
          return ListTile(
            title: Text(name),
            subtitle: Text('موجودی: $stock'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: () => _updateStock(name, -1)),
                IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () => _updateStock(name, 1)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    );
  }
}

// -----------------------------------------------------------------------------
// ۳. بخش مدیریت کارگران (Labor Management)
// -----------------------------------------------------------------------------
class LaborManagementScreen extends StatefulWidget {
  const LaborManagementScreen({super.key});

  @override
  State<LaborManagementScreen> createState() => _LaborManagementScreenState();
}

class _LaborManagementScreenState extends State<LaborManagementScreen> {
  late Box laborBox;
  final List<String> jobTypes = ['بنا', 'سیمان‌کار', 'لوله‌کش', 'برق‌کار', 'نقاش', 'کارگر عمومی', 'دیگر'];

  @override
  void initState() {
    super.initState();
    laborBox = Hive.box('laborBox');
  }

  void _addWorker(String name, String job) {
    if (name.isNotEmpty) {
      laborBox.put(name, {'job': job, 'days': 0});
      setState(() {});
    }
  }

  void _updateDays(String name, int delta) {
    final workerData = Map<String, dynamic>.from(laborBox.get(name));
    int newDays = workerData['days'] + delta;
    if (newDays < 0) return;
    workerData['days'] = newDays;
    laborBox.put(name, workerData);
    setState(() {});
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    String selectedJob = jobTypes[0];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ثبت نیروی جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام کالا')),
            DropdownButtonFormField<String>(
              value: selectedJob,
              items: jobTypes.map((job) => DropdownMenuItem(value: job, child: Text(job))).toList(),
              onChanged: (val) => selectedJob = val!,
              decoration: const InputDecoration(labelText: 'نوع شغل'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              _addWorker(nameController.text, selectedJob);
              Navigator.pop(context);
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workerNames = laborBox.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت کارگران'), backgroundColor: Colors.orangeAccent),
      body: ListView.builder(
        itemCount: workerNames.length,
        itemBuilder: (context, index) {
          final name = workerNames[index] as String;
          final data = Map<String, dynamic>.from(laborBox.get(name));
          return ListTile(
            title: Text(name),
            subtitle: Text('شغل: ${data['job']} | روزکرد: ${data['days']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: () => _updateDays(name, -1)),
                IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () => _updateDays(name, 1)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddWorkerDialog, child: const Icon(Icons.person_add)),
    );
  }
}
