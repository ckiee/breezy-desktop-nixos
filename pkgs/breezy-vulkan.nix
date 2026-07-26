{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  glslang,
  spirv-headers,
  vulkan-headers,
  vulkan-loader,
  libx11,
  version,
}:

let
  src = fetchFromGitHub {
    owner = "wheaney";
    repo = "breezy-desktop";
    rev = "v${version}";
    hash = "sha256-rRDdvFhoI3nE9zET2Whr/BSQ3J7JQzpv7/UUdvfW4wY=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation {
  pname = "breezy-vulkan";
  inherit version;

  src = "${src}/vulkan/modules/vkBasalt";

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    glslang
  ];

  buildInputs = [
    spirv-headers
    vulkan-headers
    vulkan-loader
    libx11
  ];

  postInstall = let
    sombreroSrc = "${src}/modules/sombrero";
    vulkanSrc = "${src}/vulkan";
  in ''
    # Install sombrero shaders
    mkdir -p $out/share/breezy-vulkan/shaders
    cp ${sombreroSrc}/Sombrero.frag $out/share/breezy-vulkan/shaders/
    cp ${sombreroSrc}/calibrating.png $out/share/breezy-vulkan/shaders/ || true

    # Install breezy vulkan config
    install -Dm644 ${vulkanSrc}/config/vkBasalt.conf $out/share/breezy-vulkan/vkBasalt.conf

    # Install custom banner
    cp ${vulkanSrc}/custom_banner.png $out/share/breezy-vulkan/ || true
  '';

  meta = with lib; {
    description = "Vulkan post-processing layer for Breezy Desktop XR gaming";
    homepage = "https://github.com/wheaney/breezy-desktop";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
