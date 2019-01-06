module Archlinux
  def self.setup &block
    archlinux = Archlinux::System.new
    archlinux.send :instance_eval, &block
    archlinux.send :run
  end

  class System
    def initialize
      @pacman_packages = ['base', 'base-devel']
      @aur_packages    = []
      @kernel_modules  = []
      @root            = '/mnt'
      @zone = @subzone = nil
      @locales         = ['en_US']
      @shell_scripts   = []
      @users           = []
    end

    def root path
      @root = path
    end
    
    def get_root
      @root
    end
    
    def timezone zone, subzone
      @zone    = zone
      @subzone = subzone
    end
  
    def packages *names
      @pacman_packages |= names
    end
    
    def aur *names
      @aur_packages |= names
    end
    
    def kernel_modules title, *modules
      @kernel_modules << ({ title: title, modules: modules })
    end
    
    def locales *names
      @locales |= names
    end
    
    def add_user name, &block
      new_user = User.new name
      block.call new_user
      @users << new_user
    end
    
    def run_script source
      @shell_scripts << source
    end
  
  private
    def run
      @hostname = prompt ">> What's that machine's name: "

      cmd "pacstrap '#{@root}' #{@pacman_packages.join ' '}"
      cmd "genfstab -p '#{@root}' >> '#{@root}/etc/fstab'"
      cmd "echo '#{@hostname}' > '#{@root}/etc/hostname'"
      cmd "cp /etc/resolv.conf '#{@root}/etc/resolv.conf'"
      install_kernel_modules
      install_locales
      set_localetime if (not @zone.nil?) and (not @subzone.nil?)
      
      chroot_command "mkinitcpio -p linux" # Create initial RAM disk
      chroot_command "passwd"              # Initialize root password
      
      @users.each do |user|
        user.send :run, self
      end
      
      @aur_packages.each do |package|
        run_script <<-MAKEPKG
          mkdir -p '/opt/#{package}'
          chmod 777 '/opt/#{package}'
          wget 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=#{package}' -O '/opt/#{package}/PKGBUILD'
          sudo -u nobody bash -c 'cd /opt/#{package} && makepkg'
          bash -c 'pacman -U `find "/opt/#{package}" -name "*.tar.xz"`'
        MAKEPKG
      end

      run_scripts
    end

    def prompt what
      print ">> #{what}: "
      $stdin.gets.strip
    end

    def install_kernel_modules
      cmd "mkdir -p #{@root}/etc/modules-load.d"
      @kernel_modules.each do |kernel_modules|
        filename = "'#{@root}/etc/modules-load.d/#{kernel_modules[:title]}'"
        kernel_modules[:modules].each do |kernel_module|
          cmd "echo \"#{kernel_module}\" >> #{filename}"
        end
      end
    end

    def install_locales
      cmd "mv '#{@root}/etc/locale.gen' '#{@root}/etc/locale.gen.old'"
      @locales.each do |locale|
        cmd "cat '/#{@root}/etc/locale.gen.old' | grep '#{locale}' | cut -c2- >> '#{@root}/etc/locale.gen'"
      end
      chroot_command "locale-gen"
    end

    def set_localetime
      chroot_command "ln -sf '/usr/share/zoneinfo/#{@zone}/#{@subzone}' /etc/localtime"
    end

    def run_scripts
      @shell_scripts.each do |script|
        lines = script.split "\n"
        lines.each do |line|
          chroot_command line
        end
      end
    end

    def chroot_command command
      cmd "arch-chroot '#{@root}' #{command}"
    end

    def cmd command
      print "++ #{command}\n"
      system command
    end
  end
end