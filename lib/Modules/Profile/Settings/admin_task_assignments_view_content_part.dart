part of 'admin_task_assignments_view.dart';

extension _AdminTaskAssignmentsViewContentPart
    on _AdminTaskAssignmentsViewState {
  Widget _buildEditorCard() {
    final selectedNickname =
        (_selectedUser?['nickname'] ?? '').toString().trim();
    final selectedDisplayName =
        (_selectedUser?['displayName'] ?? '').toString().trim();
    final selectedRozet = (_selectedUser?['rozet'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.tasks.editor_title'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin.tasks.editor_help'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nicknameController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadUser(),
                  style: const TextStyle(
                    fontFamily: 'MontserratMedium',
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'admin.tasks.username'.tr,
                    hintText: 'admin.tasks.username_hint'.tr,
                    labelStyle: const TextStyle(
                      fontFamily: 'MontserratMedium',
                    ),
                    prefixIcon: const Icon(Icons.alternate_email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _searching ? null : _loadUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'admin.tasks.load'.tr,
                          style: const TextStyle(fontFamily: 'MontserratBold'),
                        ),
                ),
              ),
            ],
          ),
          if (_selectedUser != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CachedUserAvatar(
                      imageUrl:
                          (_selectedUser?['avatarUrl'] ?? '').toString().trim(),
                      radius: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDisplayName.isNotEmpty
                              ? selectedDisplayName
                              : '@$selectedNickname',
                          style: const TextStyle(
                            fontFamily: 'MontserratBold',
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '@$selectedNickname',
                              style: const TextStyle(
                                fontFamily: 'MontserratMedium',
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            if (selectedRozet.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  selectedRozet,
                                  style: const TextStyle(
                                    fontFamily: 'MontserratBold',
                                    fontSize: 11,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'admin.tasks.task_list'.tr,
              style: const TextStyle(
                fontFamily: 'MontserratBold',
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ...adminTaskCatalog.map(_buildTaskTile),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveTasks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.task_alt),
                      label: Text(
                        _saving
                            ? 'admin.tasks.saving'.tr
                            : 'admin.tasks.save'.tr,
                        style: const TextStyle(fontFamily: 'MontserratBold'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _clearing ? null : _clearTasks,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _clearing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'admin.tasks.clear'.tr,
                            style: const TextStyle(
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskTile(AdminTaskDefinition task) {
    final selected = _selectedTaskIds.contains(task.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.black : Colors.black12,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) {
          _updateViewState(() {
            if (value == true) {
              if (!_selectedTaskIds.contains(task.id)) {
                _selectedTaskIds = <String>[..._selectedTaskIds, task.id];
              }
            } else {
              _selectedTaskIds = _selectedTaskIds
                  .where((element) => element != task.id)
                  .toList(growable: false);
            }
          });
        },
        activeColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Row(
          children: [
            Icon(task.icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.titleKey.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          task.descriptionKey.tr,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 11,
            color: Colors.black54,
            height: 1.35,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.tasks.assignments'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin.tasks.assignments_help'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _assignmentRepository.watchAssignments(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const AppStateView.loading(
                  padding: EdgeInsets.symmetric(vertical: 20),
                );
              }
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'admin.tasks.no_assignments'.tr,
                    style: const TextStyle(
                      fontFamily: 'MontserratMedium',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                );
              }
              return Column(
                children: docs
                    .map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AssignmentCard(
                          data: doc.data(),
                          onTap: () => _selectAssignment(doc.data()),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.data,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nickname = (data['nickname'] ?? '').toString().trim();
    final displayName = (data['displayName'] ?? '').toString().trim();
    final avatarUrl = (data['avatarUrl'] ?? '').toString().trim();
    final rozet = (data['rozet'] ?? '').toString().trim();
    final updatedAt = _formatTimestamp(data['updatedAt']);
    final taskIds = normalizeAdminTaskIds(
      data['taskIds'] is List ? data['taskIds'] as List : const [],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CachedUserAvatar(
                imageUrl: avatarUrl,
                radius: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName.isNotEmpty ? displayName : '@$nickname',
                          style: const TextStyle(
                            fontFamily: 'MontserratBold',
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (rozet.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            rozet,
                            style: const TextStyle(
                              fontFamily: 'MontserratBold',
                              fontSize: 11,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$nickname',
                    style: const TextStyle(
                      fontFamily: 'MontserratMedium',
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${'admin.tasks.updated_at'.tr}: $updatedAt',
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: taskIds
                        .map(
                          (id) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              ((adminTaskCatalogById[id]?.titleKey ?? '')
                                      .isNotEmpty)
                                  ? adminTaskCatalogById[id]!.titleKey.tr
                                  : id,
                              style: const TextStyle(
                                fontFamily: 'MontserratBold',
                                fontSize: 11,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatTimestamp(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is int) {
      date = DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (date == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
