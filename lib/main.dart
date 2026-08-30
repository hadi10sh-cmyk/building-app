import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const BuildingManagerApp());
}

class BuildingManagerApp extends StatelessWidget {
  const BuildingManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت کارگاه ساختمانی',
      debugShowCheckedModeBanner: false,
      // پشتیبانی کامل از زبان فارسی و راست‌چین
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      locale: const Locale('fa', 'IR'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber[800],
        fontFamily: 'Vazirmatn', // یا فونت دلخواه شما
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // لیست نمونه نیروها برای نمایش در ظاهر برنامه
  final List<Map<String, dynamic>> _workers = [
    {
      'name': 'استاد رحیم',
      'role': 'کاشی‌کار',
      'type': 'متری',
      'rate': 180000, // هر متر مربع
      'workDone': 150.0, // متراژ اجرا شده
      'paid': 20000000,
    },
    {
      'name': 'علی مرادی',
      'role': 'کارگر ساده',
      'type': 'روزمزد',
      'rate': 650000, // روزانه
      'workDone': 22.0, // تعداد روز
      'paid': 10000000,
    },
  ];

  // لیست نمونه مصالح انبار
  final List<Map<String, dynamic>> _materials = [
    {'name': 'سیمان تیپ ۲', 'unit': 'کیسه', 'stock': 140, 'price': 85000},
    {'name': 'گچ سفید سمنان', 'unit': 'کیسه', 'stock': 65, 'price': 48000},
    {'name': 'کاشی ۶۰×۱۲۰ پرسلان', 'unit': 'مترمربع', 'stock': 220, 'price': 390000},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سامانه هوشمند مدیریت پروژه'),
        centerTitle: true,
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: _currentIndex == 0 ? _buildWorkersView() : _buildMaterialsView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'نیروها و دستمزد',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'انبار و مصالح',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        onPressed: () {
          if (_currentIndex == 0) {
            _showAddWorkerDialog();
          } else {
            _showAddMaterialLogDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_currentIndex == 0 ? 'ثبت نیرو / کارکرد' : 'ورود / خروج مصالح'),
      ),
    );
  }

  // ویجت لیست استادکاران و کارگران
  Widget _buildWorkersView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _workers.length,
      itemBuilder: (context, index) {
        final w = _workers[index];
        final totalEarned = w['rate'] * w['workDone'];
        final balance = totalEarned - w['paid'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${w['name']} (${w['role']})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(w['type']),
                      backgroundColor: w['type'] == 'متری' ? Colors.blue[50] : Colors.green[50],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('نرخ واحد: ${w['rate'].toString()} تومان'),
                    Text('کارکرد: ${w['workDone']} ${w['type'] == 'متری' ? 'متر' : 'روز'}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('کل کارکرد: ${totalEarned.toStringAsFixed(0)} تومان'),
                    Text('دریافتی: ${w['paid'].toString()} تومان'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'مانده طلب: ${balance.toStringAsFixed(0)} تومان',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0 ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ویجت موجودی انبار مصالح
  Widget _buildMaterialsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final m = _materials[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber[100],
              child: const Icon(Icons.category, color: Colors.brown),
            ),
            title: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('آخرین قیمت واحد: ${m['price']} تومان'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('موجودی انبار:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '${m['stock']} ${m['unit']}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // فرم ثبت کارگر یا ثبت کارکرد جدید
  void _showAddWorkerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت نیروی کار یا کارکرد جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'نام و نام خانوادگی')),
            TextField(decoration: InputDecoration(labelText: 'تخصص (کاشی‌کار، گچ‌کار و...)')),
            TextField(
              decoration: InputDecoration(labelText: 'نرخ دستمزد (روزانه یا متری)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ثبت')),
        ],
      ),
    );
  }

  // فرم ورود یا خروج مصالح
  void _showAddMaterialLogDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت ورود / خروج مصالح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'نام مصالح (مثلاً سیمان)')),
            TextField(
              decoration: InputDecoration(labelText: 'مقدار (تعداد/متراژ/وزن)'),
              keyboardType: TextInputType.number,
            ),
            TextField(decoration: InputDecoration(labelText: 'توضیحات (محل مصرف یا نام فروشنده)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ذخیره')),
        ],
      ),
    );
  }
}
