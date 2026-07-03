import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/session/account_scoped_state.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  String? _navigatingUserId;

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

  Future<void> _openUserDestination(AdminUserListItem item) async {
    if (_navigatingUserId != null) return;
    setState(() => _navigatingUserId = item.userId);

    try {
      final destination = item.isDoctorUser
          ? '/admin/home/doctors/by-user/${item.userId}'
          : '/admin/home/users/${item.userId}';

      await context.push(destination);
    } finally {
      if (mounted) {
        setState(() => _navigatingUserId = null);
      }
    }
  }

  Future<void> _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    await prepareAppForUnauthenticatedSession(ref);
    if (!mounted) return;
    AppToast.success(context, 'Berhasil keluar dari akun admin');
    context.go('/login');
    scheduleAppSessionScopeReset();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Konfirmasi Keluar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Apakah Anda yakin ingin keluar dari akun admin ini?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ya, Keluar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      await _onLogout();
    }
  }

  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersNotifierProvider);
    final showOfflinePage = _isNetworkError(state.errorCause) &&
        state.items.isEmpty &&
        !state.isLoading;
    final showOfflineBanner =
        _isNetworkError(state.errorCause) && state.items.isNotEmpty;

    return AdminShellScaffold(
      title: 'Kelola Pengguna',
      subtitle: '${state.totalItems} akun terdeteksi',
      currentSection: AdminShellSection.users,
      onBackPressed: () => context.pop(),
      onHomeTap: () => context.pushReplacement('/admin/home'),
      onUsersTap: () {},
      onLogoutTap: _confirmLogout,
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
            if (state.isLoading && state.items.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  color: AdminPalette.accent,
                  backgroundColor: Color(0xFFF8FAFC),
                ),
              ),
            ] else if (showOfflineBanner) ...[
              NoConnectionState.compact(
                title: 'Koneksi terputus',
                message:
                    'Daftar pengguna terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
                onRetry: () => ref
                    .read(adminUsersNotifierProvider.notifier)
                    .refreshUsers(),
              ),
              const SizedBox(height: 16),
            ],
            if (state.isLoading && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(
                  child: CircularProgressIndicator(color: AdminPalette.accent),
                ),
              )
            else if (showOfflinePage)
              NoConnectionState.card(
                title: 'Daftar pengguna belum bisa dimuat',
                message:
                    'Kami belum bisa mengambil daftar pengguna karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                onRetry: () =>
                    ref.read(adminUsersNotifierProvider.notifier).loadUsers(),
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
                  child: _AdminUserListCard(
                    item: item,
                    isNavigating: _navigatingUserId == item.userId,
                    onTap: () => _openUserDestination(item),
                  ),
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
        style: const TextStyle(color: Color(0xFF94A3B8)),
        overflow: TextOverflow.ellipsis,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            hint,
            style: const TextStyle(color: Color(0xFF94A3B8)),
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
    required this.onTap,
    this.isNavigating = false,
  });

  final AdminUserListItem item;
  final VoidCallback onTap;
  final bool isNavigating;

  @override
  Widget build(BuildContext context) {
    final hasUsername = item.username.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: isNavigating ? null : onTap,
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
            isNavigating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AdminPalette.accent,
                    ),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
          ],
        ),
      ),
    );
  }
}
