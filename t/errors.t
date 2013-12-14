use strict;
use warnings;
use Test::More;
use RDF::aREF qw(decode_aref);

my @errors = (
# invalid subjects
    { [] => { a => 'foaf:Person' } }
        => qr/^invalid subject ARRAY\(/,
# invalid predicates        
    { '<x:subject>' => { \"" => "" } }
        => qr/^invalid predicate IRI SCALAR\(/,
# TODO: check different forms of same IRI
# invalid objects
    { '<x:subject>' => { a => \"" } }
        => 'object must not be reference to SCALAR',
    { '<x:subject>' => { a => [ \"" ] } }
        => 'object must not be reference to SCALAR',
);

use JSON;
my $i=1;
while (defined (my $aref = shift @errors)) {
    my ($expect, $got) = shift @errors;
    
    decode_aref $aref, error => sub { $got = shift };
    if (ref $expect) {
        like $got, $expect, $expect;
    } else {
        is $got, $expect, $expect;
    }
}

done_testing;
