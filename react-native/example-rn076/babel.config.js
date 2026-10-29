module.exports = {
  presets: ['module:@react-native/babel-preset'],
  // react-native-reanimated 3 needs this plugin. It must be the last entry.
  plugins: ['react-native-reanimated/plugin'],
};
