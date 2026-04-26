# Dream Homes NYC Database Design Project
## 5310 - SQL Final Project (2026 Winter)

This project aims to develop a data management solution for a real estate business operating in the Tri-State area (NY, NJ, CT).

## Repository Contents

- **ER-diagram.pdf**  
  Entity-relationship diagram of the database schema.

- **SCHEMA.sql**  
  SQL file defining the database schema.

- **data_generator.ipynb**  
  Notebook used to generate the synthetic data.

- **dreamhomes_raw_csv_v2 folder**  
  Raw synthetic data generated using `data_generator.ipynb`.

- **etl_load_to_postgres.ipynb**  
  Notebook used to transform and load raw data into the database, which is defined using `SCHEMA.sql`.

- **processed_data folder**  
  Structured data loaded into SQL tables using `etl_load_to_postgres.ipynb`.
