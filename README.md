# Variable-Speed Hermetic Reciprocating Compressor — MATLAB Model

MATLAB modelling package for a variable-speed hermetic reciprocating
compressor (R134a), built for **ENME 811 – Project 4: Compressor Modelling**.

The model takes compressor performance data (mass flow rate and electrical
power input over a grid of operating points) plus refrigerant properties
from **CoolProp**, determines the **volumetric** and **isentropic**
efficiencies, and fits **polynomial correlations** in pressure ratio and
compressor frequency. A hold-out validation and prediction demo are included.

## Results (representative 60-point dataset)

| Model | R² | RMSE |
|---|---|---|
| η_v = a0 + a1·β + a2·fn | 0.989 | 0.0048 |
| η_is = b0 + b1·β + b2·β² + b3·fn + b4·β·fn | 0.968 | 0.0057 |

Hold-out validation on unseen 70 Hz data: MAPE < 0.6 % for mass flow rate
and power input.

## Quick start

1. Install CoolProp in MATLAB's Python environment (one time):
   ```matlab
   [v,e] = pyversion; system([e, ' -m pip install --user -U CoolProp'])
   ```
2. Open MATLAB in the `matlab/` folder and run `main_compressor_model.m` (F5).

See [`matlab/README.md`](matlab/README.md) for full setup and file descriptions,
and [`report/technical_report.pdf`](report/technical_report.pdf) for the
complete technical report.

## Repository layout

```
matlab/                  MATLAB package (7 .m files + dataset)
  main_compressor_model.m   master script – runs everything
  loadCompressorData.m      data preparation
  getRefrigerantProp.m      CoolProp property wrapper
  calcEfficiencies.m        eta_v / eta_is calculation
  fitEfficiencyModels.m     polynomial regression (R², RMSE)
  predictPerformance.m      predictions at new operating points
  validateModel.m           hold-out validation + figures
  compressor_data.csv       60-point performance dataset
data/
  generate_data.py         dataset generator (CoolProp, documented)
  reference_analysis.py    Python mirror of the MATLAB analysis
report/
  technical_report.pdf     full technical report (9 pages)
  technical_report.md/.docx  report sources
```

## Compressor specification

40 mm bore × 30 mm stroke × 2 cylinders (Vd = 75.40 cm³/rev),
N = 60·f rpm, f = 30–70 Hz, 10 K suction superheat.
