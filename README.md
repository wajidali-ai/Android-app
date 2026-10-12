# Mashallah Crockery Billing App ☕🍽️

A professional, offline-first Android billing and sales-record application built with Flutter, SQLite, and Supabase PostgreSQL for **Mashallah Crockery**, designed for multiple shopkeepers operating on separate Android phones.

> [!IMPORTANT]
> **This is a billing and sales-record application, NOT an inventory management system.**
> It does not track stock quantities, warehouse movements, or stock alerts. Items are entered directly on the counter with optional quick-pick crockery chips.

---

## ✨ Features Implemented

### 1. Create Bills & Sales Transactions
- Customer name and optional phone number.
- Dynamic line item entry (item description, quantity with steppers, unit price, automatic line totals).
- Instant calculation of Subtotal, Discount, and Grand Total.
- Full support for **Paid**, **Partially Paid**, and **Unpaid (Credit)** transactions with remaining balance calculation.
- Payment method support: **Cash**, **Online (Bank/JazzCash/Nayapay)**, and **Credit**.
- Quick-pick bar for frequently sold crockery items (Dinner sets, tea cups, platters, bowls) for high-speed counter billing.

### 2. Bluetooth Thermal Receipt Printing (ESC/POS)
- Compatible with all standard Bluetooth thermal printers (supports both **58mm pocket** and **80mm desktop** formats).
- Includes shop name, contact, customer name, sequential bill number, itemized table, totals, paid amount, balance, and return policy.
- **Strict Reliability Rule**: Every bill is **saved to SQLite before printing**. If Bluetooth disconnects or paper runs out, the bill is safely retained.
- One-tap reprinting of past bills.

### 3. Offline-First Architecture & SQLite Database
- Instant local save via atomic SQLite transaction (`DbHelper.dart`).
- Full bill history with search by customer, bill number, and phone.
- Filter by payment status (Paid, Partial, Unpaid) and date ranges.
- Transaction preservation: Completed bills can be cancelled with a mandatory audit reason, updating customer balances without hard-deleting records.

### 4. Multi-Shopkeeper & Multi-Phone Support
- Multi-phone coordination with unique device prefixes (`D1`, `D2`, etc.).
- Sequential non-colliding bill numbering: `MC-[DEVICE]-[YYYYMMDD]-[0001]`.
- Shopkeeper tracking per bill (`created_by_name`, `device_id`).

### 5. Supabase Cloud Synchronization
- Automatic background sync when mobile data or WiFi reconnects.
- Clear sync status badges: `Synced`, `Pending`, `Failed`.
- Pulls bills created by other shopkeepers to maintain unified shop records.

### 6. Customer Ledger & Outstanding Balances
- Automatic customer profile indexing.
- Real-time outstanding credit balances.
- Customer purchase ledger showing all past transactions.

### 7. Dashboard & Reporting
- Today's sales summary (gross revenue, cash collected, online collected, outstanding credit, bill count).
- Daily, weekly, and monthly sales reports calculated strictly from saved transactions.
- Sales volume and bill distribution by shopkeeper.

---

## 📁 Project Architecture

```
Rehan app/
├── .agents/
│   └── skills/
│       └── human-interface-guidelines/      # HIG & UI/UX design tokens
├── android/                                 # Native Android config & permissions
├── supabase/
│   ├── README.md                            # Step-by-step Supabase cloud setup
│   └── migrations/
│       └── 20261012000000_initial_schema.sql # PostgreSQL tables, RLS & sync RPC
├── lib/
│   ├── main.dart                            # App initialization
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart           # Defaults & starter crockery items
│   │   │   └── app_theme.dart               # Apple HIG styling & 8pt grid
│   │   ├── database/
│   │   │   └── db_helper.dart               # SQLite offline database
│   │   ├── printing/
│   │   │   └── printer_service.dart         # ESC/POS Bluetooth thermal printing
│   │   └── sync/
│   │       └── sync_service.dart            # Supabase offline-first sync
│   ├── models/
│   │   ├── bill.dart                        # Bill & line items models
│   │   ├── customer.dart                    # Customer ledger model
│   │   ├── shop.dart                        # Shop & shopkeeper models
│   │   └── print_job.dart                   # Print audit & frequent items
│   ├── providers/
│   │   ├── billing_provider.dart            # Active billing calculations
│   │   ├── bills_history_provider.dart      # History, search & filters
│   │   ├── dashboard_provider.dart          # Revenue & sales reports
│   │   ├── customer_provider.dart           # Customer ledger state
│   │   └── printer_provider.dart            # Bluetooth pairing & print jobs
│   └── screens/
│       ├── main_navigation_screen.dart      # 5-tab HIG navigation
│       ├── dashboard_screen.dart            # Daily metrics & recent bills
│       ├── create_bill_screen.dart          # Counter billing interface
│       ├── bill_detail_screen.dart          # Full bill view & reprint
│       ├── bills_history_screen.dart        # Search & filters
│       ├── customers_screen.dart            # Customer directory & balances
│       ├── reports_screen.dart              # Daily/weekly/monthly reports
│       ├── bluetooth_printer_screen.dart    # Thermal printer management
│       └── settings_screen.dart             # Shopkeeper profile & Supabase config
└── pubspec.yaml                             # Dependencies
```

---

## 🚀 How to Run & Build

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.3+)
- Android Studio or Android SDK

### Steps to Run
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Connect your Android phone with USB Debugging enabled, or start an emulator.
3. Run the application:
   ```bash
   flutter run
   ```
4. To build an APK for installation on shopkeepers' phones:
   ```bash
   flutter build apk --release
   ```
   The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
