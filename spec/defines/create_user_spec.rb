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

    it { should contain_file("/sftp/#{username}").with({
      'ensure'  => 'directory',
      'owner'   => 'root',
      'group'   => 'root',
      'seltype' => 'user_home_dir_t'
      })
    }
  end

  context "with selinux disabled" do
    let(:facts) { {:selinux_enforced => 'false'} }

    it { should contain_file("/sftp/#{username}").with({
      'ensure'  => 'directory',
      'owner'   => 'root',
      'group'   => 'root',
      'seltype' => nil
      })
    }
  end

  context "with password" do
    let(:username) { "user_pass" } # hiera fixture

    it { should contain_user(username).with({
        'home'     => "/sftp/#{username}",
        'ensure'   => 'present',
        'shell'    => '/sbin/nologin',
        'uid'      => '200',
        'gid'      => '60',
        'password' => password
      }).that_requires("File[/sftp/#{username}]")
    }

    it { should have_ssh_authorized_key_resource_count(0) }
  end

  context "with pub key" do
    let(:username) { "user_ssh" } # hiera fixture

    context "with selinux enforced" do
      let(:facts) { {:selinux_enforced => 'true'} }
      
      it { should contain_file("/sftp/#{username}/.ssh").with({
        'ensure'  => 'directory',
        'owner'   => username,
        'group'   => 'sftpusers',
        'seltype' => 'user_home_t',
        'mode'    => '0700'
        }).that_requires("File[/sftp/#{username}]")
      }

      it { should contain_file("/sftp/#{username}/.ssh/authorized_keys").with({
        'ensure'  => 'file',
        'owner'   => username,
        'group'   => 'sftpusers',
        'seltype' => 'ssh_home_t',
        'mode'    => '0600'
        }).that_requires("File[/sftp/#{username}/.ssh]")
      }
    end

    context "with selinux disabled" do
      let(:facts) { {:selinux_enforced => 'false'} }

      it { should contain_file("/sftp/#{username}/.ssh").with({
        'ensure'  => 'directory',
        'owner'   => username,
        'group'   => 'sftpusers',
        'seltype' => nil,
        'mode'    => '0700'
        }).that_requires("File[/sftp/#{username}]")
      }

      it { should contain_file("/sftp/#{username}/.ssh/authorized_keys").with({
        'ensure'  => 'file',
        'owner'   => username,
        'group'   => 'sftpusers',
        'seltype' => nil,
        'mode'    => '0600'
        }).that_requires("File[/sftp/#{username}/.ssh]")
      }
    end

    it { should contain_user(username).with({
        'home'     => "/sftp/#{username}",
        'ensure'   => 'present',
        'shell'    => '/sbin/nologin',
        'uid'      => '201',
        'gid'      => '60',
        'password' => nil
      }).that_requires("File[/sftp/#{username}]")
    }

    it { should contain_ssh_authorized_key("#{username}-pub").with({
        'ensure'  => 'present',
        'key'     => pub_ssh_key,
        'type'    => pub_ssh_key_type,
        'user'    => username,
      }).that_requires("File[/sftp/#{username}/.ssh/authorized_keys]")
    }
  end
end
