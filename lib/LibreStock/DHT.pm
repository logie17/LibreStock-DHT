package LibreStock::DHT;
use strictures 1;

use Moo;
use Method::Signatures::Simple;
use JSON::XS qw(encode_json decode_json);

has hub => (
  is => 'ro',
  isa => sub { 
    ref $_[0] eq 'LibreStock::DHT::Peer' or die;
  },
);

has peers => (
  is => 'rw',
  isa => sub { ref $_[0] eq 'ARRAY' or die },
  builder => '_build_peers',
);

method _build_peers {
  decode_json(io('peers')->all);
}

method is_peer_valid($peer) {
  $peer->ping;
}

method get_images_from_peers {
  my $dht_images;
  for my $peer (@{ $self->peers }) {
    $dht_images->{$peer->name} = $peer->get_images;
  }
  return $dht_images;
}

1;
