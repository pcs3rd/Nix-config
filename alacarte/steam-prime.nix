# PRIME hybrid graphics for steammachine's new board: two discrete PCIe GPUs,
# an AMD Radeon (primary — drives the display, same card handled today by
# steam-radeon.nix/jovian's amd.gpu path) and an NVIDIA card (secondary,
# render-offload only, no monitors attached).
#
# Both cards being in PCIe slots (not a soldered-down laptop iGPU) doesn't
# change anything about how PRIME is configured — NixOS's hardware.nvidia.prime
# module only cares about PCI bus IDs, not physical form factor.
#
# On bus IDs — NOT auto-detectable at boot, and here it barely matters:
# hardware.nvidia.prime.{amdgpu,nvidia}BusId are plain Nix strings baked into
# udev rules / Xorg config at *build* time. There's no NixOS mechanism to
# lspci-probe them at boot and feed the result back into these options — Nix
# builds are pure, so "detect PCI address, then configure the address"
# genuinely can't happen in one pass without a rebuild in between. In
# practice bus IDs are also stable per PCIe slot, so the standard NixOS
# workflow is "run lspci once after first boot, hardcode the result" rather
# than detecting it every boot.
#
# That said, on *this* host it's close to a non-issue either way: with
# services.xserver.enable = false (jovian/gamescope + COSMIC are Wayland-
# only — see steam-jovian.nix), the only consumers of these bus ID strings
# in nixpkgs' nvidia.nix are services.xserver.drivers/serverLayoutSection —
# i.e. generated Xorg config that never gets written anywhere or read by
# anything, because no X server runs on this box. The actual offload
# mechanism (the `nvidia-offload` wrapper below) only sets env vars
# (__NV_PRIME_RENDER_OFFLOAD, __GLX_VENDOR_LIBRARY_NAME, etc.) — none of
# which reference a bus ID. The placeholders below only exist to satisfy a
# Nix assertion that they're non-empty; they don't need to be real for
# things to work. Still worth plugging in the real values for
# correctness/future-proofing whenever you next have a shell on the box:
#   lspci -nn | grep -Ei 'vga|3d controller'
# which prints something like:
#   03:00.0 VGA compatible controller: AMD ... [1002:...]
#   0a:00.0 VGA compatible controller: NVIDIA ... [10de:...]
# Convert each "03:00.0" (hex bus:device.function) to PRIME's decimal
# "PCI:3:0:0" form and swap them in below.
{ inputs, outputs, lib, pkgs, config, ... }:
{
  # amdgpu stays the driver for the primary/display GPU; nvidia is loaded
  # alongside it purely for the offload card. xserver.enable is off on this
  # host — videoDrivers itself is a no-op here but kept for documentation/
  # parity in case Xorg ever comes back, and it's what nixpkgs' nvidia.nix
  # keys all of its PRIME logic off of (see boot.kernelModules note below).
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam/Proton need 32-bit GL/Vulkan on both GPUs
  };

  hardware.nvidia = {
    modesetting.enable = true;

    # Open kernel module needs Turing (RTX 20-series) or newer. Flip to true
    # if this card qualifies — see https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    open = false;

    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    prime = {
      # Offload (not sync): AMD is the only card with a monitor attached, so
      # the NVIDIA GPU stays powered down until something explicitly renders
      # on it (`nvidia-offload <cmd>`, or DRI_PRIME=1 / __NV_PRIME_RENDER_OFFLOAD=1
      # set on a per-app basis). Switch to prime.sync.enable instead if
      # displays ever get wired to the NVIDIA card directly.
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # Placeholders — inert on this host (see file header), but required to
      # be non-empty/well-formed for nixpkgs' own assertions to pass.
      amdgpuBusId = "PCI:3:0:0";
      nvidiaBusId = "PCI:10:0:0";
    };
  };

  # Gotcha found while wiring this up: nixpkgs' nvidia.nix only adds
  # "nvidia"/"nvidia_modeset"/"nvidia_drm" to boot.kernelModules when
  # config.services.xserver.enable is true — see
  # `boot.kernelModules = lib.optionals config.services.xserver.enable [...]`
  # in nixos/modules/hardware/video/nvidia.nix. Since this host runs Xorg-
  # free (gamescope/COSMIC over Wayland), that condition is false and the
  # upstream module would silently skip loading them. The kernel *may* still
  # auto-load "nvidia" via its own PCI device table when udev sees the card,
  # but nvidia_drm/nvidia_modeset aren't guaranteed to come up before
  # gamescope starts probing DRM devices at boot. Force all three explicitly
  # so KMS is ready in time regardless of X11 being off.
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
}
