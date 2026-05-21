{...}: {
  programs.yazi.keymap.mgr.prepend_keymap = [
    {
      on = "<Enter>";
      run = "plugin smart-enter";
      desc = "Enter the child directory, or open the file";
    }
    {
      on = "f";
      run = "plugin jump-to-char";
      desc = "Jump to char";
    }
    {
      on = "M";
      run = "plugin mount";
      desc = "Mount";
    }
    {
      on = "F";
      run = "plugin smart-filter";
      desc = "Smart filter";
    }
    {
      on = "<S-s>";
      run = "link";
      desc = "Symlink the absolute path of yanked files";
    }
    {
      on = "`";
      run = "plugin bunny";
      desc = "Start bunny.yazi";
    }
    {
      on = ["'" ";"];
      run = "plugin custom-shell -- fish --interactive";
      desc = "custom-shell as default, interactive";
    }
    {
      on = ["'" ":"];
      run = "plugin custom-shell -- fish --interactive --block";
      desc = "custom-shell as default, interactive, block";
    }
    {
      on = "<Tab>";
      run = "shell 'ripdrag \"$@\" -anx 2>/dev/null &' --confirm";
      desc = "Drag and drop";
    }
    {
      on = "C";
      run = "plugin ouch --args=zip";
      desc = "Compress with ouch";
    }
    {
      on = "?";
      run = "plugin what-size";
      desc = "Calc size of selection or cwd";
    }
  ];
}
