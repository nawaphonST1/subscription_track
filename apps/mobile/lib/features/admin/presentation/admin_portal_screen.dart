import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/core/widgets/confirmation_dialog.dart';
import 'package:subscription_track/features/admin/application/admin_controller.dart';
import 'package:subscription_track/features/admin/domain/admin_package.dart';
import 'package:subscription_track/features/admin/domain/admin_user.dart';
import 'package:subscription_track/features/admin/domain/admin_user_detail.dart';

class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _adminEmailController =
      TextEditingController(text: 'admin@subtracker.com');
  final TextEditingController _adminPasswordController =
      TextEditingController(text: 'AdminPassword123!');
  bool _obscurePassword = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final notifier = ref.read(adminControllerProvider.notifier);

    // แจ้งเตือนเมื่อเกิดข้อผิดพลาดหรือสำเร็จ
    ref.listen<AdminState>(adminControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      } else if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    });

    final filteredUsers = state.users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (u.name ?? '').toLowerCase();
      final email = u.email.toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();

    if (state.isLoading && !state.isAdminAuthenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1D),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
          ),
        ),
      );
    }

    if (!state.isAdminAuthenticated) {
      return _buildAdminLoginScaffold(context, state, notifier);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131C2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF3B82F6), size: 24),
            SizedBox(width: 8),
            Text(
              'จัดการระบบ (Admin)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: state.isLoading ? null : () => notifier.loadAll(),
            tooltip: 'รีเฟรชข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            onPressed: state.isLoading ? null : () => notifier.logoutAdmin(),
            tooltip: 'ออกจากระบบแอดมิน',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'สถิติ & สมาชิก'),
            Tab(icon: Icon(Icons.widgets_rounded), text: 'บริการ & แพ็กเกจ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: สถิติ & รายชื่อสมาชิก
          _buildStatsAndUsersTab(state, filteredUsers, notifier),

          // Tab 2: จัดการบริการ & แพ็กเกจ
          _buildPackagesTab(state, notifier),
        ],
      ),
    );
  }

  Widget _buildStatsAndUsersTab(
    AdminState state,
    List<AdminUser> users,
    AdminController notifier,
  ) {
    return RefreshIndicator(
      onRefresh: notifier.loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview metric cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'ผู้ใช้ทั้งหมด',
                  value: '${state.stats.totalUsers}',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Subscriptions',
                  value: '${state.stats.totalSubscriptions}',
                  icon: Icons.auto_mode_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12, height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'บัตรในระบบ',
                  value: '${state.stats.totalCards}',
                  icon: Icons.credit_card_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'บริการกลาง',
                  value: '${state.stats.totalPackages}',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User list section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รายชื่อผู้ใช้ในระบบ (${users.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ค้นหาด้วยชื่อ หรืออีเมล...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF131C2E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF243049)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF243049)),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 16),

          if (users.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withAlpha(50)),
                    const SizedBox(height: 8),
                    const Text(
                      'ไม่พบรายชื่อผู้ใช้ที่ตรงกับคำค้นหา',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...users.map((user) => _buildUserCard(user, notifier)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF243049)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUser user, AdminController notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF243049)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showUserDetailSheet(context, user, notifier),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6).withAlpha(40),
                  child: Text(
                    (user.name?.isNotEmpty ?? false)
                        ? user.name![0].toUpperCase()
                        : user.email[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name?.isNotEmpty ?? false ? user.name! : 'ไม่ระบุชื่อ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildBadge(
                            '${user.subscriptionsCount} subs',
                            const Color(0xFF10B981),
                          ),
                          _buildBadge(
                            '${user.cardsCount} cards',
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFF3B82F6), size: 20),
                  onPressed: () => _showUserDetailSheet(context, user, notifier),
                  tooltip: 'จัดการและแก้ไขข้อมูลผู้ใช้',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  onPressed: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context: context,
                      title: 'ยืนยันการลบผู้ใช้',
                      message: 'ต้องการลบผู้ใช้ ${user.email} หรือไม่? ข้อมูลที่เกี่ยวข้องทั้งหมดจะถูกลบ',
                      confirmText: 'ลบผู้ใช้',
                      cancelText: 'ยกเลิก',
                      isDanger: true,
                    );
                    if (confirmed) {
                      await notifier.deleteUser(user.id);
                    }
                  },
                  tooltip: 'ลบผู้ใช้',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetailSheet(
    BuildContext context,
    AdminUser user,
    AdminController notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _AdminUserDetailView(
        userId: user.id,
        userEmail: user.email,
        userName: user.name,
        notifier: notifier,
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPackagesTab(AdminState state, AdminController notifier) {
    return RefreshIndicator(
      onRefresh: notifier.loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'บริการกลางในระบบ (${state.packages.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPackageSheet(context, notifier),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('เพิ่มบริการใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.packages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withAlpha(50)),
                    const SizedBox(height: 8),
                    const Text(
                      'ยังไม่มีบริการในระบบ กดปุ่ม "เพิ่มบริการใหม่" เพื่อเริ่มต้น',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.packages.map((pkg) => _buildPackageCard(pkg, notifier)),
        ],
      ),
    );
  }

  Widget _buildPackageCard(AdminPackage pkg, AdminController notifier) {
    Color cardBrandColor = const Color(0xFF3B82F6);
    try {
      final hex = pkg.brandColor.replaceAll('#', '');
      cardBrandColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pkg.isActive ? const Color(0xFF243049) : const Color(0xFFEF4444).withAlpha(80),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardBrandColor.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBrandColor.withAlpha(100)),
            ),
            child: Center(
              child: Text(
                pkg.name.isNotEmpty ? pkg.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: cardBrandColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: TextStyle(
                    color: pkg.isActive ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: pkg.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
              if (!pkg.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ปิดใช้งาน',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 10),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${pkg.category} • ฿${pkg.defaultPrice.toStringAsFixed(0)}/${pkg.billingCycle == 'YEARLY' ? 'ปี' : 'เดือน'}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
          onTap: () => _showEditPackageSheet(context, pkg, notifier),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 20),
                onPressed: () => _showEditPackageSheet(context, pkg, notifier),
                tooltip: 'แก้ไขบริการ',
              ),
              // Switch toggle
              Switch(
                value: pkg.isActive,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (val) => notifier.togglePackageActive(pkg.id, val),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context: context,
                    title: 'ยืนยันการลบบริการ',
                    message: 'ต้องการลบบริการ ${pkg.name} ออกจากระบบอย่างถาวรหรือไม่?',
                    confirmText: 'ลบบริการ',
                    cancelText: 'ยกเลิก',
                    isDanger: true,
                  );
                  if (confirmed) {
                    await notifier.deletePackage(pkg.id);
                  }
                },
                tooltip: 'ลบบริการ',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPackageSheet(
    BuildContext context,
    AdminPackage pkg,
    AdminController notifier,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: pkg.name);
    final categoryCtrl = TextEditingController(text: pkg.category);
    final priceCtrl = TextEditingController(text: pkg.defaultPrice.toStringAsFixed(0));
    final brandColorCtrl = TextEditingController(text: pkg.brandColor);
    final descCtrl = TextEditingController(text: pkg.description ?? '');
    String billingCycle = pkg.billingCycle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'แก้ไขบริการ / แพ็กเกจกลาง',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ชื่อบริการ (เช่น Netflix, Spotify, ChatGPT)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุชื่อบริการ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'หมวดหมู่ (เช่น Entertainment, Music, Productivity)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุหมวดหมู่' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ราคาปกติ (บาท)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณาระบุราคา';
                    if (double.tryParse(v) == null) return 'กรุณาระบุตัวเลขที่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: billingCycle,
                  dropdownColor: const Color(0xFF131C2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'รอบบิล',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MONTHLY', child: Text('รายเดือน (MONTHLY)')),
                    DropdownMenuItem(value: 'YEARLY', child: Text('รายปี (YEARLY)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => billingCycle = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: brandColorCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'สีแบรนด์ (HEX เช่น #E50914, #1DB954)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียด / หมายเหตุบริการ (ไม่บังคับ)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final success = await notifier.updatePackage(
                        pkg.id,
                        name: nameCtrl.text.trim(),
                        category: categoryCtrl.text.trim(),
                        defaultPrice: double.parse(priceCtrl.text.trim()),
                        billingCycle: billingCycle,
                        brandColor: brandColorCtrl.text.trim().isNotEmpty
                            ? brandColorCtrl.text.trim()
                            : '#3B82F6',
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                      );
                      if (success && ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('บันทึกการแก้ไข', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPackageSheet(BuildContext context, AdminController notifier) {

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Entertainment');
    final priceCtrl = TextEditingController();
    final brandColorCtrl = TextEditingController(text: '#3B82F6');
    String billingCycle = 'MONTHLY';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'เพิ่มบริการ / แพ็กเกจใหม่',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ชื่อบริการ (เช่น Netflix, Spotify, ChatGPT)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุชื่อบริการ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'หมวดหมู่ (เช่น Entertainment, Music, Productivity)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุหมวดหมู่' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ราคาปกติ (บาท)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณาระบุราคา';
                    if (double.tryParse(v) == null) return 'กรุณาระบุตัวเลขที่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: billingCycle,
                  dropdownColor: const Color(0xFF131C2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'รอบบิล',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MONTHLY', child: Text('รายเดือน (MONTHLY)')),
                    DropdownMenuItem(value: 'YEARLY', child: Text('รายปี (YEARLY)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => billingCycle = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: brandColorCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'สีแบรนด์ (HEX เช่น #E50914, #1DB954)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final success = await notifier.createPackage(
                        name: nameCtrl.text.trim(),
                        category: categoryCtrl.text.trim(),
                        defaultPrice: double.parse(priceCtrl.text.trim()),
                        billingCycle: billingCycle,
                        brandColor: brandColorCtrl.text.trim().isNotEmpty
                            ? brandColorCtrl.text.trim()
                            : '#3B82F6',
                      );
                      if (success && ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('บันทึกบริการใหม่', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLoginScaffold(
    BuildContext context,
    AdminState state,
    AdminController notifier,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131C2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'เข้าสู่ระบบแอดมิน (Admin Portal)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131C2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 42,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ระบบจัดการผู้ดูแล (Admin)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณาเข้าสู่ระบบด้วยบัญชีระดับแอดมินเพื่อจัดการข้อมูล',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF60A5FA)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'บัญชีผู้ดูแลระบบตั้งต้น (Default Admin):',
                                style: TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'อีเมล: admin@subtracker.com\nรหัสผ่าน: AdminPassword123!',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              _adminEmailController.text = 'admin@subtracker.com';
                              _adminPasswordController.text = 'AdminPassword123!';
                            },
                            child: const Text(
                              'กดเพื่อกรอกอัตโนมัติ',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _adminEmailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'อีเมลผู้ดูแลระบบ',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF60A5FA)),
                      filled: true,
                      fillColor: const Color(0xFF0A0F1D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminPasswordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF60A5FA)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0F1D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                    ),
                    onFieldSubmitted: (_) {
                      if (!state.isActionLoading) {
                        notifier.loginAsAdmin(
                          email: _adminEmailController.text.trim(),
                          password: _adminPasswordController.text,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isActionLoading
                          ? null
                          : () {
                              notifier.loginAsAdmin(
                                email: _adminEmailController.text.trim(),
                                password: _adminPasswordController.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        disabledBackgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: state.isActionLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'เข้าสู่ระบบผู้ดูแล',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminUserDetailView extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String? userName;
  final AdminController notifier;

  const _AdminUserDetailView({
    required this.userId,
    required this.userEmail,
    this.userName,
    required this.notifier,
  });

  @override
  State<_AdminUserDetailView> createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<_AdminUserDetailView> {
  bool _isLoading = true;
  AdminUserDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final detail = await widget.notifier.getUserDetail(widget.userId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF131C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6).withAlpha(40),
                  child: Text(
                    (widget.userName?.isNotEmpty ?? false)
                        ? widget.userName![0].toUpperCase()
                        : widget.userEmail[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.userName?.isNotEmpty ?? false
                                  ? widget.userName!
                                  : 'ผู้ใช้ ${widget.userEmail}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_detail != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _detail!.role == 'ADMIN'
                                    ? const Color(0xFF3B82F6).withAlpha(40)
                                    : Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _detail!.role,
                                style: TextStyle(
                                  color: _detail!.role == 'ADMIN'
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  onPressed: _loadDetail,
                  tooltip: 'รีเฟรชข้อมูล',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF243049), height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                    ),
                  )
                : _detail == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'ไม่สามารถโหลดข้อมูลผู้ใช้ได้',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadDetail,
                              child: const Text('ลองใหม่อีกครั้ง'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // 1. User Profile Card
                          _buildProfileCard(context, _detail!),
                          const SizedBox(height: 24),

                          // 2. Subscriptions Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รายการ Subscriptions (${_detail!.subscriptions.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_detail!.subscriptions.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0F1D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF243049)),
                              ),
                              child: const Center(
                                child: Text(
                                  'ผู้ใช้นี้ยังไม่มีรายการ Subscription ในระบบ',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ..._detail!.subscriptions.map(
                              (sub) => _buildSubscriptionItem(context, sub),
                            ),

                          const SizedBox(height: 24),

                          // 3. Payment Cards Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'บัตรชำระเงินที่ผูกไว้ (${_detail!.paymentCards.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_detail!.paymentCards.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0F1D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF243049)),
                              ),
                              child: const Center(
                                child: Text(
                                  'ไม่มีบัตรชำระเงินผูกกับบัญชีนี้',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ..._detail!.paymentCards.map(
                              (card) => _buildCardItem(card),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AdminUserDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF243049)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ข้อมูลบัญชีผู้ใช้',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('แก้ไขโปรไฟล์', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showEditUserDialog(context, detail),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow('ชื่อ', detail.name ?? 'ไม่ระบุ'),
              ),
              Expanded(
                child: _buildInfoRow('สิทธิ์ (Role)', detail.role),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  'รายได้ต่อเดือน',
                  '฿${detail.monthlyIncome.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  'วันที่สมัคร',
                  _formatDate(detail.createdAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem(
    BuildContext context,
    AdminUserSubscriptionDetail sub,
  ) {
    Color statusColor;
    String statusText;
    switch (sub.status.toUpperCase()) {
      case 'ACTIVE':
        statusColor = const Color(0xFF10B981);
        statusText = 'ใช้งานอยู่';
        break;
      case 'PAUSED':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'พักการใช้งาน';
        break;
      case 'CANCELLED':
        statusColor = const Color(0xFFEF4444);
        statusText = 'ยกเลิกแล้ว';
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusText = sub.status;
    }

    Color brandColor = const Color(0xFF3B82F6);
    if (sub.brandColor != null && sub.brandColor!.isNotEmpty) {
      try {
        final hex = sub.brandColor!.replaceAll('#', '');
        brandColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243049)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: brandColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brandColor.withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    sub.name.isNotEmpty ? sub.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: brandColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sub.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sub.category} • ฿${sub.price.toStringAsFixed(0)} / ${sub.billingCycle == 'YEARLY' ? 'ปี' : 'เดือน'}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'รอบถัดไป: ${_formatDate(sub.nextRenewalDate)}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              if (sub.paymentCard != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.credit_card_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  '${sub.paymentCard!['brand'] ?? 'Card'} •••• ${sub.paymentCard!['last4'] ?? ''}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ],
          ),
          if (sub.notes != null && sub.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'หมายเหตุ: ${sub.notes}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('แก้ไขรายการ', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showEditSubscriptionDialog(context, sub),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                label: const Text('ลบรายการ', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context: context,
                    title: 'ยืนยันการลบ Subscription',
                    message: 'ต้องการลบรายการ "${sub.name}" ของผู้ใช้นี้หรือไม่?',
                    confirmText: 'ลบรายการ',
                    cancelText: 'ยกเลิก',
                    isDanger: true,
                  );
                  if (confirmed) {
                    await widget.notifier.deleteSubscription(sub.id);
                    await _loadDetail();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(AdminUserCardDetail card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF243049)),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.nickname ?? card.brand ?? 'บัตรชำระเงิน',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${card.brand ?? ''} •••• ${card.last4 ?? '****'}  (คงเหลือ: ฿${card.balance.toStringAsFixed(0)})',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: card.isActive
                  ? const Color(0xFF10B981).withAlpha(30)
                  : const Color(0xFFEF4444).withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              card.isActive ? 'เปิดใช้งาน' : 'ปิดใช้งาน',
              style: TextStyle(
                color: card.isActive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AdminUserDetail detail) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: detail.name ?? '');
    final incomeCtrl = TextEditingController(
      text: detail.monthlyIncome > 0 ? detail.monthlyIncome.toStringAsFixed(0) : '',
    );
    String selectedRole = detail.role;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF131C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'แก้ไขข้อมูลผู้ใช้ (Admin)',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ-นามสกุล',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    dropdownColor: const Color(0xFF131C2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'สิทธิ์การใช้งาน (Role)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USER', child: Text('USER (สมาชิกทั่วไป)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN (ผู้ดูแลระบบ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: incomeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'รายได้ต่อเดือน (บาท)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                        return 'กรุณาระบุตัวเลขที่ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newIncome = incomeCtrl.text.trim().isNotEmpty
                      ? double.tryParse(incomeCtrl.text.trim())
                      : null;
                  final success = await widget.notifier.updateUser(
                    detail.id,
                    name: nameCtrl.text.trim(),
                    role: selectedRole,
                    monthlyIncome: newIncome,
                  );
                  if (success && dlgCtx.mounted) {
                    Navigator.pop(dlgCtx);
                    _loadDetail();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubscriptionDialog(
    BuildContext context,
    AdminUserSubscriptionDetail sub,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: sub.name);
    final categoryCtrl = TextEditingController(text: sub.category);
    final priceCtrl = TextEditingController(text: sub.price.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: sub.notes ?? '');
    String billingCycle = sub.billingCycle;
    String status = sub.status;
    DateTime nextRenewalDate = sub.nextRenewalDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF131C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'แก้ไข Subscription (Admin)',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ Subscription',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุชื่อ' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: categoryCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'หมวดหมู่',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ราคา (บาท)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'กรุณาระบุราคา';
                      if (double.tryParse(v) == null) return 'กรุณาระบุตัวเลข';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: billingCycle,
                    dropdownColor: const Color(0xFF131C2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'รอบบิล',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MONTHLY', child: Text('รายเดือน (MONTHLY)')),
                      DropdownMenuItem(value: 'YEARLY', child: Text('รายปี (YEARLY)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => billingCycle = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    dropdownColor: const Color(0xFF131C2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'สถานะ',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (ใช้งานอยู่)')),
                      DropdownMenuItem(value: 'PAUSED', child: Text('PAUSED (พักการใช้งาน)')),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED (ยกเลิกแล้ว)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => status = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dlgCtx,
                        initialDate: nextRenewalDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDlgState(() => nextRenewalDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'วันรอบบิลถัดไป',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                        suffixIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6)),
                      ),
                      child: Text(
                        _formatDate(nextRenewalDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'หมายเหตุ',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final success = await widget.notifier.updateSubscription(
                    sub.id,
                    name: nameCtrl.text.trim(),
                    category: categoryCtrl.text.trim(),
                    price: double.parse(priceCtrl.text.trim()),
                    billingCycle: billingCycle,
                    status: status,
                    nextRenewalDate: nextRenewalDate,
                    notes: notesCtrl.text.trim(),
                  );
                  if (success && dlgCtx.mounted) {
                    Navigator.pop(dlgCtx);
                    _loadDetail();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

