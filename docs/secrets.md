# Secret Management (sops-nix)

This project uses [sops-nix](https://github.com/Mic92/sops-nix) to manage secrets (API keys, tokens, passwords). Secrets are encrypted using **Age** and stored in git as `secrets.yaml`. They are decrypted at runtime using a private key stored on the device.


## 1. Prerequisites
Ensure `sops` and `age` are installed (managed via `home.packages` in `modules/core/tools.nix`).

## 2. Initial Setup (New Device)
To access secrets on a machine, it must have an Age identity key at the correct location.

### Generate a new key
If this is a completely new device that needs its own identity:
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

### Or, Restore an existing key
If you are syncing an existing identity, place your `keys.txt` backup here:
`~/.config/sops/age/keys.txt`

> **⚠ CRITICAL:** Back up `keys.txt` is on Bitwarden `kshitishkumarratha@gmail.com`.

---

## 3. Managing Secrets

### Editing Secrets
To add or modify secrets, simply run:
```bash
sops secrets.yaml
```
This opens the file in your default editor (`nvim`). The file will appear unencrypted while editing. Save and quit to re-encrypt.

**Format:**
```yaml
github_token: "ghp_EXAMPLE123"
figma_key: "fig_EXAMPLEABC"
nested_secret:
  api_key: "12345"
```

---

## 4. Consuming Secrets in Nix

### Step 1: expose the secret
In `modules/core/secrets.nix`, define the secret you want to extract.

```nix
{ config, ... }: {
  sops.secrets.github_token = { };
  # sops.secrets.nested_secret_api_key = { key = "nested_secret/api_key"; };
}
```

### Step 2: Use the secret path
Secrets are **not** exposed as environment variables automatically (for security). They are written to a file in `/run/user/1000/secrets/`.

To use them in a config file:
```nix
programs.foo.passwordFile = config.sops.secrets.github_token.path;
```

To use them in Fish/Shell environment:
```nix
programs.fish.interactiveShellInit = ''
  if test -f ${config.sops.secrets.github_token.path}
      set -gx GITHUB_TOKEN (cat ${config.sops.secrets.github_token.path})
  end
'';
```

---

## 5. Adding a New Device
If you want to add a new device (e.g., your Android phone or a Laptop) so it can decrypt the secrets:

1.  **On the New Device:**
    Generate a key (see Section 2). Copy the **Public Key** (starts with `age1...`).

2.  **On the Admin Device (PC):**
    Open `.sops.yaml` in the repo root. Add the new public key to the list.

    ```yaml
    keys:
      - &pc_pseudofractal age1rt3sn...
      - &new_device age1newdevice... # <--- Add this

    creation_rules:
      - path_regex: secrets.yaml$
        key_groups:
          - age:
              - *pc_pseudofractal
              - *new_device # <--- Add reference here
    ```

3.  **Update the Encryption:**
    Run this command to re-encrypt `secrets.yaml` with the new keys included:
    ```bash
    sops updatekeys secrets.yaml
    ```

4.  **Commit & Push:**
    Commit `.sops.yaml` and the modified `secrets.yaml`. Pull on the new device, and it will now be able to decrypt.
