function val = getRefrigerantProp(output, name1, val1, name2, val2, fluid)
%GETREFRIGERANTPROP  Refrigerant property via CoolProp (called from MATLAB).
%
%   val = getRefrigerantProp('P','T',278.15,'Q',0,'R134a')
%
%   Uses the CoolProp library through MATLAB's Python interface, exactly as
%   taught in Lecture 1 (Project 4). CoolProp must be installed in the Python
%   environment linked to MATLAB -- see README.md for the setup steps.
%
%   NOTE: specific volume is obtained as 1/D (density) because PropsSI('V',..)
%   with P,T inputs is unreliable in some CoolProp builds.

try
    val = double(py.CoolProp.CoolProp.PropsSI( ...
        output, name1, val1, name2, val2, fluid));
catch ME
    error(['CoolProp call failed.\n' ...
           'Make sure CoolProp is installed in the Python environment used by MATLAB.\n' ...
           'Setup steps are in README.md (from Lecture 1: pyversion + pip install CoolProp).\n' ...
           'Original error: %s'], ME.message);
end
end
