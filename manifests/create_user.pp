define chroot_sftp::create_user($username = $name) {
  include chroot_sftp::params

  $sftp_users       = $chroot_sftp::params::sftp_users
  validate_hash($sftp_users)
  validate_hash($sftp_users[$username])

  $uid              = $sftp_users[$username]['uid']
  $password         = $sftp_users[$username]['password']
  $pub_ssh_key      = $sftp_users[$username]['pub_ssh_key']
  $pub_ssh_key_type = $sftp_users[$username]['pub_ssh_key_type']
  $directories      = $sftp_users[$username]['directories']

  validate_string($uid)

  $user_directories = $directories ? {
    undef   => $chroot_sftp::params::global_user_directories,
    default => union($directories, $chroot_sftp::params::global_user_directories)
  }
  validate_array($user_directories)

  if(($password == undef) and ($pub_ssh_key == undef)) {
    fail("Must pass either password or pub_ssh_key")
  }
  
  file { "${chroot_sftp::params::chroot_basedir}/${username}": 
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    seltype => $selinux_enforced ? {
      'true'  => 'user_home_dir_t',
      default => undef
    }
  }
  
  user { $username:
    home     => "${chroot_sftp::params::chroot_basedir}/${username}",
    ensure   => present,
    shell    => '/sbin/nologin',
    uid      => $uid,
    gid      => $chroot_sftp::params::gid,
    password => $password,
    require  => File["${chroot_sftp::params::chroot_basedir}/${username}"]
  }

  if $pub_ssh_key {
    validate_string($pub_ssh_key_type)

    file { "${chroot_sftp::params::chroot_basedir}/${username}/.ssh": 
      ensure  => directory,
      owner   => $username,
      group   => $chroot_sftp::params::group_name,
      mode    => 0700,
      seltype => $selinux_enforced ? {
        'true'  => 'user_home_t',
        default => undef
      },
      require => File["${chroot_sftp::params::chroot_basedir}/${username}"]
    }

    file { "${chroot_sftp::params::chroot_basedir}/${username}/.ssh/authorized_keys": 
      ensure  => file,
      owner   => $username,
      group   => $chroot_sftp::params::group_name,
      mode    => 0600,
      seltype => $selinux_enforced ? {
        'true'  => 'ssh_home_t',
        default => undef
      },
      require => File["${chroot_sftp::params::chroot_basedir}/${username}/.ssh"]
    }

    ssh_authorized_key { "${username}-pub":
      ensure  => present,
      key     => $pub_ssh_key,
      type    => $pub_ssh_key_type,
      user    => $username,
      require => File["${chroot_sftp::params::chroot_basedir}/${username}/.ssh/authorized_keys"],
    }
  }

  chroot_sftp::create_user_directories { $username: directories => $user_directories }
}
