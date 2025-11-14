import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import '../providers/patient_provider.dart';
import '../providers/case_provider.dart';
import '../widgets/case_card.dart';
import '../widgets/edit_case.dart';
import '../utils/token_expiration_handler.dart';
import '../widgets/app_loading_widget.dart';
import '../widgets/ui/app_floating_action_button.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});
  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with TokenExpirationHandler {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'Title A-Z';
  final List<String> _filterOptions = [
    'All',
    'High Priority',
    'Medium Priority',
    'Low Priority',
    'Recent',
    'Older',
  ];
  final List<String> _sortOptions = [
    'Title A-Z',
    'Title Z-A',
    'Recently Added',
    'Oldest First',
    'High Priority First',
    'Low Priority First',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().refresh(widget.patientId);
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

  List<dynamic> _getFilteredCases(List<dynamic> cases) {
    // Create a mutable copy of the list
    List<dynamic> filtered = List<dynamic>.from(cases);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((medicalCase) {
        final title = medicalCase.title?.toLowerCase() ?? '';
        final description = medicalCase.description?.toLowerCase() ?? '';
        final priority = medicalCase.priority?.toLowerCase() ?? '';
        final tags = medicalCase.tags?.join(' ').toLowerCase() ?? '';

        return title.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            priority.contains(_searchQuery) ||
            tags.contains(_searchQuery);
      }).toList();
    }

    // Apply category filter
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'High Priority':
          filtered = filtered
              .where((c) => c.priority?.toLowerCase() == 'high')
              .toList();
          break;
        case 'Medium Priority':
          filtered = filtered
              .where((c) => c.priority?.toLowerCase() == 'medium')
              .toList();
          break;
        case 'Low Priority':
          filtered = filtered
              .where((c) => c.priority?.toLowerCase() == 'low')
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
          filtered = List<dynamic>.from(filtered);
          filtered.sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );
          filtered = filtered.take(10).toList();
          break;
      }
    }

    // Ensure we have a mutable list before sorting
    filtered = List<dynamic>.from(filtered);

    // Apply sorting
    switch (_sortBy) {
      case 'Title A-Z':
        filtered.sort(
          (a, b) => (a.title ?? '').toLowerCase().compareTo(
            (b.title ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Title Z-A':
        filtered.sort(
          (a, b) => (b.title ?? '').toLowerCase().compareTo(
            (a.title ?? '').toLowerCase(),
          ),
        );
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
      case 'High Priority First':
        filtered.sort((a, b) {
          final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
          final aPriority = priorityOrder[a.priority?.toLowerCase()] ?? 0;
          final bPriority = priorityOrder[b.priority?.toLowerCase()] ?? 0;
          return bPriority.compareTo(aPriority);
        });
        break;
      case 'Low Priority First':
        filtered.sort((a, b) {
          final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
          final aPriority = priorityOrder[a.priority?.toLowerCase()] ?? 0;
          final bPriority = priorityOrder[b.priority?.toLowerCase()] ?? 0;
          return aPriority.compareTo(bPriority);
        });
        break;
    }

    return filtered;
  }

  Future<void> _editCase(
    BuildContext context,
    dynamic medicalCase,
    CaseProvider caseProvider,
  ) async {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final result = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: EditCaseDialog(
          medicalCase: medicalCase,
          caseProvider: caseProvider,
        ),
      ),
    );

    // Refresh the list if the case was updated
    if (result == true) {
      // The provider will already notify listeners, so no need to do anything else
    }
  }

  Future<void> _refreshCases() async {
    final caseProv = context.read<CaseProvider>();
    await safeApiCall(
      () => caseProv.refresh(widget.patientId),
      errorMessage: 'Failed to refresh cases',
    );
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
    final patient = context.select<PatientProvider, dynamic>(
      (prov) => prov.patients.firstWhere((p) => p.id == widget.patientId),
    );
    final caseProv = context.watch<CaseProvider>();
    final cases = caseProv.casesFor(widget.patientId);
    final filteredCases = _getFilteredCases(cases);

    Widget buildCases() {
      if (caseProv.isLoading(widget.patientId)) {
        return const Center(child: AppLoadingWidget.large());
      }
      if (cases.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FIcons.fileText, size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No cases yet'),
              const SizedBox(height: 8),
              const Text(
                'Add a case using the + button',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

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
                  'Medical Cases for ${patient.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage medical cases, track symptoms, treatments, and progress. Use search to quickly find specific cases.',
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
                            hintStyle: TextStyle(
                              fontFamily: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.fontFamily,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.4),
                            ),
                            hintText:
                                'Search cases by title, description, priority, or tags...',
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
                                fontFamily: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.fontFamily,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Results count
                if (filteredCases.length != cases.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Showing ${filteredCases.length} of ${cases.length} cases',
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

          // Cases list
          Expanded(
            child: filteredCases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty || _selectedFilter != 'All'
                              ? FIcons.search
                              : FIcons.fileText,
                          size: 72,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != 'All'
                              ? 'No cases found'
                              : 'No cases yet',
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
                    onRefresh: () => safeApiCall(
                      () => caseProv.refresh(widget.patientId),
                      errorMessage: 'Failed to refresh cases',
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredCases.length,
                      itemBuilder: (context, index) {
                        final medicalCase = filteredCases[index];
                        return CaseCard(
                          medicalCase: medicalCase,
                          patientId: widget.patientId,
                          onEdit: () =>
                              _editCase(context, medicalCase, caseProv),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    return FScaffold(
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // Ensure we navigate to the patients tab on the dashboard
                  context.go('/?tab=0');
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(FIcons.arrowLeft),
              ),
            ),
            Flexible(
              child: Text(patient.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        suffixes: [
          FHeaderAction(icon: Icon(FIcons.refreshCw), onPress: _refreshCases),
        ],
      ),
      child: Stack(
        children: [
          // main body content
          Positioned.fill(child: buildCases()),
          // floating action
          Positioned(
            right: 16,
            bottom: WidgetsBinding.instance.window.viewInsets.bottom + 20,
            child: AppFloatingActionButton(
              icon: FIcons.bookmarkPlus,
              label: 'Add Case',
              tooltip: 'Add New Medical Case',
              onPressed: () =>
                  context.push('/patients/${widget.patientId}/add-case'),
            ),
          ),
        ],
      ),
    );
  }
}
