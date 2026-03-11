import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/block_service.dart';
import '../widgets/verified_badge.dart';

/// شاشة قائمة الحظر: عرض المحظورين أو حالة فارغة مع CTA للنجمة المميزون.
class BlockListScreen extends StatefulWidget {
  const BlockListScreen({
    super.key,
  });

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  final BlockService _blockService = BlockService();

  List<({String id, String name, String? avatarUrl, bool isVerified})> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await _blockService.getBlockedList(userId);
    if (mounted) {
      setState(() {
        _blocked = list;
        _loading = false;
      });
    }
  }

  Future<void> _unblock(String blockedId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final ok = await _blockService.unblock(userId, blockedId);
    if (mounted) {
      if (ok) {
        setState(() => _blocked = _blocked.where((b) => b.id != blockedId).toList());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).unblock),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onGoToFeatured() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.blockList,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.hingePurple))
          : _blocked.isEmpty
              ? _buildEmptyState(l10n)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _blocked.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.darkBlack.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, i) {
                    final b = _blocked[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.hingePurple.withValues(alpha: 0.2),
                        backgroundImage: b.avatarUrl != null && b.avatarUrl!.isNotEmpty
                            ? NetworkImage(b.avatarUrl!)
                            : null,
                        child: b.avatarUrl == null || b.avatarUrl!.isEmpty
                            ? Text(
                                b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                style: GoogleFonts.montserrat(
                                  color: AppColors.hingePurple,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (b.isVerified) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 18),
                          ],
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: () => _unblock(b.id),
                        child: Text(
                          l10n.unblock,
                          style: const TextStyle(
                            color: AppColors.hingePurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.hingePurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_outlined,
                  size: 64,
                  color: AppColors.hingePurple.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.blockListEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.blockListEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.darkBlack.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _FeaturedCard(
                title: l10n.goToFeaturedTab,
                subtitle: l10n.goToFeaturedDesc,
                onTap: _onGoToFeatured,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.hingePurple.withValues(alpha: 0.12),
                AppColors.rosePink.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.hingePurple.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.hingePurple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.hingePurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.hingePurple.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
