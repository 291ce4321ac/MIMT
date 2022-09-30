function aaa___ifversion___test(varargin)
%This is not a true test suite, but it should confirm the function runs without errors.

if nargin==0,RunTestHeadless=false;else,RunTestHeadless=true;end

% suppress v6.5 warning
v=version;v(strfind(v,'.'):end)='';v=str2double(v);
if v<=7
    warning off MATLAB:m_warning_end_without_block;clc
end

try ME=[]; %#ok<NASGU>
    w=warning('off','HJW:ifversion:NoOctaveTest');
    clc
    RunExamples
    warning(w);% Reset warning.
catch ME;if isempty(ME),ME=lasterror;end %#ok<LERR>
    warning(w);
    rethrow(ME)
end
if RunTestHeadless,clc,end
end
function RunExamples
fprintf('Do the claims below match the actual version?\nv: %s\n\n',version)
fprintf('['),if ifversion('>=','R2009a'),fprintf('X'),else,fprintf(' '),end,disp('] R2009a or later')
fprintf('['),if ifversion('<','R2016a'),fprintf('X'),else,fprintf(' '),end,disp('] R2015b or older')
fprintf('['),if ifversion('==','R2018a'),fprintf('X'),else,fprintf(' '),end,disp('] R2018a')
fprintf('['),if ifversion('==',9.9),fprintf('X'),else,fprintf(' '),end,disp('] R2020b')
fprintf('['),if ifversion('<',0,'Octave','>',0),fprintf('X'),else,fprintf(' '),end,disp('] Octave')
fprintf('['),if ifversion('<',0,'Octave','>=',6),fprintf('X'),else,fprintf(' '),end,disp('] Octave 6 and higher')
end
function tf=ifversion(test,Rxxxxab,Oct_flag,Oct_test,Oct_ver)
%Determine if the current version satisfies a version restriction
%
% To keep the function fast, no input checking is done. This function returns a NaN if a release
% name is used that is not in the dictionary.
%
% Syntax:
% tf=ifversion(test,Rxxxxab)
% tf=ifversion(test,Rxxxxab,'Octave',test_for_Octave,v_Octave)
%
% Output:
% tf       - If the current version satisfies the test this returns true.
%            This works similar to verLessThan.
%
% Inputs:
% Rxxxxab - Char array containing a release description (e.g. 'R13', 'R14SP2' or 'R2019a') or the
%           numeric version.
% test    - Char array containing a logical test. The interpretation of this is equivalent to
%           eval([current test Rxxxxab]). For examples, see below.
%
% Examples:
% ifversion('>=','R2009a') returns true when run on R2009a or later
% ifversion('<','R2016a') returns true when run on R2015b or older
% ifversion('==','R2018a') returns true only when run on R2018a
% ifversion('==',9.9) returns true only when run on R2020b
% ifversion('<',0,'Octave','>',0) returns true only on Octave
% ifversion('<',0,'Octave','>=',6) returns true only on Octave 6 and higher
%
% The conversion is based on a manual list and therefore needs to be updated manually, so it might
% not be complete. Although it should be possible to load the list from Wikipedia, this is not
% implemented.
%
%  _____________________________________________________________________________
% | Compatibility   | Windows XP/7/10 | Ubuntu 20.04 LTS | MacOS 10.15 Catalina |
% |-----------------|-----------------|------------------|----------------------|
% | ML R2020b       | W10: works      |  not tested      |  not tested          |
% | ML R2018a       | W10: works      |  works           |  not tested          |
% | ML R2015a       | W10: works      |  works           |  not tested          |
% | ML R2011a       | W10: works      |  works           |  not tested          |
% | ML R2010b       | not tested      |  works           |  not tested          |
% | ML R2010a       | W7:  works      |  not tested      |  not tested          |
% | ML 7.1 (R14SP3) | XP:  works      |  not tested      |  not tested          |
% | ML 6.5 (R13)    | W10: works      |  not tested      |  not tested          |
% | Octave 6.1.0    | W10: works      |  not tested      |  not tested          |
% | Octave 5.2.0    | W10: works      |  works           |  not tested          |
% | Octave 4.4.1    | W10: works      |  not tested      |  works               |
% """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
%
% Version: 1.0.5
% Date:    2020-12-08
% Author:  H.J. Wisselink
% Licence: CC by-nc-sa 4.0 ( https://creativecommons.org/licenses/by-nc-sa/4.0 )
% Email = 'h_j_wisselink*alumnus_utwente_nl';
% Real_email = regexprep(Email,{'*','_'},{'@','.'})

%The decimal of the version numbers are padded with a 0 to make sure v7.10 is larger than v7.9.
%This does mean that any numeric version input needs to be adapted. multiply by 100 and round to
%remove the potential for float rounding errors.
%Store in persistent for fast recall (don't use getpref, as that is slower than generating the
%variables and makes updating this function harder).
persistent  v_num v_dict octave
if isempty(v_num)
    %test if Octave is used instead of Matlab
    octave=exist('OCTAVE_VERSION', 'builtin');
    
    %get current version number
    v_num=version;
    ii=strfind(v_num,'.');if numel(ii)~=1,v_num(ii(2):end)='';ii=ii(1);end
    v_num=[str2double(v_num(1:(ii-1))) str2double(v_num((ii+1):end))];
    v_num=v_num(1)+v_num(2)/100;v_num=round(100*v_num);
    
    %get dictionary to use for ismember
    v_dict={...
        'R13' 605;'R13SP1' 605;'R13SP2' 605;'R14' 700;'R14SP1' 700;'R14SP2' 700;
        'R14SP3' 701;'R2006a' 702;'R2006b' 703;'R2007a' 704;'R2007b' 705;
        'R2008a' 706;'R2008b' 707;'R2009a' 708;'R2009b' 709;'R2010a' 710;
        'R2010b' 711;'R2011a' 712;'R2011b' 713;'R2012a' 714;'R2012b' 800;
        'R2013a' 801;'R2013b' 802;'R2014a' 803;'R2014b' 804;'R2015a' 805;
        'R2015b' 806;'R2016a' 900;'R2016b' 901;'R2017a' 902;'R2017b' 903;
        'R2018a' 904;'R2018b' 905;'R2019a' 906;'R2019b' 907;'R2020a' 908;
        'R2020b',909};
end

if octave
    if nargin==2
        warning('HJW:ifversion:NoOctaveTest',...
            ['No version test for Octave was provided.',char(10),...
            'This function might return an unexpected outcome.']) %#ok<CHARTEN>
        if isnumeric(Rxxxxab)
            v=0.1*Rxxxxab+0.9*fix(Rxxxxab);v=round(100*v);
        else
            L=ismember(v_dict(:,1),Rxxxxab);
            if sum(L)~=1
                warning('HJW:ifversion:NotInDict',...
                    'The requested version is not in the hard-coded list.')
                tf=NaN;return
            else
                v=v_dict{L,2};
            end
        end
    elseif nargin==4
        % Undocumented shorthand syntax: skip the 'Octave' argument.
        [test,v]=deal(Oct_flag,Oct_test);
        % Convert 4.1 to 401.
        v=0.1*v+0.9*fix(v);v=round(100*v);
    else
        [test,v]=deal(Oct_test,Oct_ver);
        % Convert 4.1 to 401.
        v=0.1*v+0.9*fix(v);v=round(100*v);
    end
else
    % Convert R notation to numeric and convert 9.1 to 901.
    if isnumeric(Rxxxxab)
        v=0.1*Rxxxxab+0.9*fix(Rxxxxab);v=round(100*v);
    else
        L=ismember(v_dict(:,1),Rxxxxab);
        if sum(L)~=1
            warning('HJW:ifversion:NotInDict',...
                'The requested version is not in the hard-coded list.')
            tf=NaN;return
        else
            v=v_dict{L,2};
        end
    end
end
switch test
    case '==', tf= v_num == v;
    case '<' , tf= v_num <  v;
    case '<=', tf= v_num <= v;
    case '>' , tf= v_num >  v;
    case '>=', tf= v_num >= v;
end
end