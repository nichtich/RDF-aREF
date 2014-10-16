use strict;
use warnings;
use Test::More;
use RDF::aREF;
use RDF::aREF::Encoder;

my $example = {
    "http://example.org/about" => {
        "http://purl.org/dc/terms/title" => [ 
            { value => "Anna's Homepage", 
               type => "literal", 
               lang => "en" } ]
    } 
};
my $encoder = RDF::aREF::Encoder->new( ns => '20140910' );
my $aref = {};
$encoder->add_hashref($aref, $example);
is_deeply $aref, {
      "http://example.org/about" => { dct_title => "Anna's Homepage\@en" }
    }, 'add_hashref';

use RDF::aREF;
is_deeply encode_aref($example), $aref, 'encode_aref(hashref)';
is_deeply encode_aref($example, ns => 0), {
    "http://example.org/about" => { 
        "http://purl.org/dc/terms/title" => "Anna's Homepage\@en" 
    }
}, 'encode_aref(hashref, ns => 0)';

done_testing;
