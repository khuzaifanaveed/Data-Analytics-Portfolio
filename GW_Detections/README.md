
# 🛰 Impact of Detector Expansion on Gravitational Wave Research Output

## 📌 Overview

This project investigates how gravitational wave (GW) detections and detector network expansion influenced scientific research activity over time.

Using public detection data and publication data from arXiv, the analysis explores whether:

* Detection growth was driven by infrastructure expansion
* Publication output responds to detection activity
* Research expansion is event-driven or structurally sustained

The project combines time-series analysis, regression modeling, and structural phase classification to evaluate both detection dynamics and research output behavior.

---

# 🎯 Research Questions

1. How have gravitational wave detections evolved over time?
2. Did adding detectors significantly increase detection rates?
3. Does GW publication activity respond to detection activity?
4. Is research growth episodic (run-driven) or structurally sustained?
5. Does GW research expand faster than astrophysics overall?

---

# 📊 Data Sources

## 1️⃣ Gravitational Wave Events

* Public GW event catalog
* Detection date extracted from event naming convention
* Observation runs manually structured (O1–O4a)
* Detector count per run included

Processed into monthly data:

* Event Count
* Average Active Detectors
* Cumulative Detections

---

## 2️⃣ arXiv Publication Data

Collected using the arXiv API:

* GW-related papers (`all:gravitational+wave`)
* Astrophysics papers (`cat:astro-ph*`) as control group

For each paper:

* Publication date
* Author count
* Deduplicated ID

Processed into:

* Monthly GW paper counts
* Monthly astrophysics paper counts
* GW Share (GW papers / Astrophysics papers)

---

# 🧠 Methodology

## 1️⃣ Detection Analysis

### Model 1 — Basic OLS

Event Count ~ Avg Detectors + Time Index

Findings:

* Time trend significant
* Detector count not independently significant
* Strong residual autocorrelation detected

---

### Model 2 — Autoregressive Model (AR(1))

Event Count ~ Avg Detectors + Time Index + Lag1

Findings:

* R² improved from 0.11 → 0.676
* Durbin–Watson improved from 0.40 → 2.06
* Strong persistence (Lag1 ≈ 0.80)
* Detector expansion not independently significant

Interpretation:

Detection growth follows gradual structural persistence rather than discrete jumps caused solely by increasing detector count.

---

## 2️⃣ Publication Analysis

### GW Share Trend

GW Share shows a clear upward trend, with significant increases following major detection runs. This suggests that GW research is not only growing in absolute terms but also becoming a larger proportion of the overall astrophysics research landscape.

---

## 🔎 Detection–Publication Correlation Analysis

To assess whether gravitational wave detections influence research output, multiple correlation tests were performed:

1. **Raw correlation (levels)**

   * Moderate positive association (r ≈ 0.36)
   * Likely influenced by shared long-term upward trends

2. **Differenced correlation (month-to-month changes)**

   * Weak and statistically insignificant (r ≈ 0.14)
   * Suggests short-term detection fluctuations do not strongly drive immediate publication changes

3. **Lagged correlation (3-month delay)**

   * No correlation (r ≈ 0.01)
   * Indicates that publication response to detections may be delayed beyond 3 months, or there maybe no direct short-term responsiveness and the publication growth is more structurally driven

4. **Detrended correlation (trend removed)**

   * Weak, borderline significant relationship
   * Indicates much of the observed association is driven by shared structural growth rather than direct short-term responsiveness

While detection activity and publication share are positively associated, much of this relationship reflects long-term structural expansion in gravitational wave research. Evidence for short-run responsiveness is negligible and potentially delayed beyond the 3-month lag tested.

---

### Phase-Based Institutional Model

Each month classified as:

* Baseline
* Active Run
* Post-Run (6 months after run end)

Model:

GW Share ~ Phase_Active + Phase_Post_Run + Time Index

Findings:

* Time trend strongly significant
* Phase effects weak once time trend is controlled
* R² ≈ 0.846

Interpretation:

Research growth appears structurally sustained rather than driven by discrete observation run phases.

---

# 🔍 Key Findings

* Detection counts exhibit strong temporal persistence.
* Detector expansion alone does not independently drive detection growth after controlling for time and persistence.
* GW publication share has grown structurally over time.
* Detection activity correlates with research attention.
* Observation run phases do not produce statistically strong publication spikes once long-term trends are accounted for.

Overall conclusion:

> Gravitational wave research expansion appears driven primarily by sustained structural maturation rather than isolated infrastructure changes or short-term event shocks.

---

# 🛠 Technical Stack

* Python
* pandas
* numpy
* matplotlib
* scipy
* statsmodels
* arXiv API (feedparser)

---

# 📁 Project Structure

```
├── 01 - Data/
│   ├── raw/
│   └── processed/
└── 02 - Notebooks/
    ├── 01_data_collection.ipynb
    |   ├── GW event cleaning
    |   ├── Run assignment
    |   ├── arXiv API collection
    |   └── Monthly aggregation
    |
    └── 02_data_analysis.ipynb
        ├── Detection regressions
        ├── Autocorrelation diagnostics
        ├── Publication share modeling
        ├── Phase classification regression
        └── Interpretation
```

---

# 🚀 Possible Extensions
* Forecasting detection counts
* Interactive dashboard version

---

# 🧾 Final Reflection

This project evaluates the measurable impact of scientific infrastructure expansion on discovery rates and research output.

By integrating detection data with publication dynamics and controlling for field-wide growth, the analysis shows that gravitational wave research expansion reflects sustained structural development rather than isolated event-driven shocks.