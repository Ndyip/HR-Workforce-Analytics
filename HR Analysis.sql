--Inspecting the dataset
SELECT COUNT(*) As TotalEmployees
FROM HR;

SELECT TOP 10 *
FROM HR;

SELECT
id,
COUNT(*) AS DuplicateCount
FROM HR
GROUP BY id
HAVING COUNT(*) > 1;

--Removing leading and trailing spaces
UPDATE HR
SET first_name = TRIM(first_name);
UPDATE HR
SET last_name = TRIM(last_name);
UPDATE HR
SET department = TRIM(department);
UPDATE HR
SET gender = TRIM(gender);
UPDATE HR
SET race = TRIM(race);
UPDATE HR
SET jobtitle = TRIM(jobtitle);
UPDATE HR
SET location_city = TRIM(location_city);
UPDATE HR
SET location_state = TRIM(location_state);

--Fixing the date format to a uniform format
SELECT DISTINCT birthdate
FROM HR;
ALTER TABLE HR
ADD Birth_Date DATE;

UPDATE HR
SET Birth_Date =
COALESCE
(
TRY_CONVERT(date,birthdate,101),
TRY_CONVERT(date,birthdate,110),
TRY_CONVERT(date,birthdate,1)
);

SELECT
Birth_Date
FROM HR

--Converting the hire date and term date to the same date format
ALTER TABLE HR
ADD HireDate DATE;

UPDATE HR
SET HireDate =
COALESCE
(
TRY_CONVERT(date,hire_date,101),
TRY_CONVERT(date,hire_date,110),
TRY_CONVERT(date,hire_date,1)
);

SELECT hire_date, HireDate
FROM HR;

ALTER TABLE HR
ADD TerminationDate DATE;

UPDATE HR
SET TerminationDate =
TRY_CONVERT(date,LEFT(termdate,10));

SELECT
termdate,
TerminationDate
FROM HR;

--checking for missing values
SELECT *
FROM HR
WHERE
first_name IS NULL
OR last_name IS NULL
OR gender IS NULL
OR Birth_Date IS NULL
OR HireDate IS NULL;

--calculating employees age
ALTER TABLE HR
ADD Age INT;

UPDATE HR
SET Age =
DATEDIFF(YEAR,Birth_Date,GETDATE())
-
CASE
WHEN DATEADD(YEAR,DATEDIFF(YEAR,Birth_Date,GETDATE()),Birth_Date) > GETDATE()
THEN 1
ELSE 0
END;

SELECT
Age,
Birth_Date
FROM HR;

--calculating employees years at the company 
ALTER TABLE HR
ADD YearsAtCompany INT;

UPDATE HR
SET YearsAtCompany =
DATEDIFF
(
YEAR,
HireDate,
ISNULL(TerminationDate,GETDATE())
);

SELECT YearsAtCompany
FROM HR;

--setting employment status to active and terminated
ALTER TABLE HR
ADD EmploymentStatus VARCHAR(20);

UPDATE HR
SET EmploymentStatus =
CASE
    WHEN TerminationDate IS NULL THEN 'Active'
    WHEN TerminationDate > CAST(GETDATE() AS DATE) THEN 'Active'
    ELSE 'Terminated'
END;

SELECT EmploymentStatus, TerminationDate
FROM HR;

--creating age groups

ALTER TABLE HR
ADD AgeGroup VArchar(20);

UPDATE HR
SET AgeGroup = 
CASE
WHEN Age <30 THEN '20-29'
WHEN Age <40 THEN '30-39'
WHEN Age <50 THEN '40-49'
ELSE '50+'
END

SELECT COUNT(*) AS TotalEmployees
FROM HR;

--active vs terminated employees
SELECT COUNT(*) AS ActiveEmployees
FROM HR
WHERE EmploymentStatus='Active';

SELECT COUNT(*) AS TerminatedEmployees
FROM HR
WHERE EmploymentStatus='Terminated';

--employees by department
SELECT
department,
COUNT(*) AS Employees
FROM HR
GROUP BY department
ORDER BY Employees DESC;

--by gender
SELECT
gender,
COUNT(*) AS Total
FROM HR
GROUP BY gender;

--by race
SELECT
race,
COUNT(*) AS Employees
FROM HR
GROUP BY race
ORDER BY Employees DESC;

--by state
SELECT
location_state,
COUNT(*) AS Employees
FROM HR
GROUP BY location_state
ORDER BY Employees DESC;

--by job title 
SELECT
jobtitle,
COUNT(*) AS Employees
FROM HR
GROUP BY jobtitle
ORDER BY Employees DESC;


--hiring trend/ average age/ average tenure/turnover rate 
SELECT
YEAR(HireDate) AS HireYear,
COUNT(*) AS EmployeesHired
FROM HR
GROUP BY YEAR(HireDate)
ORDER BY HireYear;

SELECT
AVG(Age) AS AverageAge
FROM HR;

SELECT
AVG(YearsAtCompany) AS AvgTenure
FROM HR;

SELECT
ROUND(
100.0*
SUM(CASE WHEN EmploymentStatus='Terminated' THEN 1 ELSE 0 END)
/COUNT(*),2
)
AS TurnoverRate
FROM HR;

--Average tenure by department.
WITH DepartmentTenure AS
(
SELECT
department,
AVG(YearsAtCompany) AS AvgTenure
FROM HR
GROUP BY department
)

SELECT *
FROM DepartmentTenure
ORDER BY AvgTenure DESC;

--Ranking departments by employee count
SELECT
department,
COUNT(*) AS Employees,
RANK() OVER
(
ORDER BY COUNT(*) DESC
) AS DepartmentRank
FROM HR
GROUP BY department;


--Ranking longest-serving employees within each department.
SELECT
first_name,
last_name,
department,
YearsAtCompany,
ROW_NUMBER() OVER
(
PARTITION BY department
ORDER BY YearsAtCompany DESC
) AS SeniorityRank
FROM HR;


--Average tenure for each employee's department.
SELECT
first_name,
last_name,
department,
YearsAtCompany,
AVG(YearsAtCompany) OVER
(
PARTITION BY department
) AS DepartmentAverage
FROM HR;

--Final report
SELECT

    id AS EmployeeID,

    CONCAT(first_name,' ',last_name) AS EmployeeName,

    department,

    jobtitle,

    gender,

    Age,

    YearsAtCompany,

    EmploymentStatus,

    AVG(CAST(YearsAtCompany AS DECIMAL(10,2)))
    OVER(PARTITION BY department) AS AvgDepartmentTenure,

    COUNT(*)
    OVER(PARTITION BY department) AS DepartmentEmployees,

    ROW_NUMBER()
    OVER
    (
        PARTITION BY department
        ORDER BY YearsAtCompany DESC
    ) AS SeniorityRank,

    RANK()
    OVER
    (
        ORDER BY YearsAtCompany DESC
    ) AS CompanyWideTenureRank

FROM HR

ORDER BY
department,
SeniorityRank;