\echo '##L2 no transition rules'
SELECT order_id AS l2 FROM orders WHERE order_code = 'ORD-100008' \gset
SELECT o.status, oi.quantity, p.name, p.stock FROM orders o JOIN order_items oi USING (order_id) JOIN products p USING (product_id) WHERE o.order_id = :l2;
CALL sp_update_order_status(:l2, 'Cancelled');
SELECT o.status, p.stock, pay.status AS pay_status FROM orders o JOIN order_items oi USING (order_id) JOIN products p USING (product_id) JOIN payments pay ON pay.order_id = o.order_id WHERE o.order_id = :l2;
CALL sp_update_order_status(:l2, 'Confirmed');
SELECT o.status, p.stock, pay.status AS pay_status FROM orders o JOIN order_items oi USING (order_id) JOIN products p USING (product_id) JOIN payments pay ON pay.order_id = o.order_id WHERE o.order_id = :l2;

\echo '##L3 COD cancelled stays pending'
SELECT order_id AS l3 FROM orders WHERE order_code = 'ORD-100004' \gset
CALL sp_update_order_status(:l3, 'Cancelled');
SELECT o.status, p.method, p.status AS pay_status FROM orders o JOIN payments p USING (order_id) WHERE o.order_id = :l3;

\echo '##DCL grant revoke'
CREATE ROLE report_viewer LOGIN PASSWORD 'viewer_demo';
GRANT USAGE ON SCHEMA public TO report_viewer;
GRANT SELECT ON public.products, public.categories TO report_viewer;
SET ROLE report_viewer;
SELECT COUNT(*) AS visible_products FROM products;
UPDATE products SET price = 1 WHERE product_id = 1;
SELECT COUNT(*) FROM orders;
RESET ROLE;
REVOKE SELECT ON public.products FROM report_viewer;
SET ROLE report_viewer;
SELECT COUNT(*) FROM products;
RESET ROLE;

\echo '##SEC anon column grant'
SET ROLE anon;
SELECT username, role FROM users WHERE username = 'alex';
SELECT password_hash FROM users WHERE username = 'alex';
\echo '##SEC anon can register manager'
SELECT username, role FROM fn_register_user('intruder', NULL, 'x12345', 'Not A Manager', 'manager');
\echo '##SEC anon can rewrite order totals (RLS policy USING true)'
UPDATE orders SET total_amount = 1.00 WHERE order_code = 'ORD-100002' RETURNING order_code, total_amount;
\echo '##SEC anon can reset any password'
SELECT fn_admin_reset_password((SELECT user_id FROM users WHERE username='manager'), 'hijacked');
RESET ROLE;
SELECT username FROM fn_login('manager', 'hijacked');
\echo '##SEC policies'
SELECT tablename, policyname, cmd, qual, with_check FROM pg_policies WHERE schemaname='public' ORDER BY tablename;
