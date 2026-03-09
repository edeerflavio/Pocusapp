import 'dart:async';
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
  // Stored once per asset ID. Never recreated on stream updates — prevents
  // FutureBuilder from resetting to ConnectionState.waiting on each rebuild.
  final Map<String, Future<String?>> _pathFutures = {};

  Future<String?> _pathFor(MediaAsset asset) {
    return _pathFutures[asset.id] ??= ref
        .read(pocusRepositoryProvider)
        .resolveLocalPath(asset)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
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
                'Nenhum vídeo vinculado a este item.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return FutureBuilder<String?>(
            future: _pathFor(videoAssets.first),
            builder: (context, snapshot) {
              // Spinner SOMENTE enquanto o Future está em andamento.
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

              // ConnectionState.done — sai do spinner independentemente do resultado.
              final localPath = snapshot.data;
              if (snapshot.hasError || localPath == null || localPath.isEmpty) {
                return const Center(
                  child: Text(
                    'Erro: Vídeo não pôde ser carregado.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return LocalVideoPlayer(localPath: localPath);
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class LocalVideoPlayer extends StatefulWidget {
  const LocalVideoPlayer({super.key, required this.localPath});
  final String localPath;

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.localPath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;

    if (!exists || size == 0) {
      if (mounted) setState(() => _error = 'Arquivo de vídeo inválido ou vazio.');
      return;
    }

    try {
      final controller = VideoPlayerController.file(file);

      // Timeout no initialize() evita que o ExoPlayer trave silenciosamente
      // em arquivos corrompidos (sem exception, sem completar o Future).
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'VideoPlayerController.initialize() excedeu 15s.',
        ),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      // Atribuído via setState imediatamente após initialize() para que
      // build() use _controller.value.isInitialized como fonte de verdade.
      setState(() => _controller = controller);

      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
    } on TimeoutException {
      if (mounted) setState(() => _error = 'Tempo limite ao carregar o vídeo.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao reproduzir o vídeo.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Spinner baseado em _controller.value.isInitialized — fonte de verdade
    // do VideoPlayerController, não de um bool interno separado.
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
