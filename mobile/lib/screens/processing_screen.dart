import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? sessionId;

  const ProcessingScreen({
    super.key,
    required this.imageBytes,
    this.sessionId,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _status = 'Загрузка фото...';
  Timer? _pollTimer;
  String? _jobId;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final job = await ApiService.instance.processPhoto(
        widget.imageBytes,
        'capture.jpg',
        sessionId: widget.sessionId,
      );
      _jobId = job.jobId;
      setState(() => _status = 'AI обрабатывает фото (10–20 сек)...');
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e) {
      setState(() => _status = 'Ошибка: $e');
    }
  }

  Future<void> _poll() async {
    if (_jobId == null) return;
    try {
      final result = await ApiService.instance.getResult(_jobId!);
      if (result.isCompleted && result.imageBase64 != null) {
        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              originalBytes: widget.imageBytes,
              resultBase64: result.imageBase64!,
              mimeType: result.mimeType ?? 'image/png',
              jobId: _jobId!,
            ),
          ),
        );
      } else if (result.isFailed) {
        _pollTimer?.cancel();
        setState(() => _status = result.error ?? 'Обработка не удалась');
      } else {
        setState(() => _status = 'Статус: ${result.status}...');
      }
    } catch (e) {
      setState(() => _status = 'Ошибка polling: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Создаём пустынный фон',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
