{
  lib,
  stdenv,
  fetchFromGitHub,
  glib,
  version,
}:

let
  src = fetchFromGitHub {
    owner = "wheaney";
    repo = "breezy-desktop";
    rev = "v${version}";
    hash = "sha256-QY9PWx53HWsGeBkNC86hosGfw+mMdlzBI8UsYu53E44=";
    fetchSubmodules = true;
  };

  uuid = "breezydesktop@xronlinux.com";
in
stdenv.mkDerivation {
  pname = "gnome-shell-extension-breezy-desktop";
  inherit version src;

  nativeBuildInputs = [
    glib # for glib-compile-schemas
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    extDir=$out/share/gnome-shell/extensions/${uuid}
    mkdir -p $extDir

    # JavaScript source files
    cd gnome/src
    for f in *.js metadata.json; do
      install -Dm644 "$f" "$extDir/$f"
    done

    # Fragment shader (resolve symlink)
    cp -L Sombrero.frag "$extDir/Sombrero.frag"

    # D-Bus interfaces
    mkdir -p "$extDir/dbus-interfaces"
    cp dbus-interfaces/*.xml "$extDir/dbus-interfaces/"

    # Textures (resolve symlinks)
    mkdir -p "$extDir/textures"
    cp -L textures/* "$extDir/textures/"

    # GSettings schema (resolve symlink and compile)
    mkdir -p "$extDir/schemas"
    cp -L schemas/*.xml "$extDir/schemas/"
    glib-compile-schemas "$extDir/schemas"

    runHook postInstall
  '';

  meta = with lib; {
    description = "GNOME Shell extension for Breezy Desktop XR virtual display";
    homepage = "https://github.com/wheaney/breezy-desktop";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
