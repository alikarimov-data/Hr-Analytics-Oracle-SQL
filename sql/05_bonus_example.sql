-- Bonus example: IT department, bonus rate depends on the salary band
SELECT employee_name,
       department_name,
       salary,
       CASE
           WHEN salary < 50000 THEN 0.10
           WHEN salary < 90000 THEN 0.07
           ELSE 0.05
       END AS bonus_rate,
       ROUND(salary * CASE
           WHEN salary < 50000 THEN 0.10
           WHEN salary < 90000 THEN 0.07
           ELSE 0.05
       END, 2) AS bonus
FROM v_hr_base
WHERE department_name = 'IT'
ORDER BY salary;
