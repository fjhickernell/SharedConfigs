% function latexdisp(Latex,OPTIONS)
%  Displays formula in a popup window, from either a direct LaTeX
%  string, or a symbolic expression generated using latexsyms. The
%  formula can be rendered with either the Matlab LaTeX interpreter
%  or an external LaTeX installation (which is useful for more
%  complicated expressions, or when you need to load external macros).
%  It can additionally save the formula as an image, for inclusion in
%  documents (note that putting one of these images into a LaTeX
%  document would be extremely silly).
%
% IMPORTANT NOTE: This package has not been tested with the MuPAD
%    symbolic engine present from r2008b onward.
%
% USAGE
%  latexdisp(LatexString,option1,value1,option2,values2...)
%
% INPUTS
%  Latex - the latex expression to be displayed, as either a symbolic
%    expression, or a string.
%  OPTIONS - additional options are added in 'key' and 'value' pairs
%    Key             |   Value
%    -------------------------------------------------------------
%    'Processor'     | ['matlab'|'external'], default 'matlab'
%                    | 'matlab' uses the Matlab LaTeX interpreter to
%                    | process the LaTeX string, while 'external' uses
%                    | an external installation of LaTeX
%                    |
%    'FontSize'      | 2<=FontSize<=144, default 24
%                    | Size of the font when using the Matlab processor
%                    |
%    'ImageDPI'      | 50<=ImageDPI<=500, default 300
%                    | Resolution (size) of the output when using
%                    | external LaTeX
%                    |
%    'PreambleString'| <string>, default ''
%                    | String to be placed in the preamble of an externally
%                    | processed formula. This is useful if you have a file
%                    | of macros to load, e.g.
%                    | 'PreambleString','\input{macros.tex}'
%                    |
%    'ExpressionName'| <string>, default 'SymbolicExpression'
%                    | The name given to the popup figure, as well as the
%                    | image if the user wants it saved.
%                    |
%    'SaveImage'     | [0|1], default 0
%                    | Saves the formula as an image in the current
%                    | directory, with name 'ExpressionName'. If using the
%                    | external processor, it is saved as a 'png' file, but
%                    | if using the Matlab processor, it is saved as a
%                    | 'eps' file. This is because the Matlab png printer
%                    | isn't working properly.
%
% EXAMPLE
%  >> latexsyms Gain \mathbf{K} Angle \theta
%  >> latexdisp(Gain*sin(Angle),'FontSize',36);
%
% v0.2.2 20-May-2009
%   Updated to BSD license.
%
% v0.2.1 27-Oct-2008
%   Added to code to manually parse the optional input parameters for
%   people running old (pre r2007a) versions of Matlab without the
%   inputParser class :-(
%
% v0.2 01-Jul-2008
%   Embedded part of newfig as a subfunction, and assume windows users have
%   Miktex and *nix users have texlive (affects the -jobname option)
%
% v0.1 28-Feb-2008
%
% Copyright 2007,2008 Zebb Prime
% Distributed under the GNU General Public License, see LICENSE.txt
% or the text appended to the source.
%
% Available from the matlab file exchange in the 'latexsyms' package.
%
% See also syms, sym, latexsyms, latexconv, latex

function latexdisp(Latex,varargin)

% USERS - You may need to change these variables depending upon your LaTeX
% distribution and configuration.
texpath_win = '';
texpath_nix = '/usr/bin/';
texpath_mac = '/usr/texbin/';

% Check for the correct number of arguments
if nargin <1
  fprintf('usage: latexdisp(Latex,OPTIONS)\n');
  return;
end

p = latexdisp_parseInput;
switch lower(p.Results.Processor)
  % If using the Matlab latex interpreter to display the results.
  case 'matlab'
    if ~any(strcmpi(p.UsingDefaults,'ImageDPI'))
      warning('latexdisp:unusedOption','ImageDPI has no effect when using the Matlab processor');
    end
    if ~any(strcmpi(p.UsingDefaults,'PreambleString'))
      warning('latexdisp:unusedOption','PreambleString has no effect when using the Matlab processor');
    end
    if isa(Latex,'sym')
      if evalin('caller','exist(''LatexSymbolTable'',''var'');')
        LatexSymbolTable = evalin('caller','LatexSymbolTable');
      end
      Latex = latexconv(Latex);
    end

    Latex = ['$',Latex,'$'];

    % Now display the text
    hfig = latexdisp_newfig(p.Results.ExpressionName);
    set(hfig,'menubar','none','resize','off','units','centimeters');
    hf_pos = get(hfig,'position');
    ha = axes;
    set(ha,'visible','off','units','normalized','position',[0,0,1,1]);
    ht = text(0.5,0.5,Latex,'interpreter','latex','verticalalignment',...
      'middle','horizontalalignment','center','fontsize',...
      floor(p.Results.FontSize));

    set(ht,'units','centimeters');
    ht_extent = get(ht,'extent');
    set(ht,'position',[ht_extent(3:4)/2,0]);
    % Mac reporting the incorrect width work-around
    if ismac
      ht_extent(3) = ht_extent(3)*1.05;
    end
    set(hfig,'position',[hf_pos(1:2),ht_extent(3:4)]);

    set(hfig,'paperpositionmode','auto');

    % Save the image if required
    if p.Results.SaveImage
      print( hfig, '-djpeg', p.Results.ExpressionName);
    end

    % If using an external installation of latex to process the string.
  case 'external'
    if ~any(strcmpi(p.UsingDefaults,'fontsize'))
      warning('latexdisp:unusedOption','FontSize has no effect when using the external processor');
    end
    if isa(Latex,'sym')
      if evalin('caller','exist(''LatexSymbolTable'',''var'');')
        LatexSymbolTable = evalin('caller','LatexSymbolTable');
      end
      Latex = latexconv(Latex,'mode','full','macros',1);
    end

    expressionName = genvarname(p.Results.ExpressionName);
    
    % Save current directory path, and go to the tempdir
    ThisDir = pwd;
    cd(tempdir);

    % Determine what platform we are using
    if ispc
      texpath = texpath_win;
    elseif ismac
      texpath = texpath_mac;
    else
      texpath = texpath_nix;
    end
    
    fid = fopen([expressionName,'.tex'],'w');
    if fid == 0
      error('latexdisp:filewrite','Unable to open file %s.tex for writing.',expressionName);
    end
    fprintf(fid,['\\documentclass{minimal}\n',...
      '\\RequirePackage[tightpage]{preview}\n',...
      '\\RequirePackage{amsmath,amssymb}\n',...
      '%s%%user preamble\n',...
      '\\begin{document}\n',...
      '\\noindent$\n\\displaystyle\n%s\n$\n',...
      '\\end{document}'],p.Results.PreambleString,Latex);
    fclose(fid);
    clear fid
    
    % Now we call LaTeX
    [LatexResult,LatexOut] = system(sprintf('%slatex -interaction=nonstopmode %s.tex',texpath,expressionName));

    % Test to see if latex completed properly
    if LatexResult ~= 0
      delete([expressionName,'*']);
      cd(ThisDir);
      error('DisplayLatex:LatexError',['LaTeX compilation failed! ',...
        'Here is the console output:\n%s'], LatexOut);
    end

    % Convert the output to png
    for ii=1:2
      [PngResult,PngOut] = system([texpath,'dvipng -D',num2str(floor(p.Results.ImageDPI)),' ',...
        expressionName,'.dvi']);
      if ~PngResult
        break
      end
    end

    % Test to see if dvipng completed properly
    if PngResult ~= 0
      delete([expressionName,'*']);
      cd(ThisDir);
      error('DisplayLatex:DvipngError',['DVIPNG conversion failed! ',...
        'Here is the console output:\n%s'], PngOut);
    end

    % Save the file if requested.
    if p.Results.SaveImage
      copyfile([expressionName,'1.png'],[ThisDir,'/',expressionName,'.png']);
    end

    % Read the input file
    [A,map] = imread([expressionName,'1.png']);
    delete([expressionName,'*']);
    cd(ThisDir);

    % Create the figure window
    hfig = latexdisp_newfig(p.Results.ExpressionName);
    % Display the image using inbuilt functions (not part of the image
    %  processing toolbod).
    image(A);colormap(map);daspect([1 1 1]);axis off;
    % x and y padding (ratio to x and y sizes)
    xsize = 1.1; ysize = 1.1;
    % Now scale the figure to make the image the right size...
    set(hfig,'Units','pixels');
    hf_pos = get(hfig,'position');
    hf_pos(3) = xsize*size(A,2); hf_pos(4) = ysize*size(A,1);
    set(hfig,'Position',hf_pos,'resize','off','menubar','none');
    set(gca,'Units','pixels','Position',...
      [floor(size(A,2)*(xsize-1)/2) floor(size(A,1)*(ysize-1)/2) size(A,2) size(A,1)]);
end

  function p = latexdisp_parseInput
    % validity check functions
    fLatexChk = @(x) isa(x,'sym')||ischar(x);
    fProcessorChk = @(x) ischar(x)&&any(strcmpi(x,{'matlab','external'}));
    fFontSizeChk = @(x) (length(x)==1) && isnumeric(x) && (x>=2) && (x<=144);
    fImageDPIChk = @(x) (length(x)==1) && (isnumeric(x)) && (x >= 50) && (x <= 500);
    fPreambleChk = @(x) ischar(x);
    fExpressionNameChk = @(x) ischar(x);
    fSaveImageChk = @(x) (length(x)==1) && isnumeric(x);
    
    % if the inputParser class exists
    if exist('inputParser','class')
      p = inputParser;
      p.FunctionName = 'latexdisp';
      p.addRequired('Latex', fLatexChk );
      p.addOptional('Processor','matlab', fProcessorChk );
      p.addOptional('FontSize',24, fFontSizeChk );
      p.addOptional('ImageDPI',300, fImageDPIChk );
      p.addOptional('PreambleString','', fPreambleChk );
      p.addOptional('ExpressionName','SymbolicExpression', fExpressionNameChk );
      p.addOptional('SaveImage',0, fSaveImageChk );
      p.parse(Latex,varargin{:});
      
      % Manually parse the input if this is an old version of Matlab :-(
    else
      p.UsingDefaults = {'Processor','FontSize','ImageDPI','PreambleString','ExpressionName','SaveImage'};
      p.Results.Processor = 'matlab';
      p.Results.FontSize = 24;
      p.Results.ImageDPI = 300;
      p.Results.PreambleString = '';
      p.Results.ExpressionName = 'SymbolicExpression';
      p.Results.SaveImage = 0;
      
      if ~fLatexChk( Latex )
        error('latexdisp:input:latex','Latex must be a symbolic expression or a latex string');
      end
      if mod( length( varargin ), 1 )
        error('latexdisp:input:OddVarargin','Optional arguments must be specified in KEY VALUE pairs (i.e. odd number of optional arguments given).');
      end

      % Loop through varargin
      for jj=1:2:length( varargin )
        if strcmpi( varargin{jj}, 'Processor' )
          if fProcessorChk( varargin{jj+1} )
            [Y,I] = find(strcmpi(p.UsingDefaults,'Processor'),1);
            p.UsingDefaults = p.UsingDefaults( setxor(1:length( p.UsingDefaults ),I) );
            p.Results.Processor = varargin{jj+1};
            continue;
          else
            error('latexdisp:input:Processor','Processor must be either ''matlab'' or ''external''');
          end
        end % Processor key
        
        if strcmpi( varargin{jj}, 'FontSize' )
          if fFontSizeChk( varargin{jj+1} )
            [Y,I] = find(strcmpi(p.UsingDefaults,'FontSize'),1);
            p.UsingDefaults = p.UsingDefaults( setxor(1:length( p.UsingDefaults ),I) );
            p.Results.FontSize = varargin{jj+1};
            continue;
          else
            error('latexdisp:input:FontSize','FontSize must be an integer between 2 and 144');
          end
        end % FontSize key
        
        if strcmpi( varargin{jj}, 'ImageDPI' )
          if fImageDPIChk( varargin{jj+1} )
            [Y,I] = find(strcmpi(p.UsingDefaults,'ImageDPI'),1);
            p.UsingDefaults = p.UsingDefaults( setxor(1:length( p.UsingDefaults ),I) );
            p.Results.ImageDPI = varargin{jj+1};
            continue;
          else
            error('latexdisp:input:ImageDPI','ImageDPI must be an integer between 50 and 500');
          end
        end % ImageDPI key
        
        if strcmpi( varargin{jj}, 'PreambleString' )
          if fPreambleChk( varargin{jj+1} )
            [Y,I] = find(strcmpi(p.UsingDefaults,'PreambleString'),1);
            p.UsingDefaults = p.UsingDefaults( setxor(1:length( p.UsingDefaults ),I) );
            p.Results.PreambleString = varargin{jj+1};
            continue;
          else
            error('latexdisp:input:PreambleString','PreambleString must be a string');
          end
        end % PreambleString key
        
        if strcmpi( varargin{jj}, 'ExpressionName' )
          if fExpressionNameChk( varargin{jj+1} )
            [Y,I] = find(strcmpi(p.UsingDefaults,'ExpressionName'),1);
            p.UsingDefaults = p.UsingDefaults( setxor(1:length( p.UsingDefaults ),I) );
            p.Results.ExpressionName = varargin{jj+1};
            continue;
          else
            error('latexdisp:input:ExpressionName','ExpressionName must be a string');
          end
        end % ExpressionName key
        
        if strcmpi( varargin{jj}, 'SaveImage' )
          if fSaveImageChk( varargin{jj+1} )
            [Y,I] = find(strcmpi(p.UsingDefaults,'SaveImage'),1);
            p.UsingDefaults = p.UsingDefaults( setxor(1:length( p.UsingDefaults ),I) );
            p.Results.SaveImage = varargin{jj+1};
            continue;
          else
            error('latexdisp:input:SaveImage','SaveImage must be either 0 or 1');
          end
        end % SaveImage key
        
        % If the key is invalid
        error('latexconv:input:invalidKey','Input Key ''%s'' is invalid',varargin{jj});
      end % varargin loop
      
    end % exist('inputParser')
  end % latexdisp_parseInput

end % latexdisp

% This is a cut-down version of my 'newfig' function, included in this file
%  so I don't have to distribute 'newfig' with the latexsyms stuff.
function hfig = latexdisp_newfig(name)
% Try and find a figure of the same name
hfig = findobj(0,'Name',name);
% If one exists clear it, and bring it into focus, otherwise create a new
% figure
if ~isempty(hfig)
  clf(hfig);
  figure(hfig);
  % Mac window size problem work-around
  if ismac
    close(hfig);
    hfig = figure;
  end
else
  hfig = figure;
end

% Set the figure name, units to centimeters, background colour to white,
% and the default text size to 8pt
set(hfig,'Name',name,'NumberTitle','off','units','centimeters',...
  'color',[1 1 1],'defaulttextfontsize',8);
end %latexsidp_newfig
