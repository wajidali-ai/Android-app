import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../providers/printer_provider.dart';

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  State<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().scanDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Printer', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Rescan Paired Devices',
            icon: const Icon(Icons.refresh),
            onPressed: printer.isScanning ? null : () => printer.scanDevices(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        children: [
          // 1. ACTIVE PRINTER STATUS BANNER
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: printer.isConnected ? AppTheme.brandSuccess.withOpacity(0.12) : Colors.grey.shade100,
              borderRadius: AppTheme.radiusLg,
              border: Border.all(
                color: printer.isConnected ? AppTheme.brandSuccess : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  printer.isConnected ? Icons.print : Icons.print_disabled,
                  color: printer.isConnected ? AppTheme.brandSuccess : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.isConnected ? 'Connected Printer' : 'No Printer Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: printer.isConnected ? AppTheme.brandSuccess : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        printer.isConnected
                            ? '${printer.connectedDeviceName ?? "Thermal Printer"} (${printer.paperWidth}mm)'
                            : 'Select a paired printer below to connect.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                if (printer.isConnected)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandDanger,
                      side: const BorderSide(color: AppTheme.brandDanger),
                    ),
                    onPressed: () => printer.disconnectPrinter(),
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLg),

          // 2. PAPER SIZE CONFIGURATION
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt Paper Width', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Standard pocket printers use 58mm', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight)),
                    ],
                  ),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 58, label: Text('58 mm')),
                      ButtonSegment(value: 80, label: Text('80 mm')),
                    ],
                    selected: {printer.paperWidth},
                    onSelectionChanged: (set) => printer.setPaperWidth(set.first),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // 3. TEST PRINT ACTION
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              minimumSize: const Size(AppTheme.minTouchTarget, 48),
            ),
            onPressed: (printer.isConnected && !printer.isPrinting) ? () => printer.printTest() : null,
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text('Print Test Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: AppTheme.spaceXl),

          // 4. PAIRED DEVICES LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paired Bluetooth Devices',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (printer.isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),

          if (printer.availableDevices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_searching, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: AppTheme.spaceSm),
                    const Text(
                      'No paired Bluetooth printers found',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1. Turn ON your thermal printer.\n2. Open your Android phone Settings > Bluetooth.\n3. Pair the printer (Default PIN usually 0000 or 1234).\n4. Return here and tap refresh.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            )
          else
            ...printer.availableDevices.map((device) {
              final isCurrent = printer.connectedDeviceName == device.name;
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? AppTheme.brandSuccess.withOpacity(0.2) : Colors.grey.shade200,
                    child: Icon(
                      Icons.print,
                      color: isCurrent ? AppTheme.brandSuccess : Colors.black54,
                    ),
                  ),
                  title: Text(
                    device.name.isNotEmpty ? device.name : 'Unknown Device',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    device.macAdress,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                  ),
                  trailing: isCurrent
                      ? const Chip(
                          label: Text('Connected', style: TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: AppTheme.brandSuccess,
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(60, 36),
                          ),
                          onPressed: () => printer.connectPrinter(device.macAdress, device.name),
                          child: const Text('Connect'),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
