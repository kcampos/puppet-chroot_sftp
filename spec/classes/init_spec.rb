require 'spec_helper'

describe 'chroot_sftp' do
  let(:params) { {:configure_ssh => false} }

  it { should contain_group('sftpusers').with_gid('60') }
  it { should contain_file('/incoming').with_ensure('directory') }
  it { should contain_file('/sftp').with_ensure('directory') }
  it { should contain_mount('/sftp').with({
    'ensure'  => 'mounted',
    'atboot'  => true,
    'fstype'  => 'ext4',
    'device'  => '/dev/vdb',
    'options' => 'defaults',
    }).that_requires("File[/sftp]")
  }
  
end
