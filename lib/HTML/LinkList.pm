package HTML::LinkList;
use strict;
use warnings;

=head1 NAME

HTML::LinkList - Create a 'smart' list of HTML links.

=head1 VERSION

This describes version B<0.07> of HTML::LinkList.

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use HTML::LinkList qw(link_list);

    # default formatting
    my $html_links = link_list(current_url=>$url,
			       urls=>\@links_in_order,
			       labels=>\%labels,
			       descriptions=>\%desc);

    # paragraph with ' :: ' separators
    my $html_links = link_list(current_url=>$url,
	urls=>\@links_in_order,
	labels=>\%labels,
	descriptions=>\%desc,
	links_head=>'<p>',
	links_foot=>'</p>',
	pre_item=>'',
	post_item=>''
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>" :: ");

=head1 DESCRIPTION

This module contains a number of functions for taking sets of URLs and
labels and creating suitably formatted HTML.  These links are "smart"
because, if given the url of the current page, if any of the links in
the list equal it, that item in the list will be formatted as a special
label, not as a link; this is a Good Thing, since the user would be
confused by clicking on a link back to the current page.

While many website systems have plugins for "smart" navbars, they are
specialized for that system only, and can't be reused elsewhere, forcing
people to reinvent the wheel. I hereby present one wheel, free to be
reused by anybody; just the simple functions, a backend, which can be
plugged into whatever system you want.

The default format for the HTML is to make an unordered list, but there
are many options, enabling one to have a flatter layout with any
separators you desire.

The "link_list" function uses a simple list of links -- good for a
simple navbar.

The "link_tree" function takes a set of nested links and makes the HTML
for them -- good for making a table of contents, or a more complicated
navbar.

The "full_tree" function takes a list of paths and makes a full tree of
all the pages and index-pages in those paths -- good for making a site
map.

The "breadcrumb_trail" function takes a url and makes a "breadcrumb trail"
from it.

The "nav_tree" function creates a set of nested links to be
used as a multi-level navbar; one can give it a list of paths
(as for full_tree) and it will only show the links related
to the current URL.

The "nav_bar" function creates a set of links designed to be used as an
"across the top" navbar.  One can give it a list of paths (as for
full_tree) and it will only show the links related to the current URL.

=cut

=head1 FUNCTIONS

To export a function, add it to the 'use' call.

    use HTML::LinkList qw(link_list);

To export all functions do:

    use HTML::LinkList ':all';

=cut

require Exporter;

our @ISA = qw(Exporter);


# Items which are exportable.
#
# This allows declaration	use HTML::LinkList ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	link_list
	link_tree
	full_tree
	breadcrumb_trail
	nav_tree
	nav_bar
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT = qw(
	
);

=head2 link_list

    $links = link_list(
	current_url=>$url,
	urls=>\@links_in_order,
	labels=>\%labels,
	descriptions=>\%desc,
	links_head=>'<ul>',
	links_foot=>'</ul>',
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>"\n");

Generates a simple list of links, from list of urls
(and optional labels) taking into account of the "current" URL.

This provides a large number of options to customize the appearance
of the list.  The default setup is for a simple UL list, but setting
the options can enable you to make it something other than a list
altogether, or add in CSS styles or classes to make it look just
like you want.

Options:

=over

=item current_url

The link to the current page.  If one of the links equals this,
then that is deemed to be the "active" link and is just displayed
as a label rather than a link.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=item labels

A hash whose keys are links and whose values are labels.
These are the labels for the links; if no label
is given, then the last part of the link is used
for the label.

=item urls

The urls in the order you want them displayed.  If this list
is empty, then nothing will be generated.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=item links_head

String to begin the list with.

=item links_foot

String to end the list with.

=item pre_item

String to prepend to each item.

=item post_item

String to append to each item.

=item pre_active_item

An additional string to put in front of each "active" item, after pre_item.
The "active" item is the link which matches 'current_url'.

=item post_active_item

An additional string to append to each active item, before post_item.

=item item_sep

String to put between items.

=back

=cut
sub link_list {
    my %args = (
		current_url=>'',
		prefix_url=>'',
		labels=>undef,
		urls=>undef,
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		@_
	       );

    my @link_order = @{$args{urls}};
    if (!defined $args{urls}
	or !@{$args{urls}})
    {
	return '';
    }
    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my %current_parents = extract_current_parents(current_url=>$args{current_url});
    my @items = ();
    foreach my $link (@link_order)
    {
	my $label = (exists $args{labels}->{$link}
	    ? $args{labels}->{$link} : '');
	my $item = make_item(%args,
	    current_parents=>\%current_parents,
	    this_link=>$link,
	    this_label=>$label);
	push @items, $item;
    }
    my $list = join($args{item_sep}, @items);
    return ($list
	? join('', $args{links_head}, $list, $args{links_foot})
	: '');
} # link_list

=head2 link_tree

    $links = link_tree(
	current_url=>$url,
	link_tree=>\@list_of_lists,
	labels=>\%labels,
	descriptions=>\%desc,
	links_head=>'<ul>',
	links_foot=>'</ul>',
	subtree_head=>'<ul>',
	subtree_foot=>'</ul>',
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>"\n",
	tree_sep=>"\n");

Generates nested lists of links from a list of lists of links.
This is useful for things such as table-of-contents or
site maps.

By default, this will return UL lists, but this is highly
configurable.

Options:

=over

=item current_url

The link to the current page.  If one of the links equals this,
then that is deemed to be the "active" link and is just displayed
as a label rather than a link.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=item labels

A hash whose keys are links and whose values are labels.
These are the labels for the links; if no label
is given, then the last part of the link is used
for the label.

=item link_tree

A list of lists of urls, in the order you want them displayed.
If a url is not in this list, it will not be displayed.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=item links_head

The string to prepend the top-level tree with.
(default: <ul>)

=item links_foot

The string to append to the top-level tree.
(default: </ul>)

=item subtree_head

The string to prepend to lower-level trees.
(default: <ul>)

=item subtree_foot

The string to append to lower-level trees.
(default: </ul>)

=item pre_item

String to prepend to each item.
(default: <li>)

=item post_item

String to append to each item.
(default: </li>)

=item pre_active_item

An additional string to put in front of each "active" item, after pre_item.
The "active" item is the link which matches 'current_url'.
(default: <em>)

=item post_active_item

An additional string to append to each active item, before post_item.
(default: </em>)

=item pre_current_parent

An additional string to put in front of a link which is a parent
of the 'current_url' link, after pre_item.

=item post_current_parent

An additional string to append to a link which is a parent
of the 'current_url' link, before post_item.

=item item_sep

The string to separate each item.

=item tree_sep

The string to separate each tree.

=back

=cut
sub link_tree {
    my %args = (
		current_url=>'',
		prefix_url=>'',
		links=>undef,
		link_tree=>undef,
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my %current_parents = extract_current_parents(current_url=>$args{current_url});

    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    if (defined $args{link_tree}
	and @{$args{link_tree}})
    {
	my @link_tree = @{$args{link_tree}};
	my $list = traverse_lol(\@link_tree,
				%args,
				current_parents=>\%current_parents);
	return join('', $args{links_head}, $list, $args{links_foot})
	    if $list;
    }
    return '';
} # link_tree

=head2 full_tree

    $links = full_tree(
	paths=>\@list_of_paths,
	labels=>\%labels,
	descriptions=>\%desc,
	hide=>$hide_regex,
	nohide=>$nohide_regex,
	start_depth=>0,
	end_depth=>0,
	preserve_order=>0,
	...
	);

Given a set of paths this will generate a tree of links in the style of
I<link_tree>.   This will figure out all the intermediate paths and construct
the nested structure for you, clustering parents and children together.

The formatting options are as for L</link_tree>.

Options:

=over

=item paths

A reference to a list of paths: that is, URLs relative to the top
of the site.

For example, if the full URL is http://www.example.com/foo.html
then the path is /foo.html

If the full URL is http://www.example.com/~frednurk/foo.html
then the path is /foo.html

This does not require that every possible path be given; all the intermediate
paths will be figured out from the list.

=item labels

Hash containing replacement labels for one or more paths.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the paths.

=item prefix_url

A prefix to prepend to all the links. (default: empty string)

=item hide

If the path matches this string, don't include it in the tree.

=item nohide

If the path matches this string, it will be included even if it matches
the 'hide' string.

=item preserve_order

Preserve the ordering of the paths in the input list of paths;
otherwise the links will be sorted alphabetically.  Note that if
preserve_order is true, the structure is at the whims of the order
of the original list of paths, and so could end up odd-looking.
(default: false)

=item start_depth

Start your tree at this depth.  Zero is the root, level 1 is the
files/sub-folders in the root, and so on.
(default: 0)

=item end_depth

End your tree at this depth.  If zero, then go all the way.

=item last_subtree_head

The string to prepend to the last lower-level tree.
Only used if end_depth is not zero.

=item last_subtree_foot

The string to append to the last lower-level tree.
Only used if end_depth is not zero.

=back

=cut
sub full_tree {
    my %args = (
		paths=>undef,
		current_url=>'',
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		hide=>'',
		nohide=>'',
		preserve_order=>0,
		labels=>{},
		start_depth=>0,
		end_depth=>0,
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my %current_parents = extract_current_parents(current_url=>$args{current_url});

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }
    my @path_list = extract_all_paths(paths=>$args{paths},
	preserve_order=>$args{preserve_order});
    @path_list = filter_out_paths(%args, paths=>\@path_list);
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  depth=>0);
    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    my $list = traverse_lol(\@list_of_lists,
			    %args,
			    current_parents=>\%current_parents);
    if ($list)
    {
	return join('', $args{links_head}, $list, $args{links_foot});
    }
    else
    {
	return '';
    }
} # full_tree

=head2 breadcrumb_trail

    $links = breadcrumb_trail(
		current_url=>$url,
		labels=>\%labels,
		descriptions=>\%desc,
		links_head=>'<p>',
		links_foot=>"\n</p>",
		subtree_head=>'',
		subtree_foot=>"\n",
		pre_item=>'',
		post_item=>'',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		item_sep=>"\n",
		tree_sep=>' &gt; ',
	...
	);

Given the current url, make a breadcrumb trail from it.
By default, this is laid out with '>' separators, but it can
be set up to give a nested set of UL lists (as for L</full_tree>).

The formatting options are as for L</link_tree>.

Options:

=over

=item current_url

The current url to be made into a breadcrumb-trail.

=item labels

Hash containing replacement labels for one or more URLS.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=back

=cut
sub breadcrumb_trail {
    my %args = (
		current_url=>'',
		links_head=>'<p>',
		links_foot=>"\n</p>",
		subtree_head=>'',
		subtree_foot=>'',
		last_subtree_head=>'{',
		last_subtree_foot=>'}',
		pre_item=>'',
		post_item=>'',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>' &gt; ',
		hide=>'',
		nohide=>'',
		labels=>{},
		paths=>[],
		start_depth=>0,
		end_depth=>undef,
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }

    # make a list of paths consisting only of the current_url
    my @paths = ($args{current_url});
    my @path_list = extract_all_paths(paths=>\@paths);
    @path_list = filter_out_paths(%args, paths=>\@path_list);
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  depth=>0);
    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    my $list = traverse_lol(\@list_of_lists, %args);
    if ($list)
    {
	return join('', $args{links_head}, $list, $args{links_foot});
    }
    else
    {
	return '';
    }
} # breadcrumb_trail

=head2 nav_tree

    $links = nav_tree(
	paths=>\@list_of_paths,
	labels=>\%labels,
	current_url=>$url,
	hide=>$hide_regex,
	nohide=>$nohide_regex,
	preserve_order=>1,
	descriptions=>\%desc,
	...
	);

This takes a list of links, and the current URL, and makes a nested navigation
tree, consisting of (a) the top-level links (b) the links leading to the
current URL (c) the links on the same level as the current URL,
(d) the related links just above this level, depending on whether
this is an index-page or a content page.

Optionally one can hide links which match match the 'hide' option.

The formatting options are as for L</link_tree>, with some additions.

Options:

=over

=item paths

A reference to a list of paths: that is, URLs relative to the top
of the site.

For example, if the full URL is http://www.example.com/foo.html
then the path is /foo.html

This does not require that every possible path be given; all the intermediate
paths will be figured out from the list.

=item labels

Hash containing replacement labels for one or more paths.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the paths.

=item hide

If a path matches this string, don't include it in the tree.

=item nohide

If the path matches this string, it will be included even if it matches
the 'hide' string.

=item preserve_order

Preserve the ordering of the paths in the input list of paths;
otherwise the links will be sorted alphabetically.
(default: true)

=item last_subtree_head

The string to prepend to the last lower-level tree.
Only used if end_depth is not zero.

=item last_subtree_foot

The string to append to the last lower-level tree.
Only used if end_depth is not zero.

=back

=cut
sub nav_tree {
    my %args = (
		paths=>undef,
		current_url=>'',
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'',
		post_current_parent=>'',
		item_sep=>"\n",
		tree_sep=>"\n",
		hide=>'',
		nohide=>'',
		preserve_order=>1,
		labels=>{},
		start_depth=>1,
		end_depth=>undef,
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my $current_is_index = ($args{current_url} =~ m#/$#);
    my %current_parents = extract_current_parents(current_url=>$args{current_url});

    # set the end depth if isn't already set
    # if this is an index-page, then make the depth its depth + 1
    # if this is a content-page, make the depth its depth
    my $current_url_depth = path_depth($args{current_url});
    $args{end_depth} = ($current_is_index
	? $current_url_depth + 1 : $current_url_depth)
	    if (!defined $args{end_depth});

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }
    my @path_list = extract_all_paths(paths=>$args{paths},
	preserve_order=>$args{preserve_order});
    @path_list = filter_out_paths(%args,
				  paths=>\@path_list,
				  do_navbar=>1);
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  do_navbar=>1,
				  depth=>0);
    $args{tree_depth} = 0;

    my $list = traverse_lol(\@list_of_lists,
			    %args,
			    current_parents=>\%current_parents);
    if ($list)
    {
	return join('', $args{links_head}, $list, $args{links_foot});
    }
    else
    {
	return '';
    }
} # nav_tree

=head2 nav_bar

    $links = nav_bar(
	paths=>\@list_of_paths,
	labels=>\%labels,
	current_url=>$url,
	hide=>$hide_regex,
	nohide=>$nohide_regex,
	preserve_order=>1,
	descriptions=>\%desc,
	...
	);

This takes a list of links, and the current URL, and makes a multi-level
navigation bar related to the current_url, where links at the same "level"
in the hierarchy are grouped together, and then links on the next level,
and so on.  It's intended for an across-the-top navbar; if you have a very
deep hierarchy it may be better to use L</nav_tree>.

Optionally one can hide links which match match the 'hide' option.

The formatting options are as for L</link_tree>, with some additions.

Options:

=over

=item paths

A reference to a list of paths: that is, URLs relative to the top
of the site.

For example, if the full URL is http://www.example.com/foo.html
then the path is /foo.html

This does not require that every possible path be given; all the intermediate
paths will be figured out from the list.

=item labels

Hash containing replacement labels for one or more paths.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the paths.

=item hide

If a path matches this string, don't include it in the tree.

=item nohide

If the path matches this string, it will be included even if it matches
the 'hide' string.

=item preserve_order

Preserve the ordering of the paths in the input list of paths;
otherwise the links will be sorted alphabetically.
(default: true)

=item pre_level

String to put in front of a level group.

=item post_level

String to append to a level group.

=item level_sep

String to separate the levels.

=item pre_level_parent

String to put in front of the link which is the parent of this level.

=item post_level_parent

String to append to the link which is the parent of this level.

=back

=cut
sub nav_bar {
    my %args = (
		paths=>undef,
		current_url=>'',
		links_head=>'<ul>',
		links_foot=>"\n</ul>",
		pre_level=>'<li>',
		post_level=>'</li>',
		pre_item=>'',
		post_item=>'',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'<strong>',
		post_current_parent=>'</strong>',
		pre_level_parent=>'[',
		post_level_parent=>']',
		item_sep=>" :\n",
		parent_item_sep=>" :\n",
		level_sep=>"\n",
		hide=>'',
		nohide=>'',
		preserve_order=>1,
		labels=>{},
		start_depth=>1,
		end_depth=>0,
		@_
	       );

    # correct the current_url
    $args{current_url} = make_canonical($args{current_url});
    my $current_is_index = ($args{current_url} =~ m#/$#);

    my %current_parents = extract_current_parents(current_url=>$args{current_url});

    # set the end depth
    # if this is an index-page, then make the depth its depth + 1
    # if this is a content-page, make the depth its depth
    my $current_url_depth = path_depth($args{current_url});
    $args{end_depth} = ($current_is_index
	? $current_url_depth + 1 : $current_url_depth);

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }
    my @path_list = extract_all_paths(paths=>$args{paths},
	preserve_order=>$args{preserve_order});
    @path_list = filter_out_paths(%args, paths=>\@path_list, do_navbar=>1);
    my @list_of_lists = build_levels(%args, paths=>\@path_list,
				  do_navbar=>1,
				  depth=>$args{start_depth});

    $args{tree_depth} = 0;
    my $list = traverse_levels(\@list_of_lists,
			       %args,
			       current_parents=>\%current_parents);
    return join('', $args{links_head}, $list, $args{links_foot});
} # nav_bar

=head1 Private Functions

These functions cannot be exported.

=head2 make_item

$item = make_item(
	this_label=>$label,
	this_link=>$link,
	current_url=>$url,
	current_parents=>\%current_parents,
	descriptions=>\%desc,
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	pre_current_parent=>'<em>',
	post_current_parent=>'</em>',
	item_sep=>"\n");
    );

Format a link item.

See L</link_list> for the formatting options.

=over

=item this_label

The label of the required link.  If there is no label,
this uses the base-name of the last part of the link,
capitalizing it and replacing underscores with spaces.

=item this_link

The URL of the required link.

=item current_url

The link to the current page.  If one of the links equals this,
then that is deemed to be the "active" link and is just displayed
as a label rather than a link.

=item current_parents

URLs of the parents of the current item.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the links (not the labels).

=item defer_post_item

Don't add the 'post_item' string if this is true.
(needed for nested lists)
(default: false)

=item no_link

Don't make a link for this, just a label.

=back

=cut
sub make_item {
    my %args = (
		this_link=>'',
		this_label=>'',
		current_url=>'',
		current_parents=>{},
		prefix_url=>'',
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'<em>',
		post_current_parent=>'</em>',
		defer_post_item=>0,
		no_link=>0,
		@_
	       );
    my $link = $args{this_link};
    my $prefix_url = $args{prefix_url};
    my $label = $args{this_label};

    if (!$label)
    {
	$label = $link if !$label;
	if ($link =~ /(\w+)\.\w+$/) # file
	{
	    $label = $1;
	}
	elsif ($link =~ /(\w+)\/?$/) # dir
	{
	    $label = $1;
	}
	else # give up
	{
	    $label = $link;
	    $label =~ s#/# :: #g;
	}
	
	# prettify
	$label =~ s#_# #g;
	$label =~ s/(\w+)/\u\L$1/g;
    }
    my $item = '';
    my $desc = '';
    if (exists $args{descriptions}->{$link}
	and defined $args{descriptions}->{$link}
	and $args{descriptions}->{$link})
    {
	$desc = ' ' . $args{descriptions}->{$link};
    }
    if (link_is_active(this_link=>$link,
	current_url=>$args{current_url}))
    {
	$item = join('', $args{pre_item},
		     $args{pre_active_item},
		     $label,
		     $desc,
		     $args{post_active_item});
    }
    elsif ($args{no_link})
    {
	$item = join('', $args{pre_item},
		     $label,
		     $desc);
    }
    elsif ($args{current_url}
	and exists $args{current_parents}->{$link}
	and $args{current_parents}->{$link})
    {
	$item = join('', $args{pre_item},
		     $args{pre_current_parent},
		     '<a href="', $prefix_url, $link, '">',
		     $label, '</a>',
		     $args{post_current_parent},
		     $desc);
    }
    else
    {
	$item = join('', $args{pre_item},
		     '<a href="', $prefix_url, $link, '">',
		     $label, '</a>',
		     $desc);
    }
    if (!$args{defer_post_item})
    {
	$item = join('', $item, $args{post_item});
    }
    return $item;
} # make_item

=head2 make_canonical

my $new_url = make_canonical($url);

Make a URL canonical; remove the 'index.*' and add on a needed
'/' -- this assumes that directory names never have a '.' in them.

=cut
sub make_canonical {
    my $url = shift;

    return $url if (!$url);
    if ($url =~ m#^(/)index\.\w+$#)
    {
	$url = $1;
    }
    elsif ($url =~ m#^(.*/)index\.\w+$#)
    {
	$url = $1;
    }
    elsif ($url =~ m#/\w+$#) # no dots; a directory
    {
	$url .= '/'; # add the slash
    }
    return $url;
} # make_canonical
 
=head2 get_index_path

my $new_url = get_index_path($url);

Get the "index" part of this path.  That is, if this path
is not for an index-page, then get the parent index-page
path for this path.
(Removes the trailing slash).

=cut
sub get_index_path {
    my $url = shift;

    return $url if (!$url);
    $url = make_canonical($url);
    if ($url =~ m#^(.*)/\w+\.\w+$#)
    {
	$url = $1;
    }
    elsif ($url ne '/')
    {
	$url =~ s#/$##;
    }
    return $url;
} # get_index_path

=head2 get_index_parent

my $new_url = get_index_parent($url);

Get the parent of the "index" part of this path.
(Removes the trailing slash).

=cut
sub get_index_parent {
    my $url = shift;

    return $url if (!$url);
    $url = get_index_path($url);
    if ($url =~ m#^(.*)/\w+$#)
    {
	$url = $1;
    }
    return $url;
} # get_index_parent
 
=head2 path_depth

my $depth = path_depth($url);

Calculate the "depth" of the given path.

=cut
sub path_depth {
    my $url = shift;

    return 0 if ($url eq '/'); # root is zero
    $url =~ s#/$##; # remove trailing /
    $url =~ s#^/##; # remove leading /
    my @url = split('/', $url);
    return scalar @url;
} # path_depth
 
=head2 link_is_active

    if (link_is_active(this_link=>$link, current_url=>$url))
    ...

Check if the given link is "active", that is, if it
matches the 'current_url'.

=cut
sub link_is_active {
    my %args = (
		this_link=>'',
		current_url=>'',
		@_
	       );
    my $link = make_canonical($args{this_link});
    my $current_url = $args{current_url};

    # if there is no current link, is not active.
    return 0 if (!$current_url);

    return 1 if ($link eq $current_url);
    return 0;

} # link_is_active

=head2 traverse_lol

$links = traverse_lol(\@list_of_lists,
    labels=>\%labels,
    tree_depth=>$depth
    ...
    );

Traverse the list of lists (of urls) to produce 
a nested collection of links.

This consumes the list_of_lists!

=cut
sub traverse_lol {
    my $lol_ref = shift;
    my %args = (
		current_url=>'',
		labels=>undef,
		prefix_url=>'',
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_current_parent=>'<em>',
		post_current_parent=>'</em>',
		item_sep=>"\n",
		@_
	       );

    my $tree_depth = $args{tree_depth};
    my @items = ();
    while (@{$lol_ref})
    {
	my $ll = shift @{$lol_ref};
	if (!ref $ll) # an item
	{
	    my $link = $ll;
	    my $label = (exists $args{labels}->{$link}
			 ? $args{labels}->{$link} : '');
	    my $item = make_item(this_link=>$link,
				 this_label=>$label,
				 defer_post_item=>1,
				 %args);

	    if (ref $lol_ref->[0]) # next one is a list
	    {
		my $ll = shift @{$lol_ref};
		$args{tree_depth}++; # no longer the first call
		my $sublist = traverse_lol($ll, %args);
		$item = join($args{tree_sep}, $item, $sublist);
	    }
	    $item = join('', $item, $args{post_item});
	    push @items, $item;
	}
	else # a reference to a list
	{
	    return traverse_lol($ll, %args);
	}
    }
    my $list = join($args{item_sep}, @items);
    return join('',
	($tree_depth > 0
	    ? (($args{end_depth} && $tree_depth == $args{end_depth} )
	    ? $args{last_subtree_head}
	    : $args{subtree_head})
	    : ''),
	$list,
	($tree_depth > 0
	    ? (($args{end_depth} && $tree_depth == $args{end_depth} )
	    ? $args{last_subtree_foot}
	    : $args{subtree_foot})
	    : ''));
} # traverse_lol

=head2 extract_all_paths

my @all_paths = extract_all_paths(paths=>\@paths,
    preserve_order=>0);

Extract all possible paths out of a list of paths.
Thus, if one has

/foo/bar/baz.html

then that would make

/
/foo/
/foo/bar/
/foo/bar/baz.html

If 'preserve_order' is true, this preserves the ordering of
the paths in the input list; otherwise the output paths
are sorted alphabetically.

=cut
sub extract_all_paths {
    my %args = (
	paths=>undef,
	preserve_order=>0,
	@_
    );
    
    my %paths = ();
    # keep track of the order of the paths in the list of paths
    my $order = 1;
    foreach my $path (@{$args{paths}})
    {
	my @path_split = split('/', $path);
	# first path as-is
	$paths{$path} = $order;
	pop @path_split;
	while (@path_split)
	{
	    # these paths are index-pages. should end in '/'
	    my $newpath = join('/', @path_split, '');
	    # give this path the same order-num as the full path
	    # but only if it hasn't already been added
	    $paths{$newpath} = $order if (!exists $paths{$newpath});
	    pop @path_split;
	}
	$order++ if ($args{preserve_order});
    }
    return sort {
	return $a cmp $b if ($paths{$a} == $paths{$b});
	return $paths{$a} <=> $paths{$b};
    } keys %paths;
} # extract_all_paths

=head2 extract_current_parents

my %current_parents = extract_current_parents(current_url=>$url);

Extract the "parent" paths of the current url

/foo/bar/baz.html

then that would make

/
/foo/
/foo/bar/

=cut
sub extract_current_parents {
    my %args = (
	current_url=>undef,
	@_
    );
    
    my %paths = ();
    my $current_url = $args{current_url};
    my @path_split = split('/', $current_url);
    pop @path_split; # remove the current url
    while (@path_split)
    {
	# these paths are index-pages. should end in '/'
	my $newpath = join('/', @path_split, '');
	# give this path the same order-num as the full path
	# but only if it hasn't already been added
	$paths{$newpath} = 1;
	pop @path_split;
    }

    return %paths;
} # extract_current_parents

=head2 build_lol

    my @lol = build_lol(
	paths=>\@paths,
	current_url=>$url,
	do_navbar=>0,
    );

Build a list of lists of paths, given a simple list of paths.
Assumes that this list has already been filtered.

=over

=item paths

Reference to list of paths; this is consumed.

=back

=cut
sub build_lol {
    my %args = (
	paths=>undef,
	depth=>0,
	start_depth=>0,
	end_depth=>0,
	current_url=>'',
	do_navbar=>0,
	@_
    );
    my $paths_ref = $args{paths};
    my $depth = $args{depth};

    my @list_of_lists = ();
    while (@{$paths_ref})
    {
	my $path = $paths_ref->[0];
	my $can_path = make_canonical($path);
	my $path_depth = path_depth($can_path);
	my $path_is_index = ($can_path =~ m#/$#);
	if ($path_depth == $depth)
	{
	    shift @{$paths_ref}; # use this path
	    push @list_of_lists, $path;
	}
	elsif ($path_depth > $depth)
	{
	    push @list_of_lists, [build_lol(
		%args,
		paths=>$paths_ref,
		depth=>$path_depth,
		start_depth=>$args{start_depth},
		end_depth=>$args{end_depth},
		do_navbar=>$args{do_navbar},
		current_url=>$args{current_url},
		)];
	}
	elsif ($path_depth < $depth)
	{
	    return @list_of_lists;
	}
    }
    return @list_of_lists;
} # build_lol

=head2 filter_out_paths

    my @filtered_paths = filter_out_paths(
	paths=>\@paths,
	current_url=>$url,
	hide=>$hide,
	nohide=>$nohide,
	start_depth=>$start_depth,
	end_depth=>$end_depth,
	do_navbar=>0,
    );

Filter out the paths we don't want from our list of paths.
Returns a list of the paths we want.

=cut
sub filter_out_paths {
    my %args = (
	paths=>undef,
	start_depth=>0,
	end_depth=>0,
	current_url=>'',
	do_navbar=>0,
	hide=>'',
	nohide=>'',
	@_
    );
    my $paths_ref = $args{paths};
    my $hide = $args{hide};
    my $nohide = $args{nohide};
    my $current_url_depth = path_depth($args{current_url});
    my $current_url_is_index = ($args{current_url} =~ m#/$#);
    # the current-url dir is the current url without the filename
    my $current_index_path = get_index_path($args{current_url});
    my $current_index_path_depth = path_depth($current_index_path);
    my $current_index_parent = get_index_parent($args{current_url});

    my @wantedpaths = ();
    foreach my $path (@{$paths_ref})
    {
	my $can_path = make_canonical($path);
	my $path_depth = path_depth($can_path);
	my $path_is_index = ($can_path =~ m#/$#);
	if ($hide and $nohide
	    and $path =~ /$hide/
	    and $path != /$nohide/)
	{
	    # skip this one
	}
	elsif ($hide and $path =~ /$hide/)
	{
	    # skip this one
	}
	elsif ($path_depth < $args{start_depth})
	{
	    # skip this one
	}
	elsif ($args{end_depth}
	    and $path_depth > $args{end_depth})
	{
	    # skip this one
	}
	# a navbar shows the parent, the children
	# and the current level
	# and the top level (if we are starting at level 1)
	# and the siblings of one's parent if one is a contents-page
	# or siblings of oneself if one is an index-page
	elsif ($args{do_navbar}
	    and $args{current_url}
	    and !(
	     ($path_depth <= $current_url_depth
	      and $args{current_url} =~ /^$path/)
	     or (
		 $path eq $args{current_url}
		)
	     or (
		 $path_depth >= $current_url_depth 
		 and $path =~ /^$current_index_path/
		)
	     or (
		 $args{start_depth} == 1
		 and $path_depth == $args{start_depth}
		)
	     or (
		 !$current_url_is_index
		 and $path_depth == $current_url_depth - 1
		 and $path =~ /^$current_index_parent/
		)
	     or (
		 $current_url_is_index
		 and $path_depth == $current_url_depth
		 and $path =~ /^$current_index_parent/
		)
	    )
	   )
	{
	    # skip this one
	}
	else
	{
	    # keep this path
	    push @wantedpaths, $path;
	}
    }
    return @wantedpaths;
} # filter_out_paths

=head2 traverse_levels

$links = traverse_levels(\@list_of_lists,
    labels=>\%labels,
    ...
    );

Expects a list, where each item is a reference to a list of links;
or a list of links plus one list of a list of links -- the latter
is an indicator of the parent(s) of this level.

Creates a list-grid of items.

=cut
sub traverse_levels {
    my $lol_ref = shift;
    my %args = (
		current_url=>'',
		labels=>undef,
		prefix_url=>'',
		pre_level=>'<li>',
		post_level=>'</li>',
		pre_item=>'',
		post_item=>'',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		pre_level_parent=>'[',
		post_level_parent=>']',
		item_sep=>" ::\n",
		parent_item_sep=>" ::\n",
		level_sep=>"\n",
		@_
	       );

    my @levels = ();
    foreach my $ll (@{$lol_ref})
    {
	if (ref $ll)
	{
	    my @items = ();
	    foreach my $link (@{$ll})
	    {
		my $label = '';
		my $item = '';
		if (ref $link) # this is a level-parent list
		{
		    my @lp_items = ();
		    foreach my $lp (@{$link})
		    {
			$label = (exists $args{labels}->{$link}
				     ? $args{labels}->{$link} : '');
			my $lp_item = make_item(%args,
					  this_link=>$lp,
					  this_label=>$label,
					  no_link=>1,
					 );
			push @lp_items, $lp_item;
			$item = join($args{parent_item_sep}, @lp_items);
			$item = join('', $args{pre_level_parent},
				     $item, $args{post_level_parent});
		    }
		    push @items, $item;
		}
		else
		{
		    $label = (exists $args{labels}->{$link}
				 ? $args{labels}->{$link} : '');
		    $item = make_item(%args,
					 this_link=>$link,
					 this_label=>$label,
					);
		    push @items, $item;
		}
	    }
	    my $level = join($args{item_sep}, @items);
	    $level = join('', $args{pre_level}, $level, $args{post_level});
	    push @levels, $level;
	}
	else
	{
	    warn "traverse_levels: '$ll' is not a list";
	}
    }
    my $group = join($args{level_sep}, @levels);
    return $group;
} # traverse_levels

=head2 build_levels

    my @lol = build_levels(
	paths=>\@paths,
	current_url=>$url,
    );

Build a "grid" of paths, given a simple list of paths.
The first item contains a list of items at 'start_depth',
then the following items contain lists of items at lower depth,
with optional filtering if we are doing a navbar.

=cut
sub build_levels {
    my %args = (
	paths=>undef,
	depth=>0,
	start_depth=>0,
	end_depth=>0,
	current_url=>'',
	tree_parents=>[],
	@_
    );
    my $paths_ref = $args{paths};
    my $depth = $args{depth};

    my @list_of_lists = ();

    # if we have no paths, we're done
    if (!@{$paths_ref})
    {
	return @list_of_lists;
    }

    # first make the top-level list
    my @top_level = ();
    my @lower_levels = ();
    my @higher_levels = ();
    foreach my $path (@{$paths_ref})
    {
	my $can_path = make_canonical($path);
	my $path_depth = path_depth($can_path);
	if ($path_depth == $depth)
	{
	    push @top_level, $path;
	}
	elsif ($path_depth > $depth)
	{
	    push @lower_levels, $path;
	}
	elsif ($path_depth < $depth)
	{
	    push @higher_levels, $path;
	}
    }
    # pass the higher-level paths back, let our caller worry about them
    @{$paths_ref} = @higher_levels;

    # if we've run out of paths, we've finished
    if (!@top_level)
    {
	return @list_of_lists;
    }

    # if there is a parent url, prepend the top-level list with it
    if (@{$args{tree_parents}})
    {
	unshift @top_level, $args{tree_parents};
    }

    # add the top-level list to the list-of-lists
    push @list_of_lists, \@top_level;

    # if we've run out of paths, we've finished
    if (!@lower_levels)
    {
	return @list_of_lists;
    }

    # go through the top-level list
    # checking for lower-level paths that match
    foreach my $top_path (@top_level)
    {
	my $top_can_path = make_canonical($top_path);
	my @tree_parents = @{$args{tree_parents}};
	push @tree_parents, $top_path;
	my @below_this_path = ();
	my @other_paths = ();
	# get the paths below this path
	foreach my $path (@lower_levels)
	{
	    my $can_path = make_canonical($path);
	    if ($can_path =~ /^$top_can_path/)
	    {
		push @below_this_path, $path;
	    }
	    else
	    {
		push @other_paths, $path;
	    }
	}
	# now recursively process the paths below this path
	my @following_items = build_levels(%args,
	    depth=>$depth + 1,
	    paths=>\@below_this_path,
	    tree_parents=>\@tree_parents);
	if (@following_items)
	{
	    push @list_of_lists, @following_items;
	}
	
	# put the other paths there for the next iteration
	@lower_levels = @other_paths;
    }

    return @list_of_lists;
} # build_levels

=head1 REQUIRES

    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com/tools/html_linklist/

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::LinkList
__END__
