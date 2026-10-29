-- ============================================================
-- Business questions answered with Oracle SQL
-- Uses: JOIN, GROUP BY, CASE, CTE, window functions
-- Run 03_data_quality_audit.sql first (it creates v_hr_base).
-- Select ONE query and press Ctrl+Enter to run it.
-- ============================================================

-- Q1. Headcount, leavers and attrition rate by department
SELECT department_name,
       COUNT(*)                                       AS headcount,
       SUM(is_active)                                 AS active,
       SUM(1 - is_active)                             AS leavers,
       ROUND(100 * SUM(1 - is_active) / COUNT(*), 1)  AS attrition_pct
FROM v_hr_base
GROUP BY department_name
ORDER BY attrition_pct DESC;

-- Q2. Salary profile by position (positions merged by name)
SELECT position_name,
       COUNT(*)              AS employees,
       ROUND(AVG(salary), 0) AS avg_salary,
       MIN(salary)           AS min_salary,
       MAX(salary)           AS max_salary
FROM v_hr_base
GROUP BY position_name
ORDER BY avg_salary DESC;

-- Q3. Top 3 highest-paid employees in each department (ROW_NUMBER)
WITH ranked AS (
    SELECT department_name, employee_name, position_name, salary,
           ROW_NUMBER() OVER (PARTITION BY department_name ORDER BY salary DESC) AS rn
    FROM v_hr_base
)
SELECT department_name, rn AS salary_rank, employee_name, position_name, salary
FROM ranked
WHERE rn <= 3
ORDER BY department_name, rn;

-- Q4. Hiring trend: hires per year, change vs previous year (LAG)
--     and cumulative hires (running total)
WITH hires AS (
    SELECT EXTRACT(YEAR FROM hire_date) AS hire_year, COUNT(*) AS hires
    FROM v_hr_base
    GROUP BY EXTRACT(YEAR FROM hire_date)
)
SELECT hire_year,
       hires,
       hires - LAG(hires) OVER (ORDER BY hire_year)                    AS change_vs_prev_year,
       ROUND(100 * (hires - LAG(hires) OVER (ORDER BY hire_year))
             / LAG(hires) OVER (ORDER BY hire_year), 1)                AS yoy_pct,
       SUM(hires) OVER (ORDER BY hire_year)                            AS cumulative_hires
FROM hires
ORDER BY hire_year;

-- Q5. Employees paid 25%+ above their department average (CTE + window AVG)
WITH dept_avg AS (
    SELECT employee_name, department_name, position_name, salary,
           AVG(salary) OVER (PARTITION BY department_name) AS dept_avg_salary
    FROM v_hr_base
)
SELECT department_name, employee_name, position_name, salary,
       ROUND(dept_avg_salary, 0)                       AS dept_avg_salary,
       ROUND(100 * (salary / dept_avg_salary - 1), 1)  AS pct_above_avg
FROM dept_avg
WHERE salary > dept_avg_salary * 1.25
ORDER BY pct_above_avg DESC
FETCH FIRST 10 ROWS ONLY;

-- Q6. How long do people stay before leaving? Tenure at exit by department
--     (leavers only, contracts with valid dates; see the audit)
SELECT department_name,
       COUNT(*)                    AS leavers,
       ROUND(AVG(tenure_years), 1) AS avg_years_before_exit,
       MIN(tenure_years)           AS shortest,
       MAX(tenure_years)           AS longest
FROM v_hr_base
WHERE is_active = 0 AND valid_dates = 1
GROUP BY department_name
ORDER BY avg_years_before_exit;

-- Q7. Gender pay comparison by department (conditional aggregation)
SELECT department_name,
       ROUND(AVG(CASE WHEN gender = 'Female' THEN salary END), 0) AS avg_female,
       ROUND(AVG(CASE WHEN gender = 'Male'   THEN salary END), 0) AS avg_male,
       ROUND(100 * (AVG(CASE WHEN gender = 'Female' THEN salary END)
                  / AVG(CASE WHEN gender = 'Male'   THEN salary END) - 1), 1) AS female_vs_male_pct
FROM v_hr_base
GROUP BY department_name
ORDER BY department_name;

-- Q8. Age groups: headcount, average salary, average vacation days
--     (Oracle cannot GROUP BY a column alias, so the CASE goes into a CTE first)
WITH grouped AS (
    SELECT CASE WHEN age < 30 THEN 'Under 30'
                WHEN age < 40 THEN '30-39'
                WHEN age < 50 THEN '40-49'
                ELSE '50+' END AS age_group,
           age, salary, vacation_days
    FROM v_hr_base
)
SELECT age_group,
       COUNT(*)                     AS employees,
       ROUND(AVG(salary), 0)        AS avg_salary,
       ROUND(AVG(vacation_days), 1) AS avg_vacation_days
FROM grouped
GROUP BY age_group
ORDER BY MIN(age);

-- Q9. Salary quartiles inside each department (NTILE)
WITH q AS (
    SELECT department_name, salary,
           NTILE(4) OVER (PARTITION BY department_name ORDER BY salary) AS quartile
    FROM v_hr_base
)
SELECT department_name, quartile,
       COUNT(*) AS employees, MIN(salary) AS from_salary, MAX(salary) AS to_salary
FROM q
GROUP BY department_name, quartile
ORDER BY department_name, quartile;

-- Q10. Managers with the most direct reports (join back to employees)
SELECT m.employee_name AS manager, COUNT(*) AS direct_reports
FROM v_hr_base b
JOIN employee_list m ON m.employee_id = b.manager_id
GROUP BY m.employee_id, m.employee_name
ORDER BY direct_reports DESC, manager
FETCH FIRST 5 ROWS ONLY;
