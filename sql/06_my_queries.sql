-- ============================================================
-- Queries I wrote myself while learning Oracle SQL (HR_ANALYTICS schema)
-- ============================================================

-- 1) Average salary by department
SELECT d.department_name,
       ROUND(AVG(c_a.salary), 2) AS avg_salary
FROM contract_appendix c_a
JOIN department d ON c_a.department_id = d.id
GROUP BY d.department_name
ORDER BY avg_salary DESC;

-- 2) Departments with at least 3 salaries above 100,000
SELECT d.department_name, COUNT(*) AS ct
FROM contract_appendix c_a
JOIN department d ON c_a.department_id = d.id
WHERE c_a.salary > 100000
GROUP BY d.department_name
HAVING COUNT(*) >= 3
ORDER BY ct DESC;

-- 3) Marketing employees with their salary (four-table join)
SELECT emp.employee_name, d.department_name, c_a.salary
FROM employee_list emp
JOIN contract c ON emp.employee_id = c.employee_id
JOIN contract_appendix c_a ON c.id = c_a.contract_id
JOIN department d ON c_a.department_id = d.id
WHERE d.department_name = 'Marketing';

-- 4) Employees who have left the company
SELECT emp.employee_name, c.hire_date, c.termination_date
FROM employee_list emp
JOIN contract c ON emp.employee_id = c.employee_id
WHERE c.termination_date IS NOT NULL;
