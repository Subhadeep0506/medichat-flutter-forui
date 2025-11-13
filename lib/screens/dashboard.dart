import 'package:MediChat/widgets/styled_icon_button.dart';
import 'package:MediChat/widgets/ui/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import '../services/toast_service.dart';
import '../providers/patient_provider.dart';
import '../widgets/patient_card.dart';
import '../components/edit_patient.dart';
import '../widgets/profile_tab_content.dart';
import '../utils/token_expiration_handler.dart';
import '../widgets/app_loading_widget.dart';
import '../utils/app_logger.dart';
import 'settings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TokenExpirationHandler {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Name A-Z';
  final List<String> _filterOptions = [
    'All',
    'Male',
    'Female',
    'Recent',
    'Older',
  ];
  final List<String> _sortOptions = [
    'Name A-Z',
    'Name Z-A',
    'Age (Low to High)',
    'Age (High to Low)',
    'Recently Added',
    'Oldest First',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final patientProvider = context.read<PatientProvider>();
      // Only refresh if we have no patients and not loading
      // Don't use safeApiCall here to avoid immediate token expiration checks
      if (!patientProvider.isLoading && patientProvider.patients.isEmpty) {
        try {
          patientProvider.refresh();
        } catch (e) {
          // Silently handle errors to avoid token expiration popups on dashboard load
          AppLogger.error('Failed to refresh patients: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<dynamic> _getFilteredPatients(List<dynamic> patients) {
    // Create a mutable copy of the list
    List<dynamic> filtered = List<dynamic>.from(patients);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        final name = patient.name?.toLowerCase() ?? '';
        final age = patient.age?.toString() ?? '';
        final gender = patient.gender?.toLowerCase() ?? '';
        final medicalHistory = patient.medicalHistory?.toLowerCase() ?? '';
        final tags = patient.tags?.join(' ').toLowerCase() ?? '';

        return name.contains(_searchQuery) ||
            age.contains(_searchQuery) ||
            gender.contains(_searchQuery) ||
            medicalHistory.contains(_searchQuery) ||
            tags.contains(_searchQuery);
      }).toList();
    }

    // Apply category filter
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Male':
          filtered = filtered
              .where((p) => p.gender?.toLowerCase() == 'male')
              .toList();
          break;
        case 'Female':
          filtered = filtered
              .where((p) => p.gender?.toLowerCase() == 'female')
              .toList();
          break;
        case 'Recent':
          filtered = List<dynamic>.from(filtered);
          filtered.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
          filtered = filtered.take(10).toList();
          break;
        case 'Older':
          filtered = filtered.where((p) => (p.age ?? 0) >= 60).toList();
          break;
      }
    }

    // Ensure we have a mutable list before sorting
    filtered = List<dynamic>.from(filtered);

    // Apply sorting
    switch (_sortBy) {
      case 'Name A-Z':
        filtered.sort(
          (a, b) => (a.name ?? '').toLowerCase().compareTo(
            (b.name ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Name Z-A':
        filtered.sort(
          (a, b) => (b.name ?? '').toLowerCase().compareTo(
            (a.name ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Age (Low to High)':
        filtered.sort((a, b) => (a.age ?? 0).compareTo(b.age ?? 0));
        break;
      case 'Age (High to Low)':
        filtered.sort((a, b) => (b.age ?? 0).compareTo(a.age ?? 0));
        break;
      case 'Recently Added':
        filtered.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
      case 'Oldest First':
        filtered.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );
        break;
    }

    return filtered;
  }

  Future<void> _editPatient(
    BuildContext context,
    dynamic patient,
    PatientProvider patientProvider,
  ) async {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final result = await showFDialog<dynamic>(
      context: context,
      builder: (ctx, style, animation) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: EditPatientDialog(
          patient: patient,
          patientProvider: patientProvider,
        ),
      ),
    );

    // Handle the result
    if (result == 'success') {
      // Success - refresh the list and show success message
      await handleTokenExpiration(() async {
        await patientProvider.refresh();
      });

      // Use post frame callback to ensure context is still valid
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            try {
              ToastService.showSuccess(
                'Patient information updated successfully!',
                context: context,
              );
            } catch (e) {
              // Keep an extra dialog fallback for safety
              if (context.mounted) {
                final maxHeight = MediaQuery.of(context).size.height * 0.7;
                showFDialog(
                  context: context,
                  builder: (ctx, style, animation) {
                    final ftheme = FTheme.of(ctx);
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
                                color: ftheme.colors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                FIcons.check,
                                color: ftheme.colors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Success',
                                style: ftheme.typography.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ftheme.colors.foreground,
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
                        body: const Text(
                          'Patient information updated successfully!',
                        ),
                        actions: [
                          FButton(
                            onPress: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            }
          }
        });
      }
    } else if (result is String && result.startsWith('error:')) {
      // Error occurred - show error message
      final errorMessage = result.substring(6); // Remove 'error:' prefix

      // Use post frame callback to ensure context is still valid
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            try {
              ToastService.showError(
                'Failed to update patient: $errorMessage',
                context: context,
              );
            } catch (e) {
              if (context.mounted) {
                final maxHeight = MediaQuery.of(context).size.height * 0.7;
                showFDialog(
                  context: context,
                  builder: (ctx, style, animation) {
                    final ftheme = FTheme.of(ctx);
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
                                color: ftheme.colors.destructive.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                FIcons.triangleAlert,
                                color: ftheme.colors.destructive,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Error',
                                style: ftheme.typography.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ftheme.colors.foreground,
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
                        body: Text('Failed to update patient: $errorMessage'),
                        actions: [
                          FButton(
                            onPress: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            }
          }
        });
      }
    }
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sort Options',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ..._sortOptions.map((option) {
                final isSelected = _sortBy == option;
                return ListTile(
                  leading: isSelected
                      ? Icon(
                          FIcons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const SizedBox(width: 24),
                  title: Text(option),
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();

    Widget buildPatients() {
      if (patientProvider.isLoading) {
        return const Center(child: AppLoadingWidget.large());
      }
      if (patientProvider.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FIcons.triangleAlert, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Failed to load patients',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  patientProvider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: "Retry",
                  onPressed: () async {
                    // Token refresh is already handled by _sendWithRetry in RemotePatientService
                    await patientProvider.refresh();
                  },
                  leading: Icon(FIcons.refreshCw),
                  padding: EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      }
      if (patientProvider.patients.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FIcons.users, size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No patients yet'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  // Token refresh is already handled by _sendWithRetry in RemotePatientService
                  await patientProvider.refresh();
                },
                icon: Icon(FIcons.refreshCw),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      final filteredPatients = _getFilteredPatients(patientProvider.patients);

      return Column(
        children: [
          // Descriptive header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and search through your patient records. View patient details, medical history, and cases.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar with sort button
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search patients by name, age, gender, or medical history...',
                            prefixIcon: Icon(FIcons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(FIcons.x),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort button
                    FButton.icon(
                      style: FButtonStyle.outline(),
                      onPress: () {
                        // Show sort options using a custom dialog or menu
                        _showSortMenu(context);
                      },
                      child: Icon(FIcons.arrowUpDown),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter badges
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = _selectedFilter == filter
                                  ? 'All'
                                  : filter;
                            });
                          },
                          child: FBadge(
                            style: isSelected
                                ? FBadgeStyle.primary()
                                : FBadgeStyle.secondary(),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Results count
                if (filteredPatients.length != patientProvider.patients.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${filteredPatients.length} of ${patientProvider.patients.length} patients',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Patient list
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty || _selectedFilter != 'All'
                              ? FIcons.search
                              : FIcons.users,
                          size: 72,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != 'All'
                              ? 'No patients found'
                              : 'No patients yet',
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => handleTokenExpiration(() async {
                      await patientProvider.refresh();
                    }),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        return PatientCard(
                          patient: patient,
                          onEdit: () =>
                              _editPatient(context, patient, patientProvider),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    final routeState = GoRouterState.of(context);
    final tabParam = routeState.uri.queryParameters['tab'];
    final parsed = int.tryParse(tabParam ?? '0');
    final currentIndex = (parsed != null && parsed >= 0 && parsed <= 2)
        ? parsed
        : 0;

    Widget body;
    switch (currentIndex) {
      case 0:
        body = buildPatients();
        break;
      case 1:
        body = const SettingsScreen();
        break;
      case 2:
        body = const ProfileTabContent();
        break;
      default:
        body = buildPatients();
    }
    String title;
    switch (currentIndex) {
      case 1:
        title = 'Settings';
        break;
      case 2:
        title = 'Profile';
        break;
      default:
        title = 'Patients';
    }

    return FScaffold(
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: Center(child: Text(title)),
        suffixes: [
          if (currentIndex == 0)
            FHeaderAction(
              icon: Icon(FIcons.refreshCw),
              onPress: () => handleTokenExpiration(() async {
                await patientProvider.refresh();
              }),
            ),
        ],
      ),
      footer: FBottomNavigationBar(
        index: currentIndex,
        onChange: (idx) {
          // Rebuild will pick up new tab from route, no state set needed
          context.go('/?tab=$idx');
        },
        children: [
          FBottomNavigationBarItem(
            icon: Icon(FIcons.users),
            label: const Text('Patients'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.settings),
            label: const Text('Settings'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.user),
            label: const Text('Profile'),
          ),
        ],
      ),
      child: Stack(
        children: [
          // main body content
          Positioned.fill(child: body),
          // floating action
          if (currentIndex == 0)
            Positioned(
              right: 16,
              bottom: WidgetsBinding.instance.window.viewInsets.bottom + 20,
              child: StyledFloatingActionButton(
                icon: FIcons.userPlus,
                onPressed: () => context.push('/add-patient'),
                tooltip: 'Add New Patient',
                label: "Add Patient",
              ),
            ),
        ],
      ),
    );
  }
}
