package RDF::aREF::Encoder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.13';

use RDF::NS;
use Scalar::Util qw(blessed);

sub new {
    my ($class, %options) = @_;

    $options{ns} ||= RDF::NS->new;
    unless ( blessed $options{ns} and $options{ns}->isa('RDF::NS') ) {
        $options{ns} = RDF::NS->new($_[0]);
    }

    $options{sn} = $options{ns}->REVERSE;

    bless \%options, $class;
}

sub qname {
    my ($self, $uri) = @_;
    return unless $self->{sn};
    my @qname = $self->{sn}->qname($uri);
    return @qname ? join('_',@qname) : undef;
}

sub uri {
    my ($self, $uri) = @_;

    if ( my $qname = $self->qname($uri) ) {
        return $qname;
    } else {
        return "<$uri>";
    }
}

sub predicate {
    my ($self, $predicate) = @_;

    return 'a' if $predicate eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';

    if ( my $qname = $self->qname($predicate) ) {
        return $qname;
    } else {
        return $predicate;
    }
}

sub object {
    my ($self, $object) = @_;
    if ($object->{type} eq 'literal') {
        my $value = $object->{value};
        if ($object->{lang}) {
            return $value.'@'.$object->{lang};
        } elsif ($object->{datatype}) {
            my $dt = $self->uri($object->{datatype});
            return "$value^$dt";
        } else {
            return "$value@";
        }
    } elsif ($object->{type} eq 'bnode') {
        return $object->{value};
    } else {
        return $self->uri($object->{value});
    }
}

1;
__END__

=head1 NAME

RDF::aREF::Encoder - encode RDF to another RDF Encoding Form

=head1 SYNOPSIS

    use RDF::aREF::Encoder;
    my $encoder = RDF::aREF::Encoder->new;
    
    my $qname  = $encoder->qname('http://schema.org/Review'); # 'schema_Review'

    my $predicate = $encoder->predicate(
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    ); # 'a'

    my $object = $encoder->object({
        type  => 'literal',
        value => 'hello, world!',
        lang  => 'en'
    }); # 'hello, world!@en'

=head1 DESCRIPTION

This module provides methods to encode RDF data in another RDF Encoding Form
(aREF). aREF was designed to facilitate creation of RDF data, so consider I<not
using this module> unless you already have RDF data.

=head1 OPTIONS

=head2 ns

A default namespace map, given either as hash reference or as version string of
module L<RDF::NS>. The most recent installed version of RDF::NS is used by
default.

=head1 METHODS

=head2 qname( $uri )

Abbreviate an URI or return undef. For instance
C<http://purl.org/dc/terms/title> is abbreviated to C<dct_title>.

=head2 predicate( $predicate )

Return an predicate URI as qname, if possible, or as given URI otherwise.

=head2 uri( $uri )

Abbreviate an URI or enclose it in angular brackets.

=head2 object( $object )

Encode an RDF object given in L<RDF/JSON|http://www.w3.org/TR/rdf-json/>
format, that is a hash reference with the following fields:

=over

=item type

one of C<uri>, C<literal> or C<bnode> (required)

=item value

the URI of the object, its lexical value or a blank node label depending on
whether the object is a uri, literal or bnode

=item lang

the language of a literal value (optional but if supplied it must not be empty)

=item datatype

the datatype URI of the literal value (optional)

=back

Please consider encoding by hand if you try to express non-RDF data in aREF:
append "C<@>" and an optional language tag to literal strings, append "C<^>"
and a datatype to datatype values, and abbreviate URIs as qualified names
(see method qname) or put them in anglular brackets C<< <...> >>.

=head1 SEE ALSO

L<RDF::aREF::Decoder>

=cut
