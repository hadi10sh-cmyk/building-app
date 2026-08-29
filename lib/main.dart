import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // راه‌اندازی دیتابیس آفلاین
  await Hive.initFlutter();
  await Hive.openBox('workers_box');
  await Hive.openBox('materials_box');
  await Hive.openBox('material_logs_box');

  runApp(const BuildingApp());
}

// قالب کلی نرم‌افزار با پشتیبانی کامل از زبان فارسی
class BuildingApp extends StatelessWidget {
  const BuildingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت کارگاه ساختمانی',
      debugShowCheckedModeBanner: false,
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
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;

  // دریافت تاریخ امروز به شمسی
  String get _todayShamsi {
    final now = Jalali.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
  }

  // فرمت ارقام به ریال / تومان با جداکننده ۳ رقمی
  String formatMoney(num amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت هوشمند پروژه و کارگاه', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'ارسال گزارش جامع به پیام‌رسان‌ها',
            onPressed: _exportAndShareReport,
          ),
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: 'محاسبه‌گر متراژ و کسر درگاه',
            onPressed: _openAreaCalculator,
          ),
        ],
      ),
      body: _tabIndex == 0 ? _buildWorkersTab() : _buildMaterialsTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'استادکاران و کارگران',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'انبار و ورود/خروج مصالح',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_tabIndex == 0 ? 'ثبت استادکار/کارگر' : 'ورود/خروج مصالح'),
        onPressed: () {
          if (_tabIndex == 0) {
            _showWorkerDialog();
          } else {
            _showMaterialDialog();
          }
        },
      ),
    );
  }

  // ==========================================
  // ۱. بخش مدیریت نیروها، متراژ و دستمزد
  // ==========================================
  Widget _buildWorkersTab() {
    final box = Hive.box('workers_box');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        if (b.isEmpty) {
          return const Center(
            child: Text('هنوز هیچ نیرویی ثبت نشده است.\nاز دکمه زیر برای ثبت استفاده کنید.', textAlign: TextAlign.center),
          );
        }

        return ListView.builder(
          itemCount: b.length,
          itemBuilder: (context, index) {
            final key = b.keyAt(index);
            final w = Map<String, dynamic>.from(b.get(key));

            final isPerMeter = w['type'] == 'متری';
            final rate = (w['rate'] ?? 0) as num;
            final workDone = (w['workDone'] ?? 0) as num;
            final paid = (w['paid'] ?? 0) as num;

            final totalEarned = rate * workDone;
            final balance = totalEarned - paid;

            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isPerMeter ? Colors.blue[100] : Colors.green[100],
                  child: Icon(isPerMeter ? Icons.straighten : Icons.timer, color: Colors.black87),
                ),
                title: Text('${w['name']} (${w['role']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('نرخ: ${formatMoney(rate)} تومان (${isPerMeter ? 'متری' : 'روزمزد'})'),
                trailing: Text(
                  'طلب: ${formatMoney(balance)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0 ? Colors.red[800] : Colors.green[800],
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('کل کارکرد: $workDone ${isPerMeter ? 'متر' : 'روز'}'),
                            Text('مبلغ استحقاقی: ${formatMoney(totalEarned)} تومان'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('کل پرداختی (مساعده): ${formatMoney(paid)} تومان'),
                            Text('شماره تماس: ${w['phone'] ?? "ثبت نشده"}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_task, size: 18),
                              label: Text(isPerMeter ? '+ ثبت متراژ' : '+ ثبت روزکار'),
                              onPressed: () => _updateWorkDone(key, w),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.payments, size: 18),
                              label: const Text('+ پرداخت مساعده'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[50]),
                              onPressed: () => _addPayment(key, w),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => b.delete(key),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // دیالوگ ثبت نیروی جدید
  void _showWorkerDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String workType = 'متری';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('ثبت نیروی کار جدید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی')),
                TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'تخصص (کاشی‌کار، گچ‌کار، کارگر ساده)')),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره تماس')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: workType,
                  decoration: const InputDecoration(labelText: 'نوع قرارداد'),
                  items: const [
                    DropdownMenuItem(value: 'متری', child: Text('متری (کاشی، گچ، سنگ و...)')),
                    DropdownMenuItem(value: 'روزمزد', child: Text('روزمزد (کارگر، نگهبان و...)')),
                  ],
                  onChanged: (val) => setModalState(() => workType = val!),
                ),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: workType == 'متری' ? 'نرخ هر متر مربع (تومان)' : 'دستمزد هر روز (تومان)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
                  Hive.box('workers_box').add({
                    'name': nameCtrl.text,
                    'role': roleCtrl.text,
                    'phone': phoneCtrl.text,
                    'type': workType,
                    'rate': double.tryParse(rateCtrl.text) ?? 0,
                    'workDone': 0.0,
                    'paid': 0.0,
                    'createdDate': _todayShamsi,
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  // ثبت متراژ اجرا شده یا تعداد روز جدید
  void _updateWorkDone(dynamic key, Map<String, dynamic> w) {
    final valCtrl = TextEditingController();
    final isPerMeter = w['type'] == 'متری';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPerMeter ? 'ثبت متراژ جدید برای ${w['name']}' : 'ثبت روزکار جدید برای ${w['name']}'),
        content: TextField(
          controller: valCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: isPerMeter ? 'متراژ کار شده جدید (مترمربع)' : 'تعداد روز کارکرد جدید',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              final added = double.tryParse(valCtrl.text) ?? 0;
              w['workDone'] = ((w['workDone'] ?? 0) as num) + added;
              Hive.box('workers_box').put(key, w);
              Navigator.pop(ctx);
            },
            child: const Text('افزودن و محاسبه'),
          ),
        ],
      ),
    );
  }

  // ثبت واریز مساعده
  void _addPayment(dynamic key, Map<String, dynamic> w) {
    final payCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('پرداخت مساعده به ${w['name']}'),
        content: TextField(
          controller: payCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مبلغ پرداختی (تومان)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              final pay = double.tryParse(payCtrl.text) ?? 0;
              w['paid'] = ((w['paid'] ?? 0) as num) + pay;
              Hive.box('workers_box').put(key, w);
              Navigator.pop(ctx);
            },
            child: const Text('ثبت پرداخت'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ۲. بخش انبارداری، ورود و خروج مصالح
  // ==========================================
  Widget _buildMaterialsTab() {
    final box = Hive.box('materials_box');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        if (b.isEmpty) {
          return const Center(child: Text('هیچ مصالحی در انبار تعریف نشده است.'));
        }

        return ListView.builder(
          itemCount: b.length,
          itemBuilder: (context, index) {
            final key = b.keyAt(index);
            final m = Map<String, dynamic>.from(b.get(key));
            final stock = (m['stock'] ?? 0) as num;
            final isLowStock = stock <= 10;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLowStock ? Colors.red[100] : Colors.amber[100],
                  child: Icon(Icons.category, color: isLowStock ? Colors.red : Colors.brown),
                ),
                title: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('واحد: ${m['unit']} | قیمت واحد: ${formatMoney(m['price'] ?? 0)} تومان'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('موجودی انبار:', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    Text(
                      '$stock ${m['unit']}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red : Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                onTap: () => _showMaterialInOutDialog(key, m),
              ),
            );
          },
        );
      },
    );
  }

  // تعریف مصالح جدید در انبار
  void _showMaterialDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'کیسه');
    final stockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعریف مصالح جدید در انبار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام مصالح (مثلاً سیمان تیپ ۲)')),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'واحد (کیسه، تن، مترمربع، شاخه)')),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی اولیه')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت خرید هر واحد (تومان)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Hive.box('materials_box').add({
                  'name': nameCtrl.text,
                  'unit': unitCtrl.text,
                  'stock': double.tryParse(stockCtrl.text) ?? 0,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('ثبت در انبار'),
          ),
        ],
      ),
    );
  }

  // ثبت ورود (خرید) یا خروج (مصرف) بار
  void _showMaterialInOutDialog(dynamic key, Map<String, dynamic> m) {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isEntry = true; // true: ورود، false: خروج/مصرف

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('ورود یا مصرف: ${m['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('ورود بار'),
                      value: true,
                      groupValue: isEntry,
                      onChanged: (v) => setModalState(() => isEntry = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('مصرف/خروج'),
                      value: false,
                      groupValue: isEntry,
                      onChanged: (v) => setModalState(() => isEntry = v!),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'مقدار (${m['unit']})'),
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'محل مصرف یا نام فروشنده'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                double currentStock = (m['stock'] ?? 0).toDouble();

                if (isEntry) {
                  currentStock += qty;
                } else {
                  currentStock -= qty;
                }

                m['stock'] = currentStock;
                Hive.box('materials_box').put(key, m);

                // ثبت لاگ ورود و خروج
                Hive.box('material_logs_box').add({
                  'materialName': m['name'],
                  'qty': qty,
                  'isEntry': isEntry,
                  'note': noteCtrl.text,
                  'date': _todayShamsi,
                });

                Navigator.pop(ctx);
              },
              child: const Text('ثبت نهایی'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ۳. محاسبه‌گر پیشرفته متراژ با کسر درگاه و پنجره
  // ==========================================
  void _openAreaCalculator() {
    final lengthCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final deductLengthCtrl = TextEditingController();
    final deductHeightCtrl = TextEditingController();
    double netArea = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('محاسبه‌گر متراژ کاشی‌کاری / گچ‌کاری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: lengthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'طول دیوار/کف (متر)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ارتفاع/عرض (متر)'))),
                ],
              ),
              const SizedBox(height: 8),
              const Text('کسر درگاه، پنجره و بازشوها:', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
              Row(
                children: [
                  Expanded(child: TextField(controller: deductLengthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عرض درگاه (متر)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: deductHeightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ارتفاع درگاه (متر)'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final l = double.tryParse(lengthCtrl.text) ?? 0;
                      final h = double.tryParse(heightCtrl.text) ?? 0;
                      final dl = double.tryParse(deductLengthCtrl.text) ?? 0;
                      final dh = double.tryParse(deductHeightCtrl.text) ?? 0;

                      final total = l * h;
                      final deduct = dl * dh;
                      setModalState(() {
                        netArea = (total - deduct) > 0 ? (total - deduct) : 0;
                      });
                    },
                    child: const Text('محاسبه متراژ خالص'),
                  ),
                  Text('متراژ خالص: ${netArea.toStringAsFixed(2)} مترمربع', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ۴. ارسال خروجی گزارش و اکسل به پیام‌رسان‌ها
  // ==========================================
  Future<void> _exportAndShareReport() async {
    final workersBox = Hive.box('workers_box');
    final materialsBox = Hive.box('materials_box');

    // ساخت محتوای متنی و فایل CSV قابل باز شدن در اکسل
    StringBuffer textReport = StringBuffer();
    StringBuffer csvReport = StringBuffer();

    textReport.writeln('📋 گزارش جامع کارگاه ساختمانی');
    textReport.writeln('📅 تاریخ گزارش: $_todayShamsi\n');

    // هدر فایل اکسل برای کارگران
    csvReport.writeln('گزارش وضعیت کارگران و استادکاران');
    csvReport.writeln('نام,تخصص,نوع قرارداد,نرخ واحد,کارکرد کل,دریافتی,مانده طلب');

    textReport.writeln('👷 وضعیت استادکاران و نیروها:');
    for (int i = 0; i < workersBox.length; i++) {
      final w = Map<String, dynamic>.from(workersBox.getAt(i));
      final rate = (w['rate'] ?? 0) as num;
      final workDone = (w['workDone'] ?? 0) as num;
      final paid = (w['paid'] ?? 0) as num;
      final balance = (rate * workDone) - paid;

      textReport.writeln('- ${w['name']} (${w['role']}): کارکرد: $workDone | طلب: ${formatMoney(balance)} تومان');
      csvReport.writeln('${w['name']},${w['role']},${w['type']},$rate,$workDone,$paid,$balance');
    }

    textReport.writeln('\n📦 وضعیت موجودی انبار:');
    csvReport.writeln('\nگزارش موجودی انبار مصالح');
    csvReport.writeln('نام مصالح,واحد,موجودی فعلی,قیمت واحد');

    for (int i = 0; i < materialsBox.length; i++) {
      final m = Map<String, dynamic>.from(materialsBox.getAt(i));
      textReport.writeln('- ${m['name']}: ${m['stock']} ${m['unit']}');
      csvReport.writeln('${m['name']},${m['unit']},${m['stock']},${m['price']}');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Building_Report_$_todayShamsi.csv');
      // ذخیره با انکودینگ UTF-8 و BOM برای پشتیبانی کامل اکسل از حروف فارسی
      await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...csvReport.toString().codeUnits]);

      // ارسال مستقیم به پیام‌رسان‌ها (روبیکا، ایتا، بله، تلگرام، واتساپ و...)
      await Share.shareXFiles(
        [XFile(file.path)],
        text: textReport.toString(),
        subject: 'گزارش حسابداری و مصالح کارگاه - $_todayShamsi',
      );
    } catch (e) {
      // در صورت بروز خطا در ذخیره فایل، متن گزارش به اشتراک گذاشته می‌شود
      await Share.share(textReport.toString());
    }
  }
}
