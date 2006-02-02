# testing nav_tree
use strict;
use Test::More tests => 12;

use HTML::LinkList qw(nav_tree);

#=====================================================================

sub make_test_html {
    my %args = (
	test_name=>'nav_tree',
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
<title>$args{test_name}</title>
</head>
<body>
<h1>$args{test_name}</h1>
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
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/wibble.html');
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a></li>
<li><em>Wibble</em></li>
<li><a href="/foo/boo/">Boo</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
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
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/');
ok($link_html, "(2) current-is-dir; links HTML");

$ok_str = '<ul><li><em>Foo</em>
<ul><li><a href="/foo/bar/">Bar</a></li>
<li><a href="/foo/wibble.html">Wibble</a></li>
<li><a href="/foo/boo/">Boo</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
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
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/bar/baz.html');
ok($link_html, "(3) lower level; links HTML");

$ok_str = '<ul><li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><em>Bazzy</em></li>
<li><a href="/foo/bar/biz.html">Biz</a></li>
</ul></li>
<li><a href="/foo/wibble.html">Wibble</a></li>
<li><a href="/foo/boo/">Boo</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
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
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/foo/bar/');
ok($link_html, "(4) mid level; links HTML");

$ok_str = '<ul><li><a href="/foo/">Foo</a>
<ul><li><em>Bar</em>
<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
<li><a href="/foo/bar/biz.html">Biz</a></li>
</ul></li>
<li><a href="/foo/wibble.html">Wibble</a></li>
<li><a href="/foo/boo/">Boo</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a></li>
</ul>';
is($link_html, $ok_str, "(4) mid level; values match");

# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

#
# more complicated links
#
@links = qw(
/
/about/about_cti.html
/about/contact_us.html
/about/people_technology.html
/products/
/products/operations_control/
/products/operations_control/Airpac.html
/products/operations_control/Airpac_Overview.pdf
/products/crewing/
/products/crewing/Crew_Rostering.pdf
/products/maintenance/
/solutions/
/services/
/news/press_release.html
);

%labels = (
'/' => 'Home',
'/index.html' => 'Home',
'/about/about_cti.html' => 'About CTI',
'/about/people_technology.html' => 'People and Technology',
);

$test_count++;
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    current_url=>'/products/');
ok($link_html, "(5) more links; links HTML");

$ok_str = '<ul><li><a href="/about/">About</a></li>
<li><em>Products</em>
<ul><li><a href="/products/operations_control/">Operations Control</a></li>
<li><a href="/products/crewing/">Crewing</a></li>
<li><a href="/products/maintenance/">Maintenance</a></li>
</ul></li>
<li><a href="/solutions/">Solutions</a></li>
<li><a href="/services/">Services</a></li>
<li><a href="/news/">News</a></li>
</ul>';
is($link_html, $ok_str, "(5) more links; values match");

# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}

# starting at level 2
$test_count++;
$link_html = nav_tree(labels=>\%labels,
    paths=>\@links,
    start_depth=>2,
    current_url=>'/products/');
ok($link_html, "(5) start_depth=2; links HTML");

$ok_str = '<ul><li><a href="/products/operations_control/">Operations Control</a></li>
<li><a href="/products/crewing/">Crewing</a></li>
<li><a href="/products/maintenance/">Maintenance</a></li>
</ul>';
is($link_html, $ok_str, "(5) start_depth=2; values match");

# make an example html file of the difference
if ($link_html ne $ok_str)
{
    make_test_html(link_html=>$link_html,
	ok_str=>$ok_str,
	test_count=>$test_count);
}
