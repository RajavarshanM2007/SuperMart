-- Tests for supabase_schema_fixed.sql (run on a disposable local PostgreSQL database)
\set VERBOSITY terse
\echo '##F0 seed data after fix'
SELECT o.order_code, o.status, pay.method, pay.status AS pay_status, o.total_amount
FROM orders o JOIN payments pay ON pay.order_id = o.order_id ORDER BY o.order_id;
SELECT product_id, name FROM products ORDER BY product_id LIMIT 4;

\echo '##F1 anon registers with role manager'
SET ROLE anon;
SELECT username, role FROM fn_register_user('intruder', NULL, 'x12345', 'Not A Manager', 'manager');
\echo '##F2 anon updates an order total directly'
UPDATE orders SET total_amount = 1.00 WHERE order_code = 'ORD-100002';
\echo '##F3 anon resets the manager password'
SELECT fn_admin_reset_password(1, 'hijacked');
\echo '##F4 anon changes order status / restocks through the API wrappers'
SELECT fn_run_update_order_status(1, 'Cancelled');
SELECT fn_run_restock(10, 20);
\echo '##F5 anon updates a product price directly'
UPDATE products SET price = 1 WHERE product_id = 1;
\echo '##F6 anon still reads users without hashes'
SELECT username, role FROM users WHERE username = 'alex';
SELECT password_hash FROM users WHERE username = 'alex';
\echo '##F7 anon checkout with a forged 99% discount'
SELECT order_code FROM fn_place_order(NULL, 'Guest', '9000000111', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0.99,
       '[{"product_id": 21, "quantity": 1}]'::jsonb);
\echo '##F8 anon checkout with an unknown product'
SELECT order_code FROM fn_place_order(NULL, 'Guest', '9000000112', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0,
       '[{"product_id": 21, "quantity": 1}, {"product_id": 99999, "quantity": 3}]'::jsonb);
\echo '##F9 anon checkout for a non-existent customer id'
SELECT order_code FROM fn_place_order(424242, 'X', '9000000113', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0,
       '[{"product_id": 21, "quantity": 1}]'::jsonb);
\echo '##F10 anon valid checkout with VIT20 still works'
SELECT order_code, total_amount FROM fn_place_order(NULL, 'Guest Buyer', '9000000114', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014',
       'Cash on Delivery', 0.20, '[{"product_id": 20, "quantity": 1}]'::jsonb) \gset f10_
\echo :f10_order_code :f10_total_amount
\echo '##F11 anon login and new hash cost'
SELECT username, role FROM fn_login('alex', 'user123');
RESET ROLE;
SELECT left(password_hash, 7) AS hash_prefix FROM users WHERE username = 'intruder';
SELECT COUNT(*) AS orders_total FROM orders;

\echo '##F12 status transitions (run by the owner, as from the SQL editor)'
SELECT order_id AS oid FROM orders WHERE order_code = :'f10_order_code' \gset
CALL sp_update_order_status(:oid, 'Delivered');
CALL sp_update_order_status(:oid, 'Shipped');
CALL sp_update_order_status(:oid, 'Delivered');
CALL sp_update_order_status(:oid, 'Cancelled');
SELECT o.status, p.status AS pay_status FROM orders o JOIN payments p USING (order_id) WHERE o.order_id = :oid;

\echo '##F13 cancelling an unpaid COD order'
SELECT order_id AS cid FROM fn_place_order(NULL, 'COD Buyer', '9000000116', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014',
       'Cash on Delivery', 0, '[{"product_id": 21, "quantity": 2}]'::jsonb) \gset
SELECT o.status, p.method, p.status AS pay_status FROM orders o JOIN payments p USING (order_id) WHERE o.order_id = :cid;
CALL sp_update_order_status(:cid, 'Cancelled');
SELECT o.status, p.method, p.status AS pay_status FROM orders o JOIN payments p USING (order_id) WHERE o.order_id = :cid;
\echo '##F14 cancelled order cannot be re-confirmed'
CALL sp_update_order_status(:cid, 'Confirmed');

\echo '##F15 regression: stock check and atomic rollback still work'
SELECT (SELECT COUNT(*) FROM orders) AS orders, (SELECT stock FROM products WHERE name = 'Samsung 4K Smart TV') AS tv_stock;
SELECT order_code FROM fn_place_order(NULL, 'Bulk', '9000000115', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0,
       jsonb_build_array(jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='Samsung 4K Smart TV'), 'quantity', 50)));
SELECT (SELECT COUNT(*) FROM orders) AS orders, (SELECT stock FROM products WHERE name = 'Samsung 4K Smart TV') AS tv_stock;
