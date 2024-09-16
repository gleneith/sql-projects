/* project description
Ben's Pizzeria wants to use the data stored to answer a few questions about the orders being made to customers, and the stock control within the pizzeria, especially Ben 
wants to be able to know when it is time to order new stock, what ingredients go into each pizza, their quality based on the size of the pizza and the existing stock level
within the pizzeria. As this is a pizzeria, Ben also wants data on his staff as he wants to find out what each staff member is working on based on the staff data Ben
wants to see how much each staff shift duration and how much they are being paid 
*/


-- creating database::
CREATE DATABASE Pizzeria

-- creating schema::
CREATE SCHEMA Pizzeria

-- creating orders table::

CREATE TABLE `orders` (
    `row_id` int  NOT NULL ,
    `order_id` varchar(10)  NOT NULL ,
    `created_at` datetime  NOT NULL ,
    `item_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    `cust_id` int  NOT NULL ,
    `delivery` boolean  NOT NULL ,
    `add_id` int  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

-- creating customers table::

CREATE TABLE `customers` (
    `cust_id` int  NOT NULL ,
    `cust_firstname` varchar(50)  NOT NULL ,
    `cust_lastname` varchar(50)  NOT NULL ,
    PRIMARY KEY (
        `cust_id`
    )
);

-- creating address table::

CREATE TABLE `address` (
    `add_id` int  NOT NULL ,
    `delivery_address1` varchar(200)  NOT NULL ,
    `delivery_address2` varchar(200)  NULL ,
    `delivery_city` varchar(50)  NOT NULL ,
    `delivery_zipcode` varchar(20)  NOT NULL ,
    PRIMARY KEY (
        `add_id`
    )
);

-- creating item 
CREATE TABLE `item` (
    `item_id` varchar(10)  NOT NULL ,
    `sku` varchar(20)  NOT NULL ,
    `item_name` varchar(100)  NOT NULL ,
    `item_cat` varchar(100)  NOT NULL ,
    `item_size` varchar(10)  NOT NULL ,
    `item_price` decimal(10,2)  NOT NULL ,
    PRIMARY KEY (
        `item_id`
    )
);

CREATE TABLE `ingredient` (
    `ing_id` varchar(10)  NOT NULL ,
    `ing_name` varchar(200)  NOT NULL ,
    `ing_weight` int  NOT NULL ,
    `ing_meas` varchar(20)  NOT NULL ,
    `ing_price` decimal(5,2)  NOT NULL ,
    PRIMARY KEY (
        `ing_id`
    )
);

CREATE TABLE `recipe` (
    `row_id` int  NOT NULL ,
    `recipe_id` varchar(20)  NOT NULL ,
    `ing_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

CREATE TABLE `inventory` (
    `inv_id` int  NOT NULL ,
    `item_id` varchar(10)  NOT NULL ,
    `quantity` int  NOT NULL ,
    PRIMARY KEY (
        `inv_id`
    )
);

CREATE TABLE `staff` (
    `staff_id` varchar(20)  NOT NULL ,
    `first_name` varchar(50)  NOT NULL ,
    `last_name` varchar(50)  NOT NULL ,
    `position` varchar(100)  NOT NULL ,
    `hourly_rate` decimal(5,2)  NOT NULL ,
    PRIMARY KEY (
        `staff_id`
    )
);

CREATE TABLE `shift` (
    `shift_id` varchar(20)  NOT NULL ,
    `day_of_week` varchar(10)  NOT NULL ,
    `start_time` time  NOT NULL ,
    `end_time` time  NOT NULL ,
    PRIMARY KEY (
        `shift_id`
    )
);

CREATE TABLE `rota` (
    `row_id` int  NOT NULL ,
    `rota_id` varchar(20)  NOT NULL ,
    `date` datetime  NOT NULL ,
    `shift_id` varchar(20)  NOT NULL ,
    `staff_id` varchar(20)  NOT NULL ,
    PRIMARY KEY (
        `row_id`
    )
);

-- analysing database based on the Pizzeria's task questions::
/* 1. Order Activity
   2. Inventory Management 
        - Total quantity by ingredients 
        - Total cost of ingredients 
        - Calculated cost of pizza
        - Percentage stock remaining by ingredients 
   3. Staff Activities
        - Staff shift duration 
        - Staff cost per role
*/
-- showing the order activities within the pizzeria
    select 
    o.order_id, i.item_price, o.quantity, i.item_cat, i.item_name, o.created_at,
    a.delivery_address1, a.delivery_address2, a.delivery_city, a.delivery_zipcode, 
    o.delivery
    from orders o 
    left join item i on o.item_id = i.item_id
    left join address a on o.add_id - a.add_id

-- showing the total quantity by the ingredients 
    select 
    o.item_id, i.sku, i.item_name, 
    sum(o.quantity) as order_quantity
    from orders o
    left join item i on o.item_id = i.item_id
    group by o.item_id, i.sku, i.item_name

-- showing the cost of ingredients
    select 
    s1.item_name, s1.ing_id, s1.ing_name, s1.ing_weight, s1.ing_price, s1.order_quantity, s1.recipe_quantity,
    s1.order_quantity * s1.recipe_quantity as ordered_weight,
    s1.ing_price/s1.ing_weight as cost_of_unit,
    (s1.order_quantity * s1.recipe_quantity) * (s1.ing_price / s1.ing_weight) as cost_of_ingredient
    
    from (select 
    o.item_id, i.sku, i.item_name, r.ing_id,ing.ing_name,ing.ing_weight, ing.ing_price,
    r.quantity as recipe_quantity,
    sum(o.quantity) as order_quantity
    from orders o
    left join item i on o.item_id = i.item_id
    left join recipe r on i.sku = r.recipe_id
    left join ingredient ing on ing.ing_id = r.ing_id
    group by o.item_id, i.sku, i.item_name, r.ing_id, r.quantity, ing.ing_name,ing.ing_weight, ing.ing_price) s1

-- showing the calculated cost of each pizza and the remaining stock by ingredients. 
/* note:: the results from  the previous query were saved as a view allowing me to work on analysing this task. which was saved as "stock one".*/
    select 
    s2.ing_name, s2.ordered_weight, 
    ing.ing_weight * inv.quantity as total_inv_weight,
    (ing.ing_weight * inv.quantity) - s2.ordered_weight as remaing_weight
    from (select 
    ing_id, ing_name, sum(ordered_weight) as ordered_weight
    from stock_one
    group by ing_name, ing_id, ordered_weight)s2
    
    left join inventory inv on inv.item_id = s2.ing_id
    left join ingredient ing on ing.ing_id = s2.ing_id

-- showing the staff shift duration
    select 
    r.date,
    s.first_name, s.last_name,
    sh.start_time, sh.end_time,
    time(timediff(sh.end_time,sh.start_time)) as shift_duration
    from rota r
    left join staff s on r.staff_id = s.staff_id
    left join shift sh on r.shift_id  = sh.shift_id

-- showing how much each staff is being paid based on their role and shift duration
    select 
    r.date,
    s.first_name, s.last_name,
    sh.start_time, sh.end_time,
    time(timediff(sh.end_time,sh.start_time)) as shift_duration,
    ((hour(timediff(sh.end_time, sh.start_time)) * 60) + (minute(timediff(sh.end_time, sh.start_time)))) / 60 as hours_in_shift,
    ((hour(timediff(sh.end_time, sh.start_time)) * 60) + (minute(timediff(sh.end_time, sh.start_time)))) / 60 * s.hourly_rate as staff_cost
    from rota r
    left join staff s on r.staff_id = s.staff_id
    left join shift sh on r.shift_id  = sh.shift_id
