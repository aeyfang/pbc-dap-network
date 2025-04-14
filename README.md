## Network Analysis Workflow

The analysis involves these key steps:

1. **Data Cleaning** (`data_cleaning.Rmd`):
   - Processes raw DAP data and creates cleaned datasets
   - Generates both unstratified and age-stratified datasets
   - Creates frequency tables for all health conditions
   - Outputs files in `./clean data/` and `./frequency tables/` folders

2. **Data Summary** (`data_summary.Rmd`):
   - Provides descriptive statistics and visualizations
   - Generates plots and tables for demographic information
   - Outputs files in `./summary statistics/` folder

3. **Network Analysis** (`data_analysis.Rmd`):
   - **IMPORTANT**: This script must be run multiple times to generate all networks
   - Set the `analysis_type` variable to one of these options:
     - `"unstrat"` - for the complete, unstratified dataset
     - `"puppy"`, `"young_adult"`, `"mature_adult"`, `"senior"` - for age-stratified analyses
   - For each run, the script will:
     - Fit logistic regression models for each disease
     - Calculate individual disease probabilities
     - Generate comorbidity networks using the Poisson binomial approach
     - Create reference tables for network visualization
   - Outputs for each analysis type are saved in:
     - `./model coefficients/`
     - `./individual stats/`
     - `./pair stats/`
     - `./Cytoscape inputs/`
     - `./reference tables/`

4. **Directed Network Analysis** (`data_directed.Rmd`):
   - Uses temporal information to create directed comorbidity networks
   - Analyzes which disease tends to precede another when both occur
   - Outputs files for directed network visualization

5. **Network Visualization** (using Cytoscape):
   - Import the generated network files from `./Cytoscape inputs/` folder
   - Use reference tables from `./reference tables/` for node and edge annotations
