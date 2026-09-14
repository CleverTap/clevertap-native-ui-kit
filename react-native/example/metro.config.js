const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const path = require('path');
const fs = require('fs');

const sdkRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(__dirname, '../../');
const ctSdkRoot = fs.realpathSync(path.resolve(__dirname, 'node_modules/clevertap-react-native'));

// Optional peer deps need no Metro stub here. The SDK loads each one through
// eval('require') in src/optional/optionalDeps.ts, so Metro never tries to
// resolve a missing package at bundle time. A missing package fails only at
// runtime, where the SDK catches it and the feature degrades gracefully.

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
      return context.resolveRequest(context, moduleName, platform);
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
