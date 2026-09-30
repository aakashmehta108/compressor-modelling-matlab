function data = loadCompressorData(filename)
%LOADCOMPRESSORDATA  Load the compressor performance dataset (data preparation).
%
%   data = loadCompressorData('compressor_data.csv')
%
%   Reads the manufacturer-style performance table with columns:
%     point_id, T_evap_C, T_cond_C, freq_Hz,
%     P_suc_bar, P_dis_bar, m_dot_kg_s, W_el_kW
%   Checks for missing values and prints a short summary.

if ~isfile(filename)
    error('Data file not found: %s', filename);
end

T = readtable(filename);

% --- basic data-quality checks -------------------------------------------
if any(any(ismissing(T)))
    warning('Missing values detected -- affected rows will be removed.');
    T = rmmissing(T);
end

data.T       = T;                       % keep full table
data.T_evap  = T.T_evap_C;              % evaporating temperature [degC]
data.T_cond  = T.T_cond_C;              % condensing temperature  [degC]
data.f       = T.freq_Hz;               % compressor frequency    [Hz]
data.m_dot   = T.m_dot_kg_s;            % measured mass flow      [kg/s]
data.W_el    = T.W_el_kW;               % measured power input    [kW]
data.n       = height(T);               % number of operating points

fprintf('Loaded %d operating points.\n', data.n);
fprintf('  T_evap : %.0f ... %.0f degC\n', min(data.T_evap), max(data.T_evap));
fprintf('  T_cond : %.0f ... %.0f degC\n', min(data.T_cond), max(data.T_cond));
fprintf('  freq   : %.0f ... %.0f Hz\n',   min(data.f),       max(data.f));
end
