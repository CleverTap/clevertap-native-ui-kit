import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Image,
  TouchableOpacity,
  StyleSheet,
  Platform,
} from 'react-native';
import CleverTap from 'clevertap-react-native';
import { NativeDisplaySlot } from '@clevertap/native-display-sdk';

// --- Data models ---

interface AppContentItem {
  id: number;
  title: string;
  subtitle: string;
  imageUrl: string;
}

type FeedItem =
  | { type: 'slot'; slotId: string }
  | { type: 'content'; item: AppContentItem };

// --- Hardcoded content (identical to Android and iOS sample apps) ---

const APP_ITEMS: AppContentItem[] = [
  { id: 1,  title: 'Morning Yoga Flow',    subtitle: '30 min \u00B7 Beginner friendly',      imageUrl: 'https://yavuzceliker.github.io/sample-images/image-1.jpg' },
  { id: 2,  title: 'Mediterranean Salad', subtitle: 'Quick & healthy lunch recipe',          imageUrl: 'https://yavuzceliker.github.io/sample-images/image-5.jpg' },
  { id: 3,  title: 'Productivity Hacks',  subtitle: '5 tips for focused work',               imageUrl: 'https://yavuzceliker.github.io/sample-images/image-10.jpg' },
  { id: 4,  title: 'Trail Running Guide', subtitle: 'Best routes near you',                  imageUrl: 'https://yavuzceliker.github.io/sample-images/image-15.jpg' },
  { id: 5,  title: 'Indoor Plants 101',   subtitle: 'Low-maintenance greenery',              imageUrl: 'https://yavuzceliker.github.io/sample-images/image-20.jpg' },
  { id: 6,  title: 'Weekend Getaways',    subtitle: 'Top 10 road trip destinations',         imageUrl: 'https://yavuzceliker.github.io/sample-images/image-25.jpg' },
  { id: 7,  title: 'Budget Meal Prep',    subtitle: 'Save time and money',                   imageUrl: 'https://yavuzceliker.github.io/sample-images/image-30.jpg' },
  { id: 8,  title: 'Home Workout',        subtitle: 'No equipment needed',                   imageUrl: 'https://yavuzceliker.github.io/sample-images/image-35.jpg' },
  { id: 9,  title: 'Coffee Brewing',      subtitle: 'Perfect pour-over technique',           imageUrl: 'https://yavuzceliker.github.io/sample-images/image-40.jpg' },
  { id: 10, title: 'Sleep Better',        subtitle: 'Science-backed tips',                   imageUrl: 'https://yavuzceliker.github.io/sample-images/image-45.jpg' },
  { id: 11, title: 'Digital Detox',       subtitle: 'Unplug and recharge',                   imageUrl: 'https://yavuzceliker.github.io/sample-images/image-50.jpg' },
  { id: 12, title: 'Book Club Picks',     subtitle: "This month's top reads",                imageUrl: 'https://yavuzceliker.github.io/sample-images/image-55.jpg' },
  { id: 13, title: 'Smoothie Recipes',    subtitle: 'Fuel your morning',                     imageUrl: 'https://yavuzceliker.github.io/sample-images/image-60.jpg' },
  { id: 14, title: 'Desk Stretches',      subtitle: 'Relieve tension in 5 min',              imageUrl: 'https://yavuzceliker.github.io/sample-images/image-65.jpg' },
  { id: 15, title: 'Mindful Breathing',   subtitle: 'Calm in 3 minutes',                     imageUrl: 'https://yavuzceliker.github.io/sample-images/image-70.jpg' },
];

// Build the 19-item feed: slots interleaved with app content at fixed positions.
// Matches Android buildFeedItems() and iOS items array exactly:
//   index 0      slot_top
//   index 1-3    app items 1-3
//   index 4      slot_feed_1
//   index 5-7    app items 4-6
//   index 8      slot_feed_2
//   index 9-17   app items 7-15
//   index 18     slot_bottom
function buildFeedItems(): FeedItem[] {
  return [
    { type: 'slot',    slotId: 'slot_top' },
    { type: 'content', item: APP_ITEMS[0]! },
    { type: 'content', item: APP_ITEMS[1]! },
    { type: 'content', item: APP_ITEMS[2]! },
    { type: 'slot',    slotId: 'slot_feed_1' },
    { type: 'content', item: APP_ITEMS[3]! },
    { type: 'content', item: APP_ITEMS[4]! },
    { type: 'content', item: APP_ITEMS[5]! },
    { type: 'slot',    slotId: 'slot_feed_2' },
    { type: 'content', item: APP_ITEMS[6]! },
    { type: 'content', item: APP_ITEMS[7]! },
    { type: 'content', item: APP_ITEMS[8]! },
    { type: 'content', item: APP_ITEMS[9]! },
    { type: 'content', item: APP_ITEMS[10]! },
    { type: 'content', item: APP_ITEMS[11]! },
    { type: 'content', item: APP_ITEMS[12]! },
    { type: 'content', item: APP_ITEMS[13]! },
    { type: 'content', item: APP_ITEMS[14]! },
    { type: 'slot',    slotId: 'slot_bottom' },
  ];
}

const FEED_ITEMS = buildFeedItems();

// --- Screen ---

export function SlotDemoScreen(): React.ReactElement {
  const ctAvailable =
    typeof (CleverTap as unknown as Record<string, unknown>).recordEvent === 'function';

  function fetchSlotData() {
    if (!ctAvailable) return;
    const ct = CleverTap as unknown as { recordEvent: (name: string) => void };
    ct.recordEvent('Footer1');
    ct.recordEvent('Footer5');
    ct.recordEvent('Header1');
    ct.recordEvent('Header2');
    ct.recordEvent('Header4');
    ct.recordEvent('lalit');
  }

  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={styles.content}
    >
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Slot Demo</Text>
        <Text style={styles.description}>
          This feed contains 4 NativeDisplaySlot views at fixed positions. Tap the button
          below to fire a CleverTap event that fetches real server data for the slots.
        </Text>
        <TouchableOpacity
          style={[styles.fetchButton, !ctAvailable && styles.fetchButtonDisabled]}
          onPress={fetchSlotData}
          disabled={!ctAvailable}
          activeOpacity={0.8}
        >
          <Text style={styles.fetchButtonText}>Fetch Slot Data</Text>
        </TouchableOpacity>
      </View>

      {/* Feed */}
      {FEED_ITEMS.map((feedItem, index) =>
        feedItem.type === 'slot' ? (
          <NativeDisplaySlot
            key={feedItem.slotId}
            slotId={feedItem.slotId}
            placeholder={<EmptySlotPlaceholder />}
            style={styles.slotView}
          />
        ) : (
          <AppContentCard key={feedItem.item.id} item={feedItem.item} />
        ),
      )}
    </ScrollView>
  );
}

// --- Slot placeholder (shown before server data arrives) ---

function EmptySlotPlaceholder(): React.ReactElement {
  return (
    <View style={styles.placeholder}>
      <Text style={styles.placeholderLabel}>Ad</Text>
    </View>
  );
}

// --- App content card ---

function AppContentCard({ item }: { item: AppContentItem }): React.ReactElement {
  const [imageLoaded, setImageLoaded] = useState(false);

  return (
    <View style={styles.card}>
      <View style={styles.imageContainer}>
        {!imageLoaded && <View style={styles.imagePlaceholder} />}
        <Image
          source={{ uri: item.imageUrl }}
          style={[styles.cardImage, !imageLoaded && styles.hidden]}
          resizeMode="cover"
          onLoad={() => setImageLoaded(true)}
        />
      </View>
      <View style={styles.cardBody}>
        <Text style={styles.cardTitle} numberOfLines={1} ellipsizeMode="tail">
          {item.title}
        </Text>
        <Text style={styles.cardSubtitle} numberOfLines={1} ellipsizeMode="tail">
          {item.subtitle}
        </Text>
      </View>
    </View>
  );
}

// --- Styles ---

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  content: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 12,
  },

  // Header
  header: {
    marginBottom: 4,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  description: {
    fontSize: 14,
    color: '#666666',
    lineHeight: 20,
    marginBottom: 12,
  },
  fetchButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
  },
  fetchButtonDisabled: {
    backgroundColor: '#A0AABA',
  },
  fetchButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },

  // Slot placeholder
  placeholder: {
    height: 80,
    width: '100%',
    backgroundColor: '#F5F5F5',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#BDBDBD',
    borderStyle: 'dashed',
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: '#9E9E9E',
  },

  // NativeDisplaySlot wrapper
  slotView: {
    width: '100%',
  },

  // App content card
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: '#000000',
        shadowOffset: { width: 0, height: 2 },
        shadowRadius: 4,
        shadowOpacity: 0.08,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  imageContainer: {
    width: '100%',
    height: 180,
  },
  cardImage: {
    width: '100%',
    height: 180,
  },
  imagePlaceholder: {
    position: 'absolute',
    width: '100%',
    height: '100%',
    backgroundColor: '#E0E0E0',
  },
  hidden: {
    opacity: 0,
  },
  cardBody: {
    padding: 12,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 4,
  },
  cardSubtitle: {
    fontSize: 14,
    color: '#888888',
  },
});
