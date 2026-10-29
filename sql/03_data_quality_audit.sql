-- ============================================================
-- Data quality audit + a clean base view (Oracle)
-- Run as HR_ANALYTICS. Select ONE statement and press Ctrl+Enter,
-- or run the whole file with F5 (Run Script).
-- ============================================================

-- 1) Contracts whose termination date is BEFORE the hire date
SELECT COUNT(*) AS bad_contracts,
       (SELECT COUNT(*) FROM contract WHERE termination_date IS NOT NULL) AS terminated_total
FROM contract
WHERE termination_date < hire_date;

-- 2) Attendance rows where the exit time is BEFORE the entrance time
SELECT COUNT(*) AS bad_rows,
       (SELECT COUNT(*) FROM employee_attendance) AS total_rows,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM employee_attendance), 1) AS bad_pct
FROM employee_attendance
WHERE exit_time < entrance_time;

-- 3) Is attendance usable at all? A realistic shift is 0-24 hours.
--    (In Oracle, DATE - DATE gives DAYS, so we multiply by 24 for hours.)
SELECT SUM(CASE WHEN exit_time >= entrance_time
                 AND (exit_time - entrance_time) * 24 <= 24 THEN 1 ELSE 0 END) AS plausible_shifts,
       COUNT(*)                                                                AS total_rows,
       ROUND(AVG((exit_time - entrance_time) * 24), 1)                         AS avg_hours_raw
FROM employee_attendance;

-- 4) Disability: employee ids that do not exist in the lookup table
SELECT e.disability_id, COUNT(*) AS employees,
       (SELECT COUNT(*) FROM disability d WHERE d.id = e.disability_id) AS found_in_lookup
FROM employee_list e
WHERE e.disability_id IS NOT NULL
GROUP BY e.disability_id
ORDER BY e.disability_id;

-- 5) Order names: how many orders actually have a name?
SELECT COUNT(*) AS orders_total,
       SUM(CASE WHEN n.id IS NOT NULL THEN 1 ELSE 0 END) AS orders_with_name
FROM order_list o
LEFT JOIN order_name_list n ON n.id = o.id;

-- 6) Duplicate position names (same name, different id)
SELECT position_name, COUNT(*) AS id_count,
       LISTAGG(id, ',') WITHIN GROUP (ORDER BY id) AS ids
FROM positions
GROUP BY position_name
HAVING COUNT(*) > 1;

-- 7) Missing values in columns that can be empty
SELECT 'employee_list.disability_id' AS column_name,
       SUM(CASE WHEN disability_id IS NULL THEN 1 ELSE 0 END) AS nulls
FROM employee_list
UNION ALL
SELECT 'contract.termination_date',
       SUM(CASE WHEN termination_date IS NULL THEN 1 ELSE 0 END)
FROM contract;

-- ------------------------------------------------------------
-- Clean base view used by the business queries.
-- tenure_years is computed to the termination date, or to today
-- for active employees. valid_dates = 0 flags broken contracts.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_hr_base AS
SELECT e.employee_id,
       e.employee_name,
       CASE e.gender_id WHEN 1 THEN 'Female' ELSE 'Male' END           AS gender,
       TRUNC(MONTHS_BETWEEN(SYSDATE, e.date_of_birth) / 12)            AS age,
       c.id                                                            AS contract_id,
       c.hire_date,
       c.termination_date,
       CASE WHEN c.termination_date IS NULL THEN 1 ELSE 0 END          AS is_active,
       CASE WHEN c.termination_date IS NULL
              OR c.termination_date >= c.hire_date THEN 1 ELSE 0 END   AS valid_dates,
       CASE WHEN c.termination_date IS NULL
              OR c.termination_date >= c.hire_date
            THEN TRUNC(MONTHS_BETWEEN(NVL(c.termination_date, SYSDATE), c.hire_date) / 12)
       END                                                             AS tenure_years,
       a.salary,
       a.vacation_days,
       a.manager_id,
       d.department_name,
       p.position_name
FROM employee_list e
JOIN contract c          ON c.employee_id = e.employee_id
JOIN contract_appendix a ON a.contract_id = c.id
JOIN department d        ON d.id = a.department_id
JOIN positions p         ON p.id = a.position_id;

SELECT COUNT(*) AS rows_in_view, SUM(valid_dates) AS valid_rows FROM v_hr_base;
