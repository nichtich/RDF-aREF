package RDF::aREF;
#ABSTRACT: Another RDF Encoding Form
#VERSION

use strict;
use RDF::aREF::Decoder;

use parent 'Exporter';
#our @EXPORT = qw();

1;

=head1 DESCRIPTION

See L<RDF::aREF::Decoder> for a module that decodes B<another RDF Encoding Form
(aREF)> to RDF triples.

=head1 SEE ALSO

=over

=item 

This module was first packaged together with L<Catmandu::RDF>.

=item

aREF is being specified at L<http://github.com/gbv/aREF>.

=item

See L<RDF::YAML> for an outdated similar RDF encoding in YAML.

=back

=encoding utf8

=cut
