import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../data/models/media_asset.dart';
import '../data/models/pocus_item.dart';
import '../data/pocus_repository.dart';

class PocusPlayerScreen extends ConsumerStatefulWidget {
  const PocusPlayerScreen({
    super.key,
    required this.pocusItem,
  });

  final PocusItem pocusItem;

  @override
  ConsumerState<PocusPlayerScreen> createState() => _PocusPlayerScreenState();
}

class _PocusPlayerScreenState extends ConsumerState<PocusPlayerScreen> {
  // Futures are cached by asset ID so FutureBuilder never receives a new
  // Future object on widget rebuild (stream update → rebuild would otherwise
  // reset FutureBuilder to ConnectionState.waiting indefinitely).
  final Map<String, Future<String?>> _pathFutures = {};

  Future<String?> _pathFor(MediaAsset asset) {
    return _pathFutures[asset.id] ??=
        ref.read(pocusRepositoryProvider).resolveLocalPath(asset);
  }

  @override
  Widget build(BuildContext context) {
    final asyncAssets = ref.watch(watchMediaAssetsProvider(widget.pocusItem.id));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.pocusItem.titlePt),
        backgroundColor: Colors.transparent,
      ),
      body: asyncAssets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (assets) {
          final videoAssets = assets.where((a) => a.kind == 'video').toList();

          if (videoAssets.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum vídeo disponível',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final videoAsset = videoAssets.first;

          return FutureBuilder<String?>(
            future: _pathFor(videoAsset),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Carregando vídeo offline...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Text(
                    'Erro ao carregar o vídeo offline.\n${snapshot.error ?? "Vídeo não encontrado."}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final localPath = snapshot.data!;

              return LocalVideoPlayer(localPath: localPath);
            },
          );
        },
      ),
    );
  }
}

class LocalVideoPlayer extends StatefulWidget {
  const LocalVideoPlayer({super.key, required this.localPath});
  final String localPath;

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.localPath));
    _controller.initialize().then((_) {
      if (mounted) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

