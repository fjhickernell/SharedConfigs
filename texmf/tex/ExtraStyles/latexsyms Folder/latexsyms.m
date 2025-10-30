% function latexsyms(varargin)
%  Creates a symbolic variable and stores its corresponding LaTeX
%  code for simpler formula visualisation and inclusion in documents.
%  The input arguments are entered in variable name and LaTeX code
%  pairs, with the optional final argument specifying the symbolic
%  variable type (real|unreal|positive). The declaration of symbolic
%  functions in this format is also allowed. The LaTeX code is stored in
%  a table in the workspace named 'LatexSymbolTable'. This is because
%  I decided it was too hard to inheret the sym class and overload
%  all of the functions.  It is recommended that you use symbolic
%  variable names that are more than 1 character long, as these can
%  cause problems if you use latexconv and latexdisp (which is kind of
%  the whole point of this function).
%
% IMPORTANT NOTE: This package has not been tested with the MuPAD
%    symbolic engine present from r2008b onward.
%
% USAGE: latexsyms sym1 latex1 func2(t) latex2(t) ... [type]
%
% EXAMPLES:
%   latexsyms Gain \mathbf{K} Accel(t) \ddot{\theta}
%   latexsyms Gain \mathbf{K} real
%
% v0.2.2 20-May-2009
%   Update to the BSD license.
%
% v0.2 30-Jun-2008
%   Allowed the declaration of symbolic functions, and changed the format
%   of the LatexSymbolTable
%
% v0.1 27-Feb-2008
%
% Available from the matlab file exchange in the 'latexsyms' package.
%
% See also syms, sym, latexconv, latexdisp

function latexsyms(varargin)

% If there are no input arguments, print out symbol and LaTeX pairs
if nargin < 1
   w = evalin('caller','whos');
   k = strmatch('sym',char({w.class,''}));
   
   % If LatexSymbolTable doesn't exist, just do what syms does
   if evalin('caller','~exist(''LatexSymbolTable'',''var'');')
     for l=k.'
       fprintf('''%s''\n',w(l).name);
     end
     return
   end
   
   % If it does exist print sym/LaTeX pairs
   for l=k.'
     if evalin('caller',['isfield(LatexSymbolTable,''',w(l).name,''');'])
       fprintf('%s -> ''%s''\n',w(l).name,evalin('caller',['LatexSymbolTable.',w(l).name,'.tex']));
     else
       fprintf('%s -> ''''\n',w(l).name);
     end
   end
   return
end

% Number of input arguments
n = numel(varargin);

% Test to see if the symbols are supposed to be a special type
special = 0;
if regexpi(varargin{n},'real|unreal|positive')
  special = 1;
  specialType = lower(varargin{n});
  n = n-1;
end

% Check for the correct number of input arguments
if mod(n,2) || (n==0)
  error('symbolic:latexsyms:errmsg1',['Wrong number of input arguments.\n',...
    'latexsyms must be called in SymName-LaTeX pairs\n',...
    'with an optional sym type at the end.']);
end

% Test to see wheter LatexSymbolTable already exists, and if it does,
%  check to make sure it's a structure.
if evalin('caller','exist(''LatexSymbolTable'',''var'');')
  if evalin('caller','~isstruct(LatexSymbolTable);')
    error('symbolic:latexsyms:errmsg3','LatexSymbolTable already exists, and is not a structure.');
  end
else
  assignin('caller','LatexSymbolTable',struct());
end

% Loop through, adding the new symbols and put the LaTeX strings in the table.
for k = 1:2:n
   x = varargin{k};
   y = varargin{k+1};
   % Check to see if the new variable names are ok.
   if ~isvarname(varargin{k})
     varname = regexp(varargin{k},'(\w*)\([\w,]*\)$','tokens','once');
     if isempty( varname ) || ~isvarname( varname{1} )
       error('symbolic:latexsyms:errmsg3','%s is not a valid variable name.',varargin{k});
     end
     varname = varname{1};
   else
     varname = varargin{k};
   end
   % Create the sym variable in the workspace
   if special
      assignin('caller',varname,sym(x,specialType));
   else
      assignin('caller',varname,sym(x));
   end
   % Place the values in the LatexSymbolTable
   evalin('caller',sprintf('LatexSymbolTable.(''%s'').sym=''%s'';',varname,x));
   evalin('caller',sprintf('LatexSymbolTable.(''%s'').tex=''%s'';',varname,y));
end