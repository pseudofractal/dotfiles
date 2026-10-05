{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  mailRoot = "${config.home.homeDirectory}/mails";
  llamaPkgs = import inputs.nixpkgs-llama {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  llamaCppGpu = llamaPkgs.llama-cpp.override {cudaSupport = true;};
  personalTags = [
    "security"
    "bank"
    "trips"
    "travel"
    "aireads"
    "learn"
    "compete"
    "devreads"
    "news"
    "jobs"
    "orders"
    "shopping"
    "socials"
    "invest"
    "intl"
    "devtools"
    "accounts"
  ];
  iiserTags = [
    "career"
    "scholarships"
    "finance"
    "exams"
    "courses"
    "tsukuba"
    "council"
    "rooms"
    "mess"
    "facilities"
    "wellbeing"
    "notices"
    "fest"
    "clubs"
    "seminars"
    "library"
    "accounts"
    "thesis"
    "urgent"
    "lostfound"
    "faith"
    "debate"
    "peers"
    "faculty"
    "dev"
  ];
  lieer = {
    enable = true;
    sync.enable = true;
    settings.ignore_tags = ["ai-classified"];
    settings.ignore_remote_labels = [];
  };
  ruleMail = pkgs.writeShellApplication {
    name = "rule-mail";
    runtimeInputs = [pkgs.notmuch];
    text = ''
      account="''${1:-}"
      if [[ "$account" != iiser && "$account" != personal ]]; then
        echo "Usage: rule-mail {iiser|personal}" >&2
        exit 2
      fi
      notmuchConfig="--config=${config.xdg.configHome}/notmuch/default/config"
      accountMailScope="(path:$account/mail/cur or path:$account/mail/new)"
      if [[ "$account" == iiser ]]; then
        untaggedOnly="and not (tag:career or tag:scholarships or tag:finance or tag:exams or tag:courses or tag:tsukuba or tag:council or tag:rooms or tag:mess or tag:facilities or tag:wellbeing or tag:notices or tag:fest or tag:clubs or tag:seminars or tag:library or tag:accounts or tag:thesis or tag:urgent or tag:lostfound or tag:faith or tag:debate or tag:peers or tag:faculty or tag:dev)"
      else
        untaggedOnly="and not (tag:security or tag:bank or tag:trips or tag:travel or tag:aireads or tag:learn or tag:compete or tag:devreads or tag:news or tag:jobs or tag:orders or tag:shopping or tag:socials or tag:invest or tag:intl or tag:devtools or tag:accounts)"
      fi
      tag() {
        notmuch "$notmuchConfig" tag "+$1" -- "$accountMailScope $untaggedOnly and ($2)"
      }
      if [[ "$account" == iiser ]]; then
        tag career '(from:oppcell@iisermohali.ac.in) or (subject:placement* or subject:internship*)'
        tag scholarships '(subject:scholarship* or subject:fellowship* or subject:daad or subject:shreyas) or from:bserc'
        tag finance '(subject:invoice* or subject:fee or subject:fees or subject:flywire or subject:payment* or subject:reimburse* or subject:insurance*)'
        tag exams '((from:academic.office@iisermohali.ac.in or subject:exam* or subject:midsem* or subject:datesheet* or subject:evaluation* or subject:grade*) and not (subject:health and subject:exam*))'
        tag courses '(from:nptel or subject:course* or subject:assignment*)'
        tag tsukuba '(from:tsukuba or from:resceu or from:shikano or from:taylorandfrancis or from:go.jp) or subject:resceu'
        tag council '(from:src@iisermohali.ac.in or from:bsmsreps4@iisermohali.ac.in or from:bsmsreps5@iisermohali.ac.in) or (subject:senate or subject:"open house" or subject:gbm or subject:election*)'
        tag rooms '((subject:room or subject:rooms) and (subject:allot* or subject:swap or subject:exchange)) or subject:allotment* or ((subject:partition and subject:shifting) or (subject:hostel and subject:warden))'
        tag mess '(from:studentmess@iisermohali.ac.in or subject:mess or subject:canteen* or subject:menu or subject:menus or subject:lunch or subject:lunchbox or subject:dinner* or subject:breakfast* or subject:"food outlet")'
        tag facilities '((subject:water and subject:tank) or subject:lift* or subject:salon or (subject:washing and subject:machine) or subject:cleaning or subject:electricity or subject:internet or subject:wifi or subject:maintenance)'
        tag wellbeing '(subject:counselling or subject:insurance* or subject:well-being or subject:wellbeing or subject:"well being" or subject:medical* or subject:"mental health" or subject:donation* or subject:camp)'
        tag library '(from:librarian@iisermohali.ac.in)'
        tag notices '((from:deanstudents@iisermohali.ac.in or from:deanacad@iisermohali.ac.in or from:director@iisermohali.ac.in or from:academic.office@iisermohali.ac.in or from:librarian@iisermohali.ac.in or from:src@iisermohali.ac.in or from:studentmess@iisermohali.ac.in or from:oppcell@iisermohali.ac.in or from:iwd@iisermohali.ac.in or from:dord@iisermohali.ac.in or from:foundationday@iisermohali.ac.in or from:sahlawat@iisermohali.ac.in or from:bsmsreps4@iisermohali.ac.in or from:bsmsreps5@iisermohali.ac.in or from:manthanmagzine@iisermohali.ac.in or from:ads@iisermohali.ac.in or from:adaa@iisermohali.ac.in or from:deanoutreach@iisermohali.ac.in) or (subject:foundation and subject:day) or (subject:thank and subject:you) or subject:grateful or subject:swachhata or subject:pledge or subject:condolence* or subject:demise)'
        tag fest '(subject:janmashtami or subject:handi or subject:bhandara or subject:diwali or subject:holi or subject:dandiya or subject:navratri or subject:christmas or subject:eid or subject:gurpurab or subject:lohri or subject:festival* or subject:celebration*)'
        tag clubs '((from:phiclub@iisermohali.ac.in or from:ambienteclub@iisermohali.ac.in or from:turingclub@iisermohali.ac.in or from:movieclub@iisermohali.ac.in or from:lumiereclub@iisermohali.ac.in or from:astronomyclub@iisermohali.ac.in or from:ariaclub@iisermohali.ac.in or from:bdfclub@iisermohali.ac.in or from:imqcclub@iisermohali.ac.in or from:gamingclub@iisermohali.ac.in or from:ldsclub@iisermohali.ac.in or from:curieclub@iisermohali.ac.in or from:danceclub@iisermohali.ac.in or from:darpanclub@iisermohali.ac.in or from:rangclub@iisermohali.ac.in or from:infinityclub@iisermohali.ac.in or from:insomnia@iisermohali.ac.in or from:miles@iisermohali.ac.in or from:manthanmagzine@iisermohali.ac.in) or (subject:workshop* or subject:meetup* or subject:tournament* or subject:orientation or subject:astrophotography or subject:music or subject:macay or subject:patang or subject:movie* or subject:screening*))'
        tag seminars '(subject:seminar* or subject:talk* or subject:colloquium or subject:rqi or subject:dcs or subject:hss or subject:conference* or subject:workshop*)'
        tag accounts '(subject:security or subject:activate* or subject:verify* or subject:registration* or subject:esta) or (from:notion or from:grammarly or from:openai or from:google.com)'
        tag thesis '(subject:thesis* or subject:dissertation* or subject:synopsis*) or (from:jasjeet@iisermohali.ac.in and to:ms22174@iisermohali.ac.in)'
        tag urgent '(subject:blood or subject:emergency* or subject:urgent)'
        tag lostfound '(subject:missing or subject:lost or subject:taken or subject:stolen or subject:theft* or subject:poster* or subject:cable* or subject:grievance* or subject:dog or subject:complaint* or subject:safety or subject:rti or subject:cctv)'
        tag faith '(subject:havan or subject:shanti or subject:puja or subject:aarti or subject:mandir or subject:chhath)'
        tag debate "(subject:letter* or subject:statement* or subject:demand* or subject:condemnation or subject:shame or subject:sexualisation or subject:discrimination* or subject:apology* or subject:tragic* or subject:\"why are\" or subject:\"for the women\" or subject:\"don't feel safe\" or subject:\"letter from\")"
        tag peers '(from:ms* or from:ph* or from:mp* or ((from:gmail.com or from:yahoo.com or from:outlook.com or from:hotmail.com) and (subject:book or subject:notes or subject:lecture or subject:assignment or subject:course)) or subject:"shared by")'
        tag faculty '(from:iisermohali.ac.in and not (from:deanstudents@iisermohali.ac.in or from:deanacad@iisermohali.ac.in or from:director@iisermohali.ac.in or from:academic.office@iisermohali.ac.in or from:librarian@iisermohali.ac.in or from:src@iisermohali.ac.in or from:studentmess@iisermohali.ac.in or from:oppcell@iisermohali.ac.in or from:iwd@iisermohali.ac.in or from:dord@iisermohali.ac.in or from:foundationday@iisermohali.ac.in or from:sahlawat@iisermohali.ac.in or from:bsmsreps4@iisermohali.ac.in or from:bsmsreps5@iisermohali.ac.in or from:manthanmagzine@iisermohali.ac.in or from:ads@iisermohali.ac.in or from:adaa@iisermohali.ac.in or from:deanoutreach@iisermohali.ac.in))'
        tag dev '(from:github.com or from:discoursemail.com or from:flutterflow.io)'
      else
        tag security '(subject:otp or subject:"verification code" or subject:"sign-in code" or subject:"security alert" or subject:"has been linked" or subject:"removed your bank" or subject:"privacy request" or subject:"delivery status" or subject:"oauth application" or subject:"login notification" or subject:"password changed" or subject:"password reset" or subject:"sign in to your" or subject:"new login to your" or subject:"new device" or subject:"logged in from" or subject:kyc) or (from:no-reply@accounts.google.com or from:haveibeenpwned.com or from:github.com or from:bitwarden.com or from:uidai.gov.in)'
        tag bank '(from:dcb.bank.in or from:slice.bank.in or from:sbicard.com or from:slicebank.com or from:dcbbank.com or from:goniyomx.com or from:goniyo.com) or (subject:debit* or subject:intimation or subject:credit* or subject:statement* or subject:repay* or subject:transact* or subject:balance)'
        tag trips '(subject:pnr or subject:itinerary* or subject:booking* or subject:ticket* or subject:boarding or subject:reservation*) or (subject:visa and not subject:card) or subject:"check-in"'
        tag travel '(from:skyscanner.com or from:goindigo.in or from:airindiaexpress.com or from:ubigi.com or from:airalo.com or from:malaysiaairlines.com or from:cleartrip.com or from:navitime.jp or from:vfsglobal.com or from:vfshelpline.com or from:easemytrip.com or from:balmerlawrietravelapp.com)'
        tag aireads '(from:theresanaiforthat.com or from:alphaxiv.org or from:z.ai or from:aiinsightblog or from:aiinsightsbiz or from:beehiiv.com)'
        tag learn '(from:duolingo.com or from:khanacademy.org or from:chess.com or from:koohii.com)'
        tag compete '(from:kaggle.com or from:marimo.io) or (subject:competition* or subject:hacktoberfest or subject:hackathon*)'
        tag devreads '(from:dev.to)'
        tag news '(from:nationalacademies.org or from:tbpn or from:medium.com or from:vivaldi.com)'
        tag jobs '(from:naukri.com or from:jobrxiv.org or from:deloitte.com or from:hr-manager.net) or subject:jobagenten'
        tag orders '(((from:steampowered.com or from:xiaomi.com or from:shop.app or from:bookmyshow.com or from:swiggy.in or from:adobe.com or from:wise.com or from:paypal.com or from:cloudflare.com or from:shopifyemail.com or from:stripe.com or from:jio.com or from:canva.com or from:trustpilotmail.com or from:anoma.ly or from:instamart.in or from:delhivery.com or from:paddle.com or from:zomato.com or from:home.id or from:bigbasket.com or from:coveritup.in) and (subject:shipped or subject:deliver* or subject:receipt* or subject:order* or subject:invoice* or subject:payment*)) or (subject:play and subject:receipt*))'
        tag shopping '((from:steampowered.com or from:xiaomi.com or from:shop.app or from:bookmyshow.com or from:swiggy.in or from:adobe.com or from:wise.com or from:paypal.com or from:cloudflare.com or from:shopifyemail.com or from:stripe.com or from:jio.com or from:canva.com or from:trustpilotmail.com or from:anoma.ly or from:instamart.in or from:delhivery.com or from:paddle.com or from:zomato.com or from:home.id or from:bigbasket.com or from:coveritup.in))'
        tag socials '(from:instagram.com or from:verify@x.com or from:info@x.com or from:reddit.com or from:redditmail.com or from:pinterest.com or from:linkedin.com or from:snapchat.com)'
        tag invest '(from:motilaloswal.com or from:nipponindia.email or from:groww.in or from:binance.com) or (subject:credit and (subject:report or subject:score))'
        tag intl '(from:tsukuba.ac.jp or from:resceu.s.u-tokyo.ac.jp or from:gtn-mobile.com or from:rakuten.co.jp or from:moneyforward.com or from:qrioinc.com or from:digital.go.jp or from:shikano or from:gtn or from:rakuten)'
        tag devtools '(from:cursor or from:deepseek or from:wolfram or from:flutterflow or from:zed or from:huggingface or from:oracle or from:cloudflare or from:codeberg or from:appsheet or from:microsoft or from:zoom)'
        tag accounts '((from:google.com or from:youtube.com or from:onetrust.com or from:googlemail.com or from:pika-network.net or from:openai.com or from:fiverr.com or from:zulip.com or from:godlike.host or from:mcserverhost.com or from:o-in.me) and not (from:notebooklm or from:notion))'
      fi
    '';
  };
  queryMap = maildir: tags: ''
    inbox=path:"${maildir}/mail/**" and tag:inbox
    unread=path:"${maildir}/mail/**" and tag:unread
    flagged=path:"${maildir}/mail/**" and tag:flagged
    recent=path:"${maildir}/mail/**" and date:2w..
    all=path:"${maildir}/mail/**"
    sent=path:"${maildir}/mail/**" and tag:sent
    drafts=path:"${maildir}/mail/**" and tag:draft
    spam=path:"${maildir}/mail/**" and tag:spam
    trash=path:"${maildir}/mail/**" and tag:trash
    ${lib.concatMapStringsSep "\n" (tag: "${tag}=path:\"${maildir}/mail/**\" and tag:${tag}") tags}
  '';
  emailClassifierModel = pkgs.fetchurl {
    url = "https://huggingface.co/distil-labs/distil-email-classifier/resolve/4a6502a92b1a67f8549bb892dd533617d25e589a/model.gguf";
    hash = "sha256-1lLLP+NKgZajrlMuY0zFAzf1mUV12O8DH9U4inP41rY=";
  };
  gmiLockFile = account: "${mailRoot}/${account}/.gmi.lock";
  lieerSync = account:
    pkgs.writeShellApplication {
      name = "lieer-sync-${account}";
      runtimeInputs = [pkgs.lieer pkgs.notmuch pkgs.util-linux];
      text = ''
        exec 9>"${gmiLockFile account}"
        if ! flock -n 9; then
          echo "lieer-sync-${account}: repo locked by another gmi instance; skipping" >&2
          exit 0
        fi
        gmi sync
        ${lib.getExe ruleMail} ${account}
        gmi push
      '';
    };
  lieerAuth = pkgs.writeShellApplication {
    name = "lieer-auth";
    runtimeInputs = [pkgs.lieer pkgs.notmuch];
    text = ''
      account="''${1:-}"
      if [[ "$account" != iiser && "$account" != personal ]]; then
        echo "Usage: lieer-auth {iiser|personal}" >&2
        exit 2
      fi

      export NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config
      notmuch new
      cd "${mailRoot}/$account"
      exec gmi auth
    '';
  };
  emailToggle = pkgs.writeShellApplication {
    name = "email-toggle";
    runtimeInputs = [pkgs.systemd pkgs.curl];
    text = ''
      timers=(lieer-iiser.timer lieer-personal.timer email-classify-backfill.timer)
      jobs=(lieer-iiser.service lieer-personal.service email-classify-backfill.service)
      clear_failed() {
        systemctl --user reset-failed "''${jobs[@]}" email-classifier.service email-classifier-gpu.service
      }
      wait_for_port_free() {
        for _ in $(seq 1 60); do
          if ! curl --silent --max-time 2 http://127.0.0.1:8013/health >/dev/null 2>&1; then
            return 0
          fi
          sleep 2
        done
        echo "port 8013 still busy after 2 minutes" >&2
        return 1
      }
      case "''${1:-toggle}" in
        off)
          systemctl --user stop "''${timers[@]}" "''${jobs[@]}" email-classifier.service email-classifier-gpu.service
          clear_failed
          ;;
        on)
          systemctl --user stop email-classifier.service email-classifier-gpu.service
          wait_for_port_free
          systemctl --user start email-classifier.service "''${timers[@]}"
          ;;
        full)
          systemctl --user stop email-classifier.service email-classifier-gpu.service
          wait_for_port_free
          systemctl --user start email-classifier-gpu.service "''${timers[@]}"
          systemctl --user --no-block start "''${jobs[@]}"
          echo "email fetching and classification: full speed (NVIDIA GPU, CPU service stopped)"
          ;;
        toggle)
          if systemctl --user is-active --quiet lieer-iiser.timer; then
            systemctl --user stop "''${timers[@]}" "''${jobs[@]}" email-classifier.service email-classifier-gpu.service
            clear_failed
            echo "email fetching and classification: off"
          else
            systemctl --user stop email-classifier-gpu.service
            systemctl --user restart email-classifier.service
            systemctl --user start "''${timers[@]}"
            echo "email fetching and classification: on"
          fi
          ;;
        *)
          echo "Usage: email-toggle [on|off|full|toggle]" >&2
          exit 2
          ;;
      esac
      systemctl --user is-active "''${timers[@]}" email-classifier.service
    '';
  };
  aercAccount = {
    account,
    address,
    maildir,
    passwordFile,
    queryMapFile,
    tags,
  }: {
    source = "notmuch://";
    maildir-account-path = maildir;
    query-map = queryMapFile;
    default = "inbox";
    folders-sort = ["inbox" "unread" "flagged" "recent"] ++ tags ++ ["all" "sent" "drafts" "spam" "trash"];
    from = "Kshitish Kumar Ratha <${address}>";
    outgoing = "smtps://${lib.strings.escapeURL address}@smtp.gmail.com:465";
    outgoing-cred-cmd = "${lib.getExe' pkgs.coreutils "cat"} ${passwordFile}";
    check-mail = "5m";
    check-mail-cmd = "${pkgs.systemd}/bin/systemctl --user --no-block start lieer-${account}.service";
    check-mail-timeout = "10m";
    cache-headers = true;
  };
  classifyBackfill = pkgs.writeShellApplication {
    name = "classify-backfill";
    runtimeInputs = [pkgs.gawk pkgs.lieer pkgs.notmuch pkgs.util-linux];
    text = ''
      avail_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"
      if (( avail_kb < 4 * 1024 * 1024 )); then
        echo "classify-backfill: only $((avail_kb / 1024)) MiB available, keeping 4 GiB buffer; skipping" >&2
        exit 0
      fi
      classify_and_push() {
        (
          exec 9>"${mailRoot}/$1/.gmi.lock"
          if ! flock -n 9; then
            echo "classify-backfill: $1 repo locked by another gmi instance; skipping" >&2
            exit 0
          fi
          cd "${mailRoot}/$1"
          ${lib.getExe ruleMail} "$1"
          if ! gmi push; then
            echo "classify-backfill: $1 gmi push failed; will retry on the next run" >&2
          fi
        )
      }
      classify_and_push iiser
      classify_and_push personal
    '';
  };
in {
  accounts.email.maildirBasePath = mailRoot;

  accounts.email.accounts = {
    iiser = {
      address = "ms22174@iisermohali.ac.in";
      userName = "ms22174@iisermohali.ac.in";
      realName = "Kshitish Kumar Ratha";
      primary = true;
      flavor = "gmail.com";
      maildir.path = "iiser";
      passwordCommand = [
        "${pkgs.coreutils}/bin/cat"
        config.sops.secrets."mail/app-passwords/google/iiser".path
      ];

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
      folders = {
        inbox = "INBOX";
        sent = null;
        drafts = "[Gmail]/Drafts";
        trash = "[Gmail]/Trash";
      };
      inherit lieer;
      notmuch.enable = true;
    };

    personal = {
      address = "kshitishkumarratha@gmail.com";
      userName = "kshitishkumarratha@gmail.com";
      realName = "Kshitish Kumar Ratha";
      flavor = "gmail.com";
      maildir.path = "personal";
      passwordCommand = [
        "${pkgs.coreutils}/bin/cat"
        config.sops.secrets."mail/app-passwords/google/personal".path
      ];

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
      folders = {
        inbox = "INBOX";
        sent = null;
        drafts = "[Gmail]/Drafts";
        trash = "[Gmail]/Trash";
      };
      inherit lieer;
      notmuch.enable = true;
    };
  };

  programs.notmuch = {
    enable = true;
    new.tags = [];
  };

  services.lieer.enable = true;

  home.sessionVariables.NOTMUCH_CONFIG = "${config.xdg.configHome}/notmuch/default/config";

  home.packages = [lieerAuth emailToggle];

  home.activation.lieerMaildirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p \
      "${mailRoot}/iiser/mail/cur" \
      "${mailRoot}/iiser/mail/new" \
      "${mailRoot}/iiser/mail/tmp" \
      "${mailRoot}/personal/mail/cur" \
      "${mailRoot}/personal/mail/new" \
      "${mailRoot}/personal/mail/tmp"
  '';

  systemd.user.services = {
    lieer-iiser = {
      Unit.ConditionPathExists = lib.mkForce "${mailRoot}/iiser/.credentials.gmailieer.json";
      Service.ExecStart = lib.mkForce "${lib.getExe (lieerSync "iiser")}";
    };
    lieer-personal = {
      Unit.ConditionPathExists = lib.mkForce "${mailRoot}/personal/.credentials.gmailieer.json";
      Service.ExecStart = lib.mkForce "${lib.getExe (lieerSync "personal")}";
    };
  };

  systemd.user.services.email-classifier = {
    Unit.Description = "Local email classification model (CPU)";
    Service = {
      ExecStart = "${llamaPkgs.llama-cpp}/bin/llama-server --model ${emailClassifierModel} --host 127.0.0.1 --port 8013 --alias email-classifier --parallel 1 --ctx-size 8192 --batch-size 128 --n-gpu-layers 0";
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStopSec = "5min";
      Nice = 19;
      CPUQuota = "5%";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.email-classifier-gpu = {
    Unit.Description = "Local email classification model (NVIDIA GPU)";
    Service = {
      ExecStart = "${llamaCppGpu}/bin/llama-server --model ${emailClassifierModel} --host 127.0.0.1 --port 8013 --alias email-classifier --parallel 1 --ctx-size 8192 --batch-size 128 --n-gpu-layers 99";
      Environment = [
        "LD_LIBRARY_PATH=/usr/lib:/usr/lib64"
        "GGML_BACKEND_PATH=${llamaCppGpu}/bin/libggml-cuda.so"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      Nice = 19;
      CPUQuota = "200%";
    };
  };

  systemd.user.services.email-classify-backfill = {
    Unit.Description = "Low-priority email classification backfill";
    Unit.ConditionACPower = true;
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe classifyBackfill;
      Nice = 19;
      CPUWeight = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.email-classify-backfill = {
    Unit.Description = "Low-priority email classification backfill";
    Timer = {
      OnCalendar = "*:0/10";
      RandomizedDelaySec = 120;
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };

  home.file."${config.xdg.configHome}/aerc/binds.conf" = {
    force = true;
    text =
      lib.replaceStrings
      ["[messages]\n"]
      ["[messages]\nRd = :read<Enter>\n"]
      (builtins.readFile "${config.programs.aerc.package}/share/aerc/binds.conf");
  };

  programs.aerc = {
    enable = true;
    extraAccounts = {
      "Gmail (IISER)" = aercAccount {
        account = "iiser";
        address = "ms22174@iisermohali.ac.in";
        maildir = "iiser";
        passwordFile = config.sops.secrets."mail/app-passwords/google/iiser".path;
        queryMapFile = "${config.xdg.configHome}/aerc/notmuch-iiser";
        tags = iiserTags;
      };
      "Gmail (Personal)" = aercAccount {
        account = "personal";
        address = "kshitishkumarratha@gmail.com";
        maildir = "personal";
        passwordFile = config.sops.secrets."mail/app-passwords/google/personal".path;
        queryMapFile = "${config.xdg.configHome}/aerc/notmuch-personal";
        tags = personalTags;
      };
    };
    extraConfig = {
      compose.editor = lib.getExe pkgs.neovim;
      general.unsafe-accounts-conf = true;
      viewer.pager = "${lib.getExe pkgs.bat} --paging=always --pager=builtin --style=plain --color=always --strip-ansi=never";
      filters = {
        ".headers" = "colorize";
        "message/delivery-status" = "colorize";
        "message/rfc822" = "colorize";
        "text/calendar" = "calendar";
        "text/html" = "! html";
        "text/plain" = "colorize";
      };
    };
    stylesets."catppuccin-mocha" = lib.mkForce ''
      *.default=true
      *.normal=true

      default.fg=#cdd6f4
      default.bg=#1e1e2e

      title.fg=#89b4fa
      title.bg=#1e1e2e
      title.bold=true

      error.fg=#f38ba8
      warning.fg=#fab387
      success.fg=#a6e3a1

      tab.fg=#a6adc8
      tab.bg=#313244
      tab.selected.fg=#1e1e2e
      tab.selected.bg=#89b4fa
      tab.selected.bold=true

      border.fg=#585b70
      border.bold=true

      msglist_default.fg=#cdd6f4
      msglist_default.bg=#1e1e2e
      msglist_read.fg=#bac2de
      msglist_unread.fg=#f5c2e7
      msglist_unread.bold=true
      msglist_deleted.fg=#f38ba8
      msglist_flagged.fg=#f9e2af
      msglist_flagged.bold=true
      msglist_marked.fg=#1e1e2e
      msglist_marked.bg=#94e2d5
      msglist_result.fg=#89b4fa
      msglist_result.bold=true
      msglist_*.selected.fg=#1e1e2e
      msglist_*.selected.bg=#89b4fa
      msglist_*.selected.bold=true

      dirlist_default.fg=#cdd6f4
      dirlist_default.bg=#1e1e2e
      dirlist_unread.fg=#94e2d5
      dirlist_*.selected.fg=#1e1e2e
      dirlist_*.selected.bg=#94e2d5
      dirlist_*.selected.bold=true

      statusline_default.fg=#cdd6f4
      statusline_default.bg=#313244
      statusline_error.fg=#f38ba8
      statusline_warning.fg=#fab387
      statusline_success.fg=#a6e3a1
      statusline_error.bold=true
      statusline_success.bold=true

      selector_focused.fg=#cdd6f4
      selector_focused.bg=#45475a
      completion_default.fg=#cdd6f4
      completion_default.bg=#313244
      completion_default.selected.fg=#1e1e2e
      completion_default.selected.bg=#cba6f7

      part_switcher.fg=#cdd6f4
      part_switcher.bg=#313244
      part_switcher.selected.fg=#1e1e2e
      part_switcher.selected.bg=#cba6f7
      part_switcher.selected.bold=true
      part_filename.fg=#f9e2af
      part_filename.bg=#313244
      part_filename.selected.fg=#1e1e2e
      part_filename.selected.bg=#cba6f7
      part_mimetype.fg=#89b4fa
      part_mimetype.bg=#313244
      part_mimetype.selected.fg=#1e1e2e
      part_mimetype.selected.bg=#cba6f7

      [viewer]
      url.fg=#89b4fa
      url.underline=true
      header.fg=#89b4fa
      header.bold=true
      signature.fg=#9399b2
      signature.dim=true
      diff_meta.fg=#cba6f7
      diff_meta.bold=true
      diff_chunk.fg=#89b4fa
      diff_chunk_func.fg=#89b4fa
      diff_chunk_func.bold=true
      diff_add.fg=#a6e3a1
      diff_del.fg=#f38ba8
      diff_whitespace.bg=#f38ba8
      quote_*.fg=#6c7086
      quote_1.fg=#9399b2
    '';
  };

  xdg.configFile = {
    "aerc/notmuch-iiser".text = queryMap "iiser" iiserTags;
    "aerc/notmuch-personal".text = queryMap "personal" personalTags;
  };
}
