import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';

class AdSplashPage extends StatefulWidget {
  const AdSplashPage({
    super.key,
    required this.config,
    required this.onFinished,
  });

  final SplashAdsConfig config;
  final VoidCallback onFinished;

  @override
  State<AdSplashPage> createState() => _AdSplashPageState();
}

class _AdSplashPageState extends State<AdSplashPage> {
  late final PageController _pageController;
  int _index = 0;
  int _elapsed = 0;
  Timer? _timer;
  bool _canSkip = false;

  List<SplashAdItem> get _items => widget.config.items;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsed = 0;
    _canSkip = widget.config.skipAfterSec <= 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_elapsed >= widget.config.skipAfterSec) _canSkip = true;
        if (_elapsed >= widget.config.durationSec) _nextOrFinish();
      });
    });
  }

  void _nextOrFinish() {
    if (_index < _items.length - 1) {
      _index++;
      _pageController.animateToPage(
        _index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _startTimer();
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    widget.onFinished();
  }

  Future<void> _openAd(SplashAdItem item) async {
    final uri = Uri.tryParse(item.linkUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remain = (widget.config.durationSec - _elapsed).clamp(0, widget.config.durationSec);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final ad = _items[i];
              return GestureDetector(
                onTap: () => _openAd(ad),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      ad.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1e293b),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 64),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Color(0xCC000000), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ad.network.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(ad.network, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            ad.title,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('点击了解详情', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_index + 1}/${_items.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  if (!_canSkip)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${widget.config.skipAfterSec - _elapsed}s 后可跳过', style: const TextStyle(color: Colors.white)),
                    )
                  else
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black45,
                      ),
                      child: Text('跳过 $remain'),
                    ),
                ],
              ),
            ),
          ),
          if (_items.length > 1)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
