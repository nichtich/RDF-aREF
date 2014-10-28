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
      foaf_age  => '42^xsd_integer',
      foaf_homepage => [
         { 
           _id => 'http://personal.example.org/',
           dct_modified => '2010-05-29^xsd_date',
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
    
    my @lastmod = aref_query $rdf, 'foaf_homepage.dct_modified^';

    my $model = RDF::Trine::Model->new;
    decode_aref( $rdf, callback => $model );
    print RDF::Trine::Serializer->new('Turtle')->serialize_model_to_string($model);

    my $model = RDF::Trine::Model->new;
    RDF::Trine::Parser->parse_url_into_model($url, $model);
    my $aref = encode_aref $model;

# DESCRIPTION

**aREF** ([another RDF Encoding Form](http://gbv.github.io/aREF/)) is an
encoding of RDF graphs in form of arrays, hashes, and Unicode strings. This
module provides methods for decoding from aREF data to RDF triples
([RDF::aREF::Decoder](https://metacpan.org/pod/RDF::aREF::Decoder)), for encoding RDF data in aREF ([RDF::aREF::Encoder](https://metacpan.org/pod/RDF::aREF::Encoder)),
and for querying parts of an RDF graph ([RDF::aREF::Query](https://metacpan.org/pod/RDF::aREF::Query)).

# EXPORTED FUNCTIONS

The following functions are exported by default.

## decode\_aref $aref \[, %options \]

Decodes an aREF document given as hash reference with [RDF::aREF::Decoder](https://metacpan.org/pod/RDF::aREF::Decoder).
Equivalent to `RDF::aREF::Decoder->new(%options)->decode($aref)`.

## encode\_aref $graph \[, %options \]

Construct an aREF subject map (using a new [RDF::aREF::Encoder](https://metacpan.org/pod/RDF::aREF::Encoder)) fron an RDF
graph. The graph can be supplied as:

- instance of [RDF::Trine::Model](https://metacpan.org/pod/RDF::Trine::Model)
- instance of [RDF::Trine::Model::Iterator](https://metacpan.org/pod/RDF::Trine::Model::Iterator)
- an URL (experimental and only if RDF::Trine is installed)
- instance of [Attean::API::TripleIterator](https://metacpan.org/pod/Attean::API::TripleIterator) (experimental)
- instance of [Attean::API::TripleStore](https://metacpan.org/pod/Attean::API::TripleStore) (experimental)
- hash reference with [RDF/JSON](http://www.w3.org/TR/rdf-json/) format (as
returned by method `as_hashref` in [RDF::Trine::Model](https://metacpan.org/pod/RDF::Trine::Model))

## aref\_query $graph, \[ $origin \], @queries

Query parts of an aREF data structure by [aREF query
expressions](http://gbv.github.io/aREF/aREF.html#aref-query) and return a list.
See [RDF::aREF::Query](https://metacpan.org/pod/RDF::aREF::Query) for details.

## aref\_query\_map( $graph, \[ $origin \], $query\_map )

Map parts of an aREF data structure to a flat key-value structure.

# SEE ALSO

- aREF is specified at [http://github.com/gbv/aREF](http://github.com/gbv/aREF).
- See [Catmandu::RDF](https://metacpan.org/pod/Catmandu::RDF) for an application of this module.
- Usee [RDF::Trine](https://metacpan.org/pod/RDF::Trine) for more elaborated handling of RDF data in Perl.
- See [RDF::YAML](https://metacpan.org/pod/RDF::YAML) for a similar (outdated) RDF encoding in YAML.

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
