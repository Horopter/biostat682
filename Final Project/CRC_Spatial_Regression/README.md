# BIOSTAT 682 Final Project: Bayesian Spatial Regression Analysis of Colorectal Cancer Tissue Imaging Data

## Project Overview

This project conducts a Bayesian spatial regression analysis on multiplexed tissue imaging data from colorectal cancer (CRC) samples. The analysis models the relationship between immune checkpoint markers and spatial coordinates, accounting for spatial correlation in the tissue microenvironment.

## Dataset

The dataset (`CRC_data_55A.csv`) contains:
- **2,874 cells** from a colorectal cancer tissue sample
- **Spatial coordinates** (cx, cy) for each cell
- **20 protein markers** including:
  - Immune checkpoint markers (PD-1, LAG-3, VISTA, ICOS)
  - T cell markers (CD2, CD5, CD25)
  - Macrophage markers (CD68, CD11b)
  - Other immune and signaling markers

## Research Question

How do immune checkpoint markers (PD-1, LAG-3) relate to other immune cell markers and spatial location in the tumor microenvironment? We model PD-1 expression as a function of other markers and spatial coordinates using a Bayesian spatial regression framework.

## Model Specification

### Likelihood
\[
y_i \sim \mathcal{N}(\mu_i, \sigma^2)
\]

where
\[
\mu_i = \beta_0 + \sum_{j=1}^{p} \beta_j x_{ij} + f(s_i)
\]

- \(y_i\): PD-1 expression for cell \(i\)
- \(x_{ij}\): Expression of marker \(j\) for cell \(i\)
- \(s_i = (cx_i, cy_i)\): Spatial coordinates
- \(f(s_i)\): Spatial random effect

### Prior Distributions

- **Regression coefficients**: \(\beta_j \sim \mathcal{N}(0, \tau^2)\) with \(\tau^2 \sim \text{InverseGamma}(2, 1)\)
- **Intercept**: \(\beta_0 \sim \mathcal{N}(0, 10^2)\)
- **Error variance**: \(\sigma^2 \sim \text{InverseGamma}(2, 1)\)
- **Spatial effect**: Gaussian Process with Matern covariance
  - Range parameter: \(\phi \sim \text{Gamma}(2, 0.1)\)
  - Variance: \(\sigma_s^2 \sim \text{InverseGamma}(2, 1)\)

## File Structure

```
CRC_Spatial_Regression/
├── README.md                    # This file
├── requirements.txt             # Python dependencies
├── analysis.ipynb              # Main analysis notebook
├── data/
│   └── CRC_data_55A.csv        # Dataset (symlink to original)
└── report/
    ├── report.pdf              # Final report (generated)
    └── figures/                # Generated figures
```

## Running the Analysis

### Prerequisites

1. Python 3.8 or higher
2. Required packages (see `requirements.txt`)

### Installation

```bash
# Create virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Execution

1. **Run the analysis notebook**:
   ```bash
   jupyter notebook analysis.ipynb
   ```
   Or using JupyterLab:
   ```bash
   jupyter lab analysis.ipynb
   ```

2. **Expected runtime**: 
   - Data loading and preprocessing: ~30 seconds
   - MCMC sampling (4 chains, 2000 draws each): ~10-15 minutes
   - Post-processing and diagnostics: ~2 minutes

3. **Outputs**:
   - Figures saved to `report/figures/`
   - Posterior samples saved for reproducibility
   - Summary statistics printed in notebook

## Reproducibility

- Random seed set to `42` for reproducibility
- All MCMC chains use the same seed
- Posterior samples can be saved/loaded for consistent results

## Convergence Diagnostics

The analysis includes:
- **R-hat statistics** (target < 1.01)
- **Effective sample size (ESS)** (target > 400 per chain)
- **Monte Carlo standard error (MCSE)** relative to posterior SD
- **Geweke diagnostic** for stationarity
- **Posterior predictive checks**

## Results Summary

Key findings (see full report for details):
- PD-1 expression is positively associated with T cell markers (CD2, CD5)
- Spatial correlation is significant, indicating clustering of immune cells
- Posterior credible intervals for key coefficients exclude zero
- Model fit assessed via posterior predictive checks

## Author

Santosh Desai
BIOSTAT 682, Fall 2025
University of Michigan

## References

See final report for complete references.

