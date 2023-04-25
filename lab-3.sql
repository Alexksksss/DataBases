/* Лабораторная работа 3. Создание/Модификация/Удаление таблиц и данных.
   Литвак А.И. гр. 932020
   База данных: csd.subent.932020.12*/
-- Делала на домашнем компьютере

---------------------------------------------------------------------------------------------
/* 1. Добавьте ограничения, гарантирующие исправление условий: */
---------------------------------------------------------------------------------------------

--     Поле pd_products.product_name не может принимать значение null.
alter table pd_products
add constraint ck_products_product
check (product_name is not null);

--     Поле pd_products.price не может принимать значение null.
alter table pd_products
add constraint ck_products_price
check (price is not null);

--     Поле pd_products.is_hot не может принимать значение null.
alter table pd_products
add constraint ck_products_is_hot
check (is_hot is not null);

--     Поле pd_products.is_vegan не может принимать значение null.
alter table pd_products
add constraint ck_products_is_vegan
check (is_vegan is not null);

--     Поле pd_employees.name не может принимать значение null.
alter table pd_employees
add constraint ck_employees_name
check (name is not null);

--     Поле pd_employees.start_date не может принимать значение null.
alter table pd_employees
add constraint ck_employees_start_date
check (start_date is not null);

--     Поле pd_customers.name не может принимать значение null.
alter table pd_customers
add constraint ck_customers_name
check (name is not null);

--     Поле pd_customers.street не может принимать значение null.
alter table pd_customers
add constraint ck_customers_street
check (street is not null);

--     Поле pd_customers.house_number не может принимать значение null.
alter table pd_customers
add constraint ck_customers_house_number
check (house_number is not null);

--     Поле pd_products.order_date не может принимать значение null.
--orders?
alter table pd_orders
add constraint ck_orders_order_date
check (order_date is not null);

--     Поле pd_products.delivery_date не может принимать значение null.
alter table pd_orders
add constraint ck_orders_delivery_date
check (delivery_date is not null);

--     Поле pd_products.order_state  может принимать только одно из трёх допустимых значений: “NEW”, “ EXEC”, “ END” , “ CANCEL”
alter table pd_orders
add constraint ck_orders_order_state
check (lower(order_state) = 'new' or lower(order_state) = 'exec' or lower(order_state) = 'end' or lower(order_state) = 'cancel');

--     Поле pd_products.cust_id не может принимать значение null.
--orders??
alter table pd_orders
add constraint ck_orders_cust_id
check (cust_id is not null);

--     pd_order_details.quantity не может принимать значение больше 100  и меньше 1.
alter table pd_order_details
add constraint ck_order_details_quantity
check (quantity between 0 and 100);

--     Поле pd_products. price не может принимать нулевое или отрицательное значение.
alter table pd_products
add constraint ck_products_price2
check (price is not null or price < 0);

--     Срок, к которому надо доставить заказ (pd_orders. delivery_date), не может превышать дату и время заказа (pd_orders. order_date),
--     заказ не может быть доставлен (pd_orders. exec_date) до того как его сделали (pd_orders.order_date);
-- delivery date же наоборот должен быть больше, чем order_date?
-- exec date должна быть больше, чем order date
alter table pd_orders
add constraint ck_orders_date
check (order_date <= delivery_date and order_date <= exec_date);


---------------------------------------------------------------------------------------------
/* 2. Добавьте значения по умолчанию:: */
---------------------------------------------------------------------------------------------

--     Поле pd_products. is_hot по умолчанию принимает значение false.
alter table pd_products
alter column is_hot set default false;

--     Поле pd_products.is_vegan по умолчанию принимает значение false.
alter table pd_products
alter column is_vegan set default false;

--     Для поля pd_products.order_date по умолчанию проставляется текучая дата.
alter table pd_orders
alter column order_date set default current_date;

--     Поле pd_products.order_state  по умолчанию принимает значение  “NEW”
alter table pd_orders
alter column order_state set default 'NEW';

--     Поле  pd_order_details.quantity по умолчанию принимает значение  1
alter table pd_order_details
alter column quantity set default 1;



---------------------------------------------------------------------------------------------
/* 3. Увеличить стоимость всех острых и не вегетарианских пицц  на 5%, новая цена не должна содержать копеек (копейки отбросить, а не округлить). */
---------------------------------------------------------------------------------------------
update pd_products
set price = trunc(price * 1.05)
where lower(category) = 'пицца' and is_hot and not is_vegan
;


---------------------------------------------------------------------------------------------
/* 4. Для всех заказов, для которых указано время исполнения заказа (pd_orders.exec_date) выставить статус заказа “доставлен” (“END”). Значения статусов, которые уже написаны корректно, не должны повторно обновляться. */
---------------------------------------------------------------------------------------------
update pd_orders
set order_state = 'END'
where exec_date is not null and lower(order_state) <> 'END'
;


---------------------------------------------------------------------------------------------
/* 3(5). В таблице pdt_phones привести все значения мобильных телефонов к одинаковому виду (шаблон: +7 xxx xxx xx xx), городские номера оставить без изменений. */
---------------------------------------------------------------------------------------------
update pdt_phones
set phone = replace(phone, ' ', ''); -- убираем все пробелы
update pdt_phones
set phone = replace(phone, ')', ''); -- убираем все )
update pdt_phones
set phone = replace(phone, '(', ''); -- убираем все (
update pdt_phones
set phone = replace(phone, '-', ''); -- убираем все дефисы
update pdt_phones
set phone = overlay (phone placing '+7' from 1 for 1 )
where phone not like '+7%'; -- заменяем все 8 и 7 на +7
update pdt_phones
set phone = SUBSTRING(phone, 1, 2) ||' '||  SUBSTRING(phone, 3, 3) ||' '|| SUBSTRING(phone, 6, 3) ||' '|| SUBSTRING(phone,9 ,2)||' '||  SUBSTRING(phone,11 ,2)
where phone like '+7%';--расставляем пробелы по шаблону



---------------------------------------------------------------------------------------------
/* 5(6). Добавить внешние ключи, согласно схеме БД описанной в PIZZADELIVERY.png. При этом каскадное удаление должно проходить только для позиций заказа, в остальных случаях должен происходить контроль возможности удаления. */
---------------------------------------------------------------------------------------------
alter table pd_order_details
add foreign key (product_id) references pd_products (id) on delete restrict;

alter table pd_order_details
add foreign key (order_id) references pd_orders (id) on delete cascade;

alter table pd_orders
add foreign key (emp_id) references pd_employees (id) on delete restrict;

alter table pd_orders
add foreign key (cust_id) references pd_customers (id) on delete restrict;


---------------------------------------------------------------------------------------------
/* 6(7). Добавить внешний ключ связывающий номер непосредственного начальника и реально существующего сотрудника (т.е. сотрудника, о котором есть сведения в БД). */
---------------------------------------------------------------------------------------------
alter table pd_employees
add foreign key (manager_id) references pd_employees (id);


---------------------------------------------------------------------------------------------
/* 7(8). Модифицировать схему базы данных так, что бы названия категорий хранились в отдельной таблице (имя: pd_categories, поля id, name),
и не осталось избыточных данных в таблице продуктов. Ограничения не должны допускать повторения названий категорий, добавления сведений о продукте без указания категории.
Ссылка на категорию в таблице продуктов - category_id */
---------------------------------------------------------------------------------------------

create table pd_categories --создаем
(
  id int,
  name varchar (100) unique,--не повторялись
  constraint pk_pd_categories
  primary key (id),
  constraint ck_pd_categories
  check (name is not null and id is not null)
);

insert into pd_categories (id, name) --вставляем id и имя
select id, cat as category
from
(
 select distinct(category) as cat, RANK() OVER(ORDER BY category) as id --row_number() over () as id
 from pd_products
) as temp;


alter table pd_products
add category_id int,
add constraint fk_pd_products_category
foreign key (category_id) references pd_categories (id)
;

update pd_products --обновляем столбец
set category_id =
  (
    select pd_products.category_id
    from pd_categories
    where pd_categories.name = pd_products.category
  );
alter table pd_products --удаляем столбец
drop column category;


---------------------------------------------------------------------------------------------
/* 8(9). Модифицировать схему базы данных так, что бы названия районов хранились в отдельной таблице (имя: pd_areas, поля id, area), и не осталось избыточных данных в таблице покупателей.
 Ограничения не должны допускать повторения названий районов, добавления сведений о покупателе, живущем в не внесённом в БД районе, при этом возможность не указывать район должна сохраниться.
 Поле для хранения ссылки на район в таблице pd_customers должно называться area_id. */
---------------------------------------------------------------------------------------------


--?при этом возможность не указывать район должна сохраниться?
-- Нужна ли ссылка в pd_areas, если район не указан. Если нужна, то удалить where area is not null в insert
create table pd_areas
(
	id int,
	area varchar unique,--не повторялись
    constraint pk_pd_areas
	primary key (id),
	constraint ck_pd_areas
	check (area is not null)--ограничение добавления сведений о покупателе, живущем в не внесённом в БД районе
);

insert into pd_areas (id, area)
select id, ar as area
from
(
	select distinct(area) as ar, RANK() OVER(ORDER BY area) as id
	from pd_customers
	where area is not null
) as temp;


alter table pd_customers
add	area_id int,
add constraint fk_pd_products_area
foreign key (area_id) references pd_areas (id)
;

update pd_customers
set area_id =
	(
		select pd_areas.id
		from pd_areas
		where pd_areas.area = pd_customers.area
	);

alter table pd_customers
drop column area;



---------------------------------------------------------------------------------------------
/* 9(10). Модифицировать схему базы данных так, что бы должности сотрудников хранились в отдельной таблице (имя: pd_posts, поля id, post, salary_amount) , и не осталось избыточных данных в таблице сотрудников.
Значения для поля pd_posts.salary_amount хранится во вспомогательной таблице pdt_salaries.
 Ограничения не должны допускать повторения названий должностей, добавления сведений о сотруднике без указания должности. Поле для хранения ссылки на должность  в таблице pd_employees должно называться post_id.*/
---------------------------------------------------------------------------------------------

create table pd_posts
(
	id int,
	post varchar unique,--не повторялись
	salary_amount numeric(10,2), -- так в pdt_salaries
    constraint pk_pd_posts
	primary key (id),
	constraint ck_pd_posts
	check (post is not null)--ограничение добавления сведений о сотруднике без указания должности
);

insert into pd_posts (id,post, salary_amount)
select e_id as id, pst as post, s_a as salary_amount
from
(
	select distinct(pd_employees.post) as pst, RANK() OVER(ORDER BY pd_employees.post) as e_id, salary_amount as s_a
	from pd_employees
	inner join pdt_salaries on lower(pd_employees.post) = lower(pdt_salaries.post)
	where pd_employees.post is not null
) as temp;

alter table pd_employees
add	post_id int,
add constraint fk_pd_employees_post_id
foreign key (post_id) references pd_posts (id)
;

update pd_employees
set post_id =
	(
		select pd_posts.id
		from pd_posts
		where pd_posts.post = pd_employees.post
	);

alter table pd_employees
drop column post;

---------------------------------------------------------------------------------------------
/* 10(11). В таблице pd_employees заменить поле salary на поле ставка (wage_rate), которое будет содержать информацию о том, какая часть от стандартного оклада (поле pd_posts. salary_amount) выплачивается сотруднику.
Рекомендация: первоначально написать запрос, который рассчитывает значение ставки для каждого сотрудника.*/
---------------------------------------------------------------------------------------------

-- первоначальный запрос
select name, pd_employees.post, salary_amount,salary, salary/pd_posts.salary_amount as wage_rate
from pd_employees
inner join pd_posts on pd_posts.id = pd_employees.post_id
;

--само задание
alter table pd_employees
add wage_rate real
;

update pd_employees
set wage_rate=
	(
	select salary/pd_posts.salary_amount as wage_rate
    from pd_posts
    where pd_posts.id = pd_employees.post_id
	);

alter table pd_employees
drop column salary;


---------------------------------------------------------------------------------------------
/* 11(12). Заменить простой первичный ключ (поле id) в таблице  pd_orders  на составной первичный ключ (поля product_id и order_id). Обратите внимание, что пара product_id и order_id изначально может быть не уникальной.*/
---------------------------------------------------------------------------------------------









---------------------------------------------------------------------------------------------
/* 12(13). Модифицировать схему базы данных таким образом, чтобы для всех таблиц при добавлении нового картежа значение поля “id” определялось автоматически.*/
---------------------------------------------------------------------------------------------

--pd_areas
create sequence pd_areas_seq_id;
select setval('pd_areas_seq_id', (select MAX(id) from pd_areas));
alter table pd_areas alter column id set default nextval('pd_areas_seq_id'::regclass);
alter sequence pd_areas_seq_id owned by pd_areas.id;

--pd_categories
create sequence pd_categories_seq_id;
select setval('pd_categories_seq_id', (select MAX(id) from pd_categories));
alter table pd_categories alter column id set default nextval('pd_categories_seq_id'::regclass);
alter sequence pd_categories_seq_id OWNED BY pd_categories.id;

--pd_customers
create sequence pd_customers_seq_id;
select setval('pd_customers_seq_id', (select MAX(id) from pd_customers));
alter table pd_customers alter column id set default nextval('pd_customers_seq_id'::regclass);
alter sequence pd_customers_seq_id OWNED BY pd_customers.id;

--pd_employees
create sequence pd_employees_seq_id;
select setval('pd_employees_seq_id', (select MAX(id) from pd_employees));
alter table pd_employees alter column id set default nextval('pd_employees_seq_id'::regclass);
alter sequence pd_employees_seq_id OWNED BY pd_employees.id;

--pd_order_details
create sequence pd_order_details_seq_id;
select setval('pd_order_details_seq_id', (select MAX(id) from pd_order_details));
alter table pd_order_details alter column id set default nextval('pd_order_details_seq_id'::regclass);
alter sequence pd_order_details_seq_id OWNED BY pd_order_details.id;

--pd_orders
create sequence pd_orders_seq_id;
select setval('pd_orders_seq_id', (select MAX(id) from pd_orders));
alter table pd_orders alter column id set default nextval('pd_orders_seq_id'::regclass);
alter sequence pd_orders_seq_id OWNED BY pd_orders.id;

--pd_posts
create sequence pd_posts_seq_id;
select setval('pd_posts_seq_id', (select MAX(id) from pd_posts));
alter table pd_posts alter column id set default nextval('pd_posts_seq_id'::regclass);
alter sequence pd_posts_seq_id owned by pd_posts.id;

--pd_products
create sequence pd_products_seq_id;
select setval('pd_products_seq_id', (select MAX(id) from pd_products));
alter table pd_products alter column id set default nextval('pd_products_seq_id'::regclass);
alter sequence pd_products_seq_id OWNED BY pd_products.id;

--в остальных нет айди


---------------------------------------------------------------------------------------------
/* 14. Модифицировать схему базы данных так, что бы для каждого сотрудника можно было хранить несколько телефонных номеров и комментарий для каждого номера. Заполните новую таблицу/таблицы  данными из таблицы pdt_phones.*/
---------------------------------------------------------------------------------------------
alter table pdt_phones -- добавляем столбец с айди работников
add  emp_id int,
add constraint fk_pdt_phones_emp_id
foreign key (emp_id) references pd_employees (id)
;

update pdt_phones -- заполняем этот столбец
set emp_id =
  (
    select pd_employees.id
    from pd_employees
    where pdt_phones.employee_name = pd_employees.name
  );


create sequence pd_phone_comments_seq_id increment 1 start 1;

create table pd_phone_comments
(
    id int default nextval('pd_phone_comments_seq_id':: regclass),
    emp_id int,
    phone varchar unique,
    comment varchar default null,--комментарий - текстовой поле или, является ли номер актуальным?
    comment_bool bool,--если комментарий - актуальность
  constraint fk_pd_phone_comments
  primary key (id),
  foreign key (phone) references pdt_phones (phone)
);
alter sequence pd_phone_comments_seq_id owned by pd_phone_comments.id;

insert into pd_phone_comments (emp_id, phone, comment_bool)
select emp_id, phone, is_actual
from pdt_phones
where phone is not null;

--drop table pdt_phones cascade; нужно ли удаление?