--jingyi Li hw --
--SQL Assignments--
use WideWorldImporters

--question 1 
--a table determine his or her personal phone num, fax num/ company phone num, fax num 
select p.fullname, p.FaxNumber, p.PhoneNumber, p.IsEmployee,s.FaxNumber as supplier_faxNum, s.PhoneNumber as supplier_PhoneNum, c.FaxNumber as customer_fax, c.PhoneNumber as customer_phone
from Application.People p
left join Purchasing.Suppliers s 
on s.SupplierID = p.PersonID -- filter if this person works for supplier company 
left join Sales.Customers c
on c.PrimaryContactPersonID = p.PersonID or c.AlternateContactPersonID = p.PersonID; --filter if this person works for customer company 

--question 2
--list the customer name if customer phone == primary contact person's phone
select c.CustomerName
from (select p.PhoneNumber, p.PersonID
from Application.People p, Purchasing.Suppliers s
where s.PrimaryContactPersonID  = p.PersonID) as pr_phone, Application.People as p, Sales.Customers as c--this sub query help to filter out the phone number of primary contact people 
where c.PhoneNumber = pr_phone.PhoneNumber 

--question 3
--customer with sales before 2016 but not sales after 2016
with avai_customer as(-- create the temp table by using CTE
select o.CustomerID
from sales.orders o 
where o.OrderDate<'20160101'
intersect -- make sure that the order date is smaller than 2016 and no sales after 2016
select cus.CustomerID
from sales.orders cus
where cus.CustomerID not in (select distinct o .CustomerID from sales.orders o where o.orderdate>'20151231')) 

select c.CustomerName
from avai_customer a, sales.Customers c
where c.CustomerID = a.CustomerID

--question 4
--list of stock item and total quantity for each stock item in perchase order in 2013
with stock_ID as(--CTE for a column of stock ID and its order date and its quantity 
select pl.stockitemID, p.OrderDate, t.Quantity
from Purchasing.PurchaseOrderLines pl , purchasing.PurchaseOrders p, Warehouse.StockItemTransactions t
where year(p.OrderDate) = 2016 and p.PurchaseOrderID = pl.PurchaseOrderID and pl.StockItemID = t.StockItemID

)

select s.StockItemID,s.StockItemname,sum(id.Quantity) as total_quant, id.OrderDate --do accumulation on the quantity by stockitem id 
from stock_ID id, Warehouse.StockItems s
where id.StockItemID = s.StockItemID 
group by s.StockItemID,s.StockItemName, id.OrderDate
order by id.OrderDate

--question 5
--stock item with at least 10 char in description
select StockItemID, StockItemName
from warehouse.StockItems s
where len(StockItemName) >=10 --at least 10 char in name 



--question 6
--stock that not sold in alabama and Gorgia in 2014
with stock_ID as(--CTE for stock id that perchased in 2014

select pl.stockitemID, p.OrderDate, s.PostalCityID, s.SupplierID
from Purchasing.PurchaseOrderLines pl , purchasing.PurchaseOrders p, Purchasing.Suppliers s
where year(p.OrderDate) = 2014 and p.PurchaseOrderID = pl.PurchaseOrderID 

)

select s.StockItemID, s.StockItemName, id.OrderDate
from Warehouse.stockitems s, stock_ID id, Application.StateProvinces pro
where s.StockItemID =id.StockItemID and s.SupplierID = id.SupplierID and id.PostalCityID not in (
		select distinct s.StateProvinceID
		from Application.StateProvinces s
		where s.StateProvinceName = 'Alabama' or s.StateProvinceName = 'Georgia'); --filter out the state that is not in alabama or georgia 





--question 7
--lst of state and avg dates for processing 
with avai as ( --this is not a good temp table because the cartition product of three table is too big to process, too much running time !!!!
	select distinct s.PostalCityID, trans.PurchaseOrderID as orderID, o.OrderDate,  i.ConfirmedDeliveryTime
	from purchasing.SupplierTransactions trans, purchasing.Suppliers s, sales.Orders o,sales.Invoices i
	where s.SupplierID = trans.SupplierID and o.orderid = i.OrderID)

select pro.StateProvinceName, avg(DATEDIFF(DAY,avai.ConfirmedDeliveryTime,avai.OrderDate)) as 'average dates for processing' 
from Application.StateProvinces pro,avai
where pro.StateProvinceID = avai.PostalCityID;





--question 8


--question 9
--list of stock item that purchased more than sold in 2015
with purchase as( --purchase table in 2015
select ol.PurchaseOrderID, ol.StockItemID, sum(ReceivedOuters) as amountPurchased
from purchasing.PurchaseOrderLines ol, purchasing.PurchaseOrders o 
where ol.PurchaseOrderID = o.PurchaseOrderID and year(o.OrderDate)=2015
group by ol.StockItemID,ol.PurchaseOrderID

),


sales as( --sale table in 2015
select ol.OrderID, ol.StockItemID, sum(Quantity) as amountSales
from sales.OrderLines ol, sales.Orders o 
where ol.OrderID = o.OrderID and year(o.OrderDate)=2015
group by ol.StockItemID,ol.OrderID

)

select distinct p.StockItemID
from purchase p, sales s
where p.StockItemID = s.StockItemID and p.amountPurchased>s.amountSales;



--question 10
--table of customer and hone num, primary contact name (whom did not sell more than 10 mugs in 2016)
with amount as( --year 2016 sales of mugs 
select o.CustomerID,o.OrderID, count(o.OrderID) as amountOrder
from sales.orderlines l, sales.orders o 
where l.OrderID = o.OrderID and year(o.OrderDate)=2016 and l.Description like '%mug%'
group by o.OrderID, CustomerID)

select distinct a.CustomerID,c.CustomerName, c.PhoneNumber,p.FullName as primary_contact_personName
from amount a,sales.Customers c, Application.people p
where a.amountOrder <10 and a.CustomerID=c.CustomerID and p.PersonID= c.PrimaryContactPersonID 


--qustion 11
--list of all cities that updated from 2015
select CityName 
from Application.Cities FOR SYSTEM_TIME BETWEEN'2015-01-01 00:00:00.0000000' AND'9999-12-31 23:59:59.9999999';--tempral table 

--question 12
--order details on 2014-7-1
select stock.StockItemName ,il.Quantity ,customer.CustomerName,i.ContactPersonID,customer.PhoneNumber,CONCAT(customer.DeliveryAddressLine1,' ' ,customer.DeliveryAddressLine1, ' ' ,customer.PostalPostalCode) AS Address,customer.PostalCityID,  
city.CityName, state.StateProvinceName, country.CountryName 
FROM Warehouse.StockItems stock,Sales.InvoiceLines il,Sales.Invoices i,Sales.Customers customer, Application.Cities city, application.StateProvinces state, Application.Countries country
where stock.StockItemID = il.StockItemID and il.InvoiceID =i.InvoiceID and i.InvoiceDate = '2014-07-01' and i.CustomerID = customer.CustomerID and customer.PostalCityID =city.CityID and state.StateProvinceID = city.StateProvinceID 
and state.CountryID = country.CountryID 


--question 13
--list of stock item and details --sum(cast(colName   as   bigint)) ----pretttttttty slow!!!!!
select stock.StockItemID, StockItemName, sum(cast(OrderedOuters as bigint)) as total_quantity_purchased, sum(cast(ol.Quantity as bigint)) as total_quantity_sold, sum(cast(OrderedOuters as bigint))-sum(cast(ol.Quantity as bigint)) as remainning 
from warehouse.StockItems stock, sales.Orders o , Purchasing.PurchaseOrderLines p, sales.OrderLines ol
where stock.StockItemID = p.StockItemID and o.OrderID = ol.OrderID
group by stock.StockItemID, stockitemname 


--question 14
select stock.StockItemName , city.CityName, state.StateProvinceName, country.CountryName , il.quantity, rank() over(partition by cityname order by  il.quantity  desc) rank
FROM Warehouse.StockItems stock,Sales.InvoiceLines il,Sales.Invoices i,Sales.Customers customer, Application.Cities city, application.StateProvinces state, Application.Countries country
where stock.StockItemID = il.StockItemID and il.InvoiceID =i.InvoiceID and year(i.InvoiceDate) = 2016 and i.CustomerID = customer.CustomerID and customer.PostalCityID =city.CityID and state.StateProvinceID = city.StateProvinceID 
and state.CountryID = country.CountryID 

--qustion 15
select OrderID, Count(OrderID) ordernumber, JSON_VALUE(i.ReturnedDeliveryData, '$.Events[0].EventTime') as DeliveryAttempt 
from Sales.Invoices i
group by OrderID,JSON_VALUE(i.ReturnedDeliveryData, '$.Events[0].EventTime') 
having COUNT(OrderID)>1 --we use the where clause here since we are filter the group 

--question 16
select StockItemID, StockItemName, JSON_VALUE(s.CustomFields, '$.CountryOfManufacture') AS manufactrue_country
from warehouse.StockItems s
where JSON_VALUE(s.CustomFields, '$.CountryOfManufacture')  = 'China'

--question 17
--total quantity of stock item sold in 2015
select  sum( ol.Quantity) as toal_quatity , JSON_VALUE(s.CustomFields, '$.CountryOfManufacture') AS manufactrue_country
from warehouse.StockItems s, sales.orderlines ol, sales.orders o
where s.StockItemID = ol.StockItemID and  o.orderid = ol.OrderID and year(OrderDate) = 2015
group by  JSON_VALUE(s.CustomFields, '$.CountryOfManufacture')

--question 18
--a view --- still confused by this 
go
CREATE VIEW  new_sa AS 
SELECT  StockGroupName,ol.Quantity AS Quantity,YEAR(o.OrderDate) AS 'year' 
FROM Sales.Orders o, sales.orderlines ol, warehouse.StockItemStockGroups st, Warehouse.StockGroups stg
where o.OrderID = ol.OrderID and ol.StockItemID = st.StockItemID and st.StockGroupID = stg.StockGroupID
GROUP BY YEAR(o.OrderDate), StockGroupName, ol.Quantity 


go

select 'StockGroupName', 'Quantity', 'Year'
from(select new_sa.Quantity, new_sa.StockGroupName, new_sa.year
from new_sa) as sourceT
PIVOT(
sum(new_sa.quantity )
for year in([2013],[2014],[2015],[2016],[2017])) as PivotT;

--question 28
/*A system of locks prevents users from modifying data in a way that affects other users. After a user performs an action that causes a lock to be applied, other users cannot perform actions that would conflict with the lock until the owner releases it.
Shared Lock (read)(a locked can be shared), Update Lock (only in multiple transactions)(update something ), Exclusive Lock (write) (exclusive to current transaction)// data has to be no lock or the data has a shared lock to lock the data.  Otherwise it has to wait for the system to release other locks before applying other new locks. 
In default senario, shared locked is applied when the transaction is tried to read the data? When reading is finished , the shared lock will disappear. 
If we want to do change to the data, the transaction is first apply to update lock, if lock cannot be apply, something else lock is applied and it need to wait ; otherwise it will change the data. Then update lock will change to exclusive locks. No other transaction will see this data. The lock will be there until transition rolled back . It will be there when the transaction ends */

/*there are 4 state of isolation. read Uncommited(no share lock), read commited(share lock) , repeatable commited(share lock to the end of the transaction ) and serializable(lock both ungoing data and futreu data ). */

--question 29 