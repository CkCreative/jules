import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/constants.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import 'thread_list.dart';

class SidebarWidget extends StatefulWidget {
  final ValueChanged<bool>? onToggleSidebar;

  const SidebarWidget({super.key, this.onToggleSidebar});

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch(ChatProvider provider) {
    setState(() => _isSearchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch(ChatProvider provider) {
    _searchController.clear();
    provider.setSidebarSearchQuery('');
    setState(() => _isSearchOpen = false);
  }

  void _showRecent(ChatProvider provider) {
    if (_isSearchOpen || provider.isSidebarSearching) {
      _closeSearch(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, provider),
          _buildActionItems(context, provider),
          if (_isSearchOpen) _buildSearchField(context, provider),
          Expanded(
            child: ThreadList(onSearchSelection: () => _closeSearch(provider)),
          ),
          _buildProfileSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatProvider provider) {
    return DragToMoveArea(
      child: Container(
        height: AppConstants.headerHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            IconButton(
              onPressed: () {
                if (widget.onToggleSidebar != null) {
                  widget.onToggleSidebar!(false);
                } else {
                  provider.toggleSidebar();
                }
              },
              icon: const Icon(
                Icons.dock,
                size: 18,
                color: AppColors.textMuted,
              ),
              tooltip: "Close Sidebar",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItems(BuildContext context, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildActionItem(
            context,
            FontAwesomeIcons.plus,
            "New thread",
            provider,
            size: 14,
            onTap: () => provider.startNewThread(null),
          ),
          _buildActionItem(
            context,
            FontAwesomeIcons.magnifyingGlass,
            "Search",
            provider,
            size: 14,
            onTap: () => _openSearch(provider),
          ),
          _buildActionItem(
            context,
            FontAwesomeIcons.clock,
            "Recent",
            provider,
            size: 14,
            onTap: () => _showRecent(provider),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: provider.setSidebarSearchQuery,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 16),
          suffixIcon: IconButton(
            onPressed: () => _closeSearch(provider),
            icon: const Icon(Icons.close, size: 16),
            tooltip: "Close search",
          ),
          hintText: "Search threads and repos",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    dynamic icon,
    String title,
    ChatProvider provider, {
    double size = 16,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Center(
                  child: icon is IconData
                      ? Icon(
                          icon,
                          size: size,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )
                      : FaIcon(
                          icon,
                          size: size,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            child: Text(
              "MC",
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "User Account",
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: Icon(
              Icons.logout,
              size: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
