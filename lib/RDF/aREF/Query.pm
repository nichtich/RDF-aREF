package RDF::aREF::Query;
use strict;
use warnings;
use v5.10;

our $VERSION = '0.18';

use RDF::aREF::Decoder qw(qName languageTag);
use Carp qw(croak);
use RDF::NS;

sub new {
    my ($class, %options) = @_;

    my $expr    = $options{query} or croak "query required";
    my $ns      = $options{ns} // RDF::NS->new;
    my $decoder = $options{decoder} // RDF::aREF::Decoder->new( ns => $ns );

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

sub query {
    my ($self) = @_;
    my $query = join '.', @{$self->{path}};
    if ($self->{type} eq 'literal') {
        if ($self->{datatype}) {
            $query .= '^' . $self->{datatype};
        } else {
            $query .= '@' . ($self->{language} // '');
        }
    } elsif ($self->{type} eq 'resource') {
        $query .= '.';
    }
    $query;
}

sub apply {
    my ($self, $rdf, $subject) = @_;

    my $decoder = $self->{decoder};

    # TODO: Support RDF::Trine::Model
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

        } else { # last path element
            @current = grep { defined } map { $decoder->object($_) } @current;

            if ($self->{type} eq 'literal') {
                @current = grep { @$_ > 1 } @current;

                if ($self->{language}) { # TODO: use language tag substring
                    @current = grep { $_->[1] and $_->[1] eq $self->{language} } 
                               @current; 
                } elsif ($self->{datatype}) { # TODO: support qName and explicit IRI
                    @current = grep { $_->[2] and $_->[2] eq $self->{datatype} } @current; 
                }
            }

            @current = map { $_->[0] } @current; # IRI or string value
        }
    }

    return @current;
}

1;
__END__

=head1 NAME

RDF::aREF::Query - aREF query expression

=head1 SYNOPSIS

    my $rdf = {
        'http://example.org/book' => {
            dct_creator => [
                'http://example.org/alice', 
                'http://example.org/bob'
            ]
        },
        'http://example.org/alice' => {
            foaf_name => "Alice"
        },
        'http://example.org/bob' => {
            foaf_name => "Bob"
        }
    };

    my $getnames = RDF::aREF::Query->new( 
        query => 'dct_creator.foaf_name' 
    );
    my @names = $getnames->apply( $rdf, 'http://example.org/boo' );
    $getnames->query; # 'dct_creator.foaf_name'

    use RDF::aREF qw(aref_query_map);
    my $record = aref_query_map( $rdf, $publication, {
        'dct_creator@' => 'creator',
        'dct_creator.foaf_name' => 'creator',
    });

=head1 DESCRIPTION

Implements L<aREF query|http://gbv.github.io/aREF/aREF.html#aref-query>, a
query language to access strings and nodes from agiven RDF graph.

See also functions C<aref_query> and C<aref_query_map> in L<RDF::aREF> for
convenient application.

=head1 CONFIGURATION

The constructor expects the following options:

=over

=item query

L<aREF query|http://gbv.github.io/aREF/aREF.html#aref-query> expression

=item decoder

Instance of L<RDF::aREF::Decoder> to map qNames to URIs. A new instance is
created unless given.

=item ns

Optional namespace map (L<RDF::NS>), passed to the constructor of
L<RDF::aREF::Decoder> if no decoder is given.

=back

=head1 METHODS

=head1 apply( $graph [, $origin ] )

Perform the query on a given RDF graph. The graph can be given as aREF
structure (subject map or predicate map) or as instance of
L<RDF::Trine::Model>. An origin subject node must be provided unless the RDF
graph is provided as L<predicate
map|http://gbv.github.io/aREF/aREF.html#predicate-maps>.

=head1 query

Returns the aREF query expression

=head1 SEE ALSO

Use SPARQL for more complex queries, e.g. with L<RDF::Trine::Store::SPARQL>.

=cut
