import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicapp/bloc/theme/theme_cubit.dart';

// Data Model - Ready for backend integration
class SearchResultModel {
  final String id;
  final String title;
  final String? artist;
  final String? imageUrl;

  SearchResultModel({
    required this.id,
    required this.title,
    this.artist,
    this.imageUrl,
  });

  // Factory constructor for JSON parsing (backend ready)
  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'],
      imageUrl: json['imageUrl'],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Load initial/recent searches
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // TODO: Replace with actual backend API call
  Future<void> _loadRecentSearches() async {
    // Mock recent searches - Replace with backend call
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _searchResults = [
        SearchResultModel(id: '1', title: 'Exed up'),
        SearchResultModel(id: '2', title: 'Afsanay'),
        SearchResultModel(id: '3', title: 'Dhundala'),
        SearchResultModel(id: '4', title: 'Thori si Daaru'),
        SearchResultModel(id: '5', title: 'Winnings Speech'),
        SearchResultModel(id: '6', title: 'Freak in Me'),
        SearchResultModel(id: '7', title: 'Out of my mine'),
        SearchResultModel(id: '8', title: 'So it Goes'),
        SearchResultModel(id: '9', title: 'Some Feelings'),
        SearchResultModel(id: '10', title: 'Cold Play'),
        SearchResultModel(id: '11', title: "I didn't Know"),
        SearchResultModel(id: '12', title: 'Cannon Ball'),
      ];
    });
  }

  // TODO: Replace with actual backend search API call
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      _loadRecentSearches();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Mock search delay - Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock filtered results - Replace with backend response
    setState(() {
      _searchResults = _searchResults
          .where(
            (item) => item.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      _isSearching = false;
    });
  }

  void _removeSearchItem(String id) {
    setState(() {
      _searchResults.removeWhere((item) => item.id == id);
    });
    // TODO: Call backend to remove from recent searches
  }

  void _clearSearch() {
    _searchController.clear();
    _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkTheme = themeCubit.isDarkMode;

    final backgroundColor = isDarkTheme
        ? const Color(0xff000000)
        : const Color(0xfff3f4f6);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkTheme
        ? Colors.grey[400]
        : Colors.grey[600];
    final borderColor = isDarkTheme ? Colors.grey[800] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor ?? Colors.grey,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: textColor, size: 24),
                  ),
                  const SizedBox(width: 12),

                  // Search Input
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search Music...',
                        hintStyle: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _performSearch,
                    ),
                  ),

                  // Clear Button
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Icon(
                        Icons.close,
                        color: secondaryTextColor,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // Search Results List
            Expanded(
              child: _isSearching
                  ? Center(child: CircularProgressIndicator(color: textColor))
                  : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return _buildSearchResultItem(
                          result,
                          textColor,
                          secondaryTextColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(
    SearchResultModel result,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to song detail or play song
        print('Tapped on: ${result.title}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // History/Clock Icon
            Icon(Icons.history, color: secondaryTextColor, size: 22),
            const SizedBox(width: 16),

            // Song Title
            Expanded(
              child: Text(
                result.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Remove Button
            GestureDetector(
              onTap: () => _removeSearchItem(result.id),
              child: Icon(Icons.close, color: secondaryTextColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Arrow/Navigate Icon
            GestureDetector(
              onTap: () {
                // TODO: Navigate to song detail
                print('Navigate to: ${result.title}');
              },
              child: Icon(
                Icons.north_east,
                color: secondaryTextColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
