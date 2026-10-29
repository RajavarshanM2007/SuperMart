# ApexMart - Modern E-Commerce Platform with Supabase Database

An interactive, full-featured E-Commerce web application built for the Web Programming course, featuring real database integration with **Supabase (Cloud PostgreSQL)**.

---

## 🌟 Key Features
1. **Product Catalog**:
   - Filter by categories: *Electronics, Audio & Wearables, Gaming, Fashion, Home & Office*.
   - Live real-time search & sorting (Low to High, High to Low, Top Rated).
   - Rich product cards with ratings, stock status, and add-to-cart controls.
2. **Shopping Cart & Checkout**:
   - Quantity management (+ / -), item removal, and subtotal calculation.
   - Discount coupon codes (e.g. `VIT20` for 20% off, `WELCOME10` for 10% off).
   - Shipping calculations, tax computations, and customer delivery address capture.
   - Payment method selection (Card, UPI / QR, Cash on Delivery).
3. **Supabase Database Integration**:
   - **`products` Table**: Fetches products directly from cloud PostgreSQL; allows adding & deleting products dynamically in Admin mode.
   - **`orders` Table**: Every placed order with customer details, order items JSON, and order code is committed to the Supabase database.
   - **Order History**: Displays real past orders retrieved from Supabase.
   - **Dual Mode**: Runs with local mock fallback out-of-the-box if Supabase credentials are not yet entered, so it never crashes!

---

## 🚀 How to Connect Your Supabase Project (3 Easy Steps)

### Step 1: Create a Free Project on Supabase
1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **"New Project"**, name it (e.g., `apex-ecommerce`), set a database password, and choose your preferred region.

### Step 2: Run the SQL Schema
1. In your Supabase Dashboard, click **"SQL Editor"** from the left navigation bar.
2. Open the file `supabase_schema.sql` located in this folder.
3. Copy all of the SQL text, paste it into the Supabase SQL Editor, and click **"Run"**.
   - This creates the `products` and `orders` tables.
   - Sets Row Level Security (RLS) policies so your frontend can read and write data.
   - Seeds the catalog with 20 real e-commerce products!

### Step 3: Connect Frontend to Supabase
1. In Supabase Dashboard, go to **Project Settings** (gear icon) -> **API**.
2. Copy:
   - **Project URL** (e.g., `https://abcdefghijkl.supabase.co`)
   - **Project API Keys** -> `anon` / `public` key.
3. Open `index.html` in your browser.
4. Click the **"Supabase: Setup Needed"** badge in the top right corner.
5. Paste your **Project URL** and **Anon API Key**, then click **"Save & Connect Database"**.
6. The status badge will turn green: `Supabase: Connected 🟢`!

---

## 💻 Running the Website
Simply double-click `index.html` to open it in Google Chrome, Microsoft Edge, or any web browser!
Or serve it via VS Code Live Server / Python:
```bash
python -m http.server 3000
```
Then visit `http://localhost:3000`.
