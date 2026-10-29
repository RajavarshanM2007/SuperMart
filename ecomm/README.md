# SuperMart – E-Commerce Database Management System

Course project for BCSE302L – Database Systems. SuperMart is a single-page web store (`index (1).html`) backed by a PostgreSQL database hosted on Supabase (`supabase_schema.sql`). Most of the business rules – stock checks, order totals, payment status and product ratings – are enforced inside the database with constraints, PL/pgSQL functions, procedures and triggers.

> An earlier version of this README described "ApexMart", a two-table design (`products`, `orders` with order items stored as JSON). That version has been replaced by the eight-table schema described below.

## Database

| Object | Contents |
|---|---|
| Tables (8) | `categories`, `products`, `users`, `addresses`, `orders`, `order_items`, `payments`, `reviews` |
| Constraints | primary and foreign keys, NOT NULL, UNIQUE, CHECK, DEFAULT |
| Indexes | `idx_products_category`, `idx_orders_user`, `idx_items_order` (plus key and unique indexes) |
| Functions (8) | `fn_place_order`, `fn_order_total`, `fn_register_user`, `fn_login`, `fn_change_password`, `fn_admin_reset_password`, `fn_run_update_order_status`, `fn_run_restock` |
| Procedures (3) | `sp_update_order_status`, `sp_restock_low_stock` (uses the cursor `cur_low`), `sp_apply_category_discount` |
| Triggers (5) | `trg_check_stock`, `trg_reduce_stock`, `trg_restore_stock`, `trg_payment_paid_at`, `trg_update_rating` |
| Extension | `pgcrypto` – passwords stored as bcrypt hashes |
| Sample data | 10 categories, 46 products, 10 users, 10 addresses, 10 orders, 12 order lines, 10 payments, 11 reviews |

The live Supabase project also contains orders placed later from the web page, so its row counts are higher than the seed data above.

## Web application features

- Catalogue with category filter, search and sorting; optional natural-language search through the Google Gemini API.
- Cart with promo codes `VIT20` (20%) and `WELCOME10` (10%), 5% tax, free shipping above 150.
- Checkout as guest or customer with card, UPI or cash on delivery; the whole order is saved by one call to `fn_place_order`.
- Order history, product reviews, registration, login and password change.
- Manager screens: add/delete products, ship/deliver/cancel orders, restock low stock, reset passwords, delete users.
- "Interactive DB Flow" panel describing the database work behind each action.
- Offline demo mode with built-in sample data when no Supabase URL/key has been entered (nothing is saved to a database in this mode).

## Setup

1. Create a Supabase project.
2. Open **SQL Editor**, paste the whole of `supabase_schema.sql` and run it. The script drops and recreates all eight tables, so do not run it on a project whose data you need.
3. In **Project Settings → API**, copy the Project URL and the `anon` public key.
4. Open `index (1).html` in a browser, click the database badge in the top bar, paste the URL and key, and save. The badge turns green when connected.

To run the script on a plain PostgreSQL server instead of Supabase, first run:

```sql
CREATE SCHEMA extensions;
CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN;
ALTER DATABASE <your_db> SET search_path = public, extensions;
```

## Known security limitations (do not use with real customer data)

Tests on a local copy of the database found that, with the current grants and Row Level Security policies (`USING (true)` on every table), anyone holding the public anon key can register as a manager, reset any user's password, change order totals and read all orders and personal details. The page also has password-less "quick login" buttons for the manager and a sample customer, and `fn_place_order` accepts any discount rate and customer id sent by the browser. The sample data contains demonstration passwords in plain text.

A tested working copy with fixes for several of these issues is in `../fixed_copy/` (see `CHANGES.md` there). It has **not** been deployed to the Supabase project. A complete fix needs Supabase Auth with per-user RLS policies.

## Documentation

- `../SuperMart_DBMS_Project_Report_Final_Verified.docx` – final project report.
- `../report_evidence/` – verification scripts, raw outputs and diagrams used in the report.
