"""
Reference analysis for the hermetic reciprocating compressor model (R134a).
Mirrors the MATLAB scripts step-by-step; results feed the technical report.

Steps: load data -> CoolProp properties -> efficiencies ->
       polynomial fits (eta_v, eta_is vs beta & frequency) ->
       hold-out validation -> plots.
"""
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from CoolProp.CoolProp import PropsSI

REF = "R134a"
SUPERHEAT = 10.0
d, s, z = 0.040, 0.030, 2
Vd = z * np.pi / 4 * d**2 * s          # m^3/rev
FIG = "/home/hatch/workspace/compressor-matlab-project/report/figures/"

df = pd.read_csv("/home/hatch/workspace/compressor-matlab-project/data/compressor_data.csv")

# ---- 1. property + efficiency calculation ---------------------------------
beta, eta_v, eta_is, fn = [], [], [], []
for _, r in df.iterrows():
    Te, Tc, f = r.T_evap_C, r.T_cond_C, r.freq_Hz
    P_suc = PropsSI("P", "T", 273.15 + Te, "Q", 0, REF)
    P_dis = PropsSI("P", "T", 273.15 + Tc, "Q", 0, REF)
    T_suc = 273.15 + Te + SUPERHEAT
    v_suc = 1.0 / PropsSI("D", "P", P_suc, "T", T_suc, REF)
    h1 = PropsSI("H", "P", P_suc, "T", T_suc, REF)
    s1 = PropsSI("S", "P", P_suc, "T", T_suc, REF)
    h2is = PropsSI("H", "P", P_dis, "S", s1, REF)
    b = P_dis / P_suc
    Vd_dot = Vd * (60.0 * f) / 60.0
    ev = r.m_dot_kg_s * v_suc / Vd_dot
    ei = r.m_dot_kg_s * (h2is - h1) / (r.W_el_kW * 1000.0)
    beta.append(b); eta_v.append(ev); eta_is.append(ei); fn.append(f / 50.0)

beta = np.array(beta); eta_v = np.array(eta_v)
eta_is = np.array(eta_is); fn = np.array(fn)

print(f"eta_v  range: {eta_v.min():.4f} - {eta_v.max():.4f}")
print(f"eta_is range: {eta_is.min():.4f} - {eta_is.max():.4f}")

def fit_report(y, yhat, name):
    ss_res = np.sum((y - yhat) ** 2)
    ss_tot = np.sum((y - y.mean()) ** 2)
    R2 = 1 - ss_res / ss_tot
    rmse = np.sqrt(np.mean((y - yhat) ** 2))
    print(f"{name}: R^2 = {R2:.5f}, RMSE = {rmse:.5f}")
    return R2, rmse

# ---- 2. polynomial fits (all data) -----------------------------------------
Xv = np.column_stack([np.ones_like(beta), beta, fn])
a, *_ = np.linalg.lstsq(Xv, eta_v, rcond=None)
eta_v_fit = Xv @ a
print("eta_v  = a0 + a1*beta + a2*fn  ->", np.round(a, 5))
fit_report(eta_v, eta_v_fit, "eta_v fit ")

Xi = np.column_stack([np.ones_like(beta), beta, beta**2, fn, beta * fn])
b_, *_ = np.linalg.lstsq(Xi, eta_is, rcond=None)
eta_is_fit = Xi @ b_
print("eta_is = b0 + b1*beta + b2*beta^2 + b3*fn + b4*beta*fn ->", np.round(b_, 5))
fit_report(eta_is, eta_is_fit, "eta_is fit")

# ---- 3. hold-out validation: train f=30..60, test f=70 ----------------------
tr = df.freq_Hz < 70
Xv_tr = Xv[tr]; Xi_tr = Xi[tr]
a_t, *_ = np.linalg.lstsq(Xv_tr, eta_v[tr], rcond=None)
b_t, *_ = np.linalg.lstsq(Xi_tr, eta_is[tr], rcond=None)

def predict_point(Te, Tc, f, a_c, b_c):
    P_suc = PropsSI("P", "T", 273.15 + Te, "Q", 0, REF)
    P_dis = PropsSI("P", "T", 273.15 + Tc, "Q", 0, REF)
    T_suc = 273.15 + Te + SUPERHEAT
    v_suc = 1.0 / PropsSI("D", "P", P_suc, "T", T_suc, REF)
    h1 = PropsSI("H", "P", P_suc, "T", T_suc, REF)
    s1 = PropsSI("S", "P", P_suc, "T", T_suc, REF)
    h2is = PropsSI("H", "P", P_dis, "S", s1, REF)
    bt, fnt = P_dis / P_suc, f / 50.0
    ev_p = a_c[0] + a_c[1] * bt + a_c[2] * fnt
    ei_p = b_c[0] + b_c[1] * bt + b_c[2] * bt**2 + b_c[3] * fnt + b_c[4] * bt * fnt
    Vd_dot = Vd * f
    m_p = ev_p * Vd_dot / v_suc
    W_p = m_p * (h2is - h1) / ei_p / 1000.0
    return m_p, W_p

te = df[~tr]
m_pred, W_pred = [], []
for _, r in te.iterrows():
    mp, Wp = predict_point(r.T_evap_C, r.T_cond_C, r.freq_Hz, a_t, b_t)
    m_pred.append(mp); W_pred.append(Wp)
m_pred = np.array(m_pred); W_pred = np.array(W_pred)
mape_m = np.mean(np.abs(m_pred - te.m_dot_kg_s.values) / te.m_dot_kg_s.values) * 100
mape_W = np.mean(np.abs(W_pred - te.W_el_kW.values) / te.W_el_kW.values) * 100
print(f"Hold-out (f=70 Hz, n={len(te)}): MAPE m_dot = {mape_m:.2f}%, MAPE W_el = {mape_W:.2f}%")

# in-sample parity with full fit
m_all, W_all = [], []
for _, r in df.iterrows():
    mp, Wp = predict_point(r.T_evap_C, r.T_cond_C, r.freq_Hz, a, b_)
    m_all.append(mp); W_all.append(Wp)
m_all = np.array(m_all); W_all = np.array(W_all)

# ---- 4. plots ----------------------------------------------------------------
plt.rcParams.update({"font.size": 11})
bg = np.linspace(beta.min(), beta.max(), 100)

plt.figure(figsize=(7, 4.6))
for f in sorted(df.freq_Hz.unique()):
    m = df.freq_Hz == f
    plt.scatter(beta[m], eta_v[m], label=f"{int(f)} Hz", s=28)
plt.plot(bg, a[0] + a[1] * bg + a[2] * 1.0, "k-", lw=2, label="Fit (f = 50 Hz)")
plt.xlabel("Pressure ratio  $\\beta = P_{dis}/P_{suc}$  [-]")
plt.ylabel("Volumetric efficiency  $\\eta_v$  [-]")
plt.legend(ncol=3, fontsize=9); plt.grid(alpha=0.3); plt.tight_layout()
plt.savefig(FIG + "eta_v_vs_beta.png", dpi=150); plt.close()

plt.figure(figsize=(7, 4.6))
for f in sorted(df.freq_Hz.unique()):
    m = df.freq_Hz == f
    plt.scatter(beta[m], eta_is[m], label=f"{int(f)} Hz", s=28)
plt.plot(bg, b_[0] + b_[1] * bg + b_[2] * bg**2 + b_[3] * 1.0 + b_[4] * bg * 1.0,
         "k-", lw=2, label="Fit (f = 50 Hz)")
plt.xlabel("Pressure ratio  $\\beta = P_{dis}/P_{suc}$  [-]")
plt.ylabel("Isentropic efficiency  $\\eta_{is}$  [-]")
plt.legend(ncol=3, fontsize=9); plt.grid(alpha=0.3); plt.tight_layout()
plt.savefig(FIG + "eta_is_vs_beta.png", dpi=150); plt.close()

plt.figure(figsize=(5.2, 5.2))
plt.scatter(df.m_dot_kg_s * 1000, np.array(m_all) * 1000, s=28)
lo, hi = (df.m_dot_kg_s.min()) * 1000 * 0.95, (df.m_dot_kg_s.max()) * 1000 * 1.05
plt.plot([lo, hi], [lo, hi], "k--")
plt.xlabel("Measured mass flow rate [g/s]"); plt.ylabel("Predicted mass flow rate [g/s]")
plt.grid(alpha=0.3); plt.axis("equal"); plt.tight_layout()
plt.savefig(FIG + "parity_mdot.png", dpi=150); plt.close()

plt.figure(figsize=(5.2, 5.2))
plt.scatter(df.W_el_kW, W_all, s=28)
lo, hi = df.W_el_kW.min() * 0.95, df.W_el_kW.max() * 1.05
plt.plot([lo, hi], [lo, hi], "k--")
plt.xlabel("Measured power input [kW]"); plt.ylabel("Predicted power input [kW]")
plt.grid(alpha=0.3); plt.axis("equal"); plt.tight_layout()
plt.savefig(FIG + "parity_power.png", dpi=150); plt.close()

print("Figures saved to", FIG)
