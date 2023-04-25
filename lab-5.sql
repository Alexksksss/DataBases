/*
функции: 	F<номер задания>_<Имя Функции>;	 пример: F1_OrdByMh.
процедуры:	P<номер задания>_<Имя Процедуры>.
исключения  EXC_<Имя Исключения>
триггеры: 	TR_<Сокрщённое имя таблицы>_<Имя тригера>;
*/




--1. Написать триггер, реализующий следующую логику.
-- Срок доставки должен быть больше текущего времени не менее чем на 30 минут
-- , если указано меньшее время, то срок доставки увеличивается до 30 минут.
-- Если время заказа не указано автоматически должно проставляться текущее время,
-- если срок доставки не указан, то он автоматически должен ставиться на час позже времени заказа.

create or replace function F1_time_of_orders ()
returns trigger as
    $$
    begin
    if new.order_date is null then
		new.order_date := current_date;--Если время заказа не указано автоматически должно проставляться текущее время
	end if;
	if new.delivery_date is null then
		new.delivery_date := new.order_date + interval '1' hour;
	end if;
	if new.delivery_date < current_date + interval '30' minute then
		new.delivery_date := new.order_date + interval '30' minute;
	end if;
   return new;
    end;
    $$ language plpgsql
;

create or replace trigger TR_ord_time_of_orders
before insert or update on pd_orders
for each row execute function F1_time_of_orders();

insert into pd_orders(id, emp_id, cust_id, paid_up,order_date, delivery_date, exec_date,order_state, order_comment)
values (10000, 33, 500388, true, null, null, null,'NEW',null);
--проверка: Если время заказа не указано автоматически должно проставляться текущее время, если срок доставки не указан, то он автоматически должен ставиться на час позже времени заказа.
insert into pd_orders(id, emp_id, cust_id, paid_up,order_date, delivery_date, exec_date,order_state, order_comment)
values (10001, 33, 500388, true, current_date, current_date + interval '1' minute,null, 'NEW',null);
--Проверка:Срок доставки должен быть больше текущего времени не менее чем на 30 минут, если указано меньшее время, то срок доставки увеличивается до 30 минут.

update pd_orders set delivery_date = order_date + interval '1' minute where id = 10001;
--Проверка:Срок доставки должен быть больше текущего времени не менее чем на 30 минут, если указано меньшее время, то срок доставки увеличивается до 30 минут в update

select *
from pd_orders
where id > 9999;

delete from pd_orders where id > 9999;

--2. Написать триггер, реализующий следующую логику.
-- Если выставляется отметка об оплате, то статус заказа меняется на доставлен (END) и в качестве времени исполнения заказа
-- указывается текущее время, при этом выставить отметку оплаты можно только для доставленных заказов.
-- Если выставляется дата исполнения заказа (EXEC_DATE) то статус заказа меняется на доставлен (END).
-- По итогу, поле “paid_up” может быть заполнено только если указаны дата исполнения заказа и статус - доставлен.
-- У доставленного заказа всегда должно быть указано время доставки.
-- Ограничить реакцию триггера только необходимыми полями.

--??

create or replace function F2_end_orders()
returns trigger as
    $$
    begin
    if new.paid_up = True then
		new.order_state := 'END';
		new.exec_date := current_date;
	end if;
	if new.exec_date is not null then
		new.order_state := 'END';
	end if;
    return new;
    end;
    $$ language plpgsql
;


--3.  Написать триггер, сохраняющий статистику изменений таблицы pd_products в таблице (таблицу создать),
-- в которой хранится сведения об изменении цены товаров, типе изменений (insert, update, delete), сведения о сотруднике,
-- вносившем изменения, дате изменения и количестве дней, прошедших с последнего изменения.


--не очень понятен смысл задания про количество дней, прошедших с последнего изменения.
--нужно сравнивать с последним изменением во всей таблице, для конкретного товара или конкретного пользователя
--в функции реализовала 1 вариант

create sequence prod_changes_seq_id increment 1 start 1;

create table pd_products_changes
(
	id  int default nextval('prod_changes_seq_id':: regclass),
	prod_id int,
	price_change numeric,
	type text,
	emp_name text,
	date_of_change date,
	last_change_days int,
	constraint pk_pd_products_changes primary key (id),
	constraint ch_pd_products_changes check (type is not null and prod_id is not null
	                                             and emp_name is not null
	                                             and date_of_change is not null)
);

alter sequence prod_changes_seq_id owned by pd_products_changes.id;

create or replace function F3_changes()
returns trigger as
    $$
    declare
        prod_id int;
        date_of_change_f date;
        last_change_days_f numeric;
    begin

    select date_of_change into date_of_change_f from pd_products_changes where id = (select max(id) from pd_products_changes);
    last_change_days_f := extract(day from current_date)-extract(day from date_of_change_f);

    if tg_op = 'UPDATE' then
        select new.id into prod_id from pd_products;
        insert into pd_products_changes(id, prod_id, price_change, type, emp_name, date_of_change, last_change_days)
        values(default, prod_id ,old.price - new.price, 'update', user,current_date, last_change_days_f);
        return new;
	elsif tg_op = 'INSERT' then
	    select new.id into prod_id from pd_products;
        insert into pd_products_changes(id, prod_id, price_change, type, emp_name, date_of_change,last_change_days)
        values(default, prod_id,new.price, 'insert', user,current_date,last_change_days_f);
        return new;
	elsif tg_op = 'DELETE' then
	    select old.id into prod_id from pd_products;
        insert into pd_products_changes(id, prod_id, price_change, type, emp_name, date_of_change, last_change_days)
        values(default, prod_id,old.price, 'delete',user,current_date, last_change_days_f);
        return old;
    end if;

    end;
    $$ language plpgsql
;

create or replace trigger TR_prod_changes
after insert or delete or update on pd_products
for each row execute function F3_changes();

insert into pd_products(id, product_name,price, is_hot, is_vegan, description, category_id)
values(10000, 'Молочный коктейль', 100, false, false, null, 5);

insert into pd_products(id, product_name,price, is_hot, is_vegan, description, category_id)
values(10001, 'Фреш', 105, false, false, null, 5);

update pd_products set price = 10*price where id = 10000;

delete from pd_products where id >=10000;

drop table pd_products_changes cascade;

drop function F3_changes() cascade;

SELECT NOW();
SET TIMEZONE='Asia/Bangkok';
SELECT NOW();

select *
from pd_products_changes;

--4. Написать триггер, реализующий следующую логику.
-- Если в таблицу pd_order_details в один и тот ж заказа добавляется уже имеющаяся позиция товара, должно происходит обновления уже имеющихся данных о количестве.

create or replace function F4_add_count()
returns trigger as
    $$
    declare
        func_order_id int;
        func_prod_id int;
        f_order_id_cur int;
        f_prod_id_cur int;
    begin
            select new.order_id into func_order_id from pd_order_details;
            select new.product_id into func_prod_id from pd_order_details;
            select order_id, product_id into f_order_id_cur, f_prod_id_cur
            from pd_order_details
                where new.order_id=order_id and product_id=new.product_id;
            if f_order_id_cur is not null and f_prod_id_cur is not null then
            update pd_order_details set quantity = quantity + new.quantity
            where order_id = func_order_id and product_id = func_prod_id;
            return old; --(новый не создаем)
        end if;
            return new;
    end;
    $$ language plpgsql
;

create or replace trigger TR_ord_det_add_count
before insert on pd_order_details
for each row execute function F4_add_count();

insert into pd_order_details(order_id, product_id,quantity)
values (10000, 29, 5);--обычное добавленеи

insert into pd_order_details(order_id, product_id,quantity)
values (10000, 29, 5);--проверка на добавление при выполнении условий

insert into pd_order_details(order_id, product_id,quantity)
values (10000, 29, 5);--проверка, если заказ тот же, но продукт другой


--6.   Добавить к таблице pd_orders не обязательное поле  “cipher”, которое должно заполниться автоматически согласно шаблону: <YYYYMMDD>- <номер район> - < номер заказа в рамках месяца>.
-- Номера не обязательно должны соответствовать дате заказа, если район не известен, то У номер района равен 0.
-- Номера районов брать из созданного во второй лабораторной справочника.
-- Учесть возможность изменения района доставки.

alter table pd_orders add cipher text;

create or replace function F6_cipher()
returns trigger as
    $$
    declare
        func_area_id int;
        num int;
        func_month int;
        cipher text;
    begin
        select pd_areas.id into func_area_id
        from pd_areas
        inner join pd_customers on pd_areas.id = pd_customers.area_id
        where pd_areas.id = new.area_id;

        select count(id) into num
        from pd_orders
        where extract(month from order_date) = new.
        group by extract(month from order_date)
        ;

        cipher:=to_char(:new.order_date, 'yyyymmdd') || '-' || func_area_id || '-' || num + 1;
        insert into pd_orders()
    end;
    $$ language plpgsql
;

create or replace trigger TR_ord_cipher
instead of insert on pd_order_details
for each row execute function F4_add_count();


select count(id) as num, extract(month from order_date)
        from pd_orders
        where extract(month from order_date) = 9
        group by extract(month from order_date);