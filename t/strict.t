use strict;
use warnings;
use Test::More;
use RDF::aREF qw(decode_aref);

my ($error, $rdf);
my %handler = (
    error    => sub { $error = shift },
    callback => sub { $rdf = shift },
);

decode_aref { '<x:subj>' => { a => undef } }, %handler;
decode_aref { '' => { a => 'foaf:Person' } }, %handler, null => '';
ok !$error, 'not strict by default';

decode_aref { '<x:subj>' => { a => '' } }, %handler, null => '';
ok !$rdf, 'empty string as null';

decode_aref { '<x:subj>' => { a => undef } }, %handler, strict => 1;
ok $error, 'strict makes undef error';

$error = 0;
decode_aref { '' => { a => 'foaf:Person' } }, %handler, strict => 1, null => '';
ok $error, 'strict makes null value error';

$error = 0;
decode_aref { '<x:subj>' => { a => '' } }, %handler, strict => 1;
ok !$error && $rdf, 'empty string not null by default';

$error = 0;
decode_aref { '' => { a => 'foaf:Person' } }, %handler, strict => 1;
ok $error, 'empty string not null by default';

done_testing;
