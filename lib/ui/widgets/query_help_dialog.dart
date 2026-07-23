import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QueryExampleCategory {
  final String categoryName;
  final IconData icon;
  final List<QueryExampleItem> items;

  const QueryExampleCategory({
    required this.categoryName,
    required this.icon,
    required this.items,
  });
}

class QueryExampleItem {
  final String title;
  final String description;
  final String exampleQuery;

  const QueryExampleItem({
    required this.title,
    required this.description,
    required this.exampleQuery,
  });
}

class QueryHelpDialog extends StatelessWidget {
  final ValueChanged<String> onReplaceQuery;
  final ValueChanged<String> onAppendQuery;

  const QueryHelpDialog({
    super.key,
    required this.onReplaceQuery,
    required this.onAppendQuery,
  });

  static const List<QueryExampleCategory> categories = [
    QueryExampleCategory(
      categoryName: 'Equality & Comparison',
      icon: Icons.compare_arrows_rounded,
      items: [
        QueryExampleItem(
          title: 'Equal To (==)',
          description: 'Matches documents where field equals value.',
          exampleQuery: "WHERE status == 'active'",
        ),
        QueryExampleItem(
          title: 'Not Equal To (!=)',
          description: 'Matches documents where field does not equal value.',
          exampleQuery: "WHERE category != 'archived'",
        ),
        QueryExampleItem(
          title: 'Greater Than (>)',
          description: 'Matches fields strictly greater than number/date.',
          exampleQuery: 'WHERE price > 100',
        ),
        QueryExampleItem(
          title: 'Greater Than or Equal (>=)',
          description: 'Matches fields greater than or equal to value.',
          exampleQuery: 'WHERE age >= 18',
        ),
        QueryExampleItem(
          title: 'Less Than (<)',
          description: 'Matches fields strictly less than value.',
          exampleQuery: 'WHERE rating < 4.0',
        ),
        QueryExampleItem(
          title: 'Less Than or Equal (<=)',
          description: 'Matches fields less than or equal to value.',
          exampleQuery: 'WHERE stock <= 10',
        ),
      ],
    ),
    QueryExampleCategory(
      categoryName: 'Array & Membership Operators',
      icon: Icons.checklist_rounded,
      items: [
        QueryExampleItem(
          title: 'Array Contains (array-contains)',
          description: 'Matches documents where array field contains specific element.',
          exampleQuery: "WHERE tags array-contains 'flutter'",
        ),
        QueryExampleItem(
          title: 'In Array (in)',
          description: 'Matches documents where field equals any element in array.',
          exampleQuery: "WHERE role in ['admin', 'editor', 'owner']",
        ),
        QueryExampleItem(
          title: 'Not In Array (not-in)',
          description: 'Matches documents where field does not equal any element in array.',
          exampleQuery: "WHERE status not-in ['banned', 'deleted']",
        ),
        QueryExampleItem(
          title: 'Array Contains Any (array-contains-any)',
          description: 'Matches documents where array field contains any element in array.',
          exampleQuery: "WHERE categories array-contains-any ['news', 'sports']",
        ),
      ],
    ),
    QueryExampleCategory(
      categoryName: 'Compound Logical Queries',
      icon: Icons.alt_route_rounded,
      items: [
        QueryExampleItem(
          title: 'Multiple AND Filters',
          description: 'Combine multiple WHERE filters using AND operator.',
          exampleQuery: "WHERE category == 'electronics' AND price >= 200 AND rating >= 4.5",
        ),
      ],
    ),
    QueryExampleCategory(
      categoryName: 'Sorting & Pagination',
      icon: Icons.sort_rounded,
      items: [
        QueryExampleItem(
          title: 'Order By Ascending',
          description: 'Sort results by field in ascending order (A-Z, 0-9).',
          exampleQuery: 'ORDER BY createdAt ASC',
        ),
        QueryExampleItem(
          title: 'Order By Descending',
          description: 'Sort results by field in descending order (Z-A, 9-0).',
          exampleQuery: 'ORDER BY score DESC',
        ),
        QueryExampleItem(
          title: 'Compound Ordering',
          description: 'Sort by primary field then secondary field.',
          exampleQuery: 'ORDER BY status ASC, createdAt DESC',
        ),
        QueryExampleItem(
          title: 'Limit Results',
          description: 'Restrict total documents fetched in query response.',
          exampleQuery: 'LIMIT 50',
        ),
        QueryExampleItem(
          title: 'Full Query Example',
          description: 'Complete query combining WHERE, ORDER BY, and LIMIT.',
          exampleQuery: "WHERE isVerified == true ORDER BY joinDate DESC LIMIT 25",
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      child: Container(
        width: 680,
        height: 540,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: AppColors.accentBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Firestore Query Guide & Examples',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Click "+ Append" to append to your active query or "Replace" to overwrite it.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Categories & Examples List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: categories.length,
                itemBuilder: (context, catIndex) {
                  final category = categories[catIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(category.icon, size: 16, color: AppColors.firebaseGold),
                            const SizedBox(width: 8),
                            Text(
                              category.categoryName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.firebaseGold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Items
                      ...category.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.exampleQuery,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: AppColors.firebaseGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentBlue,
                                  side: const BorderSide(color: AppColors.accentBlue),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('+ Append', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  onAppendQuery(item.exampleQuery);
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: const Icon(Icons.swap_horiz, size: 14),
                                label: const Text('Replace', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  onReplaceQuery(item.exampleQuery);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
