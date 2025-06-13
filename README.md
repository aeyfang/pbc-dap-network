# Dog Aging Project Comorbidity Network Analysis

This repository contains the code used to analyze comorbidity networks in companion dogs using data from the Dog Aging Project (DAP). The analysis creates both undirected and time-directed comorbidity networks, adjusting for demographic covariates using a novel Poisson binomial approach.

## Overview

The analysis pipeline processes owner-reported health data from the Dog Aging Project to identify statistically significant associations between health conditions. The methods use a Poisson binomial approach to account for individual-level covariates (age, sex, sterilization status, breed background, and weight) without requiring stratification, enabling more robust comorbidity detection than traditional methods.

## Data Sources

The analysis requires the following input data from the Dog Aging Project:
- `DAP_2021_HLES_health_conditions_v1.0.RData`: Health condition data
- `DAP_2021_HLES_cancer_conditions_v1.0.RData`: Cancer condition data  
- `DAP_2021_HLES_dog_owner_v1.0.RData`: Dog and owner demographic data
- `diseaseCodes.csv`: Mapping file connecting disease codes to names and categories

*Note: Access to the DAP data requires approval through [dogagingproject.org/data-access](https://dogagingproject.org/data-access)*

## Directory Structure

The code automatically creates the following organized directory structure:

```
├── data/
│   ├── clean/                 # Cleaned datasets (stratified and unstratified)
│   └── frequencies/           # Disease frequency tables
├── results/
│   ├── models/                # Logistic regression coefficients and probabilities
│   ├── networks/              # Network edge lists and attributes
│   └── statistics/            # Summary statistics and analysis results
└── outputs/
    ├── figures/               # Publication-ready figures and plots
    └── tables/                # Formatted tables for manuscripts
```

## Analysis Pipeline

The code consists of six main R Markdown scripts that should be executed in the following order:

### 1. `data_cleaning.Rmd`
**Purpose**: Data preprocessing and quality control
- Processes raw DAP data files
- Filters health conditions by prevalence (≥60 dogs)
- Consolidates duplicate conditions (e.g., IVDD, laryngeal paralysis)
- Stratifies data by dog life stage (puppy, young adult, mature adult, senior)
- Creates disease frequency tables and crosswalk mappings
- Generates supplementary tables (S1a, S1b)

**Key Outputs**:
- `cleaned_unstrat.csv`: Main analysis dataset
- `cleaned_{lifestage}.csv`: Age-stratified datasets
- `disease_frequencies_{dataset}.csv`: Disease prevalence tables

### 2. `undirected_network_analysis.Rmd`
**Purpose**: Core comorbidity network analysis using Poisson binomial approach
- Fits logistic regression models for each health condition
- Calculates individualized disease probabilities accounting for demographics
- Identifies significant comorbidity pairs using statistical testing
- Applies multiple testing correction (Bonferroni)
- Creates network edge lists for visualization

**Key Features**:
- Must be run separately for each dataset (`analysis_type` parameter)
- Supports both unstratified and age-stratified analyses
- Uses parallel processing for computational efficiency

**Key Outputs**:
- `significant_pairs_{dataset}.csv`: Network edge lists
- `probability_{dataset}.csv`: Individual disease probabilities
- `coef_and_pvalues_{dataset}.csv`: Regression model results

### 3. `directed_network_analysis.Rmd`
**Purpose**: Temporal relationship analysis
- Analyzes time-directed comorbidity relationships
- Implements temporal extension of Poisson binomial approach
- Uses sliding window analysis (configurable: 6, 12, 24 months)
- Processes medical history completeness and record length
- Determines which conditions tend to precede others

**Key Outputs**:
- `significant_pairs_directed_{window}m.csv`: Directed network edges
- `diagnosis_date_data.csv`: Medical history analysis
- Temporal relationship statistics

### 4. `result_analysis.Rmd`
**Purpose**: Advanced network analysis and comparative studies
- Compares breed-specific disease prevalence (purebred vs. mixed)
- Analyzes network overlap between age groups
- Fits and compares degree distributions (power law vs. exponential)
- Calculates comprehensive network centrality measures
- Identifies age-specific and shared comorbidity patterns

**Key Outputs**:
- `network_overlap_matrix.csv`: Cross-age network comparisons
- `breed_disease_associations_full.csv`: Breed risk analysis
- `network_topology_metrics.csv`: Network structural properties
- Degree distribution analysis and statistical tests

### 5. `data_summary.Rmd`  
**Purpose**: Descriptive statistics and demographic analysis
- Generates comprehensive demographic summary tables (Table 1)
- Creates age and weight distribution histograms
- Analyzes disease category distributions
- Produces top 20 most common diseases visualization
- Examines distribution of disease counts per dog
- Creates Figure 1 (study overview) including medical history boxplot

**Dependencies**: Requires `diagnosis_date_data.csv` from `directed_network_analysis.Rmd`

**Key Outputs**:
- `Figure_1_study_overview.tiff`: Main demographic figure
- Demographic summary tables and histograms

### 6. `network_visualization.Rmd`
**Purpose**: Publication-ready network visualizations
- Creates main undirected network with strategic node collapsing
- Generates age-stratified network visualizations
- Produces directed network plots with temporal arrows
- Creates network overlap heatmaps
- Combines multiple plots into publication figures

**Dependencies**: Requires outputs from all previous scripts

**Key Features**:
- Consistent color schemes and styling across all plots
- Automated node collapsing for visual clarity
- Highlighted edges for manuscript discussion
- Multiple output formats (PNG, TIFF)

**Key Outputs**:
- `final_network_layout.tiff`: Main undirected network figure
- `combined_2x2_with_heatmap_cowplot_legend.tiff`: Age comparison figure
- `combined_directed.tiff`: Temporal relationship figure

## Dependencies

### Required R Packages
```r
# Core data manipulation and analysis
library(tidyverse)      # Data manipulation and visualization
library(lubridate)      # Date handling
library(haven)          # Reading SPSS/SAS data
library(fastDummies)    # Creating dummy variables
library(miceadds)       # Loading RData files

# Statistical modeling and parallel processing  
library(caret)          # Statistical modeling
library(furrr)          # Parallel processing
library(poweRlaw)       # Distribution fitting
library(fitdistrplus)   # Distribution analysis

# Network analysis and visualization
library(igraph)         # Network analysis
library(ggraph)         # Grammar of graphics for networks
library(tidygraph)      # Tidy graph data structures

# Table creation and file handling
library(gt)             # Table formatting
library(gtsummary)      # Summary tables
library(readxl)         # Excel file reading
library(writexl)        # Excel file writing

# Plotting and visualization
library(RColorBrewer)   # Color palettes
library(cowplot)        # Plot composition
library(patchwork)      # Additional plot layout
library(ggforce)        # Extended ggplot functionality
```

## Citation

If you use this code in your research, please cite the associated publication and acknowledge the Dog Aging Project for data access.

## Support

For questions about the analysis methods or code implementation, please refer to the detailed comments within each script or contact the corresponding author of the associated publication.
