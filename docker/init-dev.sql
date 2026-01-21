-- ==========================================
-- DEV Environment Schema
-- Generated at 2025-11-23 16:44:35.807244
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
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);
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
INSERT INTO users (id, username, email, password_hash) VALUES (1, 'davidmartinez1', 'davidmartinez1@example.com', 'hash_secret_1');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (1, 'David', 'Martinez', '555-0101');
INSERT INTO users (id, username, email, password_hash) VALUES (2, 'davidjohnson2', 'davidjohnson2@example.com', 'hash_secret_2');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (2, 'David', 'Johnson', '555-0102');
INSERT INTO users (id, username, email, password_hash) VALUES (3, 'janegarcia3', 'janegarcia3@example.com', 'hash_secret_3');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (3, 'Jane', 'Garcia', '555-0103');
INSERT INTO users (id, username, email, password_hash) VALUES (4, 'johnbrown4', 'johnbrown4@example.com', 'hash_secret_4');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (4, 'John', 'Brown', '555-0104');
INSERT INTO users (id, username, email, password_hash) VALUES (5, 'janemartinez5', 'janemartinez5@example.com', 'hash_secret_5');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (5, 'Jane', 'Martinez', '555-0105');
INSERT INTO users (id, username, email, password_hash) VALUES (6, 'jessicadavis6', 'jessicadavis6@example.com', 'hash_secret_6');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (6, 'Jessica', 'Davis', '555-0106');
INSERT INTO users (id, username, email, password_hash) VALUES (7, 'lauramartinez7', 'lauramartinez7@example.com', 'hash_secret_7');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (7, 'Laura', 'Martinez', '555-0107');
INSERT INTO users (id, username, email, password_hash) VALUES (8, 'janedavis8', 'janedavis8@example.com', 'hash_secret_8');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (8, 'Jane', 'Davis', '555-0108');
INSERT INTO users (id, username, email, password_hash) VALUES (9, 'laurajones9', 'laurajones9@example.com', 'hash_secret_9');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (9, 'Laura', 'Jones', '555-0109');
INSERT INTO users (id, username, email, password_hash) VALUES (10, 'chriswilliams10', 'chriswilliams10@example.com', 'hash_secret_10');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (10, 'Chris', 'Williams', '555-0110');
INSERT INTO users (id, username, email, password_hash) VALUES (11, 'chrisbrown11', 'chrisbrown11@example.com', 'hash_secret_11');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (11, 'Chris', 'Brown', '555-0111');
INSERT INTO users (id, username, email, password_hash) VALUES (12, 'daviddavis12', 'daviddavis12@example.com', 'hash_secret_12');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (12, 'David', 'Davis', '555-0112');
INSERT INTO users (id, username, email, password_hash) VALUES (13, 'davidrodriguez13', 'davidrodriguez13@example.com', 'hash_secret_13');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (13, 'David', 'Rodriguez', '555-0113');
INSERT INTO users (id, username, email, password_hash) VALUES (14, 'danielmartinez14', 'danielmartinez14@example.com', 'hash_secret_14');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (14, 'Daniel', 'Martinez', '555-0114');
INSERT INTO users (id, username, email, password_hash) VALUES (15, 'laurasmith15', 'laurasmith15@example.com', 'hash_secret_15');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (15, 'Laura', 'Smith', '555-0115');
INSERT INTO users (id, username, email, password_hash) VALUES (16, 'michaeldavis16', 'michaeldavis16@example.com', 'hash_secret_16');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (16, 'Michael', 'Davis', '555-0116');
INSERT INTO users (id, username, email, password_hash) VALUES (17, 'janejones17', 'janejones17@example.com', 'hash_secret_17');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (17, 'Jane', 'Jones', '555-0117');
INSERT INTO users (id, username, email, password_hash) VALUES (18, 'sarahsmith18', 'sarahsmith18@example.com', 'hash_secret_18');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (18, 'Sarah', 'Smith', '555-0118');
INSERT INTO users (id, username, email, password_hash) VALUES (19, 'johnwilliams19', 'johnwilliams19@example.com', 'hash_secret_19');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (19, 'John', 'Williams', '555-0119');
INSERT INTO users (id, username, email, password_hash) VALUES (20, 'janemiller20', 'janemiller20@example.com', 'hash_secret_20');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (20, 'Jane', 'Miller', '555-0120');
INSERT INTO users (id, username, email, password_hash) VALUES (21, 'davidrodriguez21', 'davidrodriguez21@example.com', 'hash_secret_21');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (21, 'David', 'Rodriguez', '555-0121');
INSERT INTO users (id, username, email, password_hash) VALUES (22, 'michaelbrown22', 'michaelbrown22@example.com', 'hash_secret_22');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (22, 'Michael', 'Brown', '555-0122');
INSERT INTO users (id, username, email, password_hash) VALUES (23, 'johnsmith23', 'johnsmith23@example.com', 'hash_secret_23');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (23, 'John', 'Smith', '555-0123');
INSERT INTO users (id, username, email, password_hash) VALUES (24, 'chrisdavis24', 'chrisdavis24@example.com', 'hash_secret_24');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (24, 'Chris', 'Davis', '555-0124');
INSERT INTO users (id, username, email, password_hash) VALUES (25, 'janemartinez25', 'janemartinez25@example.com', 'hash_secret_25');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (25, 'Jane', 'Martinez', '555-0125');
INSERT INTO users (id, username, email, password_hash) VALUES (26, 'sarahbrown26', 'sarahbrown26@example.com', 'hash_secret_26');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (26, 'Sarah', 'Brown', '555-0126');
INSERT INTO users (id, username, email, password_hash) VALUES (27, 'lauradavis27', 'lauradavis27@example.com', 'hash_secret_27');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (27, 'Laura', 'Davis', '555-0127');
INSERT INTO users (id, username, email, password_hash) VALUES (28, 'davidjohnson28', 'davidjohnson28@example.com', 'hash_secret_28');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (28, 'David', 'Johnson', '555-0128');
INSERT INTO users (id, username, email, password_hash) VALUES (29, 'jessicamiller29', 'jessicamiller29@example.com', 'hash_secret_29');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (29, 'Jessica', 'Miller', '555-0129');
INSERT INTO users (id, username, email, password_hash) VALUES (30, 'jessicasmith30', 'jessicasmith30@example.com', 'hash_secret_30');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (30, 'Jessica', 'Smith', '555-0130');
INSERT INTO users (id, username, email, password_hash) VALUES (31, 'davidrodriguez31', 'davidrodriguez31@example.com', 'hash_secret_31');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (31, 'David', 'Rodriguez', '555-0131');
INSERT INTO users (id, username, email, password_hash) VALUES (32, 'johnjohnson32', 'johnjohnson32@example.com', 'hash_secret_32');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (32, 'John', 'Johnson', '555-0132');
INSERT INTO users (id, username, email, password_hash) VALUES (33, 'johndavis33', 'johndavis33@example.com', 'hash_secret_33');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (33, 'John', 'Davis', '555-0133');
INSERT INTO users (id, username, email, password_hash) VALUES (34, 'sarahsmith34', 'sarahsmith34@example.com', 'hash_secret_34');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (34, 'Sarah', 'Smith', '555-0134');
INSERT INTO users (id, username, email, password_hash) VALUES (35, 'sarahdavis35', 'sarahdavis35@example.com', 'hash_secret_35');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (35, 'Sarah', 'Davis', '555-0135');
INSERT INTO users (id, username, email, password_hash) VALUES (36, 'emilybrown36', 'emilybrown36@example.com', 'hash_secret_36');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (36, 'Emily', 'Brown', '555-0136');
INSERT INTO users (id, username, email, password_hash) VALUES (37, 'danielmiller37', 'danielmiller37@example.com', 'hash_secret_37');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (37, 'Daniel', 'Miller', '555-0137');
INSERT INTO users (id, username, email, password_hash) VALUES (38, 'johnmartinez38', 'johnmartinez38@example.com', 'hash_secret_38');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (38, 'John', 'Martinez', '555-0138');
INSERT INTO users (id, username, email, password_hash) VALUES (39, 'sarahsmith39', 'sarahsmith39@example.com', 'hash_secret_39');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (39, 'Sarah', 'Smith', '555-0139');
INSERT INTO users (id, username, email, password_hash) VALUES (40, 'lauragarcia40', 'lauragarcia40@example.com', 'hash_secret_40');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (40, 'Laura', 'Garcia', '555-0140');
INSERT INTO users (id, username, email, password_hash) VALUES (41, 'laurajones41', 'laurajones41@example.com', 'hash_secret_41');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (41, 'Laura', 'Jones', '555-0141');
INSERT INTO users (id, username, email, password_hash) VALUES (42, 'jessicasmith42', 'jessicasmith42@example.com', 'hash_secret_42');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (42, 'Jessica', 'Smith', '555-0142');
INSERT INTO users (id, username, email, password_hash) VALUES (43, 'chrisbrown43', 'chrisbrown43@example.com', 'hash_secret_43');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (43, 'Chris', 'Brown', '555-0143');
INSERT INTO users (id, username, email, password_hash) VALUES (44, 'davidmiller44', 'davidmiller44@example.com', 'hash_secret_44');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (44, 'David', 'Miller', '555-0144');
INSERT INTO users (id, username, email, password_hash) VALUES (45, 'laurajohnson45', 'laurajohnson45@example.com', 'hash_secret_45');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (45, 'Laura', 'Johnson', '555-0145');
INSERT INTO users (id, username, email, password_hash) VALUES (46, 'jessicawilliams46', 'jessicawilliams46@example.com', 'hash_secret_46');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (46, 'Jessica', 'Williams', '555-0146');
INSERT INTO users (id, username, email, password_hash) VALUES (47, 'sarahjohnson47', 'sarahjohnson47@example.com', 'hash_secret_47');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (47, 'Sarah', 'Johnson', '555-0147');
INSERT INTO users (id, username, email, password_hash) VALUES (48, 'emilydavis48', 'emilydavis48@example.com', 'hash_secret_48');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (48, 'Emily', 'Davis', '555-0148');
INSERT INTO users (id, username, email, password_hash) VALUES (49, 'johndavis49', 'johndavis49@example.com', 'hash_secret_49');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (49, 'John', 'Davis', '555-0149');
INSERT INTO users (id, username, email, password_hash) VALUES (50, 'danieljohnson50', 'danieljohnson50@example.com', 'hash_secret_50');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (50, 'Daniel', 'Johnson', '555-0150');
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (1, 7, 'Product 1 - Max', 'SKU-0001', 325.69, 100);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (2, 1, 'Product 2 - Plus', 'SKU-0002', 81.72, 95);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (3, 8, 'Product 3 - Lite', 'SKU-0003', 261.91, 94);
INSERT INTO product_tags (product_id, tag_id) VALUES (3, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (4, 7, 'Product 4 - Max', 'SKU-0004', 90.43, 78);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (5, 6, 'Product 5 - Standard', 'SKU-0005', 431.36, 66);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (6, 1, 'Product 6 - Plus', 'SKU-0006', 489.27, 86);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (7, 1, 'Product 7 - Pro', 'SKU-0007', 416.21, 14);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (8, 3, 'Product 8 - Max', 'SKU-0008', 267.58, 58);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (9, 2, 'Product 9 - Lite', 'SKU-0009', 53.96, 51);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (10, 4, 'Product 10 - Standard', 'SKU-0010', 267.57, 69);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (11, 5, 'Product 11 - Standard', 'SKU-0011', 54.91, 63);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (12, 1, 'Product 12 - Pro', 'SKU-0012', 106.09, 47);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (13, 3, 'Product 13 - Lite', 'SKU-0013', 301.25, 73);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (14, 4, 'Product 14 - Plus', 'SKU-0014', 371.36, 84);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (15, 4, 'Product 15 - Plus', 'SKU-0015', 318.52, 46);
INSERT INTO product_tags (product_id, tag_id) VALUES (15, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (16, 7, 'Product 16 - Lite', 'SKU-0016', 225.07, 93);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (17, 3, 'Product 17 - Standard', 'SKU-0017', 164.85, 17);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (18, 6, 'Product 18 - Max', 'SKU-0018', 420.86, 63);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (19, 6, 'Product 19 - Plus', 'SKU-0019', 454.06, 47);
INSERT INTO product_tags (product_id, tag_id) VALUES (19, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (20, 3, 'Product 20 - Lite', 'SKU-0020', 461.66, 11);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (21, 1, 'Product 21 - Standard', 'SKU-0021', 216.65, 9);
INSERT INTO product_tags (product_id, tag_id) VALUES (21, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (22, 8, 'Product 22 - Standard', 'SKU-0022', 315.84, 89);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (23, 4, 'Product 23 - Pro', 'SKU-0023', 480.06, 96);
INSERT INTO product_tags (product_id, tag_id) VALUES (23, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (24, 3, 'Product 24 - Plus', 'SKU-0024', 438.83, 37);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (25, 2, 'Product 25 - Lite', 'SKU-0025', 466.83, 8);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (26, 6, 'Product 26 - Plus', 'SKU-0026', 451.02, 36);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (27, 3, 'Product 27 - Lite', 'SKU-0027', 438.28, 89);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (28, 1, 'Product 28 - Pro', 'SKU-0028', 204.43, 51);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (29, 5, 'Product 29 - Pro', 'SKU-0029', 457.75, 66);
INSERT INTO product_tags (product_id, tag_id) VALUES (29, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (30, 3, 'Product 30 - Max', 'SKU-0030', 279.98, 32);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (31, 8, 'Product 31 - Plus', 'SKU-0031', 111.11, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (32, 8, 'Product 32 - Plus', 'SKU-0032', 474.19, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (32, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (33, 8, 'Product 33 - Plus', 'SKU-0033', 441.37, 62);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (34, 1, 'Product 34 - Pro', 'SKU-0034', 304.12, 99);
INSERT INTO product_tags (product_id, tag_id) VALUES (34, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (35, 4, 'Product 35 - Max', 'SKU-0035', 102.98, 86);
INSERT INTO product_tags (product_id, tag_id) VALUES (35, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (36, 3, 'Product 36 - Standard', 'SKU-0036', 240.83, 70);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (37, 3, 'Product 37 - Plus', 'SKU-0037', 329.62, 62);
INSERT INTO product_tags (product_id, tag_id) VALUES (37, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (38, 3, 'Product 38 - Max', 'SKU-0038', 379.66, 18);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (39, 7, 'Product 39 - Standard', 'SKU-0039', 82.09, 46);
INSERT INTO product_tags (product_id, tag_id) VALUES (39, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (40, 1, 'Product 40 - Lite', 'SKU-0040', 92.35, 67);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (41, 5, 'Product 41 - Standard', 'SKU-0041', 163.85, 62);
INSERT INTO product_tags (product_id, tag_id) VALUES (41, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (42, 8, 'Product 42 - Max', 'SKU-0042', 379.72, 29);
INSERT INTO product_tags (product_id, tag_id) VALUES (42, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (43, 8, 'Product 43 - Lite', 'SKU-0043', 398.89, 63);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (44, 4, 'Product 44 - Lite', 'SKU-0044', 91.03, 46);
INSERT INTO product_tags (product_id, tag_id) VALUES (44, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (45, 7, 'Product 45 - Plus', 'SKU-0045', 416.89, 66);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (46, 3, 'Product 46 - Pro', 'SKU-0046', 11.03, 73);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (47, 6, 'Product 47 - Standard', 'SKU-0047', 119.96, 7);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (48, 7, 'Product 48 - Standard', 'SKU-0048', 211.35, 28);
INSERT INTO product_tags (product_id, tag_id) VALUES (48, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (49, 5, 'Product 49 - Pro', 'SKU-0049', 308.15, 26);
INSERT INTO product_tags (product_id, tag_id) VALUES (49, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (50, 8, 'Product 50 - Lite', 'SKU-0050', 339.34, 9);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (51, 6, 'Product 51 - Pro', 'SKU-0051', 397.41, 23);
INSERT INTO product_tags (product_id, tag_id) VALUES (51, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (52, 2, 'Product 52 - Pro', 'SKU-0052', 178.36, 47);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (53, 8, 'Product 53 - Lite', 'SKU-0053', 46.59, 99);
INSERT INTO product_tags (product_id, tag_id) VALUES (53, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (54, 5, 'Product 54 - Standard', 'SKU-0054', 165.66, 51);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (55, 4, 'Product 55 - Lite', 'SKU-0055', 475.15, 95);
INSERT INTO product_tags (product_id, tag_id) VALUES (55, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (56, 2, 'Product 56 - Standard', 'SKU-0056', 173.17, 62);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (57, 8, 'Product 57 - Plus', 'SKU-0057', 205.83, 6);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (58, 1, 'Product 58 - Standard', 'SKU-0058', 268.64, 28);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (59, 8, 'Product 59 - Lite', 'SKU-0059', 336.32, 29);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (60, 8, 'Product 60 - Plus', 'SKU-0060', 239.78, 53);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (61, 1, 'Product 61 - Lite', 'SKU-0061', 111.52, 6);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (62, 6, 'Product 62 - Standard', 'SKU-0062', 17.75, 28);
INSERT INTO product_tags (product_id, tag_id) VALUES (62, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (63, 8, 'Product 63 - Pro', 'SKU-0063', 271.08, 25);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (64, 6, 'Product 64 - Pro', 'SKU-0064', 254.0, 47);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (65, 1, 'Product 65 - Standard', 'SKU-0065', 339.38, 60);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (66, 7, 'Product 66 - Pro', 'SKU-0066', 240.34, 10);
INSERT INTO product_tags (product_id, tag_id) VALUES (66, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (67, 8, 'Product 67 - Plus', 'SKU-0067', 216.22, 97);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (68, 7, 'Product 68 - Max', 'SKU-0068', 171.46, 55);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (69, 7, 'Product 69 - Max', 'SKU-0069', 235.77, 56);
INSERT INTO product_tags (product_id, tag_id) VALUES (69, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (70, 7, 'Product 70 - Max', 'SKU-0070', 64.56, 35);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (71, 1, 'Product 71 - Max', 'SKU-0071', 292.41, 60);
INSERT INTO product_tags (product_id, tag_id) VALUES (71, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (72, 8, 'Product 72 - Pro', 'SKU-0072', 457.2, 98);
INSERT INTO product_tags (product_id, tag_id) VALUES (72, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (73, 6, 'Product 73 - Standard', 'SKU-0073', 446.01, 68);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (74, 5, 'Product 74 - Max', 'SKU-0074', 469.97, 36);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (75, 7, 'Product 75 - Lite', 'SKU-0075', 188.98, 24);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (76, 7, 'Product 76 - Pro', 'SKU-0076', 332.72, 11);
INSERT INTO product_tags (product_id, tag_id) VALUES (76, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (77, 4, 'Product 77 - Standard', 'SKU-0077', 385.51, 43);
INSERT INTO product_tags (product_id, tag_id) VALUES (77, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (78, 8, 'Product 78 - Max', 'SKU-0078', 409.73, 29);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (79, 3, 'Product 79 - Lite', 'SKU-0079', 324.33, 87);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (80, 4, 'Product 80 - Standard', 'SKU-0080', 121.05, 81);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (81, 2, 'Product 81 - Pro', 'SKU-0081', 76.42, 94);
INSERT INTO product_tags (product_id, tag_id) VALUES (81, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (82, 4, 'Product 82 - Max', 'SKU-0082', 389.16, 9);
INSERT INTO product_tags (product_id, tag_id) VALUES (82, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (83, 4, 'Product 83 - Plus', 'SKU-0083', 358.56, 43);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (84, 8, 'Product 84 - Pro', 'SKU-0084', 476.02, 15);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (85, 7, 'Product 85 - Lite', 'SKU-0085', 72.75, 93);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (86, 2, 'Product 86 - Plus', 'SKU-0086', 439.91, 1);
INSERT INTO product_tags (product_id, tag_id) VALUES (86, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (87, 6, 'Product 87 - Standard', 'SKU-0087', 464.16, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (88, 4, 'Product 88 - Max', 'SKU-0088', 429.96, 15);
INSERT INTO product_tags (product_id, tag_id) VALUES (88, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (89, 4, 'Product 89 - Max', 'SKU-0089', 271.06, 42);
INSERT INTO product_tags (product_id, tag_id) VALUES (89, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (90, 6, 'Product 90 - Lite', 'SKU-0090', 468.15, 61);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (91, 6, 'Product 91 - Pro', 'SKU-0091', 337.2, 21);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (92, 5, 'Product 92 - Standard', 'SKU-0092', 459.49, 74);
INSERT INTO product_tags (product_id, tag_id) VALUES (92, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (93, 1, 'Product 93 - Standard', 'SKU-0093', 154.52, 91);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (94, 2, 'Product 94 - Pro', 'SKU-0094', 465.11, 71);
INSERT INTO product_tags (product_id, tag_id) VALUES (94, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (95, 4, 'Product 95 - Plus', 'SKU-0095', 274.43, 63);
INSERT INTO product_tags (product_id, tag_id) VALUES (95, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (96, 3, 'Product 96 - Lite', 'SKU-0096', 144.02, 31);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (97, 4, 'Product 97 - Pro', 'SKU-0097', 465.84, 93);
INSERT INTO product_tags (product_id, tag_id) VALUES (97, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (98, 1, 'Product 98 - Max', 'SKU-0098', 263.19, 10);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (99, 2, 'Product 99 - Max', 'SKU-0099', 148.03, 11);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (100, 1, 'Product 100 - Max', 'SKU-0100', 118.85, 54);
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (1, 46, 'ORD-2024001', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 42, 2, 61.76, 123.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 8, 2, 37.98, 75.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 31, 2, 46.48, 92.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 68, 2, 69.7, 139.4);
UPDATE orders SET total_amount = 431.84000000000003 WHERE id = 1;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (2, 20, 'ORD-2024002', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 74, 2, 65.1, 130.2);
UPDATE orders SET total_amount = 130.2 WHERE id = 2;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (3, 46, 'ORD-2024003', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 53, 1, 44.76, 44.76);
UPDATE orders SET total_amount = 44.76 WHERE id = 3;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (4, 10, 'ORD-2024004', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 39, 2, 42.25, 84.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 22, 2, 16.33, 32.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 2, 2, 34.56, 69.12);
UPDATE orders SET total_amount = 186.28 WHERE id = 4;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (5, 35, 'ORD-2024005', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 40, 1, 56.37, 56.37);
UPDATE orders SET total_amount = 56.37 WHERE id = 5;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (6, 22, 'ORD-2024006', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 53, 1, 31.27, 31.27);
UPDATE orders SET total_amount = 31.27 WHERE id = 6;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (7, 23, 'ORD-2024007', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 82, 1, 24.48, 24.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 88, 1, 54.63, 54.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 62, 1, 98.16, 98.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 38, 2, 67.46, 134.92);
UPDATE orders SET total_amount = 312.18999999999994 WHERE id = 7;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (8, 36, 'ORD-2024008', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 24, 3, 56.19, 168.57);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 70, 1, 92.93, 92.93);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 43, 1, 87.43, 87.43);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 48, 2, 16.88, 33.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 96, 3, 48.84, 146.52);
UPDATE orders SET total_amount = 529.21 WHERE id = 8;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (9, 31, 'ORD-2024009', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 59, 1, 87.61, 87.61);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 35, 3, 10.35, 31.049999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 22, 2, 71.64, 143.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 53, 3, 46.04, 138.12);
UPDATE orders SET total_amount = 400.06 WHERE id = 9;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (10, 42, 'ORD-2024010', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 79, 3, 70.5, 211.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 55, 2, 24.66, 49.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 52, 3, 10.24, 30.72);
UPDATE orders SET total_amount = 291.53999999999996 WHERE id = 10;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (11, 2, 'ORD-2024011', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 9, 3, 28.96, 86.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 9, 2, 52.58, 105.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 59, 1, 11.54, 11.54);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 63, 3, 79.01, 237.03000000000003);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 27, 1, 64.31, 64.31);
UPDATE orders SET total_amount = 504.92 WHERE id = 11;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (12, 14, 'ORD-2024012', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (12, 47, 2, 62.9, 125.8);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (12, 24, 2, 24.92, 49.84);
UPDATE orders SET total_amount = 175.64 WHERE id = 12;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (13, 42, 'ORD-2024013', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 37, 1, 66.38, 66.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 71, 3, 44.55, 133.64999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 80, 3, 30.14, 90.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 86, 2, 28.04, 56.08);
UPDATE orders SET total_amount = 346.53 WHERE id = 13;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (14, 40, 'ORD-2024014', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 1, 1, 15.17, 15.17);
UPDATE orders SET total_amount = 15.17 WHERE id = 14;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (15, 19, 'ORD-2024015', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 47, 1, 62.87, 62.87);
UPDATE orders SET total_amount = 62.87 WHERE id = 15;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (16, 4, 'ORD-2024016', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 51, 3, 20.22, 60.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 54, 3, 30.62, 91.86);
UPDATE orders SET total_amount = 152.51999999999998 WHERE id = 16;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (17, 38, 'ORD-2024017', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 63, 3, 21.57, 64.71000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 36, 3, 60.69, 182.07);
UPDATE orders SET total_amount = 246.78 WHERE id = 17;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (18, 33, 'ORD-2024018', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 68, 1, 16.68, 16.68);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 85, 2, 58.52, 117.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 84, 3, 98.63, 295.89);
UPDATE orders SET total_amount = 429.61 WHERE id = 18;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (19, 5, 'ORD-2024019', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 60, 2, 63.31, 126.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 55, 1, 87.22, 87.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 64, 3, 52.35, 157.05);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 57, 1, 98.82, 98.82);
UPDATE orders SET total_amount = 469.71 WHERE id = 19;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (20, 26, 'ORD-2024020', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 34, 2, 64.22, 128.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 50, 3, 34.0, 102.0);
UPDATE orders SET total_amount = 230.44 WHERE id = 20;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (21, 47, 'ORD-2024021', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 51, 1, 17.44, 17.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 48, 1, 59.7, 59.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 1, 3, 28.66, 85.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 50, 1, 52.84, 52.84);
UPDATE orders SET total_amount = 215.96 WHERE id = 21;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (22, 8, 'ORD-2024022', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 8, 3, 93.82, 281.46);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 68, 1, 72.7, 72.7);
UPDATE orders SET total_amount = 354.15999999999997 WHERE id = 22;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (23, 23, 'ORD-2024023', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (23, 18, 1, 84.09, 84.09);
UPDATE orders SET total_amount = 84.09 WHERE id = 23;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (24, 27, 'ORD-2024024', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 27, 3, 20.07, 60.21);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 47, 1, 23.33, 23.33);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 55, 2, 49.81, 99.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 81, 2, 53.79, 107.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 17, 1, 76.22, 76.22);
UPDATE orders SET total_amount = 366.96000000000004 WHERE id = 24;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (25, 39, 'ORD-2024025', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 76, 2, 82.22, 164.44);
UPDATE orders SET total_amount = 164.44 WHERE id = 25;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (26, 14, 'ORD-2024026', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 34, 2, 67.25, 134.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 89, 3, 37.21, 111.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 21, 3, 49.93, 149.79);
UPDATE orders SET total_amount = 395.91999999999996 WHERE id = 26;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (27, 22, 'ORD-2024027', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 60, 2, 45.16, 90.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 72, 2, 17.19, 34.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 43, 1, 51.31, 51.31);
UPDATE orders SET total_amount = 176.01 WHERE id = 27;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (28, 41, 'ORD-2024028', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 11, 2, 86.81, 173.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 46, 3, 61.36, 184.07999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 39, 1, 65.38, 65.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 69, 1, 52.51, 52.51);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 89, 3, 30.84, 92.52);
UPDATE orders SET total_amount = 568.11 WHERE id = 28;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (29, 4, 'ORD-2024029', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 85, 1, 78.55, 78.55);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 33, 3, 22.25, 66.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 53, 2, 90.15, 180.3);
UPDATE orders SET total_amount = 325.6 WHERE id = 29;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (30, 24, 'ORD-2024030', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 11, 3, 80.14, 240.42000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 98, 2, 60.51, 121.02);
UPDATE orders SET total_amount = 361.44 WHERE id = 30;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (31, 17, 'ORD-2024031', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 58, 2, 38.45, 76.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 81, 3, 29.15, 87.44999999999999);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 64, 3, 30.8, 92.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 56, 3, 10.64, 31.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 90, 1, 74.38, 74.38);
UPDATE orders SET total_amount = 363.05 WHERE id = 31;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (32, 43, 'ORD-2024032', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 69, 1, 95.61, 95.61);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 12, 2, 81.32, 162.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 9, 1, 55.28, 55.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 54, 3, 31.01, 93.03);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 62, 3, 33.18, 99.53999999999999);
UPDATE orders SET total_amount = 506.0999999999999 WHERE id = 32;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (33, 31, 'ORD-2024033', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 91, 2, 92.82, 185.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 21, 1, 18.72, 18.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 17, 3, 14.58, 43.74);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 84, 3, 70.59, 211.77);
UPDATE orders SET total_amount = 459.87 WHERE id = 33;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (34, 5, 'ORD-2024034', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 2, 3, 96.95, 290.85);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 63, 2, 90.12, 180.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 8, 2, 54.69, 109.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 31, 3, 26.78, 80.34);
UPDATE orders SET total_amount = 660.8100000000001 WHERE id = 34;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (35, 11, 'ORD-2024035', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 71, 1, 88.6, 88.6);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 4, 3, 71.15, 213.45000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 84, 1, 95.91, 95.91);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 82, 2, 14.2, 28.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 57, 3, 70.03, 210.09);
UPDATE orders SET total_amount = 636.45 WHERE id = 35;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (36, 27, 'ORD-2024036', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 46, 1, 98.63, 98.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 79, 3, 73.45, 220.35000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 86, 2, 39.6, 79.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 31, 1, 60.46, 60.46);
UPDATE orders SET total_amount = 458.64 WHERE id = 36;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (37, 44, 'ORD-2024037', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 60, 1, 79.31, 79.31);
UPDATE orders SET total_amount = 79.31 WHERE id = 37;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (38, 22, 'ORD-2024038', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (38, 7, 1, 88.43, 88.43);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (38, 30, 3, 24.43, 73.28999999999999);
UPDATE orders SET total_amount = 161.72 WHERE id = 38;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (39, 36, 'ORD-2024039', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (39, 86, 1, 45.41, 45.41);
UPDATE orders SET total_amount = 45.41 WHERE id = 39;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (40, 16, 'ORD-2024040', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 26, 3, 57.4, 172.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 49, 1, 36.35, 36.35);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 31, 2, 69.89, 139.78);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 49, 3, 85.82, 257.46);
UPDATE orders SET total_amount = 605.79 WHERE id = 40;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (41, 3, 'ORD-2024041', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 63, 2, 14.17, 28.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 34, 3, 93.42, 280.26);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (41, 38, 2, 49.33, 98.66);
UPDATE orders SET total_amount = 407.26 WHERE id = 41;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (42, 8, 'ORD-2024042', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (42, 36, 1, 61.24, 61.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (42, 54, 1, 98.75, 98.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (42, 16, 3, 91.72, 275.15999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (42, 98, 2, 78.36, 156.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (42, 93, 3, 30.8, 92.4);
UPDATE orders SET total_amount = 684.27 WHERE id = 42;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (43, 14, 'ORD-2024043', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (43, 34, 1, 37.8, 37.8);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (43, 79, 1, 93.03, 93.03);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (43, 100, 2, 27.11, 54.22);
UPDATE orders SET total_amount = 185.04999999999998 WHERE id = 43;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (44, 4, 'ORD-2024044', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 48, 2, 43.67, 87.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 17, 1, 82.0, 82.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 92, 1, 20.01, 20.01);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 72, 3, 17.47, 52.41);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (44, 30, 1, 41.44, 41.44);
UPDATE orders SET total_amount = 283.2 WHERE id = 44;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (45, 20, 'ORD-2024045', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (45, 99, 1, 99.87, 99.87);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (45, 71, 1, 70.43, 70.43);
UPDATE orders SET total_amount = 170.3 WHERE id = 45;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (46, 12, 'ORD-2024046', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 40, 1, 97.13, 97.13);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 14, 3, 11.56, 34.68);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 66, 3, 38.94, 116.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (46, 87, 2, 86.29, 172.58);
UPDATE orders SET total_amount = 421.21000000000004 WHERE id = 46;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (47, 19, 'ORD-2024047', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (47, 3, 3, 92.56, 277.68);
UPDATE orders SET total_amount = 277.68 WHERE id = 47;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (48, 50, 'ORD-2024048', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 39, 2, 86.18, 172.36);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 44, 3, 65.3, 195.89999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 100, 2, 64.38, 128.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (48, 10, 1, 53.41, 53.41);
UPDATE orders SET total_amount = 550.43 WHERE id = 48;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (49, 2, 'ORD-2024049', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 40, 2, 90.45, 180.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (49, 68, 3, 55.03, 165.09);
UPDATE orders SET total_amount = 345.99 WHERE id = 49;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (50, 38, 'ORD-2024050', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 88, 3, 49.93, 149.79);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 74, 3, 81.86, 245.57999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 94, 2, 43.83, 87.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 4, 3, 79.76, 239.28000000000003);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (50, 42, 1, 21.56, 21.56);
UPDATE orders SET total_amount = 743.8699999999999 WHERE id = 50;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (51, 41, 'ORD-2024051', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (51, 90, 1, 42.68, 42.68);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (51, 60, 2, 60.77, 121.54);
UPDATE orders SET total_amount = 164.22 WHERE id = 51;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (52, 6, 'ORD-2024052', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 9, 2, 33.54, 67.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 89, 3, 68.9, 206.70000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 71, 1, 58.5, 58.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 64, 3, 45.66, 136.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (52, 22, 2, 71.67, 143.34);
UPDATE orders SET total_amount = 612.6 WHERE id = 52;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (53, 38, 'ORD-2024053', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 12, 3, 21.88, 65.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 95, 2, 43.21, 86.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 58, 2, 12.26, 24.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (53, 94, 1, 16.13, 16.13);
UPDATE orders SET total_amount = 192.71 WHERE id = 53;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (54, 15, 'ORD-2024054', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (54, 1, 2, 20.58, 41.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (54, 99, 3, 21.55, 64.65);
UPDATE orders SET total_amount = 105.81 WHERE id = 54;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (55, 47, 'ORD-2024055', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (55, 45, 3, 49.37, 148.10999999999999);
UPDATE orders SET total_amount = 148.10999999999999 WHERE id = 55;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (56, 16, 'ORD-2024056', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 18, 1, 15.76, 15.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 12, 1, 64.85, 64.85);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (56, 67, 2, 18.35, 36.7);
UPDATE orders SET total_amount = 117.31 WHERE id = 56;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (57, 44, 'ORD-2024057', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (57, 30, 2, 69.02, 138.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (57, 56, 2, 15.13, 30.26);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (57, 20, 3, 61.09, 183.27);
UPDATE orders SET total_amount = 351.57 WHERE id = 57;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (58, 8, 'ORD-2024058', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 6, 1, 12.99, 12.99);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 89, 3, 61.44, 184.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 62, 3, 26.88, 80.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 5, 2, 99.45, 198.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (58, 32, 2, 59.63, 119.26);
UPDATE orders SET total_amount = 596.11 WHERE id = 58;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (59, 21, 'ORD-2024059', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 24, 3, 25.95, 77.85);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 82, 1, 18.58, 18.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 25, 3, 96.28, 288.84000000000003);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (59, 81, 1, 46.91, 46.91);
UPDATE orders SET total_amount = 432.18000000000006 WHERE id = 59;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (60, 36, 'ORD-2024060', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 22, 1, 10.72, 10.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 66, 1, 60.04, 60.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (60, 60, 1, 44.83, 44.83);
UPDATE orders SET total_amount = 115.59 WHERE id = 60;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (61, 33, 'ORD-2024061', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 61, 3, 64.7, 194.10000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 34, 2, 55.97, 111.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (61, 71, 2, 68.49, 136.98);
UPDATE orders SET total_amount = 443.02 WHERE id = 61;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (62, 33, 'ORD-2024062', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 72, 1, 58.08, 58.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 88, 2, 58.69, 117.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (62, 25, 3, 63.0, 189.0);
UPDATE orders SET total_amount = 364.46 WHERE id = 62;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (63, 1, 'ORD-2024063', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 5, 3, 30.21, 90.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 33, 3, 68.16, 204.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 35, 1, 22.04, 22.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 56, 2, 74.94, 149.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (63, 58, 3, 89.04, 267.12);
UPDATE orders SET total_amount = 734.1500000000001 WHERE id = 63;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (64, 39, 'ORD-2024064', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (64, 34, 2, 66.79, 133.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (64, 14, 1, 58.24, 58.24);
UPDATE orders SET total_amount = 191.82000000000002 WHERE id = 64;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (65, 20, 'ORD-2024065', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (65, 44, 2, 23.36, 46.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (65, 83, 3, 61.88, 185.64000000000001);
UPDATE orders SET total_amount = 232.36 WHERE id = 65;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (66, 2, 'ORD-2024066', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (66, 41, 3, 82.88, 248.64);
UPDATE orders SET total_amount = 248.64 WHERE id = 66;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (67, 41, 'ORD-2024067', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (67, 99, 3, 31.61, 94.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (67, 27, 1, 95.88, 95.88);
UPDATE orders SET total_amount = 190.70999999999998 WHERE id = 67;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (68, 35, 'ORD-2024068', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 59, 2, 68.08, 136.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 93, 3, 83.1, 249.29999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (68, 30, 1, 87.81, 87.81);
UPDATE orders SET total_amount = 473.27 WHERE id = 68;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (69, 9, 'ORD-2024069', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (69, 41, 2, 92.26, 184.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (69, 50, 3, 97.72, 293.15999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (69, 8, 1, 28.35, 28.35);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (69, 85, 2, 31.52, 63.04);
UPDATE orders SET total_amount = 569.0699999999999 WHERE id = 69;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (70, 16, 'ORD-2024070', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 24, 2, 44.57, 89.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 86, 1, 79.65, 79.65);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 43, 1, 62.79, 62.79);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 57, 2, 97.45, 194.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (70, 24, 1, 34.08, 34.08);
UPDATE orders SET total_amount = 460.56 WHERE id = 70;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (71, 8, 'ORD-2024071', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 83, 3, 53.96, 161.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 66, 1, 99.16, 99.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 76, 1, 65.95, 65.95);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (71, 64, 1, 64.14, 64.14);
UPDATE orders SET total_amount = 391.12999999999994 WHERE id = 71;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (72, 23, 'ORD-2024072', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 58, 3, 20.78, 62.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (72, 78, 1, 42.33, 42.33);
UPDATE orders SET total_amount = 104.67 WHERE id = 72;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (73, 18, 'ORD-2024073', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (73, 46, 1, 78.33, 78.33);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (73, 56, 1, 79.01, 79.01);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (73, 90, 1, 14.76, 14.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (73, 33, 2, 69.17, 138.34);
UPDATE orders SET total_amount = 310.44 WHERE id = 73;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (74, 4, 'ORD-2024074', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 84, 3, 31.74, 95.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 20, 3, 56.86, 170.57999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 87, 3, 79.52, 238.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 39, 2, 60.58, 121.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (74, 46, 2, 51.75, 103.5);
UPDATE orders SET total_amount = 729.02 WHERE id = 74;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (75, 44, 'ORD-2024075', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 94, 1, 87.67, 87.67);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 88, 2, 32.12, 64.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 77, 2, 54.77, 109.54);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (75, 24, 2, 93.44, 186.88);
UPDATE orders SET total_amount = 448.33 WHERE id = 75;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (76, 43, 'ORD-2024076', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (76, 47, 1, 25.2, 25.2);
UPDATE orders SET total_amount = 25.2 WHERE id = 76;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (77, 37, 'ORD-2024077', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 91, 3, 70.43, 211.29000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 16, 1, 16.28, 16.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 83, 1, 13.0, 13.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (77, 83, 1, 50.08, 50.08);
UPDATE orders SET total_amount = 290.65000000000003 WHERE id = 77;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (78, 32, 'ORD-2024078', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (78, 17, 1, 72.12, 72.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (78, 20, 2, 60.54, 121.08);
UPDATE orders SET total_amount = 193.2 WHERE id = 78;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (79, 39, 'ORD-2024079', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (79, 62, 3, 41.32, 123.96000000000001);
UPDATE orders SET total_amount = 123.96000000000001 WHERE id = 79;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (80, 31, 'ORD-2024080', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (80, 49, 3, 33.49, 100.47);
UPDATE orders SET total_amount = 100.47 WHERE id = 80;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (81, 43, 'ORD-2024081', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 45, 3, 64.15, 192.45000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 54, 2, 73.31, 146.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (81, 90, 2, 42.72, 85.44);
UPDATE orders SET total_amount = 424.51000000000005 WHERE id = 81;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (82, 43, 'ORD-2024082', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 20, 1, 75.39, 75.39);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 14, 2, 37.52, 75.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (82, 32, 1, 78.64, 78.64);
UPDATE orders SET total_amount = 229.07 WHERE id = 82;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (83, 11, 'ORD-2024083', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 69, 3, 29.66, 88.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 68, 3, 29.33, 87.99);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 62, 3, 85.92, 257.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 50, 2, 29.6, 59.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (83, 3, 1, 46.62, 46.62);
UPDATE orders SET total_amount = 540.55 WHERE id = 83;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (84, 42, 'ORD-2024084', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 9, 1, 73.51, 73.51);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 76, 2, 22.1, 44.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 80, 3, 97.49, 292.46999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (84, 79, 1, 64.57, 64.57);
UPDATE orders SET total_amount = 474.74999999999994 WHERE id = 84;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (85, 8, 'ORD-2024085', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (85, 97, 2, 88.38, 176.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (85, 79, 3, 25.53, 76.59);
UPDATE orders SET total_amount = 253.35 WHERE id = 85;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (86, 20, 'ORD-2024086', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (86, 25, 2, 50.78, 101.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (86, 97, 2, 65.92, 131.84);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (86, 82, 3, 24.29, 72.87);
UPDATE orders SET total_amount = 306.27 WHERE id = 86;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (87, 36, 'ORD-2024087', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 72, 1, 56.97, 56.97);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 94, 2, 65.75, 131.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 74, 3, 74.88, 224.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (87, 41, 1, 89.82, 89.82);
UPDATE orders SET total_amount = 502.93 WHERE id = 87;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (88, 18, 'ORD-2024088', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (88, 84, 2, 50.07, 100.14);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (88, 47, 3, 49.01, 147.03);
UPDATE orders SET total_amount = 247.17000000000002 WHERE id = 88;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (89, 9, 'ORD-2024089', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (89, 57, 1, 76.32, 76.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (89, 59, 1, 47.65, 47.65);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (89, 53, 3, 95.33, 285.99);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (89, 15, 2, 29.6, 59.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (89, 93, 1, 55.66, 55.66);
UPDATE orders SET total_amount = 524.82 WHERE id = 89;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (90, 23, 'ORD-2024090', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 67, 3, 79.91, 239.73);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 19, 3, 90.04, 270.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 65, 1, 83.62, 83.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 6, 3, 45.93, 137.79);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (90, 21, 1, 40.52, 40.52);
UPDATE orders SET total_amount = 771.78 WHERE id = 90;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (91, 22, 'ORD-2024091', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 2, 3, 59.64, 178.92000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 10, 3, 54.05, 162.14999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 65, 1, 26.89, 26.89);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 24, 1, 85.42, 85.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (91, 74, 3, 92.7, 278.1);
UPDATE orders SET total_amount = 731.48 WHERE id = 91;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (92, 24, 'ORD-2024092', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 53, 1, 45.1, 45.1);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 23, 3, 55.94, 167.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (92, 44, 3, 35.09, 105.27000000000001);
UPDATE orders SET total_amount = 318.19 WHERE id = 92;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (93, 21, 'ORD-2024093', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (93, 56, 2, 70.14, 140.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (93, 64, 3, 51.2, 153.60000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (93, 61, 3, 33.31, 99.93);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (93, 68, 3, 40.56, 121.68);
UPDATE orders SET total_amount = 515.49 WHERE id = 93;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (94, 16, 'ORD-2024094', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (94, 82, 1, 66.73, 66.73);
UPDATE orders SET total_amount = 66.73 WHERE id = 94;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (95, 16, 'ORD-2024095', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 37, 3, 33.98, 101.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 18, 1, 56.91, 56.91);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 16, 2, 79.26, 158.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (95, 86, 2, 37.8, 75.6);
UPDATE orders SET total_amount = 392.97 WHERE id = 95;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (96, 19, 'ORD-2024096', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (96, 39, 2, 55.29, 110.58);
UPDATE orders SET total_amount = 110.58 WHERE id = 96;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (97, 18, 'ORD-2024097', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 42, 1, 43.94, 43.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 67, 3, 26.07, 78.21000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 70, 2, 48.75, 97.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (97, 46, 2, 40.59, 81.18);
UPDATE orders SET total_amount = 300.83000000000004 WHERE id = 97;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (98, 20, 'ORD-2024098', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (98, 77, 3, 81.49, 244.46999999999997);
UPDATE orders SET total_amount = 244.46999999999997 WHERE id = 98;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (99, 21, 'ORD-2024099', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (99, 38, 3, 65.59, 196.77);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (99, 54, 3, 27.54, 82.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (99, 10, 1, 54.53, 54.53);
UPDATE orders SET total_amount = 333.91999999999996 WHERE id = 99;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (100, 13, 'ORD-2024100', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (100, 4, 2, 48.91, 97.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (100, 68, 2, 24.12, 48.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (100, 94, 3, 49.48, 148.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (100, 81, 1, 57.88, 57.88);
UPDATE orders SET total_amount = 352.38 WHERE id = 100;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (101, 48, 'ORD-2024101', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (101, 21, 1, 65.18, 65.18);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (101, 68, 1, 38.77, 38.77);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (101, 94, 3, 68.31, 204.93);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (101, 62, 3, 88.85, 266.54999999999995);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (101, 85, 1, 42.66, 42.66);
UPDATE orders SET total_amount = 618.0899999999999 WHERE id = 101;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (102, 36, 'ORD-2024102', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (102, 16, 1, 58.98, 58.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (102, 60, 2, 57.23, 114.46);
UPDATE orders SET total_amount = 173.44 WHERE id = 102;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (103, 31, 'ORD-2024103', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (103, 20, 3, 88.47, 265.40999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (103, 29, 3, 82.62, 247.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (103, 98, 2, 32.01, 64.02);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (103, 58, 1, 82.15, 82.15);
UPDATE orders SET total_amount = 659.4399999999999 WHERE id = 103;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (104, 3, 'ORD-2024104', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (104, 56, 3, 52.43, 157.29);
UPDATE orders SET total_amount = 157.29 WHERE id = 104;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (105, 50, 'ORD-2024105', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (105, 30, 3, 95.84, 287.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (105, 51, 1, 86.4, 86.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (105, 83, 3, 41.31, 123.93);
UPDATE orders SET total_amount = 497.84999999999997 WHERE id = 105;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (106, 17, 'ORD-2024106', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (106, 20, 3, 82.23, 246.69);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (106, 93, 1, 29.11, 29.11);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (106, 21, 1, 33.22, 33.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (106, 63, 1, 49.06, 49.06);
UPDATE orders SET total_amount = 358.08 WHERE id = 106;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (107, 2, 'ORD-2024107', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (107, 27, 2, 45.48, 90.96);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (107, 15, 3, 76.1, 228.29999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (107, 29, 2, 65.04, 130.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (107, 30, 2, 90.87, 181.74);
UPDATE orders SET total_amount = 631.08 WHERE id = 107;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (108, 25, 'ORD-2024108', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (108, 54, 2, 79.31, 158.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (108, 56, 2, 10.22, 20.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (108, 100, 1, 94.2, 94.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (108, 21, 3, 32.39, 97.17);
UPDATE orders SET total_amount = 370.43 WHERE id = 108;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (109, 36, 'ORD-2024109', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (109, 73, 3, 78.83, 236.49);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (109, 54, 3, 86.5, 259.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (109, 52, 2, 43.64, 87.28);
UPDATE orders SET total_amount = 583.27 WHERE id = 109;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (110, 12, 'ORD-2024110', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (110, 84, 1, 55.52, 55.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (110, 69, 1, 39.39, 39.39);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (110, 33, 3, 36.12, 108.35999999999999);
UPDATE orders SET total_amount = 203.26999999999998 WHERE id = 110;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (111, 50, 'ORD-2024111', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (111, 82, 1, 78.83, 78.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (111, 3, 3, 38.48, 115.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (111, 67, 3, 47.9, 143.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (111, 58, 1, 12.81, 12.81);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (111, 89, 3, 68.67, 206.01);
UPDATE orders SET total_amount = 556.79 WHERE id = 111;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (112, 50, 'ORD-2024112', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (112, 28, 1, 67.0, 67.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (112, 43, 2, 16.74, 33.48);
UPDATE orders SET total_amount = 100.47999999999999 WHERE id = 112;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (113, 22, 'ORD-2024113', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (113, 70, 1, 45.84, 45.84);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (113, 78, 2, 19.45, 38.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (113, 96, 1, 99.65, 99.65);
UPDATE orders SET total_amount = 184.39000000000001 WHERE id = 113;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (114, 8, 'ORD-2024114', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (114, 51, 2, 69.37, 138.74);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (114, 86, 3, 58.52, 175.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (114, 76, 1, 79.66, 79.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (114, 83, 3, 68.9, 206.70000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (114, 85, 1, 96.99, 96.99);
UPDATE orders SET total_amount = 697.6500000000001 WHERE id = 114;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (115, 31, 'ORD-2024115', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (115, 12, 3, 27.88, 83.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (115, 27, 2, 14.43, 28.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (115, 96, 3, 22.75, 68.25);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (115, 41, 2, 95.14, 190.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (115, 20, 1, 67.01, 67.01);
UPDATE orders SET total_amount = 438.03999999999996 WHERE id = 115;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (116, 20, 'ORD-2024116', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (116, 96, 2, 32.37, 64.74);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (116, 83, 3, 64.48, 193.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (116, 25, 2, 33.79, 67.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (116, 50, 3, 87.11, 261.33);
UPDATE orders SET total_amount = 587.0899999999999 WHERE id = 116;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (117, 1, 'ORD-2024117', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (117, 61, 3, 67.45, 202.35000000000002);
UPDATE orders SET total_amount = 202.35000000000002 WHERE id = 117;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (118, 6, 'ORD-2024118', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (118, 52, 3, 65.32, 195.95999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (118, 80, 2, 96.09, 192.18);
UPDATE orders SET total_amount = 388.14 WHERE id = 118;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (119, 21, 'ORD-2024119', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (119, 82, 2, 87.14, 174.28);
UPDATE orders SET total_amount = 174.28 WHERE id = 119;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (120, 50, 'ORD-2024120', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (120, 60, 3, 42.25, 126.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (120, 66, 3, 25.84, 77.52);
UPDATE orders SET total_amount = 204.26999999999998 WHERE id = 120;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (121, 23, 'ORD-2024121', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (121, 12, 1, 89.42, 89.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (121, 96, 1, 41.01, 41.01);
UPDATE orders SET total_amount = 130.43 WHERE id = 121;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (122, 28, 'ORD-2024122', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (122, 89, 3, 70.19, 210.57);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (122, 30, 2, 86.01, 172.02);
UPDATE orders SET total_amount = 382.59000000000003 WHERE id = 122;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (123, 20, 'ORD-2024123', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (123, 7, 1, 79.67, 79.67);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (123, 49, 3, 55.04, 165.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (123, 93, 1, 11.56, 11.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (123, 40, 1, 46.91, 46.91);
UPDATE orders SET total_amount = 303.26 WHERE id = 123;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (124, 44, 'ORD-2024124', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (124, 34, 2, 76.82, 153.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (124, 34, 2, 97.42, 194.84);
UPDATE orders SET total_amount = 348.48 WHERE id = 124;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (125, 30, 'ORD-2024125', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (125, 74, 2, 84.06, 168.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (125, 53, 1, 57.95, 57.95);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (125, 68, 3, 83.93, 251.79000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (125, 31, 1, 94.74, 94.74);
UPDATE orders SET total_amount = 572.6 WHERE id = 125;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (126, 34, 'ORD-2024126', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (126, 69, 1, 34.63, 34.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (126, 99, 2, 32.49, 64.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (126, 18, 2, 69.25, 138.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (126, 63, 3, 55.87, 167.60999999999999);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (126, 93, 1, 51.42, 51.42);
UPDATE orders SET total_amount = 457.14000000000004 WHERE id = 126;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (127, 43, 'ORD-2024127', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (127, 95, 3, 21.13, 63.39);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (127, 61, 3, 18.17, 54.510000000000005);
UPDATE orders SET total_amount = 117.9 WHERE id = 127;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (128, 40, 'ORD-2024128', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (128, 42, 3, 13.59, 40.769999999999996);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (128, 92, 3, 12.45, 37.349999999999994);
UPDATE orders SET total_amount = 78.11999999999999 WHERE id = 128;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (129, 37, 'ORD-2024129', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (129, 99, 2, 26.56, 53.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (129, 34, 3, 85.07, 255.20999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (129, 41, 3, 53.84, 161.52);
UPDATE orders SET total_amount = 469.85 WHERE id = 129;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (130, 17, 'ORD-2024130', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (130, 64, 1, 13.33, 13.33);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (130, 89, 1, 42.48, 42.48);
UPDATE orders SET total_amount = 55.809999999999995 WHERE id = 130;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (131, 48, 'ORD-2024131', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (131, 13, 2, 71.11, 142.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (131, 39, 2, 22.17, 44.34);
UPDATE orders SET total_amount = 186.56 WHERE id = 131;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (132, 11, 'ORD-2024132', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (132, 7, 1, 66.67, 66.67);
UPDATE orders SET total_amount = 66.67 WHERE id = 132;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (133, 8, 'ORD-2024133', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (133, 82, 2, 16.92, 33.84);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (133, 75, 2, 61.49, 122.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (133, 97, 1, 48.43, 48.43);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (133, 35, 2, 61.26, 122.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (133, 30, 1, 35.16, 35.16);
UPDATE orders SET total_amount = 362.92999999999995 WHERE id = 133;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (134, 35, 'ORD-2024134', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (134, 77, 1, 90.2, 90.2);
UPDATE orders SET total_amount = 90.2 WHERE id = 134;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (135, 37, 'ORD-2024135', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (135, 33, 3, 17.09, 51.269999999999996);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (135, 86, 2, 22.28, 44.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (135, 66, 1, 10.07, 10.07);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (135, 35, 3, 52.72, 158.16);
UPDATE orders SET total_amount = 264.06 WHERE id = 135;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (136, 10, 'ORD-2024136', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (136, 40, 3, 13.16, 39.480000000000004);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (136, 17, 2, 59.03, 118.06);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (136, 48, 3, 10.71, 32.13);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (136, 52, 1, 26.43, 26.43);
UPDATE orders SET total_amount = 216.10000000000002 WHERE id = 136;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (137, 8, 'ORD-2024137', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (137, 54, 2, 37.45, 74.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (137, 91, 3, 33.0, 99.0);
UPDATE orders SET total_amount = 173.9 WHERE id = 137;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (138, 49, 'ORD-2024138', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (138, 63, 1, 88.52, 88.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (138, 82, 3, 31.16, 93.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (138, 75, 1, 68.73, 68.73);
UPDATE orders SET total_amount = 250.73000000000002 WHERE id = 138;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (139, 4, 'ORD-2024139', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (139, 26, 3, 80.37, 241.11);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (139, 56, 1, 52.2, 52.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (139, 79, 3, 65.35, 196.04999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (139, 30, 3, 88.51, 265.53000000000003);
UPDATE orders SET total_amount = 754.8900000000001 WHERE id = 139;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (140, 17, 'ORD-2024140', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (140, 23, 1, 75.48, 75.48);
UPDATE orders SET total_amount = 75.48 WHERE id = 140;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (141, 45, 'ORD-2024141', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (141, 48, 2, 20.04, 40.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (141, 64, 1, 81.04, 81.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (141, 100, 3, 76.35, 229.04999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (141, 51, 1, 86.16, 86.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (141, 35, 3, 73.25, 219.75);
UPDATE orders SET total_amount = 656.0799999999999 WHERE id = 141;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (142, 48, 'ORD-2024142', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (142, 52, 1, 91.03, 91.03);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (142, 11, 3, 54.8, 164.39999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (142, 81, 2, 11.96, 23.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (142, 30, 2, 59.76, 119.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (142, 68, 2, 39.68, 79.36);
UPDATE orders SET total_amount = 478.22999999999996 WHERE id = 142;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (143, 17, 'ORD-2024143', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (143, 25, 1, 73.57, 73.57);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (143, 80, 2, 81.81, 163.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (143, 19, 3, 18.19, 54.57000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (143, 62, 2, 88.32, 176.64);
UPDATE orders SET total_amount = 468.4 WHERE id = 143;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (144, 5, 'ORD-2024144', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (144, 16, 1, 12.33, 12.33);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (144, 22, 3, 95.28, 285.84000000000003);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (144, 68, 1, 34.62, 34.62);
UPDATE orders SET total_amount = 332.79 WHERE id = 144;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (145, 47, 'ORD-2024145', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (145, 78, 1, 10.74, 10.74);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (145, 98, 1, 97.84, 97.84);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (145, 34, 2, 97.85, 195.7);
UPDATE orders SET total_amount = 304.28 WHERE id = 145;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (146, 2, 'ORD-2024146', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (146, 68, 3, 69.92, 209.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (146, 55, 3, 85.66, 256.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (146, 49, 3, 96.35, 289.04999999999995);
UPDATE orders SET total_amount = 755.79 WHERE id = 146;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (147, 31, 'ORD-2024147', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (147, 10, 2, 64.52, 129.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (147, 40, 3, 97.72, 293.15999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (147, 78, 3, 52.21, 156.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (147, 27, 1, 11.61, 11.61);
UPDATE orders SET total_amount = 590.4399999999999 WHERE id = 147;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (148, 30, 'ORD-2024148', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (148, 11, 2, 53.49, 106.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (148, 64, 2, 69.43, 138.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (148, 70, 1, 86.76, 86.76);
UPDATE orders SET total_amount = 332.6 WHERE id = 148;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (149, 18, 'ORD-2024149', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (149, 23, 1, 80.59, 80.59);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (149, 59, 1, 36.91, 36.91);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (149, 27, 2, 93.84, 187.68);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (149, 38, 2, 19.75, 39.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (149, 73, 3, 92.46, 277.38);
UPDATE orders SET total_amount = 622.06 WHERE id = 149;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (150, 44, 'ORD-2024150', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (150, 5, 1, 47.45, 47.45);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (150, 34, 2, 58.85, 117.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (150, 98, 2, 23.78, 47.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (150, 69, 1, 84.77, 84.77);
UPDATE orders SET total_amount = 297.48 WHERE id = 150;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (151, 31, 'ORD-2024151', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (151, 8, 1, 73.26, 73.26);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (151, 80, 3, 26.91, 80.73);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (151, 7, 2, 97.88, 195.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (151, 19, 3, 80.01, 240.03000000000003);
UPDATE orders SET total_amount = 589.78 WHERE id = 151;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (152, 29, 'ORD-2024152', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (152, 76, 2, 59.67, 119.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (152, 42, 2, 75.11, 150.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (152, 14, 3, 53.13, 159.39000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (152, 94, 1, 81.52, 81.52);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (152, 83, 1, 88.96, 88.96);
UPDATE orders SET total_amount = 599.4300000000001 WHERE id = 152;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (153, 40, 'ORD-2024153', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (153, 9, 1, 18.73, 18.73);
UPDATE orders SET total_amount = 18.73 WHERE id = 153;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (154, 29, 'ORD-2024154', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (154, 32, 3, 46.29, 138.87);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (154, 75, 3, 85.15, 255.45000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (154, 9, 2, 21.15, 42.3);
UPDATE orders SET total_amount = 436.62000000000006 WHERE id = 154;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (155, 14, 'ORD-2024155', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (155, 41, 3, 96.54, 289.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (155, 89, 1, 76.57, 76.57);
UPDATE orders SET total_amount = 366.19 WHERE id = 155;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (156, 44, 'ORD-2024156', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (156, 9, 3, 95.13, 285.39);
UPDATE orders SET total_amount = 285.39 WHERE id = 156;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (157, 21, 'ORD-2024157', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (157, 41, 3, 53.75, 161.25);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (157, 18, 3, 25.76, 77.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (157, 18, 2, 99.07, 198.14);
UPDATE orders SET total_amount = 436.66999999999996 WHERE id = 157;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (158, 24, 'ORD-2024158', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (158, 93, 2, 40.11, 80.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (158, 83, 1, 34.26, 34.26);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (158, 64, 3, 78.66, 235.98);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (158, 27, 3, 32.87, 98.60999999999999);
UPDATE orders SET total_amount = 449.06999999999994 WHERE id = 158;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (159, 6, 'ORD-2024159', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (159, 13, 2, 78.66, 157.32);
UPDATE orders SET total_amount = 157.32 WHERE id = 159;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (160, 21, 'ORD-2024160', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (160, 40, 3, 41.72, 125.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (160, 96, 1, 39.03, 39.03);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (160, 5, 2, 32.62, 65.24);
UPDATE orders SET total_amount = 229.43 WHERE id = 160;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (161, 38, 'ORD-2024161', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (161, 86, 1, 45.47, 45.47);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (161, 10, 1, 63.31, 63.31);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (161, 71, 3, 60.83, 182.49);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (161, 24, 3, 31.85, 95.55000000000001);
UPDATE orders SET total_amount = 386.82 WHERE id = 161;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (162, 2, 'ORD-2024162', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (162, 19, 1, 11.45, 11.45);
UPDATE orders SET total_amount = 11.45 WHERE id = 162;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (163, 32, 'ORD-2024163', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (163, 28, 1, 61.83, 61.83);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (163, 22, 1, 87.12, 87.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (163, 7, 1, 56.03, 56.03);
UPDATE orders SET total_amount = 204.98 WHERE id = 163;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (164, 14, 'ORD-2024164', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (164, 59, 2, 20.62, 41.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (164, 46, 2, 75.41, 150.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (164, 82, 1, 80.7, 80.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (164, 10, 2, 94.79, 189.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (164, 7, 3, 42.67, 128.01);
UPDATE orders SET total_amount = 590.35 WHERE id = 164;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (165, 32, 'ORD-2024165', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (165, 69, 2, 95.79, 191.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (165, 72, 1, 54.87, 54.87);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (165, 5, 3, 18.51, 55.53);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (165, 15, 2, 96.78, 193.56);
UPDATE orders SET total_amount = 495.54 WHERE id = 165;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (166, 22, 'ORD-2024166', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (166, 93, 3, 51.48, 154.44);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (166, 76, 1, 76.69, 76.69);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (166, 36, 3, 33.03, 99.09);
UPDATE orders SET total_amount = 330.22 WHERE id = 166;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (167, 38, 'ORD-2024167', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (167, 15, 1, 82.48, 82.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (167, 96, 3, 73.96, 221.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (167, 1, 3, 50.51, 151.53);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (167, 65, 2, 57.98, 115.96);
UPDATE orders SET total_amount = 571.85 WHERE id = 167;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (168, 11, 'ORD-2024168', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (168, 26, 3, 41.08, 123.24);
UPDATE orders SET total_amount = 123.24 WHERE id = 168;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (169, 40, 'ORD-2024169', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (169, 4, 2, 98.96, 197.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (169, 84, 3, 44.53, 133.59);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (169, 13, 2, 47.25, 94.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (169, 36, 2, 27.16, 54.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (169, 99, 2, 90.64, 181.28);
UPDATE orders SET total_amount = 661.61 WHERE id = 169;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (170, 3, 'ORD-2024170', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (170, 7, 1, 77.65, 77.65);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (170, 78, 3, 66.15, 198.45000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (170, 25, 1, 68.32, 68.32);
UPDATE orders SET total_amount = 344.42 WHERE id = 170;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (171, 41, 'ORD-2024171', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (171, 27, 3, 72.82, 218.45999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (171, 19, 3, 41.25, 123.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (171, 52, 3, 56.25, 168.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (171, 8, 2, 82.61, 165.22);
UPDATE orders SET total_amount = 676.18 WHERE id = 171;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (172, 16, 'ORD-2024172', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (172, 83, 3, 26.87, 80.61);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (172, 86, 2, 61.51, 123.02);
UPDATE orders SET total_amount = 203.63 WHERE id = 172;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (173, 44, 'ORD-2024173', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (173, 62, 3, 69.46, 208.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (173, 39, 3, 94.23, 282.69);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (173, 88, 2, 91.19, 182.38);
UPDATE orders SET total_amount = 673.45 WHERE id = 173;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (174, 33, 'ORD-2024174', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (174, 68, 2, 73.44, 146.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (174, 37, 3, 14.75, 44.25);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (174, 5, 2, 54.65, 109.3);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (174, 84, 2, 16.85, 33.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (174, 95, 3, 93.53, 280.59000000000003);
UPDATE orders SET total_amount = 614.72 WHERE id = 174;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (175, 29, 'ORD-2024175', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (175, 32, 1, 97.1, 97.1);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (175, 40, 3, 97.68, 293.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (175, 50, 3, 17.16, 51.480000000000004);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (175, 32, 1, 92.65, 92.65);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (175, 98, 2, 59.17, 118.34);
UPDATE orders SET total_amount = 652.61 WHERE id = 175;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (176, 25, 'ORD-2024176', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (176, 10, 1, 14.37, 14.37);
UPDATE orders SET total_amount = 14.37 WHERE id = 176;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (177, 11, 'ORD-2024177', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (177, 60, 2, 23.79, 47.58);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (177, 59, 1, 99.16, 99.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (177, 38, 2, 37.43, 74.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (177, 92, 3, 51.35, 154.05);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (177, 79, 3, 93.24, 279.71999999999997);
UPDATE orders SET total_amount = 655.37 WHERE id = 177;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (178, 10, 'ORD-2024178', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (178, 76, 2, 95.59, 191.18);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (178, 19, 3, 19.6, 58.800000000000004);
UPDATE orders SET total_amount = 249.98000000000002 WHERE id = 178;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (179, 5, 'ORD-2024179', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (179, 44, 3, 21.5, 64.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (179, 27, 3, 11.45, 34.349999999999994);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (179, 46, 1, 54.24, 54.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (179, 100, 3, 28.65, 85.94999999999999);
UPDATE orders SET total_amount = 239.04 WHERE id = 179;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (180, 46, 'ORD-2024180', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (180, 66, 1, 12.4, 12.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (180, 100, 1, 10.56, 10.56);
UPDATE orders SET total_amount = 22.96 WHERE id = 180;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (181, 17, 'ORD-2024181', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (181, 4, 3, 92.93, 278.79);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (181, 96, 3, 46.31, 138.93);
UPDATE orders SET total_amount = 417.72 WHERE id = 181;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (182, 34, 'ORD-2024182', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (182, 41, 3, 11.27, 33.81);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (182, 96, 3, 17.51, 52.53);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (182, 66, 3, 64.95, 194.85000000000002);
UPDATE orders SET total_amount = 281.19000000000005 WHERE id = 182;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (183, 48, 'ORD-2024183', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (183, 15, 3, 13.54, 40.62);
UPDATE orders SET total_amount = 40.62 WHERE id = 183;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (184, 23, 'ORD-2024184', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (184, 89, 2, 37.94, 75.88);
UPDATE orders SET total_amount = 75.88 WHERE id = 184;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (185, 26, 'ORD-2024185', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (185, 69, 3, 45.65, 136.95);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (185, 82, 1, 40.5, 40.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (185, 40, 1, 54.39, 54.39);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (185, 18, 2, 95.45, 190.9);
UPDATE orders SET total_amount = 422.74 WHERE id = 185;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (186, 17, 'ORD-2024186', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (186, 70, 1, 19.87, 19.87);
UPDATE orders SET total_amount = 19.87 WHERE id = 186;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (187, 24, 'ORD-2024187', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (187, 28, 1, 47.86, 47.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (187, 60, 1, 44.49, 44.49);
UPDATE orders SET total_amount = 92.35 WHERE id = 187;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (188, 37, 'ORD-2024188', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (188, 72, 1, 69.63, 69.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (188, 1, 2, 50.33, 100.66);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (188, 37, 3, 99.34, 298.02);
UPDATE orders SET total_amount = 468.30999999999995 WHERE id = 188;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (189, 19, 'ORD-2024189', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (189, 76, 3, 69.2, 207.60000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (189, 14, 3, 53.75, 161.25);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (189, 91, 2, 71.43, 142.86);
UPDATE orders SET total_amount = 511.71000000000004 WHERE id = 189;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (190, 29, 'ORD-2024190', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (190, 77, 3, 11.44, 34.32);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (190, 50, 3, 49.23, 147.69);
UPDATE orders SET total_amount = 182.01 WHERE id = 190;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (191, 41, 'ORD-2024191', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (191, 18, 3, 19.26, 57.78);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (191, 10, 3, 35.64, 106.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (191, 48, 1, 73.87, 73.87);
UPDATE orders SET total_amount = 238.57 WHERE id = 191;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (192, 3, 'ORD-2024192', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (192, 15, 2, 60.21, 120.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (192, 25, 2, 49.19, 98.38);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (192, 80, 3, 92.54, 277.62);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (192, 3, 1, 77.29, 77.29);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (192, 99, 3, 56.39, 169.17000000000002);
UPDATE orders SET total_amount = 742.8800000000001 WHERE id = 192;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (193, 9, 'ORD-2024193', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (193, 29, 3, 91.3, 273.9);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (193, 61, 2, 53.05, 106.1);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (193, 81, 3, 92.12, 276.36);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (193, 56, 2, 63.85, 127.7);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (193, 5, 2, 70.98, 141.96);
UPDATE orders SET total_amount = 926.0200000000001 WHERE id = 193;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (194, 47, 'ORD-2024194', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (194, 24, 2, 20.38, 40.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (194, 1, 1, 60.28, 60.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (194, 38, 1, 35.75, 35.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (194, 72, 3, 70.27, 210.81);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (194, 7, 3, 54.55, 163.64999999999998);
UPDATE orders SET total_amount = 511.25 WHERE id = 194;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (195, 22, 'ORD-2024195', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (195, 28, 3, 78.78, 236.34);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (195, 13, 3, 73.7, 221.10000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (195, 85, 1, 57.56, 57.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (195, 56, 2, 18.14, 36.28);
UPDATE orders SET total_amount = 551.28 WHERE id = 195;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (196, 9, 'ORD-2024196', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (196, 43, 2, 98.08, 196.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (196, 43, 2, 69.39, 138.78);
UPDATE orders SET total_amount = 334.94 WHERE id = 196;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (197, 16, 'ORD-2024197', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (197, 31, 1, 40.51, 40.51);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (197, 33, 1, 39.54, 39.54);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (197, 33, 2, 74.84, 149.68);
UPDATE orders SET total_amount = 229.73000000000002 WHERE id = 197;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (198, 5, 'ORD-2024198', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (198, 62, 1, 59.88, 59.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (198, 7, 2, 21.38, 42.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (198, 80, 3, 60.21, 180.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (198, 1, 2, 67.68, 135.36);
UPDATE orders SET total_amount = 418.63 WHERE id = 198;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (199, 12, 'ORD-2024199', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (199, 65, 1, 63.44, 63.44);
UPDATE orders SET total_amount = 63.44 WHERE id = 199;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (200, 27, 'ORD-2024200', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (200, 25, 2, 48.3, 96.6);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (200, 76, 3, 38.16, 114.47999999999999);
UPDATE orders SET total_amount = 211.07999999999998 WHERE id = 200;
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (67, 43, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (21, 48, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (63, 12, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (25, 43, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (38, 26, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (55, 43, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (33, 49, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (66, 15, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (50, 3, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (42, 10, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (98, 37, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (62, 49, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (10, 27, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (11, 28, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (11, 4, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (21, 18, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (61, 28, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (41, 39, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (8, 48, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (76, 17, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (75, 19, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (36, 34, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (2, 37, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (29, 13, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (55, 25, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (3, 4, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (98, 38, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (12, 9, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (2, 21, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (64, 36, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (2, 24, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (10, 45, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (66, 39, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (43, 16, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (98, 35, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (34, 41, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (69, 38, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (63, 32, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (15, 29, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (18, 8, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (14, 38, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (79, 32, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (41, 19, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (75, 9, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (9, 28, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (47, 13, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (53, 39, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (65, 14, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (39, 18, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (90, 20, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (56, 34, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (24, 13, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (94, 49, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (49, 45, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (12, 15, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (30, 41, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (5, 16, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (3, 6, 5, 'Great product!');
