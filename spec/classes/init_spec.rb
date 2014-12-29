require 'spec_helper'

describe 'chroot_sftp' do
  let(:params) { {:configure_ssh => false} }

  it { should contain_group('sftpusers').with_gid('60') }
  it { should contain_file('/incoming').with_ensure('directory') }
  it { should contain_mount('/sftp').with({
    'ensure'  => 'mounted',
    'atboot'  => true,
    'fstype'  => 'ext4',
    'device'  => '/dev/vdb',
    'options' => 'defaults',
    }).that_requires("File[/sftp]")
  }

  context "with selinux enforced" do
    let(:facts) { {:selinux_enforced => 'true'} }

    it { should contain_file('/sftp').with({
      'ensure'  => 'directory',
      'seltype' => 'chroot_user_t'
      }) 
    }

    it { should contain_exec("enable_chroot_rw_access").with({
      'command' => 'setsebool -P ssh_chroot_rw_homedirs on',
      'path'    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      'unless'  => "getsebool ssh_chroot_rw_homedirs | awk '{ print \$3 }' | grep on"
      }).that_notifies("Exec[restorecon-/sftp]")
    }

    it { should contain_exec("set_chroot_context").with({
      'command' => 'chcon -R --type=chroot_user_t /sftp',
      'path'    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      'unless'  => "ls -Z / | grep sftp | awk '{ print \$4 }' | cut -d : -f 3 | grep chroot_user_t"
      }).that_notifies("Exec[restorecon-/sftp]")
    }

    it { should contain_exec("restorecon-/sftp").with({
      'command'     => "restorecon -R /sftp",
      'path'        => '/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin',
      'refreshonly' => true
      })
    }
  end

  context "with selinux disabled" do
    let(:facts) { {:selinux_enforced => 'false'} }

    it { should contain_file('/sftp').with({
      'ensure'  => 'directory',
      'seltype' => nil
      }) 
    }

    it { should have_exec_resource_count(0) }
  end
  
end
