import React, {ReactNode} from 'react';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

type Platform = 'android-compose' | 'android-xml' | 'ios-swiftui' | 'ios-objc';

const LABELS: Record<Platform, string> = {
  'android-compose': 'Android (Compose)',
  'android-xml': 'Android (XML)',
  'ios-swiftui': 'iOS (SwiftUI)',
  'ios-objc': 'iOS (Objective-C)',
};

interface PlatformTabsProps {
  groupId?: string;
  platforms?: Platform[];
  children: ReactNode;
}

// Wraps Docusaurus <Tabs> with platform-aware defaults so that picking a
// platform on one page persists across other pages via groupId="platform".
// Children must be one <TabItem value="<platform>"> per platform listed in
// `platforms` (or all four if `platforms` is omitted).
export default function PlatformTabs({
  groupId = 'platform',
  platforms = ['android-compose', 'android-xml', 'ios-swiftui', 'ios-objc'],
  children,
}: PlatformTabsProps) {
  return (
    <Tabs
      groupId={groupId}
      values={platforms.map((p) => ({label: LABELS[p], value: p}))}
    >
      {children}
    </Tabs>
  );
}

export {TabItem};
