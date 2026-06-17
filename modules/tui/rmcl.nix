{inputs, pkgs, ...}: {
  imports = [
    inputs.rmcl.homeManagerModules.default
  ];

  programs.rmcl = {
    enable = true;
    instancesDir = "~/Games/minecraft/instances";
    metaDir = "~/Games/minecraft/meta";
    javaPath = "${pkgs.jdk8}/bin/java";
    memoryMin = "2G";
    memoryMax = "4G";
  };
}
