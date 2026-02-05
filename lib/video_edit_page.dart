import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VideoEditPage extends StatefulWidget {
  const VideoEditPage({super.key, required this.videoFile});

  final File videoFile;

  @override
  State<VideoEditPage> createState() => _VideoEditPageState();
}

class _VideoEditPageState extends State<VideoEditPage> {
  Future<void> _exportVideoWithText({
    required double widgetWidth,
    required double widgetHeight,
  }) async {
    if (_overlayTexts.isEmpty) return;
    final inputPath = widget.videoFile.path;
    final dir = await getTemporaryDirectory();
    final outputPath = p.join(
      dir.path,
      'output_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    // Get video dimensions
    final videoPlayerController = VideoPlayerController.file(widget.videoFile);
    await videoPlayerController.initialize();
    final videoWidth = videoPlayerController.value.size.width;
    final videoHeight = videoPlayerController.value.size.height;
    videoPlayerController.dispose();

    // Build FFmpeg drawtext filters for each overlay, scaling positions
    // Use the custom font file
    final fontPath = p.absolute('assets/fonts/Roboto.ttf');
    final filters = _overlayTexts
        .map((overlay) {
          final safeText = overlay.text
              .replaceAll("'", "\\'")
              .replaceAll(':', '\\:');
          final scaleX = videoWidth / widgetWidth;
          final scaleY = videoHeight / widgetHeight;
          final x = (overlay.position.dx * scaleX).toInt();
          final y = (overlay.position.dy * scaleY).toInt();
          final fontSize = (overlay.fontSize * scaleY).toInt();
          return "drawtext=text='$safeText':fontfile='$fontPath':x=$x:y=$y:fontsize=$fontSize:fontcolor=white:borderw=2:bordercolor=black";
        })
        .join(',');

    final ffmpegCmd =
        "-i '$inputPath' -vf \"$filters\" -codec:a copy '$outputPath'";

    await FFmpegKit.execute(ffmpegCmd);

    await GallerySaver.saveVideo(outputPath);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to gallery!')));
    }
  }

  final Trimmer _trimmer = Trimmer();
  int? _videoDuration;
  List<OverlayText> _overlayTexts = [];
  void _showAddTextDialog() async {
    String tempText = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Text Overlay'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => tempText = value,
            decoration: InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _overlayTexts.add(OverlayText(text: tempText));
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    loadVideo();
    super.initState();
  }

  Future<void> loadVideo() async {
    await _trimmer.loadVideo(videoFile: widget.videoFile);
    final videoPlayerController = VideoPlayerController.file(widget.videoFile);
    await videoPlayerController.initialize();
    setState(() {
      _videoDuration = videoPlayerController.value.duration.inSeconds;
    });
    videoPlayerController.dispose();
  }

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    double? lastWidgetWidth;
    double? lastWidgetHeight;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Video Editor'),
        actionsPadding: EdgeInsets.only(right: 20),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (lastWidgetWidth != null && lastWidgetHeight != null) {
                _exportVideoWithText(
                  widgetWidth: lastWidgetWidth!,
                  widgetHeight: lastWidgetHeight!,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please interact with video area first!'),
                  ),
                );
              }
            },
            child: Text('Export'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(bottom: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  lastWidgetWidth = constraints.maxWidth;
                  lastWidgetHeight = constraints.maxHeight;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoViewer(trimmer: _trimmer),
                      if (_overlayTexts.isNotEmpty)
                        ..._overlayTexts.map((overlay) {
                          return Positioned(
                            left: overlay.position.dx,
                            top: overlay.position.dy,
                            child: DraggableText(
                              overlay: overlay,
                              parentSize: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              onUpdate: () => setState(() {}),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ),
          Center(
            child: TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 50.0,
              viewerWidth: MediaQuery.of(context).size.width,
              maxVideoLength: Duration(seconds: _videoDuration ?? 0),
              onChangeStart: (value) => _startValue = value,
              onChangeEnd: (value) => _endValue = value,
              onChangePlaybackState: (value) =>
                  setState(() => _isPlaying = value),
            ),
          ),

          Row(
            crossAxisAlignment: .center,
            mainAxisAlignment: .center,
            children: [
              TextButton(
                child: _isPlaying
                    ? Icon(Icons.pause, size: 80.0, color: Colors.white)
                    : Icon(Icons.play_arrow, size: 80.0, color: Colors.white),
                onPressed: () async {
                  bool playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() {
                    _isPlaying = playbackState;
                  });
                },
              ),
              FloatingActionButton(
                onPressed: _showAddTextDialog,
                tooltip: 'Add Text Overlay',
                child: const Icon(Icons.text_fields),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OverlayText {
  String text;
  Offset position;
  double fontSize;

  OverlayText({
    required this.text,
    this.position = const Offset(50, 50),
    this.fontSize = 24,
  });
}

class DraggableText extends StatefulWidget {
  final OverlayText overlay;
  final VoidCallback onUpdate;
  final Size parentSize;

  const DraggableText({
    super.key,
    required this.overlay,
    required this.onUpdate,
    required this.parentSize,
  });

  @override
  State<DraggableText> createState() => _DraggableTextState();
}

class _DraggableTextState extends State<DraggableText> {
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final renderBox =
            _textKey.currentContext?.findRenderObject() as RenderBox?;
        final textSize = renderBox?.size ?? Size.zero;

        double newX = widget.overlay.position.dx + details.delta.dx;
        double newY = widget.overlay.position.dy + details.delta.dy;

        // Clamp using parentSize (video/container size)
        newX = newX.clamp(0.0, widget.parentSize.width - textSize.width);
        newY = newY.clamp(0.0, widget.parentSize.height - textSize.height);

        setState(() {
          widget.overlay.position = Offset(newX, newY);
          widget.onUpdate();
        });
      },
      child: Text(
        key: _textKey,
        widget.overlay.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.overlay.fontSize,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}
