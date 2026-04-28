import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../models/models.dart';
import 'file_diff_widget.dart';

class DiffPanel extends StatelessWidget {
  const DiffPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final session = provider.currentSession;
    
    // Find all activities with code changes
    final codeActivities = session?.activities
        .where((a) => a.artifacts.any((art) => art.changeSet != null))
        .toList() ?? [];

    // Use the latest activity with changes
    final List<ChangeSet> changeSets = codeActivities.isEmpty 
        ? [] 
        : codeActivities.last.artifacts
            .where((art) => art.changeSet != null)
            .map((art) => art.changeSet!)
            .toList();
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Permanent pane separator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 1,
            child: Container(color: Theme.of(context).dividerColor),
          ),
          if (codeActivities.isEmpty)
            Center(
              child: Text(
                "No code changes in this session",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, changeSets, provider),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: changeSets.length,
                    itemBuilder: (context, index) {
                      return FileDiffWidget(changeSet: changeSets[index]);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<ChangeSet> changes, ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "${changes.length} files changed",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
