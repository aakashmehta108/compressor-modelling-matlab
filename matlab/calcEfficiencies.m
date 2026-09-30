function res = calcEfficiencies(data, fluid, superheatK, Vd)
%CALCEFFICIENCIES  Property calculation + volumetric/isentropic efficiencies.
%
%   res = calcEfficiencies(data, 'R134a', 10, 75.4e-6)
%
%   For every operating point:
%     1. Saturation pressures from T_evap / T_cond  (CoolProp).
%     2. Suction state: P_suc, T_suc = T_evap + superheat ->
%        v_suc, h1, s1 (CoolProp).
%     3. Isentropic discharge enthalpy: h2_is = h(P_dis, s1) (CoolProp).
%     4. Pressure ratio  beta = P_dis / P_suc.
%     5. Displacement rate Vd_dot = Vd * N/60,  N = 60*f.
%     6. Volumetric efficiency  eta_v  = m_dot * v_suc / Vd_dot
%        Isentropic efficiency  eta_is = m_dot*(h2is-h1) / W_el
%
%   Returns struct res with fields: beta, fn, eta_v, eta_is (+ N, Vd_dot).

n  = data.n;
TK = 273.15;

beta   = zeros(n,1);
eta_v  = zeros(n,1);
eta_is = zeros(n,1);
fn     = data.f / 50;                 % normalized frequency [-]
N      = 60 * data.f;                 % shaft speed [rpm]
Vd_dot = Vd * N / 60;                 % displacement rate [m^3/s]

for i = 1:n
    Te = data.T_evap(i);  Tc = data.T_cond(i);

    P_suc = getRefrigerantProp('P','T',Te+TK,'Q',0,fluid);   % [Pa]
    P_dis = getRefrigerantProp('P','T',Tc+TK,'Q',0,fluid);   % [Pa]

    T_suc = Te + TK + superheatK;                            % [K]
    v_suc = 1 / getRefrigerantProp('D','P',P_suc,'T',T_suc,fluid); % [m^3/kg]
    h1    = getRefrigerantProp('H','P',P_suc,'T',T_suc,fluid);     % [J/kg]
    s1    = getRefrigerantProp('S','P',P_suc,'T',T_suc,fluid);     % [J/kg/K]
    h2is  = getRefrigerantProp('H','P',P_dis,'S',s1,fluid);        % [J/kg]

    beta(i)   = P_dis / P_suc;
    eta_v(i)  = data.m_dot(i) * v_suc / Vd_dot(i);
    eta_is(i) = data.m_dot(i) * (h2is - h1) / (data.W_el(i)*1000);
end

res.beta = beta;  res.fn = fn;
res.eta_v = eta_v;  res.eta_is = eta_is;
res.N = N;  res.Vd_dot = Vd_dot;

fprintf('Efficiencies calculated for %d points.\n', n);
fprintf('  eta_v  : %.3f ... %.3f\n', min(eta_v),  max(eta_v));
fprintf('  eta_is : %.3f ... %.3f\n', min(eta_is), max(eta_is));
fprintf('  beta   : %.2f ... %.2f\n',  min(beta),   max(beta));
end
