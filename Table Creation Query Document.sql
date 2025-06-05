-- Step 1: Create base tables
DROP TABLE IF EXISTS learner_raw, learneropportunity_raw, opportunity_raw, cohort, cognito, master_table CASCADE;

CREATE TABLE learner_raw (
    learner_id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT,
    cohort_id TEXT,
    cognito_id TEXT
);
SELECT * FROM learner_raw;

CREATE TABLE learneropportunity_raw (
    learner_id TEXT,
    enrollment_id TEXT,
    PRIMARY KEY (learner_id, enrollment_id),
	assigned_cohort TEXT,
	apply_date TEXT, 
	status TEXT
);
SELECT * FROM learneropportunity_raw;

CREATE TABLE opportunity_raw (
    opportunity_id TEXT ,
    stage TEXT,
    status TEXT
);
SELECT * FROM opportunity_raw;

CREATE TABLE cohort (
    cohort_id TEXT PRIMARY KEY,
    cohort_name TEXT
);
SELECT * FROM cohort;

CREATE TABLE cognito (
    cognito_id TEXT PRIMARY KEY,
    login_status TEXT
);
SELECT * FROM cognito;


-- Step 3: Create master table
CREATE TABLE master_table (
    learner_id TEXT,
    name TEXT,
    email TEXT,
    opportunity_id TEXT,
    stage TEXT,
    status TEXT,
    cohort_id TEXT,
    cohort_name TEXT,
    cognito_id TEXT,
    login_status TEXT,
    PRIMARY KEY (learner_id, opportunity_id),
    FOREIGN KEY (cohort_id) REFERENCES cohort(cohort_id),
    FOREIGN KEY (cognito_id) REFERENCES cognito(cognito_id)
);

-- Step 4: Data Cleaning (Transform stage)
-- Standardize email casing
UPDATE learner_raw SET email = LOWER(email);

-- Fill NULL login_status with 'Unknown'
UPDATE cognito SET login_status = 'Unknown' WHERE login_status IS NULL;

-- Capitalize stage
UPDATE opportunity_raw SET stage = INITCAP(stage);

-- Step 5: Load data into master table

INSERT INTO master_table (
    learner_id, name, email,
    opportunity_id, stage, status,
    cohort_id, cohort_name,
    cognito_id, login_status
)
SELECT DISTINCT ON (l.learner_id, opportunity_id)
    l.learner_id,
    l.name,
    l.email,
    opportunity_id,
    INITCAP(o.stage),
    o.status,
    c.cohort_id,
    c.cohort_name,
    cg.cognito_id,
    COALESCE(cg.login_status, 'Unknown')
FROM 
    learner_raw l
JOIN 
    learneropportunity_raw lo ON l.learner_id = lo.learner_id
JOIN 
    opportunity_raw o ON opportunity_id = o.opportunity_id
LEFT JOIN 
    cohort c ON l.cohort_id = c.cohort_id
LEFT JOIN 
    cognito cg ON l.cognito_id = cg.cognito_id;