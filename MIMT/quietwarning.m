function quietwarning(varargin)
%  QUIETWARNING(MESSAGE)
%  Print a simple warning message with backtrace momentarily disabled.
%  That's all this does; other functionality of warning() not supported.

S = warning('query','backtrace');
warning off backtrace
warning(varargin{:})
warning(S.state,'backtrace')
