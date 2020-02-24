import os

import pandas as pd

from sqlalchemy import create_engine

DATA_FOLDER = os.environ.get("DATA_FOLDER")

MSSQL_PASSWORD = os.environ.get("MSSQL_PASSWORD")
MSSQL_USER = os.environ.get("MSSQL_USER")

conn = create_engine(f'mssql+pyodbc://{MSSQL_USER}:{MSSQL_PASSWORD}@warehouse:1433/'
                     f'warehouse?driver=ODBC+Driver+17+for+SQL+Server')

for file_name in ("meets", "openpowerlifting"):
    data = pd.read_csv(f"{DATA_FOLDER}/{file_name}.csv")
    data.to_sql(file_name, conn, if_exists='replace', schema='eds')
    result = conn.execute(f'SELECT COUNT(*) FROM [eds].[{file_name}]')
    print(f"{file_name}: {result.fetchall()[0][0]}")
