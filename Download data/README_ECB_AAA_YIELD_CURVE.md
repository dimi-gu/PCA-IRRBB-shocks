# ECB AAA Zero-Coupon Yield Curve Downloader

A Python/Jupyter workflow for downloading the **euro-area AAA-rated government bond zero-coupon spot curve** from the European Central Bank’s SDMX REST API.

The notebook retrieves daily spot rates across the yield curve, calculates the unpublished **1-month and 2-month tenors** from the ECB’s daily Svensson parameters, validates the calculation against the published 3-month rate, and exports the complete term structure to CSV.

---

## Main Features

- Downloads the ECB euro-area AAA government bond spot curve
- Uses daily business-date observations
- Retrieves each maturity separately to avoid a single missing series stopping the workflow
- Covers maturities from 3 months to 30 years
- Derives 1-month and 2-month spot rates from the ECB Svensson parameters
- Performs a 3-month model-reconstruction sanity check
- Sorts all tenors in maturity order
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

The final output therefore contains up to **27 maturity columns**.

The effective historical series begins on **6 September 2004**, even though the default API request starts on 1 January 2000. The ECB returns only observations available within the requested window.

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

The Svensson zero-coupon spot rate is:

\[
\begin{aligned}
z(T) =\;& \beta_0
+\beta_1\left(\frac{1-e^{-T/\tau_1}}{T/\tau_1}\right) \\
&+\beta_2\left(
\frac{1-e^{-T/\tau_1}}{T/\tau_1}
-e^{-T/\tau_1}
\right) \\
&+\beta_3\left(
\frac{1-e^{-T/\tau_2}}{T/\tau_2}
-e^{-T/\tau_2}
\right)
\end{aligned}
\]

where:

- \(T\) is time to maturity in years;
- \(\beta_0,\ldots,\beta_3\) control the level, slope, and curvature;
- \(\tau_1,\tau_2\) control the decay structure.

The notebook evaluates the function at:

\[
T_{1M}=\frac{1}{12}
\]

\[
T_{2M}=\frac{2}{12}
\]

The daily ECB parameter series are retrieved through the same API and aligned by date before the implied rates are calculated.

Technical notes on the ECB curve methodology:

```text
https://www.ecb.europa.eu/stats/financial_markets_and_interest_rates/euro_area_yield_curves/shared/pdf/technical_notes.pdf
```

---

## Validation Check

To confirm that the Svensson function has been implemented consistently, the notebook reconstructs the three-month spot rate using:

\[
T_{3M}=\frac{3}{12}
\]

It then compares the reconstructed value with the officially published `SR_3M` series.

The saved notebook run reported:

```text
Maximum absolute difference: 0.008528 percentage points
Mean absolute difference:    0.000002 percentage points
```

This check is diagnostic rather than a formal validation of the ECB methodology.

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

| Parameter | Description |
|---|---|
| `START_DATE` | First requested observation date |
| `END_DATE` | Last requested date; defaults to the current date |
| `RATING` | ECB curve/instrument selection |
| `MODEL` | Svensson curve specification |
| `FREQ_AREA_CCY_PROV` | Frequency, area, currency, and provider portion of the series key |
| `OUTPUT_CSV` | Output filename |

The filename date reflects the **request date**, not necessarily the latest observation available from the ECB.

---

## Installation

The notebook was saved with Python 3.13.5.

Install the required third-party packages:

```bash
pip install requests pandas numpy jupyter
```

The remaining imports are part of the Python standard library.

Start Jupyter with:

```bash
jupyter notebook
```

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

The notebook pauses briefly between requests:

```python
time.sleep(0.3)
```

This reduces the request rate sent to the ECB service.

---

## Output

The exported CSV has one row per observation date and one column per maturity:

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

## Error Handling

Each maturity is downloaded independently.

A series is skipped when:

- the HTTP request fails;
- the API returns a non-200 status;
- the response is empty;
- the CSV cannot be parsed;
- the expected `TIME_PERIOD` or `OBS_VALUE` columns are absent.

The workflow raises an error only when no published maturity can be retrieved.

If one or more Svensson parameter series are unavailable, the notebook skips the implied 1M/2M calculation and retains the published maturities.

---

## Important Implementation Notes

### Remove the leading space before `fetch_parameter`

In the uploaded notebook, the cell defining the parameter-download function begins with an accidental leading space:

```python
 def fetch_parameter(...):
```

A clean execution may raise:

```text
IndentationError: unexpected indent
```

It should be:

```python
def fetch_parameter(...):
```

### Run the notebook in order

Some stored execution counts are out of sequence. Restart the kernel and use **Run All** to confirm that the notebook is reproducible from a clean state.

### The CSV is written twice

The notebook first exports the 25 published maturities and later overwrites the same file after adding the implied 1M and 2M columns.

This is harmless when the full notebook completes successfully. If execution stops before the second export, the existing CSV may contain only the published maturities.

### Missing dates are not filled

The output contains ECB observation dates only. It does not create rows for:

- weekends;
- public holidays;
- unavailable business dates.

### No automatic retry or exponential backoff

Failed requests are skipped after one attempt. Temporary network errors, API throttling, or service outages can therefore produce an incomplete curve.

For a production workflow, consider adding:

- retries;
- exponential backoff;
- response logging;
- a final expected-column check.

### Date alignment

The Svensson parameter dataframe is restricted to dates for which all six parameters are present:

```python
params = params.sort_index().dropna()
```

The calculated 1M and 2M series are aligned to the published curve by date. Dates lacking complete parameter data remain missing for those two tenors.

### Compounding convention

The selected ECB curve is based on continuously compounded spot rates. Do not treat the exported values as annually compounded par yields without applying the appropriate transformation.

---

## Potential Extensions

Possible extensions include:

- downloading the all-ratings government curve;
- retrieving instantaneous forward rates;
- supporting alternative ECB curve models;
- adding automatic retries and completeness checks;
- exporting Svensson parameters with the curve;
- converting continuously compounded rates to other conventions;
- plotting historical term structures;
- calculating daily, monthly, or annual yield changes;
- using the curve as input for PCA or IRRBB scenario analysis.

---

## Disclaimer

This project is intended for research, educational, and analytical purposes. It is not investment advice and does not replace official ECB documentation or validated market-data infrastructure.

Users should verify series definitions, units, curve conventions, data completeness, and methodological assumptions before using the output for valuation, risk management, regulatory reporting, or balance-sheet decisions.
