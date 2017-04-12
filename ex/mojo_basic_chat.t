use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

require './ex/mojo_basic_chat.pl';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);

$t->websocket_ok('/channel')
  ->send_ok('is this thing on?')
  ->message_ok
  ->message_is('is this thing on?')
  ->finish_ok;

done_testing;
