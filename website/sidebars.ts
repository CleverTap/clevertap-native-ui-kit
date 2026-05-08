import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting started',
      collapsed: false,
      items: [
        'getting-started/install',
        'getting-started/quickstart',
        'getting-started/android-compose',
        'getting-started/android-xml',
        'getting-started/ios-swiftui',
        'getting-started/ios-objc',
      ],
    },
    {
      type: 'category',
      label: 'Concepts',
      items: [
        'concepts/config-structure',
        'concepts/nodes-vs-elements',
        'concepts/layout-system',
        'concepts/arrangement-strategies',
        'concepts/style-cascading',
        'concepts/style-classes-deep',
        'concepts/theme',
        'concepts/templates-and-variables',
        'concepts/animations',
        'concepts/actions',
      ],
    },
    {
      type: 'category',
      label: 'Components',
      collapsed: false,
      items: [
        {
          type: 'category',
          label: 'Containers',
          items: [
            'components/containers/box',
            'components/containers/vertical',
            'components/containers/horizontal',
            'components/containers/gallery',
          ],
        },
        {
          type: 'category',
          label: 'Elements',
          items: [
            'components/elements/text',
            'components/elements/image',
            'components/elements/button',
            'components/elements/video',
            'components/elements/html',
            'components/elements/spacer',
            'components/elements/divider',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Dimensions',
      items: [
        'dimensions/overview',
        'dimensions/percent',
        'dimensions/dp',
        'dimensions/sp',
        'dimensions/px',
        'dimensions/special',
      ],
    },
    {
      type: 'category',
      label: 'Integrations',
      items: ['integrations/core-sdk', 'integrations/backend-payload'],
    },
    {
      type: 'category',
      label: 'Advanced',
      items: ['advanced/manual-config'],
    },
    {
      type: 'category',
      label: 'JSON reference',
      items: ['json-reference/v1.0.0-schema'],
    },
    'changelog',
  ],
};

export default sidebars;
