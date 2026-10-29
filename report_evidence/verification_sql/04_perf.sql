-- Synthetic load for plan comparison only (run in a separate database "perf")
ALTER TABLE order_items DISABLE TRIGGER USER;
UPDATE products SET stock = 1000000;
INSERT INTO users (username, password_hash, full_name, role)
SELECT 'synth_' || g, 'x', 'Synthetic ' || g, 'customer' FROM generate_series(1, 2000) g;
INSERT INTO addresses (user_id, line1, city, state, pincode)
SELECT user_id, 'Line', 'City', 'State', '600001' FROM users WHERE username LIKE 'synth_%';
INSERT INTO orders (order_code, user_id, address_id, status, total_amount)
SELECT 'SYN-' || g, a.user_id, a.address_id, (ARRAY['Confirmed','Shipped','Delivered','Cancelled'])[1 + g % 4], 100
FROM generate_series(1, 200000) g
JOIN (SELECT row_number() OVER () AS rn, user_id, address_id FROM addresses WHERE line1 = 'Line') a ON a.rn = 1 + g % 2000;
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 1 + (o.order_id % 3), p.price
FROM orders o
JOIN LATERAL (SELECT product_id, price FROM products ORDER BY product_id OFFSET (o.order_id % 46) LIMIT 1) p ON true
WHERE o.order_code LIKE 'SYN-%';
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 1, p.price
FROM orders o JOIN products p ON p.product_id = 1 + (o.order_id * 7) % 46
WHERE o.order_code LIKE 'SYN-%';
ALTER TABLE order_items ENABLE TRIGGER USER;
ANALYZE;
SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM orders) AS orders, (SELECT COUNT(*) FROM order_items) AS order_items;
