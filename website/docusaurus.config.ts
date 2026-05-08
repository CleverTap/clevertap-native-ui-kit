import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js. Don't use client-side code here.

const GITHUB_ORG = 'CleverTap';
const GITHUB_REPO = 'clevertap-native-ui-kit';

const config: Config = {
  title: 'CleverTap Native UI Kit',
  tagline: 'Server-driven native UI for Android and iOS',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: `https://${GITHUB_ORG.toLowerCase()}.github.io`,
  baseUrl: `/${GITHUB_REPO}/`,

  organizationName: GITHUB_ORG,
  projectName: GITHUB_REPO,
  deploymentBranch: 'gh-pages',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
          // editUrl intentionally omitted — the source repo is private and the
          // "Edit this page" link would 404 for external readers. Re-enable
          // once the repo (or a public mirror) becomes accessible.
          // Versioning: each `git tag v*.*.*` triggers
          // `docusaurus docs:version` in CI to snapshot the current docs.
          // Until the first snapshot lands, "current" sits at the site root.
          // After v1.0.0 ships, set lastVersion: '1.0.0' and current moves to /next/.
          lastVersion: 'current',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  plugins: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        indexBlog: false,
        docsRouteBasePath: '/',
        highlightSearchTermsOnTargetPage: true,
      },
    ],
  ],

  themeConfig: {
    image: 'img/social-card.png',
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Native UI Kit',
      logo: {
        alt: 'CleverTap',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'pathname:///api/android/',
          label: 'Android API',
          position: 'left',
          target: '_blank',
        },
        {
          href: 'pathname:///api/ios/',
          label: 'iOS API',
          position: 'left',
          target: '_blank',
        },
        {
          type: 'docsVersionDropdown',
          position: 'right',
        },
        // GitHub link omitted — repo is private; an external link would 404 for clients.
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {label: 'Getting started', to: '/getting-started/android-compose'},
            {label: 'BOX container', to: '/components/containers/box'},
            {label: 'Percentage dimensions', to: '/dimensions/percent'},
          ],
        },
        {
          title: 'API reference',
          items: [
            {label: 'Android (Dokka)', href: 'pathname:///api/android/'},
            {label: 'iOS (DocC)', href: 'pathname:///api/ios/'},
          ],
        },
        {
          title: 'More',
          items: [
            {label: 'Changelog', to: '/changelog'},
            {label: 'CleverTap dashboard', href: 'https://dashboard.clevertap.com/'},
            {label: 'CleverTap support', href: 'https://help.clevertap.com/'},
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} CleverTap.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['kotlin', 'swift', 'objectivec', 'groovy', 'java', 'bash', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
