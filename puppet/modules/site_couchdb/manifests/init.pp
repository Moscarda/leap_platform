class site_couchdb ( $bigcouch = false ) {
  tag 'leap_service'

  $x509                   = hiera('x509')
  $key                    = $x509['key']
  $cert                   = $x509['cert']
  $ca                     = $x509['ca_cert']

  $couchdb_config         = hiera('couch')
  $couchdb_users          = $couchdb_config['users']
  $couchdb_admin          = $couchdb_users['admin']
  $couchdb_admin_user     = $couchdb_admin['username']
  $couchdb_admin_pw       = $couchdb_admin['password']
  $couchdb_admin_salt     = $couchdb_admin['salt']
  $couchdb_webapp         = $couchdb_users['webapp']
  $couchdb_webapp_user    = $couchdb_webapp['username']
  $couchdb_webapp_pw      = $couchdb_webapp['password']
  $couchdb_webapp_salt    = $couchdb_webapp['salt']
  $couchdb_ca_daemon      = $couchdb_users['ca_daemon']
  $couchdb_ca_daemon_user = $couchdb_ca_daemon['username']
  $couchdb_ca_daemon_pw   = $couchdb_ca_daemon['password']
  $couchdb_ca_daemon_salt = $couchdb_ca_daemon['salt']

  $bigcouch_config        = $couchdb_config['bigcouch']
  $bigcouch_cookie        = $bigcouch_config['cookie']

  $ednp_port              = $bigcouch_config['ednp_port']

  class { 'couchdb':
    bigcouch        => $bigcouch,
    admin_pw        => $couchdb_admin_pw,
    bigcouch_cookie => $bigcouch_cookie,
    ednp_port       => $ednp_port
  }
  include couchdb::bigcouch::package::cloudant

  Service ['couchdb']
    -> Couchdb::Create_db['users']
    -> Couchdb::Create_db['client_certificates']
    -> Couchdb::Add_user[$couchdb_webapp_user]
    -> Couchdb::Add_user[$couchdb_ca_daemon_user]

  class { 'site_couchdb::stunnel':
    key  => $key,
    cert => $cert,
    ca   => $ca
  }

  couchdb::query::setup { 'localhost':
    user  => $couchdb_admin_user,
    pw    => $couchdb_admin_pw,
  }

  # Populate couchdb
  couchdb::add_user { $couchdb_webapp_user:
    roles => '["certs"]',
    pw    => $couchdb_webapp_pw,
    salt  => $couchdb_webapp_salt
  }

  couchdb::add_user { $couchdb_ca_daemon_user:
    roles => '["certs"]',
    pw    => $couchdb_ca_daemon_pw,
    salt  => $couchdb_ca_daemon_salt
  }

  couchdb::create_db { 'users':
    readers => "{ \"names\": [\"$couchdb_webapp_user\"], \"roles\": [] }"
  }

  couchdb::create_db { 'client_certificates':
    readers => "{ \"names\": [], \"roles\": [\"certs\"] }"
  }

  include site_shorewall::couchdb
  include site_shorewall::couchdb::bigcouch
}
