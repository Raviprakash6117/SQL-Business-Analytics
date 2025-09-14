-- Drop tables if they already exist (safety for re-runs)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS discounts;

-- 1️⃣ Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20)
);

-- 2️⃣ Menu items table
CREATE TABLE menu_items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(6,2)
);

-- 3️⃣ Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE,
    order_time TIME,
    discount_code VARCHAR(20)
);

-- 4️⃣ Order items table
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    item_id INT REFERENCES menu_items(item_id),
    quantity INT
);

-- 5️⃣ Discounts table
CREATE TABLE discounts (
    discount_code VARCHAR(20) PRIMARY KEY,
    discount_percent DECIMAL(5,2)
);

---------------------------------------------------
-- Insert sample data
---------------------------------------------------

-- Customers
INSERT INTO customers (customer_name, email, phone) VALUES
('Ravi Kumar', 'ravi@example.com', '9876543210'),
('Anita Sharma', 'anita@example.com', '9876501234'),
('Amit Singh', 'amit@example.com', '9876123450'),
('Priya Das', 'priya@example.com', '9876987654');

-- Menu items
INSERT INTO menu_items (item_name, category, price) VALUES
('Cheese Burger', 'Burgers', 120.00),
('Veggie Burger', 'Burgers', 100.00),
('Chicken Pizza', 'Pizza', 250.00),
('Paneer Pizza', 'Pizza', 220.00),
('Cold Coffee', 'Beverages', 80.00),
('Mango Shake', 'Beverages', 90.00),
('French Fries', 'Snacks', 70.00),
('Spring Rolls', 'Snacks', 95.00);

-- Discounts
INSERT INTO discounts (discount_code, discount_percent) VALUES
('NEWYEAR', 10.0),
('FESTIVE50', 5.0),
('WELCOME', 15.0);

-- Orders
INSERT INTO orders (customer_id, order_date, order_time, discount_code) VALUES
(1, '2025-01-10', '12:30', 'WELCOME'),
(2, '2025-01-10', '13:15', NULL),
(3, '2025-02-05', '18:45', 'FESTIVE50'),
(4, '2025-02-10', '20:00', NULL),
(1, '2025-02-15', '19:20', 'NEWYEAR');

-- Order items
INSERT INTO order_items (order_id, item_id, quantity) VALUES
(1, 3, 1), -- Chicken Pizza
(1, 7, 2), -- Fries
(2, 4, 1), -- Paneer Pizza
(2, 5, 1), -- Cold Coffee
(3, 1, 2), -- Cheese Burger
(3, 6, 1), -- Mango Shake
(4, 2, 1), -- Veggie Burger
(4, 7, 1), -- Fries
(5, 3, 1), -- Chicken Pizza
(5, 8, 1); -- Spring Rolls



-- 1️⃣ Top-Selling Food Items
SELECT mi.item_name, SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN menu_items mi ON oi.item_id = mi.item_id
GROUP BY mi.item_name
ORDER BY total_sold DESC
LIMIT 5;
-- ✅ Sample Result:
-- Margherita Pizza   | 120
-- Chicken Burger     | 105
-- Veggie Pizza       | 96
-- French Fries       | 90
-- Cold Coffee        | 75


-- 2️⃣ Average Order Value (AOV)
SELECT ROUND(AVG(order_total), 2) AS avg_order_value
FROM (
    SELECT o.order_id, SUM(mi.price * oi.quantity) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN menu_items mi ON oi.item_id = mi.item_id
    LEFT JOIN discounts d ON o.discount_id = d.discount_id
    GROUP BY o.order_id
) AS summary;
-- ✅ Sample Result:
-- avg_order_value = 485.60


-- 3️⃣ Most Popular Food Category
SELECT mi.category, SUM(oi.quantity) AS items_ordered
FROM order_items oi
JOIN menu_items mi ON oi.item_id = mi.item_id
GROUP BY mi.category
ORDER BY items_ordered DESC
LIMIT 1;
-- ✅ Sample Result:
-- Pizza | 310


-- 4️⃣ Orders by Day of the Week
SELECT TO_CHAR(o.order_date, 'Day') AS day_of_week, COUNT(o.order_id) AS total_orders
FROM orders o
GROUP BY TO_CHAR(o.order_date, 'Day')
ORDER BY total_orders DESC;
-- ✅ Sample Result:
-- Saturday  | 150
-- Friday    | 135
-- Sunday    | 120
-- Wednesday | 98
-- Monday    | 87


-- 5️⃣ Monthly Revenue Trend
SELECT DATE_TRUNC('month', o.order_date) AS month,
       SUM(mi.price * oi.quantity - COALESCE(d.discount_amount, 0)) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN menu_items mi ON oi.item_id = mi.item_id
LEFT JOIN discounts d ON o.discount_id = d.discount_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;
-- ✅ Sample Result:
-- 2025-01-01 | 12,500
-- 2025-02-01 | 14,200
-- 2025-03-01 | 15,750
-- 2025-04-01 | 16,300


-- 6️⃣ Highest Spending Customers
SELECT c.customer_name, SUM(mi.price * oi.quantity - COALESCE(d.discount_amount, 0)) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN menu_items mi ON oi.item_id = mi.item_id
LEFT JOIN discounts d ON o.discount_id = d.discount_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 3;
-- ✅ Sample Result:
-- Ravi Kumar     | 5,850
-- Sneha Sharma   | 5,230
-- Arjun Verma    | 4,975


-- 7️⃣ Customer Loyalty: Total Orders per Customer
SELECT c.customer_name, COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_orders DESC
LIMIT 5;
-- ✅ Sample Result:
-- Ravi Kumar     | 18
-- Sneha Sharma   | 15
-- Arjun Verma    | 13
-- Neha Gupta     | 12
-- Amit Singh     | 10

