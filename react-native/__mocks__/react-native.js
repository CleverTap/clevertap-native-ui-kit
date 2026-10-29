module.exports = {
  Platform: {
    OS: 'ios',
    select: (obj) => obj.ios ?? obj.default,
  },
  Dimensions: {
    get: () => ({ width: 375, height: 812 }),
  },
  Linking: {
    openURL: jest.fn(() => Promise.resolve()),
  },
  InteractionManager: {
    runAfterInteractions: (cb) => { cb(); return { cancel: () => {} }; },
  },
};
