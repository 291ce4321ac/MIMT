[![View ifversion on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/69138-ifversion)

This minitool helps you determine the version of Matlab (or Octave) that is running your code. This is helpful when imposing a minimum version requirement, or when different versions need different methods to reach the same end result. By using persistent variables this will stay fast even with repeated calls.

You shouldn't use a logical test with v=version;v=str2double(v(1:3)); as it is incomplete for several releases (like e.g. 7.14 or in the future 10.1). That also includes the potential for float rounding errors.

    % examples:
    ifversion('>=','R2009a')        % returns true when run on R2009a or later
    ifversion('<','R2016a')         % returns true when run on R2015b or older
    ifversion('==','R2018a')        % returns true only when run on R2018a
    ifversion('==',9.9)             % returns true only when run on R2020b
    ifversion('<',0,'Octave','>',0) % returns true only on Octave
    ifversion('<',0,'Octave','>=',6)% returns true only on Octave 6 and higher

Licence: CC by-nc-sa 4.0