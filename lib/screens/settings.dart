import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../providers/theme_provider.dart';
import '../providers/loading_animation_provider.dart';
import '../utils/loading_animation_style.dart';
import '../widgets/app_loading_widget.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_select.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SettingsContent();
  }
}

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LoadingAnimationProvider>(
      builder: (context, themeProvider, loadingProvider, child) {
        final effectiveDark = themeProvider.isDark(context);

        // Ensure loading animation provider is initialized
        if (!loadingProvider.initialized) {
          loadingProvider.initialize();
        }

        return FScaffold(
          // header: const FHeader(title: Text('Settings')),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reset Button Header using Forui button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Reset',
                      leading: const Icon(FIcons.refreshCw),
                      onPressed: () => _showResetAllDialog(context),
                      style: FButtonStyle.destructive(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Theme Settings Section
                _buildThemeSettingsCard(context, themeProvider, effectiveDark),
                const SizedBox(height: 12),

                // Loading Animation Settings Section
                _buildLoadingAnimationCard(context, loadingProvider),
                const SizedBox(height: 12),

                // App Information Section
                _buildAppInfoCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSettingsCard(
    BuildContext context,
    ThemeProvider themeProvider,
    bool effectiveDark,
  ) {
    final ftheme = FTheme.of(context);

    return FCard(
      title: const Text('Theme Settings'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (FCard already displays the section title)

            // Current Theme Display (use surface/background from Forui)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ftheme.colors.background, // rely on Forui background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ftheme.colors.border.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ftheme.colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      effectiveDark ? FIcons.moon : FIcons.sun,
                      color: ftheme.colors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveDark
                              ? 'Dark Mode Active'
                              : 'Light Mode Active',
                          style: ftheme.typography.base.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ftheme.colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          effectiveDark
                              ? 'Dark colors are currently in use'
                              : 'Light colors are currently in use',
                          style: ftheme.typography.sm.copyWith(
                            color: ftheme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FSwitch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChange: (value) => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
            if (themeProvider.themeMode != ThemeMode.light) ...[
              const SizedBox(height: 12),
              Center(
                child: AppButton(
                  label: 'Use System Theme',
                  onPressed: () => themeProvider.setSystemTheme(),
                  style: FButtonStyle.ghost(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingAnimationCard(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    // Use FCard title for section header; no local Forui theme needed here.

    return FCard(
      title: const Text('Loading Animation'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPreviewCard(context, provider),
            const SizedBox(height: 8),

            // Color Settings
            _buildAnimationStylesSection(context, provider),
            const SizedBox(height: 8),

            // Animation Styles
            _buildColorSettingsSection(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPreviewCard(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final ftheme = FTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ftheme.colors.background.withValues(alpha: 0.06),
            ftheme.colors.background.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ftheme.colors.border.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const AppLoadingWidget.large(),
          const SizedBox(height: 12),
          Text(
            provider.currentStyle.displayName,
            style: ftheme.typography.lg.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            provider.currentStyle.description,
            style: ftheme.typography.sm.copyWith(
              color: ftheme.colors.primaryForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSettingsSection(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final ftheme = FTheme.of(context);

    return Column(
      children: [
        FTileGroup(
          children: [
            FTile(
              prefix: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ftheme.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  provider.useThemeColor ? FIcons.brush : FIcons.brushCleaning,
                  color: ftheme.colors.primary,
                  size: 20,
                ),
              ),
              title: const Text('Use Theme Color'),
              subtitle: const Text(
                'Use the app\'s primary color for animations',
              ),
              suffix: FSwitch(
                value: provider.useThemeColor,
                onChange: (value) => provider.updateUseThemeColor(value),
              ),
            ),
          ],
        ),
        if (!provider.useThemeColor) ...[
          const SizedBox(height: 8),
          FTileGroup(
            children: [
              FTile(
                prefix: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(provider.customColorValue),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ftheme.colors.border.withValues(alpha: 0.18),
                      width: 2,
                    ),
                  ),
                ),
                title: const Text('Custom Color'),
                subtitle: const Text('Tap to choose a custom color'),
                suffix: Icon(FIcons.pen, color: ftheme.colors.primary),
                onPress: () => _showColorPicker(context, provider),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAnimationStylesSection(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    return AppSelect(
      label: const Text('Animation Style'),
      itemsList: LoadingAnimationStyle.values
          .map((s) => s.displayName)
          .toList(),
      value: provider.currentStyle.displayName,
      hint: 'Select animation style',
      onChanged: (selected) {
        if (selected == null) return;
        final match = LoadingAnimationStyle.values.firstWhere(
          (s) => s.displayName == selected,
          orElse: () => provider.currentStyle,
        );
        provider.updateStyle(match);
      },
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    final ftheme = FTheme.of(context);

    return FCard(
      title: const Text('App Information'),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            _buildInfoRow(
              context,
              icon: FIcons.smartphone,
              title: 'Version',
              value: '1.0.0',
              color: ftheme.colors.primary,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              icon: FIcons.code,
              title: 'Build',
              value: 'Release',
              color: ftheme.colors.primary,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              icon: FIcons.heartPulse,
              title: 'Platform',
              value: 'MediChat Flutter',
              color: ftheme.colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // Section header helper removed - FCard already provides a title area

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = FTheme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showColorPicker(
    BuildContext context,
    LoadingAnimationProvider provider,
  ) {
    final predefinedColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepPurple,
      Colors.brown,
    ];

    showFDialog(
      context: context,
      builder: (ctx, style, animation) {
        final ftheme = FTheme.of(ctx);
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FDialog(
            style: style.call,
            animation: animation,
            direction: Axis.horizontal,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ftheme.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(FIcons.listFilter, color: ftheme.colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose Color',
                    style: ftheme.typography.lg.copyWith(
                      color: ftheme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(ctx).pop(),
                  child: const Icon(FIcons.x),
                ),
              ],
            ),
            body: SizedBox(
              width: 300,
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: predefinedColors.length,
                itemBuilder: (context, index) {
                  final color = predefinedColors[index];
                  final isSelected = color.value == provider.customColorValue;

                  return FButton(
                    style: FButtonStyle.ghost(),
                    onPress: () {
                      provider.updateCustomColor(color.value);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? ftheme.colors.primaryForeground
                              : ftheme.colors.border.withValues(alpha: 0.22),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              FIcons.check,
                              color: ftheme.colors.primaryForeground,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            actions: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetAllDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (ctx, style, animation) {
        final ftheme = FTheme.of(ctx);
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FDialog(
            style: style.call,
            animation: animation,
            direction: Axis.horizontal,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ftheme.colors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FIcons.shieldAlert,
                    color: ftheme.colors.destructive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reset All Settings',
                    style: ftheme.typography.lg.copyWith(
                      color: ftheme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(ctx).pop(),
                  child: const Icon(FIcons.x),
                ),
              ],
            ),
            body: Text(
              'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
              style: ftheme.typography.base.copyWith(
                color: ftheme.colors.foreground,
              ),
            ),
            actions: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FButton(
                style: FButtonStyle.destructive(),
                onPress: () {
                  // Reset theme to light
                  context.read<ThemeProvider>().setThemeMode(ThemeMode.light);

                  // Reset loading animation settings
                  context.read<LoadingAnimationProvider>().resetToDefaults();

                  Navigator.of(ctx).pop();

                  // Show success feedback using ForUI themed snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            FIcons.check,
                            color: ftheme.colors.primaryForeground,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All settings have been reset to defaults',
                            style: ftheme.typography.sm.copyWith(
                              color: ftheme.colors.primaryForeground,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: ftheme.colors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
        );
      },
    );
  }
}
