import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/support_message_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

class SupportAdminView extends StatefulWidget {
  const SupportAdminView({super.key});

  @override
  State<SupportAdminView> createState() => _SupportAdminViewState();
}

class _SupportAdminViewState extends State<SupportAdminView> {
  final SupportMessageRepository _repository =
      SupportMessageRepository.ensure();
  late final Future<bool> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = AdminAccessService.canAccessTask('support');
  }

  Future<void> _updateStatus(
    String docId, {
    required String status,
    String currentNote = '',
  }) async {
    final TextEditingController noteController =
        TextEditingController(text: currentNote);
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(status == 'closed' ? 'Mesajı Kapat' : 'Mesajı Yanıtla'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: noteController,
            maxLines: 4,
            placeholder: 'Admin notu',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      noteController.dispose();
      return;
    }
    try {
      await _repository.setStatus(
        docId: docId,
        status: status,
        adminNote: noteController.text,
      );
      AppSnackbar('Güncellendi', 'Destek mesajı güncellendi.');
    } catch (e) {
      AppSnackbar('Hata', 'İşlem tamamlanamadı: $e');
    } finally {
      noteController.dispose();
    }
  }

  String _statusLabel(String status) {
    switch (status.trim()) {
      case 'answered':
        return 'Yanıtlandı';
      case 'closed':
        return 'Kapatıldı';
      default:
        return 'Açık';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim()) {
      case 'answered':
        return const Color(0xFF2E7D32);
      case 'closed':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF996800);
    }
  }

  Color _statusBg(String status) {
    switch (status.trim()) {
      case 'answered':
        return const Color(0xFFE8F7E9);
      case 'closed':
        return const Color(0xFFF0F0F0);
      default:
        return const Color(0xFFFFF3D8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, accessSnap) {
        if (accessSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          );
        }
        if (accessSnap.data != true) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  BackButtons(text: 'Kullanıcı Destek'),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Bu ekrana erişim iznin yok.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                BackButtons(text: 'Kullanıcı Destek'),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _repository.watchInbox(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      }
                      final docs = snapshot.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz destek mesajı yok.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final status = (data['status'] ?? 'open').toString();
                          final adminNote =
                              (data['adminNote'] ?? '').toString();
                          final nickname = (data['nickname'] ?? '').toString();
                          final displayName =
                              (data['displayName'] ?? '').toString();
                          final email = (data['email'] ?? '').toString();
                          final userId = (data['userId'] ?? '').toString();
                          final createdAt = data['createdAt'];
                          final createdText = createdAt is Timestamp
                              ? _formatDate(createdAt.toDate())
                              : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F6F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: userId.trim().isEmpty
                                            ? null
                                            : () => Get.to(
                                                  () => SocialProfile(
                                                    userID: userId,
                                                  ),
                                                ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nickname.trim().isEmpty
                                                  ? '@-'
                                                  : '@$nickname',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontFamily:
                                                    'MontserratSemiBold',
                                              ),
                                            ),
                                            if (displayName.trim().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                    fontFamily:
                                                        'MontserratMedium',
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusBg(status),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontSize: 12,
                                          fontFamily: 'MontserratSemiBold',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (email.trim().isNotEmpty)
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                if (createdText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    createdText,
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  (data['message'] ?? '').toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontFamily: 'MontserratMedium',
                                    height: 1.35,
                                  ),
                                ),
                                if (adminNote.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Text(
                                      adminNote,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontFamily: 'MontserratMedium',
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateStatus(
                                          doc.id,
                                          status: 'answered',
                                          currentNote: adminNote,
                                        ),
                                        child: const Text('Yanıtlandı'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(
                                          doc.id,
                                          status: 'closed',
                                          currentNote: adminNote,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Kapat'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
