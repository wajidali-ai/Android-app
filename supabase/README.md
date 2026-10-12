# Mashallah Crockery — Supabase Database Setup Guide

This guide explains how to set up the cloud database for **Mashallah Crockery Billing App** using Supabase PostgreSQL.

---

## 1. Quick Setup in Supabase Dashboard

1. Go to [https://supabase.com](https://supabase.com) and log in.
2. Click **New Project** and name it `mashallah-crockery-db`. Set a secure database password.
3. Once the project finishes provisioning, go to **SQL Editor** on the left menu.
4. Click **New query**, open the migration file:
   [`supabase/migrations/20261012000000_initial_schema.sql`](./migrations/20261012000000_initial_schema.sql)
5. Paste the entire SQL script and click **Run**.

---

## 2. What the SQL Migration Creates

- **`shops`**: Stores shop details ("Mashallah Crockery", address, phone, receipt header/footer).
- **`shop_members`**: Authorized shopkeepers and staff with roles.
- **`devices`**: Tracks registered Android phones (prevents collisions).
- **`customers`**: Stores customer names, phone numbers, and running balance totals.
- **`bills`**: Primary sales transactions (bill number, customer, subtotal, discount, grand total, paid, balance, payment status, cancellation audit).
- **`bill_items`**: Line items per bill (Item description, quantity, unit price, line total). **Strictly NO inventory/stock deduction.**
- **`payments`**: Payment ledger records.
- **`print_jobs`**: Bluetooth printing attempts and status logs.
- **`frequent_items`**: Optional frequently entered items list for speed autocomplete.
- **`sync_bill_with_items(...)`**: Atomic PostgreSQL function that upserts a bill and all its line items in a single transaction.

---

## 3. Connecting Android Phones to Supabase

1. In Supabase Dashboard, go to **Project Settings** > **API**.
2. Copy your:
   - **Project URL** (e.g. `https://xyzabc.supabase.co`)
   - **Anon Public API Key** (e.g. `eyJhbGciOi...`)
3. Open the **Mashallah Crockery** app on each phone.
4. Go to the **Settings** tab.
5. Paste the Project URL and Anon Key into the Cloud Database fields.
6. Set each phone's **Device Code**:
   - Phone 1: `D1` (Shopkeeper: "Counter 1")
   - Phone 2: `D2` (Shopkeeper: "Counter 2")
7. Tap **Save Profile & Settings** and tap **Sync Now**.
