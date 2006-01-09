# testing link_tree
use strict;
use Test::More tests => 2;

use HTML::LinkList qw(link_tree);

my @links = (
'/foo/bar/baz.html',
'/fooish.html',
'/bringle/',
['/tray/nav.html',
'/tray/tea_tray.html'],
);

my %labels = (
'/tray/nav.html' => 'Navigation',
'/foo/bar/baz.html' => 'Bazzy',
);

my $link_html = '';
# default, no current
$link_html = link_tree(labels=>\%labels,
    link_tree=>\@links);
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "(1) default; values match");

