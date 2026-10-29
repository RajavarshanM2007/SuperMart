\echo '##O1 original: anon checkout with a forged 99% discount (MacBook Air M2, price 1199)'
SET ROLE anon;
SELECT order_id AS o1 FROM fn_place_order(NULL, 'Guest', '9000000111', '1 Test Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0.99,
       jsonb_build_array(jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='MacBook Air M2'), 'quantity', 1))) \gset
SELECT order_code, discount, total_amount FROM orders WHERE order_id = :o1;
\echo '##O2 original: anon checkout in the name of customer priya'
SELECT user_id AS priya, phone AS old_phone FROM users WHERE username = 'priya' \gset
\echo priya phone before: :old_phone
SELECT order_id AS o2 FROM fn_place_order(:priya, 'Someone Else', '9999999999', '1 Other Street', 'Vellore', 'Tamil Nadu', '632014', 'UPI', 0,
       jsonb_build_array(jsonb_build_object('product_id', (SELECT product_id FROM products WHERE name='Yoga Mat Pro'), 'quantity', 1))) \gset
SELECT u.username, o.order_code, u.phone AS phone_after FROM orders o JOIN users u ON u.user_id = o.user_id WHERE o.order_id = :o2;
