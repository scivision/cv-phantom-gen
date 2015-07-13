function oct = isoctave()
%Michael Hirsch Oct 2012
% tested with Octave 3.6.3 and Matlab R2012a


oct = exist('OCTAVE_VERSION', 'builtin') == 5;

end
