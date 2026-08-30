import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // برای فرمت تاریخ

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usageBox = Hive.box('usageBox');

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش مصرف مصالح')),
      body: ValueListenableBuilder(
        valueListenable: usageBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('هنوز مصرفی ثبت نشده است'));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final record = box.getAt(index);
              // استخراج اطلاعات
              final itemName = record['item'];
              final qty = record['qty'];
              final worker = record['worker'];
              final dateStr = record['timestamp'];
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('$itemName | $qty واحد'),
                  subtitle: Text('کارگر: $worker'),
                  trailing: Text(dateStr.substring(0, 16)), // نمایش تاریخ کوتاه
                ),
              );
            },
          );
        },
      ),
    );
  }
}
