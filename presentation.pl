use Mojolicious::Lite;

app->static->paths(['.']);

plugin 'RevealJS';

any '/' => { template => 'presentation', layout => 'revealjs' };

app->start;

