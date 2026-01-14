import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/download_provider.dart';
import '../widgets/quality_selector.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleDownload() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Obter estado atual para saber se é first fetch ou start download
    final state = ref.read(downloadProvider);

    if (state is DownloadInitial || state is DownloadError || state is DownloadSuccess) {
      ref.read(downloadProvider.notifier).fetchVideoInfo(url);
    } else if (state is DownloadInfoLoaded) {
      ref.read(downloadProvider.notifier).startDownload(url, state.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadProvider);

    // Listen for transient errors to show SnackBar
    ref.listen(downloadProvider, (previous, next) {
      if (next is DownloadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const Gap(40),
                        _buildInputSection(state),
                        const Gap(24),
                        _buildStatusSection(state),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          PhosphorIcons.youtubeLogo(PhosphorIconsStyle.fill),
          size: 64,
          color: Colors.redAccent,
        ),
        const Gap(16),
        Text(
          'YouTube Downloader',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Baixe vídeos para estudar offline',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }


  Widget _buildInputSection(DownloadState state) {
    bool isLoading = state is DownloadLoading;
    bool showDownloadBtn = state is DownloadInfoLoaded;

    return GlassCard(
      child: Column(
        children: [
          GlassTextField(
            key: const Key('url_input'),
            controller: _urlController,
            hintText: 'Cole o link do YouTube aqui...',
            prefixIcon: const Icon(Icons.link, color: Colors.white54),
          ),
          const Gap(16),
          if (state is DownloadInfoLoaded && state.availableQualities.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 16),
              child: QualitySelector(
                // Map the full objects to just heights for the selector widget
                // Assuming QualitySelector expects List<int>
                qualities: state.availableQualities.map<int>((q) => q['height'] as int).toList(),
                selectedQuality: state.selectedQuality ?? 0,
                onSelected: (quality) {
                  ref.read(downloadProvider.notifier).setQuality(quality);
                },
              ),
            ),
          ],
          PrimaryButton(
            key: const Key('action_button'),
            onPressed: isLoading ? null : _handleDownload,
            text: showDownloadBtn ? 'Baixar Agora' : 'Buscar Vídeo',
            isLoading: isLoading,
            icon: Icon(
              showDownloadBtn ? PhosphorIcons.downloadSimple() : PhosphorIcons.magnifyingGlass(),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(DownloadState state) {
    if (state is DownloadInfoLoaded) {
      final info = state.info;
      return GlassCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                info['thumbnail'],
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey, width: 80, height: 60),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    info['uploader'],
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (state is DownloadProcessing) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text(
              'Processando Download...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Gap(12),

            // Video Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vídeo', style: TextStyle(color: Colors.white70)),
                Text('${state.videoProgress.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white)),
              ],
            ),
            const Gap(4),
            LinearProgressIndicator(
              value: state.videoProgress / 100,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
            ),
            const Gap(12),

             // Audio Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Áudio', style: TextStyle(color: Colors.white70)),
                Text('${state.audioProgress.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white)),
              ],
            ),
            const Gap(4),
            LinearProgressIndicator(
              value: state.audioProgress / 100,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
            ),

            if (state.isMerging) ...[
              const Gap(16),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)
                  ),
                  Gap(8),
                  Text('Unindo arquivos (FFmpeg)...', style: TextStyle(color: Colors.yellowAccent)),
                ],
              )
            ]
          ],
        ),
      );
    } else if (state is DownloadSuccess) {
      return GlassCard(
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 40),
            const Gap(8),
            const Text(
              'Download Concluído!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              'Salvo como: ${state.filename}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
             const Gap(12),
            PrimaryButton(
              onPressed: () {
                // Reset to initial or keep info? Let's reset for new search
                 ref.invalidate(downloadProvider);
                 _urlController.clear();
              },
              text: 'Novo Download',
              icon: const Icon(Icons.download, color: Colors.white),
            ),
          ],
        ),
      );
    } else if (state is DownloadError) {
      return GlassCard(
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const Gap(12),
                Expanded(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            const Gap(12),
            PrimaryButton(
              onPressed: _handleDownload, // Retry with same URL
              text: 'Tentar Novamente',
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
