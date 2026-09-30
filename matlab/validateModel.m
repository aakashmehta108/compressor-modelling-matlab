function validateModel(data, res, models, fluid, superheatK, Vd)
%VALIDATEMODEL  Hold-out validation + diagnostic plots.
%
%   validateModel(data, res, models, fluid, superheatK, Vd)
%
%   Trains the polynomial models on f = 30..60 Hz, tests on the unseen
%   f = 70 Hz points, and reports MAPE for mass flow rate and power input.
%   Produces four figures: eta_v vs beta, eta_is vs beta, and two parity plots.

% --- hold-out split ---------------------------------------------------------
isTest  = data.f == 70;
isTrain = ~isTest;
fprintf('\nValidation: train on %d points (30-60 Hz), test on %d points (70 Hz).\n', ...
    sum(isTrain), sum(isTest));

Xv = [ones(data.n,1), res.beta, res.fn];
Xi = [ones(data.n,1), res.beta, res.beta.^2, res.fn, res.beta.*res.fn];
a_t = Xv(isTrain,:) \ res.eta_v(isTrain);
b_t = Xi(isTrain,:) \ res.eta_is(isTrain);
models_t.a = a_t;  models_t.b = b_t;

[m_p, W_p] = predictPerformance(data.T_evap(isTest), data.T_cond(isTest), ...
    data.f(isTest), models_t, fluid, superheatK, Vd);
mape_m = mean(abs(m_p - data.m_dot(isTest)) ./ data.m_dot(isTest)) * 100;
mape_W = mean(abs(W_p - data.W_el(isTest))  ./ data.W_el(isTest))  * 100;
fprintf('Hold-out MAPE:  m_dot = %.2f %%,  W_el = %.2f %%\n', mape_m, mape_W);

% --- in-sample parity with the full-data models ------------------------------
[m_all, W_all] = predictPerformance(data.T_evap, data.T_cond, data.f, ...
    models, fluid, superheatK, Vd);

% --- figures -----------------------------------------------------------------
figure('Name','eta_v vs beta');
hold on; grid on;
freqs = unique(data.f);
cols  = lines(numel(freqs));
for k = 1:numel(freqs)
    m = data.f == freqs(k);
    scatter(res.beta(m), res.eta_v(m), 36, cols(k,:), 'filled', ...
        'DisplayName', sprintf('%d Hz', freqs(k)));
end
bg = linspace(min(res.beta), max(res.beta), 100);
plot(bg, models.a(1) + models.a(2)*bg + models.a(3)*1.0, ...
    'k-', 'LineWidth', 2, 'DisplayName', 'Fit (f = 50 Hz)');
xlabel('Pressure ratio \beta = P_{dis}/P_{suc} [-]');
ylabel('Volumetric efficiency \eta_v [-]');
legend('Location','best'); hold off;

figure('Name','eta_is vs beta');
hold on; grid on;
for k = 1:numel(freqs)
    m = data.f == freqs(k);
    scatter(res.beta(m), res.eta_is(m), 36, cols(k,:), 'filled', ...
        'DisplayName', sprintf('%d Hz', freqs(k)));
end
b = models.b;
plot(bg, b(1) + b(2)*bg + b(3)*bg.^2 + b(4)*1.0 + b(5)*bg*1.0, ...
    'k-', 'LineWidth', 2, 'DisplayName', 'Fit (f = 50 Hz)');
xlabel('Pressure ratio \beta = P_{dis}/P_{suc} [-]');
ylabel('Isentropic efficiency \eta_{is} [-]');
legend('Location','best'); hold off;

figure('Name','Parity: mass flow rate');
scatter(data.m_dot*1000, m_all*1000, 36, 'filled'); grid on; hold on;
lo = min(data.m_dot)*1000*0.95; hi = max(data.m_dot)*1000*1.05;
plot([lo hi], [lo hi], 'k--');
xlabel('Measured mass flow rate [g/s]');
ylabel('Predicted mass flow rate [g/s]');
axis equal; hold off;

figure('Name','Parity: power input');
scatter(data.W_el, W_all, 36, 'filled'); grid on; hold on;
lo = min(data.W_el)*0.95; hi = max(data.W_el)*1.05;
plot([lo hi], [lo hi], 'k--');
xlabel('Measured power input [kW]');
ylabel('Predicted power input [kW]');
axis equal; hold off;
end
