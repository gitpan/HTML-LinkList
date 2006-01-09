# testing dir_tree
use strict;
use Test::More tests => 6;

use HTML::LinkList qw(dir_tree);

my @links = qw(
/foo/bar/baz.html
/fooish.html
/bringle/
/tray/nav.html
/tray/tea_tray.html
);

my %labels = (
'/tray/nav.html' => 'Navigation',
'/foo/bar/baz.html' => 'Bazzy',
);

my $link_html = '';
# default, no current
$link_html = dir_tree(labels=>\%labels,
    paths=>\@links);
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/">Home</a>
<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "(1) default; values match");

# start_depth
$link_html = dir_tree(labels=>\%labels,
    paths=>\@links,
    start_depth=>2);
ok($link_html, "(2) start_depth=2; links HTML");

$ok_str = '<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "(2) start_depth=2; values match");

# start_depth and end_depth
$link_html = dir_tree(labels=>\%labels,
    paths=>\@links,
    start_depth=>2,
    end_depth=>3);
ok($link_html, "(3) start_depth=2, end_depth=3; links HTML");

$ok_str = '<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "(3) start_depth=2, end_depth=3; values match");

