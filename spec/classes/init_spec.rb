require 'spec_helper'

describe 'chroot_sftp' do
  let(:params) { {:configure_ssh => false} }

  it { should contain_group('sftpusers').with_gid('60') }
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
      'seluser' => 'system_u',
      'seltype' => 'home_root_t'
      }) 
    }

    it { should contain_exec("enable_chroot_rw_access").with({
      'command' => 'setsebool -P ssh_chroot_rw_homedirs on',
      'path'    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      'unless'  => "getsebool ssh_chroot_rw_homedirs | awk '{ print \$3 }' | grep on"
      })
    }
  end

  context "with selinux disabled" do
    let(:facts) { {:selinux_enforced => 'false'} }

    it { should contain_file('/sftp').with({
      'ensure'  => 'directory',
      'seluser' => nil,
      'seltype' => nil
      }) 
    }

    it { should have_exec_resource_count(0) }
  end
  
end
