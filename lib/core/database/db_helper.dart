import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/bill.dart';
import '../../models/bill_item.dart';
import '../../models/customer.dart';
import '../../models/shop.dart';
import '../../models/print_job.dart';
import '../../models/frequent_item.dart';
import '../constants/app_constants.dart';

/// Local SQLite Database Helper for Mashallah Crockery.
/// Provides offline-first transactional storage.
class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mashallah_crockery_billing.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Shops table
    await db.execute('''
      CREATE TABLE shops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tagline TEXT,
        address TEXT,
        phone TEXT,
        receipt_header TEXT,
        receipt_footer TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Shop members table (Shopkeepers)
    await db.execute('''
      CREATE TABLE shop_members (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'shopkeeper',
        pin_code TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        total_balance REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Bills table
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        bill_number TEXT NOT NULL UNIQUE,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        created_by_member_id TEXT,
        created_by_name TEXT NOT NULL,
        device_id TEXT NOT NULL,
        bill_date TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0.0,
        discount REAL NOT NULL DEFAULT 0.0,
        grand_total REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        balance_amount REAL NOT NULL DEFAULT 0.0,
        payment_status TEXT NOT NULL DEFAULT 'paid',
        payment_method TEXT NOT NULL DEFAULT 'cash',
        status TEXT NOT NULL DEFAULT 'active',
        cancellation_reason TEXT,
        cancelled_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        sync_error TEXT
      )
    ''');

    // 5. Bill items table (Strictly NO inventory/stock references)
    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit_price REAL NOT NULL DEFAULT 0.0,
        line_total REAL NOT NULL DEFAULT 0.0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');

    // 6. Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        bill_id TEXT,
        customer_id TEXT,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        payment_date TEXT NOT NULL,
        notes TEXT,
        received_by_member_id TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    // 7. Print jobs table
    await db.execute('''
      CREATE TABLE print_jobs (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        printer_name TEXT,
        printer_mac TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        error_message TEXT,
        attempted_at TEXT NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');

    // 8. Frequent items table (Optional speed pick list - NO stock)
    await db.execute('''
      CREATE TABLE frequent_items (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        item_name TEXT NOT NULL UNIQUE,
        default_unit_price REAL NOT NULL DEFAULT 0.0,
        usage_count INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX idx_bills_date ON bills (bill_date DESC)');
    await db.execute('CREATE INDEX idx_bills_customer ON bills (customer_name)');
    await db.execute('CREATE INDEX idx_bills_sync ON bills (sync_status)');
    await db.execute('CREATE INDEX idx_bill_items_bill ON bill_items (bill_id)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers (phone)');

    // Seed default shop
    final defaultShop = Shop(
      id: AppConstants.defaultShopId,
      name: AppConstants.appName,
      phone: AppConstants.defaultShopPhone,
      address: AppConstants.defaultShopAddress,
      receiptHeader: AppConstants.receiptTitle,
      receiptFooter: AppConstants.receiptFooter,
    );
    await db.insert('shops', defaultShop.toMap());

    // Seed starter frequent items
    for (final item in AppConstants.starterFrequentItems) {
      final frequentItem = FrequentItem(
        shopId: AppConstants.defaultShopId,
        itemName: item['name'] as String,
        defaultUnitPrice: (item['price'] as num).toDouble(),
      );
      await db.insert('frequent_items', frequentItem.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ===========================================================================
  // BILL OPERATIONS (Offline-First Transactional)
  // ===========================================================================

  /// Saves a bill and all its line items immediately in an atomic SQLite transaction.
  /// Also updates or registers customer balance.
  Future<Bill> saveBill(Bill bill, List<BillItem> items) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. If customer phone provided, find or upsert customer
      String? customerId = bill.customerId;
      if (customerId == null && bill.customerPhone != null && bill.customerPhone!.trim().isNotEmpty) {
        final existing = await txn.query(
          'customers',
          where: 'phone = ?',
          whereArgs: [bill.customerPhone!.trim()],
        );
        if (existing.isNotEmpty) {
          customerId = existing.first['id'] as String;
        } else {
          final newCust = Customer(
            shopId: bill.shopId,
            name: bill.customerName,
            phone: bill.customerPhone?.trim(),
            totalBalance: bill.balanceAmount,
          );
          await txn.insert('customers', newCust.toMap());
          customerId = newCust.id;
        }
      }

      final billToSave = bill.copyWith(customerId: customerId);

      // 2. Insert Bill
      await txn.insert('bills', billToSave.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      // 3. Insert Line Items
      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [billToSave.id]);
      for (int i = 0; i < items.length; i++) {
        final item = items[i].copyWith(billId: billToSave.id, sortOrder: i);
        await txn.insert('bill_items', item.toMap());

        // Increment frequent item count
        await txn.rawInsert('''
          INSERT INTO frequent_items (id, shop_id, item_name, default_unit_price, usage_count)
          VALUES (?, ?, ?, ?, 1)
          ON CONFLICT(item_name) DO UPDATE SET
            usage_count = usage_count + 1,
            default_unit_price = excluded.default_unit_price
        ''', [
          DateTime.now().microsecondsSinceEpoch.toString(),
          billToSave.shopId,
          item.itemName,
          item.unitPrice
        ]);
      }

      // 4. Update Customer Balance if applicable
      if (customerId != null) {
        final balanceRes = await txn.rawQuery('''
          SELECT SUM(balance_amount) as total
          FROM bills
          WHERE customer_id = ? AND status = 'active'
        ''', [customerId]);
        final totalBal = (balanceRes.first['total'] as num?)?.toDouble() ?? 0.0;
        await txn.update(
          'customers',
          {
            'total_balance': totalBal,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [customerId],
        );
      }
    });

    return getBillWithItems(bill.id).then((b) => b ?? bill);
  }

  /// Retrieves a single bill with all its line items.
  Future<Bill?> getBillWithItems(String billId) async {
    final db = await database;
    final billRows = await db.query('bills', where: 'id = ?', whereArgs: [billId]);
    if (billRows.isEmpty) return null;

    final itemRows = await db.query(
      'bill_items',
      where: 'bill_id = ?',
      whereArgs: [billId],
      orderBy: 'sort_order ASC',
    );

    final items = itemRows.map((r) => BillItem.fromMap(r)).toList();
    return Bill.fromMap(billRows.first, items: items);
  }

  /// Queries bills with search and filters.
  Future<List<Bill>> getBills({
    String? searchQuery,
    String? paymentStatus, // 'all', 'paid', 'partial', 'unpaid'
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(customer_name LIKE ? OR bill_number LIKE ? OR customer_phone LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (paymentStatus != null && paymentStatus != 'all') {
      whereClauses.add('payment_status = ?');
      whereArgs.add(paymentStatus);
    }

    if (startDate != null) {
      whereClauses.add('bill_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('bill_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final rows = await db.query(
      'bills',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'bill_date DESC',
      limit: limit,
      offset: offset,
    );

    final List<Bill> bills = [];
    for (final r in rows) {
      final billId = r['id'] as String;
      final itemRows = await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: [billId],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map((ir) => BillItem.fromMap(ir)).toList();
      bills.add(Bill.fromMap(r, items: items));
    }

    return bills;
  }

  /// Cancels an active bill with a mandatory audit reason.
  Future<void> cancelBill(String billId, String reason, String cancelledByName) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'bills',
        {
          'status': 'cancelled',
          'cancellation_reason': reason,
          'cancelled_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': 'pending', // Queue update for cloud sync
        },
        where: 'id = ?',
        whereArgs: [billId],
      );

      // Recalculate customer balance if customer was attached
      final bill = await txn.query('bills', where: 'id = ?', whereArgs: [billId]);
      if (bill.isNotEmpty && bill.first['customer_id'] != null) {
        final custId = bill.first['customer_id'] as String;
        final balanceRes = await txn.rawQuery('''
          SELECT SUM(balance_amount) as total
          FROM bills
          WHERE customer_id = ? AND status = 'active'
        ''', [custId]);
        final totalBal = (balanceRes.first['total'] as num?)?.toDouble() ?? 0.0;
        await txn.update(
          'customers',
          {'total_balance': totalBal, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [custId],
        );
      }
    });
  }

  /// Generates the next sequential bill number for the current device and date.
  /// Format: MC-[DEVICE_PREFIX]-[YYYYMMDD]-[0001]
  Future<String> generateNextBillNumber(String devicePrefix) async {
    final db = await database;
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final prefix = 'MC-$devicePrefix-$dateStr-';

    final result = await db.rawQuery('''
      SELECT bill_number FROM bills
      WHERE bill_number LIKE ?
      ORDER BY bill_number DESC
      LIMIT 1
    ''', ['$prefix%']);

    int nextNum = 1;
    if (result.isNotEmpty) {
      final lastNumberStr = result.first['bill_number'] as String;
      final parts = lastNumberStr.split('-');
      if (parts.isNotEmpty) {
        final numPart = int.tryParse(parts.last);
        if (numPart != null) {
          nextNum = numPart + 1;
        }
      }
    }

    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }

  // ===========================================================================
  // DASHBOARD & REPORTS (Calculated strictly from actual saved transactions)
  // ===========================================================================

  /// Returns today's sales summary (Revenue, bills count, paid cash/online, outstanding balance).
  Future<Map<String, dynamic>> getTodaySalesSummary() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as bill_count,
        COALESCE(SUM(grand_total), 0.0) as total_sales,
        COALESCE(SUM(paid_amount), 0.0) as total_paid,
        COALESCE(SUM(balance_amount), 0.0) as total_balance,
        COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN paid_amount ELSE 0.0 END), 0.0) as cash_collected,
        COALESCE(SUM(CASE WHEN payment_method = 'online' THEN paid_amount ELSE 0.0 END), 0.0) as online_collected
      FROM bills
      WHERE bill_date BETWEEN ? AND ?
        AND status = 'active'
    ''', [startOfDay, endOfDay]);

    return result.first;
  }

  /// Calculates sales report for a specified date range (daily, weekly, monthly).
  Future<Map<String, dynamic>> getSalesReport(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final summary = await db.rawQuery('''
      SELECT
        COUNT(*) as total_bills,
        COALESCE(SUM(grand_total), 0.0) as total_sales,
        COALESCE(SUM(discount), 0.0) as total_discounts,
        COALESCE(SUM(paid_amount), 0.0) as total_paid,
        COALESCE(SUM(balance_amount), 0.0) as total_outstanding,
        COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as paid_bills_count,
        COUNT(CASE WHEN payment_status = 'partial' THEN 1 END) as partial_bills_count,
        COUNT(CASE WHEN payment_status = 'unpaid' THEN 1 END) as unpaid_bills_count
      FROM bills
      WHERE bill_date BETWEEN ? AND ?
        AND status = 'active'
    ''', [startStr, endStr]);

    // Breakdown by shopkeeper
    final shopkeeperBreakdown = await db.rawQuery('''
      SELECT
        created_by_name,
        COUNT(*) as bills_created,
        COALESCE(SUM(grand_total), 0.0) as sales_volume
      FROM bills
      WHERE bill_date BETWEEN ? AND ?
        AND status = 'active'
      GROUP BY created_by_name
      ORDER BY sales_volume DESC
    ''', [startStr, endStr]);

    return {
      'summary': summary.first,
      'by_shopkeeper': shopkeeperBreakdown,
    };
  }

  // ===========================================================================
  // SYNC QUEUE OPERATIONS
  // ===========================================================================

  /// Returns all bills that are pending synchronization or failed previously.
  Future<List<Bill>> getPendingSyncBills() async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );

    final List<Bill> bills = [];
    for (final r in rows) {
      final billId = r['id'] as String;
      final itemRows = await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: [billId],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map((ir) => BillItem.fromMap(ir)).toList();
      bills.add(Bill.fromMap(r, items: items));
    }
    return bills;
  }

  /// Marks a bill as successfully synced.
  Future<void> markBillSynced(String billId) async {
    final db = await database;
    await db.update(
      'bills',
      {
        'sync_status': 'synced',
        'sync_error': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  /// Marks a bill as failed sync with the error message.
  Future<void> markBillSyncFailed(String billId, String error) async {
    final db = await database;
    await db.update(
      'bills',
      {
        'sync_status': 'failed',
        'sync_error': error,
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  // ===========================================================================
  // PRINT JOBS & AUDIT
  // ===========================================================================

  Future<void> recordPrintJob(PrintJob job) async {
    final db = await database;
    await db.insert('print_jobs', job.toMap());
  }

  // ===========================================================================
  // CUSTOMERS & FREQUENT ITEMS
  // ===========================================================================

  Future<List<Customer>> getCustomers({String? query}) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR phone LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final rows = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'total_balance DESC, name ASC',
    );
    return rows.map((r) => Customer.fromMap(r)).toList();
  }

  Future<List<FrequentItem>> getFrequentItems({String? query}) async {
    final db = await database;
    final where = query != null && query.trim().isNotEmpty ? 'item_name LIKE ?' : null;
    final whereArgs = query != null && query.trim().isNotEmpty ? ['%${query.trim()}%'] : null;

    final rows = await db.query(
      'frequent_items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'usage_count DESC, item_name ASC',
      limit: 20,
    );
    return rows.map((r) => FrequentItem.fromMap(r)).toList();
  }
}
