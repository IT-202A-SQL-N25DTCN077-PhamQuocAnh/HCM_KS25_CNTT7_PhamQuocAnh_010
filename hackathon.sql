CREATE DATABASE contract_management_db;
-- DROP DATABASe contract_management_db;
USE contract_management_db;

SET SQL_SAFE_UPDATES = 0;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    join_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE insurance_packages (
    package_id VARCHAR(10) PRIMARY KEY,
    package_name VARCHAR(255) NOT NULL,
    max_limit DECIMAL(18 , 2 ) NOT NULL CHECK (max_limit > 0),
    base_premium DECIMAL(18 , 2 ) NOT NULL CHECK (base_premium > 0)
);

CREATE TABLE policies (
    policy_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    package_id VARCHAR(10) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('Active', 'Expired', 'Cancelled') NOT NULL,
    FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id),
    FOREIGN KEY (package_id)
        REFERENCES insurance_packages (package_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
ALTER TABLE policies 
ADD CONSTRAINT ch_k_date CHECK (end_date > start_date);


CREATE TABLE claims(
	claim_id VARCHAR(10) PRIMARY KEY,
    policy_id VARCHAR(10) NOT NULL,
    claim_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    claim_amount DECIMAL(18,2) NOT NULL CHECK (claim_amount > 0),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
);

CREATE TABLE claim_processing_log(
	log_id VARCHAR(10) PRIMARY KEY,
    claim_id VARCHAR(10) NOT NULL,
    action_detail TEXT NOT NULL,
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processor VARCHAR(50) NOT NULL,
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
);

INSERT INTO customers(customer_id, full_name, phone_number, email, join_date) VALUES
('C001', 'Nguyen Hoang Long', '0901112223', 'long.nh@gmail.com', '2024-01-14'),
('C002', 'Tran Thi Kim Anh', '09888777666', 'anh.tk@gmail.com', '2024-03-10'),
('C003', 'Le Hoang Nam', '0903334445', 'nam.lh@gmail.com', '2025-05-20'),
('C004', 'Pham Minh Duc', '0355556667', 'duc.pm@gmail.com', '2025-08-12'),
('C005', 'Hoang Thu Thao', '0779998881', 'thao.ht@gmail.com', '2026-01-01');

INSERT INTO insurance_packages(package_id, package_name, max_limit, base_premium) VALUES 
('PKG01', 'Bảo hiểm Sức Khỏe GOLD', 500000000.00, 5000000.00 ),
('PKG02', 'Bảo hiểm Ô TÔ Liberty', 1000000000.00, 15000000.00 ),
('PKG03', 'Bảo hiểm Nhân thọ An Bình', 2000000000.00, 25000000.00 ),
('PKG04', 'Bảo hiểm Du lịch Quốc Tế', 100000000.00, 1000000.00 ),
('PKG05', 'Bảo hiểm Tai nạn 24/7', 200000000.00, 2500000.00 );

INSERT INTO policies(policy_id, customer_id, package_id, start_date, end_date, status) VALUES
('POL101', 'C001', 'PKG01', '2024-01-15', '2025-01-15', 'Expired'),
('POL102', 'C002', 'PKG02', '2024-03-10', '2026-03-10','Active'),
('POL103', 'C003', 'PKG03', '2025-05-20','2035-05-20', 'Active'),
('POL104', 'C004', 'PKG04', '2025-08-12', '2025-09-12','Expired'),
('POL105', 'C005', 'PKG01', '2026-01-01','2027-01-01', 'Active');

INSERT INTO claims(claim_id, policy_id, claim_date, claim_amount, status) VALUES
('CLM901', 'POL102', '2024-06-15',12000000.00, 'Approved'),
('CLM902', 'POL103', '2025-10-15',50000000.00, 'Pending'),
('CLM903', 'POL101', '2024-11-15',5500000.00, 'Approved'),
('CLM904', 'POL105', '2026-01-15',2000000.00, 'Rejected'),
('CLM905', 'POL102', '2025-02-15',120000000.00, 'Approved');

INSERT INTO claim_processing_log(log_id, claim_id, action_detail, recorded_at, processor) VALUES
('L001', 'CLM901', 'Đã nhận hồ sơ hiện trường', '2024-06-15 09:00','Admin_01'),
('L002', 'CLM901', 'Chấp nhận bồi thường xe tai nạn', '2024-06-20 14:30','Admin_01'),
('L003', 'CLM902', 'Đang thẩm địng hồ sơ bệnh án', '2025-10-21 10:00','Admin_02'),
('L004', 'CLM904', 'Từ chối do lỗi cố ý của khách hàng', '2026-01-16 16:00','Admin_03'),
('L005', 'CLM905', 'Đã thanh toán qua chuyển khoản', '2025-02-15 08:30','Accountant_01');

-- -----------------------------------------------------------
-- 1.3 Cập nhật và xóa dữ liệu 
UPDATE insurance_packages
SET base_premium = base_premium + (base_premium * 0.15)
WHERE max_limit > 500000000;

DELETE FROM claim_processing_log 
WHERE DATE(recorded_at) <= '2025-06-20';

-- 1.3
SELECT * FROM policies 
WHERE status = 'Active' AND (end_date BETWEEN '2026-01-01' AND '2026-12-31'); 

SELECT full_name, email FROM customers 
WHERE full_name LIKE '%Hoang%' AND (DATE(join_date) BETWEEN '2025-01-01' AND DATE(NOW()));

SELECT * FROM claims
ORDER BY claim_amount DESC
LIMIT 3 OFFSET 1;
-- -------------------------------------------
SELECT 
    c.full_name, ip.package_name, p.start_date, ip.base_premium
FROM
    customers c
        LEFT JOIN
    policies p ON p.customer_id = c.customer_id
        LEFT JOIN
    insurance_packages ip ON ip.package_id = p.package_id;

-- ----------------------------------------------------------
SELECT 
		c.customer_id,
		c.full_name,
		SUM(claim_amount) AS total_amount
FROM claims cl
    JOIN
    policies p ON cl.policy_id = p.policy_id
    JOIN 
    customers c ON c.customer_id = p.customer_id
WHERE
    cl.status = 'Approved'
GROUP BY c.customer_id, c.full_name
HAVING total_amount > 50000000;

SELECT p.package_id, ip.package_name, COUNT(p.package_id) AS total_package FROM policies p 
JOIN insurance_packages ip ON p.package_id = ip.package_id
GROUP BY  p.package_id, ip.package_name
ORDER BY total_package DESC
LIMIT 1;

-- -----------------------------------------------------------------
CREATE INDEX idx_policy_status_date ON policies(status, start_date);

CREATE VIEW vw_customer_summary AS 
SELECT c.full_name , count(c.customer_id) as so_bao_hiem, sum(ip.base_premium) as tong_tien FROM customers c
LEFT JOIN policies p ON p.customer_id = c.customer_id
LEFT JOIN insurance_packages ip ON ip.package_id = p.package_id
GROUP BY c.full_name;
-- ------------------------------------------------------------------------------------
DROP TRIGGER trg_after_claim_approved;
DELIMITER $$
CREATE TRIGGER trg_after_claim_approved
AFTER UPDATE ON claims
FOR EACH ROW
BEGIN
	INSERT INTO claim_processing_log(log_id, claim_id, action_detail, recorded_at,processor ) VALUES
    (NEW.claim_id, NEW.claim_id, 'PAYMENT PROCESSED TO CUSTOMER',NEW.claim_date, 'Admin');
END $$

DELIMITER ;

UPDATE claims
SET claim_amount  = 54646 
WHERE claim_id = 'CLM901';

DELIMITER $$
CREATE TRIGGER trg_before_delete
BEFORE DELETE ON policies
FOR EACH ROW
BEGIN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Không thể xóa hợp đồng';
END $$

DELIMITER ;

DELETE FROM policies
WHERE policy_id = 'POL102';



