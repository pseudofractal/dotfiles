# Secrets (sops-nix)

Secrets (API keys, tokens, passwords) live encrypted in `secrets.yaml` through [sops-nix](https://github.com/Mic92/sops-nix): Age-encrypted, committed to git, decrypted at runtime with a private key on the device.

## What you need

`sops` and `age` installed (both come via `home.packages` in `modules/core/tools.nix`).

## New device

The machine needs an Age identity key in the right place.

Generate one for a brand-new device:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Or drop a `keys.txt` backup at `~/.config/sops/age/keys.txt` when syncing an existing identity.

Keep a copy of `keys.txt` in Bitwarden. Without it the secrets are gone.

## Editing

Add or change secrets with:

```bash
sops secrets.yaml
```

This opens the file in your editor (`nvim`). It reads unencrypted while editing; saving re-encrypts.

Shape of the file:

```yaml
github_token: "ghp_EXAMPLE123"
figma_key: "fig_EXAMPLEABC"
nested_secret:
  api_key: "12345"
```

## Using secrets in Nix

Declare what to extract in `modules/core/secrets.nix`:

```nix
{ config, ... }: {
  sops.secrets.github_token = { };
}
```

Secrets land as files under `/run/user/1000/secrets/`, never as environment variables. Point config at the path:

```nix
programs.foo.passwordFile = config.sops.secrets.github_token.path;
```

Or into a fish session:

```nix
programs.fish.interactiveShellInit = ''
  if test -f ${config.sops.secrets.github_token.path}
      set -gx GITHUB_TOKEN (cat ${config.sops.secrets.github_token.path})
  end
'';
```

## Adding a device

So a new machine (a phone, another laptop) can decrypt secrets:

1. On the new device: generate a key (above) and copy the public key (starts with `age1...`).
1. On this PC: open `.sops.yaml` in the repo root and add the public key:

   ```yaml
   keys:
     - &pc_pseudofractal age1rt3sn...
     - &new_device age1newdevice... # <--- add this

   creation_rules:
     - path_regex: secrets.yaml$
       key_groups:
         - age:
             - *pc_pseudofractal
             - *new_device # <--- and reference it here
   ```

1. Re-encrypt with the new keys included:

   ```bash
   sops updatekeys secrets.yaml
   ```

1. Commit `.sops.yaml` and the re-encrypted `secrets.yaml`. Pull on the new device; it can decrypt now.
