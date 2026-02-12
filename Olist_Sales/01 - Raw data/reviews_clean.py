import pandas as pd
import csv

df = pd.read_csv(
    "Olist_Sales/01 - Raw data/olist_order_reviews_dataset.csv",
    engine="python",
    sep=",",
    quotechar='"',
    dtype=str,
    on_bad_lines="skip" 
)

# Strip whitespace from all columns
df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)

print(df.shape)
print(df.head())

# Save clean file
df.to_csv(
    "Olist_Sales/01 - Raw data/olist_order_reviews_clean.csv",
    index=False,
    encoding="utf-8"
)
