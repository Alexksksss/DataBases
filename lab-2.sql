/* Лабораторная работа 2. Запросы с группировкой и представления. (max 7)
   Литвак А. И. гр. 932020 */
ошибки:
--10. Сократите время выполнения запроса.???
--не понимаю, как в 10 номере сократить время выполнения запроса. Может быть Вы про 9 номер, его "вторую версию" добавила

16. У вас выбирается заказчик сделавший самый дорогой  заказа, а не самый дорогой заказа  заказчика.
--исправила

18. Задание не выполнено.

---------------------------------------------------------------------------------------------
/* 1. Найти среднюю стоимость пиццы с точность до второго знака. Выборка должна содержать только одно число. */
---------------------------------------------------------------------------------------------

SELECT ROUND(avg(price), 2) as avg_price
FROM pd_products
WHERE LOWER(pd_products.category) = 'пицца'
;

---------------------------------------------------------------------------------------------
/* 2. Найти количество отменённых и просроченных заказов. Все атрибуты должны иметь имя. */
---------------------------------------------------------------------------------------------

SELECT COUNT(CASE WHEN lower(order_state) = 'cancel' THEN 1 end) as cancelled,
       COUNT(CASE WHEN exec_date > delivery_date THEN 1 end) as overdue
FROM pd_orders
;

---------------------------------------------------------------------------------------------
/* 3. Найти среднюю стоимость для каждой категории товара с точность до второго знака.
	А так же на какой процент максимальная и минимальная стоимости отклоняются от средней стоимости.
	Выборка должна содержать наименование категории,
	среднюю стоимость и величины отклонения в процентах (округлить до второго знака). */
---------------------------------------------------------------------------------------------

SELECT ROUND(avg(price), 2) as avg_price, category,
	--MIN(price) as min_price, ROUND(MAX(price)) as max_price,
	ROUND(100 - MIN(price) / ROUND(avg(price), 2) * 100, 2) as round_min_price_percent,
	ROUND(MAX(price) / ROUND(avg(price), 2) * 100 - 100, 2) as round_max_price_percent
FROM pd_products
GROUP BY category
;

---------------------------------------------------------------------------------------------
/* 4. Для каждой из должностей найдите средний, максимальный и минимальный возраст сотрудников.
	Выборка должна название должности и средний, максимальный и минимальный возраст. */
---------------------------------------------------------------------------------------------

SELECT post,
	FLOOR(avg(EXTRACT(YEAR from current_date) - EXTRACT(YEAR from birthday))) as avg_age,
	FLOOR(MAX(EXTRACT(YEAR from current_date) - EXTRACT(YEAR from birthday))) as max_age,
	FLOOR(MIN(EXTRACT(YEAR from current_date) - EXTRACT(YEAR from birthday))) as min_age
FROM pd_employees
GROUP BY post
;

---------------------------------------------------------------------------------------------
/* 5. Для каждого заказа, сделанного зимой, посчитать сумму заказа.
	Выборка должна содержать номер заказа, сумму. */
---------------------------------------------------------------------------------------------

SELECT pd_orders.id,
	SUM(price * quantity) as sum
FROM pd_orders
INNER JOIN pd_order_details on pd_orders.id = pd_order_details.order_id
INNER JOIN pd_products on pd_order_details.product_id = pd_products.id
WHERE EXTRACT(MONTH from pd_orders.order_date) in (12, 1 ,2)
GROUP BY pd_orders.id
;

---------------------------------------------------------------------------------------------
/* 6. Для каждого месяца найдите общее количество заказанных напитков, десертов и пицц.
	Выборка должна содержать год и номер месяца (один атрибут), общее количество напитков,
	 общее количество десертов и общее количество пицц.
	Все атрибуты должны иметь имя. */
---------------------------------------------------------------------------------------------

SELECT
	CONCAT(date_part('month', o.order_date),'-', date_part('year', o.order_date)) as "date",
SUM(CASE WHEN lower(category) = 'пицца' THEN quantity end) as pizza,
SUM(CASE WHEN lower(category) = 'десерты' THEN quantity end) as dessert,
SUM(CASE WHEN lower(category) = 'напитки' THEN quantity end) as drink
FROM pd_order_details od
INNER JOIN pd_orders o on o.id = od.id
INNER JOIN pd_products pr on od.product_id = pr.id
GROUP BY "date"
;


---------------------------------------------------------------------------------------------
/* 7. Для каждого месяца найдите какой процент о общей выручки приходится на острые,
	 вегетарианские, острые и вегетарианские продукты. Без учёта каких-либо скидок. */
---------------------------------------------------------------------------------------------

SELECT
	CONCAT(date_part('month', o.order_date),'-', date_part('year', o.order_date)) as "date",
	SUM(CASE WHEN is_vegan = True and is_hot = True THEN price * quantity end) / SUM(price * quantity) * 100 as hot_vegan_percent,
	SUM(CASE WHEN is_vegan = True and is_hot = False THEN price * quantity end) / SUM(price * quantity) * 100 as only_vegan_percent,
	SUM(CASE WHEN is_vegan = False and is_hot = True THEN price * quantity end) / SUM(price * quantity) * 100 as only_hot_percent,
	SUM(CASE WHEN is_vegan = False and is_hot = False THEN price * quantity end) / SUM(price * quantity) * 100 as not_hot_not_vegan_percent
FROM pd_orders o
INNER JOIN pd_order_details od ON od.order_id = o.id
INNER JOIN pd_products pr ON od.product_id = pr.id
GROUP BY "date"
;

---------------------------------------------------------------------------------------------
/* 8. Выбрать осенние заказы, в которых общее количество заказанных продуктов не больше 5. */
---------------------------------------------------------------------------------------------

SELECT pd_orders.id, SUM(quantity)
FROM pd_orders
INNER JOIN pd_order_details on pd_order_details.order_id = pd_orders.id
WHERE EXTRACT(MONTH from order_date) in (9, 10, 11)
GROUP BY pd_orders.id
HAVING SUM(quantity) <= 5
;

---------------------------------------------------------------------------------------------
/* 9.Курьеров, которые чаще доставляли заказы в Кировский район, чем в Советский, за два последних месяца. */
---------------------------------------------------------------------------------------------

--исходная версия этого номера
SELECT pd_employees.name
FROM pd_employees
INNER JOIN pd_orders ON pd_orders.emp_id = pd_employees.id
INNER JOIN pd_customers ON pd_orders.cust_id = pd_customers.id
WHERE lower(post) = 'курьер'
		and((EXTRACT(MONTH from delivery_date) = EXTRACT(MONTH from current_date)
			  and EXTRACT(DAY from delivery_date) < EXTRACT(DAY from current_date))
			  -- октябрь до текущей даты
			or EXTRACT(MONTH from delivery_date) = (EXTRACT(MONTH from current_date) - 1)
			 -- сентябрь весь
			or (EXTRACT(MONTH from delivery_date) = (EXTRACT(MONTH from current_date) - 2)
				and EXTRACT(DAY from delivery_date) > EXTRACT(DAY from current_date) -- начиная с даты как сегодня
				--август начиная с даты, как сегодня
				)
			)
GROUP BY pd_employees.id
HAVING COUNT(CASE WHEN lower(area) = 'советский' THEN pd_employees.id END)
	<
	COUNT(CASE WHEN lower(area) = 'кировский' THEN pd_employees.id END)
;

--вторая версия этого номера
SELECT pd_employees.name
FROM pd_employees
INNER JOIN pd_orders ON pd_orders.emp_id = pd_employees.id
INNER JOIN pd_customers ON pd_orders.cust_id = pd_customers.id
WHERE lower(post) = 'курьер'
	and pd_orders.delivery_date > (current_timestamp - interval '2 month')
GROUP BY pd_employees.id
HAVING COUNT(CASE WHEN lower(area) = 'советский' THEN pd_employees.id END)
	<
	COUNT(CASE WHEN lower(area) = 'кировский' THEN pd_employees.id END)
;

---------------------------------------------------------------------------------------------
/* 10. Напишите запрос, выводящий следующие данные: номер заказа, имя курьера, имя заказчика (одной строкой),
 	общая стоимость заказа, строк доставки, отметка о том был ли заказа доставлен вовремя. */
---------------------------------------------------------------------------------------------

SELECT DISTINCT(pd_orders.id), pd_employees.name as emp_name, pd_customers.name as cust_name,
	SUM(price*quantity) OVER (partition by pd_orders.id) as total_cost,
	exec_date-order_date as deliv_time,
	CASE WHEN delivery_date > exec_date THEN True ELSE False end as is_intime
FROM pd_orders
INNER JOIN pd_order_details on pd_order_details.order_id = pd_orders.id
INNER JOIN pd_products on pd_products.id = pd_order_details.product_id
INNER JOIN pd_employees on pd_employees.id = pd_orders.emp_id
INNER JOIN pd_customers on pd_customers.id = pd_orders.cust_id
;

---------------------------------------------------------------------------------------------
/* 11. Для каждого заказа, в котором есть хотя бы 1 острая пицца посчитать стоимость напитков.*/
---------------------------------------------------------------------------------------------
with SumTable as
	(
	SELECT pd_orders.id, category, is_hot, price * quantity as sum
	FROM pd_orders
	INNER JOIN pd_order_details on pd_order_details.order_id = pd_orders.id
	INNER JOIN pd_products on pd_products.id = pd_order_details.product_id
	),
	HotPizzaTable as
	(
		SELECT DISTINCT id
		FROM SumTable
		WHERE lower(category) = 'пицца'
			and is_hot = True
	)
SELECT SumTable.id, sum(sum) as drink_cost
FROM SumTable
INNER JOIN HotPizzaTable on HotPizzaTable.id = SumTable.id
WHERE lower(category) = 'напитки'
GROUP BY SumTable.id
;

---------------------------------------------------------------------------------------------
/* 12. Найти курьера, выполнившего вовремя наибольшее число заказов (без использования limit). */
---------------------------------------------------------------------------------------------

with TempTable as
    (
        SELECT emp_id, count(emp_id) as CountOfOrders
        FROM pd_orders
        WHERE delivery_date >= exec_date
        GROUP BY emp_id
        )
SELECT name,CountOfOrders
FROM TempTable
INNER JOIN pd_employees on pd_employees.id = TempTable.emp_id
WHERE CountOfOrders = (select(max(CountOfOrders)) from TempTable) and lower(post) = 'курьер'
;

---------------------------------------------------------------------------------------------
/* 13. Определить район, в который чаще всего заказывали напитки (без использования limit). */
---------------------------------------------------------------------------------------------

with TableDrinks as
    (
        SELECT sum(quantity) as CountOfDrinks, cust_id
        FROM pd_order_details
        INNER JOIN pd_products on pd_products.id = pd_order_details.product_id
        INNER JOIN pd_orders on pd_orders.id =  pd_order_details.order_id
        WHERE lower(category) = 'напитки'
        group by cust_id
        ),
    ArreasMaxDrinks as
        (
            SELECT area, count(area) as countarr
            FROM TableDrinks
            INNER JOIN pd_customers on pd_customers.id = TableDrinks.cust_id
            WHERE area <> 'null'
            group by area
        )
SELECT area
FROM ArreasMaxDrinks
WHERE countarr = (select(max(countarr)) from ArreasMaxDrinks)
;

---------------------------------------------------------------------------------------------
/* 14. Определить район, в который чаще всего заказывали только напитки и десерты без пицц (без использования limit) */
---------------------------------------------------------------------------------------------

with Table_max_drinks_desserts as
    (
    SELECT o.id, cust_id
    FROM pd_orders o
    INNER JOIN pd_order_details od_1 on o.id = od_1.order_id
    INNER JOIN pd_order_details od_2 on o.id = od_2.order_id
    INNER JOIN pd_order_details od_3 on o.id = od_3.order_id

    INNER JOIN pd_products pr_1 on od_1.product_id = pr_1.id
    INNER JOIN pd_products pr_2 on od_2.product_id = pr_2.id
    INNER JOIN pd_products pr_3 on od_3.product_id = pr_3.id
    WHERE lower(pr_1.category) = 'напитки' and lower(pr_2.category) = 'десерты' and lower(pr_3.category) <> 'пицца'
    group by o.id),
    Table_for_area as
         (
         SELECT area, count(area) as number_of_orders
         FROM Table_max_drinks_desserts
         INNER JOIN pd_customers on Table_max_drinks_desserts.cust_id = pd_customers.id
         WHERE area <> 'null'
         group by area
         )
SELECT area
FROM Table_for_area
WHERE number_of_orders = (select(max(number_of_orders)) from Table_for_area)
;


---------------------------------------------------------------------------------------------
/* 15. Напишите запрос, выводящий следующие данные для каждого месяца:
	общее количество заказов, процент доставленных заказов, процент отменённых заказов, общий доход за месяц
	(заказы в доставке и отменённые не учитываются, на задержанные заказы предоставляется скидка в размере 15%),
	процент заказов оплаченных наличными.*/
---------------------------------------------------------------------------------------------

--какой столбец отвечает за наличную оплату?

with TabTemp as
         (SELECT DISTINCT order_id, date_part('month', order_date) as month,
                 sum(price * quantity) over (partition by pd_orders.id) *
                 CASE
                     when delivery_date < exec_date then 0.85
                     when lower(order_state) = 'cancel' or lower(order_state) = 'new' then 0
                     else 1 end as costs,
                 CASE when lower(order_state) = 'cancel' then 1 end as cancelled,
                 CASE when lower(order_state) = 'end' then 1 end as delivered
         FROM pd_order_details
         INNER JOIN pd_orders on pd_orders.id = pd_order_details.order_id
         INNER JOIN pd_products on pd_order_details.product_id = pd_products.id
    )
SELECT month, count(order_id) as all_count,
       (count(cancelled) * 100 / count(order_id)) as cancelled_perc,
       (count(delivered)  * 100 / count(order_id)) as delivered_perc,
       sum(costs) as total_sum
FROM TabTemp
group by month
ORDER BY month
;

---------------------------------------------------------------------------------------------
/* 16.Найти всех заказчиков, которые сделали заказ одного товара на сумму не менее 5000.
	 Отчёт должен содержать имя заказчика, номер самого дорогого заказа и стоимость. */
---------------------------------------------------------------------------------------------
--У вас выбирается заказчик сделавший самый дорогой  заказа, а не самый дорогой заказа  заказчика.
--исправила
WITH TempTable as
    (
	    SELECT  RANK() OVER(PARTITION BY cust.name ORDER BY SUM(price * quantity)DESC) as rank,
	        cust.name, o.id, SUM(price * quantity) as cost
	    FROM pd_orders o
	    INNER JOIN pd_customers cust ON cust.id = o.cust_id
	    INNER JOIN pd_order_details od ON od.order_id = o.id
	    INNER JOIN pd_products pr ON pr.id = od.product_id
	    GROUP BY cust.name, o.id
	    HAVING max(price * quantity) >= 5000
    )
SELECT DISTINCT TempTable.name, TempTable.id as max_cost_id, cost
FROM TempTable
WHERE rank = 1
;

---------------------------------------------------------------------------------------------
/* 17.Для каждого месяца найти стоимость самого дорогого заказа (без использования limit). */
---------------------------------------------------------------------------------------------

with sum_per_month as (
    SELECT date_part('month', order_date) as month, sum(price * quantity) as cost
    FROM pd_orders
    INNER JOIN pd_order_details on pd_order_details.order_id = pd_orders.id
    INNER JOIN pd_products on pd_products.id = pd_order_details.product_id
    group by pd_orders.id, month
    )
SELECT month, max(cost) as maximum
FROM sum_per_month
group by month
ORDER BY maximum
;

---------------------------------------------------------------------------------------------
/* 18. Для каждого месяца найдите руководителя, под чьим руководством был просрочено наименьшее число заказов. */
---------------------------------------------------------------------------------------------






---------------------------------------------------------------------------------------------
/* 19. Оформить запросы 15-18, как представления. */
---------------------------------------------------------------------------------------------

--19.15

create view TabTemp as
         (SELECT DISTINCT order_id, date_part('month', order_date) as month,
                 sum(price * quantity) over (partition by pd_orders.id) *
                 CASE
                     when delivery_date < exec_date then 0.85
                     when lower(order_state) = 'cancel' or lower(order_state) = 'new' then 0
                     else 1 end as costs,
                 CASE when lower(order_state) = 'cancel' then 1 end as cancelled,
                 CASE when lower(order_state) = 'end' then 1 end as delivered
         FROM pd_order_details
         INNER JOIN pd_orders on pd_orders.id = pd_order_details.order_id
         INNER JOIN pd_products on pd_order_details.product_id = pd_products.id
    );
SELECT month, count(order_id) as all_count,
       (count(cancelled) * 100 / count(order_id)) as cancelled_perc,
       (count(delivered)  * 100 / count(order_id)) as delivered_perc,
       sum(costs) as total_sum
FROM TabTemp
group by month
ORDER BY month
DROP VIEW TabTemp
;

--19.16

create view OneSum as
         (
            SELECT name, order_id, pr.id, price * (sum(quantity)) as sum_1_product
            FROM pd_order_details od
            INNER JOIN pd_orders o on o.id = od.order_id
            INNER JOIN pd_products pr on od.product_id = pr.id
            INNER JOIN pd_customers c on c.id = o.cust_id
            group by name, order_id, pr.id
        );
    create view AllSumTab as
        (
            SELECT name, order_id, sum(sum_1_product) as AllSum
            FROM OneSum
            group by name, order_id
            HAVING max(sum_1_product) > 5000
        );
SELECT name, order_id, AllSum
FROM AllSumTab
WHERE AllSum = (select(max(AllSum)) from AllSumTab)
DROP VIEW AllSumTab;
DROP VIEW OneSum
;

--19.17

create view sum_per_month as (
    SELECT date_part('month', order_date) as month, sum(price * quantity) as cost
    FROM pd_orders
    INNER JOIN pd_order_details on pd_order_details.order_id = pd_orders.id
    INNER JOIN pd_products on pd_products.id = pd_order_details.product_id
    group by pd_orders.id, month
    );
SELECT month, max(cost) as maximum
FROM sum_per_month
group by month
ORDER BY maximum
DROP VIEW sum_per_month
;
