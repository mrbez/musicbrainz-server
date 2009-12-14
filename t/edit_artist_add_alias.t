#!/usr/bin/perl
use strict;
use Test::More;
BEGIN { use_ok 'MusicBrainz::Server::Edit::Artist::AddAlias' }

use MusicBrainz::Server::Constants qw( $EDIT_ARTIST_ADD_ALIAS );
use MusicBrainz::Server::Test qw( accept_edit reject_edit );

my $c = MusicBrainz::Server::Test->create_test_context();
MusicBrainz::Server::Test->prepare_test_database($c, '+artistalias');
MusicBrainz::Server::Test->prepare_raw_test_database($c);

my $edit = _create_edit();
isa_ok($edit, 'MusicBrainz::Server::Edit::Artist::AddAlias');
ok(defined $edit->alias_id);
ok($edit->alias_id > 0);

my ($edits) = $c->model('Edit')->find({ artist => 1 }, 10, 0);
is(@$edits, 1);
is($edits->[0]->id, $edit->id);

$c->model('Edit')->load_all($edit);
is($edit->display_data->{artist}->id, 1);
is($edit->display_data->{alias}, 'Another alias');

my $artist = $c->model('Artist')->get_by_id(1);
is($artist->edits_pending, 1);

my $alias_set = $c->model('Artist')->alias->find_by_entity_id(1);
is(@$alias_set, 3);

reject_edit($c, $edit);

$alias_set = $c->model('Artist')->alias->find_by_entity_id(1);
is(@$alias_set, 2);

my $artist = $c->model('Artist')->get_by_id(1);
is($artist->edits_pending, 0);

my $edit = _create_edit();
accept_edit($c, $edit);

$artist = $c->model('Artist')->get_by_id(1);
is($artist->edits_pending, 0);

$alias_set = $c->model('Artist')->alias->find_by_entity_id(1);
is(@$alias_set, 3);

done_testing;

sub _create_edit {
    return $c->model('Edit')->create(
        edit_type => $EDIT_ARTIST_ADD_ALIAS,
        editor_id => 1,
        artist_id => 1,
        alias => 'Another alias',
    );
}
