import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(adminUsersNotifierProvider);
      if (state.items.isEmpty && !state.isLoading) {
        ref.read(adminUsersNotifierProvider.notifier).loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(adminUsersNotifierProvider.notifier).loadNextPage();
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(adminUsersNotifierProvider.notifier).loadUsers(
            page: 1,
            query: value.trim(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersNotifierProvider);

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: CustomAppBar(
        title: 'Kelola Pengguna',
        subtitle: '${state.totalItems} akun terdeteksi',
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: AdminPalette.accent,
        backgroundColor: Colors.white,
        onRefresh: () =>
            ref.read(adminUsersNotifierProvider.notifier).refreshUsers(),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            TextField(
              controller: _searchController,
              onChanged: _handleSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama, username, atau email',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AdminPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AdminPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AdminPalette.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                final roleFilter = _UsersFilterDropdown(
                  label: 'Role',
                  value: state.role,
                  hint: 'Semua role',
                  items: AdminManagedRoles.all
                      .map(
                        (role) => DropdownMenuItem<String?>(
                          value: role,
                          child: Text(
                            adminRoleLabel(role),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    ref.read(adminUsersNotifierProvider.notifier).loadUsers(
                          page: 1,
                          role: value,
                        );
                  },
                );

                final statusFilter = _UsersFilterDropdown(
                  label: 'Status',
                  value: state.accountStatus,
                  hint: 'Semua status',
                  items: AdminAccountStatuses.userFilterOptions
                      .map(
                        (status) => DropdownMenuItem<String?>(
                          value: status,
                          child: Text(
                            adminStatusStyle(status).label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    ref.read(adminUsersNotifierProvider.notifier).loadUsers(
                          page: 1,
                          accountStatus: value,
                        );
                  },
                );

                if (isCompact) {
                  return Column(
                    children: [
                      roleFilter,
                      const SizedBox(height: 12),
                      statusFilter,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: roleFilter),
                    const SizedBox(width: 12),
                    Expanded(child: statusFilter),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(
                  child: CircularProgressIndicator(color: AdminPalette.accent),
                ),
              )
            else if (state.error != null && state.items.isEmpty)
              AdminMessageCard(
                icon: Icons.error_outline_rounded,
                title: 'Daftar pengguna gagal dimuat',
                description: state.error!,
                actionLabel: 'Coba Lagi',
                onActionTap: () =>
                    ref.read(adminUsersNotifierProvider.notifier).loadUsers(),
              )
            else if (state.items.isEmpty)
              const AdminMessageCard(
                icon: Icons.people_outline_rounded,
                title: 'Tidak ada pengguna',
                description:
                    'Belum ada akun yang cocok dengan pencarian dan filter saat ini.',
              )
            else
              ...state.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdminUserListCard(item: item),
                ),
              ),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AdminPalette.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UsersFilterDropdown extends StatelessWidget {
  const _UsersFilterDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      value: value,
      hint: Text(
        hint,
        overflow: TextOverflow.ellipsis,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            hint,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...items,
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AdminPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AdminPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AdminPalette.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _AdminUserListCard extends StatelessWidget {
  const _AdminUserListCard({
    required this.item,
  });

  final AdminUserListItem item;

  @override
  Widget build(BuildContext context) {
    final hasUsername = item.username.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/admin/home/users/${item.userId}'),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AdminPalette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminAvatar(
              name: item.fullName,
              photoUrl: item.avatarPhoto,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    style: const TextStyle(
                      color: AdminPalette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.email,
                    style: const TextStyle(
                      color: AdminPalette.subtext,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasUsername) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${item.username}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final role in item.roles) AdminRoleChip(role: role),
                      AdminStatusChip(status: item.accountStatus),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dibuat ${formatAdminDateTime(item.createdAt)}',
                    style: const TextStyle(
                      color: AdminPalette.subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terakhir diperbarui ${formatAdminDateTime(item.updatedAt)}',
                    style: const TextStyle(
                      color: AdminPalette.subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
