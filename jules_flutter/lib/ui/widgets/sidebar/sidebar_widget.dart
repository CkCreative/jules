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

  Future<void> _showAddAccountDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final apiKeyController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Add account"),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter your Gemini API key to connect your account. Your keys are stored securely in local storage.",
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Account name",
                      hintText: "e.g. Work Account",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: apiKeyController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "API key",
                      hintText: "AIza...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (apiKeyController.text.trim().isEmpty) return;
                  context.read<AuthProvider>().login(
                        apiKeyController.text,
                        name: nameController.text,
                      );
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("Add account"),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          );
        },
      );
    } finally {
      nameController.dispose();
      apiKeyController.dispose();
    }
  }

  Future<bool> _confirmAccountAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 320,
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            );
          },
        ) ??
        false;
  }

  Future<void> _confirmSignOut(BuildContext context, String accountName) async {
    final confirmed = await _confirmAccountAction(
      context,
      title: "Sign out?",
      message:
          "This will close $accountName on this device. Your saved accounts stay available unless you remove them.",
      confirmLabel: "Sign out",
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  Future<void> _confirmRemoveAccount(
    BuildContext context,
    String accountId,
    String accountName,
  ) async {
    final confirmed = await _confirmAccountAction(
      context,
      title: "Remove account?",
      message:
          "This removes $accountName and its saved API key from this device. Cached account data is left untouched.",
      confirmLabel: "Remove",
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AuthProvider>().deleteAccount(accountId);
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
    final auth = context.watch<AuthProvider>();
    final activeAccount = auth.activeAccount;
    final accountName = activeAccount?.name ?? "No account";
    final initials = accountName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

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
              initials.isEmpty ? "JA" : initials,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              accountName,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: "Account menu",
            icon: Icon(
              Icons.account_circle_outlined,
              size: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            onSelected: (value) {
              if (value == '__add__') {
                _showAddAccountDialog(context);
              } else if (value == '__logout__') {
                _confirmSignOut(context, accountName);
              } else if (value == '__delete__' && activeAccount != null) {
                _confirmRemoveAccount(
                  context,
                  activeAccount.id,
                  activeAccount.name,
                );
              } else {
                context.read<AuthProvider>().switchAccount(value);
              }
            },
            itemBuilder: (context) => [
              for (final account in auth.accounts)
                PopupMenuItem(
                  value: account.id,
                  child: Row(
                    children: [
                      Icon(
                        account.id == activeAccount?.id
                            ? Icons.check
                            : Icons.account_circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          account.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: '__add__',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.add, size: 18),
                  title: Text("Add account"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (activeAccount != null)
                const PopupMenuItem(
                  value: '__delete__',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline, size: 18),
                    title: Text("Remove current"),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: '__logout__',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.logout, size: 18),
                  title: Text("Sign out"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
