import 'package:flutter/material.dart';

import '../widgets/nd_demo_card.dart';

/// Slot Demo — shows how multiple display units can be placed in a mixed content feed.
class SlotDemoScreen extends StatelessWidget {
  const SlotDemoScreen({super.key});

  static const _slots = [
    ('Slot 1 — Banner', 'assets/banners/banner-01-hero-summer-sale.json'),
    ('Slot 2 — Product', 'assets/banners/banner-02-product-iphone.json'),
    ('Slot 3 — Promotion', 'assets/banners/banner-08-flash-sale.json'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slot Demo')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _slots.length * 2 - 1,
        itemBuilder: (ctx, i) {
          // Interleave slot cards with mock feed items
          if (i.isOdd) return _MockFeedItem(index: i ~/ 2 + 1);
          final (title, assetPath) = _slots[i ~/ 2];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: NdDemoCard(assetPath: assetPath, title: title),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MockFeedItem extends StatelessWidget {
  final int index;

  const _MockFeedItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 120,
            color: const Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 8),
          Container(height: 12, color: const Color(0xFFEEEEEE)),
          const SizedBox(height: 6),
          Container(height: 12, width: 200, color: const Color(0xFFEEEEEE)),
          const SizedBox(height: 6),
          Text(
            'Mock feed item #$index',
            style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
