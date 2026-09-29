import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/responsive.dart';
import '../../features/auth/presentation/auth_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? true;
    final location = GoRouterState.of(context).uri.path;

    return ResponsiveLayout(
      mobile: _MobileLayout(
        currentLocation: location,
        isAdmin: isAdmin,
        userEmail: user?.email ?? 'admin@kasirku.id',
        userName: user?.name ?? 'Admin KasirKu',
        onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
        child: child,
      ),
      tablet: _TabletLayout(
        currentLocation: location,
        isAdmin: isAdmin,
        userEmail: user?.email ?? 'admin@kasirku.id',
        userName: user?.name ?? 'Admin KasirKu',
        onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
        child: child,
      ),
      desktop: _DesktopLayout(
        currentLocation: location,
        isAdmin: isAdmin,
        userEmail: user?.email ?? 'admin@kasirku.id',
        userName: user?.name ?? 'Admin KasirKu',
        onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
        child: child,
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final String currentLocation;
  final bool isAdmin;
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Widget child;

  const _DesktopLayout({
    required this.currentLocation,
    required this.isAdmin,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: AppDimensions.sidebarWidth,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.point_of_sale,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceXs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KasirKu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isAdmin ? 'Admin Portal' : 'Kasir Terminal',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.spaceXs),

                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXs,
                      vertical: AppDimensions.spaceXs,
                    ),
                    children: [
                      if (isAdmin) ...[
                        _SidebarNavItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isSelected: currentLocation == '/',
                          onTap: () => context.go('/'),
                        ),
                      ],
                      _SidebarNavItem(
                        icon: Icons.point_of_sale_outlined,
                        activeIcon: Icons.point_of_sale,
                        label: 'Kasir (POS)',
                        isSelected: currentLocation.startsWith('/pos'),
                        onTap: () => context.go('/pos'),
                      ),
                      if (isAdmin) ...[
                        _SidebarNavItem(
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2_rounded,
                          label: 'Produk',
                          isSelected: currentLocation.startsWith('/products'),
                          onTap: () => context.go('/products'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.warehouse_outlined,
                          activeIcon: Icons.warehouse_rounded,
                          label: 'Inventori & Stok',
                          isSelected: currentLocation.startsWith('/inventory'),
                          onTap: () => context.go('/inventory'),
                        ),
                      ],
                      _SidebarNavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: 'Transaksi',
                        isSelected: currentLocation.startsWith('/transactions'),
                        onTap: () => context.go('/transactions'),
                      ),
                      if (isAdmin) ...[
                        _SidebarNavItem(
                          icon: Icons.bar_chart_rounded,
                          activeIcon: Icons.bar_chart_rounded,
                          label: 'Laporan',
                          isSelected: currentLocation.startsWith('/reports'),
                          onTap: () => context.go('/reports'),
                        ),
                        _SidebarNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings_rounded,
                          label: 'Pengaturan',
                          isSelected: currentLocation.startsWith('/settings'),
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),

                // User Profile & Logout
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceSm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceXs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  isAdmin ? 'ROLE: ADMIN' : 'ROLE: KASIR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isAdmin ? AppColors.primary : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      InkWell(
                        onTap: onLogout,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceSm,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBtnBg,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusButton),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 16,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.maxContentWidth,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final String currentLocation;
  final bool isAdmin;
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Widget child;

  const _TabletLayout({
    required this.currentLocation,
    required this.isAdmin,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: AppDimensions.compactSidebarWidth,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.spaceMd),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (isAdmin)
                        _CompactNavItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard_rounded,
                          tooltip: 'Dashboard',
                          isSelected: currentLocation == '/',
                          onTap: () => context.go('/'),
                        ),
                      _CompactNavItem(
                        icon: Icons.point_of_sale_outlined,
                        activeIcon: Icons.point_of_sale,
                        tooltip: 'Kasir',
                        isSelected: currentLocation.startsWith('/pos'),
                        onTap: () => context.go('/pos'),
                      ),
                      if (isAdmin) ...[
                        _CompactNavItem(
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2_rounded,
                          tooltip: 'Produk',
                          isSelected: currentLocation.startsWith('/products'),
                          onTap: () => context.go('/products'),
                        ),
                        _CompactNavItem(
                          icon: Icons.warehouse_outlined,
                          activeIcon: Icons.warehouse_rounded,
                          tooltip: 'Inventori & Stok',
                          isSelected: currentLocation.startsWith('/inventory'),
                          onTap: () => context.go('/inventory'),
                        ),
                      ],
                      _CompactNavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        tooltip: 'Transaksi',
                        isSelected: currentLocation.startsWith('/transactions'),
                        onTap: () => context.go('/transactions'),
                      ),
                      if (isAdmin) ...[
                        _CompactNavItem(
                          icon: Icons.bar_chart_rounded,
                          activeIcon: Icons.bar_chart_rounded,
                          tooltip: 'Laporan',
                          isSelected: currentLocation.startsWith('/reports'),
                          onTap: () => context.go('/reports'),
                        ),
                        _CompactNavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings_rounded,
                          tooltip: 'Pengaturan',
                          isSelected: currentLocation.startsWith('/settings'),
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Keluar',
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  onPressed: onLogout,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final String currentLocation;
  final bool isAdmin;
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Widget child;

  const _MobileLayout({
    required this.currentLocation,
    required this.isAdmin,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      // Cashier simplified bottom bar: Kasir (0), Transaksi (1), Logout (2)
      final cashierIndex = currentLocation.startsWith('/transactions') ? 1 : 0;
      return Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            child: NavigationBar(
              selectedIndex: cashierIndex,
              onDestinationSelected: (idx) {
                if (idx == 0) context.go('/pos');
                if (idx == 1) context.go('/transactions');
                if (idx == 2) onLogout();
              },
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primaryLight,
              elevation: 0,
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
                  label: 'Kasir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  label: 'Transaksi',
                ),
                NavigationDestination(
                  icon: Icon(Icons.logout_rounded),
                  label: 'Keluar',
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Admin full bottom bar
    int adminIndex = 0;
    if (currentLocation.startsWith('/pos')) adminIndex = 1;
    if (currentLocation.startsWith('/products')) adminIndex = 2;
    if (currentLocation.startsWith('/transactions')) adminIndex = 3;
    if (currentLocation.startsWith('/inventory') ||
        currentLocation.startsWith('/reports') ||
        currentLocation.startsWith('/settings')) {
      adminIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: adminIndex,
            onDestinationSelected: (idx) {
              if (idx == 0) context.go('/');
              if (idx == 1) context.go('/pos');
              if (idx == 2) context.go('/products');
              if (idx == 3) context.go('/transactions');
              if (idx == 4) _showAdminMoreModal(context);
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            elevation: 0,
            height: 64,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
                label: 'Kasir',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                label: 'Produk',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                label: 'Transaksi',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_rounded),
                selectedIcon: Icon(Icons.menu_rounded, color: AppColors.primary),
                label: 'Lainnya',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminMoreModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
              vertical: AppDimensions.spaceSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.warehouse_outlined, color: AppColors.primary),
                  title: const Text('Inventori & Stok', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Peringatan stok menipis dan mutasi opname'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/inventory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                  title: const Text('Laporan Penjualan', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Statistik performa penjualan dan produk'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/reports');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                  title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Info toko, profil akun, dan preferensi'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/settings');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
                  subtitle: Text('$userName ($userEmail)'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactNavItem({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(isSelected ? activeIcon : icon),
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primaryLight : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
