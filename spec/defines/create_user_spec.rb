require 'spec_helper'

describe 'chroot_sftp::create_user' do
  let(:password) { "user1_pass" } # hiera fixture
  let(:pub_ssh_key) { "AHSBDGIAUYSGDI" } # hiera fixture
  let(:pub_ssh_key_type) { 'ssh-rsa' } # hiera fixture
  let(:username) { "user_pass" } # hiera fixture
  let(:user_directories) { ['tmp','drop','pickup'] } # hiera fixture
  let(:title) { username }

  it { should contain_chroot_sftp__create_user_directories(username).with_directories(user_directories) }

  context "with selinux enforced" do
    let(:facts) { {:selinux_enforced => 'true'} }
    let(:selinux_type) { 'chroot_user_t' }

    it { should contain_file("/sftp/#{username}").with({
        'ensure'  => 'directory',
        'mode'    => '0755',
        'owner'   => 'root',
        'group'   => 'root',
        'seltype' => selinux_type
      })
    }
  end

  context "with selinux disabled" do
    let(:facts) { {:selinux_enforced => 'false'} }
    let(:selinux_type) { nil }

    it { should contain_file("/sftp/#{username}").with({
        'ensure'  => 'directory',
        'mode'    => '0755',
        'owner'   => 'root',
        'group'   => 'root',
        'seltype' => selinux_type
      })
    }
  end

  context "with password" do
    let(:username) { "user_pass" } # hiera fixture

    context "and on rhel7" do
      let(:facts) { {:operatingsystemmajrelease => '7'} }

      it { should contain_user(username).with({
          'home'     => "/incoming",
          'ensure'   => 'present',
          'shell'    => '/sbin/nologin',
          'uid'      => '200',
          'gid'      => '60',
          'password' => password
        }) 
      }
    end

    context "and on rhel6" do
      it { should contain_user(username).with({
          'home'     => "/incoming/#{username}",
          'ensure'   => 'present',
          'shell'    => '/sbin/nologin',
          'uid'      => '200',
          'gid'      => '60',
          'password' => password
        }) 
      }
    end

    it { should have_ssh_authorized_key_resource_count(0) }
  end

  context "with pub key" do
    let(:username) { "user_ssh" } # hiera fixture

    context "and on rhel7" do
      let(:facts) { {:operatingsystemmajrelease => '7'} }

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
          'user'    => username,
          'target'  => "/sftp/#{username}/.ssh/authorized_keys",
        }).that_requires(["User[#{username}]","File[/sftp/#{username}]"])
      }
    end

    context "and on rhel6" do
      it { should contain_user(username).with({
          'home'     => "/incoming/#{username}",
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
          'user'    => username,
          'target'  => nil,
        }).that_requires(["User[#{username}]","File[/sftp/#{username}]"])
      }
    end
  end
end
