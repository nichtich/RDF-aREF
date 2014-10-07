package RDF::aREF;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.17';

use RDF::aREF::Query;
use Scalar::Util qw(blessed);
use Carp qw(croak);

use parent 'Exporter';
our @EXPORT = qw(decode_aref);
our @EXPORT_OK = qw(decode_aref aref_query aref_to_trine_statement);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub decode_aref(@) { ## no critic
    my ($aref, %options) = @_;
    RDF::aREF::Decoder->new(%options)->decode($aref);
}

sub aref_query {
    my $rdf    = shift;
    my $origin = @_ > 1 ? shift : undef;
    my $query  = shift;

    unless( blessed $query and $query->isa('RDF::aREF::Query') ) {
        $query = RDF::aREF::Query->new( query => $query );
    }

    $query->apply($rdf, $origin);
}

# FIXME: this is undocumented but used by Catmandu::RDF. Remove?
sub aref_to_trine_statement {
    # warn 'RDF::aREF::aref_to_trine_statement will be removed!';
    RDF::aREF::Decoder::aref_to_trine_statement(@_);
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

=head1 DESCRIPTION

B<aREF> (L<another RDF Encoding Form|http://gbv.github.io/aREF/>) is an
encoding of RDF graphs in form of arrays, hashes, and Unicode strings. This
module provides methods for decoding from aREF data to RDF triples
(L<RDF::aREF::Decoder>), for encoding RDF data in aREF (L<RDF::aREF::Encoder>),
and for querying parts of an RDF graph (L<RDF::aREF::Query>).

=head1 EXPORTED FUNCTIONS

The following functions are exported by default.

=head2 decode_aref( $aref, [ %options ] )

Decodes an aREF document given as hash reference with L<RDF::aREF::Decoder>.
Equivalent to C<< RDF::aREF::Decoder->new(%options)->decode($aref) >>.

=head2 aref_query( $aref, [ $origin ], $query )

Query parts of an aREF data structure. See L<RDF::aREF::Query> for details.

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
