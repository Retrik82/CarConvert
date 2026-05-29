import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ResultScreen extends StatelessWidget {
  final Uint8List originalBytes;
  final String resultBase64;
  final String mimeType;
  final String jobId;

  const ResultScreen({
    super.key,
    required this.originalBytes,
    required this.resultBase64,
    required this.mimeType,
    required this.jobId,
  });

  Future<void> _save(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = mimeType.contains('png') ? 'png' : 'jpg';
      final file = File('${dir.path}/carconvert_$jobId.$ext');
      await file.writeAsBytes(base64Decode(resultBase64));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сохранено: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultBytes = base64Decode(resultBase64);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Результат'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _save(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              children: [
                _ImagePage(label: 'До', bytes: originalBytes),
                _ImagePage(label: 'После', bytes: resultBytes),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Свайп влево — сравнить до/после',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePage extends StatelessWidget {
  final String label;
  final Uint8List bytes;

  const _ImagePage({required this.label, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(label, style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
