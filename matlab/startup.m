% MATLAB startup: use the standalone toolboxes in ~/SoftwareRepositories.
format compact
setupToolboxPaths;
if exist('gail.InitializeDisplay', 'file')
    % Retain GAIL's display settings and color variables in the workspace.
    gail.InitializeDisplay;
end

function setupToolboxPaths
    repoRoot = fullfile(getenv('HOME'), 'SoftwareRepositories');
    chebfunRoot = fullfile(repoRoot, 'chebfun');
    gailRepoRoot = fullfile(repoRoot, 'GAIL_Dev');
    gailRoot = fullfile(gailRepoRoot, 'GAIL_Matlab');
    if ~isfolder(gailRoot)
        % Older GAIL releases keep the MATLAB files at the repository root.
        gailRoot = gailRepoRoot;
    end

    % Chebfun needs its root on the path, not every subdirectory.
    if isfile(fullfile(chebfunRoot, '@chebfun', 'chebfun.m'))
        addpath(chebfunRoot);
        fprintf('[startup] Added Chebfun from %s\n', chebfunRoot);
    else
        warning('SharedConfigs:ChebfunMissing', ...
            'Chebfun was not found at %s.', chebfunRoot);
    end

    if isfile(fullfile(gailRoot, 'Algorithms', '+gail', 'InitializeDisplay.m'))
        % Remove paths saved for another branch's GAIL directory layout.
        currentPaths = strsplit(path, pathsep);
        oldGailPaths = currentPaths(strcmp(currentPaths, gailRepoRoot) | ...
            startsWith(currentPaths, [gailRepoRoot filesep]));
        if ~isempty(oldGailPaths)
            rmpath(oldGailPaths{:});
        end
        addpath(genpath(gailRoot));
        fprintf('[startup] Added GAIL from %s\n', gailRoot);
    else
        warning('SharedConfigs:GAILMissing', ...
            'GAIL was not found at %s.', gailRoot);
    end
end
