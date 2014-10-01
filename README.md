# NAME

RDF::aREF - Another RDF Encoding Form

# STATUS

[![Build Status](https://travis-ci.org/nichtich/RDF-aREF.png)](https://travis-ci.org/nichtich/RDF-aREF)
[![Coverage Status](https://coveralls.io/repos/nichtich/RDF-aREF/badge.png)](https://coveralls.io/r/nichtich/RDF-aREF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/RDF-aREF.png)](http://cpants.cpanauthors.org/dist/RDF-aREF)

# SYNOPSIS

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

# DESCRIPTION

aREF ([another RDF Encoding Form](http://gbv.github.io/aREF/)) is an encoding
of RDF graphs in form of arrays, hashes, and Unicode strings. This module 
implements decoding from aREF data to RDF triples.

# EXPORTED FUNCTIONS

## decode\_aref( $aref, \[ %options \] )

Decodes an aREF document given as hash referece. This function is a shortcut for

    RDF::aREF::Decoder->new(%options)->decode($aref)

See [RDF::aREF::Decoder](https://metacpan.org/pod/RDF::aREF::Decoder) for possible options.

# EXPORTABLE FUNCTIONS

## plain\_literal( @strings | \\@strings )

Converts a list of aREF objects to plain strings by removing language tags or
datatypes.

# SEE ALSO

- This module was first packaged together with [Catmandu::RDF](https://metacpan.org/pod/Catmandu::RDF).
- aREF is being specified at [http://github.com/gbv/aREF](http://github.com/gbv/aREF).
- [RDF::Trine](https://metacpan.org/pod/RDF::Trine) contains much more for handling RDF data in Perl.
- See [RDF::YAML](https://metacpan.org/pod/RDF::YAML) for a similar (outdated) RDF encoding in YAML.

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
