define chroot_sftp::create_user_directories(
  $username = $name,
  $directories,
  ) {
  include chroot_sftp::params

  $basedir = "${chroot_sftp::params::chroot_basedir}/${username}"
  $dirs    = prefix($directories, "${basedir}/")
  file { $dirs:
    ensure  => directory,
    owner   => $username,
    group   => $chroot_sftp::params::group_name,
    mode    => "0755",
    seltype => $selinux_enforced ? {
      true    => 'chroot_user_t',
      default => undef
    },
    require => File[$basedir]
  }
}
