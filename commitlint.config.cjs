module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
    'header-min-length': [2, 'always', 10],
  },
};
