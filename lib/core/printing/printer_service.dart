import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bill.dart';
import '../../models/print_job.dart';
import '../constants/app_constants.dart';
import '../database/db_helper.dart';

/// Service managing Bluetooth thermal printing for Mashallah Crockery.
/// Strictly implements:
/// - Bill MUST be saved before printing attempt.
/// - Saved bill is preserved if print fails.
/// - Full bill reprint support.
/// - Both 58mm (default standard) and 80mm paper widths.
class PrinterService {
  static final PrinterService instance = PrinterService._init();
  PrinterService._init();

  bool _isConnected = false;
  String? _connectedDeviceMac;
  String? _connectedDeviceName;
  int _paperWidth = 58; // 58mm or 80mm

  bool get isConnected => _isConnected;
  String? get connectedDeviceMac => _connectedDeviceMac;
  String? get connectedDeviceName => _connectedDeviceName;
  int get paperWidth => _paperWidth;

  /// Loads saved printer configuration from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedDeviceMac = prefs.getString(AppConstants.keyPrinterMac);
    _connectedDeviceName = prefs.getString(AppConstants.keyPrinterName);
    _paperWidth = prefs.getInt(AppConstants.keyPaperWidth) ?? 58;

    if (_connectedDeviceMac != null) {
      checkConnection();
    }
  }

  /// Scans for paired or nearby Bluetooth devices.
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      debugPrint('Error getting paired Bluetooth devices: $e');
      return [];
    }
  }

  /// Connects to selected Bluetooth printer.
  Future<bool> connect(String macAddress, String name) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      _isConnected = result;
      if (result) {
        _connectedDeviceMac = macAddress;
        _connectedDeviceName = name;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyPrinterMac, macAddress);
        await prefs.setString(AppConstants.keyPrinterName, name);
      }
      return result;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Disconnects from current printer.
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _isConnected = false;
    } catch (e) {
      debugPrint('Error disconnecting printer: $e');
    }
  }

  /// Checks active Bluetooth connection state.
  Future<bool> checkConnection() async {
    try {
      _isConnected = await PrintBluetoothThermal.connectionStatus;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Updates preferred paper width (58 or 80 mm).
  Future<void> setPaperWidth(int width) async {
    _paperWidth = width;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyPaperWidth, width);
  }

  // ===========================================================================
  // RECEIPT GENERATION & PRINT EXECUTION
  // ===========================================================================

  /// Prints the receipt for an already saved bill.
  /// GUARANTEE: If this method fails, the saved bill is untouched.
  Future<bool> printBillReceipt(Bill bill, {bool isReprint = false}) async {
    final printJob = PrintJob(
      billId: bill.id,
      printerName: _connectedDeviceName,
      printerMac: _connectedDeviceMac,
      status: PrintStatus.pending,
    );

    try {
      final isConn = await checkConnection();
      if (!isConn && _connectedDeviceMac != null) {
        // Attempt auto-reconnect once
        await connect(_connectedDeviceMac!, _connectedDeviceName ?? 'Thermal Printer');
      }

      if (!_isConnected) {
        // Record failed print job, do NOT throw or affect the bill
        await DbHelper.instance.recordPrintJob(
          PrintJob(
            billId: bill.id,
            printerName: _connectedDeviceName,
            printerMac: _connectedDeviceMac,
            status: PrintStatus.failed,
            errorMessage: 'Printer not connected. Please connect via Bluetooth Settings.',
          ),
        );
        return false;
      }

      final bytes = await _generateReceiptBytes(bill, isReprint: isReprint);
      final bool printResult = await PrintBluetoothThermal.writeBytes(bytes);

      await DbHelper.instance.recordPrintJob(
        PrintJob(
          billId: bill.id,
          printerName: _connectedDeviceName,
          printerMac: _connectedDeviceMac,
          status: printResult ? PrintStatus.success : PrintStatus.failed,
          errorMessage: printResult ? null : 'Failed to write bytes to printer.',
        ),
      );

      return printResult;
    } catch (e) {
      debugPrint('Exception during printing: $e');
      await DbHelper.instance.recordPrintJob(
        PrintJob(
          billId: bill.id,
          printerName: _connectedDeviceName,
          printerMac: _connectedDeviceMac,
          status: PrintStatus.failed,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  /// Prints a test receipt to verify printer alignment and paper feed.
  Future<bool> printTestReceipt() async {
    try {
      final isConn = await checkConnection();
      if (!isConn) return false;

      final profile = await CapabilityProfile.load();
      final paperSize = _paperWidth == 80 ? PaperSize.mm80 : PaperSize.mm58;
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.text(
        'MASHALLAH CROCKERY',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
      bytes += generator.text(
        'TEST PRINT OK',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.text('Thermal Printer is connected!', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('Error printing test receipt: $e');
      return false;
    }
  }

  /// Formats the complete ESC/POS receipt commands.
  Future<List<int>> _generateReceiptBytes(Bill bill, {bool isReprint = false}) async {
    final profile = await CapabilityProfile.load();
    final paperSize = _paperWidth == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paperSize, profile);

    List<int> bytes = [];
    bytes += generator.reset();

    // 1. SHOP HEADER
    bytes += generator.text(
      AppConstants.receiptTitle,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.text(
      AppConstants.receiptTagline,
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.text(
      AppConstants.defaultShopAddress,
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.text(
      'Tel: ${AppConstants.defaultShopPhone}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    if (isReprint) {
      bytes += generator.feed(1);
      bytes += generator.text(
        '*** DUPLICATE / REPRINT ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.hr();

    // 2. BILL METADATA
    final dateFormatted = DateFormat('dd-MM-yyyy  hh:mm a').format(bill.billDate);
    bytes += generator.row([
      PosColumn(text: 'Bill No: ${bill.billNumber}', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: bill.paymentStatus.name.toUpperCase(), width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text('Date: $dateFormatted');
    bytes += generator.text('Customer: ${bill.customerName}');
    if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) {
      bytes += generator.text('Phone: ${bill.customerPhone}');
    }
    bytes += generator.text('Shopkeeper: ${bill.createdByName}');

    bytes += generator.hr();

    // 3. ITEM COLUMNS
    // 58mm width usually fits 32 chars per line (or 42 on font B)
    if (_paperWidth == 80) {
      bytes += generator.row([
        PosColumn(text: 'Item Description', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(text: 'Total', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.hr();

      for (final item in bill.items) {
        bytes += generator.row([
          PosColumn(text: item.itemName, width: 6),
          PosColumn(text: item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2), width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: item.unitPrice.toStringAsFixed(0), width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: item.lineTotal.toStringAsFixed(0), width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      }
    } else {
      // 58mm compact layout
      bytes += generator.row([
        PosColumn(text: 'Item (Qty x Price)', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Amount', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.hr();

      for (final item in bill.items) {
        final qtyStr = item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2);
        final priceStr = item.unitPrice.toStringAsFixed(0);
        final totalStr = item.lineTotal.toStringAsFixed(0);

        bytes += generator.text(item.itemName, styles: const PosStyles(bold: true));
        bytes += generator.row([
          PosColumn(text: '  $qtyStr x Rs.$priceStr', width: 7),
          PosColumn(text: 'Rs. $totalStr', width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    // 4. TOTALS & AMOUNTS
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 7),
      PosColumn(text: 'Rs. ${bill.subtotal.toStringAsFixed(0)}', width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (bill.discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 7),
        PosColumn(text: '- Rs. ${bill.discount.toStringAsFixed(0)}', width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    // GRAND TOTAL (Emphasized)
    bytes += generator.row([
      PosColumn(text: 'GRAND TOTAL:', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: 'Rs. ${bill.grandTotal.toStringAsFixed(0)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Paid Amount (${bill.paymentMethod.name}):', width: 7),
      PosColumn(text: 'Rs. ${bill.paidAmount.toStringAsFixed(0)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    if (bill.balanceAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Remaining Balance:', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Rs. ${bill.balanceAmount.toStringAsFixed(0)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    // 5. FOOTER
    bytes += generator.hr();
    bytes += generator.text(
      AppConstants.receiptFooter,
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );

    // Feed and Cut
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
