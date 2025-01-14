#!/usr/bin/env bash
set -e

if [ ! "$(command -v prismlauncher)" ] && { [ ! "$(command -v flatpak)" ] || ! flatpak list | grep "Prism Launcher" >/dev/null; }; then
  echo "No PrismLauncher installation found, please install PrismLauncher and rerun this script"
  exit 1
fi

function add_fix_to_prismlauncher() {
  local prismlauncher_path=$1
  if [ -d "$prismlauncher_path" ]; then
    if [ ! -f "$prismlauncher_path/prismlauncher.cfg" ]; then
      printf '\033[1m%s\033[0m\n' "$prismlauncher_path/prismlauncher.cfg not found, try launching PrismLauncher first"
      return 1
    else
      printf '\033[1m%s\033[0m\n' "Adding glfw fix to PrismLauncher \"$prismlauncher_path\""
      cd "$prismlauncher_path"

      wget https://github.com/xErrorAmelie/glfw_aqm2_fix/raw/main/libglfw.so -O "$prismlauncher_path/libglfw.so"
      chmod +x "$prismlauncher_path/libglfw.so"

      mv prismlauncher.cfg "prismlauncher.cfg.bak"
      sed -e "s|^JvmArgs=.*$|JvmArgs=-Dorg.lwjgl.glfw.libname=\"$prismlauncher_path/libglfw.so\"|" prismlauncher.cfg.bak >prismlauncher.cfg
    fi
  fi
}

one_fixed=false

if add_fix_to_prismlauncher "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher"; then
  one_fixed=true
fi

if add_fix_to_prismlauncher "$HOME/.local/share/PrismLauncher"; then
  one_fixed=true
fi

if add_fix_to_prismlauncher "$HOME/.local/share/PolyMC"; then
  one_fixed=true
fi

if ! $one_fixed; then
  printf '\033[1;31mNo fix applied! Try running prismlauncher and rerun this\033[0m\n'
  exit 1
fi
