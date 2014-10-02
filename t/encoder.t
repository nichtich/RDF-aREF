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

is $encoder->object({
    type => 'resource',
    value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
}), 'rdf_type';

is $encoder->object({
    type  => 'literal',
    value => 'hello, world!',
    lang  => 'en'
}), 'hello, world!@en';

$encoder = RDF::aREF::Encoder->new( ns => 0 );
is $encoder->predicate('http://purl.org/dc/terms/title'), 'http://purl.org/dc/terms/title';
is $encoder->qname('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), 'rdf_type';

done_testing;
