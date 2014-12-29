class chroot_sftp($configure_ssh = false) inherits chroot_sftp::params {
  
  group { $group_name: gid => $gid }
  file { [$user_basedir,$chroot_basedir]: 
    ensure  => directory,
    seltype => $selinux_enforced ? {
      true    => 'chroot_user_t',
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
    } elsif(versioncmp($operatingsystemmajrelease, 7) >= 0) {
      $ssh_options = merge($default_ssh_options, {'AuthorizedKeysFile' => "${chroot_basedir}/%u/.ssh/authorized_keys"})
    } else {
      $ssh_options = $default_ssh_options
    }

    ssh::server::match_block { $group_name: type => 'Group', options => $ssh_options }
  }

  if $selinux_enforced {
    exec { "enable_chroot_rw_access":
      command => 'setsebool -P ssh_chroot_rw_homedirs on',
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      unless  => "getsebool ssh_chroot_rw_homedirs | awk '{ print \$3 }' | grep on",
      notify  => Exec["restorecon-${chroot_basedir}"]
    }

    $parent_dir = dirname($chroot_basedir)
    $dir        = basename($chroot_basedir)
    exec { "set_chroot_context":
      command => "chcon -R --type=chroot_user_t ${chroot_basedir}",
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      unless  => "ls -Z ${parent_dir} | grep ${dir} | awk '{ print \$4 }' | cut -d : -f 3 | grep chroot_user_t",
      notify  => Exec["restorecon-${chroot_basedir}"]
    }

    exec { "restorecon-${chroot_basedir}":
      command     => "restorecon -R ${chroot_basedir}",
      path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      refreshonly => true,
    }
  }
}
