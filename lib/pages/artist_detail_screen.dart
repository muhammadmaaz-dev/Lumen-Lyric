import 'package:flutter/material.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  final String artistImageUrl;
  final String subscribers;
  final List<Map<String, dynamic>> tracks;
  final int totalTracks;

  const ArtistDetailScreen({
    Key? key,
    required this.artistName,
    required this.artistImageUrl,
    required this.subscribers,
    required this.tracks,
    required this.totalTracks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(artistImageUrl),
            ),
            SizedBox(height: 24),
            Text(
              artistName.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '$subscribers SUBSCRIBERS',
              style: TextStyle(
                color: Colors.white54,
                fontFamily: 'RobotoMono',
                fontSize: 15,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundedButton('SHUFFLE', Icons.shuffle, onTap: () {}),
                SizedBox(width: 24),
                _roundedButton('FOLLOW', Icons.add, onTap: () {}),
              ],
            ),
            SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'POPULAR TRACKS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '$totalTracks TRACKS TOTAL',
                    style: TextStyle(
                      color: Colors.white38,
                      fontFamily: 'RobotoMono',
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final track = tracks[index];
                return _trackTile(index + 1, track);
              },
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white38, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () {},
                  child: Text(
                    'LOAD ALL TRACKS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'RobotoMono',
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _roundedButton(
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white38, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        foregroundColor: Colors.white,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _trackTile(int number, Map<String, dynamic> track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number.toString().padLeft(2, '0'),
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'RobotoMono',
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track['title'],
                  style: TextStyle(
                    color: track['highlight'] == true
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: track['highlight'] == true
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 17,
                    letterSpacing: 1.1,
                  ),
                ),
                Row(
                  children: [
                    if (track['explicit'] == true)
                      Container(
                        margin: EdgeInsets.only(right: 6),
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'E',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      '${track['plays']} PLAYS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            track['duration'],
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'RobotoMono',
              fontSize: 15,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.more_horiz, color: Colors.white38),
        ],
      ),
    );
  }
}
