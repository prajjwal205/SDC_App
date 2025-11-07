import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventCarousel extends StatefulWidget {
  const EventCarousel({super.key});

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  List<Map<String, dynamic>> _events = [];
  Timer? _eventTimer;
  final PageController _eventPageController =
  PageController(viewportFraction: 0.9);
  int _currentEventPageIndex = 0;

  // 1. ADDED: A variable to hold our database listener
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    // 2. CHANGED: Instead of fetching once, we now *listen* for changes
    _listenToEvents();
  }

  @override
  void dispose() {
    _eventPageController.dispose();
    _eventTimer?.cancel();
    // 3. ADDED: We must cancel the listener when the widget is removed
    _eventSubscription?.cancel();
    super.dispose();
  }

  // 4. NEW FUNCTION: This function sets up the real-time listener
  void _listenToEvents() {
    // We cancel any old listener just in case
    _eventSubscription?.cancel();

    _eventSubscription = FirebaseFirestore.instance
        .collection('events')
        .snapshots() // <-- This is the change from .get()
        .listen(
          (snapshot) {
        if (!mounted) return; // Check if widget is still active

        setState(() {
          // Update the events list with the new data from the stream
          _events = snapshot.docs.map((doc) => doc.data()).toList();
        });

        // (Re)start or stop the timer based on if there are events
        if (_events.isNotEmpty) {
          _startEventTimer();
        } else {
          _eventTimer?.cancel(); // Stop timer if no events
        }
      },
      onError: (error) {
        // Handle any errors from the stream
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading events: $error')),
          );
        }
      },
    );
  }

  // 5. REMOVED: The old _fetchEvents() function is no longer needed.

  void _startEventTimer() {
    _eventTimer?.cancel(); // Cancel any existing timer

    _eventTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int nextPage = _currentEventPageIndex + 1;
      if (nextPage >= _events.length) {
        nextPage = 0;
      }

      if (_eventPageController.hasClients) {
        _eventPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;

    // This part remains the same. It shows a loading box if _events is empty,
    // which it will be for a moment before the stream sends data.
    if (_events.isEmpty) {
      return Container(
        height: h * 0.25,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("Loading Events...")),
      );
    }

    // The rest of the UI build logic is unchanged
    return SizedBox(
      height: h * 0.25,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _eventPageController,
            itemCount: _events.length,
            onPageChanged: (index) {
              setState(() {
                _currentEventPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final event = _events[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        event['imageUrl'] ??
                            'https://placehold.co/600x300?text=Event',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey[200]),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.5, 1.0],
                            )),
                      ),
                      Positioned(
                        bottom: 30,
                        left: 16,
                        right: 16,
                        child: Text(
                          event['title'] ?? 'Event',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black87)
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_events.length, (index) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentEventPageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

