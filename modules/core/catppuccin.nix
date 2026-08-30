{lib, ...}: {
  catppuccin = {
    autoEnable = true;
    enable = true;
    flavor = "mocha";
    accent = "teal";
    nvim.enable = false;
  };

  home.activation.fixGtk3CatppuccinCss = lib.hm.dag.entryAfter ["writeBoundary"] ''
    gtk3_css="$HOME/.config/gtk-3.0/gtk.css"

    if [ -f "$gtk3_css" ] && grep -q 'sidebar_shade_color RGB' "$gtk3_css"; then
      sed -i \
        -e 's/RGB(0 0 6 \/ 25%)/rgba(0,0,6,0.25)/' \
        -e 's/RGB(0 0 6 \/ 36%)/rgba(0,0,6,0.36)/' \
        -e '/^:root {$/,/^}$/d' \
        "$gtk3_css"
    fi
  '';
}
