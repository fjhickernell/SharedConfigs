function m2tex(numb)
% This file "m2tex.m" translates a normal m-file into a LaTeX-file, so that
% the layout of both files will look the same.
% Features:
%               - recognizes all keywords, strings and comments
%               - recognizes all indents and tabs
%               - recognizes cell titles
%               - writes all recognized objects correct in a tex-file
%               - uses original Matlab colors
%               - the font looks almost the same as in Matlab Editor
%               - tex-file is saved using fontencoding "UTF-8", so that
%                 German Umlauts will be written correct
%               - option for numbered code lines
%               - recognizes a linebreak, but only with a leading space
%                 character, i.e. " ..." and only once in a line
%
% Input:        After program start you can choose one m-file from a menu.
% Output:       A tex-file will be written in the same directory with the
%               same name as the m-file.
% Integration:  Include the output.tex file via the following commands:
%               - \include{output.tex} or
%               - \input{output.tex}
%
% Option:       m2tex(numb):    numb = 'num'
%                           --> will provide numbered lines in tex-file
%
% created on:   09.06.2009 by USL with Matlab 7.5.0 (R2007b)
% Version:      1.2.4
% finished:     17.06.2009 (1.0)
% last change:  31.07.2009
%
% If there are any suggestions, problems or ideas for missing functions or
% how to improve the program,
% please contact me at Matlab Central, where you've got the file...
%
% VERSION History:
%   - 1.0   17.06.09    -> translating m-code to tex
%   - 1.1   19.06.09    -> added option 'num' for numbered code lines
%   - 1.2   26.06.09    -> recognizes now a linebreak, but only with a
%                          leading space character, i.e. " ..."
%
% Comments from the writer of this file: (I'm working on it...)
% - recognizes " ...", but only one in a line without problems and only
% with a leading space character
% - no such string as "$" is allowed to be in the whole m-file in any way
%       --> $ = variable, which can be replaced in a line, if nessecary
% - option 'bw' for output only in black/white, keywords come in "boldface"
%       + advanced: variables will be in "italic"
% - only optimized (numbers+their indents) for ?\normalsize?
% - additional input options for 'inputfilename', 'outputfilename' (which
% would include the directory)
%
clc
% de-activate the question dialog by un-commenting/changing the next line
% nargin = 1; numb = 'no_numb';
if nargin == 0
    button = questdlg('Do you want numbered code lines?','Options','Yes','No','Yes');
    if strcmp(button,'Yes')
        numb = 'num';
    else
        numb = 'no_numb';
    end
elseif ~strcmp(numb,'num') && ~strcmp(numb,'no_numb')
    error('The option for numbered lines is not set correct. Use ''num''!')
end
% menu to choose m-file for conversion
[FileName,PathName,FilterIndex] = uigetfile('*.m','Select the M-file');
% FilterIndex = 1;
% FileName = 'testfile.m';
if FilterIndex == 0
    disp('The selection of the m-file was canceled from the user.')
elseif FilterIndex == 1
    dbstop if error % dbclear if error
    fid = fopen([PathName,FileName]);
    if fid ~= -1
        tex_body = '';
        %--- for debug purpose only ---------------------------------------
%         cnt_skip_lines = 74;    % ? % how many lines to skip
%         for t = 1 : cnt_skip_lines
%             line = fgetl(fid);      %#ok<NASGU> % skip lines
%         end
        %------------------------------------------------------------------
        l_anz = 0;lib_ex = [0 0];
        while feof(fid) == 0        % read until end of file is reached
            % as of this loop, read line after line
            line  = fgetl(fid);
            % check existence of the 3 'colors'
            [idx] = check_colors(line);
            % verify validation
            [idx,lib_ex] = check_points(line,idx,lib_ex);
            % execute conversion
            [line] = write_tex(line,idx);
            % numbered code lines
            l_anz = l_anz + 1;
            [prae_line,dist] = numb_line(numb,l_anz);
            % add line to already edited text
            tex_body = sprintf('\r %s',tex_body,[prae_line,line(1),dist,line(2:end)]);
            tex_body = tex_body(2:end);
        end
        status1 = fclose(fid);       % close file
        [header,footer] = write_header;
        tex_ges = sprintf('%s \n',header,['\noindent',tex_body],footer);
        tex_ges = tex_ges(1:end-2);
        % % %         clc
        % % %         tex_ges
        % save finished code in "FileName.tex"
        fid = fopen([PathName,FileName(1:end-2),'.tex'],'w','native','UTF-8');
        if fid ~= -1
            count = fprintf(fid,'%s',tex_ges');
            disp('Program successful executed.')
        else
            disp([FileName(1:end-2),'.tex'])
            disp('File couldn''t be opened with "fopen".')
        end
        status2 = fclose(fid);       % close file
    else
        disp(FileName)
        disp('File couldn''t be opened with "fopen".')
    end
    dbclear if error
end
function [idx] = check_colors(line)
% This subroutine looks and finds all possible hints, which could cause a
% change of color in the m-code.

% initialisation of the struct variables
idx.com     = [];   % location of comment
idx.com2    = [];   % location of double-comment aka cell titles
idx.str     = [];   % location of strings
idx.str_d   = [];   % length
idx.key     = [];   % location of keywords
idx.key_d   = [];   % length
idx.fsp     = [];   % location of space characters
idx.fsp_d   = [];   % length
idx.fs2     = [];   % location of "second" word strings
idx.lib     = [];   % location of a linebreak

% find all percentage signs
idx.com = findstr('%',line);
if length(line) >= 2, idx.com2= findstr('%%',line(1:2));end
% find all apostrophe signs
idx.str = findstr('''',line);
% if there are only space characters, make line really empty
if all(isspace(line))
    line = [];
end
if ~isempty(line)   % only if line is not empty
    word = textscan(line,'%s');
    wort = unique(word{:});
    word = word{:};
    % find all 'keywords'
    for i=1:length(wort)
        if iskeyword(wort{i})
            idx.key(length(idx.key)+(1:length(findstr(wort{i},line))))     = findstr(wort{i},line);
            idx.key_d(length(idx.key_d)+(1:length(findstr(wort{i},line)))) = length(wort{i});
        end
    end
    % find "second" words
    if length(line) > 3 && length(word) >= 2
        if ~iskeyword(word{1}) && ~strcmp(word{2}(1),'=')
            idx.fs2(length(idx.fs2)+(1:length(findstr(word{2},line))))     = findstr(word{2},line);
        end
    end
    % find a linebreak " ..."
    idx.lib = findstr(' ...',line);
end
% find all space characters
idx.fsp = findstr(' ',line);
idx.fsp_d = diff(idx.fsp);

if ~isempty(idx.lib)
    % treat everything after linebreak like a comment
    idx.com = [idx.com idx.lib+4];
    % treat the " ..." like a keyword
    idx.key = [idx.key idx.lib];
    idx.key_d = [idx.key_d idx.lib./idx.lib*4];
end
function [idx,lib_ex] = check_points(line,idx,lib_ex)
% This subroutine checks all found hints of the subroutine
% "check_colors", wether they are valid.
%% if double-comments exist
if ~isempty(idx.com2)
    idx.com     = [];
    idx.str     = [];
    idx.key     = [];
    idx.fs2     = [];
    idx.lib     = [];
end
%% Group I
if ~isempty(idx.str) && ~isempty(idx.com)
    for i = 1:2:fix(length(idx.str)/2)
        for j = length(idx.com):-1:1
            index = find((idx.com(j) > idx.str(i) & idx.com(j) < idx.str(i+1)));
            idx.com(index) = [];
        end
    end
    % of valid "%" only the first will be needed
    if ~isempty(idx.com)
        idx.com = idx.com(1);
        idx.str(find(idx.com < idx.str)) = [];
        % clear all keywords after first "%"
        index = find(idx.com < idx.key);
        idx.key(index) = [];
        idx.key_d(index) = [];
    end
    % clear keywords, which are inside a string
    for i = 1:2:2*fix(length(idx.str)/2)
        index = find((idx.key > idx.str(i) & idx.key < idx.str(i+1)));
        idx.key(index) = [];
        idx.key_d(index) = [];
    end
end
%% Group II
if isempty(idx.str) && ~isempty(idx.com) && ~isempty(idx.key)
    % remember only the first "%" sign
    idx.com = min(idx.com);
    % clear all keywords after first "%"
    index = find(idx.com < idx.key);
    idx.key(index) = [];
    idx.key_d(index) = [];
end
%% Group IIa
if ~isempty(idx.str)
    % clear strings, which are really a transpose
    index_es = findstr(line,'=');
    % if one cond. is 1, then "'" is beginning of a string
    cond1 = all(isspace(line(index_es+1:idx.str(1)-1)));
    cond2 = any(findstr(line(index_es+1:idx.str(1)-1),'('));
    cond3 = any(findstr(line(index_es+1:idx.str(1)-1),'{'));
    cond4 = any(findstr(line(index_es+1:idx.str(1)-1),'['));
    if ~any([cond1 cond2 cond3 cond4])
        idx.str(1) = [];
    end
end
%% Group III
if ~isempty(idx.str) && isempty(idx.com)
    % clear keywords, which are inside a string
    for i = 1:2:2*fix(length(idx.str)/2)
        index = find((idx.key > idx.str(i) & idx.key < idx.str(i+1)));
        idx.key(index) = [];
        idx.key_d(index) = [];
    end
end
%% last Group: "second" words and other stuff...
% clear the keyword "end", if it's right after ":", for example: "1:end"
if ~isempty(idx.key)
    index = idx.key(find(idx.key-1 >0 ))-1;
    index = index(line(index) == ':')+1;
    if ~isempty(index)
        index = find(index == idx.key);
        idx.key(index) = [];
        idx.key_d(index) = [];
    end
end
if length(idx.str) >= 4
    idx.str([find(diff(idx.str) == 1) find(diff(idx.str) == 1)+1]) = [];
end
% ?? was war das hier? war für abstände gedacht, nicht mehr nötig!!!
if ~isempty(idx.fsp)
    index = find(diff(idx.fsp)~=1);
    idx.fsp([index length(idx.fsp)])   = [];
    idx.fsp_d(index) = [];
    if isempty(idx.fsp)
        idx.fsp = [];
        idx.fsp_d = [];
    end
end
% clear "second" words on the right side of "%"
if ~isempty(idx.com) && ~isempty(idx.fs2)
    idx.fs2(find(idx.com(1) <= idx.fs2)) = [];
end
if ~isempty(idx.key) && ~isempty(idx.fs2)
    % clear keywords, which are behind a "second" word, except a linebreak
    index = find(idx.key >= idx.fs2 & ~strcmp(' ...',line(idx.key:idx.key+3)));
    idx.key(index)   = [];
    idx.key_d(index) = [];
end
% clear "second" words, which are inside a string
if ~isempty(idx.str) && ~isempty(idx.fs2)
    % fs2's rausschmeissen, die innerhalb von strings sind % NOCH NÖTIG ??
    for i = 1:2:2*fix(length(idx.str)/2)
        index = find(idx.fs2 > idx.str(i) & idx.fs2 < idx.str(i+1));
        idx.fs2(index) = [];
    end
end
% if linebreak exists in previous line
if (lib_ex(1) == 1) && (lib_ex(2) == 1)
    idx.fs2 = 1;
elseif (lib_ex(1) == 1) && (lib_ex(2) == 0)
    idx.fs2 = [];
end
% set conditions for next line if linebreak exists
lib_ex = [0 0];
if ~isempty(idx.key) && ~isempty(idx.lib)
    if any(idx.key == idx.lib)
        lib_ex(1) = 1; % linebreak  exists in this line
    end
    if ~isempty(idx.fs2)
        lib_ex(2) = 1; % "2nd" word exists
    end
end
function [line] = write_tex(line,idx)
%% read the whole strings, which are colored
text.com = [];
text.str = [];
text.key = [];
text.fs2 = [];
if ~isempty(idx.com)
    text.com{1} = line(idx.com:end);
end
if ~isempty(idx.str)
    for i = 1:2:2*fix(length(idx.str)/2)
        text.str{i} = line(idx.str(i):idx.str(i+1));
    end
end
if ~isempty(idx.key)
    for i = 1:length(idx.key)
        text.key{i} = line(idx.key(i):idx.key(i)+idx.key_d(i)-1);
    end
end
if ~isempty(idx.fs2)
    text.fs2{1} = line(idx.fs2:end);
    if ~isempty(idx.com)
        text.fs2{1} = line(idx.fs2:idx.com-1);
    end
    if ~isempty(idx.lib)
        text.fs2{1} = line(idx.fs2:idx.lib-1);
    end
end
%% replace text-strings in line
% DOUBLE_COMMENT
if ~isempty(idx.com2)
    line = [['$\UndefineShortVerb{\$}',...
        '\DefineShortVerb[fontfamily=courier,fontseries=b]{\$}',...
        '\color{mgreen}$'],line,['$\color{black}',...
        '\UndefineShortVerb{\$}',...
        '\DefineShortVerb[fontfamily=courier,fontseries=m]{\$}$']];
end
% KEYWORDS
if ~isempty(text.key)
    keys = sort(idx.key);
    for i = 1:length(keys)
        key_text_sorted{i} = text.key{find(keys(i) == idx.key)};
    end
    text.key = key_text_sorted;
    for i = length(text.key):-1:1
        n = find(findstr(text.key{i},line) == keys);
        n = find(findstr(text.key{i},line) == keys(n));
        text_rep = ['$\color{mblue}$',text.key{i},'$\color{black}$'];
        if strcmp(' ...',text.key{i})
            % regexprep won't work in case of looking for ' ...', why???
            % so only one ' ...' in line is allowed
            line = strrep(line,text.key{i},text_rep);
        else
            line = regexprep(line,text.key{i},text_rep,n);
        end
    end
    if ~isempty(findstr('$color',line))
        line = strrep(line,'$color','$\color');
    end
end
% COMMENTS
if ~isempty(text.com)
    text_rep = ['$\color{mgreen}$',text.com{1},'$\color{black}$'];
    line = strrep(line,text.com{1},text_rep);
end
% STRINGS
if ~isempty(text.str)
    for i = 1:length(text.str)
        text_rep = ['$\color{mred}$',text.str{i},'$\color{black}$'];
        if ~isempty(text.str{i})
            line = strrep(line,text.str{i},text_rep);
        end
    end
end
% "SECOND" WORDS, are strings too
if ~isempty(text.fs2)
    text_rep = ['$\color{mred}$',text.fs2{1},'$\color{black}$'];
    line = strrep(line,text.fs2{1},text_rep);
end
line = ['$',line,'$\\'];
function [header,footer] = write_header
header = sprintf('%s \n'...
    ,'% This file was automatically created from the m-file'...
    ,'% "m2tex.m" written by USL.'...
    ,'% The fontencoding in this file is UTF-8.'...
    ,'% '...
    ,'% You will need to include the following two packages in'...
    ,'% your LaTeX-Main-File.'...
    ,'% '...
    ,'% \usepackage{color}'...
    ,'% \usepackage{fancyvrb}'...
    ,'% '...
    ,'% It is advised to use the following option for Inputenc'...
    ,'% \usepackage[utf8]{inputenc}'...
    ,'% '...
    ,' '...
    ,'% definition of matlab colors:'...
    ,'\definecolor{mblue}{rgb}{0,0,1}'...
    ,'\definecolor{mgreen}{rgb}{0.13333,0.5451,0.13333}'...
    ,'\definecolor{mred}{rgb}{0.62745,0.12549,0.94118}'...
    ,' '...
    ,'\DefineShortVerb[fontfamily=courier,fontseries=m]{\$}'...
    ,' '...
    );
header = header(1:end-2);

footer = sprintf('%s \n'...
    ,' '...
    ,'\UndefineShortVerb{\$}'...
    );
footer = footer(1:end-2);
function [prae_line,dist_line] = numb_line(numb,l_anz)
if strcmp(numb,'num')
    format bank
    % distances only optimized for numbers in \scriptsize and code in
    % \normalsize
    offset = -3.2; % = 0: nicht eingerückt, sonst code auf line (-3.25)
    if l_anz > 0,   n_dist = ['\hspace*{',num2str(offset+1.6),'em}'];end
    if l_anz > 9,   n_dist = ['\hspace*{',num2str(offset+1.2),'em}'];end
    if l_anz > 99,  n_dist = ['\hspace*{',num2str(offset+0.8),'em}'];end
    if l_anz > 999, n_dist = ['\hspace*{',num2str(offset+0.4),'em}'];end
    if l_anz > 9999,n_dist = ['\hspace*{',num2str(offset+0.0),'em}'];end
    % tiny, scriptsize, footnotesize, small, normalsize
    prae_line = [n_dist,'{\scriptsize ',num2str(l_anz),'}'];
    dist_line = '  ';
    format short
else
    prae_line = '';
    dist_line = '';
end