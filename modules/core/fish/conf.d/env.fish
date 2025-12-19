# Proxy Settings
# set -gx http_proxy http://172.16.2.250:3128
# set -gx https_proxy $http_proxy
# set -gx ftp_proxy $http_proxy
# set -gx all_proxy $http_proxy
# set -gx socks_proxy $http_proxy

# Pyenv Root
set -gx PYENV_ROOT "$HOME/.pyenv"

# Default Application Exporters
set -gx EDITOR "nvim"
set -gx READER "sioyek"
set -gx VISUAL "code"
set -gx TERMINAL "kitty"
set -gx BROWSER "zen-browser"
set -gx VIDEO "mpv"
set -gx IMAGE "imv"
set -gx COLORTERM "truecolor"
set -gx OPENER "xdg-open"
set -gx PAGER "bat"

# lf Variable Exporters
set -gx LF_BOOKMARK_PATH "$HOME/.config/lf/bookmark" # LF Bookmarks
