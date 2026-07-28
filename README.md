# PCA based IRRBB shock scenarios

This repository contains a Python/Jupyter workflow for generating and analysing **interest-rate shock scenarios for IRRBB** ICAAP/ECAP frameworks using Principal Component Analysis (PCA).

The notebook applies PCA to historical changes in the ECB euro-area AAA zero-coupon yield curve, identifies extreme historical shocks, compares them with the six regulatory Supervisory Outlier Test (SOT) scenarios, and demonstrates how PCA components can be combined to simulate additional curve shapes.

The repository also contains a short R script [`PCA.R`](/PCA.R) illustrating how the signs of PCA components may differ between R and Python implementations. The R script requires the same input file as the Python/Jupyter notebook.

## Input File

The required yield-curve dataset is already provided in the repository [`Download data`](./Download%20data):

```text
ecb_aaa_spot_yield_curve_2026-07-24.csv
```

The CSV must be stored in the **notebook working directory**. The notebook looks for the file using:

```python
Shocks_Input = "ecb_aaa_spot_yield_curve_2026-07-24.csv"
```

When using a newer dataset, place it in the same working directory and update `Shocks_Input` accordingly.

## Main Features

- Imports and plots the ECB AAA zero-coupon spot curve
- Calculates historical yield-curve changes over a selected period differentiation period
- Applies PCA to the term-structure shifts
- Reports PCA scores, loadings, and explained variance
- Reconstructs historical shocks using the retained components
- Identifies extreme PC observations using the 0.1% and 99.9% quantiles
- Reduces clusters of similar historical shock dates
- Calculates the six BCBS SOT scenarios:
  - Parallel up
  - Parallel down
  - Short-rate up
  - Short-rate down
  - Steepener
  - Flattener
- Compares historical PCA shocks with regulatory SOT shocks
- Simulates additional PCA-based scenarios, including a pure steepener

## Configuration

Select the historical difference period near the beginning of the notebook:

```python
DIFF_PERIOD = "Y"
```

Available values:

| Value | Period |
|---|---|
| `D` | Daily |
| `W` | Weekly |
| `M` | Monthly |
| `Q` | Quarterly |
| `S` | Half-year |
| `Y` | Yearly |

The PCA is configured to retain three components:

```python
N_COMPONENTS = 3
```

The number of Principal Components is adjustable by the user.

## Usage

1. Clone or download the repository.
2. Confirm that the provided CSV is in the notebook working directory.
3. Open `Shocks IRRBB.ipynb`.
4. Review `DIFF_PERIOD` and the other configuration values.
5. Run all cells in order.

## Outputs

The notebook produces:

- historical spot-rate and yield-change charts;
- PCA explained-variance results;
- principal-component score and loading plots;
- PCA reconstruction comparisons;
- historical extreme-shock tables and charts;
- regulatory SOT shock curves;
- historical-versus-regulatory shock comparisons;
- simulated PCA-based curve scenarios.

## Disclaimer

This project is intended for educational, analytical, and model-development purposes. It is not a validated regulatory model and should not be used for IRRBB measurement or reporting without institution-specific calibration, independent validation, and appropriate governance.
