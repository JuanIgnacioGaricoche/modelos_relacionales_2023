# -*- coding: utf-8 -*-
"""
Created on Sun Jul  2 17:34:04 2023

@author: garic
"""

#%% Librerias

import pymssql
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

import sys

#%% Conexion y consulta

server = '157.92.26.17'
user = 'Alumno'
password = 'mrcd2023'

conn = pymssql.connect(server=server, user=user, password=password, port = '1443')
cursor = conn.cursor()

cursor.execute("""
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

               """)
rows = cursor.fetchall()

product_categories_analysis = pd.DataFrame(rows, columns= ['BusinessType','EnglishProductCategoryName','total_distintos_productos_comprados','total_cantidad_lineas','total_cantidad_unidades','total_normalized_sales_amount','promo_distintos_productos_comprados','promo_cantidad_lineas','promo_cantidad_unidades','promo_normalized_sales_amount','proporcion_productos_en_promo','proporcion_lineas_con_promo','proporcion_unidades_con_promo','proporcion_ventas_con_promo','total_ventas_por_cliente','promo_ventas_por_cliente','total_ventas_por_producto','promo_ventas_por_producto','proporcion_total_venta_producto_en_cliente','proporcion_total_venta_cliente_en_producto','proporcion_promo_venta_producto_en_cliente','proporcion_promo_venta_cliente_en_producto'])

conn.close()


#%% Graficos

# Obtener los valores únicos de la columna 'BusinessType'
business_types = product_categories_analysis['BusinessType'].unique()

# Calcular el número de filas y columnas para los subplots
num_rows = 1
num_cols = len(business_types)

# Configuración de estilo de Seaborn (opcional)
sns.set(style="whitegrid")

# Crear la figura y los ejes de los subplots
fig, axes = plt.subplots(num_rows, num_cols, figsize=(12, 6))

# Iterar por cada elemento de 'BusinessType' y generar un gráfico de barras
for i, business_type in enumerate(business_types):
    # Filtrar los datos por el 'BusinessType' actual
    data = product_categories_analysis[product_categories_analysis['BusinessType'] == business_type]

    # Determinar los datos para cada par de barras
    grupos = data['EnglishProductCategoryName'].unique()
    valores1 = data.groupby('EnglishProductCategoryName')['proporcion_total_venta_producto_en_cliente'].mean()
    valores2 = data.groupby('EnglishProductCategoryName')['proporcion_promo_venta_producto_en_cliente'].mean()

    # Configurar las posiciones de las barras
    posiciones = range(len(grupos))
    ancho_barras = 0.35

    # Dibujar las barras en el subplot correspondiente
    ax = axes[i] if num_cols > 1 else axes
    barras1 = ax.bar(posiciones, valores1, width=ancho_barras, label='Ventas totales')
    barras2 = ax.bar([p + ancho_barras for p in posiciones], valores2, width=ancho_barras, label='Ventas promoción')

    # Configurar las etiquetas del eje x y el título
    ax.set_xticks([p + ancho_barras / 2 for p in posiciones])
    ax.set_xticklabels(grupos)
    # ax.set_xlabel('Grupos')
    ax.set_ylabel('Proporción sobre las ventas')
    ax.set_title(f'{business_type}')

    # Agregar una leyenda
    ax.legend()

# Ajustar los espacios entre los subplots
plt.tight_layout()

# Mostrar la visualización
plt.show()
