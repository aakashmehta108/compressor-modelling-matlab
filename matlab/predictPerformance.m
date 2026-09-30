function [m_dot, W_el, eta_v, eta_is, beta] = ...
    predictPerformance(T_evap, T_cond, f, models, fluid, superheatK, Vd)
%PREDICTPERFORMANCE  Predict compressor performance at new operating points.
%
%   [m_dot, W_el] = predictPerformance(T_evap, T_cond, f, models, ...)
%
%   Inputs (scalars or vectors of equal length):
%     T_evap, T_cond : evaporating / condensing temperatures [degC]
%     f              : compressor frequency [Hz]
%   Uses the fitted polynomial models to get eta_v, eta_is, then:
%     m_dot = eta_v * Vd_dot / v_suc
%     W_el  = m_dot * (h2is - h1) / eta_is
%
%   Example:
%     [m, W] = predictPerformance(-5, 40, 55, models, 'R134a', 10, 75.4e-6);

T_evap = T_evap(:);  T_cond = T_cond(:);  f = f(:);
n  = numel(T_evap);
TK = 273.15;

m_dot = zeros(n,1); W_el = zeros(n,1);
eta_v = zeros(n,1); eta_is = zeros(n,1); beta = zeros(n,1);

for i = 1:n
    P_suc = getRefrigerantProp('P','T',T_evap(i)+TK,'Q',0,fluid);
    P_dis = getRefrigerantProp('P','T',T_cond(i)+TK,'Q',0,fluid);
    T_suc = T_evap(i) + TK + superheatK;
    v_suc = 1 / getRefrigerantProp('D','P',P_suc,'T',T_suc,fluid);
    h1    = getRefrigerantProp('H','P',P_suc,'T',T_suc,fluid);
    s1    = getRefrigerantProp('S','P',P_suc,'T',T_suc,fluid);
    h2is  = getRefrigerantProp('H','P',P_dis,'S',s1,fluid);

    b  = P_dis / P_suc;
    fn = f(i) / 50;
    a  = models.a;  bb = models.b;

    ev = a(1) + a(2)*b + a(3)*fn;
    ei = bb(1) + bb(2)*b + bb(3)*b^2 + bb(4)*fn + bb(5)*b*fn;

    Vd_dot  = Vd * f(i);                 % Vd*N/60 with N = 60*f
    m_dot(i) = ev * Vd_dot / v_suc;      % [kg/s]
    W_el(i)  = m_dot(i)*(h2is - h1)/ei/1000;  % [kW]

    eta_v(i) = ev;  eta_is(i) = ei;  beta(i) = b;
end
end
