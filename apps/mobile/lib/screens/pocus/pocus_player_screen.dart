import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../models/media_asset.dart';
import '../../services/media_cache_manager.dart';

/// Screen that plays a POCUS ultrasound video.
///
/// Key design decisions:
/// - Video Future is created in initState, NOT in build()
///   (creating it in build causes infinite rebuild loops)
/// - Timeout on video loading prevents infinite spinner
/// - Clear error states shown to user instead of silent failures
class PocusPlayerScreen extends StatefulWidget {
  final String pocusItemId;
  final String title;

  const PocusPlayerScreen({
    super.key,
    required this.pocusItemId,
    required this.title,
  });

  @override
  State<PocusPlayerScreen> createState() => _PocusPlayerScreenState();
}

class _PocusPlayerScreenState extends State<PocusPlayerScreen> {
  late final MediaCacheManager _cacheManager;

  /// The video loading future — created once in initState, never in build().
  late final Future<_VideoLoadResult> _videoFuture;

  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _cacheManager = MediaCacheManager(Supabase.instance.client);
    // Create the Future ONCE here, not in build()
    _videoFuture = _loadVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<_VideoLoadResult> _loadVideo() async {
    try {
      // 1. Query media_assets for this pocus_item's video
      final rows = await Supabase.instance.client
          .from('media_assets')
          .select()
          .eq('owner_type', 'pocus_items')
          .eq('owner_id', widget.pocusItemId)
          .eq('kind', 'video')
          .limit(1)
          .timeout(const Duration(seconds: 10));

      if (rows.isEmpty) {
        return _VideoLoadResult.error(
          'Nenhum vídeo encontrado para este item.',
        );
      }

      final asset = MediaAsset.fromRow(rows.first);

      // 2. Get local cached file (downloads if needed)
      final file = await _cacheManager.getFile(asset.path);

      if (file == null) {
        return _VideoLoadResult.error(
          'Falha ao baixar o vídeo. Verifique sua conexão.',
        );
      }

      // 3. Initialize video player
      final controller = VideoPlayerController.file(file);
      await controller.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Video init timeout'),
          );
      controller.setLooping(true);
      await controller.play();

      _controller = controller;
      return _VideoLoadResult.success(controller);
    } catch (e) {
      print('[PocusPlayerScreen] Error loading video: $e');
      return _VideoLoadResult.error(
        'Erro ao carregar vídeo: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_VideoLoadResult>(
        // Use the memoized future — never create a new one here
        future: _videoFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando vídeo...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          // Error from Future itself
          if (snapshot.hasError) {
            return _buildError('Erro inesperado: ${snapshot.error}');
          }

          final result = snapshot.data!;

          // Error from our loading logic
          if (result.error != null) {
            return _buildError(result.error!);
          }

          // Success — show video
          final controller = result.controller!;
          return Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _controller?.dispose();
                  _controller = null;
                  // Recreate future on retry
                  _videoFuture = _loadVideo();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoLoadResult {
  final VideoPlayerController? controller;
  final String? error;

  _VideoLoadResult.success(this.controller) : error = null;
  _VideoLoadResult.error(this.error) : controller = null;
}
