use strict;
use Test::More;
use RDF::aREF;

our %sub;
sub graph     { $sub{graph}->(@_); }
sub statement { $sub{statement}->(@_); }
sub iri       { $sub{iri}->(@_); }
sub blank     { $sub{blank}->(@_); }
sub literal   { $sub{literal}->(@_); }

subtest "RDF::Trine" => sub {
    if( eval {
        require RDF::Trine;
        $sub{iri}       = sub { RDF::Trine::iri(@_) };
        $sub{statement} = sub { RDF::Trine::statement(@_) };
        $sub{blank}     = sub { RDF::Trine::blank(@_) };
        $sub{literal}   = sub { RDF::Trine::literal(@_) };
        $sub{graph}     = sub { RDF::Trine::Model->new };
        1;
    }) {
        test_perlrdf();
    } else {
        plan skip_all => 'RDF::Trine required' 
    };
};

subtest "Attean" => sub {
    if( eval {
        require Attean::RDF;
        $sub{iri}       = sub { Attean::RDF::iri(@_) };
        $sub{statement} = sub { Attean::RDF::statement(@_) };
        $sub{blank}     = sub { Attean::RDF::blank(@_) };
        $sub{literal}   = sub { Attean::RDF::literal(@_) };
        $sub{graph}     = sub { Attean->get_store('Memory')->new };
        1;
    }) {
        test_perlrdf();
    } else {
        plan skip_all => 'Attean required' 
    }
};

sub test_perlrdf {
    my $model = graph();

    decode_aref( {
            _id => 'http://example.org/alice',
            a => 'foaf_Person',
            foaf_knowns => 'http://example.org/bob'
        }, 
        callback => $model,
    );
    is $model->size, 2, 'added two statements';

    my $aref = encode_aref $model;
    is_deeply $aref, {
           'http://example.org/alice' => {
             'a' => 'foaf_Person',
             'foaf_knowns' => '<http://example.org/bob>'
           }
        }, 'encode_aref from RDF::Trine::Model';

    decode_aref( {
            _id => 'http://example.org/alice',
            a => 'foaf_Person',
            foaf_knowns => 'http://example.org/claire'
        },
        callback => $model,
    );
    is $model->size, 3, 'added another statement';

    # bnodes
    $model = graph;
    my $decoder = RDF::aREF::Decoder->new( callback => $model );
    my $aref = { _id => '<x:subject>', foaf_knows => { foaf_name => 'alice' } }; 
    $decoder->decode( $aref );
    $decoder->decode( $aref );
    is $model->size, 4, 'no bnode collision';
    is $decoder->bnode_count, 2;
    $decoder->bnode_count(1);
    $decoder->decode( $aref );
    is $model->size, 4, 'bnode collision';

    # errors
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    decode_aref( {
            _id => 'isbn:123', 
            rdfs_seeAlso => [
                'isbn:456 x',  # looks like an IRI to aREF but rejected by Trine
                'isbn:789'
            ]
        }, 
        callback => $model,
    );
    ok $warning, "bad IRI";
    is $model->size, 5, 'ignored illformed URI';

    my $encoder = RDF::aREF::Encoder->new(ns => '20140910');
    my $aref = { };
    $encoder->add_triple( $aref, statement( 
        iri('http://example.org/'),
        iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
        iri('http://xmlns.com/foaf/0.1/Agent'),
    ) );
    $encoder->add_triple( $aref, statement( 
        iri('http://example.org/'),
        iri('http://xmlns.com/foaf/0.1/name'),
        literal('Anne','de'),
    ) );

    is_deeply $aref, {
        'http://example.org/' => {
            a => 'foaf_Agent',
            foaf_name => 'Anne@de'
        }
    }, 'encoder add_triple';

    # TODO encode_aref $model / $iterator
}

done_testing;
