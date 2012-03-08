package LibreStock::DHT::Peer;
use Moo;
use strictures 1;

use Web::Simple 'LibreStock::DHT::Peer';
use Method::Signatures::Simple;

use JSON::XS qw(encode_json decode_json);
use IO::All;
use Try::Tiny;

method dispatch_request {
  [
    sub (GET + /peers) {
      [200, ['Content-type', 'application/json'], [ $self->dump_peers ] ];
    },

    sub (POST + /peers/*/add) {
      my ($peer) = @_;
      $self->add_peer($peer);
    },

    sub (PUT + /peers/*/modify) {
      my ($peer) = @_;
      $self->modify_peer($peer);
    },

    sub (DELETE + /peer/*/delete) {
      my ($peer) = @_;
      $self->delete_peer($peer);
    },
  ],
}

method dump_peers {
  return encode_json(io('peers')->all);
}

method check($peer) {
  my $is_ok = decode_json(io($peer . '/status'));
  if(ref $is_ok ne 'HASH') {
    die [412, ['Content-type', 'application/json'], [$self->bad_peer($peer) ] ];
  } elsif(!$is_ok->{OK}) {
    die [412, ['Content-type', 'application/json'], [$self->unhealthy_peer($peer) ] ];
  } else {
    return 1;
  }
}

method add_peer($peer) {
  my $peers = decode_json(io('peers')->all);
  try {
    $self->check($peer);
  } catch {
    return $_;
  };
  my $peer_info = decode_json(io($peer . '/info'));
  $peers->{$peer} = $peer_info;
  encode_json($peers) > io('peers');
}

method modify_peer($peer) {
  my $peers = decode_json(io('peers')->all);
  try {
    $self->check($peer);
    die [404, ['Content-type', 'application/json'], [$self->peer_not_found($peer) ] ]
      unless exists $peers->{$peer};
  } catch {
    return $_;
  };

  my $peer_info = decode_json(io($peer . '/info'));
  $peers->{$peer} = $peer_info;
  encode_json($peers) > io('peers');
}

method delete_peer($peer) {
  my $peers = decode_json(io('peers')->all);
  try {
    $self->check($peer);
    die [404, ['Content-type', 'application/json'], [$self->peer_not_found($peer) ] ]
      unless exists $peers->{$peer};
  } catch {
    return $_;
  };

  my $peer_info = decode_json(io($peer . '/info'));
  delete $peers->{$peer};
  encode_json($peers) > io('peers');
}

method peer_not_found($peer) {
  encode_json({
    peer => $peer,
    error => 'peer not found',
  });
}

method bad_peer($peer) {
  encode_json({
    peer => $peer,
    error => 'malformed response from peer',
  });
}

method unhealthy_peer($peer) {
  encode_json({
    peer => $peer,
    error => 'bad response to health check',
  });
}

1;
