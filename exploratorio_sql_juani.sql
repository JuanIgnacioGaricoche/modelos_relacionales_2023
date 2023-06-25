-- Hipotesis: Existen productos estacionales.

SELECT
	p.Name ,
	soh.SalesOrderID ,
	soh.OrderDate ,
	st.Name AS TerritoryName,
	st.CountryRegionCode ,
	sod.LineTotal 
FROM AdventureWorks2019.Sales.SalesOrderHeader soh 
	INNER JOIN AdventureWorks2019.Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID 
	INNER JOIN AdventureWorks2019.Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
	INNER JOIN AdventureWorks2019.Production.Product p ON sod.ProductID = p.ProductID ;
	
SELECT *
FROM AdventureWorks2019.Sales.SalesTerritory st 