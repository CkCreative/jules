import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/models.dart';
import '../widgets/sidebar/sidebar_widget.dart';
import '../widgets/chat/chat_history.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/diff/diff_panel.dart';
import '../widgets/settings_drawer.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _isSidebarOpen;
  bool? _isDiffPanelVisible;
  bool _isSettingsOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isSidebarOpen ??= context.read<ChatProvider>().isSidebarOpen;
    _isDiffPanelVisible ??= context.read<SettingsProvider>().isDiffPanelVisible;
  }

  void _setSidebarOpen(bool isOpen) {
    if (_isSidebarOpen == isOpen) return;
    setState(() => _isSidebarOpen = isOpen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().setSidebarOpen(isOpen);
    });
  }

  void _toggleDiffPanel() {
    final isVisible = !(_isDiffPanelVisible ?? true);
    _setDiffPanelVisible(isVisible);
  }

  void _setDiffPanelVisible(bool isVisible) {
    if (_isDiffPanelVisible == isVisible) return;
    setState(() => _isDiffPanelVisible = isVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().setDiffPanelVisible(isVisible);
    });
  }

  void _setSettingsOpen(bool isOpen) {
    if (_isSettingsOpen == isOpen) return;
    setState(() => _isSettingsOpen = isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((ChatProvider p) => p.isLoading);
    final isSyncing = context.select((ChatProvider p) => p.isSyncing);
    final errorMessage = context.select((ChatProvider p) => p.errorMessage);

    final isSidebarOpen = _isSidebarOpen ?? true;
    final isDiffPanelVisible = _isDiffPanelVisible ?? true;
    final diffPanelWidth = context.select(
      (SettingsProvider s) => s.diffPanelWidth,
    );

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppConstants.mobileBreakpoint;
    final isTablet = width < AppConstants.tabletBreakpoint;

    return Scaffold(
      drawer: isMobile ? const Drawer(child: SidebarWidget()) : null,
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile && isSidebarOpen)
                SidebarWidget(onToggleSidebar: _setSidebarOpen),
              Expanded(
                child: Column(
                  children: [
                    _HomeScreenTopBar(
                      isSyncing: isSyncing,
                      isSidebarOpen: isSidebarOpen,
                      isDiffPanelVisible: isDiffPanelVisible,
                      onOpenSidebar: () => _setSidebarOpen(true),
                      onToggleDiffPanel: _toggleDiffPanel,
                      onOpenSettings: () => _setSettingsOpen(true),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildChatSection(isTablet || !isDiffPanelVisible),
                          if (!isTablet && isDiffPanelVisible) ...[
                            _buildResizer(context),
                            SizedBox(
                              width: diffPanelWidth,
                              child: const _HomeScreenDiffSection(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      "Please wait...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (errorMessage != null && errorMessage.contains('SocketException'))
            _buildOfflineStatus(),
          if (errorMessage != null && !errorMessage.contains('SocketException'))
            _buildErrorBanner(context, errorMessage),
          if (_isSettingsOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setSettingsOpen(false),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 320,
              child: SettingsDrawer(
                onClose: () => _setSettingsOpen(false),
                isDiffPanelVisible: isDiffPanelVisible,
                onDiffPanelVisibilityChanged: _setDiffPanelVisible,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineStatus() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 14),
            SizedBox(width: 8),
            Text(
              "Offline Mode",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              IconButton(
                onPressed: () => context.read<ChatProvider>().refreshSessions(),
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(bool isFullWidth) {
    return Expanded(
      child: Container(
        constraints: isFullWidth
            ? null
            : const BoxConstraints(maxWidth: AppConstants.chatAreaMaxWidth),
        child: const Column(
          children: [
            Expanded(child: ChatHistory()),
            ChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildResizer(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        context.read<SettingsProvider>().updateDiffPanelWidth(details.delta.dx);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 6,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              height: double.infinity,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenTopBar extends StatelessWidget {
  final bool isSyncing;
  final bool isSidebarOpen;
  final bool isDiffPanelVisible;
  final VoidCallback onOpenSidebar;
  final VoidCallback onToggleDiffPanel;
  final VoidCallback onOpenSettings;

  const _HomeScreenTopBar({
    required this.isSyncing,
    required this.isSidebarOpen,
    required this.isDiffPanelVisible,
    required this.onOpenSidebar,
    required this.onToggleDiffPanel,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.select((ChatProvider p) => p.currentSession);
    final draftRepo = context.select((ChatProvider p) => p.draftRepo);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppConstants.mobileBreakpoint;

    final displayTitle =
        session?.title ??
        (draftRepo != null ? "New Thread" : "No session selected");
    final displayRepo = session?.repo ?? draftRepo;

    return Container(
      height: AppConstants.headerHeight,
      padding: EdgeInsets.only(
        left: (!isSidebarOpen && !isMobile) ? 80 : 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  if (isMobile)
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (!isSidebarOpen && !isMobile)
                    IconButton(
                      onPressed: onOpenSidebar,
                      icon: const Icon(
                        Icons.dock,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (!isSidebarOpen && !isMobile) const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (session != null) ...[
                    const SizedBox(width: 12),
                    _buildStateBadge(session.state),
                  ],
                  if (draftRepo != null && session == null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        "DRAFT",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                  if (isSyncing) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (!isMobile && displayRepo != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.folder,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        displayRepo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onToggleDiffPanel,
                icon: Icon(
                  isDiffPanelVisible ? Icons.splitscreen : Icons.fullscreen,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                tooltip: "Toggle Diff Panel",
              ),
              const SizedBox(width: 8),
              _buildTopBarButton(
                context,
                "New thread",
                icon: Icons.add,
                onTap: () => context.read<ChatProvider>().startNewThread(null),
              ),
              const SizedBox(width: 8),
              _buildTopBarButton(
                context,
                "Refresh",
                icon: Icons.refresh,
                onTap: () => context.read<ChatProvider>().refreshSessions(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onOpenSettings,
                icon: const Icon(
                  Icons.settings,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateBadge(SessionState state) {
    Color color = AppColors.textMuted;
    if (state == SessionState.inProgress) color = Colors.blue;
    if (state == SessionState.completed) color = Colors.green;
    if (state == SessionState.failed) color = Colors.red;
    if (state == SessionState.awaitingPlanApproval) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        state.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTopBarButton(
    BuildContext context,
    String label, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenDiffSection extends StatelessWidget {
  const _HomeScreenDiffSection();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(child: _DeferredDiffPanel());
  }
}

class _DeferredDiffPanel extends StatefulWidget {
  const _DeferredDiffPanel();

  @override
  State<_DeferredDiffPanel> createState() => _DeferredDiffPanelState();
}

class _DeferredDiffPanelState extends State<_DeferredDiffPanel> {
  bool _showDiff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showDiff = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showDiff) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    }

    return const DiffPanel();
  }
}
