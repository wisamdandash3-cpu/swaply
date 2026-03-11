import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/complaint_service.dart';

/// شاشة إرسال شكوى: سبب + دليل صورة
class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({
    super.key,
    required this.reporterId,
    required this.reportedId,
    required this.displayName,
    this.contextType = 'profile',
  });

  final String reporterId;
  final String reportedId;
  final String displayName;
  final String contextType;

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final TextEditingController _reasonController = TextEditingController();
  File? _evidenceFile;
  bool _sending = false;

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
        SnackBar(content: Text(l10n.complaintReasonRequired), backgroundColor: Colors.red),
      );
      return;
    }
    if (_evidenceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.complaintEvidenceRequired), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _sending = true);
    final err = await ComplaintService().reportUser(
      reporterId: widget.reporterId,
      reportedId: widget.reportedId,
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
    if (ok) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSend = _reasonController.text.trim().isNotEmpty && _evidenceFile != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportAbuse),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reportConfirmMessage(widget.displayName),
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _sending || !canSend ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.hingePurple,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.sendReport),
            ),
          ],
        ),
      ),
    );
  }
}
