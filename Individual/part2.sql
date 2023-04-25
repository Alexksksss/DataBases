/* Индивидуальная работа часть 2
   Литвак А. И. гр. 932020
   Вариант <5> (поставки) */

--в самом конце файла добавила создание и изменения таблиц с 1 части индивидуальной работы
------------------------------------------------------------------------------------
/*7. Написать процедуры и функции, согласно условиям . Все процедуры и функции при необходимости должны включать обработчики исключений.
Названия функций: F_<имя>.  Формат названий процедур: P_<имя>. Написать анонимные блоки или  запросы для проверки работы процедур и функций. */
!внимние для каждого описанного в задании условия должна быть позитивная и неготивания провреки (Если возможно)

/*7.1. . Написать функцию, которая возвращает количество поставщиков для заданного магазина, выполнивших доставку в течение заданного года.
Если промежуток год не указан, считается количество за всё время.*/

create or replace function F_count_of_suppliers(func_id_store int, f_year in int default null)
returns int as
    $$
    declare
	store_count int;
	count int;
begin
    if (f_year < 0 or f_year > extract(year from current_date)) then raise exception 'Ошибка ввода значений года';
    else
	select count(*)
	into store_count
	from "Магазины"
	where "Магазины"."ID_Магазина" = func_id_store;

	if (func_id_store <1 or func_id_store > (select max("ID_Магазина") from "Магазины")) then
		raise exception 'Введен неверный id';
	end if;

    select count(distinct "Поставки"."ID_Поставщика") into count
	from "Поставки"
	where "Поставки"."ID_Магазина" = func_id_store
		and (f_year is null or extract(year from"Поставки"."Дата_поставки")=f_year);

	return count;
    end if;
    end;
 $$ language plpgsql
;

select F_count_of_suppliers(1);--проверка, когда год нулл
select F_count_of_suppliers(1,2022);--проверка с годом
select F_count_of_suppliers(1,2025);--проверка на выброс исключения по году
select F_count_of_suppliers(25);--проверка на выброс исключения по айди

/*7.2. Написать функцию, которая для каждого поставщика рассчитывает среднюю стоимость поставки. Значение может рассчитываться за год и/или
для определённой категории товаров.
Функция имеет три аргумента: id_поставщика, год и категория товара. Только первый аргумент является обязательным. Предусмотреть вариант
вызова функции без необязательных аргументов. .*/

create or replace function F_avg_sum("ID_ПОСТАВЩИКА" int, f_year int default null, "КАТЕГОРИЯ" text default null)
returns int as
    $$
    declare
	sups int;
	res float;
begin
    if (f_year < 0 or f_year > extract(year from current_date)) then raise exception 'Ошибка ввода значений года';
    else

    if ("ID_ПОСТАВЩИКА" < 1 or "ID_ПОСТАВЩИКА" > (select max("ID_Поставщика") from "Поставщики")) then raise exception 'Ошибка ввода айди поставщика';
        else
	select count(*)
	into sups
	from "Поставщики"
	where "Поставщики"."ID_Поставщика" = "ID_ПОСТАВЩИКА";

    select avg("Поставки"."Цена"*"Поставки"."Количество") into res
	from "Поставки"
	inner join "Товары" on "Товары"."ID_Товара" = "Поставки"."ID_Товара"
	inner join "Категории" on "Товары"."ID_Категории" = "Категории"."ID_Категории"
	where "Поставки"."ID_Поставщика" = "ID_ПОСТАВЩИКА" and
		 (f_year is null or extract(year from"Поставки"."Дата_поставки")=f_year)
	and("КАТЕГОРИЯ" is null or lower("КАТЕГОРИЯ") = lower("Категории"."Название"));

	return res;
    end if;
    end if;
    end;
 $$ language plpgsql ;

select F_avg_sum(3,2022,'ЭмаЛи');
select F_avg_sum(3,2024,'Эмали');--выброс по году
select F_avg_sum(5);--без необязательных
select F_avg_sum(15);--выброс по айди поставщика

/*7.3. Написать процедуру, которая формирует список поставщиков поставлявших конкретный товар в указанный месяц
  (Название товара и дата – аргументы процедуру). Формат вывода:
------------------------------------------------------
Список поставок <название товара> за <название месяца>:
<Название поставщика 1>, <телефон>:
 1. <дата поставки > - Название магазина >
 2. <дата поставки > - Название магазина >
 и т.д. ….
<Название поставщика 2>, <телефон>:
 1. <дата поставки > - Название магазина >
 2. <дата поставки > - Название магазина >
 и т.д. ….
------------------------------------------------------*/

create or replace procedure P_Spisok_otcr(product_name text, p_month int, p_year int) as
     $$
    declare
	count_p int;
	last_id_of_sup int;
	num int;
    str1 text;
    month text;
    str_s_phone text;
    str_date_name text;

	curs1 cursor for
	select "Поставки"."ID_Поставщика", "Поставщики"."Название", "Поставщики"."Телефон", "Поставки"."Дата_поставки", "Магазины"."Название" as shop_name
	from "Поставки"
	inner join "Товары" on "Товары"."ID_Товара" = "Поставки"."ID_Товара"
	inner join "Поставщики"  on "Поставщики"."ID_Поставщика"= "Поставки"."ID_Поставщика"
	inner join "Магазины" on "Магазины"."ID_Магазина" = "Поставки"."ID_Магазина"
	where lower("Товары"."Название") = lower(product_name)
		and extract(month from "Поставки"."Дата_поставки") = p_month and extract(year from "Поставки"."Дата_поставки") = p_year
	order by "Поставки"."ID_Поставщика";
begin
	select count(*)
	into count_p
	from "Товары"
	where lower("Товары"."Название") = lower(product_name);

	 if (p_year < 0 or p_year > extract(year from current_date) or p_month < 0 or p_month > 12) then raise exception 'Ошибка ввода значений месяца или года';
	 end if;

	month := lower(to_char(to_date(p_month::text, 'mm'), 'TMMonth'));
	str1 := 'Список поставок товара ' || lower(product_name) || ' за ' || month||' месяц '||p_year||'-го'||' года'|| ':';
	raise notice '%' , str1;

	for i in curs1 loop
		if last_id_of_sup is null or last_id_of_sup != i."ID_Поставщика" then
			last_id_of_sup := i."ID_Поставщика";
			num := 0;
			str_s_phone:= i."Название" || ', ' || i."Телефон";
			raise notice '%' , str_s_phone;
		end if;
		num := num + 1;
		str_date_name:= num || '. ' || to_char(i."Дата_поставки", 'yyyy-mm-dd') || ' - ' || i.shop_name;
		raise notice '%', str_date_name;
	end loop;
	--close curs1;

	if last_id_of_sup is null then
		raise notice '%','В данном месяце поставок данного товара не было';
	end if;
end;
     $$ language plpgsql
;




INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 10, 4, TO_DATE('2019-10-01', 'YYYY-MM-DD'), 52,6 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 10, 5, TO_DATE('2019-10-01', 'YYYY-MM-DD'), 52,6 );--добавление для проверки, когда несколько поставщиков в несколько магазинов

call P_Spisok_otcr('Молоко',10,2019 );--несколько поставщиков, несколько магазинов
call P_Spisok_otcr('Молоко', 01, 2000); -- проверка, если не было поставок
call P_Spisok_otcr('Молоко', 10, 2024); --проверка на выброс исключения по дате

/*7.4. Написать процедуру, которая выполняете копирование всех данных об указанном магазине, включая поставки.
Аргумент процедуры -id_магазина. Для скопированной записи ставится отметка “копия” в поле название.*/

create or replace procedure P_Shop_copy("id_магазина" int) as
     $$
    declare
	store_count int;
	copy_shop int;
	copy_sup int;

	curs2 cursor for
	select *
	from "Поставки"
	where "Поставки"."ID_Магазина"="id_магазина";

begin
    if id_магазина < 1 or id_магазина > (select max("Магазины"."ID_Магазина") from "Магазины")
    then raise exception 'Такого магазина в нашей бд нет';
    else
	select count(*)
	into store_count
	from "Магазины"
	where "Магазины"."ID_Магазина"="id_магазина";

	select (max("ID_Поставки") + 1) into copy_sup from "Поставки";

	select (max("ID_Магазина") + 1) into copy_shop from "Магазины";

	insert into "Магазины"("ID_Магазина", "Название", "ФИО_директора", "Адрес", "Телефон")
    select copy_shop,'КОПИЯ - '||"Магазины"."Название", "ФИО_директора","Адрес", "Телефон"
    from "Магазины"
    where "ID_Магазина"= "id_магазина";

	for i in curs2 loop
        copy_sup:=copy_sup+1;
        insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
	    values (copy_sup, i."ID_Поставщика",i."ID_Товара", copy_shop,i."Дата_поставки",i."Цена",i."Количество");
        end loop;

	end if;
end;
     $$ language plpgsql
;


call P_Shop_copy(10);
call P_Shop_copy(9);
call P_Shop_copy(20);--проверка на выброс по магазину

/*7.5. Текст задания.*/

--вызов под каждым заданием

------------------------------------------------------------------------------------
/*8. Создать триггеры, включить обработчики исключений. Написать скрипты для проверки. При необходимости снять ограничения (если ограничение мешает проверить работу триггера).*/

/*8.1. Написать триггер, активизирующийся при изменении содержимого таблицы «Поставки» и проверяющий,
 чтобы в один и тот же магазин от одного и того же поставщика было не более 10 поставок.*/

create or replace function F_tr_for_changing_sup ()
returns trigger as
    $$
    declare
        s_count int;
    begin
        select count(*) into s_count
                        from "Поставки"
                        where "ID_Поставщика" = new."ID_Поставщика" and "ID_Магазина"=new."ID_Магазина";
        if s_count > 10 then raise exception 'Больше 10 поставок!'; end if;


    return new;
    end;
    $$ language plpgsql
;

create or replace trigger TR_more_than_10_sup
before insert on "Поставки"
for each row execute function F_tr_for_changing_sup();

--Проверка:

insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (31,1,1,1, TO_DATE('2022-12-12', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (32,1,1,1, TO_DATE('2022-12-13', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (33,1,1,1, TO_DATE('2022-12-14', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (34,1,1,1, TO_DATE('2022-12-15', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (35,1,1,1, TO_DATE('2022-12-16', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (36,1,1,1, TO_DATE('2022-12-17', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (37,1,1,1, TO_DATE('2022-12-18', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (38,1,1,1, TO_DATE('2022-12-19', 'YYYY-MM-DD'),63,1);
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (39,1,1,1, TO_DATE('2022-12-20', 'YYYY-MM-DD'),63,1);

select *
from "Поставки"
where "ID_Поставки">30;--запрос на проверку, что добавились

insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (40,1,1,1, TO_DATE('2022-12-21', 'YYYY-MM-DD'),63,1);--11-ая поставка, выброс исключения

select *
from "Поставки"
where "ID_Поставки">39;--не добавился

delete from "Поставки" where "Поставки"."ID_Поставки" > 30;--вернуть к первоначальному виду

/*8.2.  Написать триггер, сохраняющий статистику изменений таблицы «Поставки» в таблице «Поставки_Статистика», в которой хранится дата изменения, тип изменения (insert, update, delete).
 Триггер также выводит на экран сообщение с указанием количества дней прошедших со дня последнего изменения.*/

create sequence sup_stat_seq_id increment 1 start 1;

create table "Поставки_Статистика"--создаем таблицу
(
	"ID_Изменения"  int default nextval('sup_stat_seq_id':: regclass),
	"Дата_Изменения" date,
	"Тип_Изменения" text,
	constraint pk_sup_stat primary key ("ID_Изменения"),
	constraint ch_sup_sat check ("Дата_Изменения" is not null and "Тип_Изменения" is not null)
);

alter sequence sup_stat_seq_id owned by "Поставки_Статистика"."ID_Изменения";

create or replace function F_stats()
returns trigger as
    $$
    declare
        str text;
        date_of_change date;
    begin
    select max("Дата_Изменения")::date into date_of_change from "Поставки_Статистика";

     if date_of_change is not null then
       str := 'Прошло ' || extract(day from current_date ) - extract(day from date_of_change) || ' дней с момента последнего изменения';
       raise notice '%', str;--для вывода сообщения
    end if;

    if tg_op = 'UPDATE' then
        insert into "Поставки_Статистика"("ID_Изменения", "Дата_Изменения", "Тип_Изменения")
        values(default, current_date , 'update');
        return new;
	elsif tg_op = 'INSERT' then
        insert into "Поставки_Статистика"("ID_Изменения", "Дата_Изменения", "Тип_Изменения")
        values(default, current_date , 'insert');
        return new;
	elsif tg_op = 'DELETE' then
        insert into "Поставки_Статистика"("ID_Изменения", "Дата_Изменения", "Тип_Изменения")
        values(default, current_date , 'delete');
        return old;
    end if;
    end;
    $$ language plpgsql
;

create or replace trigger TR_stat_change
after insert or delete or update on "Поставки"
for each row execute function F_stats();--сам триггер

insert into "Поставки" ("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена","Количество")
values (50, 1,1,2, TO_DATE('2022-12-25', 'YYYY-MM-DD'), 65,1);

update "Поставки" set "Цена" = 2 * "Цена" where "ID_Поставки" = 50;

delete from "Поставки" where "Поставки"."ID_Поставки" > 49;

select *
from "Поставки_Статистика";

/*8.3. Написать триггер, активизирующийся при вставке в таблицу “Поставки” и проверяющий наличие поставки в тот же магазин того же товара от того же поставщика.
 Если такая поставка найдена, то вместо вставки количество суммируется, берётся максимальная сумма и самое позднее время поставки.*/

create or replace function F_sum()
returns trigger as
    $$
    declare
        id int;
        price float;
        current_max_price float default 0;
    begin
    select max("ID_Поставки"), max("Цена")
           into id, current_max_price from "Поставки"
        where "Поставки"."ID_Магазина"= new."ID_Магазина" and "ID_Поставщика"= new."ID_Поставщика";
     if id is not null and current_max_price >0 then--(есть уже такая поставка)
         if  current_max_price > new."Цена" then price := current_max_price;
         else price:= new."Цена";
        end if;
         update "Поставки"
         set "Количество" = "Количество"+ new."Количество",
             "Дата_поставки" = new."Дата_поставки",
             "Цена" = price
         where "ID_Поставки" = id;
         return old;
     end if;
    return new;
    end;
    $$ language plpgsql
;

create or replace trigger TR_sum
before insert on "Поставки"
for each row execute function F_sum();


insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (100,6,1,10,TO_DATE('2022-12-26', 'YYYY-MM-DD'), 60, 2 ); -- добавился новый (в функции не произошел выход, поэтому возврат нью)
insert into "Поставки"("ID_Поставки", "ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество")
values (101,6,1,10,TO_DATE('2022-12-27', 'YYYY-MM-DD'), 65, 3 );--выход в ифе, возврат олд

select *
from "Поставки"
where "ID_Поставки"> 99;

------------------------------------------
--<тут запросы на удаление всех таблиц, представлений, процедур и функций>

drop function if exists F_avg_sum(integer, integer, text) cascade;
drop function if exists F_count_of_suppliers(integer, integer) cascade;
drop procedure if exists P_Spisok_otcr(text, integer, integer) cascade;
drop procedure if exists P_Shop_copy(integer) cascade;

drop function if exists F_tr_for_changing_sup() cascade;
drop function if exists F_stats() cascade;
drop function if exists F_sum() cascade;

drop table if exists "Категории" cascade;
drop table if exists "Магазины" cascade;
drop table if exists "Поставки" cascade;
drop table if exists "Поставки_Статистика" cascade;
drop table if exists "Поставщики" cascade;
drop table if exists "Товары" cascade;





------------------------------------------
--все добавления, изменения таблиц из 1 части

--create database supplies;
create sequence Поставщики_seq_id increment 1 start 1;

create sequence Товары_seq_id increment 1 start 1;

create sequence Магазины_seq_id increment 1 start 1;

create sequence Поставки_seq_id increment 1 start 1;

create table "Поставщики"
(
	"ID_Поставщика" int default nextval('Поставщики_seq_id':: regclass),
	"Название" text,
	"Адрес" text,
	"Телефон" text,
	constraint PK_Поставщики primary key ("ID_Поставщика"),
	constraint CH_Поставщики check ("Название" is not null and "ID_Поставщика" is not null)
);
alter sequence Поставщики_seq_id owned by "Поставщики"."ID_Поставщика";

create table "Товары"
(
	"ID_Товара" int default nextval('Товары_seq_id':: regclass),
	"Название" text,
	"Категория" text,
	"Производитель" text,
	constraint PK_Товары primary key ("ID_Товара"),
	constraint CH_Товары check ("Название" is not null and "Категория" is not null and "Производитель" is not null and "ID_Товара" is not null)
);
alter sequence Товары_seq_id owned by "Товары"."ID_Товара";

create table "Магазины"
(
	"ID_Магазина" int default nextval('Магазины_seq_id':: regclass),
	"Название" text,
	"ФИО_директора" text,
	"Адрес" text,
	"Телефон" text,
	constraint PK_Магазины primary key ("ID_Магазина"),
	constraint CH_Магазины check ("Название" is not null and "ФИО_директора" is not null and "ID_Магазина" is not null)
);
alter sequence Магазины_seq_id owned by "Магазины"."ID_Магазина";


create table "Поставки"
(
	"ID_Поставки" int  default nextval('Поставки_seq_id':: regclass),
	"ID_Поставщика" int,
	"ID_Товара" int,
	"ID_Магазина" int,
	"Дата_поставки" timestamp,
	"Цена" decimal,
	"Количество" int,
	constraint PK_Поставки primary key ("ID_Поставки"),
	constraint FK_Поставки_Поставщики foreign key ("ID_Поставщика") references "Поставщики" ("ID_Поставщика"),
	constraint FK_Поставки_Товары foreign key ("ID_Товара") references "Товары" ("ID_Товара"),
	constraint FK_Поставки_Магазины foreign key ("ID_Магазина") references "Магазины" ("ID_Магазина"),
	constraint CH_Поставки check ("Дата_поставки" is not null and "Цена" is not null and "Количество" is not null
	                                  and "Цена" >= 0 and "Количество" >= 0)
);
alter sequence Поставки_seq_id owned by "Поставки"."ID_Поставки";

INSERT INTO "Поставщики" ("Название", "Адрес", "Телефон") VALUES ('Вкуснотеево','г. Томск, ул. Нахимова 6', '+7 903 915 13 43');
INSERT INTO "Поставщики" ("Название", "Адрес", "Телефон") VALUES ('Макарена','г. Томск, пер. Инструментальный 41', '+7 913 886 77 53');
INSERT INTO "Поставщики" ("Название", "Адрес", "Телефон") VALUES ('ВеземВсем','г. Москва, ул. Красноармейская 119', '+7 923 801 00 25');
INSERT INTO "Поставщики" ("Название", "Адрес", "Телефон") VALUES ('ГудГудс','г. Новосибирск, ул. Никитина 23', '+7 903 975 31 34');
INSERT INTO "Поставщики" ("Название", "Адрес", "Телефон") VALUES ('PROКисло','г. Томск, ул. Ленина 30', '+7 913 809 19 77');
INSERT INTO "Поставщики" ("Название", "Адрес", "Телефон") VALUES ('ООО Интер','г. Москва, ул. Советская 15', '+7 905 970 15 51');

INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Кефир','Молочная продукция', 'Простоквашино');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Творог','Молочная продукция', 'Простоквашино');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Макароны','Бакалея', 'Barilla');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Coca-Cola','Напитки', 'The Coca-Cola company');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Sprite','Напитки', 'The Coca-Cola company');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Эмаль для дерева белая','Эмали', 'ИП рога и копыта');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Эмаль для дерева черная','Эмали', 'ИП рога и копыта');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Лак для дерева белый','Лаки', 'ИП рога и копыта');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Лак для дерева черный','Лаки', 'ИП копыта и рога');
INSERT INTO "Товары"("Название", "Категория", "Производитель") VALUES ('Молоко','Молочная продукция', 'Простоквашино');

INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Лента','Иванов Степан Владимирович', 'г. Томск, ул. Кирова 15', '+7 911 820 23 22');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Ярче','Фомин Валерий Валерьевич', 'г. Москва, ул. Вершинина 22', '+7 911 156 23 12');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Спар','Александрова Елена Сергеевна', 'г. Москва, ул. Мира 34', '+7 905 546 89 54');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Мария-Ра','Русланова Екатерина Игоревна', 'г. Новосибирск, ул. Гоголя 56', '+7 912 467 88 88');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Абрикос','Макаров Алексей Алексеевич', 'г. Томск, ул. Сибирская 48', '+7 903 952 00 11');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Космос','Селиванова Надежда Алексеевна', 'г. Бийск, ул. Пионерская 11', '+7 941 685 85 13');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Мир','Поздов Афанасий Савванович', 'г. Хабароск, ул. Южная 48', '+7 903 952 12 58');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Корзинка','Жабкина Оксана Ефремовна', 'г. Бердск, ул. Речная 121', '+7 912 902 24 90');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Магнит','Янова Инна Александровна', 'г. Оренбург, ул. Первая 18', '+7 913 956 35 10');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Пятерочка','Курганова Василиса Александровна', 'г. Северск, ул. Солнечная 53', '+7 908 983 49 00');
INSERT INTO "Магазины"("Название", "ФИО_директора", "Адрес", "Телефон") VALUES ('Метро','Ивакина Алла Валерьевна', 'г. Нижний Новгород, ул. Елизаровых 38', '+7 935 967 23 13');

INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (1, 4, 1, TO_DATE('2022-11-01', 'YYYY-MM-DD'), 56,100 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (1, 5, 1, TO_DATE('2019-11-01', 'YYYY-MM-DD'), 58,100 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (5, 2, 4, TO_DATE('2021-08-13 ', 'YYYY-MM-DD'), 152,10 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (5, 1, 4, TO_DATE('2020-07-23 ', 'YYYY-MM-DD'), 80,20 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (2, 3, 2, TO_DATE('2022-04-13 ', 'YYYY-MM-DD'), 80,27 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (6, 6, 5, TO_DATE('2021-12-15 ', 'YYYY-MM-DD'), 240,25 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (6, 9, 5, TO_DATE('2022-01-05 ', 'YYYY-MM-DD'), 210,15 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 1, TO_DATE('2022-08-05 ', 'YYYY-MM-DD'), 210,15 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 2, TO_DATE('2022-09-05 ', 'YYYY-MM-DD'), 205,20 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 3, TO_DATE('2022-10-05 ', 'YYYY-MM-DD'), 208,18 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 4, TO_DATE('2022-09-05 ', 'YYYY-MM-DD'), 223,10 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 5, TO_DATE('2022-09-05 ', 'YYYY-MM-DD'), 200,25 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 6, TO_DATE('2022-08-05 ', 'YYYY-MM-DD'), 253,8 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 7, TO_DATE('2022-07-05 ', 'YYYY-MM-DD'), 268,5 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 8, TO_DATE('2022-07-05 ', 'YYYY-MM-DD'), 208,90 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 9, TO_DATE('2022-08-05 ', 'YYYY-MM-DD'), 219,17 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 10, TO_DATE('2022-09-05 ', 'YYYY-MM-DD'), 267,6 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (3, 7, 10, TO_DATE('2022-09-06 ', 'YYYY-MM-DD'), 254,8 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (5, 10, 4, TO_DATE('2020-10-01', 'YYYY-MM-DD'), 56,5 );
INSERT INTO "Поставки"("ID_Поставщика", "ID_Товара", "ID_Магазина", "Дата_поставки", "Цена", "Количество") VALUES (5, 10, 4, TO_DATE('2019-10-01', 'YYYY-MM-DD'), 53,5 );


update "Магазины"
set "Название" = concat("Магазины"."Название", ' - Интер')
from "Поставки"
inner join "Поставщики" "П" on "П"."ID_Поставщика" = "Поставки"."ID_Поставщика"
where  "Магазины"."ID_Магазина" = "Поставки"."ID_Магазина" and lower("Магазины"."Адрес") like '%томск%'
    and lower("П"."Название") = 'ооо интер' and lower("П"."Название") not like '%интер%'
;

delete from "Товары"
where "Товары"."ID_Товара" not in
      (select "Поставки"."ID_Товара"
       from "Поставки"); -- удалил 8 id

delete from "Поставщики"
where "Поставщики"."ID_Поставщика" not in
      (select "Поставки"."ID_Поставщика"
       from "Поставки"); -- удалил 4 Id

delete from "Магазины"
where "Магазины"."ID_Магазина" not in
      (select "Поставки"."ID_Магазина"
       from "Поставки");--удалил 11 id


create sequence Категории_seq_id increment 1 start 1;

create table "Категории"
(
	"ID_Категории" int default nextval('Категории_seq_id':: regclass),
	"Название" varchar unique,
    constraint PK_Категории primary key ("ID_Категории"),
	constraint CH_Категории check ("Категории"."Название" is not null and "ID_Категории" is not null)
);

alter sequence Категории_seq_id owned by "Категории"."ID_Категории";

insert into "Категории" ("Название")
select distinct "Категория"
from "Товары"
;

alter table "Товары"
add	"ID_Категории" int,
add constraint FK_Товары_ID_Категории
foreign key ("ID_Категории") references "Категории" ("ID_Категории")
;

update "Товары"
set "ID_Категории" =
	(
		select "Категории"."ID_Категории"
		from "Категории"
		where "Категории"."Название" = "Товары"."Категория"
	);

alter table "Товары"
drop column "Категория";