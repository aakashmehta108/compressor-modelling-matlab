%% ENME 811 -- Project 4: Compressor Modelling
%  Variable-speed hermetic reciprocating compressor (R134a)
%
%  This master script runs the full modelling package:
%    1. Data preparation          (loadCompressorData)
%    2. Property calculation      (getRefrigerantProp via CoolProp)
%    3. Efficiency calculation    (calcEfficiencies)
%    4. Regression models         (fitEfficiencyModels)
%    5. Predictions               (predictPerformance)
%    6. Validation + figures      (validateModel)
%
%  Run this file section by section (Ctrl+Enter) or all at once (F5).
%  Requires: CoolProp installed in MATLAB's Python environment (see README).

clear; clc; close all;

%% 0. Settings ---------------------------------------------------------------
fluid      = 'R134a';   % refrigerant
superheatK = 10;        % suction superheat [K]

% Compressor geometry: 40 mm bore x 30 mm stroke, 2 cylinders (typical small
% hermetic reciprocating unit)
d_bore = 0.040; s_stroke = 0.030; z_cyl = 2;
Vd = z_cyl * pi/4 * d_bore^2 * s_stroke;   % displacement volume [m^3/rev]
fprintf('Compressor: hermetic reciprocating, Vd = %.2f cm^3/rev\n', Vd*1e6);

%% 1. Data preparation ---------------------------------------------------------
data = loadCompressorData('compressor_data.csv');

%% 2 + 3. Property calculation & efficiency calculation --------------------------
res = calcEfficiencies(data, fluid, superheatK, Vd);

%% 4. Regression models ----------------------------------------------------------
models = fitEfficiencyModels(res);

%% 5. Predictions at new operating points -----------------------------------------
% Example: two points NOT in the dataset (new temperatures and a new speed)
Te_new = [-7; 2];  Tc_new = [38; 42];  f_new = [45; 55];
[m_new, W_new, eta_v_new, eta_is_new, beta_new] = ...
    predictPerformance(Te_new, Tc_new, f_new, models, fluid, superheatK, Vd);
fprintf('\nPredictions at new operating points:\n');
fprintf(' Te [C] | Tc [C] | f [Hz] | beta | eta_v | eta_is | m_dot [g/s] | W_el [kW]\n');
for i = 1:numel(Te_new)
    fprintf(' %6.1f | %6.1f | %6.0f | %4.2f | %.3f | %.3f  | %10.2f  | %9.3f\n', ...
        Te_new(i), Tc_new(i), f_new(i), beta_new(i), ...
        eta_v_new(i), eta_is_new(i), m_new(i)*1000, W_new(i));
end

%% 6. Validation + figures ----------------------------------------------------------
validateModel(data, res, models, fluid, superheatK, Vd);

fprintf('\nDone.\n');
