part of 'admin_approvals_view.dart';

extension _AdminApprovalsViewContentPart on _AdminApprovalsViewState {
  Widget _buildBody(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'admin.approvals.title'.tr),
          Expanded(
            child: FutureBuilder<bool>(
              future: _canAccessFuture,
              builder: (context, accessSnap) {
                if (accessSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (accessSnap.data != true) {
                  return _buildNoAccessState();
                }
                return FutureBuilder<bool>(
                  future: _isPrimaryAdminFuture,
                  builder: (context, primarySnap) {
                    final isPrimaryAdmin = primarySnap.data == true;
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _approvalRepository.watchApprovals(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snap.data?.docs ?? const [];
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ApprovalCard(
                                doc: docs[index],
                                isPrimaryAdmin: isPrimaryAdmin,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'admin.no_access'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'admin.approvals.empty'.tr,
        style: const TextStyle(
          fontFamily: 'MontserratMedium',
          fontSize: 13,
        ),
      ),
    );
  }
}

extension _AdminApprovalsCardContentPart on _ApprovalCardState {
  Widget _buildCardContent() {
    final data = widget.doc.data();
    final title = (data['title'] ?? '').toString().trim();
    final summary = (data['summary'] ?? '').toString().trim();
    final status = (data['status'] ?? 'pending').toString().trim();
    final targetNickname = (data['targetNickname'] ?? '').toString().trim();
    final createdByNickname =
        (data['createdByNickname'] ?? '').toString().trim();
    final createdAt = _formatTimestamp(data['createdAt']);
    final rejectionReason = (data['rejectionReason'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? 'admin.approvals.default_title'.tr : title,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            targetNickname.isEmpty ? summary : '@$targetNickname • $summary',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${'admin.approvals.created_by'.tr}: ${createdByNickname.isEmpty ? '-' : '@$createdByNickname'}${createdAt == null ? '' : ' • $createdAt'}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          if (rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${'admin.approvals.rejection_reason'.tr}: $rejectionReason',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
          ],
          if (status == 'pending' && widget.isPrimaryAdmin) ...[
            const SizedBox(height: 12),
            _buildApprovalActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _processing ? null : _approve,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'admin.approvals.approve'.tr,
                    style: const TextStyle(fontFamily: 'MontserratBold'),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _processing ? null : _reject,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'admin.approvals.reject'.tr,
              style: const TextStyle(fontFamily: 'MontserratBold'),
            ),
          ),
        ),
      ],
    );
  }
}
