use strict;
use warnings;
use Test::More;
use RDF::aREF::Encoder;

sub test_encoder(@) {
    my ($encoder, $method, @tests) = @_;
    while (@tests) {
        my $input  = shift @tests;
        my $expect = shift @tests;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        if ( ref $expect ) {
            is_deeply $encoder->$method($input), $expect, $expect;
        } else {
            is $encoder->$method($input), $expect, $expect;
        }
    }
}

my $encoder = RDF::aREF::Encoder->new( ns => '20140910' );

test_encoder $encoder => 'qname',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => 'rdf_type',
    'http://schema.org/Review' => 'schema_Review',
;
test_encoder $encoder => 'predicate',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => 'a',
    'http://undefinednamespace.foo' => 'http://undefinednamespace.foo',
    'http://purl.org/dc/terms/title' => 'dct_title',
;

test_encoder $encoder => 'uri',
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => 'rdf_type',
    'http://undefinednamespace.foo' => '<http://undefinednamespace.foo>'
;

test_encoder $encoder => 'object',
  # RDF/JSON
    {
        type => 'resource',
        value => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    } => 'rdf_type',
    {
        type  => 'literal',
        value => 'hello, world!',
        lang  => 'en'
    } => 'hello, world!@en',
    {
        type  => 'literal',
        value => '12',
        datatype => 'http://www.w3.org/2001/XMLSchema#integer'
    } => '12^xs_integer',
    {
        type  => 'bnode',
        value => '_:12',
    } => '_:12',
  # RDF::Trine
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] => 'rdf_type',
    ['URI','http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] => 'rdf_type',
    ['BLANK', 0 ] => '_:0',
    ['hello, world!', 'en', undef ] => 'hello, world!@en',
    [42, undef, 'http://www.w3.org/2001/XMLSchema#integer'] => '42^xs_integer',
;

test_encoder $encoder => 'literal',
    '' => '@'
;

test_encoder $encoder => 'bnode',
    abc => '_:abc'
;

test_encoder $encoder => 'rdfjson',
    {
      "http://example.org/about" => {
          "http://purl.org/dc/terms/title" => [ { value => "Anna's Homepage", 
                                                  type => "literal", 
                                                  lang => "en" } ] 
      }
    } => {
      "http://example.org/about" => {
        dct_title => "Anna's Homepage\@en"
       }
    };

$encoder = RDF::aREF::Encoder->new( ns => 0 );
is $encoder->predicate('http://purl.org/dc/terms/title'), 'http://purl.org/dc/terms/title';
is $encoder->qname('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'), 'rdf_type';
is $encoder->literal( 42, undef, 'http://www.w3.org/2001/XMLSchema#integer'), '42^xsd_integer';

done_testing;
