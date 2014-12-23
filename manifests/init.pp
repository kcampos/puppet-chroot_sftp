class chroot_sftp($configure_ssh = false) inherits chroot_sftp::params {
  
  group { $group_name: gid => $gid }
  file { [$user_basedir,$chroot_basedir]: ensure => directory }

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
    if(versioncmp($operatingsystemmajrelease, 6) == -1) {
      fail("Only RHEL 6+")
    }

    ssh::server::match_block { $group_name:
      type    => 'Group',
      options => {
        'ChrootDirectory'        => "${chroot_basedir}/%u",
        'ForceCommand'           => 'internal-sftp',
        'PasswordAuthentication' => $allow_password_auth,
        'AllowTcpForwarding'     => 'no',
        'X11Forwarding'          => 'no',
      }
    }
  }

  if $selinux_enforced {
    exec { "enable_chroot_rw_access":
      command => 'setsebool -P ssh_chroot_rw_homedirs on',
      path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      unless  => "getsebool ssh_chroot_rw_homedirs | awk '{ print \$3 }' | grep on",
      notify  => Exec["restorecon-${chroot_basedir}"]
    }

    exec { "restorecon-${chroot_basedir}":
      command     => "restorecon -R ${chroot_basedir}",
      path        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      refreshonly => true,
    }
  }
}
