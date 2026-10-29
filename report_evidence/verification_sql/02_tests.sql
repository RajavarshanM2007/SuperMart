\set VERBOSITY default
\echo '##TX1 guest checkout'
SELECT name, stock FROM products WHERE name IN ('PlayStation 5 Console','Yoga Mat Pro') ORDER BY name;
SELECT * FROM fn_place_order(NULL, 'Test Guest', '9123456780', '12 Lake Road', 'Vellore', 'Tamil Nadu', '632014',
        'UPI', 0, (SELECT jsonb_agg(jsonb_build_object('product_id', product_id, 'quantity', q))
                   FROM (SELECT product_id, CASE WHEN name='Yoga Mat Pro' THEN 2 ELSE 1 END AS q
                         FROM products WHERE name IN ('PlayStation 5 Console','Yoga Mat Pro')) s)) \gset tx1_
SELECT o.order_code, u.username LIKE 'guest_%' AS guest_user, u.role, o.status, o.discount, o.total_amount
FROM orders o JOIN users u ON u.user_id = o.user_id WHERE o.order_id = :tx1_order_id;
SELECT p.name, oi.quantity, oi.unit_price FROM order_items oi JOIN products p USING (product_id) WHERE oi.order_id = :tx1_order_id ORDER BY p.name;
SELECT method, amount, status, paid_at IS NOT NULL AS paid_at_set FROM payments WHERE order_id = :tx1_order_id;
SELECT name, stock FROM products WHERE name IN ('PlayStation 5 Console','Yoga Mat Pro') ORDER BY name;

\echo '##TX2 customer checkout VIT20 COD'
SELECT * FROM fn_place_order((SELECT user_id FROM users WHERE username='priya'), 'Priya Sharma', '', 'Flat 12, Anna Nagar', 'Chennai', 'Tamil Nadu', '600040',
        'Cash on Delivery', 0.20, jsonb_build_array(jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='Database System Concepts'), 'quantity', 1))) \gset tx2_
SELECT o.order_code, o.discount, o.total_amount, pay.method, pay.status, pay.paid_at IS NULL AS paid_at_null
FROM orders o JOIN payments pay ON pay.order_id = o.order_id WHERE o.order_id = :tx2_order_id;

\echo '##TX3 insufficient stock -> whole call rolled back'
SELECT (SELECT COUNT(*) FROM orders) AS orders, (SELECT COUNT(*) FROM addresses) AS addresses,
       (SELECT COUNT(*) FROM users) AS users, (SELECT stock FROM products WHERE name='Samsung 4K Smart TV') AS tv_stock,
       (SELECT stock FROM products WHERE name='Yoga Mat Pro') AS mat_stock;
SELECT * FROM fn_place_order(NULL, 'Bulk Buyer', '9000000099', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0,
        jsonb_build_array(jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='Yoga Mat Pro'), 'quantity', 1),
                          jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='Samsung 4K Smart TV'), 'quantity', 50)));
SELECT (SELECT COUNT(*) FROM orders) AS orders, (SELECT COUNT(*) FROM addresses) AS addresses,
       (SELECT COUNT(*) FROM users) AS users, (SELECT stock FROM products WHERE name='Samsung 4K Smart TV') AS tv_stock,
       (SELECT stock FROM products WHERE name='Yoga Mat Pro') AS mat_stock;

\echo '##TX4 deliver COD order'
CALL sp_update_order_status(:tx2_order_id, 'Delivered');
SELECT o.status, pay.status AS pay_status, pay.paid_at IS NOT NULL AS paid_at_set
FROM orders o JOIN payments pay ON pay.order_id = o.order_id WHERE o.order_id = :tx2_order_id;

\echo '##TX5 cancel paid order'
CALL sp_update_order_status(:tx1_order_id, 'Cancelled');
SELECT o.status, pay.status AS pay_status FROM orders o JOIN payments pay ON pay.order_id = o.order_id WHERE o.order_id = :tx1_order_id;
SELECT name, stock FROM products WHERE name IN ('PlayStation 5 Console','Yoga Mat Pro') ORDER BY name;

\echo '##TX5b unknown order'
CALL sp_update_order_status(99999, 'Shipped');

\echo '##TX6 review trigger'
SELECT name, rating FROM products WHERE name = 'Sony WH-1000XM5';
INSERT INTO reviews (product_id, user_id, rating, comment)
VALUES ((SELECT product_id FROM products WHERE name='Sony WH-1000XM5'), (SELECT user_id FROM users WHERE username='priya'), 3, 'Ear cups get warm.');
SELECT name, rating FROM products WHERE name = 'Sony WH-1000XM5';
DELETE FROM reviews WHERE product_id = (SELECT product_id FROM products WHERE name='Sony WH-1000XM5');
SELECT name, rating FROM products WHERE name = 'Sony WH-1000XM5';

\echo '##TX7 restock cursor'
SELECT name, stock FROM products WHERE stock < 10 ORDER BY stock, name;
CALL sp_restock_low_stock(10, 20);
SELECT name, stock FROM products WHERE name IN ('Dyson V12 Cordless Vacuum','PlayStation 5 Console','Samsung 4K Smart TV','MacBook Air M2') ORDER BY name;

\echo '##TX8 category discount'
SELECT p.name, p.price FROM products p JOIN categories c USING (category_id) WHERE c.name='Gaming' ORDER BY p.name;
CALL sp_apply_category_discount('Gaming', 10);
SELECT p.name, p.price FROM products p JOIN categories c USING (category_id) WHERE c.name='Gaming' ORDER BY p.name;

\echo '##TX9 auth'
SELECT user_id, username, role FROM fn_register_user('nisha', 'nisha@vit.edu', 'pass1234', 'Nisha Rao');
SELECT left(password_hash, 7) AS hash_prefix, length(password_hash) AS hash_len FROM users WHERE username='nisha';
SELECT username, role FROM fn_login('NISHA@vit.edu', 'pass1234');
SELECT COUNT(*) AS rows_returned FROM fn_login('nisha', 'wrongpass');
SELECT fn_change_password((SELECT user_id FROM users WHERE username='nisha'), 'wrongpass', 'new5678') AS changed_with_wrong_old;
SELECT fn_change_password((SELECT user_id FROM users WHERE username='nisha'), 'pass1234', 'new5678') AS changed_with_right_old;
SELECT username FROM fn_login('nisha', 'new5678');
SELECT COUNT(*) AS guest_logins FROM users u, fn_login(u.username, 'anything') WHERE u.role='guest';

\echo '##C1 pincode'
INSERT INTO addresses (user_id, line1, city, state, pincode) VALUES (3, '1 Test Street', 'Mysuru', 'Karnataka', '5700');
\echo '##C2 duplicate review'
INSERT INTO reviews (product_id, user_id, rating)
VALUES ((SELECT product_id FROM products WHERE name='Apple iPhone 15 Pro'), (SELECT user_id FROM users WHERE username='priya'), 3);
\echo '##C3 FK restrict'
DELETE FROM products WHERE name = 'Apple iPhone 15 Pro';
\echo '##C4 price check'
UPDATE products SET price = 0 WHERE name = 'Yoga Mat Pro';
\echo '##C5 status check'
UPDATE orders SET status = 'Lost' WHERE order_code = 'ORD-100001';
\echo '##C6 rating range'
INSERT INTO reviews (product_id, user_id, rating) VALUES ((SELECT product_id FROM products WHERE name='Yoga Mat Pro'), 2, 6);
\echo '##C7 username length'
SELECT * FROM fn_register_user('ab', NULL, 'x', 'Too Short');
\echo '##C8 FK orphan'
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (99999, 1, 1, 10);
\echo '##C9 stock cannot go negative directly'
UPDATE products SET stock = stock - 1000 WHERE name = 'Yoga Mat Pro';

\echo '##SP savepoint'
BEGIN;
UPDATE products SET stock = stock + 5 WHERE name = 'Honey Jar 500g';
SAVEPOINT before_price;
UPDATE products SET price = price * 2 WHERE name = 'Honey Jar 500g';
SELECT name, price, stock FROM products WHERE name = 'Honey Jar 500g';
ROLLBACK TO SAVEPOINT before_price;
COMMIT;
SELECT name, price, stock FROM products WHERE name = 'Honey Jar 500g';

\echo '##L1 unknown product id silently skipped'
SELECT order_code, total_amount FROM fn_place_order(NULL, 'Ghost Item', '9000000098', '2 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0,
   jsonb_build_array(jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='Yoga Mat Pro'), 'quantity', 1),
                     jsonb_build_object('product_id', 99999, 'quantity', 3))) \gset l1_
SELECT COUNT(*) AS lines_saved FROM order_items oi JOIN orders o USING (order_id) WHERE o.order_code = :'l1_order_code';

\echo '##L2 no transition rules'
SELECT stock AS mat_stock_before FROM products WHERE name='Yoga Mat Pro';
CALL sp_update_order_status((SELECT order_id FROM orders WHERE order_code = :'l1_order_code'), 'Cancelled');
CALL sp_update_order_status((SELECT order_id FROM orders WHERE order_code = :'l1_order_code'), 'Confirmed');
SELECT o.status, (SELECT stock FROM products WHERE name='Yoga Mat Pro') AS mat_stock_after FROM orders o WHERE o.order_code = :'l1_order_code';

\echo '##L3 COD cancelled stays pending'
CALL sp_update_order_status((SELECT order_id FROM orders WHERE order_code='ORD-100004'), 'Cancelled');
SELECT o.status, p.method, p.status AS pay_status FROM orders o JOIN payments p USING (order_id) WHERE o.order_code='ORD-100004';
