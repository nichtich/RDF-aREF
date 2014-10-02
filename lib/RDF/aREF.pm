package RDF::aREF;
use strict;
use warnings;
use v5.12;

our $VERSION = '0.14';

use RDF::aREF::Decoder qw(qName languageTag);
use Carp qw(croak);

use parent 'Exporter';
our @EXPORT = qw(decode_aref);
our @EXPORT_OK = qw(decode_aref aref_query aref_to_trine_statement);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub decode_aref(@) { ## no critic
    my ($aref, %options) = @_;
    RDF::aREF::Decoder->new(%options)->decode($aref);
}

sub aref_to_trine_statement {
    # TODO: warn 'RDF::aREF::aref_to_trine_statement will be removed!';
    RDF::aREF::Decoder::aref_to_trine_statement(@_);
}

# move to Decoder?
sub aref_query {
    my $rdf     = shift;
    my $subject = @_ > 1 ? shift : undef;
    my $expr    = shift // '';
    my $type = 'any';
    my ($language, $datatype);

    # TODO: default ns for decoder?
    state $decoder = RDF::aREF::Decoder->new( ns => RDF::NS->new );

    if ($expr =~ /^(.*)\.$/) {
        $type = 'resource';
        $expr = $1;
    } elsif ( $expr =~ /^([^@]*)@([^@]*)$/ ) {
        ($expr, $language) = ($1, $2);
        if ( $language eq '' or $language =~ languageTag ) {
            $type = 'literal';
        } else {
            croak 'invalid languageTag in aREF query';
        }
    } elsif ( $expr =~ /^([^^]*)\^([^^]*)$/ ) { # TODO: support explicit IRI
        ($expr, $datatype) = ($1, $2);
        if ( $datatype =~ qName ) {
            $type = 'literal';
            $datatype = $decoder->prefixed_name( split '_', $datatype );
            $datatype = undef if $datatype eq $decoder->prefixed_name('xsd','string');
        } else {
            croak 'invalid datatype qName in aREF query';
        }
    }

    my @path = split /\./, $expr;
    foreach (@path) {
        croak "invalid aref path expression" if $_ !~ qName;
    }

    # TODO: try abbreviated *and* full URI?
    my @current = ($subject ? $rdf->{$subject} : $rdf); # TODO: for predicate map

    while (my $field = shift @path) {

        # get objects in aREF
        @current = grep { defined }
                   map { (ref $_ and ref $_ eq 'ARRAY') ? @$_ : $_ }
                   map { $_->{$field} } @current;
        return if !@current;

        if (@path or $type eq 'resource') {

            # get resources
            @current = grep { defined } 
                       map { $decoder->resource($_) } @current;

            if (@path) {
                # TODO: only if RDF given as predicate map!
                @current = grep { defined } map { $rdf->{$_} } @current;
            }

        } else {
            @current = grep { defined } map { $decoder->object($_) } @current;

            if ($type eq 'literal') {
                @current = map { $_ if @$_ > 1 } @current;

                if ($language) { # TODO: use language tag substring
                    @current = grep { $_->[1] and $_->[1] eq $language } @current; 
                } elsif ($datatype) { # TODO: support qName and explicit IRI
                    @current = grep { $_->[2] and $_->[2] eq $datatype } @current; 
                }
            }

            @current = map { $_->[0] } @current;
        }
    }

    return @current;
}

sub aref_get_literal {
    state $decoder = RDF::aREF::Decoder->new;
    if (ref $_[0]) {
        return grep { defined } map { $decoder->plain_literal($_) } @{$_[0]};
    } else {
        $decoder->plain_literal(@_);
    }
}

sub aref_get_resource {
    state $decoder = RDF::aREF::Decoder->new;
    if (ref $_[0]) {
        return grep { defined } map { $decoder->resource($_) } @{$_[0]};
    } else {
        $decoder->resource(@_);
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
implements methods for decoding from aREF data to RDF triples
(L<RDF::aREF::Decoder>) and for encoding RDF data in aREF
(L<RDF::aREF::Encoder>).

=head1 EXPORTED FUNCTIONS

=head2 decode_aref( $aref, [ %options ] )

Decodes an aREF document given as hash reference. This function is a shortcut for
C<< RDF::aREF::Decoder->new(%options)->decode($aref) >>.

=head2 aref_query( $aref, [ $subject ], $query )

experimental.

=head1 SEE ALSO

=over

=item

aREF is being specified at L<http://github.com/gbv/aREF>.

=item 

This module was first packaged together with L<Catmandu::RDF>.

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
