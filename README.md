# Data_Wearhouse_Start_Schema_On_northwind_database

# ETL_Northwind_Star_Schema

This project contains a T-SQL script to create a Star Schema from the classic Northwind database in SQL Server.

## Description
- Creates dimension tables: DimCustomer, DimProduct, DimEmployee, DimTime
- Creates a fact table: FactSales
- Populates all tables with data from the NORTHWIND database
- Defines required foreign key relationships

## How to Use

1. Create a new database:
```sql
CREATE DATABASE ETL_Northwind_Star_Schema;
