package RDF::aREF::Encoder;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.18';

use RDF::NS;
use Scalar::Util qw(blessed reftype);

sub new {
    my ($class, %options) = @_;

    if (!defined $options{ns}) {
        $options{ns} = RDF::NS->new;
    } elsif (!$options{ns}) {
        $options{ns} = bless {
            rdf =>  'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
            owl =>  'http://www.w3.org/2002/07/owl#',
            xsd =>  'http://www.w3.org/2001/XMLSchema#',
        }, 'RDF::NS';
    } elsif ( !blessed $options{ns} or !$options{ns}->isa('RDF::NS') ) {
        $options{ns} = RDF::NS->new($options{ns});
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

    if (reftype $object eq 'HASH') {
        if ($object->{type} eq 'literal') {
            $self->literal( $object->{value}, $object->{lang}, $object->{datatype} )
        } elsif ($object->{type} eq 'bnode') {
            $object->{value}
        } else {
            $self->uri($object->{value})
        }
    } elsif (reftype $object eq 'ARRAY') {
        if (@$object == 3) {
            $self->literal(@$object)
        } elsif ($object->[0] eq 'URI') {
            $self->uri("".$object->[1])
        } elsif ($object->[0] eq 'BLANK') {
            $self->bnode($object->[1])
        } else {
            return
        }
    } else {
        return
    }
}

sub literal {
    my ($self, $value, $language, $datatype) = @_;
    if ($language) {
        $value.'@'.$language
    } elsif ($datatype) {
        $value.'^'.$self->uri($datatype)
    } else {
        $value.'@'
    }
}

sub bnode {
    '_:'.$_[1]
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

    # method also accepts RDF::Trine::Node instances
    my $object = $encoder->object( RDF::Trine::Resource->new($iri) );

=head1 DESCRIPTION

This module provides methods to encode RDF data in another RDF Encoding Form
(aREF). As aREF was designed to facilitate creation of RDF data, it may be
easier to create aREF "by hand" instead of using this module!

=head1 OPTIONS

=head2 ns

A default namespace map, given as version string of module L<RDF::NS> for
stable qNames or as instance of L<RDF::NS>. The most recent installed version
of L<RDF::NS> is used by default. The value C<0> can be used to only use
required namespace mappings (rdf, rdfs, owl and xsd).

=head1 METHODS

Note that no syntax checking is applied, e.g. whether a given URI is a valid
URI or whether a given language is a valid language tag.

=head2 qname( $uri )

Abbreviate an URI as qName or return C<undef>. For instance
C<http://purl.org/dc/terms/title> is abbreviated to "C<dct_title>".

=head2 uri( $uri )

Abbreviate an URI or as qName or enclose it in angular brackets.

=head2 predicate( $uri )

Return an predicate URI as qNamem, as "C<a>", or as given URI.

=head2 literal( $value, $language_tag, $datatype_uri )

Encode a literal RDF node by either appending "C<@>" and an optional
language tag, or "C<^>" and an datatype URI.

=head2 bnode( $identifier )

Encode a blank node by prepending "C<_:>" to its identifier.

=head2 object( $object )

Encode an RDF object given either as hash reference as defined in
L<RDF/JSON|http://www.w3.org/TR/rdf-json/> format (see also method
C<as_hashref> of L<RDF::Trine::Iterator::Graph>), or in array reference as
internally used by L<RDF::Trine>.

A hash reference is expected to have the following fields:

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

An array reference is expected to consists of

=over

=item 

three elements (value, language tag, and datatype uri) for literal nodes,

=item 

two elements "C<URI>" and the URI for URI nodes,

=item

two elements "C<BLANK>" and the blank node identifier for blank nodes.

=back

=head1 SEE ALSO

L<RDF::aREF::Decoder>, L<RDF::Trine::Node>

=cut
