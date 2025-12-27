class BanksDb {
  static Future<List<String>> fetchBankNames({
    String startsWith = '',
    int limit = 5,
  }) async {
    return const [];
  }

  static Future<List<Map<String, dynamic>>> fetchBanks() async {
    return const [];
  }

  static Future<String?> fetchBankIcon(String name) async {
    return null;
  }
}
