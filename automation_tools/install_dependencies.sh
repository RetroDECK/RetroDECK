#!/bin/bash
# This script is installing the required dependencies to correctly run the pipeline and build the flatpak

unset pkg_mgr

# rpm-ostree must be checked before dnf because a dnf (wrapper) command also works on rpm-ostree distros (not what we want)
for potential_pkg_mgr in apt pacman rpm-ostree dnf; do
  command -v "$potential_pkg_mgr" &> /dev/null && pkg_mgr="$potential_pkg_mgr" && break
done

case "$pkg_mgr" in
  apt)
    sudo apt install -y flatpak flatpak-builder p7zip-full xmlstarlet bzip2 curl jq
    ;;
  pacman)
    sudo pacman -S --noconfirm flatpak flatpak-builder p7zip xmlstarlet bzip2
    ;;
  rpm-ostree)
    echo "When using a distro with rpm-ostree, you shouldn't build directly on the host. Try using a distrobox."
    exit 1
    ;;
  dnf)
    sudo dnf install -y flatpak flatpak-builder p7zip p7zip-plugins xmlstarlet bzip2 curl
    ;;
  *)
    echo "Package manager $pkg_mgr not supported. Please open an issue."
    ;;
esac

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
