Create Database SaaS;
Use SaaS;


-- Verify
SELECT COUNT(*) FROM saas_subscriptions;
SELECT * FROM saas_subscriptions LIMIT 5;

-- What's the overall monthly churn rate?
select count(*) as Total_Customers,
Sum(Case When `Status` = "Churned" Then 1 Else 0 End) As Churn_Customer,
Round(Sum(Case When `Status` = "Churned" Then 1 Else 0 End) * 100/ Count(*), 2) As Churn_Rate_Pct
From saas_subscriptions;

-- Which subscription plan has the highest churn?
select Plan,
count(*) as Total_Customers,
Sum(Case When `Status` = "Churned" Then 1 Else 0 End) As Churn_Customer,
Round(Sum(Case When `Status` = "Churned" Then 1 Else 0 End) * 100/ Count(*), 2) As Churn_Rate_Pct,
Sum(MRR) as Avg_MRR       -- Monthly Recurring Revenue 
From saas_subscriptions
Group by Plan
Order by Churn_Rate_Pct Desc;

-- What's the average customer lifetime (in months) before cancellation?
select 
Plan,
`Status`,
Round(Avg(TenureMonths), 2) As Avg_Tenure_Month,
Round(Avg(LTV), 2) As Avg_LTV     -- Life Time Value Of Customer
From saas_subscriptions
Group by Plan,`Status`
Order by Plan, `Status`;


-- Is churn higher for customers who signed up via a discount/trial vs. full price?
select 
Case When IsDiscount = 1 Then 'Discount/Trial' Else 'Full Price' End As Customer_Type,
count(*) as Total_Customers,
Sum(Case When `Status` = 'Churned' Then 1 Else 0 End) As Churn,
Round(Sum(Case When `Status` = 'Churned' Then 1 Else 0 End) * 100/ Count(*), 2) As Churn_Rate_Pct,
Round(Avg(LTV), 2) As Avg_LTV
From saas_subscriptions
Group by IsDiscount;


-- What's the Monthly Recurring Revenue (MRR) trend over the last 12 months?
select count(*) as New_Customer,
Sum(MRR) as New_MRR,
Date_Format(SignupDate, '%y-%m') as SignUp_Month,
Sum(Sum(MRR)) Over (Order By Date_Format(SignupDate, '%y-%m') ) As Cummulative_MRR
From saas_subscriptions
Group by Date_Format(SignupDate, '%y-%m')
order by SignUp_Month;

-- Which customer segment (by plan or signup cohort) has the best retention?
select AcquisitionSource,
count(*) as Total_Customers,
Sum(Case When `Status` = 'Active' Then 1 Else 0 End) As Active_Customer,
Round(Sum(Case When `Status` = "Churned" Then 1 Else 0 End) * 100/ Count(*), 2) As Retention_Rate_Pct,
Round(Avg(LTV), 2) As Avg_LTV
From saas_subscriptions
Group by AcquisitionSource ;