import 'dart:async';
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ipController = TextEditingController(text: settings.ip);
    _portController = TextEditingController(text: settings.port);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      ref.read(settingsProvider.notifier).updateSettings(
            _ipController.text.trim(),
            _portController.text.trim(),
          );
    });
  }

  void _save() {
    ref.read(settingsProvider.notifier).updateSettings(
      _ipController.text.trim(),
      _portController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas e verificadas!')),
    );
    // Não fecha a tela para permitir visualização do status
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
    final settingsState = ref.watch(settingsProvider);

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
        child: SingleChildScrollView(
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
                onChanged: (_) => _onChanged(),
              ),
              const Gap(16),
              _buildTextField(
                controller: _portController,
                label: 'Porta',
                hint: 'Ex: 8000',
                keyboardType: TextInputType.number,
                onChanged: (_) => _onChanged(),
              ),
              const Gap(24),
              _buildHealthStatus(settingsState),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Salvar e Verificar'),
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
      ),
    );
  }

  Widget _buildHealthStatus(SettingsState state) {
    Color color;
    IconData icon;
    String text;

    switch (state.healthStatus) {
      case HealthStatus.initial:
        return const SizedBox.shrink();
      case HealthStatus.checking:
        color = Colors.blue;
        icon = Icons.refresh;
        text = 'Verificando conexão...';
        break;
      case HealthStatus.success:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        text = 'Health check ok, API alcançável';
        break;
      case HealthStatus.error:
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        text = state.errorMessage ?? 'Erro na API';
        break;
      case HealthStatus.unreachable:
        color = Colors.red;
        icon = Icons.error_outline;
        text = state.errorMessage ?? 'API Inalcançável';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
           state.healthStatus == HealthStatus.checking
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(icon, color: color),
          const Gap(16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
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
          onChanged: onChanged,
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
