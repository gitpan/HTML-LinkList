# testing dir_tree
use strict;
use Test::More tests => 6;

use HTML::LinkList qw(nav_tree);

my @links = qw(
/foo/bar/baz.html
/foo/bar/biz.html
/foo/wibble.html
/fooish.html
/bringle/
/bringle/brangle.html
/tray/nav.html
/tray/tea_tray.html
);

my %labels = (
'/tray/nav.html' => 'Navigation',
'/foo/bar/baz.html' => 'Bazzy',
);

my $link_html = '';
# default
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/wibble.html');
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a></li>
<li><em>Wibble</em></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
</ul>';

is($link_html, $ok_str, "(1) default; values match");

# current is dir
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/');
ok($link_html, "(2) current-is-dir; links HTML");

$ok_str = '<ul><li><em>Foo</em>
<ul><li><a href="/foo/bar/">Bar</a></li>
<li><a href="/foo/wibble.html">Wibble</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
</ul>';
is($link_html, $ok_str, "(2) current-is_dir; values match");

# lower level
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/bar/baz.html');
ok($link_html, "(3) lower level; links HTML");

$ok_str = '<ul><li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><em>Bazzy</em></li>
<li><a href="/foo/bar/biz.html">Biz</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
</ul>';
is($link_html, $ok_str, "(3) lower level; values match");

