{...}: {
  programs.zen-browser.profiles.main.search = {
    force = true;
    default = "poros";
    engines = {
      poros = {
        name = "poros";
        urls = [
          {
            template = "https://pseudofractal.github.io/Poros/?query={searchTerms}";
            params = [
              {
                name = "query";
                value = "searchTerms";
              }
            ];
          }
        ];
        definedAliases = ["@poros"];
      };
    };
  };
}
