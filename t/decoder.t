use strict;
use warnings;
use Test::More;
use RDF::aREF::Decoder;

my $_rdf  = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
my $_foaf = "http://xmlns.com/foaf/0.1/";
my $_xsd  = 'http://www.w3.org/2001/XMLSchema#';
my $_ex   = "http://example.org/";
my $alice = "http://example.org/alice";

sub decode {
    my @triples;
    RDF::aREF::Decoder->new(
        callback => sub {
            push @triples, join " ", map { 
                (ref $_ ? '?'.$$_ : $_) // '' 
            } @_;
        }
    )->decode( $_[0] );
    join "\n", sort @triples;
}

sub test_decode(@) { ## no critic
    is decode($_[0]), $_[1];
}

# many ways to encode the same simple triple
test_decode $_, "$alice ${_rdf}type ${_foaf}Person" for
  # predicate map
    { _id => $alice, a => "foaf:Person" },
    { _id => $alice, a => "${_foaf}Person" },
    { _id => $alice, a => "<${_foaf}Person>" },
    { _id => $alice, rdf_type => "foaf:Person" },
    { _id => $alice, 'rdf:type' => "foaf:Person" },
    { _id => $alice, "${_rdf}type" => "foaf:Person" },
    { _id => $alice, "<${_rdf}type>" => "foaf:Person" },
    { _id => $alice, _ns => $_foaf, a => ":Person" },
    { _id => $alice, _ns => $_rdf, type => "foaf:Person" },
    { _id => $alice, _ns => $_rdf, _type => "foaf:Person" },
    { _id => $alice, _ns => $_rdf, ':type' => "foaf:Person" },
  # subject map
    { $alice => { a => "foaf:Person" } },
    { $alice => { a => "${_foaf}Person" } },
    { $alice => { a => "<${_foaf}Person>" } },
    { $alice => { rdf_type => "foaf:Person" } },
    { $alice => { 'rdf:type' => "foaf:Person" } },
    { $alice => { "${_rdf}type" => "foaf:Person" } },
    { $alice => { "<${_rdf}type>" => "foaf:Person" } },
    { _ns => $_foaf, $alice => { a => ":Person" } },
    { _ns => $_rdf, $alice => { type => "foaf:Person" } },
    { _ns => $_rdf, $alice => { _type => "foaf:Person" } },
    { _ns => $_rdf, $alice => { ':type' => "foaf:Person" } },
    { _ns => { _ => $_foaf, x => $_ex }, x_alice => { a => ":Person" } },
    { _ns => { f => $_foaf, '' => $_ex }, alice => { a => "foaf:Person" } },
    { _ns => $_ex, alice => { a => "foaf:Person" } },
    { _ns => $_ex, _alice => { a => "foaf:Person" } },
    { _ns => $_ex, ':alice' => { a => "foaf:Person" } },
;

# simple literals
test_decode $_, "$alice ${_foaf}name Alice " for
    { $alice => { foaf_name => "Alice" } },
    { $alice => { foaf_name => "Alice@" } },
    { $alice => { foaf_name => "Alice^<${_xsd}string>" } },
    { $alice => { foaf_name => "Alice^^<${_xsd}string>" } },
    { $alice => { foaf_name => "Alice^xsd:string" } },
    { $alice => { foaf_name => "Alice^^xsd:string" } },
    { _ns => $_xsd, $alice => { foaf_name => "Alice^:string" } },
;

# datatypes
test_decode $_, "$alice ${_foaf}age 42  ${_xsd}integer" for
    { $alice => { foaf_age => "42^xsd:integer" } },
    { $alice => { foaf_age => "42^^xsd:integer" } },
    { $alice => { foaf_age => "42^<${_xsd}integer>" } },
    { $alice => { foaf_age => "42^^<${_xsd}integer>" } },
    { _ns => $_xsd, $alice => { foaf_age => "42^:integer" } },
;

# language tags
test_decode { $alice => { foaf_name => "Alice\@$_" } }, 
    "$alice ${_foaf}name Alice ".lc($_) for qw(en en-US abcdefgh-x-12345678);

# blank nodes
test_decode $_, "$alice ${_foaf}knows ?1" for
    { $alice => { foaf_knows => { } } },
    { $alice => { foaf_knows => { _id => '_:1' } } },
;
test_decode $_, "?1 ${_rdf}type ${_foaf}Person\n$alice ${_foaf}knows ?1" for
    { $alice => { foaf_knows => { a => 'foaf:Person' } } },
    { $alice => { foaf_knows => { _id => '_:1', a => 'foaf:Person' } } },
    { $alice => { foaf_knows => '_:1' }, '_:1' => { a => 'foaf:Person' } },
;

# TODO: more blank nodes

# TODO: error handling

sub test_error(@) { ## no critic
}

done_testing;
