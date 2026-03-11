import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// طبقة فيديو الوردة: عرض كامل 9:16، تشغيل مرة واحدة، خلفية شفافة.
/// تُعرض عند استلام هدية الوردة.
class RoseVideoOverlay extends StatefulWidget {
  const RoseVideoOverlay({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  static void show(BuildContext context, {required VoidCallback onComplete}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => RoseVideoOverlay(
        onComplete: () {
          Navigator.of(context, rootNavigator: true).pop();
          onComplete();
        },
      ),
    );
  }

  @override
  State<RoseVideoOverlay> createState() => _RoseVideoOverlayState();
}

class _RoseVideoOverlayState extends State<RoseVideoOverlay> {
  late VideoPlayerController _controller;
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/0309_1.mp4')
      ..setLooping(false)
      ..setVolume(1.0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _addCompletionListener();
        }
      }).catchError((_) {
        if (mounted) widget.onComplete();
      });
  }

  void _addCompletionListener() {
    if (_listenerAdded) return;
    _listenerAdded = true;
    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (!mounted || !_controller.value.isInitialized) return;
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      _controller.removeListener(_onVideoUpdate);
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => widget.onComplete(),
        behavior: HitTestBehavior.opaque,
        child: _controller.value.isInitialized
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final videoH = w * 16 / 9;
                  final videoW = h * 9 / 16;
                  final width = videoH <= h ? w : videoW;
                  final height = videoH <= h ? videoH : h;
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: VideoPlayer(_controller),
                    ),
                  );
                },
              )
            : SizedBox.expand(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.pink.shade300,
                  ),
                ),
              ),
      ),
    );
  }
}
