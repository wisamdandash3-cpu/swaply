import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_colors.dart';
import '../services/spotify_search_service.dart';

/// شاشة تشغيل أغنية Spotify داخل التطبيق عبر WebView.
class SpotifyEmbedScreen extends StatelessWidget {
  const SpotifyEmbedScreen({
    super.key,
    required this.spotifyUrl,
    this.title,
    this.artist,
  });

  final String spotifyUrl;
  final String? title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final trackId = SpotifyTrackData.extractTrackId(spotifyUrl);
    final embedUrl = trackId != null
        ? 'https://open.spotify.com/embed/track/$trackId'
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title ?? 'Spotify'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: embedUrl != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (artist != null && artist!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        artist!,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.darkBlack.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: WebViewWidget(
                      controller: WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..loadRequest(Uri.parse(embedUrl)),
                    ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'رابط Spotify غير صالح',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkBlack.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
