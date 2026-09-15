{pkgs, ...}: let
  keyboard = pkgs.fcitx5.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/im/keyboard/keyboard.cpp \
          --replace-fail 'auto name = _("Keyboard - {0}", description);' 'auto name = layoutInfo.name == "us" ? _("English") : _("Keyboard - {0}", description);'
        substituteInPlace src/im/keyboard/keyboard.cpp \
          --replace-fail '.setLabel(layoutInfo.shortDescription.empty()' '.setLabel(layoutInfo.name == "us" ? "English" : layoutInfo.shortDescription.empty()'
      '';
  });
  mozc = pkgs.fcitx5-mozc.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/unix/fcitx5/mozc_engine.cc \
          --replace-fail 'return _(kPropCompositionModes[mozc_state->GetCompositionMode()].description);' 'return {};'
      '';
  });
  m17n = pkgs.fcitx5-m17n.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace im/overrideparser.cpp \
          --replace-fail "if (!line.empty() || line[0] == '#')" "if (line.empty() || line[0] == '#')"
        substituteInPlace im/engine.cpp \
          --replace-fail 'auto fxName = _("{0} (M17N)", i18nname);' 'auto fxName = i18nname;'
      '';
  });
in {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      fcitx5-with-addons = pkgs.qt6Packages.fcitx5-with-addons.override {
        fcitx5 = keyboard;
      };
      addons = [
        m17n
        mozc
      ];
      waylandFrontend = true;
      systemd.enable = true;
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
        };
        "Groups/0/Items/2" = {
          Name = "m17n_hi_itrans";
        };
        "Groups/0/Items/3" = {
          Name = "m17n_or_itrans";
        };
      };
      sessionVariables = {
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        INPUT_METHOD = "fcitx";
      };
    };
  };

  home.file.".local/share/fcitx5/m17n/default".text = ''
    # Keep the upstream m17n defaults while naming the active Indic methods.
    hi:itrans:2:Hindi
    or:itrans:2:Odia
    as:*:2
    bn:*:2
    gu:*:2
    hi:*:2
    kn:*:2
    ks:*:2
    mai:*:2
    ml:*:2
    mr:*:2
    ne:*:2
    or:*:2
    pa:*:2
    sa:*:2
    sd:*:2
    si:*:2
    ta:*:2
    te:*:2
    as:phonetic:1
    bn:inscript:1
    gu:inscript:1
    hi:inscript:1
    kn:kgp:1
    ks:kbd:1
    mai:inscript:1
    ml:inscript:1
    mr:inscript:1
    ne:rom:1
    or:inscript:1
    pa:inscript:1
    sa:harvard-kyoto:1
    sd:inscript:1
    si:wijesekera:1
    ta:tamil99:1
    te:inscript:1
    zh:bopomofo:100:Chewing Symbol
    zh:pinyin:100:Pinyin Symbol
    zh:cangjie:-1:Cangjie
    zh:py:-1:Pinyin
    zh:tonepy:-1:Tone Pinyin
    *:kbd:-1:Keyboard
    ja:anthy:-1:Anthy
    ko:han2:-1:Hanja
    ko:romaja:-1:Romaja
    zh:quick:-1:Quick
  '';

  home.file.".local/share/fcitx5/inputmethod/mozc.conf".text = ''
    [InputMethod]
    Name=Japanese
    Icon=mozc
    Label=Japanese
    LangCode=ja
    Addon=mozc
    Configurable=True
  '';
}
