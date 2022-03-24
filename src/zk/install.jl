using Pkg

# Install missing packages
function install_packages()
  packages = setdiff(split("ArgParse JSON Revise TimeZones YAML OrderedCollections"),
                     keys(Pkg.project().dependencies))
  if !isempty(packages)
    print("Installing packages: $packages")
    for pkg in packages Pkg.add(pkg) end
  end
end

install_packages()
