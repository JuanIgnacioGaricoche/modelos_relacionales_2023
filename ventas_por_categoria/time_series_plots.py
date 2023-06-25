# -*- coding: utf-8 -*-
"""
Created on Thu Jun 22 23:13:44 2023

@author: garic
"""

import pymssql
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

import sys

server = '157.92.26.17'
user = 'Alumno'
password = 'mrcd2023'

conn = pymssql.connect(server=server, user=user, password=password, port = '1443')
cursor = conn.cursor()

cursor.execute("""
SELECT Name
FROM AdventureWorks2019.Production.ProductCategory pc 

               """)
rows = cursor.fetchall()
product_categories = pd.DataFrame(rows, columns= ['category'])

for category in product_categories['category']:
    cursor.execute("""
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
    WHERE CategoryName = '{}'
    -- WHERE Name = 'Mountain-100 Black, 42'
    GROUP BY OrderDateYearMonth
    )
    SELECT
    	*,
    	AVG(MonthYearTotal) OVER(ORDER BY OrderDateYearMonth ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS MonthYearTotalRollingAvg
    FROM monthly_sale_series
    ORDER BY OrderDateYearMonth
                   """.format(category))
    
    rows = cursor.fetchall()
    
    globals()[category.lower()] = pd.DataFrame(rows, columns=['OrderDateYearMonth', 'MonthYearTotal', 'MonthYearTotalRollingAvg'])

accessories = globals()['accessories']
bikes = globals()['bikes']
clothing = globals()['clothing']
components = globals()['components']

df_categories = [accessories, bikes, clothing, components]

for dataframe in df_categories:
    plt.xticks(rotation=90)
    sns.lineplot(data = dataframe, y = 'MonthYearTotalRollingAvg', x = 'OrderDateYearMonth')
    sns.lineplot(data = dataframe, y = 'MonthYearTotal', x = 'OrderDateYearMonth')

conn.close()