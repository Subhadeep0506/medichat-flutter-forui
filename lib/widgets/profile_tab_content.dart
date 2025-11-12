import 'package:MediChat/widgets/ui/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../utils/api_error_handler.dart';
import '../services/toast_service.dart';
import 'app_loading_widget.dart';

class ProfileTabContent extends StatefulWidget {
  const ProfileTabContent({super.key});

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final userProvider = context.read<UserProvider>();
    await ApiErrorHandler.safeApiCall(
      context,
      () => userProvider.fetchProfile(),
      errorMessage: 'Failed to load profile',
    );
  }

  void _showEditDialog(String field, String? currentValue) {
    final controller = TextEditingController(text: currentValue ?? '');
    final userProvider = context.read<UserProvider>();

    String title;
    String hintText;
    IconData icon;
    String description;

    switch (field) {
      case 'name':
        title = 'Edit Name';
        description = 'Update your display name';
        hintText = 'Enter your full name';
        icon = FIcons.user;
        break;
      case 'email':
        title = 'Edit Email';
        description = 'Update your email address';
        hintText = 'Enter your email address';
        icon = FIcons.mail;
        break;
      case 'phone':
        title = 'Edit Phone';
        description = 'Update your phone number';
        hintText = 'Enter your phone number';
        icon = FIcons.phoneCall;
        break;
      default:
        return;
    }

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
                    color: ftheme.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: ftheme.colors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ftheme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ftheme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: ftheme.typography.base.copyWith(
                          color: ftheme.colors.mutedForeground,
                        ),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(ctx).pop(),
                  child: const Icon(FIcons.x),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentValue != null && currentValue.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ftheme.colors.background.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ftheme.colors.border.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FIcons.info,
                          color: ftheme.colors.primary.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current: $currentValue',
                          style: ftheme.typography.base.copyWith(
                            color: ftheme.colors.mutedForeground,
                            fontSize: 12,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: controller,
                  hintText: hintText,
                  label: Text(title.replaceAll('Edit ', '')),
                  keyboardType: field == 'email'
                      ? TextInputType.emailAddress
                      : field == 'phone'
                      ? TextInputType.phone
                      : TextInputType.text,
                  prefixIcon: Icon(
                    icon,
                    color: ftheme.colors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(),
                style: FButtonStyle.ghost(),
              ),
              _SaveButton(
                controller: controller,
                currentValue: currentValue,
                field: field,
                userProvider: userProvider,
                onSaveComplete: () async {
                  Navigator.of(ctx).pop();
                  await _loadProfile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ftheme = FTheme.of(context);
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: AppLoadingWidget.large());
        }
        final user = userProvider.user ?? authProvider.user;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FIcons.userPen,
                  size: 64,
                  color: ftheme.colors.mutedForeground,
                ),
                const SizedBox(height: 16),
                Text(
                  'No user data available',
                  style: ftheme.typography.lg.copyWith(
                    color: ftheme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(label: 'Try Again', onPressed: _loadProfile),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Profile Header Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: ftheme.colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (user.name?.isNotEmpty == true
                                        ? user.name!.substring(0, 1)
                                        : user.email.substring(0, 1))
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name ?? user.email.split('@').first,
                                  style: ftheme.typography.lg.copyWith(
                                    color: ftheme.colors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ftheme.colors.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role ?? 'User',
                                    style: ftheme.typography.sm.copyWith(
                                      color: ftheme.colors.primaryForeground,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Modern Profile Details Card (use ForUI)
                  FCard.raw(
                    child: Column(
                      children: [
                        _buildModernListTile(
                          context,
                          icon: FIcons.user,
                          title: user.name ?? 'Not specified',
                          subtitle: 'Full Name',
                          color: Colors.blue,
                          onTap: () => _showEditDialog('name', user.name),
                          isEditable: true,
                        ),
                        _buildDivider(),
                        _buildModernListTile(
                          context,
                          icon: FIcons.messageSquareX,
                          title: user.email,
                          subtitle: 'Email Address',
                          color: Colors.green,
                          onTap: () => _showEditDialog('email', user.email),
                          isEditable: true,
                        ),
                        _buildDivider(),
                        _buildModernListTile(
                          context,
                          icon: FIcons.phone,
                          title: user.phone ?? 'Not specified',
                          subtitle: 'Phone Number',
                          color: Colors.orange,
                          onTap: () => _showEditDialog('phone', user.phone),
                          isEditable: true,
                        ),
                        _buildDivider(),
                        _buildModernListTile(
                          context,
                          icon: FIcons.shieldUser,
                          title: user.role ?? 'User',
                          subtitle: 'Account Role',
                          color: Colors.purple,
                          isEditable: false,
                        ),
                        if (user.createdAt != null) ...[
                          _buildDivider(),
                          _buildModernListTile(
                            context,
                            icon: FIcons.calendar,
                            title: user.createdAt!.toLocal().toString().split(
                              '.',
                            )[0],
                            subtitle: 'Member Since',
                            color: Colors.indigo,
                            isEditable: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (userProvider.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ftheme.colors.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ftheme.colors.destructive.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ftheme.colors.destructive.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              FIcons.triangleAlert,
                              color: ftheme.colors.destructive,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Modern Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: "Logout",
                      leading: Icon(
                        FIcons.logOut,
                        color: ftheme.colors.destructiveForeground,
                      ),
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              try {
                                await authProvider.logout();
                                if (mounted) context.go('/login');
                              } catch (_) {}
                            },
                      style: FButtonStyle.destructive(),
                      isLoading: authProvider.isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    required bool isEditable,
  }) {
    final ftheme = FTheme.of(context);

    return FItem(
      onPress: onTap,
      prefix: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: ftheme.typography.base.copyWith(
          fontWeight: FontWeight.w600,
          color: ftheme.colors.foreground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: ftheme.typography.sm.copyWith(
          color: ftheme.colors.mutedForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
      suffix: isEditable
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ftheme.colors.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FIcons.pencil,
                size: 16,
                color: ftheme.colors.mutedForeground,
              ),
            )
          : null,
    );
  }

  Widget _buildDivider() {
    final ftheme = FTheme.of(context);
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            ftheme.colors.border.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final TextEditingController controller;
  final String? currentValue;
  final String field;
  final UserProvider userProvider;
  final VoidCallback onSaveComplete;

  const _SaveButton({
    required this.controller,
    required this.currentValue,
    required this.field,
    required this.userProvider,
    required this.onSaveComplete,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: isLoading ? 'Saving...' : 'Save Changes',
      onPressed: isLoading ? null : _handleSave,
      leading: isLoading ? const AppLoadingWidget.small() : null,
      isLoading: isLoading,
    );
  }

  Future<void> _handleSave() async {
    final value = widget.controller.text.trim();

    if (value == widget.currentValue) {
      widget.onSaveComplete();
      return;
    }

    setState(() => isLoading = true);

    try {
      switch (widget.field) {
        case 'name':
          await ApiErrorHandler.safeApiCall(
            context,
            () => widget.userProvider.updateProfile(name: value),
            errorMessage: 'Failed to update name',
          );
          break;
        case 'email':
          await ApiErrorHandler.safeApiCall(
            context,
            () => widget.userProvider.updateProfile(email: value),
            errorMessage: 'Failed to update email',
          );
          break;
        case 'phone':
          await ApiErrorHandler.safeApiCall(
            context,
            () => widget.userProvider.updateProfile(
              phone: value.isEmpty ? null : value,
            ),
            errorMessage: 'Failed to update phone',
          );
          break;
      }

      if (mounted) {
        ToastService.showSuccess(
          'Profile updated successfully',
          context: context,
        );
        widget.onSaveComplete();
      }
    } catch (e) {
      // Error already handled by ApiErrorHandler
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
