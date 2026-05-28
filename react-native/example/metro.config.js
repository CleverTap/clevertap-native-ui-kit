const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const path = require('path');
const fs = require('fs');

const sdkRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(__dirname, '../../');
const ctSdkRoot = fs.realpathSync(path.resolve(__dirname, 'node_modules/clevertap-react-native'));

// Optional peer deps that may not be installed in this example app.
// Metro resolves require() statically at bundle time, so missing packages
// must be redirected to a stub - the tryLoad() try/catch handles it at runtime.
const OPTIONAL_PEER_DEPS = [
  'react-native-linear-gradient',
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

const config = {
  watchFolders: [sdkRoot, repoRoot, ctSdkRoot],
  resolver: {
    nodeModulesPaths: [
      path.resolve(__dirname, 'node_modules'),
      path.resolve(sdkRoot, 'node_modules'),
    ],
    resolveRequest: (context, moduleName, platform) => {
      if (moduleName === 'clevertap-react-native') {
        return {
          filePath: require.resolve('clevertap-react-native', { paths: [__dirname] }),
          type: 'sourceFile',
        };
      }
      if (moduleName === '@clevertap/native-display-sdk') {
        return {
          filePath: path.resolve(sdkRoot, 'src/index.ts'),
          type: 'sourceFile',
        };
      }
      // Force react and react-native to always resolve from example/node_modules.
      // npm v7+ auto-installs peer deps, so the SDK's node_modules also has
      // react-native. Metro's path-walking finds that copy first for files
      // inside sdkRoot, loading two separate instances and breaking TurboModules.
      if (moduleName === 'react' || moduleName === 'react-native') {
        return {
          filePath: require.resolve(moduleName, { paths: [__dirname] }),
          type: 'sourceFile',
        };
      }
      if (OPTIONAL_PEER_DEPS.includes(moduleName) && !isInstalled(moduleName)) {
        return { filePath: optionalStubPath, type: 'sourceFile' };
      }
      return context.resolveRequest(context, moduleName, platform);
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
