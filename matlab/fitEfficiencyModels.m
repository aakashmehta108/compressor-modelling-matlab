function models = fitEfficiencyModels(res)
%FITEFFICIENCYMODELS  Fit polynomial correlations for the efficiencies.
%
%   models = fitEfficiencyModels(res)
%
%   Model forms (Lecture 1: efficiencies are functions of pressure ratio
%   and compressor frequency):
%     eta_v  = a0 + a1*beta + a2*fn
%     eta_is = b0 + b1*beta + b2*beta^2 + b3*fn + b4*beta*fn
%   with fn = f/50 Hz (normalized frequency).
%
%   Least-squares solution via the backslash operator. Reports R^2 and RMSE.

beta = res.beta;  fn = res.fn;

% --- volumetric efficiency: linear in beta and fn --------------------------
Xv = [ones(size(beta)), beta, fn];
a  = Xv \ res.eta_v;
eta_v_fit = Xv * a;

% --- isentropic efficiency: quadratic in beta, linear in fn ----------------
Xi = [ones(size(beta)), beta, beta.^2, fn, beta.*fn];
b  = Xi \ res.eta_is;
eta_is_fit = Xi * b;

models.a = a;  models.b = b;
models.eta_v_fit = eta_v_fit;  models.eta_is_fit = eta_is_fit;

[R2v, RMSEv]   = fitStats(res.eta_v,  eta_v_fit);
[R2is, RMSEis] = fitStats(res.eta_is, eta_is_fit);

fprintf('\nVolumetric efficiency model: eta_v = a0 + a1*beta + a2*fn\n');
fprintf('  a = [%.5f  %.5f  %.5f]\n', a);
fprintf('  R^2 = %.4f,  RMSE = %.5f\n', R2v, RMSEv);

fprintf('\nIsentropic efficiency model: eta_is = b0 + b1*beta + b2*beta^2 + b3*fn + b4*beta*fn\n');
fprintf('  b = [%.5f  %.5f  %.5f  %.5f  %.5f]\n', b);
fprintf('  R^2 = %.4f,  RMSE = %.5f\n', R2is, RMSEis);

models.R2v = R2v;   models.RMSEv = RMSEv;
models.R2is = R2is; models.RMSEis = RMSEis;
end

function [R2, RMSE] = fitStats(y, yhat)
%FITSTATS  Coefficient of determination and root-mean-square error.
ss_res = sum((y - yhat).^2);
ss_tot = sum((y - mean(y)).^2);
R2   = 1 - ss_res/ss_tot;
RMSE = sqrt(mean((y - yhat).^2));
end
