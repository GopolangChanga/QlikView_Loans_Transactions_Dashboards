# Bank Data Model – Qlik ETL Scripts

Three-layer ETL scripts for loading and modelling banking data in **Qlik Sense / QlikView**.

## Architecture

SQL Server (Bank.dbo.*)
│
▼
┌─────────────────────┐
│  01 – Extract       │  → Raw QVDs  ($(vQVD_E_Directory))
└─────────────────────┘
│
▼
┌─────────────────────┐
│  02 – Transform     │  → Cleaned / enriched QVDs  ($(vQVD_T_Directory))
└─────────────────────┘
│
▼
┌─────────────────────┐
│  03 – Presentation  │  → Final in-memory data model
└─────────────────────┘



## Files

| File | Layer | Description |
|------|-------|-------------|
| `01_extract_model_load_scripts.md` | Extract | Pulls data from SQL Server and stores raw QVDs |
| `02_transform_model_load_scripts.md` | Transform | Cleans, standardises and enriches data |
| `03_presentation_model_load_scripts.md` | Presentation | Builds the final star-schema data model |

## Required Variables

Define these before running the scripts (usually in a Config or Main script):

```qvs
SET vQVD_E_Directory = 'lib://QVDs/Extract';
SET vQVD_T_Directory = 'lib://QVDs/Transform';



Load Order

1. Establish the database connection (OLE DB / ODBC)
2. Run Extract → creates raw QVDs
3. Run Transform → creates cleaned QVDs
4. Run Presentation → builds the final data model
5. (Optional) Load a Master Calendar and apply Section Access



Data Model
Key Relationships

accounts_dim.account_id_fact ↔ fact_transaction.account_id_fact
accounts_dim.account_id_card ↔ cards_dim.account_id_card
customer_dim.customer_id ↔ accounts_dim.customer_id / fact_loan.customer_id
merchants_dim.merchant_id ↔ fact_transaction.merchant_id


How to Use

Create a new Qlik Sense / QlikView app
Copy the script blocks from the three Markdown files into your load script
Set the folder connections / variables to the correct QVD directories
Reload the app

