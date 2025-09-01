USE AdventureWorksDW2022;

/*

	Resellers Sales Performance Matrix with Dynamic Period Comparisons (Using PIVOT/UNPIVOT and Window Functions):
	Create a dynamic report that shows the total sales amount for each product category, broken down by country and quarter for the year 2021. 
	The report should use PIVOT to have each quarter (Q1, Q2, Q3, Q4) as a separate column. 
	Additionally, include a column that shows the percentage change in sales from Q1 to Q4 for each country and product category. 

	- Tables: Sales, Reseller, Geo
	- Columns: 
		FactReseller(OrderDate, ResellerKey, SalesAmount) 
		Reseller (GeographyKey)
		Geo(EnsglishCountryRegionName) **
		Product(ProductSubcategory)
		Subcategory(ProductCategoryKey)
		Category (EnglishProductCategoryName) **

		** will be shown as they are, in the final result


*/


WITH 
cte1 AS(  -- Joining and casting dates into quarters.
	SELECT 
		g.EnglishCountryRegionName country,
		c.EnglishProductCategoryName category,
		DATEPART(q, rs.OrderDate) quarter_number,
		rs.SalesAmount sales
	FROM FactResellerSales rs
	JOIN dbo.DimReseller r
		ON r.ResellerKey = rs.ResellerKey
	JOIN dbo.DimGeography g
		ON r.GeographyKey = g.GeographyKey
	JOIN dbo.DimProduct p
		ON rs.ProductKey = p.ProductKey
	JOIN dbo.DimProductSubcategory sc
		ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
	JOIN dbo.DimProductCategory c
		ON sc.ProductCategoryKey = c.ProductCategoryKey
), 
cte2 AS(  -- Create matrix with sales per category per country.
	SELECT 
		country,
		category,
		[1] AS q1_sale, 
		[2] AS q2_sale, 
		[3] AS q3_sale, 
		[4] AS q4_sale
	FROM cte1 AS SourceTable
	PIVOT (
		SUM(sales) FOR quarter_number
		IN ([1], [2], [3], [4])
	) AS pivoted
)
SELECT 
	*,
	((cte2.q4_sale / cte2.q1_sale) - 1)*100 'growth (%)'  -- Adding column with growth rate.
FROM cte2
ORDER BY 
	cte2.country,
	cte2.category
;


