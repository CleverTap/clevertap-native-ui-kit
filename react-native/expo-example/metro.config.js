// Metro config for the Expo example.
//
// Three jobs:
//   1. Load `@clevertap/native-display-sdk` from its TypeScript source
//      (../src/index.ts) so changes hot-reload without `npm run build` in the
//      SDK package - same trick the bare example uses.
//   2. Load all 6 screens from the bare example's `screens/` folder via the
//      `@bare-example/screens/*` alias, so this app's UI tracks the bare
//      example 1:1 (single source of truth for screens).
//   3. Force `react`, `react-native`, and `clevertap-react-native` to resolve
//      from `expo-example/node_modules` so we don't end up with two copies of
//      the same package loaded into the runtime.
//
// Missing optional UI peer deps are routed to a no-op stub - matches the
// bare example's pattern and keeps Metro bundling green when the user has
// pruned packages they don't want.

const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');
const fs = require('fs');

const sdkRoot = path.resolve(__dirname, '..');                 // react-native/
const bareExampleRoot = path.resolve(__dirname, '../example'); // react-native/example/
const repoRoot = path.resolve(__dirname, '../..');             // monorepo root
const ctSdkRoot = fs.realpathSync(
  path.resolve(__dirname, 'node_modules/clevertap-react-native'),
);

const OPTIONAL_PEER_DEPS = [
  'react-native-linear-gradient',
  'expo-linear-gradient',
  'react-native-svg',
  'react-native-reanimated',
  'react-native-webview',
  'react-native-video',
  '@react-native-masked-view/masked-view',
  '@react-native-community/blur',
  'expo-image',
  'react-native-fast-image',
];

const optionalStubPath = path.resolve(__dirname, 'stubs/optional-stub.js');

function isInstalled(pkg) {
  try {
    require.resolve(pkg, { paths: [__dirname] });
    return true;
  } catch {
    return false;
  }
}

const config = getDefaultConfig(__dirname);

// Watch the SDK source, the bare example's screens, and the linked
// clevertap-react-native package so Metro picks up changes live.
config.watchFolders = [
  ...(config.watchFolders ?? []),
  sdkRoot,
  bareExampleRoot,
  repoRoot,
  ctSdkRoot,
];

// Prefer this app's node_modules; fall back to SDK's for transitive deps.
config.resolver.nodeModulesPaths = [
  path.resolve(__dirname, 'node_modules'),
  path.resolve(sdkRoot, 'node_modules'),
];

const upstreamResolveRequest = config.resolver.resolveRequest;

config.resolver.resolveRequest = (context, moduleName, platform) => {
  // Bare-example screen alias: e.g. `@bare-example/screens/SlotDemoScreen`
  // → `react-native/example/screens/SlotDemoScreen.tsx`.
  if (moduleName.startsWith('@bare-example/')) {
    const sub = moduleName.slice('@bare-example/'.length);
    // Resolve with both .tsx and .ts in that order to match Metro defaults.
    for (const ext of ['.tsx', '.ts', '.js', '/index.tsx', '/index.ts', '/index.js']) {
      const candidate = path.resolve(bareExampleRoot, sub + ext);
      if (fs.existsSync(candidate)) {
        return { filePath: candidate, type: 'sourceFile' };
      }
    }
  }

  // Load SDK from TS source so edits hot-reload without rebuilding dist.
  if (moduleName === '@clevertap/native-display-sdk') {
    return {
      filePath: path.resolve(sdkRoot, 'src/index.ts'),
      type: 'sourceFile',
    };
  }

  // CleverTap RN SDK lives outside this monorepo as a file:// link;
  // resolve through the symlinked path so Metro can follow it.
  if (moduleName === 'clevertap-react-native') {
    return {
      filePath: require.resolve('clevertap-react-native', { paths: [__dirname] }),
      type: 'sourceFile',
    };
  }

  // Force `react` and `react-native` from THIS app's node_modules so we never
  // double-instantiate the runtime when files from sdkRoot try to import them.
  if (moduleName === 'react' || moduleName === 'react-native') {
    return {
      filePath: require.resolve(moduleName, { paths: [__dirname] }),
      type: 'sourceFile',
    };
  }

  // Route missing optional peer deps to a `module.exports = null` stub so
  // Metro can finish bundling. The SDK's `optionalDeps.ts` tryLoad() pattern
  // observes `null` and falls back to its degraded path at runtime.
  if (OPTIONAL_PEER_DEPS.includes(moduleName) && !isInstalled(moduleName)) {
    return { filePath: optionalStubPath, type: 'sourceFile' };
  }

  // Defer to Expo's default resolver (which honors expo-modules autolinking).
  if (upstreamResolveRequest) {
    return upstreamResolveRequest(context, moduleName, platform);
  }
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = config;
