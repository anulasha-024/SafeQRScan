import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerificationResultPage extends StatefulWidget {
  final String payload;
  final Map<String, dynamic> result;
  const VerificationResultPage({super.key, required this.payload, required this.result});
  @override
  State<VerificationResultPage> createState() => _VerificationResultPageState();
}

class _VerificationResultPageState extends State<VerificationResultPage> {
  bool _reporting = false;
  Future<void> _report() async {
    String reason = '';
    final submitted = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Report this QR code'),
      content: TextField(maxLength: 2000, maxLines: 3, onChanged: (value) => reason = value,
          decoration: const InputDecoration(hintText: 'Why is it suspicious?')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (reason.trim().isNotEmpty) Navigator.pop(context, reason.trim());
        }, child: const Text('Submit'))],
    ));
    if (submitted == null || !mounted) return;
    setState(() => _reporting = true);
    try {
      await ApiService.reportQr(widget.payload, submitted);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report saved.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally { if (mounted) setState(() => _reporting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final merchant = result['merchant'] as Map?;
    final score = result['risk_score'] as num? ?? 0;
    return Scaffold(appBar: AppBar(title: const Text('Verification result')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text('${result['risk_level']}', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text('Risk score: $score / 100'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (score / 100).clamp(0.0, 1.0),
            color: score > 60 ? Colors.red : Colors.amber),
        const SizedBox(height: 20),
        const Text('Rule-based demo assessment. This does not guarantee a safe payment or website.'),
        const SizedBox(height: 20),
        const Text('Reasons', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final reason in (result['reasons'] as List? ?? []))
          ListTile(leading: const Icon(Icons.info_outline), title: Text('$reason'.replaceAll('_', ' '))),
        if (merchant != null) ...[
          const Text('Merchant', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final entry in merchant.entries)
            if (entry.value != null) Text('${entry.key.toString().replaceAll('_', ' ')}: ${entry.value}'),
        ],
        const SizedBox(height: 20),
        const Text('Scanned payload', style: TextStyle(fontWeight: FontWeight.bold)),
        SelectableText(widget.payload),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: _reporting ? null : _report,
          icon: const Icon(Icons.flag_outlined), label: Text(_reporting ? 'Saving…' : 'Report suspicious QR')),
      ]));
  }
}
