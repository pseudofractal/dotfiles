{
  uuidV4FromName = input_string: let
    hash = builtins.hashString "sha256" input_string;
  in
    "${builtins.substring 0 8 hash}-"
    + "${builtins.substring 8 4 hash}-"
    + "4${builtins.substring 13 3 hash}-"
    + "8${builtins.substring 17 3 hash}-"
    + "${builtins.substring 20 12 hash}";
}
