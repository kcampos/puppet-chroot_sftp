require 'spec_helper'

describe 'chroot_sftp::create_user_directories' do
  let(:dirs) { ["drop","pickup"] }
  let(:username) { "user_pass" } # hiera fixture
  let(:title) { username }
  let(:params) { {:directories => dirs}}

  it { should contain_file("/sftp/#{username}/drop").with({
      'ensure'  => 'directory',
      'mode'    => '0755',
      'owner'   => username,
      'group'   => 'sftpusers'
    })
  }

  it { should contain_file("/sftp/#{username}/pickup").with({
      'ensure' => 'directory',
      'mode'   => '0755',
      'owner'  => username,
      'group'  => 'sftpusers'
    })
  }
end
