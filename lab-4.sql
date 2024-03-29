/* Лабораторная работа 4. Процедуры и функции.
   Литвак А.И. гр. 932020
   База данных: csd.subent.932020.12
   Делала на домашнем компьютере
*/

--Ошибки:
1. Нет корректности проверки ввода месяца и года.
3. Нет корректности проверки ввода месяца и года.
4. Нет корректности проверки ввода месяца и года.
9. Задание не выполнено.

--проверки на выбросы исключений в задачах 1, 3 и 4 выбрала
---------------------------------------------------------------------------------------------
/* 1. Написать функцию, возвращающую число доставленных заказов по номеру сотрудника за месяц.
Заказы должны быть отмеченные как доставленные и оплаченные. Все аргументы функции должны принимать определенной значение. */
---------------------------------------------------------------------------------------------

create or replace function f1_count_orders (func_emp_id in int, month in int, year in int)
returns int as
    $$
    declare
        number_of_orders integer;
    begin
    if (year < 0 or year > extract(year from current_date) or month < 0 or month > 12) then raise exception 'Ошибка ввода значений месяца или года';
    else
    select count(*) into number_of_orders
    from pd_orders
    where func_emp_id = pd_orders.emp_id and
        month = extract(month from delivery_date) and year = extract(year from delivery_date) and
        lower(order_state) = 'end' and paid_up = True;
    return number_of_orders;
    end if;
    end;
    $$ language plpgsql ;

--запрос для проверки выброса исключений
select f1_count_orders(1,13,2022);

---------------------------------------------------------------------------------------------
/* 1а. Написать запрос для проверки полученных результатов:
Количество доставленных заказов  для каждого курьера в текущем месяце рассчитанное с использованием и без использования написанной функции.
Запрос должен содержать следующие атрибуты: номер месяца, фамилия курьера, количество доставленных заказов, рассчитанное при помощи функции,
количество доставленных заказов,  рассчитанное без использования функции, результат сравнения  полученных значений.*/
---------------------------------------------------------------------------------------------

select extract(month from current_date)-3 as month_sept , name,
       f1_count_orders(pd_employees.id, extract(month from current_date)::integer-3, extract(year from current_date)::integer),
       --у нас нет заказов за 12 месяц, поэтому написала запрос за 9, для проверки
        count(*) as not_func_count_orders,
        f1_count_orders(pd_employees.id, extract(month from current_date)::integer-3, extract(year from current_date)::integer)=count(*)  as is_equal
from pd_employees
inner join pd_posts on pd_posts.id = pd_employees.post_id
inner join pd_orders po on pd_employees.id = po.emp_id
where lower(pd_posts.post) = 'курьер' and
    pd_employees.id = po.emp_id and
    extract(month from current_date)-3 = extract(month from delivery_date) and extract(year from current_date) = extract(year from delivery_date) and
    lower(order_state) = 'end'
group by name, pd_employees.id
;

---------------------------------------------------------------------------------------------
/* 1б. Написать запрос с использованием написанной функции: Составить рейтинг  сотрудников по количеству доставленных заказов.
Для каждого осеннего месяца  вывести имена сотрудников занявших первые три места.
Если в течение месяца не было выполнено ни одного заказа, то итоги по этому месяцу не должны попасть в итоговую выборку.
Запрос должен содержать следующие атрибуты:  ФИО сотрудника, количество выполненных заказов,  место в рейтинге, номер месяца.
Сортировка по месяцу,  номеру в рейтинге потом по фамилии..*/
---------------------------------------------------------------------------------------------

with autumn as(
    select distinct name, (extract(month from delivery_date)::integer) as month, extract(year from current_date)::integer as year,
    f1_count_orders(pd_employees.id, extract(month from delivery_date)::integer,extract(year from current_date)::integer) as count
    from pd_orders
    inner join pd_employees on pd_orders.emp_id = pd_employees.id
    inner join pd_posts on pd_posts.id = post_id
    where extract(month from delivery_date)in (9,10,11)
    and lower(pd_posts.post) = 'курьер'
    group by name, pd_employees.id, delivery_date, month),
rank_emp as(
    select distinct name, count as count_of_orders,
    RANK() OVER(PARTITION BY month ORDER BY count desc) as pos, month
    from autumn
    group by name, month,count)
select *
from rank_emp
where pos in (1,2,3)
order by  month, pos, name
;

---------------------------------------------------------------------------------------------
/* 2. Написать функцию,  формирующую скидку по итогам последних N дней.
-- Количество  дней считается от введенной даты, если дата не указана то от текущей.
-- Условия: скидка 10% на самую часто заказываемую пиццу; скидка 5% на пиццу, которую заказывали на самую большую сумму.
-- Скидки суммируются.*/
---------------------------------------------------------------------------------------------

create or replace function f2_sales ( f_days int, s_date in text default current_date)
returns table (pizza_name text, sale real) as
    $$
    declare
        pizza text;
        max_order integer;
        max_cost integer;
        curs cursor
    for
        select product_name,
        RANK() OVER (ORDER BY count(*) desc) as max_order,
        RANK() OVER (ORDER BY price*sum(quantity) desc) as max_cost
        from pd_orders
        inner join pd_order_details on pd_order_details.order_id = pd_orders.id
        inner join pd_products on pd_products.id = pd_order_details.product_id
        inner join pd_categories on pd_categories.id = pd_products.category_id
        where lower(pd_categories.name) = 'пицца' and order_date > to_date(s_date, 'yyyy-mm-dd')- f_days
        group by pd_products.id, product_name;
    begin
    open curs;
    loop
        fetch curs into pizza, max_order, max_cost;
        exit when not found;
        sale := 0;
        if max_order = 1 then sale := sale + 0.1; end if;
        if max_cost = 1 then sale := sale + 0.05; end if;
        pizza_name = pizza;
        return next;
    end loop;
    close curs;
    exception when datetime_field_overflow then raise exception 'Вы ввели невервный формат даты. Правильный формат - ГГГГ-ММ-ДД';
    end;
$$language plpgsql
;

---------------------------------------------------------------------------------------------
/* 2а. Скидка на все пиццы по итогам последних 20 дней.*/
---------------------------------------------------------------------------------------------

select * from f2_sales(20);--за 20 дней нет заказов
select * from f2_sales (70);--взяла за 70 дней, чтобы проверить, что скидки суммируются
select * from f2_sales(70,'2022-01-01');
select * from f2_sales(70,'22-22-01');--проверки на исправность выбрсоа исключения

---------------------------------------------------------------------------------------------
/* 2б. Пицца с максимальной скидкой за каждый месяц 2022 года.*/
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
/* 3. Написать функцию, возвращающую число доставленных и оплаченных  заказов под руководством сотрудника по его номеру за месяц.
-- Все аргументы функции должны принимать определенное значение.*/
---------------------------------------------------------------------------------------------

create or replace function f3_count_orders_manager (em_id in int, month in int, year in int)
returns int as
    $$
    declare
        number_of_orders integer;
    begin
    if (year < 0 or year > extract(year from current_date) or month < 0 or month > 12) then raise exception 'Ошибка ввода значений месяца или года';
    else
    select count(*) into number_of_orders
    from pd_orders
    inner join pd_employees on pd_orders.emp_id = pd_employees.id
    where em_id = pd_employees.manager_id and
        month = extract(month from delivery_date) and year = extract(year from delivery_date) and
        paid_up = true and
        lower(order_state)= 'end'
    ;
    return number_of_orders;
    end if;
    end;
    $$ language plpgsql
;

--запрос для проверки выброса исключений
select f3_count_orders_manager(1,13,2022);

---------------------------------------------------------------------------------------------
/* 3а. Количество доставок для каждого курьера за предыдущий месяц,
 для руководителей групп в отдельном атрибуте указать количество доставок в их группах.*/
---------------------------------------------------------------------------------------------

select name,pd_employees.id,
        f1_count_orders(pd_employees.id, extract(month from current_date)::integer-3, extract(year from current_date)::integer) as count_orders,--функция из 1 задания
        f3_count_orders_manager(pd_employees.id, extract(month from current_date)::integer-3,extract(year from current_date)::integer) as count_orders_managers
--за 9 месяц для проверки
from pd_employees
inner join pd_posts on pd_posts.id = pd_employees.post_id
;

---------------------------------------------------------------------------------------------
/* 3б. Имя и должность самого результативного руководителя за каждый месяц 2022 года.*/
---------------------------------------------------------------------------------------------

with managers as (select distinct extract(month from delivery_date)::integer as month ,pd_employees.id,
        f3_count_orders_manager(pd_employees.id,extract(month from delivery_date)::integer, 2022) as func,
       RANK() OVER(PARTITION BY extract(month from delivery_date)
           ORDER BY f3_count_orders_manager(pd_employees.id,extract(month from delivery_date)::integer, 2022) desc) as best_manager
    from pd_employees
    inner join pd_orders po on pd_employees.id = po.emp_id
    inner join pd_posts pp on pd_employees.post_id = pp.id
    where extract(year from delivery_date) = 2022
    group by pd_employees.id, pp.post, extract(month from delivery_date), extract(year from delivery_date)
)
select month, managers.id, func as count_of_orders, name
from managers
inner join pd_employees on pd_employees.id = managers.id
where best_manager = 1
order by month
;

---------------------------------------------------------------------------------------------
/* 4.Написать функцию, возвращающую общее число заказов за месяц.
Все аргументы функции должны принимать определенной значение.*/
---------------------------------------------------------------------------------------------

create or replace function f4_count_orders_per_month (month in int,year in int)
returns int as
    $$
    declare
        number_of_orders integer;
    begin
    if (year < 0 or year > extract(year from current_date) or month < 0 or month > 12) then raise exception 'Ошибка ввода значений месяца или года';
    else
    select count(*) into number_of_orders
    from pd_orders
    where month = extract(month from order_date) and year = extract(year from order_date);
    return number_of_orders;
    end if;
    end;
    $$ language plpgsql
;

--запрос для проверки выброса исключений
select f4_count_orders_per_month(9,2023);

---------------------------------------------------------------------------------------------
/* Проверочный запрос*/
---------------------------------------------------------------------------------------------

select extract(month from order_date)::integer as month, count(*), f4_count_orders_per_month(extract(month from order_date)::integer, extract(year from order_date)::integer),
       count(*) = f4_count_orders_per_month(extract(month from order_date)::integer, extract(year from order_date)::integer) as is_equal
from pd_orders
group by extract(month from order_date), extract(year from order_date);

---------------------------------------------------------------------------------------------
/* 5.Написать функцию, выводящую насколько цена продукта больше чем средняя цена в категории.*/
---------------------------------------------------------------------------------------------

create or replace function f5_higher_than_amount (func_product_id in int)
returns int as
    $$
    declare
        price_difference integer;
    begin
        select (p1.price - avg(p2.price)) into price_difference--разница(может быть отрицательной)
        from pd_products p1
        inner join pd_products p2 on p1.category_id = p2.category_id
        where func_product_id = p1.id
        group by p1.price;
    return price_difference;
    end;
    $$ language plpgsql
;

---------------------------------------------------------------------------------------------
/* Проверочный запрос*/
---------------------------------------------------------------------------------------------

select id,product_name, f5_higher_than_amount(id), avg(price)
from pd_products
group by id;

---------------------------------------------------------------------------------------------
/* 6. Написать функцию, возвращающую максимальную общую стоимость заказа (не учитывать другие товары в заказе) для каждого товара за указанный месяц года.
-- Если месяц не указан, выводить стоимость максимальную стоимость за всё время.
--Параметры функции: месяц года (даты с точностью до месяца) и номер товара.*/
---------------------------------------------------------------------------------------------

create or replace function f6_max_cost(func_product_id in int, func_date in char default null)
returns int as
    $$
    declare
        date date;
	max_cost int;
    begin
        date := to_date(func_date, 'yyyy-mm');
        select pd_products.price * max(pd_order_details.quantity) into max_cost--максимумальная стоимость
        from pd_orders
        inner join pd_order_details on pd_orders.id = pd_order_details.order_id
        inner join pd_products on pd_order_details.product_id = pd_products.id
        where func_product_id = pd_order_details.product_id
        and (to_char(pd_orders.order_date,'yyyy-mm') = func_date or func_date is null)--если не указан
        group by pd_products.price;
    return max_cost;
    end;
    $$ language plpgsql
;

---------------------------------------------------------------------------------------------
/* Написать запрос использованием написанной функции:
Список товаров с наименованиями и стоимостями за всё время и за сентябрь 2022 года.*/
---------------------------------------------------------------------------------------------

select product_name, f6_max_cost(id, '2022-09') as max_cost_september,
       f6_max_cost(id) as full_max_cost
from pd_products;

---------------------------------------------------------------------------------------------
/* 7. Сформировать “открытку” с поздравлением всех изменников заранее заданного месяца:
“В <название месяца> мы поздравляем с днём рождения: <имя, имя > и <имя >”. Скобки вида “<>”  выводить не нужно. Написать проверочные запросы.*/
---------------------------------------------------------------------------------------------

create or replace function f7_congratulations (proc_month in numeric)
    returns text as
    $$
    declare
        str text;
        str_return text;
        month text;
        name_p text;
        first_name text;
        last_name text;
        curs7 cursor for
        select name
        from pd_employees
        where proc_month = extract(month from birthday);
begin
    month := lower(to_char(to_date(proc_month::text, 'mm'), 'TMMonth'));
    str := 'В месяце '||  month || ' мы поздравляем с днем рожджения: ';

    open curs7;
    fetch curs7 into first_name;
    if first_name is null then str_return:='Нет именинников в месяце '|| month; return str_return; end if;
    str := str || first_name;

    fetch curs7 into last_name;
    loop
        fetch curs7 into name_p;
        exit when not found;
        str := str || ', ' ||name_p;
    end loop;

    if last_name is not null then str := str  || ' и ' || last_name || '.';
    else str := str ||'.'; end if;


    close curs7;
    return str;
    end
    $$ language plpgsql;

---------------------------------------------------------------------------------------------
/* Проверочный запрос*/
---------------------------------------------------------------------------------------------

select f7_congratulations(1);
select f7_congratulations(2);
select f7_congratulations(3);
select f7_congratulations(4);
select f7_congratulations(5);
select f7_congratulations(6);
select f7_congratulations(7);
select f7_congratulations(8);
select f7_congratulations(9);
select f7_congratulations(10);
select f7_congratulations(11);
select f7_congratulations(12);

---------------------------------------------------------------------------------------------
/* 8. Написать процедуру, создающую новый заказа как копию существующего заказа,
-- чей номер – аргумент функции. Новый заказ должен иметь соответствующий статус.*/
---------------------------------------------------------------------------------------------

create or replace procedure p8_new_order (proc_order_id in int) as
    $$
    declare
        order_id int;
        new_order_id int;

    begin
    select count(*) into order_id
    from pd_orders
    where proc_order_id = pd_orders.id;

    select max(id) + 1 into new_order_id--обхожу ограничение уникальности
    from pd_orders;

    insert into pd_orders(id, emp_id, cust_id, paid_up, order_date, delivery_date, exec_date, order_state,order_comment)
    select new_order_id, emp_id, cust_id, paid_up, current_date, (delivery_date - pd_orders.order_date + current_date),null,'NEW', null
    from pd_orders
    where pd_orders.id = proc_order_id
    ;

    insert into pd_order_details( order_id, product_id, quantity)
    select  new_order_id, product_id, quantity
    from pd_order_details
    where pd_order_details.order_id = proc_order_id
    ;
    end;
    $$ language plpgsql
;

---------------------------------------------------------------------------------------------
/* Проверочный запрос*/
---------------------------------------------------------------------------------------------

call p8_new_order(6010);

select *
from pd_orders
inner join pd_order_details pod on pd_orders.id = pod.order_id
where pd_orders.id = 6010 or pd_orders.id = 6011
;



--Запросы на удаление
drop function if exists f1_count_orders(integer, integer, integer);
drop function if exists f2_sales(f_days int, s_date text);
drop function if exists f3_count_orders_manager(em_id int, month int, year int);
drop function if exists f4_count_orders_per_month(month int, year int);
drop function if exists f5_higher_than_amount(func_product_id int);
drop function if exists f6_max_cost(func_product_id int, func_date char);
drop function if exists f7_congratulations(proc_month numeric);
drop function if exists p8_new_order(proc_order_id int);