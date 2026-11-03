module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    // Reanimated 4 split the worklets engine into `react-native-worklets`, and
    // the babel plugin moved here too. Using the old `react-native-reanimated/plugin`
    // with Reanimated 4 leaves worklets uninstrumented and the app silently fails
    // to mount on Android. Must be last in the plugin list.
    'react-native-worklets/plugin',
  ],
};
