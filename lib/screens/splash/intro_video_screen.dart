import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/env.dart';
import '../../services/auth_service.dart' as mock;
import '../../services/firebase_auth_service.dart' as fbsvc;
import '../../screens/auth/welcome_screen.dart';
import '../../app_shell.dart';

/// Plays an intro video, then routes to either dashboard (if logged in) or login.
class IntroVideoScreen extends ConsumerStatefulWidget {
  const IntroVideoScreen({super.key});
  @override
  ConsumerState<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends ConsumerState<IntroVideoScreen> {
  late VideoPlayerController _c;
  bool _ready = false;
  bool _navigated = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _c = VideoPlayerController.asset('assets/videos/IntroVideo.mp4');
    try {
      await _c.initialize();
      // Web/mobile autoplay constraints: keep muted to allow autoplay
      if (kIsWeb) await _c.setVolume(0.0);
      await _c.play();
      setState(() => _ready = true);

      // Navigate when the video finishes
      _c.addListener(() {
        final v = _c.value;
        if (v.isInitialized && !v.isPlaying && v.position >= (v.duration - const Duration(milliseconds: 250))) {
          _goNext();
        }
      });

      // Safety: if something blocks playback, continue anyway after 7s
      _safetyTimer = Timer(const Duration(seconds: 7), _goNext);
    } catch (_) {
      // If the video can't start, continue gracefully
      _goNext();
    }
  }

  Future<void> _goNext() async {
    if (_navigated) return;
    _navigated = true;
    _safetyTimer?.cancel();

    final user = kUseMockAuth
        ? await ref.read(mock.authServiceProvider).currentUser()
        : await ref.read(fbsvc.firebaseAuthServiceProvider).currentUser();

    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready) FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _c.value.size.width,
              height: _c.value.size.height,
              child: VideoPlayer(_c),
            ),
          ) else const Center(child: CircularProgressIndicator()),
          // Brand overlay & skip
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  // Add your logo here if you want (optional)
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 28,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              onPressed: _goNext,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}
