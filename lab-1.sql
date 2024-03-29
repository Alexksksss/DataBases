/* Лабораторная работа 1. Простые запросы на выборку данных.
   Литвак А. И. гр. 932020 */

--Ошибки были в номерах 8, 9, 13, 15. Исправила

---------------------------------------------------------------------------------------------
-- 1.	Список всех не пицц. Выборка должна содержать только наименование, цену и категорию товара.
---------------------------------------------------------------------------------------------

SELECT product_name, price, category
FROM pd_products
WHERE lower(category) <> 'пицца';

---------------------------------------------------------------------------------------------
-- 2.	Список всех улиц и районов, в которые делались заказы. В списке не должно быть дублей. Выборка должна содержать только улицу и район.
---------------------------------------------------------------------------------------------

SELECT DISTINCT street, area
FROM pd_customers;

---------------------------------------------------------------------------------------------
-- 3.	Список всех продукты, в описании которых упоминается “Моцарелла”. Выборка должна содержать только наименование и описание.
---------------------------------------------------------------------------------------------

SELECT product_name, description
FROM pd_products
WHERE description ILIKE '%Моцарелла%';

---------------------------------------------------------------------------------------------
-- 4.	Список всех пицц, где для каждой подписана характеристика, является ли пицца острой или вегетарианской. Характеристика должны быть подписана по-русски, должен учитываться вариант выставления обоих отметок. Выборка должна содержать только наименование, цену и характеристику.
---------------------------------------------------------------------------------------------

SELECT product_name, price,
CASE  WHEN is_vegan = True and is_hot = True THEN 'острая и вегетарианская'
	WHEN is_hot = True  and is_vegan = False THEN 'острая'
	WHEN is_vegan = True  and is_hot = False THEN 'вегетарианская'
	ELSE 'не острая и не вегетарианская' END as pizza_characrteristic
FROM pd_products
WHERE category = 'Пицца';

---------------------------------------------------------------------------------------------
-- 5.	Список всех сотрудников в формате: <Имя> должность “<название с маленькой буквы>”, работает с <месяц (имя месяца)> <год> года.
---------------------------------------------------------------------------------------------

SELECT
CONCAT(name, ' должность - ', LOWER(post), ', работает с ',
	   LOWER(to_char(pd_employees.start_date, 'TMMonth')),
	' месяца ', EXTRACT(YEAR from start_date), ' года') AS info
FROM pd_employees;


---------------------------------------------------------------------------------------------
-- 6.	Список адресов покупателей, которые не указали район. Выборка должна представлять список адресов в формате <название улицы>, дом <номер дома> кв. <номер квартиры>.
---------------------------------------------------------------------------------------------

SELECT
CONCAT(street, ', ', 'дом ', house_number,', кв. ', apartment) as address_without_area
FROM pd_customers
WHERE area IS NULL or area = ' ';

---------------------------------------------------------------------------------------------
-- 7.	Выбрать все продукты без описания в категориях десерт и напитки.  Выборка должна содержать только наименование, цену и  категорию.
---------------------------------------------------------------------------------------------

SELECT product_name, price, category
FROM pd_products
WHERE (LOWER(category) = 'десерты' or LOWER(category) = 'напитки')
	and description IS NULL or description =' ';

---------------------------------------------------------------------------------------------
-- 8.	Список всех острых или вегетарианских пицц с базиликом ценой от 500. Выборка должна содержать только наименование, описание, категорию и цену.
---------------------------------------------------------------------------------------------

--Ошибка: Сравнение с учётом регистра.+ (использовала lower)

SELECT product_name, description, category, price
FROM pd_products
WHERE LOWER(category) = 'пицца'
	and price >= 500
	and (is_hot = true or is_vegan = true)
	and LOWER(description) LIKE '%базилик%';

---------------------------------------------------------------------------------------------
-- 9.	Список всех острых пицц стоимостью от 460 до 510, если пицц  при этом ещё и вегетарианская, то стоимость может доходить до 560. Выборка должна содержать только наименование, цену и отметки об остроте и доступности для вегетарианцев.
---------------------------------------------------------------------------------------------

--Ошибка: Сравнение с учётом регистра.+ (использовала lower)

SELECT product_name, price, is_hot, is_vegan
FROM pd_products
WHERE LOWER(category) = 'пицца'
	and price >= 460
	and is_hot = true
	and (price<=510 or is_vegan=true and price<=560);

---------------------------------------------------------------------------------------------
-- 10.	Для каждого продукта рассчитать, на сколько процентов можно поднять цену,  так что бы первая цифра цены не поменялась (т.е. что бы все цены стали вида: x9, x99 и т.д). Выборка должна содержать только наименование, цену, новую цену, процент повышения цены (округлить до 3-х знаков после запятой), размер возможного повышения до копеек.
---------------------------------------------------------------------------------------------

SELECT product_name, price,
--CASE WHEN (price > 99) THEN floor(price / 100) else floor(price / 10) END AS first_digit,
		--находим первую цифру числа
CASE WHEN (price > 99) THEN (floor(price / 100) * 100 + 99) else (floor(price / 10) * 10 + 9) END AS NEW_PRICE,
		-- находим какой цена должна стать
CASE WHEN (price > 99) THEN ROUND(((floor(price / 100) * 100 + 99) - price), 2) else ROUND(((floor(price / 10) * 10 + 9) - price), 2) END AS MINUS,
		--находим разность для вычисления процента и размер возможного повышения (округляем до копеек - 2 знака после запятой)
--CASE WHEN (price > 99) THEN (((floor(price / 100) * 100 + 99) - price) / price * 100) else (((floor(price / 10) * 10 + 9) - price) / price * 100) END AS percent,
		-- находим процент
CASE WHEN (price > 99) THEN ROUND((((floor(price / 100) * 100 + 99) - price) / price * 100),3) else ROUND((((floor(price / 10) * 10 + 9) - price) / price * 100),3) END AS round_percent
		--округляем процент
FROM pd_products;

---------------------------------------------------------------------------------------------
-- 11.	Список возможных цен на все продукты, если увеличить цену для острых продуктов на 1,5% , для вегетарианских на 1%, для острых и вегетарианских на 2%. Выбрать продукты, для которых новая цена не будет превышать 520 для пицц, 190 для сэндвич-роллов 65 для остальных. Выборка должна содержать только наименование, описание, цену, новую цену (до 2-х знаков после запятой), размер увеличения цены цену (до 2-х знаков после запятой)  и отметки об остроте и доступности для вегетарианцев.
---------------------------------------------------------------------------------------------

SELECT
product_name, description, price,
ROUND(price * CASE
	WHEN is_hot = True AND is_vegan = True THEN 1.02
	WHEN is_hot = True AND is_vegan = False THEN 1.015
	WHEN is_vegan = True AND is_hot = False THEN 1.01
	ELSE 1 END, 2) AS new_price,
ROUND(price * CASE
	WHEN is_hot = True AND is_vegan = True THEN 0.02
	WHEN is_hot = True AND is_vegan = False THEN 0.015
	WHEN is_vegan = True AND is_hot = False THEN 0.01
	ELSE 0 END, 2) AS minus_price,
CASE  WHEN is_vegan = True AND is_hot = True THEN 'острая и вегетарианская'
	WHEN is_hot = True AND is_vegan = False THEN 'острая'
	WHEN is_vegan = True AND is_hot = False THEN 'вегетарианская'
	ELSE 'не острая и не вегетарианская' END as pizza_characrteristic
FROM pd_products
WHERE price * CASE
	WHEN is_hot = True AND is_vegan = True THEN 1.02
	WHEN is_hot = True AND is_vegan = False THEN 1.015
	WHEN is_vegan = True AND is_hot = False THEN 1.01
	ELSE 1
END <= CASE
	WHEN LOWER(category) = 'пицца' THEN 520
	WHEN LOWER(category) = 'сэндвич-ролл' THEN 190
	ELSE 65 END;

---------------------------------------------------------------------------------------------
-- 12.	Список всех курьеров, которые выполняли заказы 1-го и 2-го января. Выборка должна  содержать только Имя курьера и полный адрес заказа.
---------------------------------------------------------------------------------------------

SELECT pd_employees.name, pd_customers.area, pd_customers.street,
	pd_customers.house_number, pd_customers.apartment
FROM pd_orders
JOIN pd_employees on pd_orders.emp_id = pd_employees.id
JOIN pd_customers on pd_orders.cust_id = pd_customers.id
WHERE EXTRACT(MONTH from delivery_date) = 01
		and (EXTRACT(DAY from delivery_date) = 01 or (EXTRACT(DAY from delivery_date) = 02))
		and post = 'Курьер';
---------------------------------------------------------------------------------------------
-- 13.	Список всех заказчиков, заказывавших пиццу в октябрьском районе в сентябре или октябре. Выборка должна содержать только имена покупателей без дублирования.
---------------------------------------------------------------------------------------------

--Ошибка: Не полное условие. Прочитайте ещё раз задание.+ (проверка, что категория - пицца)

SELECT DISTINCT(pd_customers."name")
FROM pd_orders
JOIN pd_customers on pd_orders.cust_id = pd_customers.id
JOIN pd_order_details ON pd_orders.id = pd_order_details.order_id
JOIN pd_products ON pd_products.id = pd_order_details.product_id
WHERE (EXTRACT(MONTH from order_date) = 10 or EXTRACT(MONTH from order_date) = 09)
	AND LOWER(category) = 'пицца'
	AND LOWER(area) = 'октябрьский';

---------------------------------------------------------------------------------------------
-- 14.	Список всех сотрудников в формате: <Имя> должность “<название с маленькой буквы>”, работает с <месяц (имя месяца)> <год> года, непосредственный руководитель <Имя>.
---------------------------------------------------------------------------------------------

SELECT CONCAT(emp.name, ' - ', LOWER(emp.post), ', работает с ',
	   LOWER(to_char(emp.start_date, 'TMMonth')),
	' месяца ', EXTRACT(YEAR from emp.start_date), ' года, ',
	'непосредственный руководитель - ', CASE WHEN managers.name is NULL THEN 'НЕТ' ELSE managers.name END ) AS info
FROM pd_employees as emp
LEFT JOIN pd_employees as managers on emp.manager_id = managers.id ;

---------------------------------------------------------------------------------------------
-- 15.	Список всех адресов (без дублирования), которые были доставлены под руководством Барановой (или ей самой) зимой. В списке также должны отображаться: имя курьера, адрес, район (‘нет’ – если район не известен). Выборка должна быть отсортирована по именам курьеров.
---------------------------------------------------------------------------------------------

--Ошибка:  Логическая ошибка в условии (поставила скобки в or)

SELECT DISTINCT(CONCAT(custom.street,', дом ', custom.house_number,', кв. ', custom.apartment))as Address, empl.name,
	CASE WHEN custom.area is NULL or custom.area = ' ' THEN 'нет' else custom.area END as area
FROM pd_employees as empl
JOIN pd_employees as managers on empl.manager_id = managers.id
JOIN pd_orders as ord on empl.id = ord.emp_id
JOIN pd_customers as custom on custom.id = ord.cust_id
WHERE (empl.name ILIKE 'Баранова%' or managers.name ILIKE 'Баранова%')
	and EXTRACT(MONTH from ord.delivery_date) in (12, 1 ,2)
ORDER BY empl.name ASC;

---------------------------------------------------------------------------------------------
-- 16.	Список продуктов, которые заказывали вмести с острыми или вегетарианскими пиццами в этом месяце.
---------------------------------------------------------------------------------------------

SELECT DISTINCT(pd_products_first.product_name) -- нужно ли DISTINCT?
FROM pd_orders
JOIN pd_order_details as pd_order_details_first ON pd_orders.id = pd_order_details_first.order_id
JOIN pd_order_details as pd_order_details_sec ON pd_orders.id = pd_order_details_sec.order_id
JOIN pd_products as pd_products_first ON pd_order_details_first.product_id = pd_products_first.id
JOIN pd_products as pd_products_sec ON pd_order_details_sec.product_id = pd_products_sec.id
WHERE LOWER(pd_products_first.category) <> 'пицца'
	and LOWER(pd_products_sec.category) = 'пицца'
	and (pd_products_sec.is_hot or pd_products_sec.is_vegan)
	and EXTRACT(MONTH from pd_orders.order_date) = EXTRACT(MONTH from current_date);
