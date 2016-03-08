# Puppet manifest for my PHP dev machine
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

$projectName = 'evolution'
# notice( "Interpolation works in double quote string ${projectName} and $projectName" )
$gitDomain   = 'github.com'
$gitUpstream = 'git@github.com:gplsek/evonutapi.git'

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

  file {
    "/home/vagrant":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => 711,
      ensure => "directory"
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
    "/home/vagrant/www/logs/${projectName}.access_log":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => "775",
      ensure  => present
      ;
    "/home/vagrant/www/logs/${projectName}.error_log":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => "775",
      ensure  => present
      ;
    "/home/vagrant/www/${projectName}":
      owner   => "vagrant",
      group   => "vagrant",
      ensure => "directory"
      ;
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
      creates => "/etc/yum.repos.d/mysql-community.repo",
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
      "screen",
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
      "php-xdebug",
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
      require   => [
        Package["nginx"],
        File["/home/vagrant/www/logs/${projectName}.access_log"],
        File["/home/vagrant/www/logs/${projectName}.error_log"],
      ],
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
    "/etc/nginx/conf.d/${projectName}.conf":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/nginx/conf.d/${projectName}.conf",
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
    "/etc/php.d/xdebug.ini":
      owner   => "root",
      group   => "root",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/xdebug.ini",
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
    "/home/vagrant/.bashrc":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/.bashrc"
      ;
    "/home/vagrant/git-completion.bash":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => 644,
      replace => true,
      ensure  => present,
      source  => "/vagrant/files/git-completion.bash"
      ;
    "/home/vagrant/www/${projectName}/cache-clear.sh":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => 750,
      replace => true,
      ensure  => present,
      require => Vcsrepo["/home/vagrant/www/${projectName}"],
      source  => "/vagrant/files/cache-clear.sh"
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

  user {
    "vagrant":
      groups => ["nginx"],
      membership => minimum,
      require => Package["nginx"];
  }

  mysql_database { 'symfony':
    ensure  => 'present',
    charset => 'utf8',
    collate => 'utf8_general_ci',
  }

  exec {
    "set samba passwd":
      command => "/bin/echo -e \"vagrant\nvagrant\n\" | /usr/bin/smbpasswd -s -a vagrant",
      require => Package["samba"],
      ;
    "allow git domain":
      unless => "grep -Fq \"${gitDomain} ssh-rsa\" /home/vagrant/.ssh/known_hosts",
      command => "ssh-keyscan ${gitDomain} >> /home/vagrant/.ssh/known_hosts",
      user => 'vagrant',
      require => File['/home/vagrant/.ssh/known_hosts']
      ;
    "install gulp":
      creates => "/usr/bin/gulp",
      command => "npm install -g gulp",
      require => Package['npm']
      ;
    "install bower":
      creates => "/usr/bin/bower",
      command => "npm install -g bower",
      require => Package['npm']
      ;
    "symlink gulp-out":
      creates => "/home/vagrant/www/${projectName}/gulp-out",
      cwd => "/home/vagrant/www/${projectName}",
      command => "ln -s /home/vagrant/www/${projectName} gulp-out",
      require => Vcsrepo["/home/vagrant/www/${projectName}"],
      ;
  }

  vcsrepo { "/home/vagrant/www/${projectName}":
    user                => 'vagrant',
    ensure              => present,
    provider            => git,
    source              => {
      'upstream'          => $gitUpstream,
    },
    remote              => 'upstream',
    revision            => 'master',
    require => [
      File['/home/vagrant/.ssh/id_rsa'],
      File["/home/vagrant/www/${projectName}"],
      Exec["allow git domain"],
    ],
    owner               => 'vagrant',
    group               => 'vagrant'
    ;
  }

  file {
    "/home/vagrant/www/${projectName}/.git":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => "775",
      require => Vcsrepo["/home/vagrant/www/${projectName}"],
      ensure  => "directory"
      ;
    "/home/vagrant/www/${projectName}/.git/hooks":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => "775",
      require => Vcsrepo["/home/vagrant/www/${projectName}"],
      ensure  => "directory"
      ;
    "/home/vagrant/www/${projectName}/.git/hooks/prepare-commit-msg":
      owner   => "vagrant",
      group   => "vagrant",
      mode    => "775",
      source  => "/vagrant/files/prepare-commit-msg",
      require => Vcsrepo["/home/vagrant/www/${projectName}"],
      ensure  => present
      ;
  }
}
include phpdevweb
