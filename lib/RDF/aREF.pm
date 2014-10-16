package RDF::aREF;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.20';

use RDF::aREF::Query;
use RDF::aREF::Decoder;
use RDF::aREF::Encoder;
use Scalar::Util qw(blessed reftype);
use Carp qw(croak);

use parent 'Exporter';
our @EXPORT = qw(decode_aref encode_aref aref_query aref_query_map);
our %EXPORT_TAGS = (all => [@EXPORT]);

sub decode_aref(@) { ## no critic
    my ($aref, %options) = @_;
    RDF::aREF::Decoder->new(%options)->decode($aref);
}

sub encode_aref(@) { ## no critic
    my ($source, %options) = @_;
    my $encoder = RDF::aREF::Encoder->new(%options);
    my $aref = {};

    if (blessed $source and $source->isa('RDF::Trine::Iterator')) {
        $encoder->add_iterator( $aref, $source );
    } elsif (blessed $source and $source->isa('RDF::Trine::Model')) {
        $encoder->add_iterator( $aref, $source->as_stream );
    } elsif (ref $source and reftype $source eq 'HASH') {
        $encoder->add_hashref( $aref, $source );
    } # TODO: add via callback with code reference
    
    return $aref;
}

sub aref_query {
    my ($graph, $origin, $query) = @_ < 3 ? ($_[0], undef, $_[1]) : @_;

    unless( blessed $query and $query->isa('RDF::aREF::Query') ) {
        $query = RDF::aREF::Query->new( query => $query );
    }

    $query->apply($graph, $origin);
}


sub aref_query_map {
    my ($graph, $origin, $map) = @_ < 3 ? ($_[0], undef, $_[1]) : @_;

    my %record;
    
    while (my ($query, $field) = each %$map) {
        my @values = aref_query( $origin ? ($graph, $origin, $query)
                                         : ($graph, $query) );
        if (@values) {
            if ($record{$field}) {
                if (ref $record{$field}) {
                    push @{$record{$field}}, @values;
                } else {
                    $record{$field} = [ $record{$field}, @values ];
                }
            } else {
                $record{$field} = @values > 1 ? \@values : $values[0];
            }
        }
    }

    \%record;
}

1;
__END__

=head1 NAME

RDF::aREF - Another RDF Encoding Form

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/RDF-aREF.png)](https://travis-ci.org/nichtich/RDF-aREF)
[![Coverage Status](https://coveralls.io/repos/nichtich/RDF-aREF/badge.png)](https://coveralls.io/r/nichtich/RDF-aREF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/RDF-aREF.png)](http://cpants.cpanauthors.org/dist/RDF-aREF)

=end markdown

=head1 SYNOPSIS

    use RDF::aREF;

    my $rdf = {
      _id       => 'http://example.com/people#alice',
      foaf_name => 'Alice Smith',
      foaf_age  => '42^xsd_integer',
      foaf_homepage => [
         { 
           _id => 'http://personal.example.org/',
           dct_modified => '2010-05-29^xsd_date',
         },
        'http://work.example.com/asmith/',
      ],
      foaf_knows => {
        dct_description => 'a nice guy@en',
      },
    };

    decode_aref( $rdf,
        callback => sub {
            my ($subject, $predicate, $object, $language, $datatype) = @_;
            ...
        }
    );
    
    my @lastmod = aref_query( $rdf, 'foaf_homepage.dct_modified^' );

    my $model = RDF::Trine::Model->new;
    decode_aref( $rdf, callback => $model );
    print RDF::Trine::Serializer->new('Turtle')->serialize_model_to_string($model);

    my $model = RDF::Trine::Model->new;
    RDF::Trine::Parser->parse_url_into_model($url, $model);
    my $aref = encode_aref $model;

=head1 DESCRIPTION

B<aREF> (L<another RDF Encoding Form|http://gbv.github.io/aREF/>) is an
encoding of RDF graphs in form of arrays, hashes, and Unicode strings. This
module provides methods for decoding from aREF data to RDF triples
(L<RDF::aREF::Decoder>), for encoding RDF data in aREF (L<RDF::aREF::Encoder>),
and for querying parts of an RDF graph (L<RDF::aREF::Query>).

=head1 EXPORTED FUNCTIONS

The following functions are exported by default.

=head2 decode_aref( $aref [, %options ] )

Decodes an aREF document given as hash reference with L<RDF::aREF::Decoder>.
Equivalent to C<< RDF::aREF::Decoder->new(%options)->decode($aref) >>.

=head2 encode_aref( $rdf [, %options ] )

Create a new L<RDF::aREF::Encoder> and construct an aREF subject map with RDF
triples given as L<RDF::Trine::Model>, as L<RDF::Trine::Model::Iterator> or as
hash reference with L<RDF/JSON|http://www.w3.org/TR/rdf-json/> format, as
returned by method C<as_hashref> in L<RDF::Trine::Model>.

I<experimental>

=head2 aref_query( $graph, [ $origin ], $query )

Query parts of an aREF data structure. See L<RDF::aREF::Query> for details.

=head2 aref_query_map( $graph, [ $origin ], $query_map )

Map parts of an aREF data structure to a flat key-value structure.

=head1 SEE ALSO

=over

=item

aREF is specified at L<http://github.com/gbv/aREF>.

=item 

See L<Catmandu::RDF> for an application of this module.

=item

Usee L<RDF::Trine> for more elaborated handling of RDF data in Perl.

=item

See L<RDF::YAML> for a similar (outdated) RDF encoding in YAML.

=back

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
