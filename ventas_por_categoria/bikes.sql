-- Hipotesis: Existen productos estacionales.
WITH base_query AS
(
SELECT
	p.Name AS ProductName,
	pc.Name AS CategoryName,
	soh.SalesOrderID ,
	soh.OrderDate ,
	st.Name AS TerritoryName,
	st.CountryRegionCode ,
	sod.LineTotal,
	CONCAT(YEAR(soh.OrderDate), FORMAT(soh.OrderDate, 'MM')) AS OrderDateYearMonth
FROM AdventureWorks2019.Sales.SalesOrderHeader soh 
	INNER JOIN AdventureWorks2019.Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID 
	INNER JOIN AdventureWorks2019.Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
	INNER JOIN AdventureWorks2019.Production.Product p ON sod.ProductID = p.ProductID
	INNER JOIN AdventureWorks2019.Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID 
	INNER JOIN AdventureWorks2019.Production.ProductCategory pc ON ps.ProductCategoryID  = pc.ProductCategoryID 
),
monthly_sale_series AS
(
SELECT 
	OrderDateYearMonth, 
	ROUND(SUM(LineTotal), 2) AS MonthYearTotal
FROM base_query
WHERE CategoryName = 'Bikes'
-- WHERE Name = 'Mountain-100 Black, 42'
GROUP BY OrderDateYearMonth
)
SELECT
	*,
	AVG(MonthYearTotal) OVER(ORDER BY OrderDateYearMonth ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS MonthYearTotalRollingAvg
FROM monthly_sale_series
ORDER BY OrderDateYearMonth


SELECT *
FROM AdventureWorks2019.Production.ProductCategory pc 