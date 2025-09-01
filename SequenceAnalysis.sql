USE AdventureWorksDW2022;

/*

	Customer Behavioral Sequence Analysis (Using CTEs, Window Functions, and Conditional Logic):
	Identify customers who, in their first three purchase transactions, 
	bought products from a different product category each time. 
	Segment these customers into groups based on the specific sequence of their first three category purchases 
	(e.g., 'Bikes -> Components -> Clothing'). 
	The final result should show each unique purchasing sequence and the number of customers who followed that sequence. 

	- Tables: Category, Sub-category, product, Internet sales

	- Columns:
		Sales (productkey, customerkey, orderdatekey)
		product(subcategory key)
		subcategory(category key)
		category(name)

	- Flow: 
		Rank purchases per customer
		Join the necessary tables to get customer, order, and category
		Get first 3 purchases
		Create a matrix with the 3 purchases per customer
		Choose only those rows with distinct purchases
		edit so it looks like a text


*/

WITH 
cx_list AS(  -- Ranking cx�s purchases
	SELECT 
		fis.CustomerKey customer,
		c.EnglishProductCategoryName category,
		ROW_NUMBER() OVER(
			PARTITION BY fis.CustomerKey
			ORDER BY fis.SalesOrderNumber
		) AS order_rank
	FROM FactInternetSales fis
	JOIN DimProduct p
		ON fis.ProductKey = p.ProductKey
	JOIN DimProductSubcategory sc
		ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
	JOIN DimProductCategory c
		ON sc.ProductCategoryKey = c.ProductCategoryKey
)
,filtered_table AS( -- getting first 3 purchases per cx
	SELECT 
		*
	FROM cx_list
	WHERE order_rank <= 3
)
,sequence_CTE AS( -- Creating the matrix of categories per customer
	SELECT 
		customer,
		[1] AS first_purchase,
		[2] AS second_purchase,
		[3] AS third_purchase
	FROM filtered_table AS SourceTable
	PIVOT(
		MAX(category) FOR order_rank
		IN ([1],[2],[3])
	) AS pivotedTable
)
SELECT 
	first_purchase + '->' + second_purchase + '->' + third_purchase PurchaseSequence,  -- Formating for a cleaner presentation
	COUNT(customer) cx_count
FROM sequence_CTE
WHERE              -- Showing just distinct combinations
	first_purchase != second_purchase 
	AND second_purchase != third_purchase 
	AND first_purchase != third_purchase  
GROUP BY 
	first_purchase,
	second_purchase,
	third_purchase
ORDER BY cx_count DESC
;

