% function LatexString = latexconv(SymbolicExpression,OPTIONS)
%   Converts a symbolic expression into a form suitable for LaTeX, and
%   if present, it substitutes symbols for LaTeX code generated using
%   latexsyms.
%
% IMPORTANT NOTE: This package has not been tested with the MuPAD
%    symbolic engine present from r2008b onward.
%
% USAGE
%  LatexString = latexconv(SymbolicExpression,'key1','options1')
%
% INPUTS
%  SymbolicExpression - the sybolic expression to be
%    displayed
%  OPTIONS - are input as 'key' and 'value' pairs.
%    KEY      |   VALUE
%    --------------------------------------------------
%    'mode'   | ['simple'|'full']
%             |  'simple' basically uses the default output from the
%             |  'latex' command and performs symbol substitution.
%             |  'full' removes some of the manual formatting inserted
%             |  by the 'latex' command and is more suitable for inclusion
%             |  in a document, but requires the 'amsmath' package
%             |  to be loaded.
%             |
%    'macros' | [0|1]
%             |  Treat unknown symbols as macros? This options will treat
%             |  any symbolic variable without matches as a macro, prefixing
%             |  it with a '\'. This is useful if you have lots of macros
%             |  defined in your LaTeX document, and you use the same
%             |  symbolic variable name in Matlab.
%
% OUTPUT
%  LatexString - the Latex equivalent of the input
%    symbolic expression. If the 'full' mode is used you will
%    need to load the 'amsmath' package in you LaTeX document.
%
% EXAMPLE
%  >> latexsyms Length \mathbf{L} Angle \theta
%  >> latexconv(Length*cos(Angle))
%  ans =
%  \mathbf{L}\,\cos \left( \theta \right)
%
% v0.2.2 20-May-2009
%   Updated to the BSD license.
%
% v0.2.1 27-Oct-2008
%   Wrote manual input parsing functions for old versions of Matlab that
%   don't have the inputParser class :-( (pre r2007a).
%
% v0.2 30-Jun-2008
%   Fixed bug caused by symbols with underscores in their name.
%   Rewritten to handle sym functions and work with latexsyms v0.2
%
% v0.1 28-Feb-2008
%
% Available from the matlab file exchange in the 'latexsyms' package.
%
% See also syms, sym, latexsyms, latexdisp, latex

function LatexString = latexconv(SymbolicExpression,varargin)

% Check for the correct number of arguments
if nargin <1
  fprintf('usage: LatexString = latexconv(SymbolicExpression,OPTIONS);\n');
  return;
end

p = latexconv_parseInput;

% Convert the symbolic expression to LaTeX
LatexString = latex(SymbolicExpression);

% See if the LatexSymbolTable from latexsyms is present, if so, get it.
if evalin('caller','exist(''LatexSymbolTable'',''var'');')
  LatexSymbolTable = evalin('caller','LatexSymbolTable');
  if ~isstruct(LatexSymbolTable)
    LatexSymbolTable = struct();
  end
else
  LatexSymbolTable = struct();
end

% Make sure Matlab hasn't put any \_ in when latex was called
LatexString = regexprep(LatexString,'\\_','_');

% Now do the replacements
Symbols = fieldnames(LatexSymbolTable);
for ii=1:length(Symbols)
  % Test to see if the sym is a variable or function
  symfunc = regexp(LatexSymbolTable.(Symbols{ii}).sym,'(\w*)\(([\w,]*)\)$','tokens');
  % If it is a variable
  if isempty( symfunc )
    if length(Symbols{ii}) > 1
      LatexString = regexprep(LatexString,...
        regexptranslate('escape',['{\it ',Symbols{ii},'}']),...
        regexptranslate('escape',LatexSymbolTable.(Symbols{ii}).tex));
    else
      LatexString = regexprep(LatexString,...
        ['(\W+|^)',regexptranslate('escape',[Symbols{ii}]),'(\W+|$)'],...
        ['$1',regexptranslate('escape',LatexSymbolTable.(Symbols{ii}).tex),'$2']);
    end
    % Else if it is a function
  else
    if length( Symbols{ii} ) > 1
      LatexString = regexprep(LatexString,...
        regexptranslate('escape',['{\it ',symfunc{1}{1},'}',' \left( ',symfunc{1}{2},' \right)']),...
        regexptranslate('escape',LatexSymbolTable.(Symbols{ii}).tex));
      LatexString = regexprep(LatexString,...
        regexptranslate('escape',['{\it ',Symbols{ii},'}']),...
        regexptranslate('escape',LatexSymbolTable.(Symbols{ii}).tex));
    else
      LatexString = regexprep(LatexString,...
        ['(\W+|^)',regexptranslate('escape',[symfunc{1}{1},' \left( ',symfunc{1}{2},' \right)']),'(\W+|$)'],...
        ['$1',regexptranslate('escape',LatexSymbolTable.(Symbols{ii}).tex),'$2']);
      LatexString = regexprep(LatexString,...
        ['(\W+|^)',regexptranslate('escape',Symbols{ii}),'(\W+|$)'],...
        ['$1',regexptranslate('escape',LatexSymbolTable.(Symbols{ii}).tex),'$2']);
    end
  end
end

if p.Results.Macros
  % Replace the symbol names with macros
  LatexString = regexprep(LatexString,'{\\it (\w*)}','\\$1');
end

if strcmpi(p.Results.Mode,'full')
  % Get rid of all the \, spaces
  LatexString = regexprep(LatexString,'\\,',' ');
  % Replace \begin{array} with \begin{bmatrix}
  LatexString = regexprep(LatexString,'\\left\[ \\begin {array}{c*}',...
    '\\begin{bmatrix}');
  LatexString = regexprep(LatexString,'\\end {array} \\right\]',...
    '\\end{bmatrix}');
  % Replace the \noalign business
  LatexString = regexprep(LatexString,regexptranslate('escape','\\\noalign{\medskip}'),...
    regexptranslate('escape',' \\ '));
end

% Subfunction to parse the input.
  function p = latexconv_parseInput
    % Functions to test for valid input
    fSymExpChk = @(x) isa(x,'sym');
    fModeChk = @(x) ischar(x) && any(strcmpi(x,{'simple','full'}));
    fMacrosChk = @(x) (length(x)==1)&&isnumeric(x);
    
    % If you are using a new (post r2007a) version of matlab, use the
    % inputParser class to parse input
    if exist('inputParser','class')
      p = inputParser;
      p.FunctionName = 'latexconv';
      p.addRequired('SymbolicExpression', fSymExpChk );
      p.addOptional('Mode', 'simple', fModeChk );
      p.addOptional('Macros', 0, fMacrosChk );
      p.parse(SymbolicExpression,varargin{:});
    
    % Otherwise manually parse the input :-(
    else
      p.Results.Mode = 'simple';
      p.Results.Macros = 0;
      %warning('latexconv:oldMatlab','Manually parsing input because you are using an old version of Matlab :-(');
      if ~fSymExpChk( SymbolicExpression )
        error('latexconv:input:SymbolixExpression','SymbolicExpression must by a sym');
      end
      if mod( length( varargin ), 1 )
        error('latexconv:input:OddVarargin','Optional arguments must be specified in KEY VALUE pairs (i.e. odd number of optional arguments given).');
      end
      % Loop through varargin
      for jj=1:2:length( varargin )
        % Mode key
        if strcmpi( varargin{jj}, 'Mode' )
          if fModeChk( varargin{jj+1} )
            p.Results.Mode = varargin{jj+1};
            continue;
          else
            error('latexconv:input:mode','Mode must be either ''simple'' or ''full''');
          end
        end % Mode key
        % Macros key
        if strcmpi( varargin{jj}, 'Macros' )
          if fMacrosChk( varargin{jj+1} )
            p.Results.Macros = varargin{jj+1};
            continue;
          else
            error('latexconv:input:macros','Macros must be either ''simple'' or ''full''');
          end
        end % Macros key
        % If the key is invalid
        error('latexconv:input:invalidKey','Input Key ''%s'' is invalid',varargin{jj});
      end % varargin loop
    end % manual input parsing
  end % function latexconv_parseInput

end % function latexconv