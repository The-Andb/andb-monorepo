-- ==========================================
-- PROD Environment Schema
-- Generated at 2025-11-23 16:44:35.900730
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
INSERT INTO users (id, username, email, password_hash) VALUES (1, 'danielsmith1', 'danielsmith1@example.com', 'hash_secret_1');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (1, 'Daniel', 'Smith', '555-0101');
INSERT INTO users (id, username, email, password_hash) VALUES (2, 'lauradavis2', 'lauradavis2@example.com', 'hash_secret_2');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (2, 'Laura', 'Davis', '555-0102');
INSERT INTO users (id, username, email, password_hash) VALUES (3, 'johnjohnson3', 'johnjohnson3@example.com', 'hash_secret_3');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (3, 'John', 'Johnson', '555-0103');
INSERT INTO users (id, username, email, password_hash) VALUES (4, 'danieljohnson4', 'danieljohnson4@example.com', 'hash_secret_4');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (4, 'Daniel', 'Johnson', '555-0104');
INSERT INTO users (id, username, email, password_hash) VALUES (5, 'emilyjohnson5', 'emilyjohnson5@example.com', 'hash_secret_5');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (5, 'Emily', 'Johnson', '555-0105');
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (1, 7, 'Product 1 - Standard', 'SKU-0001', 20.5, 8);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (2, 2, 'Product 2 - Pro', 'SKU-0002', 470.34, 88);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (3, 6, 'Product 3 - Max', 'SKU-0003', 406.36, 14);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (4, 5, 'Product 4 - Plus', 'SKU-0004', 138.67, 61);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (5, 1, 'Product 5 - Plus', 'SKU-0005', 205.31, 76);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (6, 8, 'Product 6 - Standard', 'SKU-0006', 72.77, 48);
INSERT INTO product_tags (product_id, tag_id) VALUES (6, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (7, 3, 'Product 7 - Pro', 'SKU-0007', 352.33, 53);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (8, 5, 'Product 8 - Lite', 'SKU-0008', 478.18, 39);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (9, 1, 'Product 9 - Pro', 'SKU-0009', 480.67, 51);
INSERT INTO product_tags (product_id, tag_id) VALUES (9, 5);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (10, 4, 'Product 10 - Plus', 'SKU-0010', 39.56, 64);
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (1, 2, 'ORD-2024001', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 7, 1, 53.16, 53.16);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 1, 1, 72.54, 72.54);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 9, 3, 26.05, 78.15);
UPDATE orders SET total_amount = 203.85000000000002 WHERE id = 1;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (2, 4, 'ORD-2024002', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 7, 1, 75.45, 75.45);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 10, 3, 11.89, 35.67);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 6, 1, 89.0, 89.0);
UPDATE orders SET total_amount = 200.12 WHERE id = 2;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (3, 4, 'ORD-2024003', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 9, 3, 63.11, 189.32999999999998);
UPDATE orders SET total_amount = 189.32999999999998 WHERE id = 3;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (4, 1, 'ORD-2024004', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 5, 1, 26.51, 26.51);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 6, 2, 13.05, 26.1);
UPDATE orders SET total_amount = 52.61 WHERE id = 4;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (5, 5, 'ORD-2024005', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 3, 3, 40.82, 122.46000000000001);
UPDATE orders SET total_amount = 122.46000000000001 WHERE id = 5;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (6, 5, 'ORD-2024006', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 4, 2, 31.58, 63.16);
UPDATE orders SET total_amount = 63.16 WHERE id = 6;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (7, 5, 'ORD-2024007', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 1, 3, 79.24, 237.71999999999997);
UPDATE orders SET total_amount = 237.71999999999997 WHERE id = 7;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (8, 3, 'ORD-2024008', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 3, 2, 54.14, 108.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 3, 3, 66.49, 199.46999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 7, 1, 24.75, 24.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 7, 2, 27.2, 54.4);
UPDATE orders SET total_amount = 386.9 WHERE id = 8;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (9, 5, 'ORD-2024009', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 2, 1, 71.24, 71.24);
UPDATE orders SET total_amount = 71.24 WHERE id = 9;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (10, 1, 'ORD-2024010', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 9, 3, 41.36, 124.08);
UPDATE orders SET total_amount = 124.08 WHERE id = 10;
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (8, 2, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (10, 5, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (9, 5, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (7, 5, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (4, 2, 5, 'Great product!');
