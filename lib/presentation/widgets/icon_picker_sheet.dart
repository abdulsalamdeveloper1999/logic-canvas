import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:logic_canvas/core/free_plan.dart';

class IconPickerSheet extends StatefulWidget {
  final bool isPro;
  final String? selectedIconPath;
  final ValueChanged<String> onIconSelected;

  const IconPickerSheet({
    super.key,
    required this.isPro,
    this.selectedIconPath,
    required this.onIconSelected,
  });

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Grouped icons (Expanded)
  final Map<String, List<String>> _allIcons = {
    'aws-icons': [
      "aws-lambda.svg", "aws-ec2.svg", "aws-simple-storage-service.svg", "aws-dynamodb.svg",
      "aws-api-gateway.svg", "aws-identity-and-access-management.svg", "aws-cloudwatch.svg", "aws-rds.svg",
      "aws-app-mesh.svg", "aws-app-runner.svg", "aws-athena.svg", "aws-batch.svg", "aws-bedrock.svg",
      "aws-billing-conductor.svg", "aws-blockchain.svg", "aws-cloud-control-api.svg", "aws-iam-identity-center.svg"
    ],
    'azure-icons': [
      "azure-virtual-machine.svg", "azure-function-apps.svg", "azure-cosmos-db.svg", "azure-active-directory.svg",
      "azure-sql-database.svg", "azure-storage-accounts.svg", "azure-virtual-networks.svg", "azure-app-services.svg",
      "azure-language-services.svg", "azure-logic-apps.svg", "azure-machine-learning.svg", "azure-monitor.svg"
    ],
    'gcp-icons': [
      "gcp-compute-engine.svg", "gcp-cloud-functions.svg", "gcp-cloud-storage.svg", "gcp-bigquery.svg",
      "gcp-cloud-run.svg", "gcp-cloud-sql.svg", "gcp-identity-and-access-management.svg", "gcp-pubsub.svg",
      "gcp-artifact-registry.svg", "gcp-cloud-build.svg", "gcp-cloud-dns.svg", "gcp-datastore.svg"
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isPro ? 4 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredIcons(String category) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
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
                      const Icon(Icons.category_rounded, color: Colors.blueAccent),
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.isPro
                          ? "Search 1,200+ icons..."
                          : "Search basic icons (Pro unlocks full library)...",
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.blueAccent),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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
                  tabs: widget.isPro
                      ? const [
                          Tab(text: "ALL"),
                          Tab(text: "AWS"),
                          Tab(text: "AZURE"),
                          Tab(text: "GCP"),
                        ]
                      : const [
                          Tab(text: "BASIC"),
                        ],
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  indicatorColor: Colors.blueAccent,
                  indicatorWeight: 3,
                  dividerColor: Colors.white.withValues(alpha: 0.05),
                ),

                // Icon Grid
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: widget.isPro
                        ? [
                            _buildGrid("all"),
                            _buildGrid("aws-icons"),
                            _buildGrid("azure-icons"),
                            _buildGrid("gcp-icons"),
                          ]
                        : [
                            _buildGrid("basic"),
                          ],
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
    final icons = _getFilteredIcons(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (icons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              "No matches for \"$_searchQuery\"",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
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
              color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    iconName.split('.').first.replaceAll('aws-', '').replaceAll('azure-', '').replaceAll('gcp-', '').toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8, // Reduced from 9
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      color: isSelected ? Colors.blueAccent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
