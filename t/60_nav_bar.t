# testing nav_bar
use strict;
use Test::More tests => 10;

use HTML::LinkList qw(nav_bar);

#=====================================================================

sub make_test_html {
    my %args = (
	test_name=>'nav_bar',
	test_count=>0,
	link_html=>'',
	ok_str=>'',
	@_
    );

    if ($args{link_html} ne $args{ok_str})
    {
	my $test_file = "${args{test_name}}${args{test_count}}.html";
	open(HTML, ">", $test_file)
	    or die "could not open $test_file for writing";
	print HTML<<EOT;
	<html>
	    <head>
	    <title>$args{test_name} $args{test_count}</title>
	    </head>
	    <body>
	    <h1>$args{test_name} $args{test_count}</h1>
	    <p>Got:
	    $args{link_html}
	    <p>Wanted:
	    $args{ok_str}
	    </body>
	    </html>
EOT
	close(HTML);
    }
}

#=====================================================================

my @links = qw(
/foo/bar/baz.html
/foo/bar/biz.html
/foo/wibble.html
/foo/boo/thren.html
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

my $test_count = 0;
my $link_html = '';
$test_count++;
# default
$link_html = nav_bar(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/wibble.html');
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><strong><a href="/foo/">Foo</a></strong> :
<a href="/fooish.html">Fooish</a> :
<a href="/bringle/">Bringle</a> :
<a href="/tray/">Tray</a></li>
<li>[Foo] :
<a href="/foo/bar/">Bar</a> :
<em>Wibble</em> :
<a href="/foo/boo/">Boo</a></li>
</ul>';

is($link_html, $ok_str, "(1) default; values match");

# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

# current is dir
$test_count++;
$link_html = nav_bar(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/');
ok($link_html, "(2) current-is-dir; links HTML");

$ok_str = '<ul><li><em>Foo</em> :
<a href="/fooish.html">Fooish</a> :
<a href="/bringle/">Bringle</a> :
<a href="/tray/">Tray</a></li>
<li>[<em>Foo</em>] :
<a href="/foo/bar/">Bar</a> :
<a href="/foo/wibble.html">Wibble</a> :
<a href="/foo/boo/">Boo</a></li>
</ul>';
is($link_html, $ok_str, "(2) current-is_dir; values match");
# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

# lower level
$test_count++;
$link_html = nav_bar(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/bar/baz.html');
ok($link_html, "(3) lower level; links HTML");

$ok_str = '<ul><li><strong><a href="/foo/">Foo</a></strong> :
<a href="/fooish.html">Fooish</a> :
<a href="/bringle/">Bringle</a> :
<a href="/tray/">Tray</a></li>
<li>[Foo] :
<strong><a href="/foo/bar/">Bar</a></strong> :
<a href="/foo/wibble.html">Wibble</a> :
<a href="/foo/boo/">Boo</a></li>
<li>[Foo :
Bar] :
<em>Bazzy</em> :
<a href="/foo/bar/biz.html">Biz</a></li>
</ul>';
is($link_html, $ok_str, "(3) lower level; values match");
# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

# mid-level index
$test_count++;
$link_html = nav_bar(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/bar/');
ok($link_html, "(4) mid level; links HTML");

$ok_str = '<ul><li><strong><a href="/foo/">Foo</a></strong> :
<a href="/fooish.html">Fooish</a> :
<a href="/bringle/">Bringle</a> :
<a href="/tray/">Tray</a></li>
<li>[Foo] :
<em>Bar</em> :
<a href="/foo/wibble.html">Wibble</a> :
<a href="/foo/boo/">Boo</a></li>
<li>[Foo :
<em>Bar</em>] :
<a href="/foo/bar/baz.html">Bazzy</a> :
<a href="/foo/bar/biz.html">Biz</a></li>
</ul>';
is($link_html, $ok_str, "(4) mid level; values match");
# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

# very top level
$test_count++;
$link_html = nav_bar(labels=>\%labels,
    paths=>\@links,
    current_url=>'/');
ok($link_html, "(5) very-top-level; links HTML");

$ok_str = '<ul><li><a href="/foo/">Foo</a> :
<a href="/fooish.html">Fooish</a> :
<a href="/bringle/">Bringle</a> :
<a href="/tray/">Tray</a></li>
</ul>';
is($link_html, $ok_str, "(5) very-top-level; values match");
# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

