use strict;
use warnings;
package RDF::aREF;
#ABSTRACT: Another RDF Encoding Form
#VERSION

use RDF::aREF::Decoder;

use parent 'Exporter';
our @EXPORT = qw(decode_aref);
our @EXPORT_OK = qw(aref_to_trine_statement decode_aref);

sub decode_aref(@) { ## no critic
    my ($aref, %options) = @_;
    RDF::aREF::Decoder->new(%options)->decode($aref);
}

# experimental
# TODO: test this
sub aref_to_trine_statement {
    require RDF::Trine::Statement;

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

=head1 DESCRIPTION

aREF (L<another RDF Encoding Form|http://gbv.github.io/aREF/>) is an encoding
of RDF graphs in form of arrays, hashes, and Unicode strings. This module 
implements decoding from aREF data to RDF triples.

=head1 EXPORTED FUNCTIONS

=head2 decode_aref ( $aref, [ %options ] )

Decodes an aREF document given as hash referece. This function is a shortcut for

    RDF::aREF::Decoder->new(%options)->decode($aref)

See L<RDF::aREF::Decoder> for possible options.

=head1 SEE ALSO

=over

=item 

This module was first packaged together with L<Catmandu::RDF>.

=item

aREF is being specified at L<http://github.com/gbv/aREF>.

=item

See L<RDF::YAML> for a similar (outdated) RDF encoding in YAML.

=back

=encoding utf8

=cut
