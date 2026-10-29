SELECT user_id AS uid FROM users WHERE username = 'synth_500' \gset
SELECT product_id AS pid FROM products WHERE name = 'Yoga Mat Pro' \gset
-- warm-up
SELECT COUNT(*) FROM orders WHERE user_id = :uid;
SELECT COUNT(*) FROM order_items WHERE product_id = :pid;
\echo '##E1 with idx_orders_user'
EXPLAIN (ANALYZE, COSTS OFF, TIMING ON, SUMMARY ON)
SELECT order_id, order_code, status, total_amount FROM orders WHERE user_id = :uid;
\echo '##E2 without idx_orders_user'
BEGIN;
DROP INDEX idx_orders_user;
EXPLAIN (ANALYZE, COSTS OFF, TIMING ON, SUMMARY ON)
SELECT order_id, order_code, status, total_amount FROM orders WHERE user_id = :uid;
ROLLBACK;
\echo '##E3 order lines of one order (idx_items_order)'
EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON)
SELECT p.name, oi.quantity, oi.unit_price
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
WHERE oi.order_id = 150000;
\echo '##E4 unindexed FK order_items.product_id'
EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON)
SELECT COUNT(*) FROM order_items WHERE product_id = :pid;
\echo '##E5 after proposed index'
BEGIN;
CREATE INDEX idx_items_product ON order_items(product_id);
ANALYZE order_items;
EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON)
SELECT COUNT(*) FROM order_items WHERE product_id = :pid;
ROLLBACK;
\echo '##E6 small table: planner prefers seq scan'
\c supermart
EXPLAIN SELECT order_id, order_code FROM orders WHERE user_id = 2;
