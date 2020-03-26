####################################
# This is a script to demonstrate what is sourced when using a shell
#
# To use it, source it from command line:
# source path.sh
#
# To switch shell, use:
# For system zsh: chsh -s /bin/zsh
# For system bash: chsh -s /bin/bash
# For brew bash: chsh -s /usr/local/bin/bash (https://stackoverflow.com/a/11704224)
####################################

# Fail if exit code is not zero, in pipes, and also if variable is not set
# See: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euo pipefail

echo "Shell: '$SHELL'"
echo "Version: $($SHELL --version)"

declare -a files=(
  # Shared
  "$HOME/.profile"
  "/etc/profile"

  # zsh
  "$HOME/.zshrc"
  "$HOME/.zshenv"
  "$HOME/.zlogin"
  "$HOME/.zlogout"
  "$HOME/.zprofile"
  "/etc/zshenv"
  "/etc/zprofile"
  "/etc/zshrc"
  "/etc/zlogin"
  "/etc/zlogout"

  # bash
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.bash_login"
  "$HOME/.bash_logout"
  "/etc/bash.bashrc"
  "/etc/bashrc"
  )

# Clean
for f in "${files[@]}"; do
  sudo touch "$f"
  sudo sed -i '' '/SOURCE_ORIGINS/d' "$f"
  if [ -s "$f" ]; then
    echo "== File '$f' is not empty"
    # cat "$f"
  else
    sudo rm "$f"
    echo "** Removed empty file '$f'"
  fi
done

# for f in "${files[@]}"; do
#   sudo touch "$f"
#   name_to_append="$f"
#   if grep -q 'path_helper' "$f"; then
#     name_to_append="$f*"
#   fi
#   sudo echo "export SOURCE_ORIGINS=\"$name_to_append:\$SOURCE_ORIGINS\"" | sudo tee -a "$f" > /dev/null
# done

# echo "interactive_login: $SOURCE_ORIGINS"

# non_interactive_non_login=$(SOURCE_ORIGINS="";$SHELL -c 'echo $SOURCE_ORIGINS')
# echo "non_interactive_non_login: $non_interactive_non_login"

# non_interactive_login=$(SOURCE_ORIGINS="";$SHELL --login -c 'echo $SOURCE_ORIGINS')
# echo "non_interactive_login: $non_interactive_login"
