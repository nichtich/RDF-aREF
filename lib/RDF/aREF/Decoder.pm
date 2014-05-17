use strict;
use warnings;
package RDF::aREF::Decoder;
#ABSTRACT: Decode another RDF Encoding Form (to RDF triples)
our $VERSION = '0.11'; #VERSION
use RDF::NS;
use v5.12;
use feature 'unicode_strings';
use Scalar::Util qw(refaddr blessed);

no warnings 'uninitialized';

our $nameChar = 'A-Z_a-z\N{U+00C0}-\N{U+00D6}\N{U+00D8}-\N{U+00F6}\N{U+00F8}-\N{U+02FF}\N{U+0370}-\N{U+037D}\N{U+037F}-\N{U+1FFF}\N{U+200C}-\N{U+200D}\N{U+2070}-\N{U+218F}\N{U+2C00}-\N{U+2FEF}\N{U+3001}-\N{U+D7FF}\N{U+F900}-\N{U+FDCF}\N{U+FDF0}-\N{U+FFFD}\N{U+10000}-\N{U+EFFFF}';
our $nameStartChar = $nameChar.'0-9\N{U+00B7}\N{U+0300}\N{U+036F}\N{U+203F}-\N{U+2040}-';
our $Prefix = '[a-z][a-z0-9]*';
our $Name   = "[$nameStartChar][$nameChar]*";

use constant explicitIRI => qr/^<(.+)>$/;
use constant IRIlike     => qr/^[a-z][a-z0-9+.-]*:/;
use constant blankNode   => qr/^_:([a-zA-Z0-9]+)$/;

sub new {
    my ($class, %options) = @_;

    my $self = bless {
        ns           => $options{ns},
        error        => $options{error} // sub { say STDERR $_[0] },
        strict       => $options{strict} // 0,
        null         => $options{null}, # undef by default
        bnode_prefix => $options{bnode_prefix} || 'b',
        bnode_count  => $options{bnode_count} || 0,
    }, $class;

    # facilitate use of this module together with RDF::Trine
    my $callback = $options{callback} // sub { };
    if (blessed $callback and $callback->isa('RDF::Trine::Model')) {
        require RDF::Trine::Statement;
        my $model = $callback;
        $callback = sub {
            eval {
                $model->add_statement( aref_to_trine_statement( @_ ) )
            };
            $self->error($@) if $@;
        };
    }
    $self->{callback} = $callback;

    return $self;
}

sub namespace_map { # sets the local namespace map
    my ($self, $map) = @_;

    # TODO: copy on write because this is expensive!
    
    # copy default namespace map
    my $ns = ref $self->{ns} 
        ? bless { %{$self->{ns}} }, 'RDF::NS'
        : RDF::NS->new($self->{ns});

    if (ref $map) {
        if (ref $map eq 'HASH') {
            while (my ($prefix,$namespace) = each %$map) {
                $prefix = '' if $prefix eq '_';
                if ($prefix !~ /^([a-z][a-z0-9+.-]*)?$/) {
                    $self->error("invalid prefix: $prefix");
                } elsif ($namespace !~ IRIlike) {
                    $self->error("invalid namespace: $namespace");
                } else { 
                    $ns->{$prefix} = $namespace;
                }
            }
        } else {
            $self->error("namespace map must be map or string");
        }
    } elsif (defined $map) {
        # set default namespace (TODO: validate)
        $ns->{''} = $map;
    }

    $self->{ns} = $ns;
}

sub decode {
    my ($self, $map) = @_;

    $self->{blank_node_ids} = { }; # required (?)
    $self->{visited} = { };

    $self->namespace_map( $map->{"_ns"} );

    if (exists $map->{_id}) {
        my $id = $map->{_id};
        my $subject = ($id // '') ne '' ? $self->resource($id,\'subject') : undef;
        if (defined $subject and $subject ne '') {
            $self->predicate_map( $subject, $map );
        } elsif ($self->{strict}) { 
            $self->error("invalid subject $id");
        }
    } else {
        for my $key (grep { $_ ne '_ns' } keys %$map) {
            next if $key eq '' and !$self->{strict};
            my $subject = $self->resource($key,\'subject') // next;
            my $predicates = $map->{$key};
            if (exists $predicates->{_id} and $self->resource($predicates->{_id}) ne $subject) {
                $self->error("subject _id must be <$subject>");
            } else {
                $self->predicate_map( $subject, $predicates );
            }
        }
    }
}

sub predicate_map {
    my ($self, $subject, $map) = @_;

    $self->{visited}{refaddr $map} = 1;

    for (keys %$map) {
        next if $_ eq '_id' or $_ eq '_ns';

        my $predicate = do {
            if ($_ eq 'a') {
                "http://www.w3.org/1999/02/22-rdf-syntax-ns#type";
            } elsif ( /^<(.+)>$/ ) {
                $self->iri($1);
            } elsif ( /^(($Prefix)?[:_])?($Name)$/o ) {
                $self->prefixed_name($2,$3);
            } elsif ( $_ =~ IRIlike ) {
                $self->iri($_);
            } else {
                $self->error("invalid predicate IRI $_")
                    if $_ ne '' or $self->{strict};
                next;
            }
        } or next;

        my $value = $map->{$_};
        # empty arrays are always alowed BTW
        foreach (ref $value eq 'ARRAY' ? @$value : $value) {

            # ???
            if (defined $self->{null} and $_ eq $self->{null}) {
                $_ = undef;
            }
            # TODO: undef is ignored - is this an error?

            if (ref $_ eq 'HASH') {
                my $object = exists $_->{_id}
                    ? ($self->resource($_->{_id},\'object _id') // next)
                    : $self->blank_identifier();

                $self->triple( $subject, $predicate, $object );

                unless( $self->{visited}{refaddr $_} ) {
                    $self->predicate_map( $object, $_ );
                }
            } elsif (!ref $_) {
                my @object;

                if ( $_ =~ explicitIRI ) {
                    push @object, $self->iri($1) // next;
                } elsif ( $_ =~ blankNode ) {
                    push @object, $self->blank_identifier($1);
                } elsif ( /^($Prefix)?:($Name)$/o ) {
                    push @object, $self->prefixed_name($1,$2) // next;
                } elsif ( /^(.*)@([a-z]{2,8}(-[a-z0-9]{1,8})*)?$/i ) {
                    @object = ($1, defined $2 ? lc($2) : undef);
                } elsif ( /^(.*?)[\^][\^]?($Prefix)?:($Name)$/o ) {
                    my $datatype = $self->prefixed_name($2,$3) // next;
                    if ($datatype eq 'http://www.w3.org/2001/XMLSchema#string') {
                        @object = ($1,undef);
                    } else {
                        @object = ($1,undef,$datatype);
                    }
                } elsif ( /^(.*?)[\^][\^]?<([a-z][a-z0-9+.-]*:.*)>$/ ) {
                    my $datatype = $self->iri($2) // next;
                    if ($datatype eq 'http://www.w3.org/2001/XMLSchema#string') {
                        @object = ($1,undef);
                    } else {
                        @object = ($1,undef,$datatype);
                    }
                } elsif ( $_ =~ IRIlike ) {
                    @object = $self->iri($_) // next;
                } elsif (!defined $_) {
                    $self->error('object must not be null') if $self->{strict};
                    next;
                } else {
                    @object = ($_,undef);
                }
                $self->triple( $subject, $predicate, @object );
            } else {
                $self->error('object must not be reference to '.ref $_);
            }
        }
    }
}

sub iri {
    my ($self, $iri) = @_;
    # TODO: check full RFC form of IRIs
    if ( $iri !~ IRIlike ) {
        return $self->error("invalid IRI $iri");
    } else {
        return $iri;
    }
}

# Returns an IRI (as string), a blank node (as string reference), or undef.
sub resource { 
    my ($self, $r, $expect) = @_;
    if ( $r =~ explicitIRI ) {
        $self->iri($1);
    } elsif ( $r =~ blankNode ) {
        $self->blank_identifier($1);
    } elsif ( $r =~ /^(($Prefix)?[:_])?($Name)$/o ) {
        $self->prefixed_name($2,$3);
    } elsif ( $r =~ IRIlike )  {
        $self->iri($r);
    } else {
        $self->error("invalid ".$$expect." $r") if $expect;
        undef;
    }
}

sub prefixed_name {
    my ($self, $prefix, $name) = @_;
    my $base = $self->{ns}{$prefix // ''}
        // return $self->error(
            $prefix // '' ne '' 
            ? "unknown prefix: $prefix" : "not an URI: $name");
    $self->iri($base.$name);
}

sub triple {
    my $self = shift;
    $self->{callback}->(@_);
}

sub error {
    $_[0]->{error}->($_[1]); # TODO: also pass location path
    return;
}

sub bnode_count {
    $_[0]->{bnode_count} = $_[1] if @_ > 1;
    $_[0]->{bnode_count};
}

sub blank_identifier {
    my ($self, $id) = @_;

    # TODO: preserve ids on request

    my $bnode;
    if ( defined $id ) {
        $bnode = ($self->{blank_node_ids}{$id} //= $self->{bnode_prefix} . ++$self->{bnode_count});
    } else {
        $bnode = $self->{bnode_prefix} . ++$self->{bnode_count};
    }

    return \$bnode;
}
 
# TODO: test this
sub aref_to_trine_statement {
    RDF::Trine::Statement->new(
        # subject
        ref $_[0] ? RDF::Trine::Node::Blank->new(${$_[0]})
            : RDF::Trine::Node::Resource->new($_[0]),
        # predicate
        RDF::Trine::Node::Resource->new($_[1]),
        # object
        do {
            if (ref $_[2]) {
                RDF::Trine::Node::Blank->new(${$_[2]});
            } elsif (@_ == 3) {
                RDF::Trine::Node::Resource->new($_[2]);
            } else {
                RDF::Trine::Node::Literal->new($_[2],$_[3],$_[4]);
            } 
        }
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::aREF::Decoder - Decode another RDF Encoding Form (to RDF triples)

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use RDF::aREF::Decoder;

    RDF::aREF::Decoder->new( %options )->decode( $aref );

=head1 DESCRIPTION

This module implements a decoder from another RDF Encoding Form (aREF), given
as in form of Perl arrays, hashes, and Unicode strings, to RDF triples.

=head1 OPTIONS

=head2 ns

A default namespace map, given either as hash reference or as version string of
module L<RDF::NS>. Set to the most recent version of RDF::NS by default, but relying
on a default value is not recommended!

=head2 callback

A code reference that is called for each triple with a list of three to five
elements:

=over

=item subject

The subject IRI as string or subject blank node as string reference.

=item predicate

The predicate IRI.

=item object

The object IRI as string or object blank node as string reference or
literal object as string.

=item language

The language tag (possible the empty string) for literal objects.

=item datatype

The object's datatype if object is a literal and datatype is not
C<http://www.w3.org/2001/XMLSchema#string>.

=back

For convenience an instance of L<RDF::Trine::Model> can also be used as
callback.

=head2 error

A code reference that decoding errors are passed to. By default an error
message is printed to STDOUT.

=head2 strict

Enables errors on undefined subjects, predicates, and objects. By default
the Perl value C<undef> in any part of an encoded RDF triple will silently
ignore the triple, so aREF structures can easily be used as templates with
optional values.

=head2 null

A null object that is treated equivalent to C<undef> if found as object.  For
instance setting this to the empty string will ignore all triples with the
empty string as literal value. 

=head2 bnode_prefix

A prefix for blank node identifiers. Defaults to "b", so blank node identifiers
will be "b1", "b2", "b3" etc.

=head2 bnode_counter

An integer to start creating blank node identifiers with. The default value "0"
results in blank node identifiers starting from "b1". This option can be useful
to avoid collision of blank node identifiers when merging multiple aREF
instances. The current counter value is accessible as accessor.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
