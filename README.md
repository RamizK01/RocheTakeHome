# RocheTakeHome
Take home assignment for Roche ADS Programmer Role

## Repository Structure

```
RocheTakeHome/
├── 📄 README.md                         # Main documentation
├── 📄 utils.R                           # Shared R utilities
├── 📄 renv.lock                         # R environment lock file
│
├── 📁 question_1_sdtm/                  # SDTM Domain Creation (SAS)
│   ├── 01_create_ds_domain.R            # Create DS domain dataset
│   ├── sdtm_ct.csv                      # Controlled terminology
│   ├── DS_20260211_163515.Rds           # Output: DS domain
│   └── q1_log_20260211_163457.txt       # Execution log
│
├── 📁 question_2_adam/                  # ADaM Dataset Creation
│   ├── create_adsl.R                    # Create ADSL (Subject-Level) dataset
│   ├── ADSL_20260211_185452.Rds         # Output: ADSL dataset
│   └── q2_log_20260211_185449.txt       # Execution log
│
├── 📁 question_3_tlg/                   # Tables, Listings & Graphs
│   ├── 01_create_ae_summary_table.R     # Create adverse events summary table
│   ├── 02_create_visualizations.R       # Create visualizations
│   ├── 📁 summary_table/                # Table outputs
│   │   ├── adae_summary_20260211_213448.pdf
│   │   └── q3_viz_log_20260211_213444.txt
│   ├── 📁 visualizations/               # Plot outputs
│   │   ├── freq_plot_20260211_213513.png
│   │   ├── severity_plot_20260211_213448.png
│   │   └── q3_plots_log_20260211_213512.txt
│
├── 📁 question_4_llm/                   # Clinical AI Assistant
│   ├── 🐍 clin_assistant.py             # Main LLM-based agent
│   ├── 📓 example_queries.ipynb         # Interactive examples (3 queries)
│   ├── ae.csv                           # Adverse events input data
│   ├── environment.yml                  # Conda environment definition
│   ├── .env.example                     # API key template
│   └── __pycache__/                     # Python cache
│
└── 📁 renv/                             # R environment configuration
    ├── activate.R                       # Environment activation script
    └── settings.json                    # Environment settings
```

### 📋 Directory Guide

| Directory | Purpose | Language |
|-----------|---------|----------|
| `question_1_sdtm/` | SDTM domain creation from clinical trial data | R |
| `question_2_adam/` | ADaM dataset creation for statistical analysis | R |
| `question_3_tlg/` | Tables, Listings, and Graphs for reporting | R |
| `question_4_llm/` | AI-powered adverse events data query agent | Python |
| `renv/` | R dependency management | R |

### 🔧 Key Files

- **clin_assistant.py** - Clinical Trial Data Agent with LLM integration
- **example_queries.ipynb** - Interactive notebook with 3 example queries
- **environment.yml** - Conda dependencies for Python components
- **utils.R** - Shared R utility functions
- **renv.lock** - Locked R package versions for reproducibility

