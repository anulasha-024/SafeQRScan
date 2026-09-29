import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _history;
  @override
  void initState() { super.initState(); _history = ApiService.getHistory(); }
  void _reload() => setState(() => _history = ApiService.getHistory());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Server scan history'), actions: [
      IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _history, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, children: [Text('${snapshot.error}', textAlign: TextAlign.center),
          TextButton(onPressed: _reload, child: const Text('Retry'))])));
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const Center(child: Text('No scans yet. Verify a QR code first.'));
      return ListView.separated(itemCount: items.length,
        separatorBuilder: (_, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(leading: const Icon(Icons.qr_code),
            title: Text('${item['risk_level']} · ${item['risk_score']}/100'),
            subtitle: Text('${item['qr_payload']}\n${item['timestamp']}', maxLines: 3, overflow: TextOverflow.ellipsis),
            onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
              title: Text('${item['risk_level']}'),
              content: SingleChildScrollView(child: SelectableText('${item['qr_payload']}\n\n${item['reasons']}')),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
            )));
        });
    }),
  );
}
