# ECB AAA Zero-Coupon Yield Curve Downloader

A Python/Jupyter workflow for downloading the **euro-area AAA-rated government bond zero-coupon spot curve** from the European Central Bank’s SDMX REST API.

The notebook retrieves daily spot rates across the yield curve, calculates the unpublished **1-month and 2-month tenors** from the ECB’s daily Svensson parameters, validates the calculation against the published 3-month rate, and exports the complete term structure to CSV.

**User needs to run this notebook only once**. The exported CSV is automatically saved in the working directory and is read by "[PCA-IRRBB-shocks](../Shocks%20IRRBB.ipynb)". If user needs an updated curve, he must re-run this notebook.

---

## Main Features

- Downloads the ECB euro-area AAA government bond spot curve
- Uses daily business-date observations
- Covers maturities from 3 months to 30 years
- Derives implied 1-month and 2-month spot rates from the ECB Svensson parameters
- Exports one wide CSV file with dates as rows and maturities as columns
- Automatically includes the current date in the output filename

---

## Data Source

The notebook uses the ECB Data Portal SDMX API:

```text
https://data-api.ecb.europa.eu/service/data/YC/
```

The yield-curve series follow this key structure:

```text
B.U2.EUR.4F.G_N_A.SV_C_YM.SR_<maturity>
```

| Code | Meaning |
|---|---|
| `B` | Daily frequency / business-week observations |
| `U2` | Euro area, changing composition |
| `EUR` | Euro |
| `4F` | ECB as financial-market data provider |
| `G_N_A` | Nominal government bonds issued by AAA-rated entities |
| `SV_C_YM` | Svensson model, continuously compounded, yield-error minimisation |
| `SR_<maturity>` | Zero-coupon spot rate for the selected maturity |

The notebook is configured for the **AAA-rated curve**. To request the all-ratings curve, the relevant ECB rating/instrument code must be changed.

ECB yield-curve information:

```text
https://www.ecb.europa.eu/stats/financial_markets_and_interest_rates/euro_area_yield_curves/html/index.en.html
```

---

## Maturity Coverage

The notebook requests 25 published spot-rate maturities:

```text
3M, 4M, 5M, 6M, 7M, 8M, 9M, 10M, 11M,
1Y, 2Y, 3Y, 4Y, 5Y, 6Y, 7Y, 8Y, 9Y, 10Y,
12Y, 15Y, 18Y, 20Y, 25Y, 30Y
```

It then adds two model-implied maturities:

```text
1M, 2M
```

The final output therefore contains **27 maturity tenors**.

The effective historical series begins on **6 September 2004** up to the date of the script execution.

---

## Svensson-Implied 1M and 2M Rates

The ECB publishes the AAA spot curve from three months onward. The notebook derives the missing one-month and two-month tenors using the ECB’s daily Svensson parameters:

```text
BETA0
BETA1
BETA2
BETA3
TAU1
TAU2
```
The daily ECB parameter series are retrieved through the same API and aligned by date before the implied rates are calculated.

Technical notes on the ECB curve methodology:

```text
https://www.ecb.europa.eu/stats/financial_markets_and_interest_rates/euro_area_yield_curves/shared/pdf/technical_notes.pdf
```
---

## Configuration

The main settings are defined near the beginning of the notebook:

```python
BASE_URL = "https://data-api.ecb.europa.eu/service/data/YC/"
START_DATE = "2000-01-01"
END_DATE = dt.date.today().isoformat()

RATING = "G_N_A"
MODEL = "SV_C_YM"
FREQ_AREA_CCY_PROV = "B.U2.EUR.4F"

OUTPUT_CSV = f"ecb_aaa_spot_yield_curve_{END_DATE}.csv"
```
The output file is saved in the notebook's working directory.

| Parameter | Description |
|---|---|
| `START_DATE` | First requested observation date |
| `END_DATE` | Last requested date; defaults to the current date |
| `RATING` | ECB curve/instrument selection |
| `MODEL` | Svensson curve specification |
| `FREQ_AREA_CCY_PROV` | Frequency, area, currency, and provider portion of the series key |
| `OUTPUT_CSV` | Output filename |

---

## Usage

1. Clone or download the repository.
2. Open the notebook in Jupyter.
3. Review the configuration and maturity list.
4. Run the cells from top to bottom.
5. Wait for the ECB series and Svensson parameters to download.
6. Review the 3M sanity-check result.
7. Locate the generated CSV in the notebook’s working directory.

An internet connection is required.

---

## Output

The exported CSV has one row per observation date and 27 maturity columns:

| Date | 1M | 2M | 3M | ... | 10Y | ... | 30Y |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2004-09-06 | 1.976563 | 2.005252 | 2.034172 | ... | 4.209220 | ... | 4.988680 |
| 2004-09-07 | 1.974783 | 2.007910 | 2.040893 | ... | 4.211... | ... | 4.98... |

The values are written as returned or calculated by the notebook. No percentage-to-decimal conversion is applied.

Example filename:

```text
ecb_aaa_spot_yield_curve_2026-07-24.csv
```
---

## Saved Notebook Result

The saved execution produced:

```text
5,592 daily rows
27 maturity columns
Observation period: 2004-09-06 to 2026-07-22
```
The exact number of rows and latest date will change as new ECB observations become available.

---

## Disclaimer

This project is intended for research, educational, and analytical purposes. It is not investment advice and does not replace official ECB documentation or validated market-data infrastructure.

Users should verify series definitions, units, curve conventions, data completeness, and methodological assumptions before using the output for valuation, risk management, regulatory reporting, or balance-sheet decisions.

