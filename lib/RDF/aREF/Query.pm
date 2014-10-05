package RDF::aREF::Query;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.15';

use RDF::aREF::Decoder qw(qName languageTag);
use Carp qw(croak);

sub new {
    my ($class, $expr, $decoder) = @_;
    $decoder //= RDF::aREF::Decoder->new();

    my $type = 'any';
    my ($language, $datatype);

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

    bless {
        path     => \@path,
        type     => $type,
        language => $language,
        datatype => $datatype,
        decoder  => $decoder,
    }, $class;
}

sub apply {
    my ($self, $rdf, $subject) = @_;

    my $decoder = $self->{decoder};

    # TODO: try abbreviated *and* full URI?
    my @current = ($subject ? $rdf->{$subject} : $rdf); # TODO: for predicate map

    my @path = @{$self->{path}};

    while (my $field = shift @path) {

        # get objects in aREF
        @current = grep { defined }
                   map { (ref $_ and ref $_ eq 'ARRAY') ? @$_ : $_ }
                   map { $_->{$field} } @current;
        return if !@current;

        if (@path or $self->{type} eq 'resource') {

            # get resources
            @current = grep { defined } 
                       map { $decoder->resource($_) } @current;

            if (@path) {
                # TODO: only if RDF given as predicate map!
                @current = grep { defined } map { $rdf->{$_} } @current;
            }

        } else {
            @current = grep { defined } map { $decoder->object($_) } @current;

            if ($self->{type} eq 'literal') {
                @current = map { $_ if @$_ > 1 } @current;

                if ($self->{language}) { # TODO: use language tag substring
                    @current = grep { $_->[1] and $_->[1] eq $self->{language} } 
                               @current; 
                } elsif ($self->{datatype}) { # TODO: support qName and explicit IRI
                    @current = grep { $_->[2] and $_->[2] eq $self->{datatype} } @current; 
                }
            }

            @current = map { $_->[0] } @current;
        }
    }

    return @current;
}

1;
__END__

=head1 NAME

RDF::aREF::Query - query expression to access parts of aREF data

=head1 DESCRIPTION

This module is experimental.

See function C<aref_query> in L<RDF::aREF> for usage.

=head1 METHODS

=head1 new( $expression [, $decoder ] )

=head1 apply( $rdf [, $subject ] )

=cut
