import 'package:flutter/material.dart';

// --- Data models ---

class _AppItem {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  const _AppItem(this.id, this.title, this.subtitle, this.imageUrl);
}

sealed class _FeedItem {}
class _ContentItem extends _FeedItem {
  final _AppItem item;
  _ContentItem(this.item);
}
class _SlotItem extends _FeedItem {
  final String slotId;
  _SlotItem(this.slotId);
}

// --- Feed data ---

const _appItems = [
  _AppItem(1,  'Morning Yoga Flow',      '30 min · Beginner friendly',         'https://yavuzceliker.github.io/sample-images/image-1.jpg'),
  _AppItem(2,  'Mediterranean Salad',    'Quick & healthy lunch recipe',        'https://yavuzceliker.github.io/sample-images/image-5.jpg'),
  _AppItem(3,  'Productivity Hacks',     '5 tips for focused work',             'https://yavuzceliker.github.io/sample-images/image-10.jpg'),
  _AppItem(4,  'Trail Running Guide',    'Best routes near you',                'https://yavuzceliker.github.io/sample-images/image-15.jpg'),
  _AppItem(5,  'Indoor Plants 101',      'Low-maintenance greenery',            'https://yavuzceliker.github.io/sample-images/image-20.jpg'),
  _AppItem(6,  'Weekend Getaways',       'Top 10 road trip destinations',       'https://yavuzceliker.github.io/sample-images/image-25.jpg'),
  _AppItem(7,  'Budget Meal Prep',       'Save time and money',                 'https://yavuzceliker.github.io/sample-images/image-30.jpg'),
  _AppItem(8,  'Home Workout',           'No equipment needed',                 'https://yavuzceliker.github.io/sample-images/image-35.jpg'),
  _AppItem(9,  'Coffee Brewing',         'Perfect pour-over technique',         'https://yavuzceliker.github.io/sample-images/image-40.jpg'),
  _AppItem(10, 'Sleep Better',           'Science-backed tips',                 'https://yavuzceliker.github.io/sample-images/image-45.jpg'),
  _AppItem(11, 'Digital Detox',          'Unplug and recharge',                 'https://yavuzceliker.github.io/sample-images/image-50.jpg'),
  _AppItem(12, 'Book Club Picks',        'This month\'s top reads',             'https://yavuzceliker.github.io/sample-images/image-55.jpg'),
  _AppItem(13, 'Smoothie Recipes',       'Fuel your morning',                   'https://yavuzceliker.github.io/sample-images/image-60.jpg'),
  _AppItem(14, 'Desk Stretches',         'Relieve tension in 5 min',            'https://yavuzceliker.github.io/sample-images/image-65.jpg'),
  _AppItem(15, 'Mindful Breathing',      'Calm in 3 minutes',                   'https://yavuzceliker.github.io/sample-images/image-70.jpg'),
];

List<_FeedItem> _buildFeed() => [
  _SlotItem('slot_top'),
  ..._appItems.sublist(0, 3).map(_ContentItem.new),
  _SlotItem('slot_feed_1'),
  ..._appItems.sublist(3, 6).map(_ContentItem.new),
  _SlotItem('slot_feed_2'),
  ..._appItems.sublist(6, 15).map(_ContentItem.new),
  _SlotItem('slot_bottom'),
];

// --- Screen ---

class SlotDemoScreen extends StatefulWidget {
  const SlotDemoScreen({super.key});

  @override
  State<SlotDemoScreen> createState() => _SlotDemoScreenState();
}

class _SlotDemoScreenState extends State<SlotDemoScreen> {
  final _feed = _buildFeed();
  // In a real integration, slot configs would come from NativeDisplayBridge.
  // Here we show dashed placeholders to demonstrate the layout.

  void _fetchSlotData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Integrate CleverTap Core SDK to receive live slot data'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Slot Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _feed.length + 1, // +1 for header
        itemBuilder: (ctx, i) {
          if (i == 0) return _Header(onFetch: _fetchSlotData);
          final item = _feed[i - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: switch (item) {
              _SlotItem s => _SlotPlaceholder(slotId: s.slotId),
              _ContentItem c => _AppContentCard(item: c.item),
            },
          );
        },
      ),
    );
  }
}

// --- Header ---

class _Header extends StatelessWidget {
  final VoidCallback onFetch;
  const _Header({required this.onFetch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Slot Demo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'This feed contains 4 NativeDisplaySlot views at fixed positions. '
            'Tap the button below to fire a CleverTap event that fetches real server data for the slots.',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onFetch,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Fetch Slot Data'),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// --- Slot placeholder (dashed border, matches Android EmptySlotPlaceholder) ---

class _SlotPlaceholder extends StatelessWidget {
  final String slotId;
  const _SlotPlaceholder({required this.slotId});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: SizedBox(
        height: 80,
        width: double.infinity,
        child: Center(
          child: Text(
            'Ad',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(8);
    final rect = RRect.fromLTRBR(0, 0, size.width, size.height, radius);
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashLen = 8.0;
    const gapLen = 4.0;
    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}

// --- App content card ---

class _AppContentCard extends StatelessWidget {
  final _AppItem item;
  const _AppContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              item.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: const Color(0xFFEEEEEE),
                child: const Icon(Icons.image, color: Color(0xFFBBBBBB), size: 48),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      height: 180,
                      color: const Color(0xFFF5F5F5),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
