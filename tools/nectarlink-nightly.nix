{pkgs}:
pkgs.writeShellApplication {
  name = "nectarlink-nightly";
  runtimeInputs = with pkgs; [
    coreutils
    curl
    gawk
    git
    gnugrep
    gnused
    jq
    nix
    util-linux
  ];

  meta.mainProgram = "nectarlink-nightly";

  text = ''
    repo=''${NECTARLINK_REPO:-$HOME/dotfiles}
    data_dir=''${NECTARLINK_DATA_DIR:-$HOME/.local/share/Nectarlink}
    cache_dir=''${XDG_CACHE_HOME:-$HOME/.cache}/nectarlink-nightly
    state_dir=''${XDG_STATE_HOME:-$HOME/.local/state}/nectarlink-nightly
    queued_dir=$state_dir/queued
    rollback_dir=$state_dir/rollback
    remote=https://github.com/thtbee/nectarlink.git
    nectarlink_input_prefix='github:thtbee/nectarlink/'
    releases=https://github.com/thtbee/nectarlink/releases/download
    default_api_port=53320
    api_wait_attempts=5
    lock_wait_seconds=60
    http_timeout=30
    curl_max_time=300
    git_timeout=15
    nix_timeout=300
    nightly_tag_regex='^v[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]+$'
    api_error=""
    version_tag_regex='^v[0-9]+\.[0-9]+\.[0-9]+(-nightly\.[0-9]+)?$'
    api_connect_timeout=1
    api_request_timeout=2
    api_poll_interval=1
    http_connect_timeout=10
    download_connect_timeout=15
    download_retries=3
    download_retry_delay=2
    download_attempts=2
    send_connect_timeout=3

    log() { printf 'nectarlink-nightly: %s\n' "$*" >&2; }
    info() { log "$*"; }
    warn() { log "warning: $*"; }
    die() {
      log "error: $*"
      exit 1
    }

    die_usage() {
      log "error: $*"
      exit 2
    }

    usage() {
      cat <<'EOF'
    Usage: nectarlink-nightly <COMMAND> [OPTIONS]

    Commands:
      latest                  Print the newest v*-nightly.* tag with a release.
      pinned                  Print the NectarLink tag in flake.nix.
      update [--dry-run]      Pin flake.nix to the newest nightly and re-lock it.
                              Prints the new tag; exits 3 when already current.
      recover                 Resolve a pending transaction without using the network.
      mark-switched           Record a successful switch in a pending transaction.
      commit                  Finish a pending update after a successful switch.
      rollback [OPTIONS]      Restore the flake files from the pending update.
                              --clear-queued also clears this tag's device markers.
                              --allow-switched permits rollback after the switch.
      send [OPTIONS]          Download, verify and queue the pinned tag's APK.
      status                  Show the pin, newest tag, and per-device APK state.
      has-pending             Exit 0 when a NectarLink transaction is pending.

    send options:
      --tag TAG               Send this tag instead of the pinned one.
      --pending               Only send to online devices without a marker; mark
                              successful devices. Exit 4 while any device is pending.
      --mark-queued           Mark successful manual queues.
      --dry-run               Show what would be queued; do not download or write state.

    Common options:
      --repo PATH             Dotfiles checkout (default: $NECTARLINK_REPO or ~/dotfiles).
      -h, --help              Show this help.

    Exit codes: 0 ok, 1 error, 2 usage, 3 already current, 4 deferred, 5 recovered.
    EOF
    }

    ensure_dirs() {
      mkdir -p "$cache_dir" "$state_dir" "$queued_dir"
    }

    migrate_state() {
      [[ -d $state_dir/sent ]] || return 0
      if cp -a "$state_dir/sent/." "$queued_dir/" 2>/dev/null; then
        rm -rf "$state_dir/sent"
      else
        warn "can't merge the old sent state; leaving it in place"
      fi
    }

    remaining_args=()
    parse_common() {
      while (($# > 0)); do
        case $1 in
        -h | --help)
          usage
          exit 0
          ;;
        --repo)
          (($# >= 2)) || die_usage "--repo needs a path"
          repo=$2
          shift 2
          ;;
        *)
          remaining_args+=("$1")
          shift
          ;;
        esac
      done
    }

    lock_state() {
      ensure_dirs
      if [[ -n ''${NECTARLINK_REBUILD_LOCKED:-} ]]; then
        migrate_state
        return 0
      fi
      exec 9>"$state_dir/rebuild.lock"
      flock -w "$lock_wait_seconds" 9 || die "another NectarLink operation is running"
      migrate_state
    }

    latest_tags() {
      local tags
      if ! tags=$(timeout "$git_timeout" git ls-remote --tags --refs "$remote"); then
        return 2
      fi
      tags=$(printf '%s\n' "$tags" |
        awk -F/ '{print $NF}' |
        grep -E "$nightly_tag_regex" |
        sort -rV || true)
      printf '%s\n' "$tags"
    }

    pinned_tag() {
      local ref
      ref=$(sed -nE "s#.*''${nectarlink_input_prefix}([^\"]+).*#\\1#p" "$repo/flake.nix" |
        head -n1)
      [[ -n $ref ]] || return 1
      printf '%s\n' "$ref"
    }

    release_apk_name() {
      printf 'Nectarlink-%s-android.apk\n' "''${1#v}"
    }

    tag_is_current_or_newer() {
      local current=$1 latest=$2
      [[ $current == "$latest" ]] ||
        [[ $(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n1) == "$current" ]]
    }

    release_file_state() {
      local url=$1 code
      if ! code=$(curl -sIL --connect-timeout "$http_connect_timeout" --max-time "$http_timeout" \
        -o /dev/null -w '%{http_code}' "$url"); then
        return 2
      fi
      case $code in
      2??) return 0 ;;
      404) return 1 ;;
      *) return 2 ;;
      esac
    }

    validate_release() {
      local tag=$1
      local apk_name state sums checksum
      apk_name=$(release_apk_name "$tag")

      release_file_state "$releases/$tag/$apk_name" || {
        state=$?
        return "$state"
      }
      release_file_state "$releases/$tag/SHA256SUMS.txt" || {
        state=$?
        return "$state"
      }

      sums=$(mktemp) || return 3
      if ! curl -fsSL --connect-timeout "$http_connect_timeout" --max-time "$http_timeout" \
        "$releases/$tag/SHA256SUMS.txt" -o "$sums"; then
        rm -f "$sums"
        return 2
      fi

      checksum=$(awk -v file="$apk_name" '$2 == file {print $1; exit}' "$sums")
      rm -f "$sums"
      [[ $checksum =~ ^[0-9a-f]{64}$ ]] || return 1
    }

    restore_file() {
      local src=$1 dst=$2
      local tmp
      tmp=$(mktemp "$dst.XXXXXX") || return 1
      if ! cp -p "$src" "$tmp" || ! mv "$tmp" "$dst"; then
        rm -f "$tmp"
        return 1
      fi
    }

    transaction_hash() {
      local file=$1 name=$2
      [[ -f $file ]] || return 1
      awk -v name="$name" '$2 == name {print $1; exit}' "$file"
    }

    restore_transaction_file() {
      local name=$1
      local stage old_hash new_hash current_hash
      stage=$(transaction_stage)
      old_hash=$(transaction_hash "$rollback_dir/old.sha256" "$name" || true)
      new_hash=$(transaction_hash "$rollback_dir/updated.sha256" "$name" || true)
      if [[ -f $repo/$name ]]; then
        if ! current_hash=$(sha256sum "$repo/$name" | awk '{print $1}'); then
          warn "can't read $name; refusing to overwrite it"
          return 1
        fi
      else
        current_hash=""
      fi

      if [[ $stage == lock-updating && $name == flake.lock ]]; then
        local flake_old_hash flake_new_hash flake_hash
        flake_old_hash=$(transaction_hash "$rollback_dir/old.sha256" flake.nix || true)
        flake_new_hash=$(transaction_hash "$rollback_dir/updated.sha256" flake.nix || true)
        flake_hash=""
        if [[ -f $repo/flake.nix ]]; then
          flake_hash=$(sha256sum "$repo/flake.nix" | awk '{print $1}')
        fi
        if [[ -n $flake_hash && ($flake_hash == "$flake_old_hash" || $flake_hash == "$flake_new_hash") ]]; then
          if [[ -f $rollback_dir/flake.lock ]]; then
            restore_file "$rollback_dir/flake.lock" "$repo/flake.lock" || return 1
          elif ! rm -f "$repo/flake.lock"; then
            warn "can't remove flake.lock; refusing to finish the rollback"
            return 1
          fi
          return 0
        fi
      fi

      if [[ -z $current_hash ]]; then
        if [[ -z $old_hash ]]; then
          return 0
        fi
        if [[ -f $rollback_dir/$name ]]; then
          restore_file "$rollback_dir/$name" "$repo/$name" || return 1
          return 0
        fi
        warn "backup for $name is missing; refusing to continue"
        return 1
      fi
      if [[ -n $old_hash && $current_hash == "$old_hash" ]]; then
        return 0
      fi
      if [[ -n $new_hash && $current_hash == "$new_hash" ]]; then
        if [[ -f $rollback_dir/$name ]]; then
          restore_file "$rollback_dir/$name" "$repo/$name" || return 1
        elif ! rm -f "$repo/$name"; then
          warn "can't remove $name; refusing to finish the rollback"
          return 1
        fi
        return 0
      fi
      warn "$name changed since the NectarLink transaction; refusing to overwrite"
      return 1
    }

    transaction_stage() {
      if [[ -f $rollback_dir/switched ]]; then
        echo switched
      elif [[ -f $rollback_dir/locked ]]; then
        echo locked
      elif [[ -f $rollback_dir/lock-updating ]]; then
        echo lock-updating
      elif [[ -f $rollback_dir/prepared ]]; then
        echo prepared
      else
        echo unknown
      fi
    }

    transaction_matches_repo() {
      local recorded current
      recorded=$(cat "$rollback_dir/repo" 2>/dev/null || true)
      [[ -n $recorded ]] || return 1
      current=$(realpath "$repo" 2>/dev/null) || return 1
      [[ $recorded == "$current" ]]
    }

    transaction_file_matches_repo() {
      local name=$1 current old_hash new_hash
      old_hash=$(transaction_hash "$rollback_dir/old.sha256" "$name" || true)
      new_hash=$(transaction_hash "$rollback_dir/updated.sha256" "$name" || true)
      if [[ -f $repo/$name ]]; then
        if ! current=$(sha256sum "$repo/$name" | awk '{print $1}'); then
          return 1
        fi
        [[ -n $current && ($current == "$old_hash" || $current == "$new_hash") ]]
        return
      fi
      [[ -z $old_hash && -z $new_hash ]]
    }

    transaction_hashes_match_repo() {
      transaction_file_matches_repo flake.nix &&
        transaction_file_matches_repo flake.lock
    }

    clear_transaction() {
      rm -rf "$rollback_dir" || {
        warn "can't remove the NectarLink transaction state"
        return 1
      }
    }

    rollback_transaction() {
      local clear_queued=''${1:-false}
      [[ -d $rollback_dir ]] || return 0

      local stage old new
      stage=$(transaction_stage)
      old=$(cat "$rollback_dir/old_tag" 2>/dev/null || true)
      new=$(cat "$rollback_dir/new_tag" 2>/dev/null || true)
      if [[ $stage == unknown || ! -s $rollback_dir/old.sha256 ]]; then
        warn "incomplete NectarLink transaction; refusing to restore"
        return 1
      fi

      restore_transaction_file flake.nix || return 1
      restore_transaction_file flake.lock || return 1
      if [[ $clear_queued == true && -n $new && $new =~ $version_tag_regex ]]; then
        if ! rm -rf "''${queued_dir:?}/''${new:?}"; then
          warn "can't clear queued markers for $new"
        fi
      fi
      clear_transaction || return 1
      info "rolled back NectarLink to ''${old:-the previous pin}"
    }

    rollback_or_die() {
      local message=$1
      if ! rollback_transaction; then
        die "$message; rollback could not be completed and the transaction was retained for inspection"
      fi
      die "$message; restored the previous pin"
    }

    begin_transaction() {
      local old=$1 new=$2
      local tmp="$rollback_dir.tmp"
      local repo_path
      repo_path=$(realpath "$repo") || return 1
      rm -rf "$tmp"
      mkdir -p "$tmp" || return 1
      cp -p "$repo/flake.nix" "$tmp"/ || {
        rm -rf "$tmp"
        return 1
      }
      if [[ -f $repo/flake.lock ]]; then
        cp -p "$repo/flake.lock" "$tmp"/ || {
          rm -rf "$tmp"
          return 1
        }
      fi
      printf '%s\n' "$old" >"$tmp/old_tag" || {
        rm -rf "$tmp"
        return 1
      }
      printf '%s\n' "$new" >"$tmp/new_tag" || {
        rm -rf "$tmp"
        return 1
      }
      printf '%s\n' "$repo_path" >"$tmp/repo" || {
        rm -rf "$tmp"
        return 1
      }
      if ! (cd "$tmp" && {
        sha256sum flake.nix
        [[ ! -f flake.lock ]] || sha256sum flake.lock
      } >old.sha256); then
        rm -rf "$tmp"
        return 1
      fi
      : >"$tmp/prepared" || {
        rm -rf "$tmp"
        return 1
      }
      [[ ! -d $rollback_dir ]] || {
        warn "a NectarLink transaction already exists; refusing to replace it"
        rm -rf "$tmp"
        return 1
      }
      mv "$tmp" "$rollback_dir"
    }

    recover_transaction() {
      [[ -d $rollback_dir ]] || return 0

      local stage current old new
      stage=$(transaction_stage)
      if [[ $stage == unknown || ! -s $rollback_dir/old.sha256 ]]; then
        warn "incomplete NectarLink transaction; discarding it"
        clear_transaction || return 1
        return 0
      fi
      if ! transaction_matches_repo; then
        if ! transaction_hashes_match_repo; then
          die "pending NectarLink transaction belongs to another checkout; run the updater there or remove $rollback_dir"
        fi
        realpath "$repo" >"$rollback_dir/repo" ||
          die "can't adopt the pending NectarLink transaction"
      fi

      if [[ $stage == switched ]]; then
        current=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
        old=$(cat "$rollback_dir/old_tag" 2>/dev/null || true)
        new=$(cat "$rollback_dir/new_tag" 2>/dev/null || true)
        if [[ $current == "$new" ]]; then
          recovered_switched=1
          clear_transaction || return 1
          info "committed previous NectarLink update to $new"
        else
          warn "NectarLink transaction $old -> $new no longer matches pin $current; discarding it"
          clear_transaction || return 1
        fi
        return 0
      fi

      rollback_transaction || die "can't roll back the pending NectarLink transaction"
    }

    mark_switched() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "mark-switched: unexpected argument: $1"

      lock_state
      if [[ ! -d $rollback_dir ]]; then
        info "no pending NectarLink update to mark"
        return 0
      fi
      transaction_matches_repo || die "pending NectarLink transaction belongs to another checkout"

      local stage current new
      stage=$(transaction_stage)
      if [[ $stage != locked && $stage != switched ]]; then
        warn "NectarLink transaction is not locked; refusing to mark it switched"
        return 1
      fi
      current=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      new=$(cat "$rollback_dir/new_tag" 2>/dev/null || true)
      if [[ $current != "$new" ]]; then
        warn "pin is $current, not $new; refusing to mark the transaction switched"
        return 1
      fi
      : >"$rollback_dir/switched" || {
        warn "can't mark the NectarLink transaction as switched"
        return 1
      }
      info "marked NectarLink $new as switched"
    }

    commit() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "commit: unexpected argument: $1"

      lock_state
      if [[ ! -d $rollback_dir ]]; then
        info "no pending NectarLink update to commit"
        return 0
      fi
      transaction_matches_repo || die "pending NectarLink transaction belongs to another checkout"

      local stage current new
      stage=$(transaction_stage)
      if [[ $stage != switched ]]; then
        warn "NectarLink transaction is not marked switched; run mark-switched first"
        return 1
      fi
      current=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      new=$(cat "$rollback_dir/new_tag" 2>/dev/null || true)
      if [[ -z $new ]]; then
        warn "incomplete NectarLink transaction; leaving it for recovery"
        return 1
      fi
      if [[ $current != "$new" ]]; then
        warn "pin is $current, not $new; leaving the transaction for recovery"
        return 1
      fi

      clear_transaction || return 1
      info "committed NectarLink $new"
    }

    recover() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "recover: unexpected argument: $1"

      lock_state
      if [[ ! -d $rollback_dir ]]; then
        info "no pending NectarLink update to recover"
        return 0
      fi
      recover_transaction
    }

    rollback() {
      local clear_queued=false
      local allow_switched=false
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      while (($# > 0)); do
        case $1 in
        --clear-queued)
          clear_queued=true
          shift
          ;;
        --allow-switched)
          allow_switched=true
          shift
          ;;
        *)
          die_usage "rollback: unknown option: $1"
          ;;
        esac
      done

      lock_state
      if [[ ! -d $rollback_dir ]]; then
        info "no pending NectarLink update to roll back"
        return 0
      fi
      transaction_matches_repo || die "pending NectarLink transaction belongs to another checkout"
      if [[ $(transaction_stage) == switched && $allow_switched == false ]]; then
        warn "the NectarLink update is already switched; run 'home-manager switch --rollback' first, then retry with --allow-switched"
        return 1
      fi
      rollback_transaction "$clear_queued"
    }

    has_pending() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "has-pending: unexpected argument: $1"
      [[ -d $rollback_dir ]] || return 1
      transaction_matches_repo
    }

    latest_valid_tag() {
      local tags tag state
      if ! tags=$(latest_tags); then
        return 2
      fi
      while IFS= read -r tag; do
        [[ -n $tag ]] || continue
        if validate_release "$tag"; then
          printf '%s\n' "$tag"
          return 0
        else
          state=$?
          if ((state == 2 || state == 3)); then
            return "$state"
          fi
        fi
      done <<<"$tags"
      return 1
    }

    rewrite_flake() {
      local current=$1 latest=$2
      local matches tmp new_flake_hash old_lock_hash expected_flake_hash current_flake_hash

      [[ $(pinned_tag) == "$current" ]] ||
        die "NectarLink pin changed during update; aborting"
      matches=$(awk -v prefix="$nectarlink_input_prefix" '{n += gsub(prefix, "&")} END {print n}' "$repo/flake.nix")
      [[ $matches -eq 1 ]] ||
        die "expected exactly one NectarLink input in flake.nix, found $matches"

      begin_transaction "$current" "$latest" ||
        die "can't start a NectarLink transaction"

      if ! tmp=$(mktemp "$repo/flake.nix.XXXXXX"); then
        rollback_or_die "can't create a temporary flake"
      fi
      if ! sed -E "s#($nectarlink_input_prefix)[^\"]+#\1$latest#" \
        "$repo/flake.nix" >"$tmp"; then
        rm -f "$tmp"
        rollback_or_die "can't rewrite flake.nix"
      fi
      if ! grep -q "''${nectarlink_input_prefix}$latest\"" "$tmp"; then
        rm -f "$tmp"
        rollback_or_die "flake.nix rewrite did not produce $latest"
      fi
      if ! new_flake_hash=$(sha256sum "$tmp" | awk '{print $1}'); then
        rm -f "$tmp"
        rollback_or_die "can't hash the rewritten flake"
      fi
      old_lock_hash=""
      if [[ -f $repo/flake.lock ]]; then
        if ! old_lock_hash=$(sha256sum "$repo/flake.lock" | awk '{print $1}'); then
          rm -f "$tmp"
          rollback_or_die "can't hash the current lock"
        fi
      fi
      if ! {
        printf '%s  flake.nix\n' "$new_flake_hash"
        if [[ -n $old_lock_hash ]]; then
          printf '%s  flake.lock\n' "$old_lock_hash"
        fi
      } >"$rollback_dir/updated.sha256.tmp" ||
        ! mv "$rollback_dir/updated.sha256.tmp" "$rollback_dir/updated.sha256"; then
        rm -f "$rollback_dir/updated.sha256.tmp"
        rollback_or_die "can't record the updated flake hash"
      fi

      [[ $(pinned_tag) == "$current" ]] ||
        rollback_or_die "NectarLink pin changed during update"
      expected_flake_hash=$(transaction_hash "$rollback_dir/old.sha256" flake.nix || true)
      if ! current_flake_hash=$(sha256sum "$repo/flake.nix" | awk '{print $1}'); then
        rollback_or_die "can't hash flake.nix before replacing it"
      fi
      [[ -n $expected_flake_hash && $current_flake_hash == "$expected_flake_hash" ]] ||
        rollback_or_die "flake.nix changed during update"

      : >"$rollback_dir/lock-updating" || rollback_or_die "can't mark the NectarLink lock update"
      if ! chmod --reference="$repo/flake.nix" "$tmp" || ! mv "$tmp" "$repo/flake.nix"; then
        rm -f "$tmp"
        rollback_or_die "can't replace flake.nix"
      fi

      if ! (cd "$repo" && timeout "$nix_timeout" nix flake update nectarlink); then
        rollback_or_die "nix flake update failed"
      fi

      if ! (cd "$repo" && {
        sha256sum flake.nix
        [[ ! -f flake.lock ]] || sha256sum flake.lock
      } >"$rollback_dir/updated.sha256.tmp") ||
        ! mv "$rollback_dir/updated.sha256.tmp" "$rollback_dir/updated.sha256"; then
        rm -f "$rollback_dir/updated.sha256.tmp"
        rollback_or_die "can't record the updated flake hashes"
      fi
      rm -f "$rollback_dir/lock-updating" || rollback_or_die "can't finish the NectarLink lock update"
      : >"$rollback_dir/locked" || rollback_or_die "can't mark the NectarLink transaction as locked"
    }

    update() {
      local dry_run=false
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      while (($# > 0)); do
        case $1 in
        --dry-run)
          dry_run=true
          shift
          ;;
        *)
          die_usage "update: unknown option: $1"
          ;;
        esac
      done

      [[ -f $repo/flake.nix ]] || die "no flake.nix in $repo"

      recovered_switched=0
      if [[ $dry_run == false ]]; then
        lock_state
        recover_transaction || die "can't recover the pending NectarLink transaction"
      fi

      local current latest latest_state
      current=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      [[ $current =~ $version_tag_regex ]] ||
        die "pinned NectarLink ref is not a version tag: $current"
      if latest=$(latest_valid_tag); then
        :
      else
        latest_state=$?
        if ((latest_state == 2)); then
          die "can't reach the NectarLink release feed; try again later"
        fi
        if ((latest_state == 3)); then
          die "can't create a temporary file for release validation"
        fi
        die "no nightly release with an APK was found"
      fi

      if tag_is_current_or_newer "$current" "$latest"; then
        info "already on $current"
        if [[ $dry_run == false && $recovered_switched -eq 1 ]]; then
          return 5
        fi
        return 3
      fi

      if [[ $dry_run == true ]]; then
        printf '%s\n' "$latest"
        return 0
      fi

      local tag=$latest apk_name apk_dir apk sums
      apk_name=$(release_apk_name "$tag")
      apk_dir="$cache_dir/$tag"
      apk="$apk_dir/$apk_name"
      sums="$apk_dir/SHA256SUMS.txt"
      download_and_verify_apk "$tag" "$apk_name" "$apk" "$sums"

      rewrite_flake "$current" "$latest"
      printf '%s\n' "$latest"
    }

    fetch() {
      local url=$1 out=$2 quiet=''${3:-}
      local tmp="$out.part"
      rm -f "$tmp"
      if [[ $quiet == true ]]; then
        curl -fsSL --retry "$download_retries" --retry-delay "$download_retry_delay" --connect-timeout "$download_connect_timeout" --max-time "$curl_max_time" \
          -o "$tmp" "$url" || {
          rm -f "$tmp"
          return 1
        }
      else
        curl -fL --retry "$download_retries" --retry-delay "$download_retry_delay" --connect-timeout "$download_connect_timeout" --max-time "$curl_max_time" \
          --progress-bar -o "$tmp" "$url" || {
          rm -f "$tmp"
          return 1
        }
      fi
      mv "$tmp" "$out"
    }

    read_api_credentials() {
      local token_file=$data_dir/api-token.json
      if [[ ! -f $token_file ]]; then
        api_error="local API credentials not found"
        return 1
      fi
      if ! jq -e '
        (.token | type) == "string" and
        ((.port | type) == "number" or (.port | type) == "string" or .port == null)
      ' "$token_file" >/dev/null 2>&1; then
        api_error="local API credentials are invalid"
        return 1
      fi
      if ! api_port=$(jq -r --argjson default "$default_api_port" '.port // $default' "$token_file"); then
        api_error="local API credentials are unreadable"
        return 1
      fi
      if ! api_token=$(jq -r '.token // empty' "$token_file"); then
        api_error="local API credentials are unreadable"
        return 1
      fi
      if [[ -z $api_token ]]; then
        api_error="local API token is empty"
        return 1
      fi
      if [[ ! $api_port =~ ^[0-9]+$ ]] || ((10#$api_port < 1 || 10#$api_port > 65535)); then
        api_error="local API port is invalid"
        return 1
      fi
      api_port=$((10#$api_port))
      if [[ ! $api_token =~ ^[[:graph:]]+$ ]]; then
        api_error="local API token is invalid"
        return 1
      fi
    }

    load_devices_json() {
      read_api_credentials || return 1
      local response status
      if response=$(curl -fsS --connect-timeout "$api_connect_timeout" --max-time "$api_request_timeout" \
        -H "Authorization: Bearer $api_token" \
        --noproxy '*' "http://127.0.0.1:$api_port/v1/devices" 2>/dev/null); then
        :
      else
        status=$?
        api_error="local API request failed (curl $status)"
        return 1
      fi
      if ! jq -e '
        (.devices | type) == "array" and
        all(.devices[];
          (.id | type) == "string" and
          (.id | test("^[A-Za-z0-9_-]+$")) and
          (.name | type) == "string" and
          (.platform | type) == "string" and
          (.online | type) == "boolean"
        )' >/dev/null 2>&1 <<<"$response"; then
        api_error="unexpected local API response"
        return 1
      fi
      devices_json=$response
    }

    wait_for_devices() {
      local attempt
      for ((attempt = 1; attempt <= api_wait_attempts; attempt++)); do
        if load_devices_json; then
          return 0
        fi
        if ((attempt < api_wait_attempts)); then
          sleep "$api_poll_interval"
        fi
      done
      return 1
    }

    pending_device_count() {
      local devices_json=$1 marker_dir=$2
      local count=0 id
      while IFS=$'\t' read -r id _; do
        [[ -f "$marker_dir/$id" ]] || count=$((count + 1))
      done < <(android_devices <<<"$devices_json")
      printf '%s\n' "$count"
    }

    android_devices() {
      jq -r '.devices[] | select(.platform == "android") | [.id, .name, (.online | tostring)] | @tsv'
    }

    count_android_devices() {
      jq '[.devices[] | select(.platform == "android")] | length'
    }

    count_online_android_devices() {
      jq '[.devices[] | select(.platform == "android" and .online)] | length'
    }

    select_send_targets() {
      local tag=$1 only_unmarked=$2 id name online
      while IFS=$'\t' read -r id name online; do
        [[ $online == true ]] || continue
        if [[ $only_unmarked == true && -f $queued_dir/$tag/$id ]]; then
          continue
        fi
        printf '%s\t%s\n' "$id" "$name"
      done < <(android_devices)
    }

    queue_apk() {
      local id=$1 name=$2 apk=$3 port=$4 token=$5 payload
      payload=$(jq -n --arg device "$id" --arg path "$apk" '{device: $device, paths: [$path]}')
      if curl -fsS --connect-timeout "$send_connect_timeout" --max-time "$http_timeout" -X POST \
        -H "Authorization: Bearer $token" \
        -H 'Content-Type: application/json' \
        --data "$payload" \
        --noproxy '*' "http://127.0.0.1:$port/v1/send" >/dev/null; then
        printf 'Queued APK for %s.\n' "$name"
        return 0
      fi
      warn "failed to queue APK for $name"
      return 1
    }

    show_send_plan() {
      local tag=$1 pending=$2 devices_json=$3 marker_dir=$queued_dir/$1
      if [[ -z $devices_json ]]; then
        printf 'Would queue APK for %s (%s).\n' "$tag" "''${api_error:-local API unavailable}"
        return 0
      fi

      local total
      total=$(count_android_devices <<<"$devices_json")
      if ((total == 0)); then
        printf 'No paired Android devices.\n'
        return 0
      fi

      local -a targets=()
      mapfile -t targets < <(select_send_targets "$tag" "$pending" <<<"$devices_json")
      local target
      for target in "''${targets[@]}"; do
        printf 'Would queue APK for %s.\n' "''${target#*$'\t'}"
      done

      if ((''${#targets[@]} == 0)); then
        local missing
        missing=$(pending_device_count "$devices_json" "$marker_dir")
        if ((missing == 0)); then
          printf 'All paired Android devices are already queued.\n'
        else
          printf '%d Android device(s) still need the APK; would queue when online.\n' "$missing"
        fi
      else
        printf 'Would queue %d transfer(s).\n' "''${#targets[@]}"
      fi
    }

    download_and_verify_apk() {
      local tag=$1 apk_name=$2 apk=$3 sums=$4
      local expected actual attempt
      mkdir -p "$(dirname "$apk")"

      for ((attempt = 0; attempt < download_attempts; attempt++)); do
        if [[ ! -f $sums ]]; then
          fetch "$releases/$tag/SHA256SUMS.txt" "$sums" true ||
            die "can't download SHA256SUMS.txt for $tag"
        fi

        expected=$(awk -v file="$apk_name" '$2 == file {print $1; exit}' "$sums")
        if [[ -z $expected ]]; then
          warn "no checksum for $apk_name; refreshing SHA256SUMS.txt"
          rm -f "$sums"
          continue
        fi

        if [[ -f $apk ]]; then
          actual=$(sha256sum "$apk" | awk '{print $1}')
          if [[ $actual == "$expected" ]]; then
            info "APK: $apk"
            info "SHA-256: $actual"
            return 0
          fi
          warn "cached APK failed verification; downloading again"
          rm -f "$apk"
        fi

        fetch "$releases/$tag/$apk_name" "$apk" || die "can't download $apk_name"
        actual=$(sha256sum "$apk" | awk '{print $1}')
        if [[ $actual == "$expected" ]]; then
          info "APK: $apk"
          info "SHA-256: $actual"
          return 0
        fi

        warn "downloaded APK failed verification; refreshing the cache"
        rm -f "$apk" "$sums"
      done

      die "APK checksum mismatch for $apk"
    }

    send_dry_run() {
      local tag=$1 pending=$2 devices_json=""

      if [[ -z $tag ]]; then
        tag=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      fi
      [[ $tag =~ $version_tag_regex ]] ||
        die "expected a version tag, got $tag"
      load_devices_json || true
      show_send_plan "$tag" "$pending" "$devices_json"
      return 0
    }

    send_apk() {
      local tag=$1 pending=$2 mark_queued=$3
      local marker_dir devices_json=""

      lock_state
      if [[ -z $tag ]]; then
        tag=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      fi
      [[ $tag =~ $version_tag_regex ]] ||
        die "expected a version tag, got $tag"

      marker_dir="$queued_dir/$tag"
      local apk_name apk_dir apk sums
      apk_name=$(release_apk_name "$tag")
      apk_dir="$cache_dir/$tag"
      apk="$apk_dir/$apk_name"
      sums="$apk_dir/SHA256SUMS.txt"

      local api_port api_token
      if ! read_api_credentials; then
        warn "''${api_error:-NectarLink local API credentials not found}; will retry"
        return 4
      fi

      if ! wait_for_devices; then
        warn "''${api_error:-NectarLink local API is not available}; will retry"
        return 4
      fi

      local total_android online_android
      total_android=$(count_android_devices <<<"$devices_json")
      if ((total_android == 0)); then
        warn "no paired Android devices"
        return 4
      fi
      online_android=$(count_online_android_devices <<<"$devices_json")

      local -a targets=()
      mapfile -t targets < <(select_send_targets "$tag" "$pending" <<<"$devices_json")
      if ((''${#targets[@]} == 0)); then
        if [[ $pending == true ]]; then
          local missing
          missing=$(pending_device_count "$devices_json" "$marker_dir")
          if ((missing == 0)); then
            info "APK $tag is queued for all paired Android devices"
            return 0
          fi
          info "$missing Android device(s) still need the APK; will retry"
          return 4
        fi
        info "no online Android devices; will retry"
        return 4
      fi

      download_and_verify_apk "$tag" "$apk_name" "$apk" "$sums"

      local queued=0 failed=0 target id name
      for target in "''${targets[@]}"; do
        id=''${target%%$'\t'*}
        name=''${target#*$'\t'}
        if queue_apk "$id" "$name" "$apk" "$api_port" "$api_token"; then
          queued=$((queued + 1))
          if [[ $pending == true || $mark_queued == true ]]; then
            mkdir -p "$marker_dir"
            : >"$marker_dir/$id"
          fi
        else
          failed=1
        fi
      done

      if ((failed == 1)); then
        return 1
      fi

      if [[ $pending == true ]]; then
        local missing
        missing=$(pending_device_count "$devices_json" "$marker_dir")
        if ((missing > 0)); then
          info "$missing Android device(s) still need the APK; will retry"
          return 4
        fi
      elif ((online_android != total_android)); then
        info "$((total_android - online_android)) Android device(s) offline; will retry"
        return 4
      fi

      info "APK $tag is queued for all paired Android devices ($queued queued, $((total_android - queued)) already present)"
      return 0
    }

    send() {
      local tag=""
      local pending=false
      local mark_queued=false
      local dry_run=false
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      while (($# > 0)); do
        case $1 in
        --tag)
          (($# >= 2)) || die_usage "--tag needs a value"
          [[ -n $2 ]] || die_usage "--tag needs a non-empty value"
          tag=$2
          shift 2
          ;;
        --pending)
          pending=true
          shift
          ;;
        --mark-queued)
          mark_queued=true
          shift
          ;;
        --dry-run)
          dry_run=true
          shift
          ;;
        *)
          die_usage "send: unknown option: $1"
          ;;
        esac
      done

      if [[ $dry_run == true ]]; then
        send_dry_run "$tag" "$pending"
        return
      fi
      send_apk "$tag" "$pending" "$mark_queued"
    }

    status() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "status: unexpected argument: $1"

      ensure_dirs
      local current latest latest_state
      current=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      if latest=$(latest_valid_tag); then
        :
      else
        latest_state=$?
        if ((latest_state == 2)); then
          latest="unreachable"
        else
          latest="unknown"
        fi
      fi
      printf 'Pinned: %s\n' "$current"
      printf 'Latest: %s\n' "$latest"
      printf 'State:  %s\n' "$state_dir"
      if [[ -d $rollback_dir ]]; then
        if transaction_matches_repo; then
          printf 'Pending transaction: %s\n' "$(cat "$rollback_dir/new_tag" 2>/dev/null || true)"
        else
          printf 'Pending transaction: another checkout\n'
        fi
      fi

      local devices_json
      if ! load_devices_json; then
        printf 'Devices: %s\n' "''${api_error:-NectarLink local API is not available}"
        return 0
      fi

      printf 'Devices:\n'
      local device id name online marker
      while IFS= read -r device; do
        id=$(jq -r '.id' <<<"$device")
        name=$(jq -r '.name' <<<"$device")
        online=$(jq -r 'if .online then "online" else "offline" end' <<<"$device")
        if [[ ! $current =~ $version_tag_regex ]]; then
          marker=unknown
        elif [[ -f "$queued_dir/$current/$id" ]]; then
          marker=queued
        else
          marker=pending
        fi
        printf '  %-20s %-8s %s\n' "$name" "$online" "$marker"
      done < <(jq -c '.devices[] | select(.platform == "android")' <<<"$devices_json")
    }

    latest() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "latest: unexpected argument: $1"
      local tag state
      if tag=$(latest_valid_tag); then
        :
      else
        state=$?
        if ((state == 2)); then
          die "can't reach the NectarLink release feed; try again later"
        fi
        if ((state == 3)); then
          die "can't create a temporary file for release validation"
        fi
        die "no nightly release with an APK was found"
      fi
      printf '%s\n' "$tag"
    }

    pinned() {
      remaining_args=()
      parse_common "$@"
      set -- "''${remaining_args[@]}"
      (($# == 0)) || die_usage "pinned: unexpected argument: $1"
      local tag
      tag=$(pinned_tag) || die "can't read the NectarLink input from $repo/flake.nix"
      printf '%s\n' "$tag"
    }

    case ''${1:-} in
    latest)
      shift
      latest "$@"
      ;;
    pinned)
      shift
      pinned "$@"
      ;;
    update)
      shift
      update "$@"
      ;;
    mark-switched)
      shift
      mark_switched "$@"
      ;;
    commit)
      shift
      commit "$@"
      ;;
    rollback)
      shift
      rollback "$@"
      ;;
    send)
      shift
      send "$@"
      ;;
    status)
      shift
      status "$@"
      ;;
    has-pending)
      shift
      has_pending "$@"
      ;;
    recover)
      shift
      recover "$@"
      ;;
    -h | --help)
      usage
      ;;
    "")
      usage >&2
      exit 2
      ;;
    *)
      usage >&2
      exit 2
      ;;
    esac
  '';
}
