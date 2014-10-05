use strict;
use warnings;
use Test::More;
use RDF::aREF::Encoder;

my $encoder = RDF::aREF::Encoder->new;

is $encoder->qname('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), 'rdf_type';
is $encoder->qname('http://schema.org/Review'), 'schema_Review';

is $encoder->predicate('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), 'a';
is $encoder->predicate('http://undefinednamespace.foo'), 'http://undefinednamespace.foo';
is $encoder->predicate('http://purl.org/dc/terms/title'), 'dct_title';

is $encoder->uri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), 'rdf_type';
is $encoder->uri('http://undefinednamespace.foo'), '<http://undefinednamespace.foo>';

my @objects = ({
        type => 'resource',
        value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    } => 'rdf_type',
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] => 'rdf_type',
    {
        type  => 'literal',
        value => 'hello, world!',
        lang  => 'en'
    } => 'hello, world!@en',
    ['hello, world!', 'en', undef ] => 'hello, world!@en',
    [42, undef, 'http://www.w3.org/2001/XMLSchema#integer'] => '42^xs_integer',
);

while (my $object = shift @objects) {
    my $expect = shift @objects;
    is $encoder->object($object), $expect, $expect;
}


$encoder = RDF::aREF::Encoder->new( ns => 0 );
is $encoder->predicate('http://purl.org/dc/terms/title'), 'http://purl.org/dc/terms/title';
is $encoder->qname('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), 'rdf_type';
is $encoder->literal( 42, undef, 'http://www.w3.org/2001/XMLSchema#integer'), '42^xsd_integer';

done_testing;
