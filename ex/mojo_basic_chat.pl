use Mojolicious::Lite;
use experimental 'signatures';

get '/' => 'chat';

my %subscribers;

# reveal begin websocket
websocket '/channel' => sub ($c) {
  $c->inactivity_timeout(3600);

  # Add controller to hash of subscribers
  $subscribers{$c} = $c;

  # Forward messages from the browser to all subscribers
  $c->on(message => sub ($c, $message) {
    $_->send($message) for values %subscribers;
  });

  # Remove controller from subscribers on close
  $c->on(finish => sub ($c, @) { delete $subscribers{$c} });
};
# reveal end websocket

app->start;
__DATA__

@@ chat.html.ep
<!-- reveal begin chat -->
<form onsubmit="sendChat(this.children[0]); return false"><input></form>
<div id="log"></div>
<script>
var ws  = new WebSocket('<%= url_for('channel')->to_abs %>');
ws.onmessage = function (e) {
  document.getElementById('log').innerHTML += '<p>' + e.data + '</p>';
};
function sendChat(input) { ws.send(input.value); input.value = '' }
</script>
