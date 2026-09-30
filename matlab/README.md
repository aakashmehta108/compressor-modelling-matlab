# ENME 811 – Project 4: Compressor Modelling (MATLAB)

Variable-speed hermetic reciprocating compressor model (R134a).
The model computes volumetric and isentropic efficiencies from performance
data + refrigerant properties (CoolProp), then fits polynomial correlations
in pressure ratio and compressor frequency, and validates predictions on
unseen operating points.

## Files

| File | Purpose |
|---|---|
| `main_compressor_model.m` | Master script – runs the whole package |
| `loadCompressorData.m` | 1. Data preparation – loads & checks the dataset |
| `getRefrigerantProp.m` | 2. Property calculation – CoolProp wrapper |
| `calcEfficiencies.m` | 3. Efficiency calculation – eta_v, eta_is, beta |
| `fitEfficiencyModels.m` | 4. Regression – polynomial fits, R², RMSE |
| `predictPerformance.m` | 5. Predictions at new operating points |
| `validateModel.m` | 6. Validation (hold-out) + diagnostic figures |
| `compressor_data.csv` | 60-point representative performance dataset |

## Setup (one time)

The code calls CoolProp through MATLAB's Python interface (as taught in Lecture 1):

1. In MATLAB, run `pyversion` to see the linked Python (install Python 3 if none).
2. Install CoolProp into that Python:
   ```matlab
   [v,e] = pyversion; system([e, ' -m pip install --user -U CoolProp'])
   ```
3. Test: `py.CoolProp.CoolProp.PropsSI('T','P',1e5,'Q',0,'Water')` should
   return ≈ 372.76 (Kelvin).

## Run

1. Open MATLAB, `cd` to this folder.
2. Run `main_compressor_model.m` (F5), or section by section (Ctrl+Enter).
3. Read the printed coefficients, R²/RMSE and validation MAPE; four figures pop up.

## Model summary

- Compressor: hermetic reciprocating, 40 mm bore × 30 mm stroke × 2 cylinders,
  Vd = 75.40 cm³/rev, N = 60·f rpm, f = 30–70 Hz.
- Suction superheat 10 K. Efficiencies:
  - eta_v  = a0 + a1·beta + a2·fn
  - eta_is = b0 + b1·beta + b2·beta² + b3·fn + b4·beta·fn
  - beta = P_dis/P_suc, fn = f/50.

## Notes

- `compressor_data.csv` is a representative manufacturer-style dataset
  (60 operating points: T_evap −10…5 °C, T_cond 35…45 °C, f 30…70 Hz).
  Replace it with real Bitzer/lab data in the same column format to model a
  specific compressor – no code changes needed.
- Specific volume is computed as 1/D (density) – `PropsSI('V',...)` with P,T
  inputs is unreliable in some CoolProp builds.
