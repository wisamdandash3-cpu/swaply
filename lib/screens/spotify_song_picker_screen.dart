import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/spotify_search_service.dart';

/// شاشة اختيار أغنية من Spotify (بحث حي + نتائج + إمكانية لصق الرابط).
/// تُستدعى من قسم «أغنيتي المفضلة» وتعيد الرابط عند الحفظ.
class SpotifySongPickerScreen extends StatefulWidget {
  const SpotifySongPickerScreen({
    super.key,
    this.initialUrl,
  });

  final String? initialUrl;

  @override
  State<SpotifySongPickerScreen> createState() => _SpotifySongPickerScreenState();
}

class _SpotifySongPickerScreenState extends State<SpotifySongPickerScreen> {
  late TextEditingController _controller;
  Timer? _debounce;
  final SpotifySearchService _searchService = SpotifySearchService();
  List<SpotifyTrack> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _searchError = false;

  static const Duration _debounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl ?? '');
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(_debounceDuration, _performSearch);
  }

  Future<void> _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _hasSearched = true;
      _isSearching = true;
      _searchError = false;
    });
    try {
      final results = await _searchService.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _searchError = false;
      });
    } on SpotifySearchException catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
        _searchError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).searchError),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _onSelectTrack(SpotifyTrack track) {
    Navigator.pop(context, SpotifyTrackData(
      url: track.url,
      imageUrl: track.imageUrl,
      name: track.name,
      artist: track.artist,
    ));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDone() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    if (!url.toLowerCase().contains('spotify.com')) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.voiceSpotifyInvalidUrl),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context, SpotifyTrackData(url: url.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showResults = _hasSearched && !_isSearching;
    final showEmptyState = !_hasSearched || (_hasSearched && _results.isEmpty);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.mySong),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l10n.searchOnSpotify,
                  prefixIcon: const Icon(Icons.search, color: AppColors.darkBlack),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: showResults
                    ? _results.isEmpty
                        ? _buildEmptyResults(l10n, isError: _searchError)
                        : _buildResultsList(l10n)
                    : showEmptyState
                        ? _buildEmptyState(l10n)
                        : const SizedBox.shrink(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.spotify, size: 28, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'Spotify',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.pasteLinkHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.darkBlack.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.hingePurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.done),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.headphones,
          size: 120,
          color: AppColors.neonCoral.withValues(alpha: 0.9),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.whichSongLookingFor,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlack,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.songShownInProfile,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.darkBlack.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyResults(AppLocalizations l10n, {bool isError = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.search_off,
          size: 64,
          color: isError ? Colors.red.shade400 : AppColors.darkBlack.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          isError ? l10n.searchError : l10n.noResults,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkBlack.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(AppLocalizations l10n) {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final track = _results[index];
        return _TrackResultTile(
          track: track,
          onSelect: () => _onSelectTrack(track),
          selectLabel: l10n.select,
        );
      },
    );
  }
}

class _TrackResultTile extends StatelessWidget {
  const _TrackResultTile({
    required this.track,
    required this.onSelect,
    required this.selectLabel,
  });

  final SpotifyTrack track;
  final VoidCallback onSelect;
  final String selectLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              track.imageUrl ?? '',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade300,
                child: const Icon(Icons.music_note, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkBlack.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onSelect,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.hingePurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(selectLabel),
          ),
        ],
      ),
    );
  }
}
