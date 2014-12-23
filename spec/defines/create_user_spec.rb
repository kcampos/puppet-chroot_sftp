require 'spec_helper'

describe 'chroot_sftp::create_user' do
  let(:password) { "user1_pass" } # hiera fixture
  let(:pub_ssh_key) { "AHSBDGIAUYSGDI" } # hiera fixture
  let(:pub_ssh_key_type) { 'ssh-rsa' } # hiera fixture
  let(:username) { "user_pass" } # hiera fixture
  let(:user_directories) { ['tmp','drop','pickup'] } # hiera fixture
  let(:title) { username }

  context "with password" do
    let(:username) { "user_pass" } # hiera fixture

    it { should contain_user(username).with({
        'home'     => "/incoming",
        'ensure'   => 'present',
        'shell'    => '/sbin/nologin',
        'uid'      => '200',
        'gid'      => '60',
        'password' => password
      }) 
    }

    it { should have_ssh_authorized_key_resource_count(0) }
  end

  context "with pub key" do
    let(:username) { "user_ssh" } # hiera fixture

    it { should contain_user(username).with({
        'home'     => "/incoming",
        'ensure'   => 'present',
        'shell'    => '/sbin/nologin',
        'uid'      => '201',
        'gid'      => '60',
        'password' => nil
      }) 
    }

    it { should contain_ssh_authorized_key("#{username}-pub").with({
        'ensure'  => 'present',
        'key'     => pub_ssh_key,
        'type'    => pub_ssh_key_type,
        'user'    => username
      }).that_requires("User[#{username}]")
    }
  end

  it { should contain_file("/sftp/#{username}").with({
      'ensure' => 'directory',
      'mode'   => '0755',
      'owner'  => 'root',
      'group'  => 'root'
    })
  }

  it { should contain_chroot_sftp__create_user_directories(username).with_directories(user_directories) }
end
