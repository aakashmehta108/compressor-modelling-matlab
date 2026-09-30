"""
Generate a representative manufacturer-style performance dataset for a
variable-speed hermetic reciprocating compressor (R134a).

The dataset mimics what Bitzer's selection software (or a lab test rig)
would report: for each operating point (evaporating temp, condensing temp,
compressor frequency) it lists the measured refrigerant mass flow rate and
electrical power input. All thermodynamic properties are REAL (CoolProp).

True (hidden) efficiency correlations used to synthesize the "measurements":
    eta_v  = 0.98 - 0.050*beta + 0.010*(fn-1) - 0.030*(fn-1)^2
    eta_is = 0.72 - 0.015*(beta-3) - 0.008*(beta-3)^2 - 0.020*(fn-1)^2
where beta = P_dis/P_suc (pressure ratio) and fn = f/50 (normalized frequency).
Small Gaussian noise is added to mimic measurement uncertainty.

Compressor geometry (typical small hermetic reciprocating unit):
    bore d = 40 mm, stroke s = 30 mm, z = 2 cylinders
    Vd = z * pi/4 * d^2 * s  (per revolution)
    N  = 60 * f  (rpm, 2-pole motor, slip neglected)
"""
import numpy as np
import pandas as pd
from CoolProp.CoolProp import PropsSI

REF = "R134a"
RNG = np.random.default_rng(42)

# ---- compressor geometry -------------------------------------------------
d = 0.040          # bore [m]
s = 0.030          # stroke [m]
z = 2              # cylinders
Vd = z * np.pi / 4 * d**2 * s      # displacement volume per rev [m^3]

SUPERHEAT = 10.0   # suction superheat [K]

# ---- operating grid ------------------------------------------------------
T_evap = [-10, -5, 0, 5]        # [degC]
T_cond = [35, 40, 45]           # [degC]
freqs  = [30, 40, 50, 60, 70]   # [Hz]

rows = []
pid = 0
for Te in T_evap:
    for Tc in T_cond:
        P_suc = PropsSI("P", "T", 273.15 + Te, "Q", 0, REF)          # [Pa]
        P_dis = PropsSI("P", "T", 273.15 + Tc, "Q", 0, REF)          # [Pa]
        T_suc = 273.15 + Te + SUPERHEAT
        # NOTE: CoolProp 8.0.0 returns a wrong value for PropsSI('V',...) with
        # P,T inputs on some states, so specific volume is obtained as 1/D.
        v_suc = 1.0 / PropsSI("D", "P", P_suc, "T", T_suc, REF)      # [m^3/kg]
        h1 = PropsSI("H", "P", P_suc, "T", T_suc, REF)               # [J/kg]
        s1 = PropsSI("S", "P", P_suc, "T", T_suc, REF)               # [J/kg/K]
        h2is = PropsSI("H", "P", P_dis, "S", s1, REF)                # [J/kg]
        beta = P_dis / P_suc
        for f in freqs:
            N = 60.0 * f                                            # [rpm]
            Vd_dot = Vd * N / 60.0                                  # [m^3/s]
            fn = f / 50.0
            # hidden true efficiencies
            eta_v_true = 0.98 - 0.050 * beta + 0.010 * (fn - 1) - 0.030 * (fn - 1) ** 2
            eta_is_true = (0.72 - 0.015 * (beta - 3) - 0.008 * (beta - 3) ** 2
                           - 0.020 * (fn - 1) ** 2)
            m_dot = eta_v_true * Vd_dot / v_suc                      # [kg/s]
            W_el = m_dot * (h2is - h1) / eta_is_true / 1000.0        # [kW]
            # measurement noise
            m_dot_m = m_dot * (1 + RNG.normal(0, 0.008))
            W_el_m = W_el * (1 + RNG.normal(0, 0.010))
            pid += 1
            rows.append(dict(point_id=pid, T_evap_C=Te, T_cond_C=Tc, freq_Hz=f,
                             P_suc_bar=P_suc / 1e5, P_dis_bar=P_dis / 1e5,
                             m_dot_kg_s=m_dot_m, W_el_kW=W_el_m))

df = pd.DataFrame(rows)
df.to_csv("/home/hatch/workspace/compressor-matlab-project/data/compressor_data.csv",
          index=False)
print(f"Wrote {len(df)} operating points")
print(f"Vd = {Vd*1e6:.2f} cm^3/rev")
print(df.describe().round(4).to_string())
