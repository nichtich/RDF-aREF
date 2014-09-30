use Test::More;
use RDF::aREF ':all';

my %tests = (
    "a@" => "a",
    "0^<xs:integer>" => "0",
    "http://example.org/" => undef,
    "http://example.org/@" => 'http://example.org/',
    "<http://example.org/@>" => undef,
#    "<>" => undef, # FIXME?
);

while (my ($aref, $literal) = each %tests) {
    my $got = plain_literal($aref);
    is $got, $literal, $aref;
}

# TODO: check calling with array reference

done_testing;
