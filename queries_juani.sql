-- Series tiempo ventas
WITH normalized_sales AS
(
SELECT
	frs.*,
	(frs.SalesAmount * fcr.EndOfDayRate * 1.0) AS NormalizedSales,
	dpc.EnglishProductCategoryName
FROM AdventureWorksDW2019.dbo.FactResellerSales frs 
	INNER JOIN AdventureWorksDW2019.dbo.FactCurrencyRate fcr 
		ON frs.OrderDateKey = fcr.DateKey 
		AND frs.CurrencyKey = fcr.CurrencyKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc ON dps.ProductCategoryKey = dpc.ProductCategoryKey 
),
sales_by_day AS
(
SELECT
	CAST(OrderDate AS DATE) AS OrderDate, SUM(NormalizedSales) AS Sales,
	EnglishProductCategoryName
FROM normalized_sales ns
GROUP BY CAST(OrderDate AS DATE), EnglishProductCategoryName 
)
SELECT
	*,
	ROUND(AVG(Sales) OVER(ORDER BY OrderDate ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS SalesMovingAverage
FROM sales_by_day;

-- Costos categoria de productos
SELECT
	dpc.EnglishProductCategoryName ,
	AVG(frs.TotalProductCost) AS average_product_cost
FROM AdventureWorksDW2019.dbo.FactResellerSales frs 
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc ON dps.ProductCategoryKey = dpc.ProductCategoryKey 
GROUP BY dpc.EnglishProductCategoryName ;

-- Proporcion ventas por cliente y categoria de producto

WITH productos_por_reseller AS
(
SELECT
	dr.BusinessType,
	dpc.EnglishProductCategoryName,
	COUNT(DISTINCT frs.ProductKey ) AS total_distintos_productos_comprados,
	COUNT(*) AS total_cantidad_lineas,
	SUM(frs.OrderQuantity) AS total_cantidad_unidades,
	ROUND(SUM(frs.SalesAmount * fcr.EndOfDayRate * 1.0), 2) AS total_normalized_sales_amount
FROM AdventureWorksDW2019.dbo.FactResellerSales frs
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey = dp.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc on dps.ProductCategoryKey = dpc.ProductCategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimReseller dr ON frs.ResellerKey = dr.ResellerKey 
	INNER JOIN AdventureWorksDW2019.dbo.FactCurrencyRate fcr on frs.OrderDateKey = fcr.DateKey 
GROUP BY dr.BusinessType, dpc.EnglishProductCategoryName  
),
productos_por_reseller_promo AS
(
SELECT
	dr.BusinessType,
	dpc.EnglishProductCategoryName,
	COUNT(DISTINCT frs.ProductKey ) AS promo_distintos_productos_comprados,
	COUNT(*) AS promo_cantidad_lineas,
	SUM(frs.OrderQuantity) AS promo_cantidad_unidades,
	ROUND(SUM(frs.SalesAmount * fcr.EndOfDayRate * 1.0), 2) AS promo_normalized_sales_amount
FROM AdventureWorksDW2019.dbo.FactResellerSales frs
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey = dp.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc on dps.ProductCategoryKey = dpc.ProductCategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimReseller dr ON frs.ResellerKey = dr.ResellerKey 
	INNER JOIN AdventureWorksDW2019.dbo.FactCurrencyRate fcr on frs.OrderDateKey = fcr.DateKey 
WHERE frs.PromotionKey IN (2,3,4,5,6)
GROUP BY dr.BusinessType, dpc.EnglishProductCategoryName  
),
business_category AS
(
	SELECT BusinessType, EnglishProductCategoryName
	FROM
	(
	SELECT DISTINCT DR.BusinessType , 1 as join_column
	FROM AdventureWorksDW2019.dbo.DimReseller dr
	) a 
	INNER JOIN
	(
	SELECT DISTINCT dpc.EnglishProductCategoryName, 1 as join_column
	FROM AdventureWorksDW2019.dbo.DimProductCategory dpc 
	) b
	ON a.join_column = b.join_column
),
metrics AS
(
SELECT
	ppr.*,
	pprp.promo_distintos_productos_comprados,
	pprp.promo_cantidad_lineas,
	pprp.promo_cantidad_unidades,
	pprp.promo_normalized_sales_amount,
	(pprp.promo_distintos_productos_comprados*1.0/ ppr.total_distintos_productos_comprados*1.0) AS proporcion_productos_en_promo,
	(pprp.promo_cantidad_lineas*1.0 / ppr.total_cantidad_lineas*1.0) AS proporcion_lineas_con_promo,
	(pprp.promo_cantidad_unidades*1.0 / ppr.total_cantidad_unidades*1.0) AS proporcion_unidades_con_promo,
	(pprp.promo_normalized_sales_amount*1.0 / ppr.total_normalized_sales_amount*1.0) AS proporcion_ventas_con_promo,
	SUM(total_normalized_sales_amount) OVER(PARTITION BY ppr.BusinessType) AS total_ventas_por_cliente,
	SUM(promo_normalized_sales_amount) OVER(PARTITION BY ppr.BusinessType) AS promo_ventas_por_cliente,
	SUM(total_normalized_sales_amount) OVER(PARTITION BY ppr.EnglishProductCategoryName) AS total_ventas_por_producto,
	SUM(promo_normalized_sales_amount) OVER(PARTITION BY ppr.EnglishProductCategoryName) AS promo_ventas_por_producto
FROM business_category bc
	LEFT JOIN productos_por_reseller ppr ON bc.BusinessType = ppr.BusinessType
		AND bc.EnglishProductCategoryName = ppr.EnglishProductCategoryName
	LEFT JOIN productos_por_reseller_promo pprp ON bc.BusinessType = pprp.BusinessType
		AND bc.EnglishProductCategoryName = pprp.EnglishProductCategoryName
)
SELECT
	*,
	(total_normalized_sales_amount / total_ventas_por_cliente ) AS proporcion_total_venta_producto_en_cliente,
	(total_normalized_sales_amount / total_ventas_por_producto ) AS proporcion_total_venta_cliente_en_producto,
	(promo_normalized_sales_amount / promo_ventas_por_cliente ) AS proporcion_promo_venta_producto_en_cliente,
	(promo_normalized_sales_amount / promo_ventas_por_producto ) AS proporcion_promo_venta_cliente_en_producto	
FROM metrics
ORDER BY 1,2;

SELECT 
	COUNT(DISTINCT frs.ProductKey)
FROM AdventureWorksDW2019.dbo.FactResellerSales frs
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey = dp.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc on dps.ProductCategoryKey = dpc.ProductCategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimReseller dr ON frs.ResellerKey = dr.ResellerKey 
WHERE 1=1
	AND dr.BusinessType = 'Value Added Reseller'
	AND dpc.EnglishProductCategoryName = 'Clothing'
	AND frs.PromotionKey != 1;


---------------------------------
SELECT
	*
	-- dr.BusinessType, COUNT(DISTINCT ProductKey) OVER(PARTITION BY dr.BusinessType) AS cantidad_de_productos_por_reseller
FROM AdventureWorksDW2019.dbo.FactResellerSales frs 
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey = dp.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc on dps.ProductCategoryKey = dpc.ProductCategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimReseller dr ON frs.ResellerKey = dr.ResellerKey ;
	
SELECT *
FROM AdventureWorksDW2019.dbo.DimPromotion dp ;

SELECT
	frs.*, 
	ROUND(frs.SalesAmount * fcr.EndOfDayRate * 1.0, 2) AS normalized_sales_amount
FROM AdventureWorksDW2019.dbo.FactResellerSales frs
	INNER JOIN AdventureWorksDW2019.dbo.FactCurrencyRate fcr on frs.OrderDateKey = fcr.DateKey ;

SELECT *
FROM AdventureWorksDW2019.dbo.FactCurrencyRate fcr 
WHERE fcr.CurrencyKey  = 100;

SELECT *
FROM AdventureWorksDW2019.dbo.DimCurrency dc 
WHERE dc.CurrencyKey = 100;

SELECT *
FROM AdventureWorksDW2019.dbo.DimPromotion dp ;