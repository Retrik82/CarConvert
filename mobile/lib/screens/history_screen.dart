import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/history_item.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.instance.getHistory();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openJob(HistoryItem item) async {
    if (!item.hasResult || item.status != 'completed') return;
    try {
      final result = await ApiService.instance.getResult(item.jobId);
      if (!mounted || result.imageBase64 == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            originalBytes: Uint8List(0),
            resultBase64: result.imageBase64!,
            mimeType: result.mimeType ?? 'image/png',
            jobId: item.jobId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('История'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _items.isEmpty
                  ? const Center(child: Text('Пока нет обработок', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return ListTile(
                          leading: Icon(
                            item.status == 'completed' ? Icons.check_circle : Icons.hourglass_empty,
                            color: item.status == 'completed' ? Colors.greenAccent : Colors.amber,
                          ),
                          title: Text(
                            'Обработка ${item.jobId.substring(0, 8)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt.toLocal()),
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Text(item.status, style: const TextStyle(color: Colors.white38)),
                          onTap: () => _openJob(item),
                        );
                      },
                    ),
    );
  }
}
