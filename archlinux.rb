Archlinux.setup do
  timezone 'Europe', 'Paris'
  locales 'fr_FR', 'es_ES'

  ## Base
  packages 'grub'
  
  run_script <<-GRUB_INSTALL
    grub-install --target=i386-pc --recheck --force --debug /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
  GRUB_INSTALL

  if Archlinux::Machine.is_virtual_box?
    packages 'virtualbox-guest-utils', 'virtualbox-guest-modules'
    kernel_modules :virtualbox, 'vboxguest', 'vboxsf', 'vboxvideo'
  end

  ## Network
  packages 'net-tools', 'dnsutils', 'ntp', 'openssh'

  ## Shell
  packages 'zsh'

  ## Development packages
  packages 'git', 'vim', 'wget'
  packages 'cmake', 'scons', 'gcc'
  packages 'nodejs', 'npm'
  packages 'ruby'

  ## GUI
  packages 'xorg-server', 'xorg-server-common'
  packages 'xorg-xbacklight', 'xorg-xgamma', 'xorg-xhost', 'xorg-xinput', 'xorg-xmodmap', 'xorg-xrandr', 'xorg-xrefresh', 'xorg-xset', 'xorg-xsetroot', 'xorg-xkill'
  packages 'sddm'
  packages 'plasma-meta', 'oxygen-icons'
  packages 'kde-applications-meta'

  packages 'xf86-video-nouveau' if Archlinux::Machine.has_gforce_video_card?
  packages 'xf86-video-intel'   if Archlinux::Machine.has_intel_video_card?
  packages 'xf86-video-ati'     if Archlinux::Machine.has_ati_video_card?
  #packages 'xf86-input-synaptics'

  ## Pacaur
  packages 'expac', 'sudo', 'jq', 'perl'
  aur 'auracle-git', 'pacaur'

  ## Applications
  packages 'konsole', 'kate', 'dolphin', 'kwrite', 'kompare'
  packages 'gwenview', 'kimageformats'

  add_user 'plaristote' do |user|
    user.temporary_password = 'password'
    user.default_shell      = 'zsh'    
    user.provide_file '.zshrc', 'http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc'
  end

  run_script <<-SERVICES
    systemctl enable dhcpcd
    systemctl enable ntpd
  SERVICES
end
