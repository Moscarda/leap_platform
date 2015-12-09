class site_apt::dist_upgrade {

  if $::apt_running == 'true' {
    fail ('apt-get is running in background - Please wait until it finishes. Exiting.')
  } else {
    exec{'initial_apt_dist_upgrade':
      command     => "/usr/bin/apt-get -q -y -o 'DPkg::Options::=--force-confold'  dist-upgrade",
      refreshonly => false,
      timeout     => 1200,
      require     => Exec['refresh_apt']
    }
  }
}
