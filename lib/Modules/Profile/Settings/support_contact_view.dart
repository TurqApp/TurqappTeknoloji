import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/support_message_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class SupportContactView extends StatefulWidget {
  const SupportContactView({super.key});

  @override
  State<SupportContactView> createState() => _SupportContactViewState();
}

class _SupportContactViewState extends State<SupportContactView> {
  final TextEditingController _messageController = TextEditingController();
  final SupportMessageRepository _repository =
      SupportMessageRepository.ensure();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      AppSnackbar('Eksik Bilgilendirme', 'Lutfen bir mesaj yaz.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _repository.createMessage(message: message);
      _messageController.clear();
      AppSnackbar('Gonderildi', 'Mesajin admin destek kuyruğuna düştü.');
    } catch (e) {
      AppSnackbar('Hata', 'Mesaj gonderilemedi: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
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

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'Bize Yazın'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destek Mesajı',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'MontserratSemiBold',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mesajin doğrudan admin destek kuyruğuna düşer.',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _messageController,
                          maxLines: 7,
                          minLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Sorununu veya talebini yaz...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.black12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Colors.black54),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sending ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _sending
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Mesajı Gönder',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'MontserratSemiBold',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Geçmiş Mesajların',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontFamily: 'MontserratSemiBold',
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _repository.watchOwnMessages(currentUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      }
                      final docs = [...(snapshot.data?.docs ?? const [])]
                        ..sort((a, b) {
                          final aTs = a.data()['createdAt'];
                          final bTs = b.data()['createdAt'];
                          final aMs =
                              aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
                          final bMs =
                              bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
                          return bMs.compareTo(aMs);
                        });
                      if (docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: const Text(
                            'Henüz destek mesajın yok.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final status = (data['status'] ?? 'open').toString();
                          final adminNote =
                              (data['adminNote'] ?? '').toString();
                          final createdAt = data['createdAt'];
                          final createdText = createdAt is Timestamp
                              ? _formatDate(createdAt.toDate())
                              : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                      child: Text(
                                        createdText,
                                        style: const TextStyle(
                                          color: Colors.black45,
                                          fontSize: 12,
                                          fontFamily: 'MontserratMedium',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: status == 'open'
                                            ? const Color(0xFFFFF3D8)
                                            : const Color(0xFFE8F7E9),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: status == 'open'
                                              ? const Color(0xFF996800)
                                              : const Color(0xFF2E7D32),
                                          fontSize: 12,
                                          fontFamily: 'MontserratSemiBold',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
