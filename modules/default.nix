{inputs, ...}: {
  imports = [
    ./core
    ./cli
    ./tui
    ./programming

    # External Modules from Flake Inputs
    inputs.mnemosyne.homeManagerModules.default
    inputs.kensaku.homeManagerModules.default
    inputs.shiryoku.homeManagerModules.default
  ];
}
