import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/markdown_accordion.dart';
import '../data/models/pocus_item.dart';
import '../data/video_download_manager.dart';

// ---------------------------------------------------------------------------
// PocusPlayerScreen — Multi-window protocol detail screen.
// Route: /pocus/player/:id   receives PocusItem via GoRouter extra.
// ---------------------------------------------------------------------------

class PocusPlayerScreen extends StatelessWidget {
  const PocusPlayerScreen({super.key, required this.pocusItem});

  final PocusItem pocusItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: Text(
          pocusItem.titlePt,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(pocusItem: pocusItem),
            _WindowSections(pocusItem: pocusItem),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — category chip + title + premium badge
// ---------------------------------------------------------------------------

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.pocusItem});

  final PocusItem pocusItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pocusItem.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF004D40),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pocusItem.titlePt,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
          ),
          if (pocusItem.isPremium) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.workspace_premium, size: 14, color: Color(0xFFFF6F61)),
                const SizedBox(width: 4),
                Text(
                  'Conteúdo Premium',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6F61),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// Video-aware image builder — wires _InlineVideoPlayer for .mp4/.mov/.webm
// ===========================================================================

Widget _buildMarkdownImage(MarkdownImageConfig config) {
  final path = config.uri.toString();
  final isVideo =
      path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.webm');

  if (isVideo) return _InlineVideoPlayer(storagePath: path);

  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      path,
      width: config.width,
      height: config.height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );
}

// ===========================================================================
// UI — Body content from Supabase (Markdown) rendered as shared accordions
// ===========================================================================

class _WindowSections extends StatelessWidget {
  const _WindowSections({required this.pocusItem});

  final PocusItem pocusItem;

  @override
  Widget build(BuildContext context) {
    final body = pocusItem.bodyPt;

    if (body.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Conteúdo ainda não disponível.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    final parsed = parseMarkdownBody(body);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro (text before first ###) ──────────────────────────
            if (parsed.intro.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MarkdownBody(
                  data: parsed.intro,
                  selectable: true,
                  sizedImageBuilder: _buildMarkdownImage,
                  styleSheet: sharedMarkdownStyle(),
                ),
              ),

            // ── Accordion sections (one per ###) ──────────────────────
            for (int i = 0; i < parsed.sections.length; i++) ...[
              MarkdownSectionCard(
                section: parsed.sections[i],
                index: i,
                initiallyExpanded: i == 0,
                imageBuilder: _buildMarkdownImage,
              ),
              if (i < parsed.sections.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline video player — Offline-first via VideoDownloadManager.
//
// Downloads are managed by a global keepAlive ChangeNotifier, so they survive
// widget disposal. The widget just observes the download state and initializes
// the VideoPlayerController when the file is ready.
// ---------------------------------------------------------------------------

class _InlineVideoPlayer extends ConsumerStatefulWidget {
  const _InlineVideoPlayer({required this.storagePath});
  final String storagePath;

  @override
  ConsumerState<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends ConsumerState<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _playerInitStarted = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the manager deduplicates and survives widget disposal.
    ref.read(videoDownloadManagerProvider).ensureDownloaded(widget.storagePath);
  }

  Future<void> _initPlayer(String path) async {
    if (_playerInitStarted) return;
    _playerInitStarted = true;

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    controller.setLooping(true);
    controller.setVolume(0.0);
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(
      videoDownloadManagerProvider
          .select((m) => m.taskFor(widget.storagePath)),
    );

    // Completed — initialize player if not already done.
    if (task.status == DownloadStatus.completed && task.localPath != null) {
      _initPlayer(task.localPath!);
    }

    // Error state
    if (task.status == DownloadStatus.error) {
      return _VideoPlaceholder(message: task.error ?? 'Erro');
    }

    // Player ready — tap to play/pause
    if (_controller != null) {
      return GestureDetector(
        onTap: () {
          final c = _controller;
          if (c == null) return;
          setState(() {
            c.value.isPlaying ? c.pause() : c.play();
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller!),
                if (!_controller!.value.isPlaying)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.play_arrow, size: 36, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading / downloading state
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: task.progress > 0
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: task.progress,
                        color: Colors.white54,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(task.progress * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.white54),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable dark placeholder for error / unavailable states
// ---------------------------------------------------------------------------

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      ),
    );
  }
}
