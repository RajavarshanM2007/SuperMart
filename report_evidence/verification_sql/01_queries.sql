\pset footer on
\echo '##Q1'
SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'users',       COUNT(*) FROM users
UNION ALL SELECT 'addresses',   COUNT(*) FROM addresses
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments',    COUNT(*) FROM payments
UNION ALL SELECT 'reviews',     COUNT(*) FROM reviews;
\echo '##Q2'
SELECT c.name AS category, COUNT(p.product_id) AS products
FROM   categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY products DESC, c.name;
\echo '##Q3'
SELECT p.name AS product, c.name AS category, p.price
FROM   products p
JOIN   categories c ON c.category_id = p.category_id
WHERE  c.name = 'Electronics' AND p.price > 500
ORDER BY p.price DESC;
\echo '##Q4'
SELECT o.order_code, u.full_name AS customer, a.city, o.status,
       pay.method, pay.status AS pay_status, o.total_amount
FROM   orders o
JOIN   users     u   ON u.user_id    = o.user_id
JOIN   addresses a   ON a.address_id = o.address_id
JOIN   payments  pay ON pay.order_id = o.order_id
ORDER BY o.order_id;
\echo '##Q5'
SELECT c.name AS category,
       SUM(oi.quantity)                 AS units_sold,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM   order_items oi
JOIN   orders     o ON o.order_id    = oi.order_id
JOIN   products   p ON p.product_id  = oi.product_id
JOIN   categories c ON c.category_id = p.category_id
WHERE  o.status <> 'Cancelled'
GROUP BY c.name
ORDER BY revenue DESC;
\echo '##Q6'
SELECT u.full_name AS customer,
       COUNT(o.order_id)   AS orders_placed,
       SUM(o.total_amount) AS total_spent
FROM   users u
JOIN   orders o ON o.user_id = u.user_id
GROUP BY u.user_id, u.full_name
HAVING COUNT(o.order_id) > 1;
\echo '##Q7'
SELECT name, stock FROM products WHERE stock < 10 ORDER BY stock, name;
\echo '##Q8'
SELECT p.name AS product, COUNT(r.review_id) AS reviews,
       ROUND(AVG(r.rating), 1) AS avg_rating, p.rating AS stored_rating
FROM   products p
JOIN   reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.name, p.rating
ORDER BY avg_rating DESC, p.name;
\echo '##Q9'
SELECT c.name AS category
FROM   categories c
WHERE  NOT EXISTS (SELECT 1 FROM products p WHERE p.category_id = c.category_id)
ORDER BY c.name;
\echo '##Q10'
SELECT name, price FROM products
WHERE  price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;
\echo '##Q11'
SELECT o.order_code, SUM(oi.quantity) AS items, o.total_amount
FROM   orders o JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_code, o.total_amount
ORDER BY o.total_amount DESC
LIMIT 5;
\echo '##Q12'
SELECT p.product_id, p.name, p.price
FROM   products p
LEFT JOIN reviews r ON r.product_id = p.product_id
WHERE  r.review_id IS NULL AND p.price > 100
ORDER BY p.price DESC;
\echo '##Q13'
SELECT status, COUNT(*) AS orders, SUM(total_amount) AS value
FROM   orders GROUP BY status ORDER BY orders DESC, status;
\echo '##Q14'
SELECT u.full_name AS customer, SUM(o.total_amount) AS spent,
       RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS rank
FROM   users u JOIN orders o ON o.user_id = u.user_id
WHERE  o.status <> 'Cancelled'
GROUP BY u.user_id, u.full_name
ORDER BY rank, customer;
\echo '##Q15'
SELECT product_id, name FROM products WHERE category_id <> 10
EXCEPT
SELECT p.product_id, p.name FROM products p JOIN order_items oi ON oi.product_id = p.product_id
ORDER BY product_id;
\echo '##Q16'
SELECT o.order_code, o.discount, o.total_amount,
       fn_order_total(o.order_id)                     AS items_minus_discount,
       ROUND(fn_order_total(o.order_id) * 1.05, 2)    AS with_tax
FROM orders o WHERE o.order_code IN ('ORD-100001','ORD-100010') ORDER BY o.order_code;
\echo '##Q17'
SELECT u.username FROM users u JOIN reviews r ON r.user_id = u.user_id
INTERSECT
SELECT u.username FROM users u JOIN orders o ON o.user_id = u.user_id
ORDER BY 1;
\echo '##Q18'
SELECT a.full_name AS customer, b.full_name AS same_city_customer, ad1.city
FROM   users a
JOIN   addresses ad1 ON ad1.user_id = a.user_id
JOIN   addresses ad2 ON ad2.city = ad1.city AND ad2.user_id > a.user_id
JOIN   users b ON b.user_id = ad2.user_id;
\echo '##Q19'
SELECT upper(left(u.full_name, 1)) || lower(substr(u.username, 2)) AS tag,
       length(u.email) AS email_len, split_part(u.email, '@', 2) AS domain,
       to_char(u.created_at, 'YYYY-MM-DD') AS joined
FROM users u WHERE u.role = 'customer' ORDER BY u.user_id LIMIT 4;
\echo '##Q20'
SELECT COUNT(*) AS products, MIN(price) AS cheapest, MAX(price) AS dearest,
       ROUND(AVG(price), 2) AS avg_price, SUM(stock) AS units_in_stock
FROM products;
\echo '##Q21'
SELECT c.name AS category, p.name AS product
FROM   products p RIGHT JOIN categories c ON c.category_id = p.category_id
WHERE  c.name IN ('Beauty','Books','Toys') ORDER BY c.name;
\echo '##Q22'
SELECT pm.method, s.status
FROM  (VALUES ('Credit/Debit Card'),('UPI'),('Cash on Delivery')) AS pm(method)
CROSS JOIN (VALUES ('Pending'),('Paid')) AS s(status)
ORDER BY 1, 2 LIMIT 6;
\echo '##Q23'
SELECT name, price FROM products
WHERE  product_id IN (SELECT product_id FROM order_items WHERE quantity >= 2)
ORDER BY name;
\echo '##Q24'
SELECT p.name, p.price, c.name AS category
FROM products p JOIN categories c ON c.category_id = p.category_id
WHERE p.price = (SELECT MAX(p2.price) FROM products p2 WHERE p2.category_id = p.category_id)
ORDER BY p.price DESC LIMIT 6;
\echo '##Q25'
SELECT DISTINCT a.state FROM addresses a ORDER BY a.state;
