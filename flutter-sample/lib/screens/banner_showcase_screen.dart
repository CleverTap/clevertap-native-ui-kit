import 'package:flutter/material.dart';

import 'banner_detail_screen.dart';

class _BannerItem {
  final String emoji;
  final String title;
  final String description;
  final String assetPath;

  const _BannerItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.assetPath,
  });
}

const _banners = [
  _BannerItem(
    emoji: '☀️',
    title: 'Summer Sale',
    description: 'Hero banner with gradient',
    assetPath: 'assets/banners/banner-01-hero-summer-sale.json',
  ),
  _BannerItem(
    emoji: '📱',
    title: 'iPhone 15 Pro',
    description: 'Product showcase',
    assetPath: 'assets/banners/banner-02-product-iphone.json',
  ),
  _BannerItem(
    emoji: '🎉',
    title: 'New Features',
    description: 'App update announcement',
    assetPath: 'assets/banners/banner-03-announcement-update.json',
  ),
  _BannerItem(
    emoji: '✈️',
    title: 'Travel Deals',
    description: 'Multi-button travel banner',
    assetPath: 'assets/banners/banner-04-travel-deals.json',
  ),
  _BannerItem(
    emoji: '👗',
    title: 'Fashion Collection',
    description: 'Image banner',
    assetPath: 'assets/banners/banner-05-fashion-collection.json',
  ),
  _BannerItem(
    emoji: '💳',
    title: 'Cashback Offer',
    description: 'Credit card with GIF',
    assetPath: 'assets/banners/banner-06-credit-card-offer.json',
  ),
  _BannerItem(
    emoji: '⭐',
    title: 'App Rating',
    description: 'Social proof',
    assetPath: 'assets/banners/banner-07-app-rating.json',
  ),
  _BannerItem(
    emoji: '⚡',
    title: 'Flash Sale',
    description: 'Urgency banner',
    assetPath: 'assets/banners/banner-08-flash-sale.json',
  ),
  _BannerItem(
    emoji: '💎',
    title: 'Go Premium',
    description: 'Typography showcase',
    assetPath: 'assets/banners/banner-09-premium-subscription.json',
  ),
  _BannerItem(
    emoji: '👋',
    title: 'Welcome',
    description: 'Onboarding banner',
    assetPath: 'assets/banners/banner-10-welcome-onboarding.json',
  ),
];

class BannerShowcaseScreen extends StatelessWidget {
  const BannerShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _banners.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _BannerListItem(banner: _banners[i]),
      ),
    );
  }
}

class _BannerListItem extends StatelessWidget {
  final _BannerItem banner;

  const _BannerListItem({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BannerDetailScreen(
                title: banner.title,
                assetPath: banner.assetPath,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF5F5F5),
                child: Text(banner.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}
