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
  
  file { "${chroot_sftp::params::chroot_basedir}/${username}": ensure => directory }
  
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

    ssh_authorized_key { "${username}-pub":
      ensure  => present,
      key     => $pub_ssh_key,
      type    => $pub_ssh_key_type,
      user    => $username,
      require => User[$username],
    }
  }

  chroot_sftp::create_user_directories { $username: directories => $user_directories }
}
