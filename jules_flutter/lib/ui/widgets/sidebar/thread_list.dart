import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../providers/chat_provider.dart';

class ThreadList extends StatelessWidget {
  final VoidCallback? onSearchSelection;

  const ThreadList({super.key, this.onSearchSelection});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    if (provider.isSidebarSearching) {
      return _SearchResults(onSearchSelection: onSearchSelection);
    }

    final sessions = provider.sessions;
    final Map<String, List<Session>> grouped = {};
    for (final session in sessions) {
      final key = session.repo ?? 'Other';
      grouped.putIfAbsent(key, () => []).add(session);
    }

    final flatItems = grouped.entries
        .expand((entry) => [entry.key, ...entry.value])
        .toList();

    return RepaintBoundary(
      child: ListView.builder(
        itemCount: flatItems.length,
        itemBuilder: (context, index) {
          final item = flatItems[index];
          if (item is String) {
            return _CategoryHeader(name: item);
          }
          return _SessionItem(session: item as Session);
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final VoidCallback? onSearchSelection;

  const _SearchResults({this.onSearchSelection});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final query = provider.sidebarSearchQuery.trim().toLowerCase();
    final threadMatches = provider.visibleSessions;
    final repoMatches = provider.sortedRepoIds.where((repo) {
      return repo.toLowerCase().contains(query);
    }).toList();
    final isHistoryIndexing = provider.isHistoryIndexing;
    final hasMoreSessions = provider.hasMoreSessions;

    if (repoMatches.isEmpty && threadMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHistoryIndexing) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Indexing older history...',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ] else
                const Text(
                  'No matches found',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: ListView(
        children: [
          if (repoMatches.isNotEmpty) ...[
            const _SearchSectionHeader(title: 'Repositories'),
            for (final repo in repoMatches)
              _RepoSearchItem(repo: repo, onSelected: onSearchSelection),
          ],
          if (threadMatches.isNotEmpty) ...[
            const _SearchSectionHeader(title: 'Threads'),
            for (final session in threadMatches)
              _SessionItem(
                session: session,
                showRepoSubtitle: true,
                onSelected: onSearchSelection,
              ),
          ],
          if (hasMoreSessions) const _SearchMoreHistoryButton(),
        ],
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  final String title;

  const _SearchSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _RepoSearchItem extends StatelessWidget {
  final String repo;
  final VoidCallback? onSelected;

  const _RepoSearchItem({required this.repo, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: () {
          context.read<ChatProvider>().startNewThread(repo);
          onSelected?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.folder_open,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Start a new thread in this repo',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_square, size: 15, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchMoreHistoryButton extends StatelessWidget {
  const _SearchMoreHistoryButton();

  @override
  Widget build(BuildContext context) {
    final isHistoryIndexing = context.select(
      (ChatProvider p) => p.isHistoryIndexing,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: OutlinedButton.icon(
        onPressed: isHistoryIndexing
            ? null
            : () => context.read<ChatProvider>().loadMoreSessions(),
        icon: isHistoryIndexing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.history, size: 16),
        label: Text(
          isHistoryIndexing
              ? 'Indexing older history...'
              : 'Finish indexing history',
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatefulWidget {
  final String name;

  const _CategoryHeader({required this.name});

  @override
  State<_CategoryHeader> createState() => _CategoryHeaderState();
}

class _CategoryHeaderState extends State<_CategoryHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.folder_open, size: 14, color: mutedColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.name,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: _isHovered,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_horiz, size: 16, color: mutedColor),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      context.read<ChatProvider>().startNewThread(widget.name);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.edit_square,
                        size: 16,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  final Session session;
  final bool showRepoSubtitle;
  final VoidCallback? onSelected;

  const _SessionItem({
    required this.session,
    this.showRepoSubtitle = false,
    this.onSelected,
  });

  String _getRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays >= 365) {
      return "${(difference.inDays / 365).floor()}y";
    }
    if (difference.inDays >= 30) return "${(difference.inDays / 30).floor()}mo";
    if (difference.inDays >= 7) return "${(difference.inDays / 7).floor()}w";
    if (difference.inDays >= 1) return "${difference.inDays}d";
    if (difference.inHours >= 1) return "${difference.inHours}h";
    if (difference.inMinutes >= 1) return "${difference.inMinutes}m";
    return "now";
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = context.select(
      (ChatProvider p) => p.currentSession?.id == session.id,
    );
    final timeStr = _getRelativeTime(session.createTime);
    final isInProgress = session.state == SessionState.inProgress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: () {
          context.read<ChatProvider>().selectSession(session);
          onSelected?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showRepoSubtitle && session.repo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.repo!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isInProgress)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey,
                    ),
                  ),
                )
              else
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
