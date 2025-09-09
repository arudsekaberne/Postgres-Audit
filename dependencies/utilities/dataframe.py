#####################################################
# Packages                                          #
#####################################################

import csv
import pandas as pd
from typing import Any
from tabulate import tabulate
from dependencies.utilities.postgre import PGConnection


#####################################################
# Class                                             #
#####################################################


class Dataframe:

    """A utility class for handling data operations with Pandas DataFrames."""


    # Class Variable
    DB_UTIL: PGConnection  = PGConnection()


    @classmethod
    def select_query_all(cls, query: str) -> pd.DataFrame:
        
        """
        Fetches a table records into a pandas DataFrame using SQLAlchemy engine and context manager.
        """
        
        with cls.DB_UTIL as (_, connection):
            return pd.read_sql(sql = query, con = connection)
        

    @classmethod
    def select_query_one(cls, query: str) -> Any:
        
        """
        Fetches first cell table records into a pandas DataFrame using SQLAlchemy engine and context manager.
        """
        
        return cls.select_query_all(query).values[0][0]
    

    @classmethod
    def write_to_table(cls, df: pd.DataFrame, schema_name: str, table_name: str, mode: str = "truncate_load") -> None:

        """
        Writes a Pandas DataFrame to a PostgreSQL table using SQLAlchemy.
        """

        with cls.DB_UTIL as (engine, _):

            if mode == "truncate_load":
                cls.DB_UTIL.execute_sql(f"TRUNCATE TABLE {schema_name}.{table_name};")

            df.to_sql(
                con = engine,
                schema = schema_name, name = table_name, index = False,
                if_exists = "append", method = "multi", chunksize = 10_000
            )


    @classmethod
    def parse_csv_value(cls, value):

        """
        Parses a single CSV-formatted string into a list of values.
        """
        
        # return pd.read_csv(io.StringIO(value), header = None, quotechar = '"').iloc[0].tolist()
        return next(csv.reader([value], quotechar='"'))


    @staticmethod
    def print(df: pd.DataFrame) -> None:
        
        """
        Pretty print a pandas DataFrame using the tabulate library.
        """

        # Apply repr() to every element so that pd.NA, None, NaN show as literal.

        safe_df: pd.DataFrame = df.applymap(repr) # type: ignore

        print(f"\n{tabulate(safe_df, headers='keys', tablefmt='psql', showindex=False)}") # type: ignore