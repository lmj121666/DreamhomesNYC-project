# Dream Homes NYC Database Design Project
## 5310 - SQL Final Project (2026 Spring)

## Team Members

**April Liu** - ql2578@columbia.edu    
**Mengjie Liu** - ml5384@columbia.edu   
**Chun-Wei Hsu** - ch4004@columbia.edu     
**Zhenyuan Wei** - zw3152@columbia.edu   

This project aims to develop a data management solution for a real estate business operating in the Tri-State area (NY, NJ, CT).

## Repository Contents

- **ER-diagram.pdf**  
  [Entity-relationship diagram](https://github.com/lmj121666/DreamhomesNYC-project/blob/e8ddabe9530a5b281540aed7b41c409f8f5c1abf/ER-diagram.pdf) of the database schema.

- **SCHEMA.sql**  
  [SQL file](https://github.com/lmj121666/DreamhomesNYC-project/blob/ec43e490e1d42890b79ebd051ee0b0354857db38/etl_load_to_postgres.ipynb) defining the database schema.

- **data_generator.ipynb**  
  [Notebook](https://github.com/lmj121666/DreamhomesNYC-project/blob/029b8d9d529cd6b44cc405ae1db8701ddbdc7ef4/data_generator.ipynb) used to generate the synthetic data.

- **dreamhomes_raw_csv_v2 folder**  
  Raw synthetic [data](https://github.com/lmj121666/DreamhomesNYC-project/tree/2eb76bed259888ff21fb9d3019c8c14eed1ebdcb/data/dreamhomes_raw_csv_v2) generated using `data_generator.ipynb`.

- **etl_load_to_postgres.ipynb**  
  [Notebook](https://github.com/lmj121666/DreamhomesNYC-project/blob/8743ed4d02052afe3642d193bb1f591723bb9ea0/etl_load_to_postgres.ipynb) used to transform and load raw data into the database, which is defined using `SCHEMA.sql`.

- **processed_data folder**  
  Structured [data](https://github.com/lmj121666/DreamhomesNYC-project/tree/8e722a40a344aedd4379319d41a3824c191fda25/data/processed_data) loaded into SQL tables using `etl_load_to_postgres.ipynb`.

- **SQL Queries folder**
  [SQL Queries](https://github.com/lmj121666/DreamhomesNYC-project/tree/main/SQL%20Queries) containing SQL query files used for data analysis and retrieval from the database.
