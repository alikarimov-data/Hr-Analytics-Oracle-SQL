-- ============================================================
-- STEP 0 (run ONCE, as SYSTEM) - Oracle 21c XE
-- Connect in SQL Developer as SYSTEM with Service name = XEPDB1
-- (NOT the "XE" SID). Then run this script (F5).
-- Change the password below to your own before running.
-- ============================================================
CREATE USER hr_analytics IDENTIFIED BY "ChangeMe_123";
GRANT CONNECT, RESOURCE, CREATE VIEW TO hr_analytics;
ALTER USER hr_analytics QUOTA UNLIMITED ON USERS;
