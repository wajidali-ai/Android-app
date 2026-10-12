import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../models/bill.dart';
import '../printing/printer_service.dart';

/// Manages printer connection, device scanning, and printing state.
class PrinterProvider extends ChangeNotifier {
  List<BluetoothInfo> _availableDevices = [];
  bool _isScanning = false;
  bool _isPrinting = false;
  String? _statusMessage;

  List<BluetoothInfo> get availableDevices => _availableDevices;
  bool get isScanning => _isScanning;
  bool get isPrinting => _isPrinting;
  String? get statusMessage => _statusMessage;
  bool get isConnected => PrinterService.instance.isConnected;
  String? get connectedDeviceName => PrinterService.instance.connectedDeviceName;
  int get paperWidth => PrinterService.instance.paperWidth;

  Future<void> init() async {
    await PrinterService.instance.init();
    notifyListeners();
  }

  /// Scans for paired Bluetooth printers.
  Future<void> scanDevices() async {
    _isScanning = true;
    _statusMessage = 'Scanning for paired Bluetooth printers...';
    notifyListeners();

    try {
      _availableDevices = await PrinterService.instance.getPairedDevices();
      _statusMessage = _availableDevices.isEmpty
          ? 'No paired printers found. Please pair printer in Android Bluetooth settings first.'
          : 'Found ${_availableDevices.length} paired devices.';
    } catch (e) {
      _statusMessage = 'Error scanning devices: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Connects to a specific printer by MAC address.
  Future<bool> connectPrinter(String mac, String name) async {
    _statusMessage = 'Connecting to $name...';
    notifyListeners();

    final success = await PrinterService.instance.connect(mac, name);
    _statusMessage = success ? 'Connected to $name' : 'Failed to connect to $name';
    notifyListeners();
    return success;
  }

  /// Disconnects the active printer.
  Future<void> disconnectPrinter() async {
    await PrinterService.instance.disconnect();
    _statusMessage = 'Printer disconnected.';
    notifyListeners();
  }

  /// Updates paper width (58mm or 80mm).
  Future<void> setPaperWidth(int width) async {
    await PrinterService.instance.setPaperWidth(width);
    notifyListeners();
  }

  /// Prints a bill receipt.
  /// GUARANTEE: Does NOT touch or modify the saved bill if print fails.
  Future<bool> printBill(Bill bill, {bool isReprint = false}) async {
    _isPrinting = true;
    _statusMessage = isReprint ? 'Reprinting receipt...' : 'Printing receipt...';
    notifyListeners();

    final success = await PrinterService.instance.printBillReceipt(bill, isReprint: isReprint);
    _statusMessage = success
        ? 'Receipt printed successfully.'
        : 'Printing failed or printer not connected. Bill is safely saved.';
    _isPrinting = false;
    notifyListeners();
    return success;
  }

  /// Prints a test receipt.
  Future<bool> printTest() async {
    _isPrinting = true;
    _statusMessage = 'Printing test ticket...';
    notifyListeners();

    final success = await PrinterService.instance.printTestReceipt();
    _statusMessage = success ? 'Test receipt printed!' : 'Test print failed. Check printer.';
    _isPrinting = false;
    notifyListeners();
    return success;
  }
}
