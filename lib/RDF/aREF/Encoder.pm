package RDF::aREF::Encoder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.12';

use RDF::NS;

has ns => ( 
    is => 'ro', 
    default => sub { RDF::NS->new },
    coerce => sub {
        return $_[0] if blessed($_[0]) and $_[0]->isa('RDF::NS');
        return if !$_[0];
        return RDF::NS->new($_[0]);
    },
    handles => ['uri'],
);

has 'sn' => (
    is => 'ro',
    lazy    => 1,
    builder => sub {
        $_[0]->ns ? $_[0]->ns->REVERSE : undef
    }
);

sub aref_iri {
    my ($self, $uri, $sep) = @_; # type: subjec/predicate/object

    return 'a' if $uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

    if ($self->sn) {
        my @qname = $self->sn->qname($uri);
        return join($sep,@qname) if @qname;
    }

    return "<$uri>";
}

sub aref_object {
    my ($self, $object) = @_;
    if ($object->{type} eq 'literal') {
        my $value = $object->{value};
        if ($object->{lang}) {
            return $value.'@'.$object->{lang};
        } elsif ($object->{datatype}) {
            my $dt = $self->aref_iri($object->{datatype},':');
            return "$value^$dt";
        } else {
            return "$value@";
        }
    } elsif ($object->{type} eq 'bnode') {
        return $object->{value};
    } else {
        my $obj = $self->aref_iri($object->{value},':');
        return $obj;
    }
}

1;
__END__

=head1 NAME

RDF::aREF::Encoder - encode RDF to another RDF Encoding Form

=head1 DESCRIPTION

This module implements methods for encoding RDF data in another RDF Encoding
Form (aREF).

This module is experimental!

=head1 OPTIONS

=head2 ns

A default namespace map, given either as hash reference or as version string of
module L<RDF::NS>. Set to the most recent version of RDF::NS by default, but relying
on a default value is not recommended!

=head1 SEE ALSO

L<RDF::aREF::Decoder>

=cut
