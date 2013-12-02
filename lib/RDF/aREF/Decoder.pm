use strict;
package RDF::aREF::Decoder;
#ABSTRACT: Decode another RDF Encoding Form (to RDF triples)
#VERSION
use RDF::NS;
use v5.12;
use feature 'unicode_strings';
use Scalar::Util qw(refaddr);

no warnings 'uninitialized';

our $nameChar = 'A-Z_a-z\N{U+00C0}-\N{U+00D6}\N{U+00D8}-\N{U+00F6}\N{U+00F8}-\N{U+02FF}\N{U+0370}-\N{U+037D}\N{U+037F}-\N{U+1FFF}\N{U+200C}-\N{U+200D}\N{U+2070}-\N{U+218F}\N{U+2C00}-\N{U+2FEF}\N{U+3001}-\N{U+D7FF}\N{U+F900}-\N{U+FDCF}\N{U+FDF0}-\N{U+FFFD}\N{U+10000}-\N{U+EFFFF}';
our $nameStartChar = $nameChar.'0-9\N{U+00B7}\N{U+0300}\N{U+036F}\N{U+203F}-\N{U+2040}-';
our $Prefix = '[a-z][a-z0-9]*';
our $Name   = "[$nameStartChar][$nameChar]*";

sub new {
    my ($class, %options) = @_;

    bless {
        ns       => $options{ns},
        callback => $options{callback} // sub { },
        error    => $options{error} // sub { say STDERR $_[0] },
    }, $class;
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
            for (keys %$map) {
                my $prefix = $_ eq '_' ? '' : $_;
                if ($prefix !~ /^([a-z][a-z0-9]*)?$/) {
                    $self->error("invalid prefix: $prefix");
                    # TODO: validate IRI base
                } else { 
                    $ns->{ $prefix } = $map->{$_};
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

    $self->{blank_node_ids} = { };
    $self->{blank_node_count} = 0;
    $self->{visited} = { };

    $self->namespace_map( $map->{"_ns"} );

    if (exists $map->{_id}) {
        my $subject = $self->resource( $map->{_id} );
        $self->predicate_map( $subject, $map ) if $subject;
    } else {
        for my $key (grep { $_ ne '_ns' } %$map) {
            my $subject = $self->resource($key) // next;
            my $predicates = $map->{$key};
            if (exists $predicates->{_id} and $self->resource( $predicates->{_id} ) ne $subject) {
                $self->error("inconsistent _id");
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

        my $predicate = $_ eq 'a'
            ? "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
            : $self->resource($_) // next;

        my $value = $map->{$_};
        foreach (ref $value eq 'ARRAY' ? @$value : $value) {
            if (ref $_ eq 'HASH') {
                my $object = exists $_->{_id}
                    ? ($self->resource($_->{_id}) // next)
                    : $self->blank_identifier();

                $self->triple( $subject, $predicate, $object );

                unless( $self->{visited}{refaddr $_} ) {
                    $self->predicate_map( $object, $_ );
                }
            } elsif (!ref $_) {
                my @object;

                if ( /^<(.+)>$/ ) {
                    push @object, $self->iri($1) // next;
                } elsif ( /^_:([a-zA-Z0-9]+)$/ ) {
                    push @object, $self->blank_identifier($1);
                } elsif ( /^($Prefix)?:($Name)$/ ) {
                    push @object, $self->prefixed_name($1,$2) // next;
                } elsif ( /^(.*)@([a-z]{2,8}(-[a-z0-9]{1,8})*)?$/i ) {
                    @object = ($1, defined $2 ? lc($2) : undef);
                } elsif ( /^(.*?)[\^][\^]?($Prefix)?:($Name)$/ ) {
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
                } elsif ( /^[a-z][a-z0-9+.-]*:/ ) {
                    @object = $self->iri($_) // next;
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
    # TODO: check RFC form 
    if (!$iri) {
        return $self->error("invalid IRI: $iri");
    } else {
        return $iri;
    }
}

=head2 resource( $string )

Returns an IRI (as string), a blank node (as string reference), or undef.

=cut
sub resource { 
    my ($self, $_) = @_;
    if ( /^<(.+)>$/ ) {
        $self->iri($1);
    } elsif ( /^_:([a-zA-Z0-9]+)$/ ) {
        $self->blank_identifier($1);
    } elsif ( /^(($Prefix)?[:_])?($Name)$/ ) {
        $self->prefixed_name($2,$3);
    } elsif ( qr{^[a-z][a-z0-9+.-]*:} )  {
        $self->iri($_);
    } else {
        $self->error("invalid IRI: $_");
    }
}

sub prefixed_name {
    my ($self, $prefix, $name) = @_;
    my $base = $self->{ns}{$prefix // ''}
        // return $self->error("unknown prefix: $prefix");
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

sub blank_identifier {
    my ($self, $id) = @_;

    # TODO: preserve ids on request

    my $bnode = defined $id 
        ? $self->{blank_node_ids}{$id} // 
          ($self->{blank_node_ids}{$id} = ++$self->{blank_node_count})
        : ++$self->{blank_node_count};

    return \$bnode;
}

1;

=head1 DESCRIPTION

For each RDF triple the callback method is called with a list of following elements:

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

=cut
