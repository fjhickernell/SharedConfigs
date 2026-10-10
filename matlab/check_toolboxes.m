% Quick numerical checks after installing MATLAB or synchronizing toolboxes.
% For documentation, use: help GAIL; help integral_g; help chebfun
checkToolboxes;

function checkToolboxes
    fprintf('MATLAB %s\n', version('-release'));
    which chebfun
    which integral_g

    f = chebfun(@sin);
    assert(norm(chebfun('sin(x)') - f, inf) < 1e-12);
    assert(abs(f(1) - sin(1)) < 1e-12);
    fprintf('Chebfun passed: sin(1) = %.15f\n', f(1));

    [q, info] = integral_g(@(x) x.^2, 0, 1, 1e-8);
    assert(abs(q - 1/3) < 1e-8 && ~info.exceedbudget);
    fprintf('GAIL passed: integral of x^2 on [0,1] = %.15f; error = %.3g\n', ...
        q, abs(q - 1/3));
end
