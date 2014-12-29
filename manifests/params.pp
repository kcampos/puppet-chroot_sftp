class chroot_sftp::params {
  $group_name              = hiera('sftp_group', 'sftpusers')
  $gid                     = hiera('sftp_gid', '60')
  $user_basedir            = hiera('sftp_user_basedir', '/incoming')
  $chroot_basedir          = hiera('sftp_chroot_basedir', '/sftp')
  $allow_password_auth     = hiera('sftp_allow_password_auth', 'no')
  $chroot_dir_mounted      = str2bool(hiera('sftp_chroot_dir_mounted', false))
  $chroot_dir_device       = hiera('sftp_chroot_dir_device', undef)
  $global_user_directories = hiera('sftp_global_user_directories', [])

  if(versioncmp($operatingsystemmajrelease, 7) >= 0) {
    $chroot_ssh_auth = true
  } else {
    $chroot_ssh_auth = false
  }

  # sftp_users:
  #   username:
  #     uid: ''
  #     password: '' (optional)
  #     pub_ssh_key: '' (optional)
  #     pub_ssh_key_type: '' (optional)
  #     directories: (optional)
  #       - 'incoming'
  #       - 'outgoing'
  $sftp_users     = hiera_hash('sftp_users', {})
}
