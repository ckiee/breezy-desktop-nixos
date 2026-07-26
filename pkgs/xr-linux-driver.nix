{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  python3,
  libusb1,
  libevdev,
  openssl,
  json_c,
  curl,
  wayland,
  systemd,
  rustPlatform,
  cargo,
  rustc,
  autoPatchelfHook,
  makeWrapper,
  jq,
  version,
}:

let
  arch = if stdenv.hostPlatform.isx86_64 then "x86_64"
         else if stdenv.hostPlatform.isAarch64 then "aarch64"
         else throw "Unsupported architecture for xr-linux-driver";

  src = fetchFromGitHub {
    owner = "wheaney";
    repo = "XRLinuxDriver";
    rev = "33f15b0e15b141e7664afcc4c09d2c19b62716c0";
    hash = "sha256-fbaNdv6vjRphYYSzbOYqmRK6c24hv1gkTh3xlql0VEU=";
    fetchSubmodules = true;
  };

  cargoRoot = "modules/xrealInterfaceLibrary/interface_lib/modules/xreal_one_driver";

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/${cargoRoot}/Cargo.lock";
  };
in
stdenv.mkDerivation {
  pname = "xr-linux-driver";
  inherit version src cargoDeps cargoRoot;

  nativeBuildInputs = [
    cmake
    pkg-config
    (python3.withPackages (ps: [ ps.pyyaml ]))
    cargo
    rustc
    rustPlatform.cargoSetupHook
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libusb1
    libevdev
    openssl
    json_c
    curl
    wayland
    systemd # for libudev
    stdenv.cc.cc.lib # libstdc++ for vendor SDKs
  ];

  # Prevent CMake from trying to run git submodule update
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'execute_process(COMMAND git submodule update --init --recursive' \
                     'message(STATUS "Skipping git submodule update in Nix build"'

    # Create a valid custom_banner_config.yml with defaults
    cat > custom_banner_config.yml <<EOF
    start_date: 0
    end_date: 0
    EOF
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  # The vendor .so blobs and hidapi-hidraw need libudev at link time
  NIX_LDFLAGS = "-ludev";

  installPhase = ''
    runHook preInstall

    # Main binary
    install -Dm755 xrDriver $out/bin/xrDriver

    # Vendor SDK shared libraries
    mkdir -p $out/lib
    for so in $src/lib/${arch}/*.so; do
      [ -f "$so" ] && install -Dm755 "$so" $out/lib/$(basename "$so")
    done
    if [ -d "$src/lib/${arch}/viture" ]; then
      for so in $src/lib/${arch}/viture/*.so*; do
        [ -f "$so" ] && install -Dm755 "$so" $out/lib/$(basename "$so")
      done
    fi

    # Install hidapi shared libs built during CMake
    find . -name 'libhidapi*.so*' \( -type f -o -type l \) | while read -r f; do
      cp -a "$f" $out/lib/
    done

    patchelf --set-rpath "$out/lib:${lib.makeLibraryPath [ systemd stdenv.cc.cc.lib curl openssl json_c libusb1 libevdev wayland ]}" $out/bin/xrDriver

    # CLI tool
    install -Dm755 $src/bin/xr_driver_cli $out/bin/xr_driver_cli
    wrapProgram $out/bin/xr_driver_cli \
      --prefix PATH : ${lib.makeBinPath [ jq curl ]}

    # Udev rules
    install -Dm644 $src/udev/70-xreal-xr.rules $out/lib/udev/rules.d/70-xreal-xr.rules
    install -Dm644 $src/udev/70-uinput-xr.rules $out/lib/udev/rules.d/70-uinput-xr.rules
    install -Dm644 $src/udev/70-rayneo-xr.rules $out/lib/udev/rules.d/70-rayneo-xr.rules
    install -Dm644 $src/udev/70-rokid-xr.rules $out/lib/udev/rules.d/70-rokid-xr.rules
    install -Dm644 $src/udev/70-viture-xr.rules $out/lib/udev/rules.d/70-viture-xr.rules

    # Systemd user service
    install -Dm644 $src/systemd/xr-driver.service $out/lib/systemd/user/xr-driver.service
    substituteInPlace $out/lib/systemd/user/xr-driver.service \
      --replace-fail '{ld_library_path}' "$out/lib" \
      --replace-fail '{bin_dir}' "$out/bin"

    runHook postInstall
  '';

  # autoPatchelfHook will fix the vendor .so files
  autoPatchelfIgnoreMissingDeps = [ "libopencv_*" ];

  meta = with lib; {
    description = "Linux user-space driver for XR glasses (XREAL, Viture, RayNeo, Rokid)";
    homepage = "https://github.com/wheaney/XRLinuxDriver";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    maintainers = [ ];
  };
}
