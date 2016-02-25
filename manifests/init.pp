# Puppet manifest for my PHP dev machine
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
class phpdevweb
{
  File {
    owner   => "root",
    group   => "root",
    mode    => 644,
  }

  file { '/etc/motd':
   content => "Welcome to your Vagrant-built virtual machine! Managed by Puppet.\n"
  }

  exec {
    "grap-epel":
      command => "/bin/rpm -Ui http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
      creates => "/etc/yum.repos.d/epel.repo",
      alias   => "grab-epel"
      ;
    "grap-remi":
      command => "/bin/rpm -Ui http://rpms.famillecollet.com/enterprise/remi-release-6.rpm",
      creates => "/etc/yum.repos.d/remi.repo",
      alias   => "grab-remi",
      require => Exec["grab-epel"],
      ;
    "grap-percona":
      command => "/bin/rpm -Ui http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm",
      creates => "/etc/yum.repos.d/percona-release.repo",
      alias   => "grab-percona",
      ;
    "grap-mysql":
      command => "/bin/rpm -Ui http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm",
      creates => "/etc/yum.repos.d/mysql-release.repo",
      alias   => "grab-mysql",
      require => Exec["grab-percona"],
      ;
  }

  yumrepo {
    'remi':
        enabled => "1",
        require => Exec["grab-remi"],
  }

  package {[
      "iptables",
      "vim-enhanced",
      "git",
      "nginx",
      "php",
      "php-fpm",
      "samba",
      "samba-client",
      "samba-common",
      "nodejs",
      "npm",
    ]:
    ensure => present,
    require => Yumrepo["remi"]
  }

  package {[
      "mysql-community-server",
    ]:
    ensure => present,
    require => File['/etc/yum.repos.d/mysql-community.repo'],
  }

  package {[
      "php-gd",
      "php-mysqlnd",
      "php-mbstring",
      "php-xml",
      "php-mcrypt",
    ]:
    ensure => present,
    require => [Yumrepo["remi"], Package["php"], Package["php-fpm"]],
    notify  => Service["php-fpm"]
  }

  service {
    "iptables":
      require    => Package["iptables"],
      hasstatus  => true,
      status     => "true",
      hasrestart => false
      ;
    "nginx":
      name      => 'nginx',
      require   => Package["nginx"],
      ensure    => running,
      enable    => true
      ;
    "php-fpm":
      name      => 'php-fpm',
      require   => Package["php-fpm"],
      ensure    => running,
      enable    => true
      ;
    "mysqld":
      name      => 'mysqld',
      require   => Package["mysql-community-server"],
      ensure    => running,
      enable    => true
      ;
    "smb":
      name      => 'smb',
      require   => Package["samba"],
      ensure    => running,
      enable    => true
      ;
    "nmb":
      name      => 'nmb',
      require   => Package["samba"],
      ensure    => running,
      enable    => true
      ;
  }

  file {
    "/etc/sysconfig/iptables":
      owner   => "root",
      group   => "root",
      mode    => 600,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/iptables.txt",
      require => Package["iptables"],
      notify  => Service["iptables"]
      ;
    "/etc/nginx/conf.d/evolution.conf":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/nginx/conf.d/evolution.conf",
      require => Package["nginx"],
      notify  => Service["nginx"]
      ;
    "/etc/nginx/conf.d/test.conf":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/nginx/conf.d/test.conf",
      require => Package["nginx"],
      notify  => Service["nginx"]
      ;
    "/etc/samba/smb.conf":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/smb.conf",
      require => Package["samba"],
      notify  => [Service["smb"], Service["nmb"]]
      ;
    "/etc/php-fpm.d/www.conf":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/php-fpm.d/www.conf",
      require => Package["php-fpm"],
      notify  => Service["php-fpm"]
      ;
    "/etc/php.ini":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/php.ini",
      require => Package["php-fpm"],
      notify  => Service["php-fpm"]
      ;
    "/home/vagrant/.ssh":
      mode    => 700,
      owner   => "vagrant",
      group   => "vagrant",
      ensure => "directory"
      ;
    "/home/vagrant/.ssh/known_hosts":
      mode    => 644,
      owner   => "vagrant",
      group   => "vagrant",
      ensure => present
      ;
    "/home/vagrant/.ssh/id_rsa":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => 400,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/id_rsa"
      ;
    "/home/vagrant/www":
      owner   => "vagrant",
      group   => "vagrant",
      ensure => "directory"
      ;
    "/home/vagrant/www/logs":
      owner   => "vagrant",
      group   => "vagrant",
      ensure => "directory"
      ;
    "/home/vagrant/www/evolution":
      owner   => "vagrant",
      group   => "vagrant",
      ensure => "directory"
      ;
    "/home/vagrant":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => 711,
      ensure => "directory"
      ;
    "/etc/yum.repos.d/mysql-community.repo":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/mysql-community.repo",
      require => [Exec["grab-percona"], Exec["grap-mysql"]],
      ;
  }

  vcsrepo { '/home/vagrant/www/evolution':
    user                => 'vagrant',
    ensure              => present,
    provider            => git,
    source              => 'git@github.com:vladimirgolub/evonutapi.git',
    require => [
      File['/home/vagrant/.ssh/id_rsa'],
      File['/home/vagrant/www/evolution'],
      Exec["allow github"]
    ],
    owner               => 'vagrant',
    group               => 'vagrant',
    revision => 'master';
  }

  user {
    "vagrant":
      groups => ["nginx"],
      membership => minimum,
      require => Package["nginx"];
  }

  exec {
    "set samba passwd":
      command => "/bin/echo -e \"vagrant\nvagrant\n\" | /usr/bin/smbpasswd -s -a vagrant",
      require => Package["samba"],
      ;
    "allow github":
      command => "ssh-keyscan github.com >> /home/vagrant/.ssh/known_hosts",
      user => 'vagrant',
      require => File['/home/vagrant/.ssh/known_hosts'];
    "install gulp":
      command => "npm install -g gulp",
      require => Package['npm'];
  }
}
include phpdevweb
