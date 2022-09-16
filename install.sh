#!/usr/bin/env bash
set -e

if [ ! "$(command -v polymc)" ] && [ ! -x "/var/lib/flatpak/app/org.polymc.PolyMC/current/active/files/bin/polymc" ]; then
  echo "No PolyMC installation found, please install PolyMC and rerun this script"
  exit 1
fi

function add_fix_to_polymc() {
  local polymc_path=$1
  if [ -d "$polymc_path" ]; then
    if [ ! -f "$polymc_path/polymc.cfg" ]; then
      printf '\033[1m%s\033[0m\n' "$polymc_path/polymc.cfg not found, try launching PolyMC first"
      return 1
    else
      printf '\033[1m%s\033[0m\n' "Adding glfw fix to PolyMC \"$polymc_path\""
      cd "$polymc_path"

      cat >"$polymc_path/glfw_fix.sh" <<EOF
#!/usr/bin/env bash
cd "\$1"
mkdir natives
cp "\$(dirname "\$0")/libglfw.so" natives/
EOF

      wget https://github.com/FederAndInk/glfw_aqm2_fix/raw/main/libglfw.so -O "$polymc_path/libglfw.so"
      chmod +x "$polymc_path/libglfw.so"

      mv polymc.cfg "polymc.cfg-$(date '+%s').bak"
      sed -e "s|^PreLaunchCommand=.*$|PreLaunchCommand=bash \"$polymc_path/glfw_fix.sh\" \"\$INST_DIR\"|" -e 's/^UseNativeGLFW=false$/UseNativeGLFW=true/' polymc.cfg.bak >polymc.cfg
      if ! grep 'UseNativeGLFW=true' polymc.cfg; then
        echo 'UseNativeGLFW=true' >>polymc.cfg
      fi
      if ! grep -q "PreLaunchCommand=bash \"$polymc_path/glfw_fix.sh\" \"\$INST_DIR\"" polymc.cfg; then
        echo "PreLaunchCommand=bash \"$polymc_path/glfw_fix.sh\" \"\$INST_DIR\"" >>polymc.cfg
      fi
    fi
  fi
}

one_fixed=false

if add_fix_to_polymc "$HOME/.var/app/org.polymc.PolyMC/data/PolyMC"; then
  one_fixed=true
fi

if add_fix_to_polymc "$HOME/.local/share/PolyMC"; then
  one_fixed=true
fi

if ! $one_fixed; then
  printf '\033[1;31mNo fix applied! Try running polymc and rerun this\033[0m\n'
  exit 1
fi
