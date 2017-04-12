use Mojolicious::Lite;

plugin 'RevealJS';

any '/' => { template => 'presentation', layout => 'revealjs' };

app->start;

