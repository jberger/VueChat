use Mojolicious::Lite;
use Mojo::Pg;
use experimental 'signatures';

helper pg => sub { state $pg = Mojo::Pg->new('postgresql://test:test@/test') };

get '/' => 'chat';

websocket '/channel' => sub ($c) {
  $c->inactivity_timeout(3600);

  # Forward messages from the browser to PostgreSQL
  $c->on(message => sub ($c, $message) {
    $c->pg->pubsub->notify(mojochat => $message);
  });

  # Forward messages from PostgreSQL to the browser
  my $cb = sub ($pubsub, $message) { $c->send($message) };
  $c->pg->pubsub->listen(mojochat => $cb);

  # Remove callback from PG listeners on close
  $c->on(finish => sub ($c, @) {
    $c->pg->pubsub->unlisten(mojochat => $cb);
  });
};

app->start;
__DATA__

@@ chat.html.ep
<!-- reveal begin chat -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/vue/2.0.5/vue.js"></script>
<div id="chat">
  Username: <input v-model="username"><br>
  Send: <input @keydown.enter="send" v-model="current"><br>
  <div id="log">
    <p v-for="m in messages">{{m.username}}: {{m.message}}</p>
  </div>
</div>
<script>
var ws = new WebSocket('<%= url_for('channel')->to_abs %>');
var vm = new Vue({
  el: '#chat',
  data: {
    current: '',
    messages: [],
    username: '',
  },
  methods: {
    send: function() {
      var data = {username: this.username, message: this.current};
      ws.send(JSON.stringify(data));
      this.current = '';
    },
  },
});
ws.onmessage = function (e) { vm.messages.push(JSON.parse(e.data)) };
</script>
