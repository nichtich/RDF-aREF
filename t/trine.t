use strict;
use Test::More;
use RDF::aREF;

BEGIN {
    eval { 
        require RDF::Trine::Model; 
        1; 
    } or do {
        plan skip_all => "RDF::Trine required";
    };
}

my $model = RDF::Trine::Model->new;

decode_aref( {
        _id => 'http://example.org/alice',
        a => 'foaf:Person',
        foaf_knowns => 'http://example.org/bob'
    }, 
    callback => $model,
);
is $model->size, 2, 'added two statements';

decode_aref( {
        _id => 'http://example.org/alice',
        a => 'foaf:Person',
        foaf_knowns => 'http://example.org/claire'
    },
    callback => $model,
);
is $model->size, 3, 'added another statement';

done_testing;
