use strict;
use warnings;
use Test::More;
use RDF::aREF qw(decode_aref);

my @errors = (
# invalid subjects
    { 'x:bar' => { a => 'foaf:Person' } }
        => 'unknown prefix: x',
    { _id => 'x:bar', a => 'foaf:Person' }
        => 'unknown prefix: x',
    { '"x"' => { a => 'foaf:Person' } }
        => 'invalid subject "x"',
    { _id => '"x"', a => 'foaf:Person' }
        => 'invalid subject "x"',
    { [] => { a => 'foaf:Person' } }
        => qr/^invalid subject ARRAY\(/,
    { _id => [], a => 'foaf:Person' }
        => qr/^invalid subject ARRAY\(/,
    { '<x:a>' => { _id => '<x:b>', a => 'foaf:Person' } }
        => 'subject _id must be <x:a>',
# invalid predicates        
    { '<x:subject>' => { bar_y => '123' } }
        => 'unknown prefix: bar',
    { '<x:subject>' => { "_:1" => "" } }
        => 'invalid predicate IRI _:1',
    { '<x:subject>' => { "<x>" => "" } }
        => 'invalid IRI x',
    { '<x:subject>' => { \"" => "" } }
        => qr/^invalid predicate IRI SCALAR\(/,
    # TODO: check different forms of same IRI
# invalid objects
    { '<x:subject>' => { a => \"" } }
        => 'object must not be reference to SCALAR',
    { '<x:subject>' => { a => [ \"" ] } }
        => 'object must not be reference to SCALAR',
#    { '<x:subject>' => { a => [undef] } }
#        => 'object must not be reference to SCALAR',
    { '<x:subject>' => { a => { _id => 'x:bar' } } }
        => 'unknown prefix: x',
    { '<x:subject>' => { a => { _id => '"x"' } } }
        => 'invalid object _id "x"',
    { '<x:subject>' => { a => { _id => [ [] ] } } }
        => qr/^invalid object _id ARRAY\(/,
# invalid datatypes
    { '<x:subject>' => { dct_extent => '123^x:bar' } }
        => 'unknown prefix: x',
);

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
