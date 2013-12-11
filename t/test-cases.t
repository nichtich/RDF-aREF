use strict;
use Test::More;
use File::Find;

BEGIN {
    eval { 
        require RDF::Trine::Model; 
        require RDF::Trine::Serializer::NTriples::Canonical;
        require JSON;
        1; 
    } or do {
        plan skip_all => "RDF::Trine or JSON not installed";
    };
}

use RDF::aREF qw(aref_to_trine_statement);

find( \&check_example, 't/test-cases' );

sub slurp { local (@ARGV, $/) = @_; <>; }

sub check_example {
    return if $_ !~ /(.+)\.json$/;
    my $name = $_;
    my $aref = JSON::from_json(slurp("$1.json"));
    my $nt   = slurp("$1.nt");
    my $err  = -e "$1.err" ? slurp("$1.err") : undef;
    my @errors;

    my $model = RDF::Trine::Model->new;
    # TODO: use iterator instead
    # a (->next returns a trine-statement)
    $model->begin_bulk_ops;
    RDF::aREF::Decoder->new(
        callback => sub {
            $model->add_statement( aref_to_trine_statement( @_ ) ) 
        }, 
        error  => sub { push @errors, $_[0] },
    )->decode( $aref );
    # decode_as_iterator();
    # decode_as_iterator( as => 'trine_statement' ); # if (exists aref_to_$foo) ...
    # decode_as_iterator( as => sub { aref_to_trine_statement() } );
    $model->end_bulk_ops;
    my $got = RDF::Trine::Serializer::NTriples::Canonical->new(
        onfail => 'truncate',
    )->serialize_model_to_string($model);
    $got =~ s/\r//g;

    is $got, $nt, $name;
    if (@errors) {
        is join("\n", sort @errors)."\n", $err;
    }
}

done_testing;
