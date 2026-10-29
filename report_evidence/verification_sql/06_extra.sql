\echo '##V1 view'
CREATE VIEW vw_order_summary AS
SELECT o.order_id, o.order_code, u.full_name AS customer, o.status,
       COUNT(oi.order_item_id) AS lines, SUM(oi.quantity) AS units,
       o.total_amount, pay.method, pay.status AS pay_status
FROM   orders o
JOIN   users u        ON u.user_id   = o.user_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN payments pay   ON pay.order_id = o.order_id
GROUP BY o.order_id, u.full_name, pay.method, pay.status;
SELECT order_code, customer, status, lines, units, total_amount, pay_status
FROM vw_order_summary WHERE status <> 'Delivered' ORDER BY total_amount DESC;
\echo '##V2 view not updatable'
UPDATE vw_order_summary SET status = 'Shipped' WHERE order_code = 'ORD-100004';
\echo '##V3 simple view updatable'
CREATE VIEW vw_low_stock AS SELECT product_id, name, stock FROM products WHERE stock < 10;
SELECT table_name, is_updatable FROM information_schema.views WHERE table_name IN ('vw_order_summary','vw_low_stock') ORDER BY 1;
DROP VIEW vw_low_stock; DROP VIEW vw_order_summary;
\echo '##S1 identity sequences'
SELECT pg_get_serial_sequence('public.orders','order_id') AS seq, last_value FROM orders_order_id_seq;
\echo '##S2 explicit id then default'
BEGIN;
INSERT INTO categories (category_id, name) VALUES (11, 'Stationery');
INSERT INTO categories (name) VALUES ('Pet Supplies');
ROLLBACK;
BEGIN;
INSERT INTO categories (category_id, name) VALUES (11, 'Stationery');
SELECT setval(pg_get_serial_sequence('public.categories','category_id'), (SELECT MAX(category_id) FROM categories));
INSERT INTO categories (name) VALUES ('Pet Supplies') RETURNING category_id, name;
ROLLBACK;
\echo '##ISO'
SHOW transaction_isolation;
SHOW deadlock_timeout;
