import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../models/models.dart';

class FileDiffWidget extends StatelessWidget {
  final ChangeSet changeSet;

  const FileDiffWidget({super.key, required this.changeSet});

  @override
  Widget build(BuildContext context) {
    final patch = changeSet.gitPatch.unidiffPatch;
    final lines = _parsePatch(patch);
    final filename = _extractFilename(patch);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFileHeader(filename),
        _buildDiffLines(context, lines),
      ],
    );
  }

  Widget _buildFileHeader(String filename) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            filename,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffLines(BuildContext context, List<_ParsedLine> lines) {
    return Column(
      children: lines.map((line) => _buildLine(context, line)).toList(),
    );
  }

  Widget _buildLine(BuildContext context, _ParsedLine line) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color? bgColor;
    Color? lineNumberColor;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8) ?? Colors.grey;

    if (line.type == _LineType.added) {
      bgColor = isDark ? AppColors.diffAddedBgDark : AppColors.diffAddedBgLight;
      lineNumberColor = isDark ? AppColors.diffAddedLineDark : AppColors.diffAddedLineLight;
      textColor = isDark ? AppColors.diffAddedLineDark : AppColors.diffAddedLineLight;
    } else if (line.type == _LineType.removed) {
      bgColor = isDark ? AppColors.diffRemovedBgDark : AppColors.diffRemovedBgLight;
      lineNumberColor = isDark ? AppColors.diffRemovedLineDark : AppColors.diffRemovedLineLight;
      textColor = isDark ? AppColors.diffRemovedLineDark : AppColors.diffRemovedLineLight;
    } else if (line.type == _LineType.header) {
      textColor = isDark ? AppColors.textMuted.withValues(alpha: 0.5) : AppColors.diffLineNumberLight;
      bgColor = isDark ? AppColors.sidebarBg.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.05);
    } else {
      lineNumberColor = isDark ? AppColors.textMuted.withValues(alpha: 0.3) : AppColors.diffLineNumberLight;
    }

    final String lineNumberStr = line.type == _LineType.header 
        ? '' 
        : (line.type == _LineType.added ? line.newLineNumber : line.oldLineNumber)?.toString() ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: (line.type == _LineType.added || line.type == _LineType.removed)
              ? BorderSide(color: lineNumberColor!, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              lineNumberStr,
              style: TextStyle(
                color: lineNumberColor ?? (isDark ? AppColors.textMuted.withValues(alpha: 0.3) : AppColors.diffLineNumberLight),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                line.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ParsedLine> _parsePatch(String patch) {
    final List<_ParsedLine> result = [];
    final lines = patch.split('\n');
    
    int oldLine = 0;
    int newLine = 0;

    for (var line in lines) {
      if (line.startsWith('---') || line.startsWith('+++') || line.startsWith('diff')) {
        continue;
      }
      
      if (line.startsWith('@@')) {
        final match = RegExp(r'@@ -(\d+),?\d* \+(\d+),?\d* @@').firstMatch(line);
        if (match != null) {
          oldLine = int.parse(match.group(1)!);
          newLine = int.parse(match.group(2)!);
        }
        result.add(_ParsedLine(line, _LineType.header, ' ', null, null));
      } else if (line.startsWith('+')) {
        result.add(_ParsedLine(line.substring(1), _LineType.added, '+', null, newLine));
        newLine++;
      } else if (line.startsWith('-')) {
        result.add(_ParsedLine(line.substring(1), _LineType.removed, '-', oldLine, null));
        oldLine++;
      } else {
        result.add(_ParsedLine(
          line.isEmpty ? '' : (line.startsWith(' ') ? line.substring(1) : line), 
          _LineType.unchanged, 
          ' ', 
          oldLine, 
          newLine
        ));
        oldLine++;
        newLine++;
      }
    }
    return result;
  }

  String _extractFilename(String patch) {
    final lines = patch.split('\n');
    for (var line in lines) {
      if (line.startsWith('+++ b/')) {
        return line.substring(6);
      }
    }
    return "Unknown file";
  }
}

enum _LineType { added, removed, unchanged, header }

class _ParsedLine {
  final String content;
  final _LineType type;
  final String prefix;
  final int? oldLineNumber;
  final int? newLineNumber;
  
  _ParsedLine(this.content, this.type, this.prefix, this.oldLineNumber, this.newLineNumber);
}
