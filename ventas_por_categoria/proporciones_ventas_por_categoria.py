# -*- coding: utf-8 -*-
"""
Created on Sun Jul  2 22:01:03 2023

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


# =============================================================================
cursor.execute("""
WITH normalized_sales AS
(
SELECT
 	frs.*,
 	(frs.SalesAmount * fcr.EndOfDayRate * 1.0) AS NormalizedSales
FROM AdventureWorksDW2019.dbo.FactResellerSales frs 
 	INNER JOIN AdventureWorksDW2019.dbo.FactCurrencyRate fcr 
		ON frs.OrderDateKey = fcr.DateKey 
		AND frs.CurrencyKey = fcr.CurrencyKey 
),
sales_by_day AS
(
SELECT
 	CAST(OrderDate AS DATE) AS OrderDate, SUM(NormalizedSales) AS Sales
FROM normalized_sales ns
GROUP BY CAST(OrderDate AS DATE)
)
SELECT
 	*,
 	ROUND(AVG(Sales) OVER(ORDER BY OrderDate ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS SalesMovingAverage
FROM sales_by_day;

                """)
rows = cursor.fetchall()
time_series = pd.DataFrame(rows, columns= ['OrderDate','Sales','SalesMovingAverage'])
# =============================================================================

# =============================================================================
# cursor.execute("""
# WITH normalized_sales AS
# (
# SELECT
# 	frs.*,
# 	(frs.SalesAmount * fcr.EndOfDayRate * 1.0) AS NormalizedSales,
# 	dpc.EnglishProductCategoryName
# FROM AdventureWorksDW2019.dbo.FactResellerSales frs 
# 	INNER JOIN AdventureWorksDW2019.dbo.FactCurrencyRate fcr 
# 		ON frs.OrderDateKey = fcr.DateKey 
# 		AND frs.CurrencyKey = fcr.CurrencyKey 
# 	INNER JOIN AdventureWorksDW2019.dbo.DimProduct dp ON frs.ProductKey = dp.ProductKey 
# 	INNER JOIN AdventureWorksDW2019.dbo.DimProductSubcategory dps ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey 
# 	INNER JOIN AdventureWorksDW2019.dbo.DimProductCategory dpc ON dps.ProductCategoryKey = dpc.ProductCategoryKey 
# ),
# sales_by_day AS
# (
# SELECT
# 	CAST(OrderDate AS DATE) AS OrderDate, SUM(NormalizedSales) AS Sales,
# 	EnglishProductCategoryName
# FROM normalized_sales ns
# GROUP BY CAST(OrderDate AS DATE), EnglishProductCategoryName 
# )
# SELECT
# 	*,
# 	ROUND(AVG(Sales) OVER(ORDER BY OrderDate ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS SalesMovingAverage
# FROM sales_by_day;
# 
#                 """)
# =============================================================================
#rows = cursor.fetchall()
#time_series = pd.DataFrame(rows, columns= ['OrderDate','Sales','EnglishProductCategoryName','SalesMovingAverage'])





conn.close()


#%% Graficos

datos = time_series

# Supongamos que tienes un DataFrame llamado 'datos' con las columnas 'fecha', 'ventas' y 'promedio_movil'

# Configuración de estilo de Seaborn (opcional)
sns.set(style="whitegrid")

# Crear la figura y los ejes
fig, ax = plt.subplots()

# Graficar la serie de tiempo de ventas
ax.plot(datos['OrderDate'], datos['Sales'], label='Ventas en millones de dólares')

# Graficar la serie de tiempo del promedio móvil
ax.plot(datos['OrderDate'], datos['SalesMovingAverage'], label='Tendencia en ventas')

# Configurar las etiquetas del eje x y el título
ax.set_xlabel('Fecha')
ax.set_ylabel('Ventas en millones de dólares')
ax.set_title('Ventas y promedio móvil')

# Agregar una leyenda
ax.legend()

# Rotar las etiquetas del eje x para una mejor legibilidad
plt.xticks(rotation=45)

# Mostrar el gráfico
plt.show()

#%%

# Supongamos que tienes un DataFrame llamado 'datos' con las columnas 'fecha', 'ventas', 'promedio_movil' y 'EnglishProductCategoryName'

# Configuración de estilo de Seaborn (opcional)
sns.set(style="whitegrid")

# Crear la figura y los ejes
fig, ax = plt.subplots()

# Agrupar los datos por la columna 'EnglishProductCategoryName'
grupos = datos.groupby('EnglishProductCategoryName')

# Iterar por cada grupo y graficar la serie de tiempo correspondiente
for grupo, datos_grupo in grupos:
    ax.plot(datos_grupo['OrderDate'], datos_grupo['Sales'], label=grupo)

# Configurar las etiquetas del eje x y el título
ax.set_xlabel('Fecha')
ax.set_ylabel('Ventas en millones de dólares')
ax.set_title('Ventas por Categoría')

# Agregar una leyenda
ax.legend()

# Rotar las etiquetas del eje x para una mejor legibilidad
plt.xticks(rotation=45)

# Mostrar el gráfico
plt.show()
