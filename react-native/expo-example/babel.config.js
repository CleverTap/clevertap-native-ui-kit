// Babel config for the Expo example app.
//
// `babel-preset-expo` is the standard preset for Expo projects - bundles JSX
// runtime config, hermes-compatible transforms, etc.
//
// `react-native-reanimated/plugin` MUST be the last plugin. It rewrites worklet
// functions and any plugins running after it could corrupt the transformed AST.
// This is the same rule the bare example follows.
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      'react-native-reanimated/plugin',
    ],
  };
};
