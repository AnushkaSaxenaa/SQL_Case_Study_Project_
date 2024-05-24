                                                     
													 /*-----------------------
                                                        Case Study Questions
                                                      ----------------------*/
/*                                                      
Each of the following case study questions can be answered using a single SQL statement:

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) 
    they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
*/


-- 1. What is the total amount each customer spent at the restaurant?

       SELECT s.customer_id, sum(price) as total_amount 
       FROM sales s 
       JOIN menu m 
       ON s.product_id = m.product_id
       GROUP BY s.customer_id 
       ORDER BY total_amount DESC;


-- 2. How many days has each customer visited the restaurant?

      SELECT customer_id, count( distinct order_date) as Number_of_times_visited
      FROM sales
      GROUP BY customer_id
      ORDER BY Number_of_times_visited; 

-- 3. What was the first item from the menu purchased by each customer?

WITH cte_item AS(
	    SELECT s.customer_id, me.product_name,
		ROW_NUMBER() OVER( PARTITION BY s.customer_id ORDER BY s.order_date , me.product_id) as item_order 
		FROM sales s 
		JOIN menu me
		ON s.product_id = me.product_id)
SELECT * FROM cte_item 
WHERE item_order = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

      SELECT me.product_name, count(s.product_id) as order_count
      FROM sales s
      INNER JOIN menu me
      ON s.product_id = me.product_id
      GROUP BY product_name 
      ORDER BY order_count DESC
      LIMIT 1;


-- 5. Which item was the most popular for each customer?

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


-- 6. Which item was purchased first by the customer after they became a member?

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


-- 7. Which item was purchased just before the customer became a member?


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

-- 8. What is the total items and amount spent for each member before they became a member?


        SELECT s.customer_id,  count(s.product_id) as total_item , concat('Rs.','',sum(price)) as amount_spent
        FROM sales s														  
        INNER JOIN menu me On s.product_id = me.product_id
        INNER JOIN members mem ON s.customer_id = mem.customer_id  
        WHERE order_date < join_date
        GROUP BY s.customer_id
        ORDER BY s.customer_id;



-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


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

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi - how many points do customer A and B have at the end of January?


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
  
                                                    --Bonus Questions--
--                                                  Join All The Things
/* The following questions are related creating basic data tables that Danny and his team can use to quickly derive 
insights without needing to join the underlying tables using SQL.*/
 
 -- Q.1 Recreate the table output using the available data:
 
SELECT s.customer_id, order_date, product_name,	price,
  CASE WHEN order_date < join_date THEN 'N'
	    WHEN order_date >= join_date THEN 'Y'
       ELSE 'N' END AS members
FROM sales s 
LEFT JOIN members mem ON s.customer_id = mem.customer_id
INNER JOIN menu me ON me.product_id = s.product_id
ORDER BY s.customer_id, order_date
;



--Q.2                                    Rank All The Things
/*  Danny also requires further information about the ranking of customer products,but he purposely does not need the ranking
   for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.*/

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










