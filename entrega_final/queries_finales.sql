-- Queries para trabajo final modelo relacionales 2023

/*
1 - Tipos de cliente y comportamiento de compra
*/

WITH CTE AS (
    SELECT r.BusinessType, SalesOrderNumber,
    CONCAT(SalesOrderNumber, '-', SalesOrderLineNumber) AS LineId, 
    CASE WHEN PromotionKey IN(2,3,4,5,6) THEN 'VolProm' ELSE 'noVolProm' END volProm,
    OrderQuantity

    FROM AdventureWorksDW2019.dbo.FactResellerSales rs
    --inner porque solo nos interesan las ventas con un reseller asociado
    INNER JOIN AdventureWorksDW2019.dbo.DimReseller r
    ON rs.ResellerKey = r.ResellerKey
)

SELECT DISTINCT BusinessType, volProm,

--lines
COUNT(LineId) OVER(PARTITION BY BusinessType, volProm) 
AS BusinessPromNumLines,

COUNT(LineId) OVER(PARTITION BY BusinessType) 
AS BusinessNumLines,

COUNT(LineId) OVER(PARTITION BY BusinessType, volProm) * 1.0 / (COUNT(LineId) OVER(PARTITION BY BusinessType)) 
AS percBusinessPromLines,

COUNT(LineId) OVER(PARTITION BY BusinessType) * 1.0 / (COUNT(LineId) OVER())
AS percBusinessNumLines,

--------
--units
SUM(OrderQuantity) OVER(PARTITION BY BusinessType, VolProm) 
AS BusinessPromNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType) 
AS BusinessNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType, volProm)* 1.0 / (SUM(OrderQuantity) OVER(PARTITION BY BusinessType))
AS percBusinessPromNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType)* 1.0 / (SUM(OrderQuantity) OVER())
AS percBusinessNumUnits,

AVG(OrderQuantity * 1.0) OVER(PARTITION BY BusinessType, volProm) 
AS avgBusinessPromOrderQty,

AVG(OrderQuantity * 1.0) OVER(PARTITION BY BusinessType) 
AS avgBusinessOrderQty


FROM CTE
ORDER BY BusinessType, volProm;

/*
2 - Análsis por cliente y tipo de promocion
*/

WITH CTE AS (
    SELECT rs.ProductKey, pc.ProductCategoryKey, pc.EnglishProductCategoryName, ps.ProductSubcategoryKey, ps.EnglishProductSubcategoryName,
    r.BusinessType, SalesOrderNumber, PromotionKey,
    CONCAT(SalesOrderNumber, '-', SalesOrderLineNumber) AS LineId, OrderQuantity

    FROM AdventureWorksDW2019.dbo.FactResellerSales rs
    LEFT JOIN AdventureWorksDW2019.dbo.DimReseller r
    ON rs.ResellerKey = r.ResellerKey
    LEFT JOIN AdventureWorksDW2019.dbo.DimProduct dp
    ON rs.ProductKey = dp.ProductKey
    LEFT JOIN AdventureWorksDW2019.dbo.DimProductSubcategory ps
    ON dp.ProductSubcategoryKey = ps.ProductSubcategoryKey
    LEFT JOIN AdventureWorksDW2019.dbo.DimProductCategory pc 
    ON ps.ProductCategoryKey = pc.ProductCategoryKey
)

SELECT DISTINCT BusinessType, PromotionKey,

--lines
COUNT(LineId) OVER(PARTITION BY BusinessType, PromotionKey) 
AS BusinessPromKeyNumLines,

COUNT(LineId) OVER(PARTITION BY BusinessType) 
AS BusinessNumLines,

COUNT(LineId) OVER(PARTITION BY BusinessType, PromotionKey) * 1.0 /  (COUNT(LineId) OVER(PARTITION BY BusinessType))
AS percBusinessPromKeyLines,

COUNT(LineId) OVER(PARTITION BY BusinessType) * 1.0 /  (COUNT(LineId) OVER())
AS percBusinessNumLines,

-----

--units
SUM(OrderQuantity) OVER(PARTITION BY BusinessType, PromotionKey)
AS BusinessPromKeyNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType) 
AS BusinessNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType, PromotionKey)* 1.0 /  SUM(OrderQuantity) OVER(PARTITION BY BusinessType)
AS percBusinessPromKeyNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType) * 1.0 /  (SUM(OrderQuantity) OVER())
AS percBusinessNumUnits,

AVG(OrderQuantity*1.0) OVER(PARTITION BY BusinessType, PromotionKey) 
AS avgBusinessPromKeyOrderQty



FROM CTE
ORDER BY BusinessType, PromotionKey;

/*
3 - Chequeamos que todas las ventas tengan un reseller asociado
*/

SELECT r.BusinessType, SalesOrderNumber,
    CONCAT(SalesOrderNumber, '-', SalesOrderLineNumber) AS LineId, 
    CASE WHEN PromotionKey IN(2,3,4,5,6) THEN 'VolProm' ELSE 'noVolProm' END volProm,
    OrderQuantity

    FROM AdventureWorksDW2019.dbo.FactResellerSales rs
    LEFT JOIN AdventureWorksDW2019.dbo.DimReseller r
    ON rs.ResellerKey = r.ResellerKey
    WHERE r.ResellerKey IS NULL;
    
/*
4 - Caracterizamos a los descuentos por volumen
*/
   
WITH CTE AS(
SELECT DISTINCT rs.ProductKey, pc.ProductCategoryKey, pc.EnglishProductCategoryName, ps.ProductSubcategoryKey, ps.EnglishProductSubcategoryName,
CASE WHEN PromotionKey IN(2,3,4,5,6) THEN 'VolProm' ELSE 'noVolProm' END volProm

FROM AdventureWorksDW2019.dbo.FactResellerSales rs
LEFT JOIN AdventureWorksDW2019.dbo.DimProduct dp
ON rs.ProductKey = dp.ProductKey
LEFT JOIN AdventureWorksDW2019.dbo.DimProductSubcategory ps
ON dp.ProductSubcategoryKey = ps.ProductSubcategoryKey
LEFT JOIN AdventureWorksDW2019.dbo.DimProductCategory pc 
ON ps.ProductCategoryKey = pc.ProductCategoryKey

)

SELECT DISTINCT EnglishProductCategoryName, EnglishProductSubcategoryName, ProductKey, volProm,
-- acá tendría que ser un count distinct pero eso no se permite en las window functions, rehacer de otra manera
COUNT(ProductKey) OVER(PARTITION BY ProductSubcategoryKey, volProm)  AS prodQty,
FORMAT(COUNT(ProductKey) OVER(PARTITION BY ProductSubcategoryKey, volProm) * 1.0 / COUNT(ProductKey) OVER(PARTITION BY ProductSubcategoryKey),'P')  AS percProd

FROM CTE
ORDER BY ProductKey;


SELECT DISTINCT rs.ProductKey, pc.ProductCategoryKey, pc.EnglishProductCategoryName, ps.ProductSubcategoryKey, ps.EnglishProductSubcategoryName,PromotionKey
--CASE WHEN PromotionKey IN(2,3,4,5,6) THEN 'VolProm' ELSE 'noVolProm' END volProm

FROM AdventureWorksDW2019.dbo.FactResellerSales rs
LEFT JOIN AdventureWorksDW2019.dbo.DimProduct dp
ON rs.ProductKey = dp.ProductKey
LEFT JOIN AdventureWorksDW2019.dbo.DimProductSubcategory ps
ON dp.ProductSubcategoryKey = ps.ProductSubcategoryKey
LEFT JOIN AdventureWorksDW2019.dbo.DimProductCategory pc 
ON ps.ProductCategoryKey = pc.ProductCategoryKey

ORDER BY ProductKey;

/*
5 - Ejemplo de producto en promo
 */
SELECT DISTINCT rs.ProductKey, PromotionKey, DiscountAmount, OrderDate, OrderQuantity,
CASE WHEN PromotionKey IN(2,3,4,5,6) THEN 'VolProm' ELSE 'noVolProm' END volProm
FROM AdventureWorksDW2019.dbo.FactResellerSales rs
WHERE ProductKey = 213
ORDER BY OrderDate, ProductKey;

/*
6 - Caracterizamos la relación entre los distintos tipos de clientes 
y los descuentos por volumen
(qué tipos de productos compran, cuántas unidades compran en promedio y qué descuento es el que más utilizan).
*/

WITH CTE AS (
    SELECT rs.ProductKey, pc.ProductCategoryKey, pc.EnglishProductCategoryName, ps.ProductSubcategoryKey, ps.EnglishProductSubcategoryName,
    r.BusinessType, SalesOrderNumber,
    CONCAT(SalesOrderNumber, '-', SalesOrderLineNumber) AS LineId, 
    CASE WHEN PromotionKey IN(2,3,4,5,6) THEN 'VolProm' ELSE 'noVolProm' END volProm,
    OrderQuantity

    FROM AdventureWorksDW2019.dbo.FactResellerSales rs
    LEFT JOIN AdventureWorksDW2019.dbo.DimReseller r
    ON rs.ResellerKey = r.ResellerKey
    LEFT JOIN AdventureWorksDW2019.dbo.DimProduct dp
    ON rs.ProductKey = dp.ProductKey
    LEFT JOIN AdventureWorksDW2019.dbo.DimProductSubcategory ps
    ON dp.ProductSubcategoryKey = ps.ProductSubcategoryKey
    LEFT JOIN AdventureWorksDW2019.dbo.DimProductCategory pc 
    ON ps.ProductCategoryKey = pc.ProductCategoryKey
)

SELECT DISTINCT BusinessType, volProm, EnglishProductCategoryName,

--lines
COUNT(LineId) OVER(PARTITION BY BusinessType, volProm, ProductCategoryKey)
AS BusinessCatPromNumLines,

COUNT(LineId) OVER(PARTITION BY BusinessType, ProductCategoryKey)
AS BusinessCatLines,

COUNT(LineId) OVER(PARTITION BY BusinessType, volProm, ProductCategoryKey) * 1.0 /  (COUNT(LineId) OVER(PARTITION BY BusinessType, ProductCategoryKey))
AS percBusinessCatPromLines,

COUNT(LineId) OVER(PARTITION BY BusinessType, ProductCategoryKey) * 1.0 /  (COUNT(LineId) OVER(PARTITION BY BusinessType))
AS percBusinessCatLines,


--units
SUM(OrderQuantity) OVER(PARTITION BY BusinessType, volProm, ProductCategoryKey) 
AS BusinessCatPromNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType, ProductCategoryKey) 
AS BusinessCatNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType, volProm, ProductCategoryKey)* 1.0 /  SUM(OrderQuantity) OVER(PARTITION BY BusinessType, ProductCategoryKey)
AS percBusinessCatPromNumUnits,

SUM(OrderQuantity) OVER(PARTITION BY BusinessType, ProductCategoryKey) * 1.0 /  (SUM(OrderQuantity) OVER(PARTITION BY BusinessType))
AS percBusinessCatNumUnits,

AVG(OrderQuantity*1.0) OVER(PARTITION BY BusinessType, volProm, ProductCategoryKey) 
AS avgBusinessPromCatOrderQty



FROM CTE
ORDER BY BusinessType, EnglishProductCategoryName, volProm

/*
7 - Series de tiempo ventas  
*/

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

/*
8 - Costos categoria de productos
*/

SELECT
	dpc.EnglishProductCategoryName ,
	AVG(frs.TotalProductCost) AS average_product_cost
FROM AdventureWorksDW2019.dbo.FactResellerSales frs 
	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey 
	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc ON dps.ProductCategoryKey = dpc.ProductCategoryKey 
GROUP BY dpc.EnglishProductCategoryName ;

/*
9 - Proporcion ventas por cliente y categoria de producto
*/

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