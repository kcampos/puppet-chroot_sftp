require 'spec_helper'

describe 'chroot_sftp::create_user_directories' do
  let(:dirs) { ["drop","pickup"] }
  let(:username) { "user_pass" } # hiera fixture
  let(:title) { username }
  let(:params) { {:directories => dirs}}

  context "with selinux enforced" do
    let(:facts) { {:selinux_enforced => true} }
    let(:selinux_type) { 'chroot_user_t' }

    it { should contain_file("/sftp/#{username}/drop").with({
        'ensure'  => 'directory',
        'mode'    => '0755',
        'owner'   => username,
        'group'   => 'sftpusers',
        'seltype' => selinux_type
      })
    }

    it { should contain_file("/sftp/#{username}/pickup").with({
        'ensure' => 'directory',
        'mode'   => '0755',
        'owner'  => username,
        'group'  => 'sftpusers',
        'seltype' => selinux_type
      })
    }
  end

  context "with selinux disabled" do
    let(:facts) { {:selinux_enforced => false} }
    let(:selinux_type) { nil }

    it { should contain_file("/sftp/#{username}/drop").with({
        'ensure'  => 'directory',
        'mode'    => '0755',
        'owner'   => username,
        'group'   => 'sftpusers',
        'seltype' => selinux_type
      })
    }

    it { should contain_file("/sftp/#{username}/pickup").with({
        'ensure' => 'directory',
        'mode'   => '0755',
        'owner'  => username,
        'group'  => 'sftpusers',
        'seltype' => selinux_type
      })
    }
  end
end
