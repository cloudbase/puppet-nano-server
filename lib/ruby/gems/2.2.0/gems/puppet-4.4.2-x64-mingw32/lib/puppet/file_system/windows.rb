require 'puppet/file_system/posix'
require 'puppet/util/windows'

class Puppet::FileSystem::Windows < Puppet::FileSystem::Posix

  def exist?(path)
    return Puppet::Util::Windows::File.exist?(path)
  end

  def symlink(path, dest, options = {})
    raise_if_symlinks_unsupported

    dest_exists = exist?(dest) # returns false on dangling symlink
    dest_stat = Puppet::Util::Windows::File.stat(dest) if dest_exists

    # silent fail to preserve semantics of original FileUtils
    return 0 if dest_exists && dest_stat.ftype == 'directory'

    if dest_exists && dest_stat.ftype == 'file' && options[:force] != true
      raise(Errno::EEXIST, "#{dest} already exists and the :force option was not specified")
    end

    if options[:noop] != true
      ::File.delete(dest) if dest_exists # can only be file
      Puppet::Util::Windows::File.symlink(path, dest)
    end

    0
  end

  def symlink?(path)
    return false if ! Puppet.features.manages_symlinks?
    Puppet::Util::Windows::File.symlink?(path)
  end

  def readlink(path)
    raise_if_symlinks_unsupported
    Puppet::Util::Windows::File.readlink(path)
  end

  def unlink(*file_names)
    if ! Puppet.features.manages_symlinks?
      return ::File.unlink(*file_names)
    end

    file_names.each do |file_name|
      file_name = file_name.to_s # handle PathName
      stat = Puppet::Util::Windows::File.stat(file_name) rescue nil

      # sigh, Ruby + Windows :(
      if !stat
        ::File.unlink(file_name) rescue Dir.rmdir(file_name)
      elsif stat.ftype == 'directory'
        if Puppet::Util::Windows::File.symlink?(file_name)
          Dir.rmdir(file_name)
        else
          raise Errno::EPERM.new(file_name)
        end
      else
        ::File.unlink(file_name)
      end
    end

    file_names.length
  end

  def stat(path)
    Puppet::Util::Windows::File.stat(path)
  end

  def lstat(path)
    if ! Puppet.features.manages_symlinks?
      return Puppet::Util::Windows::File.stat(path)
    end
    Puppet::Util::Windows::File.lstat(path)
  end

  def chmod(mode, path)
    Puppet::Util::Windows::Security.set_mode(mode, path.to_s)
  end

  def read_preserve_line_endings(path)
    contents = path.read( :mode => 'rb', :encoding => Encoding::UTF_8)
    contents = path.read( :mode => 'rb', :encoding => Encoding::default_external) unless contents.valid_encoding?
    contents = path.read unless contents.valid_encoding?

    contents
  end

  private

  def raise_if_symlinks_unsupported
    if ! Puppet.features.manages_symlinks?
      msg = "This version of Windows does not support symlinks.  Windows Vista / 2008 or higher is required."
      raise Puppet::Util::Windows::Error.new(msg)
    end

    if ! Puppet::Util::Windows::Process.process_privilege_symlink?
      Puppet.warning "The current user does not have the necessary permission to manage symlinks."
    end
  end

end
