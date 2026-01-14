import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import 'package:gap/gap.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _ipController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ipController = TextEditingController(text: settings.ip);
    _portController = TextEditingController(text: settings.port);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(settingsProvider.notifier).updateSettings(
      _ipController.text.trim(),
      _portController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas!')),
    );
    Navigator.pop(context);
  }

  void _reset() async {
    await ref.read(settingsProvider.notifier).resetToDefault();
    final settings = ref.read(settingsProvider);
    setState(() {
      _ipController.text = settings.ip;
      _portController.text = settings.port;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restaurado para padrão (Automático)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Configurações de API'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endereço do Backend',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            const Text(
              'Configure o IP e a porta onde o backend FastAPI está rodando.',
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(24),
            _buildTextField(
              controller: _ipController,
              label: 'Endereço IP',
              hint: 'Ex: 10.0.2.2 (Android) ou 127.0.0.1 (PC)',
            ),
            const Gap(16),
            _buildTextField(
              controller: _portController,
              label: 'Porta',
              hint: 'Ex: 8000',
              keyboardType: TextInputType.number,
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restore),
                label: const Text('Resetar Padrão (Auto)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentCyan,
                  side: const BorderSide(color: AppColors.accentCyan),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Gap(8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
