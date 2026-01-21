-- ==========================================
-- UAT Environment Schema
-- Generated at 2025-11-23 16:44:35.872087
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
INSERT INTO users (id, username, email, password_hash) VALUES (1, 'laurabrown1', 'laurabrown1@example.com', 'hash_secret_1');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (1, 'Laura', 'Brown', '555-0101');
INSERT INTO users (id, username, email, password_hash) VALUES (2, 'lauramartinez2', 'lauramartinez2@example.com', 'hash_secret_2');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (2, 'Laura', 'Martinez', '555-0102');
INSERT INTO users (id, username, email, password_hash) VALUES (3, 'johnmartinez3', 'johnmartinez3@example.com', 'hash_secret_3');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (3, 'John', 'Martinez', '555-0103');
INSERT INTO users (id, username, email, password_hash) VALUES (4, 'davidrodriguez4', 'davidrodriguez4@example.com', 'hash_secret_4');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (4, 'David', 'Rodriguez', '555-0104');
INSERT INTO users (id, username, email, password_hash) VALUES (5, 'davidmiller5', 'davidmiller5@example.com', 'hash_secret_5');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (5, 'David', 'Miller', '555-0105');
INSERT INTO users (id, username, email, password_hash) VALUES (6, 'emilyrodriguez6', 'emilyrodriguez6@example.com', 'hash_secret_6');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (6, 'Emily', 'Rodriguez', '555-0106');
INSERT INTO users (id, username, email, password_hash) VALUES (7, 'janejohnson7', 'janejohnson7@example.com', 'hash_secret_7');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (7, 'Jane', 'Johnson', '555-0107');
INSERT INTO users (id, username, email, password_hash) VALUES (8, 'emilymiller8', 'emilymiller8@example.com', 'hash_secret_8');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (8, 'Emily', 'Miller', '555-0108');
INSERT INTO users (id, username, email, password_hash) VALUES (9, 'johndavis9', 'johndavis9@example.com', 'hash_secret_9');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (9, 'John', 'Davis', '555-0109');
INSERT INTO users (id, username, email, password_hash) VALUES (10, 'janegarcia10', 'janegarcia10@example.com', 'hash_secret_10');
INSERT INTO user_profiles (user_id, first_name, last_name, phone) VALUES (10, 'Jane', 'Garcia', '555-0110');
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (1, 2, 'Product 1 - Pro', 'SKU-0001', 292.47, 61);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (2, 5, 'Product 2 - Pro', 'SKU-0002', 410.89, 62);
INSERT INTO product_tags (product_id, tag_id) VALUES (2, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (3, 3, 'Product 3 - Pro', 'SKU-0003', 472.07, 98);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (4, 7, 'Product 4 - Pro', 'SKU-0004', 309.02, 6);
INSERT INTO product_tags (product_id, tag_id) VALUES (4, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (5, 7, 'Product 5 - Max', 'SKU-0005', 273.14, 49);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (6, 8, 'Product 6 - Standard', 'SKU-0006', 404.15, 44);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (7, 7, 'Product 7 - Max', 'SKU-0007', 317.6, 64);
INSERT INTO product_tags (product_id, tag_id) VALUES (7, 4);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (8, 7, 'Product 8 - Plus', 'SKU-0008', 274.97, 54);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (9, 5, 'Product 9 - Lite', 'SKU-0009', 400.81, 42);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (10, 1, 'Product 10 - Plus', 'SKU-0010', 230.18, 9);
INSERT INTO product_tags (product_id, tag_id) VALUES (10, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (11, 4, 'Product 11 - Standard', 'SKU-0011', 400.17, 91);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (12, 2, 'Product 12 - Plus', 'SKU-0012', 138.17, 53);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (13, 5, 'Product 13 - Lite', 'SKU-0013', 438.11, 15);
INSERT INTO product_tags (product_id, tag_id) VALUES (13, 1);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (14, 5, 'Product 14 - Lite', 'SKU-0014', 348.0, 3);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (15, 6, 'Product 15 - Plus', 'SKU-0015', 402.77, 29);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (16, 2, 'Product 16 - Plus', 'SKU-0016', 270.01, 59);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (17, 3, 'Product 17 - Standard', 'SKU-0017', 209.0, 7);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (18, 2, 'Product 18 - Lite', 'SKU-0018', 403.81, 88);
INSERT INTO product_tags (product_id, tag_id) VALUES (18, 2);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (19, 2, 'Product 19 - Plus', 'SKU-0019', 491.67, 79);
INSERT INTO products (id, category_id, name, sku, price, stock_quantity) VALUES (20, 4, 'Product 20 - Pro', 'SKU-0020', 419.79, 100);
INSERT INTO product_tags (product_id, tag_id) VALUES (20, 1);
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (1, 7, 'ORD-2024001', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 10, 2, 33.96, 67.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 15, 1, 40.79, 40.79);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (1, 1, 2, 46.88, 93.76);
UPDATE orders SET total_amount = 202.47000000000003 WHERE id = 1;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (2, 3, 'ORD-2024002', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 5, 1, 43.01, 43.01);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (2, 19, 1, 79.2, 79.2);
UPDATE orders SET total_amount = 122.21000000000001 WHERE id = 2;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (3, 1, 'ORD-2024003', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 15, 1, 32.53, 32.53);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (3, 1, 1, 82.96, 82.96);
UPDATE orders SET total_amount = 115.49 WHERE id = 3;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (4, 1, 'ORD-2024004', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 6, 3, 71.37, 214.11);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 5, 3, 62.25, 186.75);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (4, 15, 1, 19.9, 19.9);
UPDATE orders SET total_amount = 420.76 WHERE id = 4;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (5, 3, 'ORD-2024005', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 2, 1, 42.56, 42.56);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (5, 5, 3, 84.73, 254.19);
UPDATE orders SET total_amount = 296.75 WHERE id = 5;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (6, 4, 'ORD-2024006', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 7, 1, 59.85, 59.85);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 1, 3, 91.64, 274.92);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 11, 2, 57.04, 114.08);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 18, 3, 71.57, 214.70999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (6, 18, 2, 55.72, 111.44);
UPDATE orders SET total_amount = 775.0 WHERE id = 6;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (7, 6, 'ORD-2024007', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 10, 1, 94.47, 94.47);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (7, 13, 3, 53.43, 160.29);
UPDATE orders SET total_amount = 254.76 WHERE id = 7;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (8, 2, 'ORD-2024008', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 9, 3, 51.0, 153.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (8, 11, 3, 75.57, 226.70999999999998);
UPDATE orders SET total_amount = 379.71 WHERE id = 8;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (9, 6, 'ORD-2024009', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 6, 2, 27.97, 55.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (9, 8, 1, 55.55, 55.55);
UPDATE orders SET total_amount = 111.49 WHERE id = 9;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (10, 9, 'ORD-2024010', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 16, 1, 82.07, 82.07);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 12, 2, 24.86, 49.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 5, 2, 12.56, 25.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 1, 2, 80.91, 161.82);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (10, 14, 1, 34.28, 34.28);
UPDATE orders SET total_amount = 353.01 WHERE id = 10;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (11, 5, 'ORD-2024011', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 7, 3, 54.3, 162.89999999999998);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (11, 16, 1, 88.62, 88.62);
UPDATE orders SET total_amount = 251.51999999999998 WHERE id = 11;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (12, 3, 'ORD-2024012', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (12, 12, 1, 52.21, 52.21);
UPDATE orders SET total_amount = 52.21 WHERE id = 12;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (13, 10, 'ORD-2024013', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 7, 2, 64.44, 128.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 19, 3, 18.66, 55.980000000000004);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 14, 3, 93.21, 279.63);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 13, 2, 71.02, 142.04);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (13, 19, 1, 50.57, 50.57);
UPDATE orders SET total_amount = 657.1 WHERE id = 13;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (14, 2, 'ORD-2024014', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 11, 1, 19.71, 19.71);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 7, 2, 16.9, 33.8);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (14, 6, 2, 48.26, 96.52);
UPDATE orders SET total_amount = 150.03 WHERE id = 14;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (15, 5, 'ORD-2024015', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 12, 3, 18.4, 55.199999999999996);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 6, 1, 57.88, 57.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 9, 3, 97.15, 291.45000000000005);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (15, 11, 1, 90.82, 90.82);
UPDATE orders SET total_amount = 495.35 WHERE id = 15;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (16, 2, 'ORD-2024016', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 14, 3, 76.88, 230.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 19, 1, 74.17, 74.17);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 1, 1, 85.91, 85.91);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 7, 3, 97.74, 293.21999999999997);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (16, 9, 2, 62.37, 124.74);
UPDATE orders SET total_amount = 808.6800000000001 WHERE id = 16;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (17, 7, 'ORD-2024017', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 11, 2, 25.61, 51.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 19, 1, 53.97, 53.97);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 19, 3, 40.76, 122.28);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (17, 17, 1, 95.11, 95.11);
UPDATE orders SET total_amount = 322.58 WHERE id = 17;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (18, 2, 'ORD-2024018', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 10, 3, 74.81, 224.43);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 4, 1, 20.43, 20.43);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (18, 13, 3, 63.72, 191.16);
UPDATE orders SET total_amount = 436.02 WHERE id = 18;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (19, 4, 'ORD-2024019', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 19, 1, 64.45, 64.45);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 4, 3, 98.09, 294.27);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 3, 2, 68.32, 136.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (19, 4, 2, 66.73, 133.46);
UPDATE orders SET total_amount = 628.8199999999999 WHERE id = 19;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (20, 6, 'ORD-2024020', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 15, 3, 51.92, 155.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 9, 1, 39.81, 39.81);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 17, 2, 74.65, 149.3);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (20, 15, 1, 93.67, 93.67);
UPDATE orders SET total_amount = 438.54 WHERE id = 20;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (21, 4, 'ORD-2024021', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 8, 2, 46.7, 93.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 9, 2, 47.75, 95.5);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 9, 2, 11.73, 23.46);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 1, 1, 91.36, 91.36);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (21, 4, 2, 46.31, 92.62);
UPDATE orders SET total_amount = 396.34000000000003 WHERE id = 21;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (22, 2, 'ORD-2024022', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (22, 11, 1, 92.4, 92.4);
UPDATE orders SET total_amount = 92.4 WHERE id = 22;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (23, 10, 'ORD-2024023', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (23, 11, 3, 73.69, 221.07);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (23, 1, 3, 44.57, 133.71);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (23, 2, 3, 34.6, 103.80000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (23, 15, 3, 10.04, 30.119999999999997);
UPDATE orders SET total_amount = 488.7 WHERE id = 23;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (24, 4, 'ORD-2024024', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 14, 3, 34.63, 103.89000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 18, 2, 18.05, 36.1);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 15, 1, 18.48, 18.48);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (24, 16, 2, 43.81, 87.62);
UPDATE orders SET total_amount = 246.09 WHERE id = 24;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (25, 10, 'ORD-2024025', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 12, 3, 34.2, 102.60000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 10, 2, 13.2, 26.4);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 7, 2, 27.56, 55.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (25, 13, 3, 27.58, 82.74);
UPDATE orders SET total_amount = 266.86 WHERE id = 25;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (26, 5, 'ORD-2024026', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (26, 4, 1, 96.76, 96.76);
UPDATE orders SET total_amount = 96.76 WHERE id = 26;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (27, 8, 'ORD-2024027', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 5, 2, 88.42, 176.84);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 12, 2, 74.42, 148.84);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 20, 2, 29.36, 58.72);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 10, 2, 28.6, 57.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (27, 4, 2, 83.27, 166.54);
UPDATE orders SET total_amount = 608.14 WHERE id = 27;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (28, 8, 'ORD-2024028', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 12, 3, 82.62, 247.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 6, 2, 35.32, 70.64);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 6, 1, 10.17, 10.17);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 9, 1, 95.17, 95.17);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (28, 19, 2, 26.61, 53.22);
UPDATE orders SET total_amount = 477.06000000000006 WHERE id = 28;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (29, 4, 'ORD-2024029', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 4, 2, 10.06, 20.12);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 14, 3, 31.14, 93.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (29, 12, 2, 27.89, 55.78);
UPDATE orders SET total_amount = 169.32 WHERE id = 29;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (30, 9, 'ORD-2024030', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 7, 1, 77.74, 77.74);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 10, 2, 93.71, 187.42);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 9, 2, 36.18, 72.36);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (30, 14, 3, 54.27, 162.81);
UPDATE orders SET total_amount = 500.33 WHERE id = 30;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (31, 1, 'ORD-2024031', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 17, 1, 13.24, 13.24);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (31, 2, 1, 89.91, 89.91);
UPDATE orders SET total_amount = 103.14999999999999 WHERE id = 31;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (32, 9, 'ORD-2024032', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 4, 3, 84.62, 253.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (32, 16, 1, 58.71, 58.71);
UPDATE orders SET total_amount = 312.57 WHERE id = 32;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (33, 3, 'ORD-2024033', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 5, 3, 85.75, 257.25);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 18, 3, 37.02, 111.06);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 18, 1, 83.86, 83.86);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 9, 1, 64.1, 64.1);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (33, 6, 1, 73.66, 73.66);
UPDATE orders SET total_amount = 589.93 WHERE id = 33;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (34, 2, 'ORD-2024034', 0, 'shipped');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 5, 2, 42.39, 84.78);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 11, 1, 63.88, 63.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 12, 2, 11.97, 23.94);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (34, 14, 1, 18.3, 18.3);
UPDATE orders SET total_amount = 190.9 WHERE id = 34;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (35, 2, 'ORD-2024035', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 20, 3, 31.07, 93.21000000000001);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 13, 3, 83.14, 249.42000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 1, 2, 57.4, 114.8);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 20, 3, 55.4, 166.2);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (35, 9, 3, 18.79, 56.37);
UPDATE orders SET total_amount = 680.0 WHERE id = 35;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (36, 10, 'ORD-2024036', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 10, 2, 98.61, 197.22);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 16, 1, 84.49, 84.49);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 18, 1, 24.0, 24.0);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 15, 1, 31.47, 31.47);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (36, 11, 3, 55.38, 166.14000000000001);
UPDATE orders SET total_amount = 503.31999999999994 WHERE id = 36;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (37, 5, 'ORD-2024037', 0, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 4, 3, 93.7, 281.1);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (37, 19, 3, 85.53, 256.59000000000003);
UPDATE orders SET total_amount = 537.69 WHERE id = 37;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (38, 1, 'ORD-2024038', 0, 'cancelled');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (38, 13, 3, 88.96, 266.88);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (38, 20, 3, 55.92, 167.76);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (38, 13, 1, 91.17, 91.17);
UPDATE orders SET total_amount = 525.81 WHERE id = 38;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (39, 4, 'ORD-2024039', 0, 'processing');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (39, 19, 3, 77.41, 232.23);
UPDATE orders SET total_amount = 232.23 WHERE id = 39;
INSERT INTO orders (id, user_id, order_number, total_amount, status) VALUES (40, 3, 'ORD-2024040', 0, 'delivered');
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 14, 3, 80.45, 241.35000000000002);
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (40, 11, 2, 82.19, 164.38);
UPDATE orders SET total_amount = 405.73 WHERE id = 40;
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (5, 10, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (15, 8, 4, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (5, 6, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (20, 9, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (1, 8, 5, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (4, 2, 2, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (18, 4, 3, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (14, 6, 1, 'Great product!');
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (15, 4, 1, 'Great product!');
