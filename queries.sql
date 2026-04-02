-- queries.sql

-- Q1 — Employee Directory with Departments
SELECT e.emp_id, e.first_name, e.last_name, d.dept_name, e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name ASC, e.salary DESC;

-- Q2 — Department Salary Analysis
SELECT d.dept_name, SUM(e.salary) AS total_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING SUM(e.salary) > 150000
ORDER BY total_salary DESC;

-- Q3 — Highest-Paid Employee per Department
WITH ranked AS (
    SELECT e.emp_id, e.first_name, e.last_name, e.salary, d.dept_name,
           ROW_NUMBER() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
)
SELECT emp_id, first_name, last_name, dept_name, salary
FROM ranked
WHERE rnk = 1;

-- Q4 — Project Staffing Overview
SELECT p.project_name,
       COUNT(a.emp_id) AS employee_count,
       COALESCE(SUM(a.hours_allocated),0) AS total_hours
FROM projects p
LEFT JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_name
ORDER BY p.project_name;

-- Q5 — Above-Average Departments
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS dept_avg_salary
    FROM employees
    GROUP BY dept_id
),
company_avg AS (
    SELECT AVG(salary) AS company_avg_salary
    FROM employees
)
SELECT d.dept_name, da.dept_avg_salary, ca.company_avg_salary
FROM dept_avg da
JOIN departments d ON da.dept_id = d.dept_id
CROSS JOIN company_avg ca
WHERE da.dept_avg_salary > ca.company_avg_salary;

-- Q6 — Running Salary Total
SELECT e.emp_id, e.first_name, e.last_name, e.salary,
       SUM(e.salary) OVER (PARTITION BY e.dept_id ORDER BY e.hire_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM employees e
ORDER BY e.dept_id, e.hire_date;

-- Q7 — Unassigned Employees
SELECT e.emp_id, e.first_name, e.last_name
FROM employees e
LEFT JOIN assignments a ON e.emp_id = a.emp_id
WHERE a.project_id IS NULL;

-- Q8 — Hiring Trends
WITH hires AS (
    SELECT EXTRACT(YEAR FROM hire_date) AS yr,
           EXTRACT(MONTH FROM hire_date) AS mon,
           COUNT(*) AS hires_count
    FROM employees
    GROUP BY yr, mon
)
SELECT yr, mon, hires_count
FROM hires
ORDER BY yr, mon;

-- Q9 — Schema Design: Employee Certifications

-- 9a — Create tables
CREATE TABLE certifications (
    certification_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    issuing_org VARCHAR(100),
    level VARCHAR(20)
);

CREATE TABLE employee_certifications (
    id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES employees(emp_id),
    certification_id INT REFERENCES certifications(certification_id),
    certification_date DATE NOT NULL
);

-- 9b — Insert sample certifications
INSERT INTO certifications (name, issuing_org, level) VALUES
('SQL Fundamentals','Levant Tech Academy','Beginner'),
('Project Management','PMI','Intermediate'),
('Python Programming','Coursera','Beginner');

-- 9c — Insert sample employee_certifications
INSERT INTO employee_certifications (emp_id, certification_id, certification_date) VALUES
(1, 1, '2024-01-15'),
(2, 2, '2024-02-20'),
(3, 1, '2024-03-05'),
(4, 3, '2024-01-30'),
(5, 2, '2024-02-25');

-- 9d — Query employees with certifications
SELECT e.first_name, e.last_name, c.name AS certification_name,
       c.issuing_org, ec.certification_date
FROM employees e
JOIN employee_certifications ec ON e.emp_id = ec.emp_id
JOIN certifications c ON ec.certification_id = c.certification_id
ORDER BY e.emp_id, c.certification_id;