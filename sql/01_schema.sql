-- ============================================================
-- HR Analytics (synthetic dataset) - Oracle schema
-- Connect as HR_ANALYTICS (service name XEPDB1), then run (F5).
-- Power BI calculated columns (Age, Gender, Tenure...) and the
-- personal-id-like column Fincode are NOT stored.
-- ============================================================

-- ---------- Lookup tables ----------
CREATE TABLE department (
    id              NUMBER(10)    PRIMARY KEY,
    department_name VARCHAR2(50)  NOT NULL,
    cancel          NUMBER(1)     NOT NULL
);

CREATE TABLE positions (
    id            NUMBER(10)    PRIMARY KEY,
    position_name VARCHAR2(80)  NOT NULL,
    cancel        NUMBER(1)     NOT NULL
);

CREATE TABLE disability (
    id                NUMBER(10) PRIMARY KEY,
    disability_degree NUMBER(10) NOT NULL,
    cancel            NUMBER(1)  NOT NULL
);

CREATE TABLE order_name_list (
    id         NUMBER(10)    PRIMARY KEY,
    order_name VARCHAR2(80)  NOT NULL,
    cancel     NUMBER(1)     NOT NULL
);

CREATE TABLE order_list (
    id         NUMBER(10) PRIMARY KEY,
    order_id   NUMBER(10) NOT NULL,
    start_date DATE       NOT NULL,
    end_date   DATE       NOT NULL,
    cancel     NUMBER(1)  NOT NULL,
    CONSTRAINT uq_order_id UNIQUE (order_id)
);

-- ---------- Core tables ----------
CREATE TABLE employee_list (
    employee_id   NUMBER(10)    PRIMARY KEY,
    employee_name VARCHAR2(120) NOT NULL,
    gender_id     NUMBER(1)     NOT NULL,   -- 1 = Female, 2 = Male (per the Power BI model)
    cancel        NUMBER(1)     NOT NULL,
    date_of_birth DATE          NOT NULL,
    disability_id NUMBER(10),               -- values 10/20/30, lookup has 1/2/3 (see audit)
    veteran       NUMBER(1)     NOT NULL,
    modify_date   DATE          NOT NULL
);

CREATE TABLE contract (
    id               NUMBER(10) PRIMARY KEY,
    employee_id      NUMBER(10) NOT NULL,
    hire_date        DATE       NOT NULL,
    termination_date DATE,
    modify_date      DATE       NOT NULL,
    cancel           NUMBER(1)  NOT NULL,
    CONSTRAINT fk_contract_employee FOREIGN KEY (employee_id) REFERENCES employee_list (employee_id)
);

CREATE TABLE contract_appendix (
    id            NUMBER(10)   PRIMARY KEY,
    contract_id   NUMBER(10)   NOT NULL,
    salary        NUMBER(12,2) NOT NULL,
    department_id NUMBER(10)   NOT NULL,
    position_id   NUMBER(10)   NOT NULL,
    manager_id    NUMBER(10)   NOT NULL,
    vacation_days NUMBER(5)    NOT NULL,
    order_id      NUMBER(10)   NOT NULL,
    CONSTRAINT fk_app_contract   FOREIGN KEY (contract_id)   REFERENCES contract (id),
    CONSTRAINT fk_app_department FOREIGN KEY (department_id) REFERENCES department (id),
    CONSTRAINT fk_app_position   FOREIGN KEY (position_id)   REFERENCES positions (id),
    CONSTRAINT fk_app_order      FOREIGN KEY (order_id)      REFERENCES order_list (order_id)
);

CREATE TABLE employee_attendance (
    id            NUMBER(10) PRIMARY KEY,
    employee_id   NUMBER(10) NOT NULL,
    entrance_time DATE       NOT NULL,      -- Oracle DATE includes the time part
    exit_time     DATE       NOT NULL,
    cancel        NUMBER(1)  NOT NULL,
    CONSTRAINT fk_att_employee FOREIGN KEY (employee_id) REFERENCES employee_list (employee_id)
);
