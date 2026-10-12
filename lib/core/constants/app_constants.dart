/// Global application constants for Mashallah Crockery Billing.
class AppConstants {
  static const String appName = 'Mashallah Crockery';
  static const String defaultShopId = '00000000-0000-0000-0000-000000000001';
  static const String currencySymbol = 'Rs.';
  static const String defaultShopPhone = '0300-8451234';
  static const String defaultShopAddress = 'Shop #14, Main Crockery Bazaar, Lahore';

  // Receipt formatting
  static const String receiptTitle = 'MASHALLAH CROCKERY';
  static const String receiptTagline = 'Quality Dinner Sets, Glassware & Kitchenware';
  static const String receiptFooter = 'Thank you for your visit!\nExchange within 3 days with bill.\nNo cash refunds.';

  // Storage Keys
  static const String keyDeviceId = 'mashallah_device_id';
  static const String keyShopkeeperName = 'mashallah_shopkeeper_name';
  static const String keyShopkeeperId = 'mashallah_shopkeeper_id';
  static const String keyPrinterMac = 'mashallah_printer_mac';
  static const String keyPrinterName = 'mashallah_printer_name';
  static const String keyPaperWidth = 'mashallah_paper_width'; // 58 or 80
  static const String keySupabaseUrl = 'mashallah_supabase_url';
  static const String keySupabaseAnonKey = 'mashallah_supabase_anon_key';
  static const String keyLastSyncTime = 'mashallah_last_sync_time';

  // Frequently Sold Starter Items (Crockery specific - strictly NO stock tracking)
  static const List<Map<String, dynamic>> starterFrequentItems = [
    {'name': 'Dinner Plate (Ceramic)', 'price': 450.0},
    {'name': 'Quarter Plate (Ceramic)', 'price': 300.0},
    {'name': 'Soup Bowl with Spoon', 'price': 250.0},
    {'name': 'Rice Serving Platter', 'price': 1200.0},
    {'name': 'Curry Serving Bowl Large', 'price': 850.0},
    {'name': 'Glass Tumbler Set (6 Pcs)', 'price': 1500.0},
    {'name': 'Tea Cup & Saucer Set (6 Pcs)', 'price': 2800.0},
    {'name': 'Melamine Dinner Set (72 Pcs)', 'price': 18500.0},
    {'name': 'Bone China Dinner Set (72 Pcs)', 'price': 42000.0},
    {'name': 'Non-Stick Cooking Pot Large', 'price': 3800.0},
    {'name': 'Stainless Steel Cutlery Set', 'price': 4500.0},
    {'name': 'Water Pitcher with 6 Glasses', 'price': 2200.0},
  ];
}
