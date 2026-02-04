import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:musicapp/pages/search_result_screen.dart';
import 'package:musicapp/provider/search_provider.dart';
import 'package:musicapp/utils/slide_route.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _onChanged(String value) {
    // setState isliye taake UI rebuild ho aur 'isQueryEmpty' update ho
    setState(() {});
    ref.read(searchProvider.notifier).fetchSuggestions(value);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    ref.read(searchProvider.notifier).clearSuggestions();

    // Save current query to controller if triggered by tap
    if (_searchController.text != query) {
      _searchController.text = query;
    }

    Navigator.push(
      context,
      SlideRightToLeftRoute(page: SearchResultScreen(searchQuery: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    final isQueryEmpty = _searchController.text.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: TextField(
            controller: _searchController,
            style: theme.textTheme.bodyLarge,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: "What do you want to play?",
              hintStyle: TextStyle(color: theme.hintColor),
              border: InputBorder.none,
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.r),
                borderSide: BorderSide.none,
              ),
              suffixIcon: !isQueryEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: theme.iconTheme.color),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        ref.read(searchProvider.notifier).clearSuggestions();
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: isQueryEmpty
          ? _buildHistoryAndViral(context, searchState.history, theme)
          : _buildSuggestionsList(searchState.suggestions, theme),
    );
  }

  // --- New Widget: History & Viral Tags ---
  Widget _buildHistoryAndViral(
    BuildContext context,
    List<String> history,
    ThemeData theme,
  ) {
    // Static list of Viral/Trending topics
    final viralTags = [
      "Trending Now",
      "Lo-fi Beats",
      "Coke Studio",
      "Arijit Singh",
      "New Releases",
      "90s Hits",
      "Punjabi Pop",
      "Sleep Music",
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Recent Searches (Show only if history exists)
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Searches",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(searchProvider.notifier).clearHistory(),
                  child: Text(
                    "Clear All",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            ...history.map(
              (term) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(term, style: theme.textTheme.bodyLarge),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () =>
                      ref.read(searchProvider.notifier).removeFromHistory(term),
                ),
                onTap: () => _performSearch(term),
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // 2. Viral Suggestions
          Text(
            "Try Searching",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: viralTags
                .map(
                  (term) => ActionChip(
                    label: Text(term),
                    backgroundColor: theme.cardColor,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _performSearch(term),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- Existing Suggestions List ---
  // --- Updated Suggestions List with Highlighted Keyword ---
  Widget _buildSuggestionsList(List<String> suggestions, ThemeData theme) {
    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          "Searching...",
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    // Get the current search query
    final query = _searchController.text;

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Colors.grey),
          // Use RichText to highlight the matching part
          title: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge,
              children: _getHighlightedText(suggestion, query, theme),
            ),
          ),
          onTap: () => _performSearch(suggestion),
        );
      },
    );
  }

  // --- Helper Function to Highlight Matching Text ---
  List<TextSpan> _getHighlightedText(
    String text,
    String query,
    ThemeData theme,
  ) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      // Find the index of the query in the suggestion text
      int index = lowerText.indexOf(lowerQuery, start);

      // If no match found, add the remaining text and break
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      // Add the text before the match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add the matched text with a specific style (e.g., Bold or Primary Color)
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor, // Optional: Change color if desired
          ),
        ),
      );

      // Move the start position forward
      start = index + query.length;
    }

    return spans;
  }
}
