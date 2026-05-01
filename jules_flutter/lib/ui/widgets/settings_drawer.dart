import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/settings_provider.dart';

class SettingsDrawer extends StatelessWidget {
  final VoidCallback? onClose;
  final bool? isDiffPanelVisible;
  final ValueChanged<bool>? onDiffPanelVisibilityChanged;

  const SettingsDrawer({
    super.key,
    this.onClose,
    this.isDiffPanelVisible,
    this.onDiffPanelVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            height: AppConstants.headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Settings",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose ?? () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader("Appearance"),
                const SizedBox(height: 16),
                _buildSettingTile(
                  context,
                  "Theme Mode",
                  const _ThemeModeDropdown(),
                ),
                Divider(height: 40, color: Theme.of(context).dividerColor),
                _buildSectionHeader("Diff View"),
                const SizedBox(height: 16),
                _buildSettingTile(
                  context,
                  "Show Diff Panel",
                  _DiffPanelSwitch(
                    value: isDiffPanelVisible,
                    onChanged: onDiffPanelVisibilityChanged,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  context,
                  "Reset Diff Width",
                  const _ResetDiffWidthButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    Widget trailing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13)),
        trailing,
      ],
    );
  }
}

class _ThemeModeDropdown extends StatelessWidget {
  const _ThemeModeDropdown();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((SettingsProvider s) => s.themeMode);

    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  themeMode.name[0].toUpperCase() + themeMode.name.substring(1),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 14),
              ],
            ),
          ),
        );
      },
      menuChildren: ThemeModeOption.values.map((mode) {
        return MenuItemButton(
          onPressed: () => context.read<SettingsProvider>().setThemeMode(mode),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  mode == themeMode ? Icons.check : null,
                  size: 14,
                  color: AppColors.primary,
                ),
                SizedBox(width: mode == themeMode ? 8 : 22),
                Text(
                  mode.name[0].toUpperCase() + mode.name.substring(1),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DiffPanelSwitch extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool>? onChanged;

  const _DiffPanelSwitch({this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final providerValue = context.select(
      (SettingsProvider s) => s.isDiffPanelVisible,
    );
    final isVisible = value ?? providerValue;

    return Switch(
      value: isVisible,
      onChanged: (nextValue) {
        if (onChanged != null) {
          onChanged!(nextValue);
        } else {
          context.read<SettingsProvider>().setDiffPanelVisible(nextValue);
        }
      },
      activeThumbColor: AppColors.primary,
    );
  }
}

class _ResetDiffWidthButton extends StatelessWidget {
  const _ResetDiffWidthButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final width = context.read<SettingsProvider>().diffPanelWidth;
        context.read<SettingsProvider>().updateDiffPanelWidth(450.0 - width);
      },
      child: const Text("450px", style: TextStyle(fontSize: 12)),
    );
  }
}
