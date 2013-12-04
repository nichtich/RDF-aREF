use strict;
use warnings;
use Test::More;
use RDF::aREF qw(decode_aref);

my @tests = (
    { '' => { a => 'foaf:Person' } }
        => 'invalid subject ',
    { _id => '', a => 'foaf:Person' },
        => 'invalid subject ',
    { _id => undef, a => 'foaf:Person' },
        => 'invalid subject ',
    { '<x:subject>' => { '' => 'object' } }
        => 'invalid predicate IRI ',
    { '<x:subject>' => { 'a' => undef } }
        => 'object must not be null',
    { '<x:subject>' => { 'a' => '' } }
        => 'object must not be null',
);

while (defined (my $aref = shift @tests)) {
    my ($err, $msg, $rdf) = shift @tests;
    decode_aref $aref, 
        error => sub { $msg = shift }, null => '', callback => sub { $rdf++ };
    ok !defined $msg && !$rdf, 'not strict by default';
    decode_aref $aref, 
        error => sub { $msg = shift }, strict => 1, null => '';
    is $msg, $err, $err;
}

my ($aref, $rdf, $err) = { '<x:subject>' => { dc_title => '' } }; 
my $decoder = RDF::aREF::Decoder->new(
    callback => sub { $rdf = shift },
    error    => sub { $err = shift }
);

$decoder->decode($aref);
ok($rdf && !defined $err, 'empty object allowed');

done_testing;
