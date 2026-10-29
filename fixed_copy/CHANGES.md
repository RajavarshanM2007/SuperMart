# Fixed working copy – what changed and how it was tested

These files are a **working copy only**. The originals in `../ecomm/` are unchanged and the Supabase project has **not** been modified.

| File | Based on |
|---|---|
| `supabase_schema_fixed.sql` | `../ecomm/supabase_schema.sql` (every change is marked `-- FIX`) |
| `index_fixed.html` | `../ecomm/index (1).html` |
| `tests_fixed.sql` / `tests_fixed.out` | tests and their raw output |

## Changes

| # | Problem in the original | Change in the working copy |
|---|---|---|
| 1 | `fn_register_user` lets the caller choose the role `manager` | Role is always `customer` (parameter kept but ignored) |
| 2 | `anon` can INSERT/UPDATE/DELETE orders, order_items, payments, addresses, categories and UPDATE products | Those privileges revoked; writes happen only inside SECURITY DEFINER functions |
| 3 | `anon` can call `fn_admin_reset_password`, `fn_run_update_order_status`, `fn_run_restock` | EXECUTE revoked from `PUBLIC`, `anon`, `authenticated`; manager runs them from the SQL editor |
| 4 | `fn_place_order` accepts any discount rate | New table `promo_codes`; rate must match an active code |
| 5 | Unknown product ids silently skipped; empty cart accepted | Error raised |
| 6 | Any `p_user_id` accepted | Must be an existing non-guest user (impersonation of a real customer is still possible without Supabase Auth) |
| 7 | Cart rows locked in arbitrary order (deadlock possible) | Items processed in `product_id` order |
| 8 | Any status change allowed (e.g. Delivered → Cancelled, Cancelled → Confirmed) | Only Confirmed → Shipped/Cancelled and Shipped → Delivered/Cancelled |
| 9 | Cancelling a COD order leaves payment Pending | Payment set to new status `Cancelled` |
| 10 | Seed totals omit shipping; shipped COD orders marked Paid | Seed uses the same shipping rule as checkout; COD paid only when delivered, card/UPI paid at order time |
| 11 | Seed identity values depend on join order | Seed inserts ordered, IDs identical across runs (checked with two loads) |
| 12 | bcrypt cost 6 | `gen_salt('bf', 10)` |
| 13 | No index on `order_items.product_id` | `idx_items_product` added |
| 14 | Password-less quick login (manager and customer) and a manager option on the registration form | Buttons and option removed; `quickLogin()` refuses |

## Still open (needs Supabase Auth and per-user RLS)

- Anyone with the anon key can still read all orders, addresses and user details (SELECT is still granted).
- Product insert/delete, review writes and user delete are still granted to `anon` because the current page uses them directly.
- A caller can still place an order under another existing customer's id.
- With the fixed grants, the manager panel's status-change, restock and password-reset buttons return "permission denied"; these actions must be run in the SQL editor until real authentication exists.

## How it was tested

PostgreSQL 16.15 in a disposable Docker container, with the preparation statements from the README. `tests_fixed.out` is the unedited output of `tests_fixed.sql` (only the `psql:` line prefixes were removed). `index_fixed.html` was syntax-checked with `node --check` and loaded in headless Microsoft Edge in offline demo mode; it was **not** tested against a live Supabase project.
