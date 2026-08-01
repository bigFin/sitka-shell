{pkgs, ...}:
pkgs.app2unit.overrideAttrs (final: prev: {
  postPatch =
    (prev.postPatch or "")
    + ''
      sed -i \
        -e '/^[[:space:]]*app-_/ { s/_\(\$[{]\)/\1/g; s/}_/}/g; s/app_name/app\\_name/g; }' \
        -e '/^app-/s/^/\t\t/' \
        app2unit.1.scd
    '';
})
