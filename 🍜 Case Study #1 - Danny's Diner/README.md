# 🍜Case Study #1 - Danny's Diner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Image description" width= 40% height=40%>

## 🏴‍☠️ Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

* sales
* menu
* members

## 🪄 Example Datasets
All datasets exist within the dannys_diner database schema - be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

### Table 1: sales
The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.

|customer_id|order_date|product_id|
|-----------|----------|----------|
|A          |2021-01-01|1         |
|A          |2021-01-01|2         |
|A          |2021-01-07|2         |
|A          |2021-01-10|3         |
|A          |2021-01-11|3         |
|A          |2021-01-11|3         |
|B          |2021-01-01|2         |
|B          |2021-01-02|2         |
|B          |2021-01-04|1         |
|B          |2021-01-11|1         |
|B          |2021-01-16|3         |
|B          |2021-02-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-07|3         |

 ### Table 2: menu
The menu table maps the product_id to the actual product_name and price of each menu item.

|product_id|product_name|price|
|----------|-----------|------|
|1         |sushi	   |10    |
|2	       |curry	   |15    |  
|3	       |ramen	   |12    |

### Table 3: members
The final members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.

|customer_id|join_date |
|-----------|----------|
|A	        |2021-01-07|
|B      	|2021-01-09|

### 🔆 Tools Used
 * PostgreSQL 


# 🤓 Case Study Questions and Solutions
Each of the following case study questions can be answered using a single SQL statement:

1. What is the total amount each customer spent at the restaurant?
```SQL
SELECT s.customer_id, sum(price) as total_amount 
       FROM sales s 
       JOIN menu m 
       ON s.product_id = m.product_id
       GROUP BY s.customer_id 
       ORDER BY total_amount DESC; 
 ```      

 |customer_id|total_amount|
 |-----------|------------|
 |A	       |76          |
 |B	       |74          |
 |C	       |36          |



2. How many days has each customer visited the restaurant?
```SQL
SELECT customer_id, count( distinct order_date) as Number_of_times_visited
      FROM sales
      GROUP BY customer_id
      ORDER BY Number_of_times_visited;
``` 

|customer_id|Number_of_times_visited|
|-----------|-----------------------|
|C	      |2                      |
|A	      |4                      |
|B	      |6                      |


3. What was the first item from the menu purchased by each customer? 
```SQL
WITH cte_item AS(
	    SELECT s.customer_id, me.product_name,
		ROW_NUMBER() OVER( PARTITION BY s.customer_id ORDER BY s.order_date , me.product_id) as item_order 
		FROM sales s 
		JOIN menu me
		ON s.product_id = me.product_id)
SELECT * FROM cte_item 
WHERE item_order = 1;
```
|customer_id|product_name|item_order|
|-----------|------------|----------|
|A          |sushi       |1         |
|B      	|curry       |1         | 
|C       	|ramen       |1         |



4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```SQL
SELECT me.product_name, count(s.product_id) as order_count
      FROM sales s
      INNER JOIN menu me
      ON s.product_id = me.product_id
      GROUP BY product_name 
      ORDER BY order_count DESC
      LIMIT 1;
```
|product_name|order_count|
|------------|-----------|
|ramen	 |8          |



5.  Which item was the most popular for each customer?
```SQL
WITH cte_order_count AS(
                        SELECT s.customer_id, me.product_name, count(*) AS order_count 
	                    from sales s
	                    JOIN menu me
	                    ON s.product_id = me.product_id
	                    GROUP BY customer_id, product_name
                   	    ORDER BY customer_id, order_count DESC),  
    cte_popular_item AS(
                        SELECT *, 
                        RANK() OVER( PARTITION BY customer_id ORDER BY order_count DESC) AS rank_of_item
                        from cte_order_count)
SELECT * FROM cte_popular_item
WHERE rank_of_item = 1;
```
|customer_id|product_name|order_count|rank_of_item|
|-----------|------------|-----------|------------|
|A	      |ramen	 |3	       |1           | 
|B	      |sushi	 |2        	 |1           |
|B	      |curry	 |2	       |1           |
|B	      |ramen	 |2	       |1           | 
|C	      |ramen	 |3	       |1           |          


6. Which item was purchased first by the customer after they became a member?
```SQL
WITH cte_food_item AS(
                      SELECT s.customer_id, product_name, s.product_id, mem.join_date, s.order_date,
                      DENSE_RANK() OVER ( PARTITION BY  s.customer_id ORDER BY order_date) AS item_rank
	                  FROM menu me
	                  INNER JOIN sales s On s.product_id = me.product_id
	                  INNER JOIN members mem ON s.customer_id = mem.customer_id
                      WHERE order_date >= join_date)
SELECT customer_id, product_name, order_date
from cte_food_item
where item_rank = 1;
```
|customer_id|product_name|order_date|
|-----------|------------|----------|
|A	      |curry	 |2021-01-07|   
|B	      |sushi	 |2021-01-11|


7. Which item was purchased just before the customer became a member?
```SQL
WITH cte_dinner AS(
                    SELECT s.customer_id, product_name, s.product_id, mem.join_date, s.order_date,
                	DENSE_RANK() OVER ( PARTITION BY  s.customer_id ORDER BY order_date DESC ) AS item_rank
                 	FROM menu me
                	INNER JOIN sales s On s.product_id = me.product_id
                	INNER JOIN members mem ON s.customer_id = mem.customer_id
                    WHERE order_date < join_date)
SELECT customer_id, product_name, order_date, join_date
from cte_dinner
where item_rank = 1 ;

```
|customer_id|product_name| order_date|join_date |
|-----------|------------|-----------|----------| 
|A	      |sushi	 |2021-01-01 |2021-01-07|
|A	      |curry	 |2021-01-01 |2021-01-07|
|B	      |sushi       |2021-01-04 |2021-01-09|


8. What is the total items and amount spent for each member before they became a member?
```SQL
  SELECT s.customer_id,  count(s.product_id) as total_item , concat('Rs.','',sum(price)) as amount_spent
        FROM sales s														  
        INNER JOIN menu me On s.product_id = me.product_id
        INNER JOIN members mem ON s.customer_id = mem.customer_id  
        WHERE order_date < join_date
        GROUP BY s.customer_id
        ORDER BY s.customer_id;
```

|customer_id|total_item|amount_spent|
|-----------|----------|------------|
|A     	|2	     |Rs.25       |
|B	      |3	     |Rs.40       |


9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```SQL
 SELECT s.customer_id,
         SUM(CASE 
		         WHEN product_name = 'sushi' THEN price*20
                 ELSE price*10
	     END) as Customer_points
  FROM sales s
  INNER JOIN menu me ON s.product_id = me.product_id
  INNER JOIN members mem ON s.customer_id = mem.customer_id
  WHERE order_date >= join_date
  GROUP BY s.customer_id 
  ORDER BY s.customer_id; 
  ```
|customer_id|customer_points|
|-----------|---------------|
|A       	|510            |
|B	      |440            |


10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```SQL
SELECT s.customer_id,
     SUM (CASE
		      WHEN product_name = 'sushi' THEN price * 20
		      WHEN order_date BETWEEN join_date AND join_date + 7 THEN price * 20
		      ELSE price * 10
		  END) AS points
FROM members mem
INNER JOIN sales s ON s.customer_id = mem.customer_id
INNER JOIN menu me ON me.product_id = s.product_id
WHERE order_date <= '2021-01-31'
GROUP BY s.customer_id;
```
|customer_id|points|
|-----------|------|
|A	      |1370  |      
|B     	|940   |
    


# 🌟 Bonus Questions
### 💫 Join All The Things
Q.1  The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

Recreate the following table output using the available data:

|customer_id|order_date |product_name|price |member|
|-----------|-----------|------------|------|------|
|A	      |2021-01-01	|curry     	 |15    |N     |
|A	      |2021-01-01	|sushi     	 |10    |N     |
|A	      |2021-01-07	|curry	 |15    |Y     | 
|A          |2021-01-10	|ramen    	 |12    |Y     |
|A        	|2021-01-11	|ramen	 |12	  |Y     | 
|A       	|2021-01-11	|ramen	 |12	  |Y     | 
|B      	|2021-01-01	|curry	 |15	  |N     |
|B      	|2021-01-02	|curry    	 |15	  |N     |
|B      	|2021-01-04	|sushi	 |10	  |N     |
|B          |2021-01-11	|sushi    	 |10	  |Y     | 
|B          |2021-01-16	|ramen	 |12	  |Y     | 
|B         	|2021-02-01	|ramen	 |12	  |Y     | 
|C         	|2021-01-01	|ramen	 |12	  |N     |
|C         	|2021-01-01	|ramen	 |12	  |N     |
|C         	|2021-01-07	|ramen	 |12	  |N     |

```SQL
SELECT s.customer_id, order_date, product_name,	price,
  CASE WHEN order_date < join_date THEN 'N'
	    WHEN order_date >= join_date THEN 'Y'
       ELSE 'N' END AS members
FROM sales s 
LEFT JOIN members mem ON s.customer_id = mem.customer_id
INNER JOIN menu me ON me.product_id = s.product_id
ORDER BY s.customer_id, order_date
;

```
Output will be same as the table given in the question.



### 💫 Rank All The Things
Q.2 Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

|customer_i|order_date	|product_name	|price	|member	|ranking|
|----------|------------|---------------|-------|-------|-------|
|A	       |2021-01-01	|curry	        |15     |N	    | null  |
|A	       |2021-01-01	|sushi	        |10	    |N	    | null  |
|A	       |2021-01-07	|curry       	|15	    |Y	    | 1     |
|A	       |2021-01-10	|ramen	        |12	    |Y	    | 2     |
|A	       |2021-01-11	|ramen         	|12	    |Y	    | 3     |
|A	       |2021-01-11	|ramen         	|12	    |Y	    | 3     |
|B	       |2021-01-01	|curry      	|15	    |N	    | null  |
|B          |2021-01-02	|curry         	|15	    |N	    | null  |
|B	       |2021-01-04	|sushi	        |10  	|N 	    | null  |
|B	       |2021-01-11	|sushi 	        |10	    |Y	    | 1     |
|B	       |2021-01-16	|ramen       	|12	    |Y	    | 2     |
|B	       |2021-02-01	|ramen	        |12	    |Y	    | 3     |
|C	       |2021-01-01	|ramen        	|12	    |N	    | null  |
|C	       |2021-01-01	|ramen	        |12	    |N	    | null  |
|C	       |2021-01-07	|ramen	        |12	    |N	    | null  |


```SQL
WITH cte_join as
      (SELECT s.customer_id, order_date, product_name,	price,
  CASE WHEN order_date < join_date THEN 'N'
	    WHEN order_date >= join_date THEN 'Y'
       ELSE 'N' END AS members
FROM sales s 
LEFT JOIN members mem ON s.customer_id = mem.customer_id
INNER JOIN menu me ON me.product_id = s.product_id
ORDER BY s.customer_id, order_date
)

Select *,
CASE 
   when members = 'N' THEN NULL
   ELSE RANK() OVER (PARTITION BY customer_id, members ORDER BY order_date)
   END AS ranking
 from cte_join;  
```
Output will be same as the table given in the question.





























