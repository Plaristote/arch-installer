module Archlinux
  class User
    attr_accessor :temporary_password
    attr_accessor :default_shell
    attr_reader :files, :name
    
    def initialize name
      @name          = name
      @default_shell = "bash"
      @files         = []
      @archlinux     = nil
    end
    
    def home_directory
      "/home/#{name}"
    end
    
    def provide_file target, source
      @files << ({ target: target, source: source })
    end
  
  private
    def run archlinux
      @archlinux = archlinux
      @archlinux.send :chroot_command, "useradd -m -g users -G wheel -s \"/bin/#{default_shell}\" \"#{name}\""
      set_password
      make_home
      set_rights
    end
  
    def make_home
      @archlinux.send :chroot_command, "mkdir -p '#{home_directory}'"
      files.each do |file|
        @archlinux.send :cmd, "curl --location #{file[:source]} > '#{@archlinux.get_root}/#{home_directory}/#{file[:target]}'"
      end
    end
  
    def set_rights
      @archlinux.send :chroot_command, "chown -R plaristote \"#{home_directory}\""
    end
    
    def set_password
      @archlinux.send :cmd, "echo \"#{name}:#{temporary_password}\" | arch-chroot '#{@archlinux.get_root}' chpasswd"
      @archlinux.send :chroot_command, "chage -d 0 \"#{name}\""
    end
  end
end