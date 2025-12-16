import 'package:flutter/material.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  // 1. Controller banaya sheet ko control karne ke liye
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Icon ki state track karne ke liye
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Sheet ki movement sunne ke liye listener (taake icon update ho sake agar user haath se swipe kare)
    _sheetController.addListener(() {
      if (_sheetController.size > 0.2 && !isExpanded) {
        setState(() => isExpanded = true);
      } else if (_sheetController.size <= 0.2 && isExpanded) {
        setState(() => isExpanded = false);
      }
    });
  }

  // 2. Button click ka function
  void toggleSheet() {
    if (isExpanded) {
      // Agar khula hai to wapis chota (0.15) kar do
      _sheetController.animateTo(
        0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Agar band hai to expand (0.7) kar do
      _sheetController.animateTo(
        0.7,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Background Music Player
      body: Stack(
        children: [
          // Piche ka Music Player Content (Image, Title etc.)
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(Icons.music_note, size: 150, color: Colors.blueAccent),
                SizedBox(height: 20),
                Text(
                  "Freak In Me",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Mild Orange",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 3. Draggable Sheet (Lyrics Section)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.15, // Shuru mein 15% dikhega (thoda visible)
            minChildSize: 0.15, // Minimum itna hi rahega minimize hone par
            maxChildSize: 0.7, // Expand hone par 70% screen cover karega
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ), // Top round corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller:
                      scrollController, // Important: Isko connect karna zaroori hai swipe ke liye
                  child: Column(
                    children: [
                      // --- Header (Lyrics Title + Arrow Button) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.music_note_outlined,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Lyrics",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Arrow Button
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  // Icon change logic based on state
                                  isExpanded
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_up,
                                  color: Colors.black,
                                ),
                              ),
                              onPressed:
                                  toggleSheet, // Button click function call
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      // --- Lyrics Content ---
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Lately, I think of you lots\n"
                          "'Cause my mind's in circles for you\n"
                          "Please connect the dots\n"
                          "And bring me, bring me to you\n\n"
                          "'Cause you bring out the freak in me\n"
                          "It's only for you\n"
                          "Yeah, you bring out the freak in me\n"
                          "It's only for you\n\n"
                          "(Lyrics continue...)\n"
                          "Lorem ipsum dolor sit amet...",
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Extra space bottom pe taake scroll pura ho sake
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
