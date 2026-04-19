{lib, ...}: let

  create-fake-uuid-v4 = input_string: let
    hash = builtins.hashString "sha256" input_string;
  in
    "${builtins.substring 0 8 hash}-"
    + "${builtins.substring 8 4 hash}-"
    + "4${builtins.substring 13 3 hash}-"
    + "8${builtins.substring 17 3 hash}-"
    + "${builtins.substring 20 12 hash}";

  spaceId = spaceName: create-fake-uuid-v4 "zen-browser-space:${spaceName}";

  rawPins = [
    {
      title = "WhatsApp";
      url = "https://web.whatsapp.com/";
      workspace = spaceId "General";
      position = 1000;
      isEssential = true;
    }
    {
      title = "ChatGPT";
      url = "https://chat.openai.com/";
      workspace = spaceId "General";
      position = 2000;
      isEssential = true;
    }
    {
      title = "Mail (General)";
      url = "https://mail.google.com/mail/u/1/#inbox";
      workspace = spaceId "General";
      position = 3000;
    }
    {
      title = "Moodle";
      url = "https://web.iisermohali.ac.in/moodle/";
      workspace = spaceId "Studies";
      position = 4000;
    }
    {
      title = "Classroom";
      url = "https://classroom.google.com/u/0/";
      workspace = spaceId "Studies";
      position = 5000;
    }
    {
      title = "Mail (Studies)";
      url = "https://mail.google.com/mail/u/0/#inbox";
      workspace = spaceId "Studies";
      position = 6000;
    }
    {
      title = "Question Papers";
      url = "https://iiserm.github.io/question-paper-repo/";
      workspace = spaceId "Studies";
      position = 7000;
    }
    {
      title = "Drive Folder";
      url = "https://drive.google.com/drive/folders/1o0VNqbWD2q02ceao0EqwFgNI4Sg4qEpz";
      workspace = spaceId "Studies";
      position = 8000;
    }
    {
      title = "Google Scholar";
      url = "https://scholar.google.com/";
      workspace = spaceId "Research";
      position = 9000;
    }
    {
      title = "arXiv";
      url = "https://www.arxiv.org/";
      workspace = spaceId "Research";
      position = 10000;
    }
    {
      title = "alphaXiv";
      url = "https://alphaxiv.org/";
      workspace = spaceId "Research";
      position = 11000;
    }
    {
      title = "Awesome Niri";
      url = "https://github.com/Vortriz/awesome-niri/?tab=readme-ov-file#custom-shells";
      workspace = spaceId "Rice";
      position = 12000;
    }
    {
      title = "Vortriz Dotfiles";
      url = "https://github.com/Vortriz/dotfiles/";
      workspace = spaceId "Rice";
      position = 13000;
    }
    {
      title = "Home Manager Options";
      url = "https://home-manager-options.extranix.com/?query=&release=master";
      workspace = spaceId "Rice";
      position = 14000;
    }
    {
      title = "pseudofractal dotfiles";
      url = "https://github.com/pseudofractal/dotfiles";
      workspace = spaceId "Rice";
      position = 15000;
    }
    {
      title = "YouTube Track";
      url = "https://www.youtube.com/watch?v=Na0w3Mz46GA";
      workspace = spaceId "Entertainment";
      position = 16000;
    }
    {
      title = "YouTube";
      url = "https://www.youtube.com/";
      workspace = spaceId "Entertainment";
      position = 17000;
    }
    {
      title = "pstream";
      url = "https://pstream.org/";
      workspace = spaceId "Entertainment";
      position = 18000;
    }
  ];
in {
  programs.zen-browser.profiles.main.pins = builtins.listToAttrs (lib.imap1 (
      idx: pin: {
        name = "pin-${toString idx}";
        value = pin // {id = create-fake-uuid-v4 "zen-browser-pin:${pin.title}:${pin.url}";};
      }
    )
    rawPins);
}
