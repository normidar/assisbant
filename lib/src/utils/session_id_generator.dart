import 'dart:math';

const _adjectives = [
  'swift', 'golden', 'silver', 'azure', 'crimson', 'jade', 'coral',
  'misty', 'sunny', 'starry', 'cozy', 'brave', 'calm', 'sharp', 'wild',
  'fuzzy', 'bright', 'lucky', 'fancy', 'sleepy', 'jolly', 'quirky',
  'mellow', 'snappy', 'zesty', 'breezy', 'chilly', 'stormy', 'cosmic',
  'silky', 'peppy', 'nifty', 'groovy', 'spunky', 'zippy', 'dandy',
];

const _nouns = [
  // Animals
  'panda', 'tiger', 'dolphin', 'penguin', 'flamingo', 'koala', 'hedgehog',
  'otter', 'fox', 'wolf', 'eagle', 'owl', 'peacock', 'swan', 'lynx',
  'gecko', 'sloth', 'bison', 'tapir', 'quokka', 'capybara', 'axolotl',
  // Fruits
  'mango', 'papaya', 'lemon', 'peach', 'cherry', 'kiwi', 'melon',
  'guava', 'lychee', 'plum', 'fig', 'lime', 'pear', 'apricot',
  // Plants
  'bamboo', 'fern', 'lotus', 'cedar', 'maple', 'willow', 'cactus',
  'orchid', 'ivy', 'jasmine', 'clover', 'dahlia', 'zinnia', 'sage',
];

String generateSessionId() {
  final rng = Random();
  final adj = _adjectives[rng.nextInt(_adjectives.length)];
  final noun = _nouns[rng.nextInt(_nouns.length)];
  return '$adj-$noun';
}
