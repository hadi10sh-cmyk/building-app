import 'package:flutter/material.dart';

void main() => runApp(const ContractorProApp());

class ContractorProApp extends StatelessWidget {
  const ContractorProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// مدل کارگر برای مدیریت بدهی و شغل
class Worker {
  final String name;
  final String job; // مثلا: بنا، لوله‌کش، گچ‌کار
  final double totalDebt; // بدهی کارگر به پیمانکار
  final double totalCredit; // بستانکاری کارگر

  Worker({required this.name, required this.job, this.totalDebt = 0, this.totalCredit = 0});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // لیست نمونه برای تست
  final List<Worker> _workers = [
    Worker(name: 'رضا بنا', job: 'بنا', totalDebt: 500000),
    Worker(name: 'علی لوله‌کش', job: 'لوله‌کش', totalCredit: 200000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت هوشمند پیمانکاری'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () {
            // اینجا بعداً کد ساخت PDF را اضافه می‌کنیم
          }),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(), // بخش خلاصه وضعیت مالی
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('لیست کارگران و وضعیت بدهی:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _workers.length,
              itemBuilder: (context, index) {
                final worker = _workers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(worker.name[0])),
                    title: Text(worker.name),
                    subtitle: Text(worker.job),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'بدهی: ${worker.totalDebt} ت',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        Text(
                          'بستانکاری: ${worker.totalCredit} ت',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // اینجا فرم اضافه کردن کارگر جدید باز می‌شود
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Text('خلاصه وضعیت پروژه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('کل مصالح خریده شده:'),
              Text('۱۲,۰۰۰,۰۰۰ ت', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('کل دستمزد پرداختی:'),
              Text('۸,۵۰۰,۰۰۰ ت', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
