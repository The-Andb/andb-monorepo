-- ==========================================
-- STAGE Environment Schema
-- Generated at 2025-11-23 16:44:35.839893
-- ==========================================
-- ==========================================
-- 1. DDL: Tables
-- ==========================================
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product_tags;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS audit_logs;
DROP VIEW IF EXISTS v_user_order_summary;
DROP PROCEDURE IF EXISTS sp_process_order;
DROP FUNCTION IF EXISTS fn_get_user_level;

CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


CREATE TABLE user_profiles (
    user_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    address TEXT,
    birth_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);


CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    parent_id INT,
    FOREIGN KEY (parent_id) REFERENCES categories(id)
);


CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT,
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    description TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);


CREATE TABLE tags (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL
);


CREATE TABLE product_tags (
    product_id INT,
    tag_id INT,
    PRIMARY KEY (product_id, tag_id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);


CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    shipping_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);


CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);


CREATE TABLE reviews (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    rating TINYINT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);


CREATE TABLE audit_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(20),
    old_value JSON,
    new_value JSON,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. DDL: Indexes
-- ==========================================
CREATE INDEX idx_users_email ON users(email);
-- ==========================================
-- 3. DDL: Views
-- ==========================================

CREATE VIEW v_user_order_summary AS
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(o.id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    MAX(o.created_at) AS last_order_date
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;

-- ==========================================
-- 4. DDL: Stored Procedures
-- ==========================================
DELIMITER //

CREATE PROCEDURE sp_process_order(IN p_order_id INT)
BEGIN
    DECLARE v_status VARCHAR(20);
    
    SELECT status INTO v_status FROM orders WHERE id = p_order_id;
    
    IF v_status = 'pending' THEN
        UPDATE orders SET status = 'processing' WHERE id = p_order_id;
        -- Simulate some complex logic here
        INSERT INTO audit_logs (table_name, record_id, action, changed_at)
        VALUES ('orders', p_order_id, 'processed', NOW());
    END IF;
END //

DELIMITER ;
-- ==========================================
-- 5. DDL: Functions
-- ==========================================
DELIMITER //

CREATE FUNCTION fn_get_user_level(p_total_spent DECIMAL(12,2)) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_level VARCHAR(20);
    
    IF p_total_spent > 10000 THEN
        SET v_level = 'VIP';
    ELSEIF p_total_spent > 5000 THEN
        SET v_level = 'Gold';
    ELSEIF p_total_spent > 1000 THEN
        SET v_level = 'Silver';
    ELSE
        SET v_level = 'Bronze';
    END IF;
    
    RETURN v_level;
END //

DELIMITER ;
-- ==========================================
-- 6. DDL: Triggers
-- ==========================================
DELIMITER //

CREATE TRIGGER trg_products_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF OLD.price <> NEW.price THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_value, new_value)
        VALUES (
            'products', 
            NEW.id, 
            'price_change', 
            JSON_OBJECT('price', OLD.price), 
            JSON_OBJECT('price', NEW.price)
        );
    END IF;
END //

DELIMITER ;
-- ==========================================
-- 7. DML: Sample Data
-- ==========================================
INSERT INTO categories (id, name, description) VALUES (1, 'Electronics', 'All about Electronics');
INSERT INTO categories (id, name, description) VALUES (2, 'Books', 'All about Books');
INSERT INTO categories (id, name, description) VALUES (3, 'Clothing', 'All about Clothing');
INSERT INTO categories (id, name, description) VALUES (4, 'Home & Garden', 'All about Home & Garden');
INSERT INTO categories (id, name, description) VALUES (5, 'Toys', 'All about Toys');
INSERT INTO categories (id, name, description) VALUES (6, 'Sports', 'All about Sports');
INSERT INTO categories (id, name, description) VALUES (7, 'Beauty', 'All about Beauty');
INSERT INTO categories (id, name, description) VALUES (8, 'Automotive', 'All about Automotive');
INSERT INTO tags (id, name) VALUES (1, 'New Arrival');
INSERT INTO tags (id, name) VALUES (2, 'Best Seller');
INSERT INTO tags (id, name) VALUES (3, 'Sale');
INSERT INTO tags (id, name) VALUES (4, 'Limited Edition');
INSERT INTO tags (id, name) VALUES (5, 'Eco-friendly');
INSERT INTO users (id, username, email, password_hash) VALUES (1, 'davidmiller1', 'davidmiller1@example.com', 'hash_secret_1');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (1, 'David', 'Miller', '555-0101');
INSERT INTO users (id, username, email, password_hash) VALUES (2, 'laurawilliams2', 'laurawilliams2@example.com', 'hash_secret_2');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (2, 'Laura', 'Williams', '555-0102');
INSERT INTO users (id, username, email, password_hash) VALUES (3, 'michaeljohnson3', 'michaeljohnson3@example.com', 'hash_secret_3');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (3, 'Michael', 'Johnson', '555-0103');
INSERT INTO users (id, username, email, password_hash) VALUES (4, 'danieljohnson4', 'danieljohnson4@example.com', 'hash_secret_4');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (4, 'Daniel', 'Johnson', '555-0104');
INSERT INTO users (id, username, email, password_hash) VALUES (5, 'michaelbrown5', 'michaelbrown5@example.com', 'hash_secret_5');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (5, 'Michael', 'Brown', '555-0105');
INSERT INTO users (id, username, email, password_hash) VALUES (6, 'lauradavis6', 'lauradavis6@example.com', 'hash_secret_6');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (6, 'Laura', 'Davis', '555-0106');
INSERT INTO users (id, username, email, password_hash) VALUES (7, 'janegarcia7', 'janegarcia7@example.com', 'hash_secret_7');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (7, 'Jane', 'Garcia', '555-0107');
INSERT INTO users (id, username, email, password_hash) VALUES (8, 'danieldavis8', 'danieldavis8@example.com', 'hash_secret_8');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (8, 'Daniel', 'Davis', '555-0108');
INSERT INTO users (id, username, email, password_hash) VALUES (9, 'emilyrodriguez9', 'emilyrodriguez9@example.com', 'hash_secret_9');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (9, 'Emily', 'Rodriguez', '555-0109');
INSERT INTO users (id, username, email, password_hash) VALUES (10, 'chrisbrown10', 'chrisbrown10@example.com', 'hash_secret_10');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (10, 'Chris', 'Brown', '555-0110');
INSERT INTO users (id, username, email, password_hash) VALUES (11, 'michaelmartinez11', 'michaelmartinez11@example.com', 'hash_secret_11');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (11, 'Michael', 'Martinez', '555-0111');
INSERT INTO users (id, username, email, password_hash) VALUES (12, 'emilywilliams12', 'emilywilliams12@example.com', 'hash_secret_12');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (12, 'Emily', 'Williams', '555-0112');
INSERT INTO users (id, username, email, password_hash) VALUES (13, 'chrisjohnson13', 'chrisjohnson13@example.com', 'hash_secret_13');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (13, 'Chris', 'Johnson', '555-0113');
INSERT INTO users (id, username, email, password_hash) VALUES (14, 'sarahsmith14', 'sarahsmith14@example.com', 'hash_secret_14');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (14, 'Sarah', 'Smith', '555-0114');
INSERT INTO users (id, username, email, password_hash) VALUES (15, 'danielmartinez15', 'danielmartinez15@example.com', 'hash_secret_15');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (15, 'Daniel', 'Martinez', '555-0115');
INSERT INTO users (id, username, email, password_hash) VALUES (16, 'laurabrown16', 'laurabrown16@example.com', 'hash_secret_16');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (16, 'Laura', 'Brown', '555-0116');
INSERT INTO users (id, username, email, password_hash) VALUES (17, 'johnjones17', 'johnjones17@example.com', 'hash_secret_17');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (17, 'John', 'Jones', '555-0117');
INSERT INTO users (id, username, email, password_hash) VALUES (18, 'johnsmith18', 'johnsmith18@example.com', 'hash_secret_18');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (18, 'John', 'Smith', '555-0118');
INSERT INTO users (id, username, email, password_hash) VALUES (19, 'danielwilliams19', 'danielwilliams19@example.com', 'hash_secret_19');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (19, 'Daniel', 'Williams', '555-0119');
INSERT INTO users (id, username, email, password_hash) VALUES (20, 'janegarcia20', 'janegarcia20@example.com', 'hash_secret_20');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (20, 'Jane', 'Garcia', '555-0120');
INSERT INTO users (id, username, email, password_hash) VALUES (21, 'johnmiller21', 'johnmiller21@example.com', 'hash_secret_21');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (21, 'John', 'Miller', '555-0121');
INSERT INTO users (id, username, email, password_hash) VALUES (22, 'michaelsmith22', 'michaelsmith22@example.com', 'hash_secret_22');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (22, 'Michael', 'Smith', '555-0122');
INSERT INTO users (id, username, email, password_hash) VALUES (23, 'danielrodriguez23', 'danielrodriguez23@example.com', 'hash_secret_23');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (23, 'Daniel', 'Rodriguez', '555-0123');
INSERT INTO users (id, username, email, password_hash) VALUES (24, 'johnjohnson24', 'johnjohnson24@example.com', 'hash_secret_24');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (24, 'John', 'Johnson', '555-0124');
INSERT INTO users (id, username, email, password_hash) VALUES (25, 'lauramartinez25', 'lauramartinez25@example.com', 'hash_secret_25');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (25, 'Laura', 'Martinez', '555-0125');
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (1, 7, 'Product 1 - Lite', 'SKU-0001', 197.43, 51);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (2, 6, 'Product 2 - Pro', 'SKU-0002', 168.52, 30);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (3, 4, 'Product 3 - Plus', 'SKU-0003', 392.55, 27);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (4, 3, 'Product 4 - Max', 'SKU-0004', 484.18, 53);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (5, 5, 'Product 5 - Standard', 'SKU-0005', 78.39, 1);
INSERT INTO product_tags (product_id, tag_id) VALUES (5, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (6, 6, 'Product 6 - Lite', 'SKU-0006', 412.13, 81);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (7, 7, 'Product 7 - Pro', 'SKU-0007', 471.36, 29);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (8, 5, 'Product 8 - Max', 'SKU-0008', 61.91, 85);
INSERT INTO product_tags (product_id, tag_id) VALUES (8, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (9, 3, 'Product 9 - Max', 'SKU-0009', 440.56, 78);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (10, 2, 'Product 10 - Pro', 'SKU-0010', 232.29, 74);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (11, 7, 'Product 11 - Max', 'SKU-0011', 176.19, 6);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (12, 1, 'Product 12 - Standard', 'SKU-0012', 151.88, 38);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (13, 3, 'Product 13 - Max', 'SKU-0013', 318.94, 48);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (14, 7, 'Product 14 - Plus', 'SKU-0014', 239.35, 31);
INSERT INTO product_tags (product_id, tag_id) VALUES (14, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (15, 6, 'Product 15 - Max', 'SKU-0015', 76.44, 34);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (16, 8, 'Product 16 - Lite', 'SKU-0016', 447.88, 29);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (17, 5, 'Product 17 - Lite', 'SKU-0017', 421.67, 65);
INSERT INTO product_tags (product_id, tag_id) VALUES (17, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (18, 7, 'Product 18 - Max', 'SKU-0018', 328.73, 85);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (19, 4, 'Product 19 - Pro', 'SKU-0019', 396.74, 23);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (20, 7, 'Product 20 - Pro', 'SKU-0020', 304.54, 81);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (21, 7, 'Product 21 - Lite', 'SKU-0021', 118.81, 97);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (22, 1, 'Product 22 - Standard', 'SKU-0022', 238.88, 63);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (23, 2, 'Product 23 - Max', 'SKU-0023', 24.58, 47);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (24, 3, 'Product 24 - Lite', 'SKU-0024', 52.83, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (25, 7, 'Product 25 - Pro', 'SKU-0025', 479.29, 83);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (26, 4, 'Product 26 - Max', 'SKU-0026', 119.73, 35);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (27, 5, 'Product 27 - Max', 'SKU-0027', 298.4, 58);
INSERT INTO product_tags (product_id, tag_id) VALUES (27, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (28, 4, 'Product 28 - Plus', 'SKU-0028', 365.95, 81);
INSERT INTO product_tags (product_id, tag_id) VALUES (28, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (29, 7, 'Product 29 - Plus', 'SKU-0029', 321.03, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (30, 4, 'Product 30 - Plus', 'SKU-0030', 253.13, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (31, 5, 'Product 31 - Plus', 'SKU-0031', 315.84, 70);
INSERT INTO product_tags (product_id, tag_id) VALUES (31, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (32, 8, 'Product 32 - Pro', 'SKU-0032', 53.15, 62);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (33, 8, 'Product 33 - Plus', 'SKU-0033', 35.31, 0);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (34, 3, 'Product 34 - Standard', 'SKU-0034', 422.9, 28);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (35, 5, 'Product 35 - Lite', 'SKU-0035', 484.49, 46);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (36, 6, 'Product 36 - Lite', 'SKU-0036', 429.35, 73);
INSERT INTO product_tags (product_id, tag_id) VALUES (36, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (37, 6, 'Product 37 - Plus', 'SKU-0037', 128.96, 97);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (38, 6, 'Product 38 - Standard', 'SKU-0038', 499.27, 66);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (39, 1, 'Product 39 - Standard', 'SKU-0039', 97.24, 62);
INSERT INTO product_tags (product_id, tag_id) VALUES (39, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (40, 2, 'Product 40 - Lite', 'SKU-0040', 129.38, 31);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (41, 6, 'Product 41 - Standard', 'SKU-0041', 23.19, 8);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (42, 3, 'Product 42 - Plus', 'SKU-0042', 368.2, 29);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (43, 5, 'Product 43 - Max', 'SKU-0043', 476.02, 96);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (44, 5, 'Product 44 - Max', 'SKU-0044', 101.77, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (45, 3, 'Product 45 - Max', 'SKU-0045', 109.69, 81);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (46, 4, 'Product 46 - Max', 'SKU-0046', 13.69, 23);
INSERT INTO product_tags (product_id, tag_id) VALUES (46, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (47, 3, 'Product 47 - Lite', 'SKU-0047', 292.93, 37);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (48, 5, 'Product 48 - Max', 'SKU-0048', 329.0, 81);
INSERT INTO product_tags (product_id, tag_id) VALUES (48, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (49, 7, 'Product 49 - Lite', 'SKU-0049', 30.37, 55);
INSERT INTO product_tags (product_id, tag_id) VALUES (49, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (50, 3, 'Product 50 - Plus', 'SKU-0050', 137.77, 54);
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (1, 5, 'ORD-2024001', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 19, 1, 77.5, 77.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 35, 3, 15.9, 47.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 20, 2, 65.36, 130.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 27, 1, 28.83, 28.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 30, 1, 36.19, 36.19);
UPDATE orders SET total_amount = 320.94 WHERE id = 1;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (2, 21, 'ORD-2024002', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 23, 1, 57.88, 57.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 10, 2, 30.56, 61.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 34, 2, 89.77, 179.54);
UPDATE orders SET total_amount = 298.53999999999996 WHERE id = 2;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (3, 14, 'ORD-2024003', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 7, 2, 63.51, 127.02);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 20, 2, 67.9, 135.8);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 16, 2, 16.98, 33.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 19, 1, 39.07, 39.07);
UPDATE orders SET total_amount = 335.84999999999997 WHERE id = 3;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (4, 10, 'ORD-2024004', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 2, 2, 68.84, 137.68);
UPDATE orders SET total_amount = 137.68 WHERE id = 4;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (5, 6, 'ORD-2024005', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 45, 2, 93.07, 186.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 26, 1, 93.45, 93.45);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 31, 2, 40.56, 81.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 14, 2, 61.49, 122.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 34, 1, 70.42, 70.42);
UPDATE orders SET total_amount = 554.11 WHERE id = 5;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (6, 19, 'ORD-2024006', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 37, 3, 51.6, 154.8);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 6, 3, 86.04, 258.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 35, 2, 64.67, 129.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 38, 2, 44.91, 89.82);
UPDATE orders SET total_amount = 632.0799999999999 WHERE id = 6;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (7, 5, 'ORD-2024007', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 20, 1, 74.14, 74.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 16, 2, 77.89, 155.78);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 35, 3, 53.43, 160.29);
UPDATE orders SET total_amount = 390.21000000000004 WHERE id = 7;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (8, 1, 'ORD-2024008', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 17, 3, 32.53, 97.59);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 13, 1, 89.67, 89.67);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 5, 1, 27.52, 27.52);
UPDATE orders SET total_amount = 214.78 WHERE id = 8;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (9, 9, 'ORD-2024009', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 4, 1, 83.07, 83.07);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 37, 3, 26.9, 80.69999999999999);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 41, 1, 87.76, 87.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 7, 3, 21.39, 64.17);
UPDATE orders SET total_amount = 315.7 WHERE id = 9;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (10, 4, 'ORD-2024010', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 44, 3, 81.47, 244.41);
UPDATE orders SET total_amount = 244.41 WHERE id = 10;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (11, 25, 'ORD-2024011', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 21, 3, 85.65, 256.95000000000005);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 37, 1, 86.22, 86.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 27, 3, 89.11, 267.33);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 23, 3, 23.01, 69.03);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 40, 2, 26.82, 53.64);
UPDATE orders SET total_amount = 733.17 WHERE id = 11;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (12, 25, 'ORD-2024012', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (12, 25, 3, 12.99, 38.97);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (12, 14, 2, 40.76, 81.52);
UPDATE orders SET total_amount = 120.49 WHERE id = 12;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (13, 25, 'ORD-2024013', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 13, 1, 31.75, 31.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 8, 2, 68.29, 136.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 30, 2, 31.66, 63.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 45, 1, 56.09, 56.09);
UPDATE orders SET total_amount = 287.74 WHERE id = 13;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (14, 23, 'ORD-2024014', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 8, 1, 42.91, 42.91);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 36, 2, 29.07, 58.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 7, 1, 18.0, 18.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 29, 1, 43.4, 43.4);
UPDATE orders SET total_amount = 162.45 WHERE id = 14;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (15, 20, 'ORD-2024015', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 43, 3, 20.45, 61.349999999999994);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 35, 2, 52.31, 104.62);
UPDATE orders SET total_amount = 165.97 WHERE id = 15;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (16, 12, 'ORD-2024016', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 49, 2, 96.26, 192.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 28, 1, 54.44, 54.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 49, 1, 28.86, 28.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 22, 2, 63.97, 127.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 30, 2, 69.49, 138.98);
UPDATE orders SET total_amount = 542.74 WHERE id = 16;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (17, 3, 'ORD-2024017', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 2, 1, 10.45, 10.45);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 1, 1, 24.22, 24.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 20, 3, 54.84, 164.52);
UPDATE orders SET total_amount = 199.19 WHERE id = 17;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (18, 12, 'ORD-2024018', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 4, 1, 69.17, 69.17);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 48, 3, 91.99, 275.96999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 47, 1, 82.51, 82.51);
UPDATE orders SET total_amount = 427.65 WHERE id = 18;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (19, 7, 'ORD-2024019', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 38, 3, 86.31, 258.93);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 42, 1, 64.39, 64.39);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 38, 2, 27.07, 54.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 44, 2, 90.61, 181.22);
UPDATE orders SET total_amount = 558.68 WHERE id = 19;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (20, 13, 'ORD-2024020', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 21, 3, 32.08, 96.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 17, 3, 60.51, 181.53);
UPDATE orders SET total_amount = 277.77 WHERE id = 20;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (21, 10, 'ORD-2024021', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 24, 1, 23.12, 23.12);
UPDATE orders SET total_amount = 23.12 WHERE id = 21;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (22, 20, 'ORD-2024022', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 31, 1, 53.99, 53.99);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 11, 3, 64.07, 192.20999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 11, 1, 87.35, 87.35);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 16, 3, 32.37, 97.10999999999999);
UPDATE orders SET total_amount = 430.65999999999997 WHERE id = 22;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (23, 8, 'ORD-2024023', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (23, 5, 3, 14.57, 43.71);
UPDATE orders SET total_amount = 43.71 WHERE id = 23;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (24, 12, 'ORD-2024024', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 32, 1, 80.96, 80.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 29, 3, 56.94, 170.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 15, 1, 38.23, 38.23);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 17, 1, 45.07, 45.07);
UPDATE orders SET total_amount = 335.08 WHERE id = 24;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (25, 7, 'ORD-2024025', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 4, 3, 16.38, 49.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 24, 1, 74.09, 74.09);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 20, 2, 95.54, 191.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 38, 1, 17.52, 17.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 8, 3, 86.94, 260.82);
UPDATE orders SET total_amount = 592.65 WHERE id = 25;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (26, 12, 'ORD-2024026', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 38, 2, 57.95, 115.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 22, 3, 30.23, 90.69);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 8, 3, 59.24, 177.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 29, 2, 59.47, 118.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 2, 2, 48.28, 96.56);
UPDATE orders SET total_amount = 599.81 WHERE id = 26;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (27, 11, 'ORD-2024027', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 23, 2, 98.88, 197.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 40, 2, 72.44, 144.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 29, 2, 36.57, 73.14);
UPDATE orders SET total_amount = 415.78 WHERE id = 27;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (28, 2, 'ORD-2024028', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 12, 3, 59.94, 179.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 33, 1, 18.44, 18.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 34, 1, 29.16, 29.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 5, 3, 54.59, 163.77);
UPDATE orders SET total_amount = 391.19 WHERE id = 28;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (29, 3, 'ORD-2024029', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 4, 2, 53.47, 106.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 41, 3, 91.56, 274.68);
UPDATE orders SET total_amount = 381.62 WHERE id = 29;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (30, 17, 'ORD-2024030', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 5, 1, 13.4, 13.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 13, 2, 18.38, 36.76);
UPDATE orders SET total_amount = 50.16 WHERE id = 30;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (31, 8, 'ORD-2024031', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 15, 1, 42.04, 42.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 42, 1, 91.45, 91.45);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 10, 1, 54.69, 54.69);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 24, 2, 56.27, 112.54);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 41, 2, 59.7, 119.4);
UPDATE orders SET total_amount = 420.12 WHERE id = 31;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (32, 17, 'ORD-2024032', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 36, 1, 89.92, 89.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 30, 1, 34.79, 34.79);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 13, 3, 68.63, 205.89);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 42, 1, 13.17, 13.17);
UPDATE orders SET total_amount = 343.77000000000004 WHERE id = 32;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (33, 16, 'ORD-2024033', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 36, 3, 90.04, 270.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 2, 3, 99.85, 299.54999999999995);
UPDATE orders SET total_amount = 569.67 WHERE id = 33;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (34, 20, 'ORD-2024034', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 46, 1, 11.81, 11.81);
UPDATE orders SET total_amount = 11.81 WHERE id = 34;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (35, 25, 'ORD-2024035', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 40, 3, 91.96, 275.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 25, 2, 50.28, 100.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 29, 1, 26.72, 26.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 44, 3, 61.94, 185.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 9, 3, 46.66, 139.98);
UPDATE orders SET total_amount = 728.96 WHERE id = 35;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (36, 13, 'ORD-2024036', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 20, 1, 77.24, 77.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 44, 3, 35.44, 106.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 37, 2, 30.03, 60.06);
UPDATE orders SET total_amount = 243.62 WHERE id = 36;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (37, 11, 'ORD-2024037', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 50, 3, 50.2, 150.60000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 16, 3, 17.33, 51.989999999999995);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 24, 3, 76.86, 230.57999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 20, 2, 51.03, 102.06);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 19, 3, 25.64, 76.92);
UPDATE orders SET total_amount = 612.15 WHERE id = 37;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (38, 6, 'ORD-2024038', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (38, 40, 1, 35.89, 35.89);
UPDATE orders SET total_amount = 35.89 WHERE id = 38;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (39, 11, 'ORD-2024039', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (39, 32, 1, 75.91, 75.91);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (39, 5, 2, 71.03, 142.06);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (39, 43, 1, 70.83, 70.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (39, 40, 3, 93.16, 279.48);
UPDATE orders SET total_amount = 568.28 WHERE id = 39;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (40, 8, 'ORD-2024040', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 25, 3, 34.72, 104.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 6, 3, 47.96, 143.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 25, 3, 16.17, 48.510000000000005);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 46, 1, 37.51, 37.51);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 10, 2, 54.57, 109.14);
UPDATE orders SET total_amount = 443.2 WHERE id = 40;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (41, 2, 'ORD-2024041', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 7, 1, 16.09, 16.09);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 2, 1, 40.59, 40.59);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 50, 1, 15.06, 15.06);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 35, 3, 11.46, 34.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 26, 1, 19.7, 19.7);
UPDATE orders SET total_amount = 125.82000000000001 WHERE id = 41;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (42, 22, 'ORD-2024042', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (42, 37, 3, 94.62, 283.86);
UPDATE orders SET total_amount = 283.86 WHERE id = 42;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (43, 3, 'ORD-2024043', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (43, 19, 2, 98.58, 197.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (43, 36, 1, 11.43, 11.43);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (43, 10, 1, 57.25, 57.25);
UPDATE orders SET total_amount = 265.84000000000003 WHERE id = 43;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (44, 24, 'ORD-2024044', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 50, 1, 52.56, 52.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 35, 3, 88.86, 266.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 17, 3, 35.18, 105.53999999999999);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 24, 3, 30.34, 91.02);
UPDATE orders SET total_amount = 515.6999999999999 WHERE id = 44;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (45, 22, 'ORD-2024045', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (45, 9, 1, 26.7, 26.7);
UPDATE orders SET total_amount = 26.7 WHERE id = 45;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (46, 19, 'ORD-2024046', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 47, 2, 64.96, 129.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 24, 2, 64.82, 129.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 36, 1, 27.01, 27.01);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 5, 1, 44.92, 44.92);
UPDATE orders SET total_amount = 331.48999999999995 WHERE id = 46;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (47, 13, 'ORD-2024047', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (47, 30, 3, 91.44, 274.32);
UPDATE orders SET total_amount = 274.32 WHERE id = 47;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (48, 7, 'ORD-2024048', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 31, 2, 77.32, 154.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 8, 2, 12.73, 25.46);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 46, 1, 24.7, 24.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 26, 1, 79.22, 79.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 40, 2, 69.85, 139.7);
UPDATE orders SET total_amount = 423.71999999999997 WHERE id = 48;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (49, 13, 'ORD-2024049', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 44, 3, 66.16, 198.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 47, 1, 49.05, 49.05);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 21, 2, 66.29, 132.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 12, 2, 86.98, 173.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 43, 1, 87.03, 87.03);
UPDATE orders SET total_amount = 641.1 WHERE id = 49;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (50, 1, 'ORD-2024050', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 48, 1, 63.05, 63.05);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 39, 3, 82.48, 247.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 40, 1, 85.69, 85.69);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 10, 3, 59.66, 178.98);
UPDATE orders SET total_amount = 575.16 WHERE id = 50;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (51, 7, 'ORD-2024051', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (51, 6, 2, 30.93, 61.86);
UPDATE orders SET total_amount = 61.86 WHERE id = 51;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (52, 16, 'ORD-2024052', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 28, 1, 76.34, 76.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 25, 3, 16.34, 49.019999999999996);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 12, 2, 65.17, 130.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 42, 3, 67.65, 202.95000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 36, 3, 11.29, 33.87);
UPDATE orders SET total_amount = 492.52 WHERE id = 52;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (53, 22, 'ORD-2024053', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 40, 2, 15.79, 31.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 26, 1, 18.65, 18.65);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 21, 3, 12.19, 36.57);
UPDATE orders SET total_amount = 86.8 WHERE id = 53;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (54, 23, 'ORD-2024054', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (54, 44, 2, 27.76, 55.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (54, 50, 1, 35.67, 35.67);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (54, 5, 3, 61.33, 183.99);
UPDATE orders SET total_amount = 275.18 WHERE id = 54;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (55, 6, 'ORD-2024055', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (55, 20, 2, 43.01, 86.02);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (55, 46, 3, 87.79, 263.37);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (55, 15, 2, 19.85, 39.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (55, 32, 1, 70.18, 70.18);
UPDATE orders SET total_amount = 459.27 WHERE id = 55;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (56, 12, 'ORD-2024056', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 37, 3, 77.15, 231.45000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 38, 1, 84.23, 84.23);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 5, 2, 16.52, 33.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 14, 3, 32.0, 96.0);
UPDATE orders SET total_amount = 444.72 WHERE id = 56;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (57, 10, 'ORD-2024057', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (57, 18, 3, 99.36, 298.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (57, 12, 3, 83.85, 251.54999999999998);
UPDATE orders SET total_amount = 549.63 WHERE id = 57;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (58, 23, 'ORD-2024058', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 33, 3, 64.76, 194.28000000000003);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 7, 3, 11.35, 34.05);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 14, 2, 79.38, 158.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 1, 1, 87.77, 87.77);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 23, 1, 39.78, 39.78);
UPDATE orders SET total_amount = 514.64 WHERE id = 58;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (59, 24, 'ORD-2024059', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 31, 2, 89.72, 179.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 22, 2, 40.31, 80.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 25, 3, 20.07, 60.21);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 48, 2, 47.2, 94.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 8, 2, 83.12, 166.24);
UPDATE orders SET total_amount = 580.91 WHERE id = 59;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (60, 10, 'ORD-2024060', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 15, 1, 82.09, 82.09);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 27, 1, 94.71, 94.71);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 5, 3, 66.87, 200.61);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 21, 1, 92.92, 92.92);
UPDATE orders SET total_amount = 470.33000000000004 WHERE id = 60;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (61, 8, 'ORD-2024061', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 15, 1, 29.66, 29.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 29, 2, 44.85, 89.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 7, 2, 50.46, 100.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 30, 3, 84.78, 254.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 4, 3, 93.8, 281.4);
UPDATE orders SET total_amount = 756.02 WHERE id = 61;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (62, 14, 'ORD-2024062', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 29, 3, 19.24, 57.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 24, 2, 83.31, 166.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 20, 3, 77.34, 232.02);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 12, 1, 75.68, 75.68);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 13, 3, 18.79, 56.37);
UPDATE orders SET total_amount = 588.41 WHERE id = 62;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (63, 17, 'ORD-2024063', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 26, 2, 48.12, 96.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 43, 1, 10.83, 10.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 32, 2, 57.11, 114.22);
UPDATE orders SET total_amount = 221.29 WHERE id = 63;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (64, 20, 'ORD-2024064', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (64, 3, 1, 26.48, 26.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (64, 23, 2, 50.56, 101.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (64, 27, 2, 11.11, 22.22);
UPDATE orders SET total_amount = 149.82 WHERE id = 64;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (65, 16, 'ORD-2024065', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (65, 2, 2, 35.61, 71.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (65, 22, 2, 69.75, 139.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (65, 34, 3, 32.47, 97.41);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (65, 7, 3, 34.02, 102.06);
UPDATE orders SET total_amount = 410.19 WHERE id = 65;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (66, 9, 'ORD-2024066', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (66, 36, 2, 47.0, 94.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (66, 19, 2, 88.26, 176.52);
UPDATE orders SET total_amount = 270.52 WHERE id = 66;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (67, 5, 'ORD-2024067', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (67, 25, 2, 36.01, 72.02);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (67, 31, 3, 94.66, 283.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (67, 20, 2, 29.2, 58.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (67, 29, 3, 31.11, 93.33);
UPDATE orders SET total_amount = 507.72999999999996 WHERE id = 67;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (68, 8, 'ORD-2024068', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 16, 2, 59.75, 119.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 42, 2, 61.59, 123.18);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 35, 2, 13.62, 27.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 22, 1, 88.72, 88.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 20, 3, 14.59, 43.769999999999996);
UPDATE orders SET total_amount = 402.40999999999997 WHERE id = 68;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (69, 8, 'ORD-2024069', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (69, 16, 1, 25.85, 25.85);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (69, 16, 2, 99.17, 198.34);
UPDATE orders SET total_amount = 224.19 WHERE id = 69;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (70, 24, 'ORD-2024070', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 27, 2, 33.78, 67.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 7, 2, 87.47, 174.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 23, 1, 90.83, 90.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 45, 2, 29.95, 59.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 30, 3, 26.77, 80.31);
UPDATE orders SET total_amount = 473.53999999999996 WHERE id = 70;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (71, 15, 'ORD-2024071', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 38, 2, 49.33, 98.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 11, 1, 54.75, 54.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 24, 3, 58.19, 174.57);
UPDATE orders SET total_amount = 327.98 WHERE id = 71;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (72, 6, 'ORD-2024072', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 5, 1, 10.22, 10.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 48, 1, 50.9, 50.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 19, 1, 48.31, 48.31);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 22, 3, 35.51, 106.53);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 29, 1, 54.09, 54.09);
UPDATE orders SET total_amount = 270.05 WHERE id = 72;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (73, 12, 'ORD-2024073', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (73, 48, 1, 44.97, 44.97);
UPDATE orders SET total_amount = 44.97 WHERE id = 73;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (74, 4, 'ORD-2024074', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 14, 1, 33.76, 33.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 7, 2, 52.12, 104.24);
UPDATE orders SET total_amount = 138.0 WHERE id = 74;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (75, 6, 'ORD-2024075', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 36, 3, 65.7, 197.10000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 25, 2, 86.64, 173.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 26, 1, 43.33, 43.33);
UPDATE orders SET total_amount = 413.71 WHERE id = 75;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (76, 20, 'ORD-2024076', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (76, 33, 3, 72.26, 216.78000000000003);
UPDATE orders SET total_amount = 216.78000000000003 WHERE id = 76;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (77, 25, 'ORD-2024077', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 24, 3, 41.62, 124.85999999999999);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 7, 1, 12.64, 12.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 17, 3, 53.36, 160.07999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 46, 2, 60.15, 120.3);
UPDATE orders SET total_amount = 417.88 WHERE id = 77;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (78, 6, 'ORD-2024078', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (78, 39, 2, 95.43, 190.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (78, 33, 3, 65.52, 196.56);
UPDATE orders SET total_amount = 387.42 WHERE id = 78;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (79, 3, 'ORD-2024079', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (79, 6, 2, 64.62, 129.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (79, 37, 1, 19.82, 19.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (79, 14, 2, 33.87, 67.74);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (79, 3, 2, 43.09, 86.18);
UPDATE orders SET total_amount = 302.98 WHERE id = 79;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (80, 24, 'ORD-2024080', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (80, 18, 3, 22.11, 66.33);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (80, 11, 1, 62.51, 62.51);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (80, 44, 1, 95.0, 95.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (80, 41, 3, 32.73, 98.19);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (80, 22, 2, 61.43, 122.86);
UPDATE orders SET total_amount = 444.89 WHERE id = 80;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (81, 23, 'ORD-2024081', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 10, 3, 66.65, 199.95000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 42, 1, 46.16, 46.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 3, 2, 60.11, 120.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 34, 3, 67.0, 201.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 28, 2, 26.2, 52.4);
UPDATE orders SET total_amount = 619.73 WHERE id = 81;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (82, 10, 'ORD-2024082', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 18, 2, 68.98, 137.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 43, 3, 43.0, 129.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 26, 2, 34.96, 69.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 44, 3, 63.86, 191.57999999999998);
UPDATE orders SET total_amount = 528.46 WHERE id = 82;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (83, 10, 'ORD-2024083', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 32, 2, 93.19, 186.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 24, 2, 75.56, 151.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 42, 2, 26.78, 53.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 12, 1, 49.46, 49.46);
UPDATE orders SET total_amount = 440.52 WHERE id = 83;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (84, 23, 'ORD-2024084', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 11, 3, 44.41, 133.23);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 24, 1, 31.37, 31.37);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 18, 1, 36.56, 36.56);
UPDATE orders SET total_amount = 201.16 WHERE id = 84;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (85, 8, 'ORD-2024085', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (85, 49, 1, 46.96, 46.96);
UPDATE orders SET total_amount = 46.96 WHERE id = 85;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (86, 13, 'ORD-2024086', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (86, 35, 1, 35.16, 35.16);
UPDATE orders SET total_amount = 35.16 WHERE id = 86;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (87, 13, 'ORD-2024087', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 17, 3, 73.71, 221.13);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 34, 1, 13.11, 13.11);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 35, 3, 32.53, 97.59);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 42, 1, 91.9, 91.9);
UPDATE orders SET total_amount = 423.73 WHERE id = 87;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (88, 3, 'ORD-2024088', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (88, 10, 1, 84.97, 84.97);
UPDATE orders SET total_amount = 84.97 WHERE id = 88;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (89, 5, 'ORD-2024089', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (89, 28, 3, 26.48, 79.44);
UPDATE orders SET total_amount = 79.44 WHERE id = 89;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (90, 18, 'ORD-2024090', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 9, 2, 33.95, 67.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 39, 3, 68.21, 204.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 1, 3, 63.65, 190.95);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 10, 3, 33.56, 100.68);
UPDATE orders SET total_amount = 564.16 WHERE id = 90;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (91, 23, 'ORD-2024091', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 25, 2, 90.94, 181.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 27, 2, 56.95, 113.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 27, 2, 30.65, 61.3);
UPDATE orders SET total_amount = 357.08 WHERE id = 91;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (92, 11, 'ORD-2024092', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 46, 1, 88.67, 88.67);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 43, 2, 34.06, 68.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 3, 3, 84.62, 253.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 49, 3, 72.76, 218.28000000000003);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 4, 2, 18.13, 36.26);
UPDATE orders SET total_amount = 665.19 WHERE id = 92;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (93, 9, 'ORD-2024093', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (93, 29, 1, 57.17, 57.17);
UPDATE orders SET total_amount = 57.17 WHERE id = 93;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (94, 11, 'ORD-2024094', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (94, 44, 2, 33.45, 66.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (94, 27, 1, 72.64, 72.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (94, 33, 1, 17.02, 17.02);
UPDATE orders SET total_amount = 156.56000000000003 WHERE id = 94;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (95, 23, 'ORD-2024095', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 33, 2, 49.58, 99.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 48, 1, 52.57, 52.57);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 7, 2, 89.99, 179.98);
UPDATE orders SET total_amount = 331.71 WHERE id = 95;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (96, 13, 'ORD-2024096', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (96, 14, 3, 49.69, 149.07);
UPDATE orders SET total_amount = 149.07 WHERE id = 96;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (97, 24, 'ORD-2024097', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 24, 2, 36.02, 72.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 1, 1, 68.39, 68.39);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 19, 1, 85.84, 85.84);
UPDATE orders SET total_amount = 226.27 WHERE id = 97;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (98, 5, 'ORD-2024098', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (98, 41, 3, 10.44, 31.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (98, 10, 3, 62.12, 186.35999999999999);
UPDATE orders SET total_amount = 217.67999999999998 WHERE id = 98;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (99, 12, 'ORD-2024099', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (99, 39, 2, 89.1, 178.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (99, 21, 2, 50.12, 100.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (99, 30, 2, 86.95, 173.9);
UPDATE orders SET total_amount = 452.34000000000003 WHERE id = 99;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (100, 13, 'ORD-2024100', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (100, 1, 2, 86.5, 173.0);
UPDATE orders SET total_amount = 173.0 WHERE id = 100;
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (21, 2, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (24, 12, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (11, 6, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (12, 2, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (6, 1, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (6, 25, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (45, 10, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (20, 23, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (33, 2, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (43, 18, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (34, 8, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (13, 2, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (45, 9, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (45, 13, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (23, 17, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (41, 18, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (2, 15, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (49, 24, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (45, 12, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (41, 6, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (43, 9, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (3, 1, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (35, 25, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (15, 23, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (41, 19, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (49, 16, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (30, 14, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (17, 3, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (7, 25, 4, 'Great product!');
