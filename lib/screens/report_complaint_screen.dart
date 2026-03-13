import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/complaint_service.dart';

/// شاشة إرسال شكوى: سبب + دليل صورة. تدعم شكوى ضد مستخدم أو شكوى عامة.
class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({
    super.key,
    required this.reporterId,
    this.reportedId,
    this.displayName,
    this.contextType = 'profile',
  });

  final String reporterId;
  final String? reportedId;
  final String? displayName;
  final String contextType;

  /// شكوى عامة (من نصائح المواعدة الآمنة أو الإعدادات): بدون مستخدم مشكو منه.
  static ReportComplaintScreen generalComplaint({required String reporterId}) {
    return ReportComplaintScreen(
      reporterId: reporterId,
      reportedId: null,
      displayName: null,
      contextType: 'general',
    );
  }

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final TextEditingController _reasonController = TextEditingController();
  File? _evidenceFile;
  bool _sending = false;
  List<ComplaintConversation> _conversations = [];
  bool _loadingConversations = true;
  String? _deletingId;

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() => _loadingConversations = true);
    final list = await ComplaintService().getMyComplaintConversations(
      widget.reporterId,
    );
    if (mounted) {
      setState(() {
        _conversations = list;
        _loadingConversations = false;
      });
    }
  }

  Future<void> _deleteConversation(ComplaintConversation conv) async {
    if (_deletingId != null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المحادثة'),
        content: const Text(
          'سيتم حذف الشكوى وكل الردود من التطبيق والقاعدة ولن تعود. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deletingId = conv.id);
    final err = await ComplaintService().deleteComplaintConversation(
      widget.reporterId,
      conv.id,
    );
    if (!mounted) return;
    setState(() => _deletingId = null);
    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }
    await _loadConversations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المحادثة'),
          backgroundColor: AppColors.forestGreen,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (xfile != null && mounted) {
      setState(() => _evidenceFile = File(xfile.path));
    }
  }

  Future<void> _send() async {
    final reason = _reasonController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.complaintReasonRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_evidenceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.complaintEvidenceRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    final bool isGeneral = widget.reportedId == null;
    final String? err = isGeneral
        ? await ComplaintService().reportGeneralComplaint(
            reporterId: widget.reporterId,
            reason: reason,
            context: widget.contextType,
            evidenceImage: _evidenceFile,
          )
        : await ComplaintService().reportUser(
            reporterId: widget.reporterId,
            reportedId: widget.reportedId!,
            reason: reason,
            context: widget.contextType,
            evidenceImage: _evidenceFile,
          );
    if (!mounted) return;
    setState(() => _sending = false);
    final ok = err == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.reportSent : err),
        backgroundColor: ok ? AppColors.forestGreen : Colors.red,
      ),
    );
    if (ok) {
      await _loadConversations();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isGeneralComplaint => widget.reportedId == null;

  Widget _buildConversationCard(ComplaintConversation conv) {
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat('d/M/y HH:mm', locale.languageCode);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(conv.createdAt),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              conv.reason,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.darkBlack,
                height: 1.4,
              ),
            ),
            if (conv.evidenceUrl != null && conv.evidenceUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  conv.evidenceUrl!,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 40),
                ),
              ),
            ],
            ...conv.replies.map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.forestGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رد الدعم',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.content,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.darkBlack,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(r.createdAt),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _deletingId == conv.id
                    ? null
                    : () => _deleteConversation(conv),
                icon: _deletingId == conv.id
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  _deletingId == conv.id ? 'جاري الحذف...' : 'حذف المحادثة',
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSend =
        _reasonController.text.trim().isNotEmpty && _evidenceFile != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isGeneralComplaint ? l10n.submitComplaint : l10n.reportAbuse,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'شكاوىي والردود',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingConversations)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'لا توجد محادثات بعد. أرسل شكوى أدناه.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ..._conversations.map((conv) => _buildConversationCard(conv)),
            const SizedBox(height: 24),
            Text(
              _isGeneralComplaint
                  ? l10n.submitComplaintDescription
                  : l10n.reportConfirmMessage(widget.displayName!),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.complaintReason,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.complaintReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.complaintEvidence,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlack,
              ),
            ),
            const SizedBox(height: 8),
            if (_evidenceFile != null)
              Stack(
                alignment: Alignment.topLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _evidenceFile!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _evidenceFile = null),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(l10n.complaintAddEvidence),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _sending || !canSend ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.hingePurple,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.sendReport),
            ),
          ],
        ),
      ),
    );
  }
}
