import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/markdown_accordion.dart';
import '../data/models/pocus_item.dart';

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
// Inline video player — Offline-first: cache local em disco.
//
// 1. Verifica se o arquivo já existe em getApplicationDocumentsDirectory()
// 2. Se sim → VideoPlayerController.file() (100% offline)
// 3. Se não → download via Signed URL, salva localmente, depois toca
// ---------------------------------------------------------------------------

/// Derives a deterministic cache filename from a storage path.
/// E.g. "E-Fast/teste1.mp4" → "a1b2c3d4e5.mp4"
String _cacheFileName(String storagePath) {
  final hash = md5.convert(utf8.encode(storagePath)).toString();
  final ext = p.extension(storagePath).isNotEmpty ? p.extension(storagePath) : '.mp4';
  return '$hash$ext';
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.storagePath});
  final String storagePath;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  double _downloadProgress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final localFile = await _localFile();

      // 1. Cache hit — play from disk immediately
      if (await localFile.exists() && await localFile.length() > 0) {
        await _initPlayer(localFile);
        return;
      }

      // 2. Cache miss — download then play
      await _downloadAndCache(localFile);
    } catch (e) {
      if (mounted) setState(() { _error = 'Falha ao carregar vídeo'; _loading = false; });
    }
  }

  Future<File> _localFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(docsDir.path, 'pocus_video_cache'));
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return File(p.join(cacheDir.path, _cacheFileName(widget.storagePath)));
  }

  Future<void> _downloadAndCache(File localFile) async {
    // Get signed URL
    final signedUrl = await Supabase.instance.client.storage
        .from('pocus-media')
        .createSignedUrl(widget.storagePath, 300)
        .timeout(const Duration(seconds: 10));

    // Stream download to disk (avoids loading entire file into memory)
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(signedUrl));
      final response = await request.close().timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        if (mounted) setState(() { _error = 'Erro HTTP ${response.statusCode}'; _loading = false; });
        return;
      }

      final contentLength = response.contentLength;
      final sink = localFile.openWrite();
      int received = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() => _downloadProgress = received / contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      // Validate downloaded file
      if (await localFile.length() == 0) {
        await localFile.delete().catchError((_) => localFile);
        if (mounted) setState(() { _error = 'Download vazio'; _loading = false; });
        return;
      }

      await _initPlayer(localFile);
    } finally {
      httpClient.close();
    }
  }

  Future<void> _initPlayer(File file) async {
    final controller = VideoPlayerController.file(file);
    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    controller.setLooping(true);
    controller.setVolume(0.0);
    setState(() { _controller = controller; _loading = false; });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null) {
      return _VideoPlaceholder(message: _error!);
    }

    // Loading / downloading state
    if (_loading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _downloadProgress > 0
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: _downloadProgress,
                          color: Colors.white54,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_downloadProgress * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(color: Colors.white54),
          ),
        ),
      );
    }

    // Player ready — tap to play/pause
    return GestureDetector(
      onTap: () {
        final c = _controller;
        if (c == null) return;
        setState(() { c.value.isPlaying ? c.pause() : c.play(); });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_controller != null) VideoPlayer(_controller!),
              if (_controller != null && !_controller!.value.isPlaying)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
                ),
            ],
          ),
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
