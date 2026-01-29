import 'package:flutter/material.dart';

class SongMetadataScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final String album;
  final String year;
  final String duration;
  final String genre;
  final bool explicit;
  final String views;
  final String likes;
  final String label;
  final String url;

  const SongMetadataScreen({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    required this.duration,
    required this.genre,
    required this.explicit,
    required this.views,
    required this.likes,
    required this.label,
    required this.url,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back),
                    iconSize: 30,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Album Art
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Song Info
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(artist, style: TextStyle(color: Colors.white70, fontSize: 22)),
            SizedBox(height: 4),
            Text(
              album,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 32),
            // Metadata Grid
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metaItem('YEAR', year),
                      _metaItem('DURATION', duration),
                      _metaItem('GENRE', genre, highlight: true),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metaItem('EXPLICIT', explicit ? 'E' : '', box: true),
                      _metaItem('VIEWS', views),
                      _metaItem('LIKES', likes),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_metaItem('LABEL', label, wide: true)],
                  ),
                ],
              ),
            ),
            Spacer(),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Open URL
                        if (url.isNotEmpty) {
                          // Use url_launcher package in real app
                        }
                      },
                      child: Text(
                        'OPEN URL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.download, color: Colors.white, size: 28),
                      onPressed: () {
                        // Download action
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(
    String label,
    String value, {
    bool highlight = false,
    bool box = false,
    bool wide = false,
  }) {
    return Container(
      width: wide ? 180 : 90,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              color: Colors.white54,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 6),
          box
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: highlight ? Colors.white : Colors.white70,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                    fontSize: highlight ? 16 : 15,
                  ),
                ),
        ],
      ),
    );
  }
}
