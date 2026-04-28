import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../models/models.dart';
import 'message_bubble.dart';

class ChatHistory extends StatelessWidget {
  const ChatHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.select((ChatProvider p) => p.currentSession);
    final isNewThreadMode = context.select((ChatProvider p) => p.isNewThreadMode);
    final isRepoSelectionMode = context.select((ChatProvider p) => p.isRepoSelectionMode);
    final draftRepo = context.select((ChatProvider p) => p.draftRepo);
    
    if (session == null && !isNewThreadMode && !isRepoSelectionMode) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            const Text(
              "Select a thread to start building", 
              style: TextStyle(color: Colors.white24, fontSize: 14)
            ),
          ],
        ),
      );
    }

    if (isRepoSelectionMode) {
      return const _RepoSelectorView();
    }

    if (isNewThreadMode) {
      return _NewThreadWelcome(repo: draftRepo!);
    }

    final activities = session!.activities;
    final prompt = session.prompt;

    return RepaintBoundary(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: (prompt != null ? 1 : 0) + activities.length,
        itemBuilder: (context, index) {
          if (prompt != null && index == 0) {
            return MessageBubble(
              activity: Activity(
                id: 'prompt',
                originator: ActivityOriginator.user,
                createTime: session.createTime,
                userMessage: prompt,
              ),
            );
          }
          final activityIndex = prompt != null ? index - 1 : index;
          return MessageBubble(activity: activities[activityIndex]);
        },
      ),
    );
  }
}

class _RepoSelectorView extends StatefulWidget {
  const _RepoSelectorView();

  @override
  State<_RepoSelectorView> createState() => _RepoSelectorViewState();
}

class _RepoSelectorViewState extends State<_RepoSelectorView> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final allRepos = provider.sortedRepoIds;

    final filteredRepos = allRepos
        .where((r) => r.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a repository",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                ? "Showing recently used and available repositories." 
                : "Searching repositories...",
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search repositories...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredRepos.length + (provider.hasMoreSources ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index < filteredRepos.length) {
                    return _buildRepoTile(context, filteredRepos[index]);
                  }
                  
                  if (index == filteredRepos.length && provider.hasMoreSources) {
                    return _buildLoadMoreButton(context, provider);
                  }

                  // Last item is always the "Add custom" entry if searching
                  if (_searchQuery.isEmpty) return const SizedBox();
                  return _buildRepoTile(context, _searchQuery, isNew: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton(
        onPressed: provider.isSyncing ? null : () => provider.loadMoreSources(),
        child: provider.isSyncing 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Load more repositories..."),
      ),
    );
  }

  Widget _buildRepoTile(BuildContext context, String repo, {bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.read<ChatProvider>().updateDraftRepo(repo);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(isNew ? Icons.add : Icons.folder_outlined, size: 18, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  repo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              if (isNew)
                const Text("Add new", style: TextStyle(fontSize: 11, color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewThreadWelcome extends StatefulWidget {
  final String repo;
  const _NewThreadWelcome({required this.repo});

  @override
  State<_NewThreadWelcome> createState() => _NewThreadWelcomeState();
}

class _NewThreadWelcomeState extends State<_NewThreadWelcome> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => context.read<ChatProvider>().startNewThread(null),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "New Task for ",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.repo,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_horiz, size: 16, color: Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "What are we building today? Describe your task in the input below to start the conversation.",
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
