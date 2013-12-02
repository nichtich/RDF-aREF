use strict;
use Test::More;
use File::Find;

BEGIN {
    eval { 
        require RDF::Trine::Model; 
        require RDF::Trine::Serializer::NTriples::Canonical;
        require JSON;
        1; 
    } or do {
        plan skip_all => "RDF::Trine or JSON not installed";
    };
}

use RDF::aREF qw(aref_to_trine_statement);

find( sub {
    return if $_ !~ /(.+)\.json$/;
    my ($aref, $nt, $name) = ($_,"$1.nt",$1);
    $nt   = do { local (@ARGV,$/) = $nt; <> };
    $aref = JSON::from_json( do { local (@ARGV,$/) = $aref; <> } );

    my $model = RDF::Trine::Model->new;
    my $serializer = RDF::Trine::Serializer::NTriples::Canonical->new( onfail=>'truncate' );
    $model->begin_bulk_ops;
    RDF::aREF::Decoder->new( callback => sub {
        $model->add_statement( aref_to_trine_statement( @_ ) ) 
    } )->decode( $aref );
    $model->end_bulk_ops;
    my $got = $serializer->serialize_model_to_string($model);
    $got =~ s/\r//g;
    is $got, $nt, $name;
},'t/examples');

ok(1);

done_testing;
