function matlab = ismatlab()
%Michael Hirsch Oct 2012
% tested with Octave 3.6.3 and Matlab R2012a


if isempty(ver('matlab')), matlab = false; %running octave
else matlab = true; %running matlab
end

end
