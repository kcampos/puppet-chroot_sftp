class chroot_sftp($configure_ssh = false) inherits chroot_sftp::params {
  
  group { $group_name: gid => $gid }

  file { $chroot_basedir: 
    ensure => directory,
    seluser => $selinux_enforced ? {
      'true'  => 'system_u',
      default => undef
    },
    seltype => $selinux_enforced ? {
      'true'  => 'home_root_t',
      default => undef
    }
  }

  if $chroot_dir_mounted {
    validate_string($chroot_dir_device)

    mount { $chroot_basedir: 
      ensure  => 'mounted',
      atboot  => true,
      fstype  => 'ext4',
      device  => $chroot_dir_device,
      options => 'defaults',
      require => File[$chroot_basedir]
    }
  }

  $sftp_usernames = keys($sftp_users)  
  chroot_sftp::create_user { $sftp_usernames: }

  if $configure_ssh {
    $default_ssh_options = {
      'ChrootDirectory'        => "${chroot_basedir}/%u",
      'ForceCommand'           => 'internal-sftp',
      'PasswordAuthentication' => $allow_password_auth,
      'AllowTcpForwarding'     => 'no',
      'X11Forwarding'          => 'no'
    }

    if(versioncmp($operatingsystemmajrelease, 6) == -1) {
      fail("Only RHEL 6+")
    } elsif $chroot_ssh_auth {
      $ssh_options = merge($default_ssh_options, {'AuthorizedKeysFile' => "${chroot_basedir}/%u/.ssh/authorized_keys"})
    } else {
      $ssh_options = $default_ssh_options
    }

    ssh::server::match_block { $group_name: type => 'Group', options => $ssh_options }
  }

  if str2bool($selinux_enforced) {
    exec { "enable_chroot_rw_access":
      command => 'setsebool -P ssh_chroot_rw_homedirs on',
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      unless  => "getsebool ssh_chroot_rw_homedirs | awk '{ print \$3 }' | grep on",
    }
  }
}
