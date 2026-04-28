import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../models/models.dart';

class MessageBubble extends StatelessWidget {
  final Activity activity;

  const MessageBubble({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isUser = activity.originator == ActivityOriginator.user;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isUser)
            _buildUserBubble(context)
          else
            _buildAgentActivity(context),
        ],
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        activity.userMessage ?? activity.description ?? '',
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildAgentActivity(BuildContext context) {
    final bodyMedium = Theme.of(context).textTheme.bodyMedium;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activity.agentMessage != null) ...[
          Text(
            activity.agentMessage!,
            style: bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
        ],
        
        if (activity.planGenerated != null) ...[
          _buildPlanSection(context, activity.planGenerated!),
          const SizedBox(height: 12),
        ],

        if (activity.progressUpdated != null) ...[
          _buildStatusLine(context, activity.progressUpdated!.title, activity.progressUpdated!.description),
          const SizedBox(height: 12),
        ],

        if (activity.artifacts.isNotEmpty) ...[
          ...activity.artifacts.map((a) => _buildArtifact(context, a)),
        ],

        if (activity.agentMessage == null && 
            activity.planGenerated == null && 
            activity.progressUpdated == null && 
            activity.artifacts.isEmpty)
          Text(
            activity.description ?? 'System event',
            style: bodySmall?.copyWith(fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildPlanSection(BuildContext context, Plan plan) {
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planned changes",
          style: bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ...plan.steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${step.index + 1}. ", style: bodySmall?.copyWith(fontSize: 12)),
              Expanded(
                child: Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStatusLine(BuildContext context, String title, String description) {
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    final mutedColor = bodySmall?.color ?? AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 14, color: mutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: bodySmall?.copyWith(fontSize: 12, color: mutedColor.withValues(alpha: 0.85), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildArtifact(BuildContext context, Artifact artifact) {
    if (artifact.changeSet != null) {
      return _buildFilePill(context, "Edited", artifact.changeSet!.gitPatch.suggestedCommitMessage ?? "Source changes");
    }
    if (artifact.bashOutput != null) {
      return _buildStatusLine(context, "Run", artifact.bashOutput!.command);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilePill(BuildContext context, String action, String filename) {
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    final mutedColor = bodySmall?.color ?? AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$action ",
            style: bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              filename,
              style: bodySmall?.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check, size: 12, color: mutedColor),
        ],
      ),
    );
  }
}
