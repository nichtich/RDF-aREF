use Test::More;
use strict;
use warnings;

use RDF::aREF qw(aref_query);

BEGIN {
    eval { require JSON; 1; } 
    or plan skip_all => "test requires JSON";
}

my $rdf = JSON::from_json(do { local (@ARGV, $/) = "t/doi-example.json"; <> });
my $uri = "http://dx.doi.org/10.2474/trol.7.147";

is_deeply [ aref_query($rdf, $uri, 'dct_title') ], 
    ['Frictional Coefficient under Banana Skin'], 'dct_title';
is_deeply [ aref_query($rdf, $uri, 'dct_title@') ], 
    ['Frictional Coefficient under Banana Skin'], 'dct_title@';
is_deeply [ aref_query($rdf, $uri, 'dct_title^xsd_string') ], 
    ['Frictional Coefficient under Banana Skin'], 'dct_title^xsd_string';
is_deeply [ aref_query($rdf, $uri, 'dct_title@en') ], 
    [ ], 'dct_title@';

is_deeply [ sort(aref_query($rdf->{$uri}, 'dct_publisher')) ], [
    'Japanese Society of Tribologists',
    'http://d-nb.info/gnd/5027072-2',
], 'dct_publisher';

is_deeply [ aref_query($rdf->{$uri}, 'dct_publisher.') ], [
    'http://d-nb.info/gnd/5027072-2',
], 'dct_publisher.';

is_deeply [ aref_query($rdf->{$uri}, 'dct_date') ], ["2012"], 'dct_date';
is_deeply [ aref_query($rdf->{$uri}, 'dct_date^xsd_gYear') ], ["2012"], 'dct_date^xsd_gYear';
is_deeply [ aref_query($rdf->{$uri}, 'dct_date^xsd_foo') ], [], 'dct_date^xsd_foo';

foreach my $query (qw(dct_creator dct_creator.)) {
    is_deeply [ sort (aref_query($rdf, $uri, $query)) ], [
        "http://id.crossref.org/contributor/daichi-uchijima-y2ol1uygjx72",
        "http://id.crossref.org/contributor/kensei-tanaka-y2ol1uygjx72",
        "http://id.crossref.org/contributor/kiyoshi-mabuchi-y2ol1uygjx72",
        "http://id.crossref.org/contributor/rina-sakai-y2ol1uygjx72",
    ], $query;
}

is join(' ',sort(aref_query($rdf,$uri,'dct_creator.foaf_familyName'))),
    "Mabuchi Sakai Tanaka Uchijima", 'dct_creator.foaf_familyName';

my %names = (
    'dct_creator.foaf_name'  => 4,
    'dct_creator.foaf_name@' => 4,
    'dct_creator.foaf_name@en' => 4,
    'dct_creator.foaf_name@ja' => 0,
);
while ( my ($query, $count) = each %names ) {
    my @names = aref_query( $rdf, $uri, $query );
    is scalar @names, $count, $query;
}

done_testing;
