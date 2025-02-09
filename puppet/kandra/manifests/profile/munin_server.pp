class kandra::profile::munin_server inherits kandra::profile::base {

  include kandra::apache
  include zulip::supervisor

  $munin_packages = [
    'munin',
    'autossh',
    'libapache2-mod-fcgid',
  ]
  package { $munin_packages: ensure => installed }

  $default_host_domain = zulipconf('nagios', 'default_host_domain', undef)
  $hosts = zulipconf_nagios_hosts()

  file { '/etc/munin/apache.conf':
    require => Package['munin-node'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/kandra/munin/apache.conf',
    notify  => Service['apache2'],
  }

  file { '/etc/apache2/conf-available/munin.conf':
    ensure  => link,
    target  => '/etc/munin/apache.conf',
    require => File['/etc/munin/apache.conf'],
  }

  apache2conf { 'munin':
    ensure  => present,
    require => File['/etc/apache2/conf-available/munin.conf'],
    notify  => Service['apache2'],
  }

  file { '/etc/munin/munin.conf':
    ensure  => file,
    require => Package['munin'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('kandra/munin/munin.conf.erb'),
  }

  file { "${zulip::common::supervisor_conf_dir}/munin_tunnels.conf":
    ensure  => file,
    require => Package['supervisor', 'autossh'],
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('kandra/supervisor/conf.d/munin_tunnels.conf.erb'),
    notify  => Service['supervisor'],
  }
}
