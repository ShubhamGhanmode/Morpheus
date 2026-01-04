import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';

class CategoryRuleMatch {
  const CategoryRuleMatch({required this.category, required this.score});

  final String category;
  final int score;
}

final Map<String, List<String>> _ruleKeywordMap = {
  'Groceries': [
    'grocery',
    'supermarket',
    'market',
    'mart',
    'walmart',
    'target',
    'costco',
    'tesco',
    'aldi',
    'lidl',
    'kroger',
    'wholefoods',
    'whole foods',
    'sainsbury',
    'carrefour',
    'seven eleven',
    '7 eleven',
  ],
  'Vegetables': [
    'tomato',
    'potato',
    'onion',
    'carrot',
    'spinach',
    'lettuce',
    'cabbage',
    'broccoli',
    'cauliflower',
    'pepper',
    'capsicum',
    'cucumber',
    'garlic',
    'ginger',
    'mushroom',
    'okra',
    'eggplant',
    'aubergine',
    'zucchini',
    'beans',
    'peas',
    'corn',
    'sweetcorn',
    'beetroot',
  ],
  'Fruits': [
    'apple',
    'banana',
    'orange',
    'mango',
    'grape',
    'grapes',
    'pineapple',
    'berry',
    'berries',
    'strawberry',
    'blueberry',
    'raspberry',
    'watermelon',
    'melon',
    'kiwi',
    'pear',
    'peach',
    'plum',
    'pomegranate',
  ],
  'Milk': [
    'milk',
    'dairy',
    'yogurt',
    'cheese',
    'butter',
    'curd',
    'cream',
  ],
  'Alcohol': [
    'beer',
    'wine',
    'whiskey',
    'vodka',
    'rum',
    'gin',
    'tequila',
    'scotch',
    'bourbon',
    'brandy',
    'cider',
    'lager',
    'ipa',
    'stout',
    'heineken',
    'budweiser',
    'corona',
    'guinness',
    'stella',
    'carlsberg',
    'coors',
    'miller',
    'sapporo',
    'asahi',
    'modelo',
  ],
  'Rent': [
    'rent',
    'landlord',
    'lease',
    'apartment',
    'flat rent',
    'rental',
  ],
  'Tuition': [
    'tuition',
    'school',
    'college',
    'university',
    'course',
    'class',
    'exam fee',
    'semester',
  ],
  'Utilities': [
    'electric',
    'electricity',
    'water',
    'gas bill',
    'internet',
    'broadband',
    'wifi',
    'utility',
    'power',
    'sewer',
    'trash',
    'garbage',
  ],
  'Fuel': [
    'fuel',
    'gas',
    'petrol',
    'diesel',
    'shell',
    'bp',
    'esso',
    'chevron',
    'exxon',
    'texaco',
    'mobil',
  ],
  'Healthcare': [
    'pharmacy',
    'doctor',
    'clinic',
    'hospital',
    'medicine',
    'meds',
    'dentist',
    'dental',
    'optical',
    'vision',
    'therapy',
  ],
  'Dining Out': [
    'restaurant',
    'cafe',
    'coffee',
    'pizza',
    'burger',
    'diner',
    'takeout',
    'takeaway',
    'delivery',
    'uber eats',
    'ubereats',
    'doordash',
    'zomato',
    'swiggy',
    'deliveroo',
  ],
  'Entertainment': [
    'movie',
    'cinema',
    'theatre',
    'concert',
    'show',
    'ticket',
    'game',
    'steam',
    'playstation',
    'xbox',
    'nintendo',
    'arcade',
  ],
  'Travel': [
    'hotel',
    'flight',
    'airbnb',
    'booking',
    'expedia',
    'trip',
    'trip.com',
    'ticket',
    'visa',
    'train',
    'rail',
    'taxi',
    'uber',
    'lyft',
    'delta',
    'united',
    'american',
    'southwest',
    'ryanair',
    'easyjet',
    'jetblue',
    'lufthansa',
    'emirates',
    'qatar',
    'singapore',
    'air france',
    'british airways',
    'air india',
    'indigo',
    'spicejet',
  ],
  'Gadgets': [
    'phone',
    'laptop',
    'tablet',
    'ipad',
    'iphone',
    'android',
    'samsung',
    'pixel',
    'macbook',
    'airpods',
    'headphones',
    'earbuds',
    'charger',
  ],
  'Subscriptions': [
    'netflix',
    'spotify',
    'prime',
    'amazon prime',
    'disney',
    'hulu',
    'youtube',
    'youtube premium',
    'apple music',
    'icloud',
    'google one',
    'onedrive',
    'dropbox',
    'notion',
    'figma',
    'slack',
    'zoom',
    'adobe',
    'office 365',
    'microsoft 365',
    'chatgpt',
  ],
  'Savings': [
    'savings',
    'investment',
    'deposit',
    'brokerage',
    'mutual fund',
    'index fund',
  ],
  'Card Payment': [
    'card payment',
    'credit card',
    'cc payment',
    'card bill',
    'pay card',
  ],
};

List<String> ruleBasedCategorySuggestions({
  required String title,
  required List<ExpenseCategory> categories,
  int limit = 3,
}) {
  final trimmed = title.trim().toLowerCase();
  if (trimmed.isEmpty) return const [];

  final allowed = AppConfig.defaultExpenseCategories
      .map((seed) => seed.name.toLowerCase())
      .toSet();
  final categoryLookup = {
    for (final category in categories)
      category.name.toLowerCase(): category.name,
  };

  final tokens = _tokenize(trimmed);
  final matches = <CategoryRuleMatch>[];

  for (final entry in _ruleKeywordMap.entries) {
    final key = entry.key.toLowerCase();
    if (!allowed.contains(key)) continue;
    final categoryName = categoryLookup[key];
    if (categoryName == null) continue;

    var score = 0;
    for (final keyword in entry.value) {
      if (_keywordMatches(keyword.toLowerCase(), trimmed, tokens)) {
        score += 1;
      }
    }
    if (score > 0) {
      matches.add(CategoryRuleMatch(category: categoryName, score: score));
    }
  }

  matches.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.category.compareTo(b.category);
  });

  return matches.take(limit).map((match) => match.category).toList();
}

bool _keywordMatches(String keyword, String fullText, Set<String> tokens) {
  if (keyword.contains(' ') || keyword.contains('-')) {
    return fullText.contains(keyword);
  }
  return tokens.contains(keyword);
}

Set<String> _tokenize(String value) {
  final tokens = value
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toSet();
  return tokens;
}
