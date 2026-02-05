import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_editing_app/video_edit_page.dart';

class VideoHomePage extends StatefulWidget {
  const VideoHomePage({super.key});

  @override
  State<VideoHomePage> createState() => _VideoHomePageState();
}

class _VideoHomePageState extends State<VideoHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Column(
        spacing: 20,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Placeholder(),
          ),

          ElevatedButton(
            onPressed: () async {
              final videoFile = await FilePicker.platform.pickFiles(
                type: FileType.video,
                allowMultiple: false,
              );
              if (videoFile != null && context.mounted) {
                File file = File(videoFile.files.single.path!);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return VideoEditPage(videoFile: file);
                    },
                  ),
                );
              }
            },
            child: Text('Select Video'),
          ),
        ],
      ),
    );
  }
}
