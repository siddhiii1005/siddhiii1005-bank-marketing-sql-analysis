"""Load the UCI Bank Marketing CSV into a local SQLite database.

Usage:
    python scripts/load_data.py
Then run any file in sql/ against bank.db, e.g.:
    sqlite3 bank.db < sql/03_targeting_strategy.sql
"""
import sqlite3
import pandas as pd

df = pd.read_csv("data/bank-additional-full.csv", sep=";")
df.columns = [c.replace(".", "_") for c in df.columns]  # emp.var.rate -> emp_var_rate

con = sqlite3.connect("bank.db")
df.to_sql("bank_marketing", con, if_exists="replace", index=False)
print(f"Loaded {len(df):,} rows into bank.db :: bank_marketing")
