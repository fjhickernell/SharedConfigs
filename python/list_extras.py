import importlib.metadata as im, tomllib, pathlib

p = pathlib.Path.home() / "SoftwareRepositories" / "MATH565Fall2025" / "QMCSoftware" / "pyproject.toml"
t = tomllib.load(open(p, "rb"))
deps = set()
deps.update(t["project"]["dependencies"])
for group in t["project"]["optional-dependencies"].values():
    deps.update(group)
deps = {d.split()[0].split('[')[0].lower().replace('-', '_') for d in deps}

installed = {dist.metadata["Name"].lower().replace('-', '_') for dist in im.distributions()}
extras = sorted(installed - deps)

for e in extras:
    print(e)