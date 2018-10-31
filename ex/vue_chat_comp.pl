use Mojolicious::Lite -signatures;
use Mojo::Pg;

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
<script src="https://cdnjs.cloudflare.com/ajax/libs/vue/2.0.5/vue.js"></script>
<!-- reveal begin template -->
<div id="chat">
  Username: <input v-model="username"><br>
  Send: <chat-entry @message="send"></chat-entry><br>
  <div id="log">
    <chat-msg v-for="m in messages" :username="m.username" :message="m.message"></chat-msg>
  </div>
</div>
<!-- reveal end template -->
<script>
// reveal begin entry
Vue.component('chat-entry', {
  template: '<input @keydown.enter="message" v-model="current">',
  data: function() { return { current: '' } },
  methods: {
    message: function() {
      this.$emit('message', this.current);
      this.current = '';
    },
  },
});
// reveal end entry
// reveal begin message
Vue.component('chat-msg', {
  template: '<p>{{username}}: {{message}}</p>',
  props: {
    username: { type: String, required: true },
    message:  { type: String, default: '' },
  },
});
// reveal end message
// reveal begin app
var vm = new Vue({
  el: '#chat',
  data: { messages: [], username: '', ws: null },
  methods: {
    connect: function() {
      var self = this;
      self.ws = new WebSocket('<%= url_for('channel')->to_abs %>');
      self.ws.onmessage = function (e) { self.messages.push(JSON.parse(e.data)) };
    },
    send: function(message) {
      var data = {username: this.username, message: message};
      this.ws.send(JSON.stringify(data));
    },
  },
  created: function() { this.connect() },
});
// reveal end app
</script>
