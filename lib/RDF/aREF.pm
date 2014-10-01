package RDF::aREF;
use strict;
use warnings;
use v5.12;

our $VERSION = '0.111';

use RDF::aREF::Decoder;

use parent 'Exporter';
our @EXPORT = qw(decode_aref);
our @EXPORT_OK = qw(aref_to_trine_statement decode_aref plain_literal);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub decode_aref(@) { ## no critic
    my ($aref, %options) = @_;
    RDF::aREF::Decoder->new(%options)->decode($aref);
}

sub aref_to_trine_statement {
    # TODO: warn 'RDF::aREF::aref_to_trine_statement will be removed!';
    RDF::aREF::Decoder::aref_to_trine_statement(@_);
}

sub plain_literal {
    state $decoder = RDF::aREF::Decoder->new;
    if (ref $_[0]) {
        return grep { defined } map { $decoder->plain_literal($_) } @{$_[0]};
    } else {
        $decoder->plain_literal(@_);
    }
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
      foaf_age  => '42^xsd:integer',
      foaf_homepage => [
         { 
           _id => 'http://personal.example.org/',
           dct_modified => '2010-05-29^xsd:date',
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
    
    my $model = RDF::Trine::Model->new;
    decode_aref( $rdf, callback => $model );
    print RDF::Trine::Serializer->new('Turtle')->serialize_model_to_string($model);

=head1 DESCRIPTION

aREF (L<another RDF Encoding Form|http://gbv.github.io/aREF/>) is an encoding
of RDF graphs in form of arrays, hashes, and Unicode strings. This module 
implements decoding from aREF data to RDF triples.

=head1 EXPORTED FUNCTIONS

=head2 decode_aref( $aref, [ %options ] )

Decodes an aREF document given as hash referece. This function is a shortcut for

    RDF::aREF::Decoder->new(%options)->decode($aref)

See L<RDF::aREF::Decoder> for possible options.

=head1 EXPORTABLE FUNCTIONS

=head2 plain_literal( @strings | \@strings )

Converts a list of aREF objects to plain strings by removing language tags or
datatypes.

=head1 SEE ALSO

=over

=item 

This module was first packaged together with L<Catmandu::RDF>.

=item

aREF is being specified at L<http://github.com/gbv/aREF>.

=item

L<RDF::Trine> contains much more for handling RDF data in Perl.

=item

See L<RDF::YAML> for a similar (outdated) RDF encoding in YAML.

=back

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
