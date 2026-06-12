import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:logic_canvas/core/free_plan.dart';

class IconPickerSheet extends StatefulWidget {
  final bool isSubscribed;
  final String? selectedIconPath;
  final ValueChanged<String> onIconSelected;

  const IconPickerSheet({
    super.key,
    required this.isSubscribed,
    this.selectedIconPath,
    required this.onIconSelected,
  });

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  // String _searchQuery = "";
  String _searchQuery = "";

  // Pagination
  int _displayedCount = 60;
  static const int _pageSize = 40;

  // Grouped icons (Discovered dynamically)
  Map<String, List<String>> _allIcons = {
    'aws-icons': [],
    'azure-icons': [],
    'gcp-icons': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isSubscribed ? 4 : 1,
      vsync: this,
    );
    _tabController.addListener(_handleTabChange);
    _loadIcons();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _resetPagination();
    }
  }

  void _loadMore() {
    final totalAvailable = _getFilteredIcons(_getCurrentCategory()).length;
    if (_displayedCount < totalAvailable) {
      setState(() {
        _displayedCount += _pageSize;
      });
    }
  }

  void _resetPagination() {
    setState(() {
      _displayedCount = 60;
    });
  }

  String _getCurrentCategory() {
    if (!widget.isSubscribed) return 'basic';
    switch (_tabController.index) {
      case 0:
        return 'all';
      case 1:
        return 'aws-icons';
      case 2:
        return 'azure-icons';
      case 3:
        return 'gcp-icons';
      default:
        return 'all';
    }
  }

  Future<void> _loadIcons() async {
    try {
      // Use the modern AssetManifest API (Flutter 3.10+)
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      final List<String> assets = manifest.listAssets();

      final Map<String, List<String>> discoveredIcons = {
        'aws-icons': [],
        'azure-icons': [],
        'gcp-icons': [],
      };

      for (final String path in assets) {
        if (!path.endsWith('.svg')) continue;

        if (path.startsWith('assets/icons/aws-icons/')) {
          discoveredIcons['aws-icons']!.add(path.split('/').last);
        } else if (path.startsWith('assets/icons/azure-icons/')) {
          discoveredIcons['azure-icons']!.add(path.split('/').last);
        } else if (path.startsWith('assets/icons/gcp-icons/')) {
          discoveredIcons['gcp-icons']!.add(path.split('/').last);
        }
      }

      // Sort alphabetically for better UX
      discoveredIcons.forEach((key, list) => list.sort());

      if (mounted) {
        setState(() {
          _allIcons = discoveredIcons;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading assets: $e");
      // Fallback for older Flutter versions if AssetManifest fails
      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifest = json.decode(manifestJson);
        final Map<String, List<String>> fallbackIcons = {
          'aws-icons': [],
          'azure-icons': [],
          'gcp-icons': [],
        };
        for (final String path in manifest.keys) {
          if (!path.endsWith('.svg')) continue;
          if (path.startsWith('assets/icons/aws-icons/')) {
            fallbackIcons['aws-icons']!.add(path.split('/').last);
          } else if (path.startsWith('assets/icons/azure-icons/')) {
            fallbackIcons['azure-icons']!.add(path.split('/').last);
          } else if (path.startsWith('assets/icons/gcp-icons/')) {
            fallbackIcons['gcp-icons']!.add(path.split('/').last);
          }
        }
        if (mounted) {
          setState(() {
            _allIcons = fallbackIcons;
            _isLoading = false;
          });
        }
      } catch (innerE) {
        debugPrint("Fallback asset loading failed: $innerE");
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<String> _getFilteredIcons(String category) {
    if (_isLoading) return [];

    List<String> baseList;
    if (category == 'basic') {
      baseList = FreePlan.basicIconFileNames;
    } else if (category == 'all') {
      baseList = _allIcons.values.expand((e) => e).toList();
    } else {
      baseList = _allIcons[category] ?? [];
    }

    if (_searchQuery.isEmpty) return baseList;

    return baseList.where((icon) {
      return icon.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.category_rounded,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Asset Library",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _resetPagination();
                    },
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.isSubscribed
                          ? "Search 1,200+ icons..."
                          : "Search basic icons (Premium unlocks full library)...",
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: widget.isSubscribed
                      ? const [
                          Tab(text: "ALL"),
                          Tab(text: "AWS"),
                          Tab(text: "AZURE"),
                          Tab(text: "GCP"),
                        ]
                      : const [Tab(text: "BASIC")],
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                  indicatorColor: Colors.blueAccent,
                  indicatorWeight: 3,
                  dividerColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.05),
                ),

                // Icon Grid
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: widget.isSubscribed
                        ? [
                            _buildGrid("all"),
                            _buildGrid("aws-icons"),
                            _buildGrid("azure-icons"),
                            _buildGrid("gcp-icons"),
                          ]
                        : [_buildGrid("basic")],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(String category) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Text(
              "Loading assets...",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    final allIcons = _getFilteredIcons(category);
    final icons = allIcons.take(_displayedCount).toList();

    if (allIcons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              "No matches for \"$_searchQuery\"",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return true;
      },
      child: GridView.builder(
        key: PageStorageKey(category),
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final iconName = icons[index];
          String actualCategory = category;
          if (category == 'all' || category == 'basic') {
            if (iconName.startsWith('aws-')) {
              actualCategory = 'aws-icons';
            } else if (iconName.startsWith('azure-')) {
              actualCategory = 'azure-icons';
            } else if (iconName.startsWith('gcp-')) {
              actualCategory = 'gcp-icons';
            }
          }

          final path = "assets/icons/$actualCategory/$iconName";
          final isSelected = widget.selectedIconPath == path;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onIconSelected(path);
              Navigator.pop(context);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Transform.scale(
                        scale: 1 / 1.2, // reduce icon size by ~1.2x
                        child: SvgPicture.asset(path, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      iconName
                          .split('.')
                          .first
                          .replaceAll('aws-', '')
                          .replaceAll('azure-', '')
                          .replaceAll('gcp-', '')
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8, // Reduced from 9
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.blueAccent
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
