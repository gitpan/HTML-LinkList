package HTML::LinkList;
use strict;
use warnings;

=head1 NAME

HTML::LinkList - Create a 'smart' list of HTML links.

=head1 VERSION

This describes version B<0.01> of HTML::LinkList.

=cut

our $VERSION = '0.01';

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
	pre_list=>'<p>',
	post_list=>'</p>',
	pre_item=>'',
	post_item=>''
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
	item_sep=>" :: ");

=head1 DESCRIPTION

This module contains a number of functions for taking sets of
URLs and labels and creating suitably formatted HTML.
These links are "smart" because, if given the url of
the current page, if any of the links in the list equal it,
that item in the list will be formatted as a special label,
not as a link; this is a Good Thing, since the user would
be confused by clicking on a link back to the current page.

While the default format for the HTML is to make an unordered list,
there are many options, enabling one to have a flatter layout
with any separators you desire.

The "link_list" function uses a simple list of links -- good
for a simple navbar.

The "link_tree" function takes a set of nested links
and makes the HTML for them -- good for making a table of contents,
or a more complicated navbar.

The "dir_tree" function takes a list of paths and makes
a full tree of all the files and directories in those
paths -- good for making a site map.

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
	dir_tree
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
	pre_list=>'<ul>',
	post_list=>'</ul>',
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

=item pre_list

String to begin the list with.

=item post_list

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
		pre_list=>'<ul>',
		post_list=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		item_sep=>"\n",
		@_
	       );

    my @link_order = @{$args{urls}};
    if (!defined $args{urls}
	or !@{$args{urls}})
    {
	return '';
    }
    my @items = ();
    foreach my $link (@link_order)
    {
	my $label = (exists $args{labels}->{$link}
	    ? $args{labels}->{$link} : '');
	my $item = make_item(this_link=>$link,
	    this_label=>$label,
	    %args);
	push @items, $item;
    }
    my $list = join($args{item_sep}, @items);
    return ($list
	? join('', $args{pre_list}, $list, $args{post_list})
	: '');
} # link_list

=head2 link_tree

    $links = link_tree(
	current_url=>$url,
	link_tree=>\@list_of_lists,
	labels=>\%labels,
	descriptions=>\%desc,
	tree_head=>'<ul>',
	tree_foot=>'</ul>',
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

=item tree_head

The string to prepend the top-level tree with.
(default: <ul>)

=item tree_foot

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
		tree_head=>'<ul>',
		tree_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_list=>'<ul>',
		post_list=>'</ul>',
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		item_sep=>"\n",
		tree_sep=>"\n",
		@_
	       );

    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    if (defined $args{link_tree}
	and @{$args{link_tree}})
    {
	my @link_tree = @{$args{link_tree}};
	my $list = traverse_lol(\@link_tree, %args);
	return join('', $args{tree_head}, $list, $args{tree_foot});
    }
    else # no list of lists
    {
	return '';
    }
} # link_tree

=head2 dir_tree

    $links = dir_tree(
	paths=>\@list_of_paths,
	labels=>\%labels,
	descriptions=>\%desc,
	hide=>$hide_regex,
	start_depth=>0,
	end_depth=>0,
	...
	);

Given a set of paths this will generate a tree of links in the style of
I<link_tree>.  The lists will be nested just like the directories are,
and sorted in alphabetical order.

If you don't want them sorted in alphabetical order, then you would
do better to generate your own list of paths, and use I<link_tree>.

The formatting options are as for L</link_tree>.

Options:

=over

=item paths

A reference to a list of paths; for example, files relative to the top
of the website.  Note that they need to be URL relative paths (with the
'/' character as directory separator) not MS-Windows-style filenames.
This does not require that every possible path be given; all the intermediate
paths will be figured out from the list.

=item labels

Hash containing replacement labels for one or more categories.
If no label is given for '/' (the root path) then 'Home' will
be used.

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the urls.

=item hide

If the path matches this string, don't include it in the tree.

=item start_depth

Start your tree at this depth.

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
sub dir_tree {
    my %args = (
		paths=>undef,
		tree_head=>'<ul>',
		tree_foot=>"\n</ul>",
		subtree_head=>'<ul>',
		subtree_foot=>"\n</ul>",
		last_subtree_head=>'<ul>',
		last_subtree_foot=>"\n</ul>",
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		item_sep=>"\n",
		tree_sep=>"\n",
		hide=>'',
		labels=>{},
		start_depth=>0,
		end_depth=>0,
		@_
	       );

    # set the root label
    if (!$args{labels}->{'/'})
    {
	$args{labels}->{'/'} = 'Home';
    }
    my @path_list = extract_all_paths(paths=>$args{paths});
    my @list_of_lists = build_lol(%args, paths=>\@path_list,
				  depth=>0);
    $args{tree_depth} = 0;
    $args{end_depth} = 0;

    my $list = traverse_lol(\@list_of_lists, %args);
    return join('', $args{tree_head}, $list, $args{tree_foot});
} # dir_tree

=head1 Private Functions

These functions cannot be exported.

=head2 make_item

$item = make_item(
	this_label=>$label,
	this_link=>$link,
	current_url=>$url,
	descriptions=>\%desc,
	pre_list=>'<ul>',
	post_list=>'</ul>',
	pre_item=>'<li>',
	post_item=>'</li>'
	pre_active_item=>'<em>',
	post_active_item=>'</em>',
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

=item descriptions

Optional hash of descriptions, to put next to the links.  The keys
of this hash are the links (not the labels).

=item defer_post_item

Don't add the 'post_item' string if this is true.
(needed for nested lists)
(default: false)

=back

=cut
sub make_item {
    my %args = (
		this_link=>'',
		this_label=>'',
		current_url=>'',
		prefix_url=>'',
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<em>',
		post_active_item=>'</em>',
		defer_post_item=>0,
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
    if ($link eq $args{current_url}) # active
    {
	$item = join('', $args{pre_item},
		     $args{pre_active_item},
		     $label,
		     $desc,
		     $args{post_active_item});
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
		pre_list=>'<ul>',
		post_list=>'</ul>',
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<li><em>',
		post_active_item=>'</em></li>',
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

my @all_paths = extract_all_paths(paths=>\@paths);

Extract all possible paths out of a list of paths.
Thus, if one has

/foo/bar/baz.html

then that would make

/
/foo/
/foo/bar/
/foo/bar/baz.html

This returns a sorted list of all possible paths.

=cut
sub extract_all_paths {
    my %args = (
	paths=>undef,
	@_
    );
    
    my %paths = ();
    foreach my $path (@{$args{paths}})
    {
	my @path_split = split('/', $path);
	# first path as-is
	$paths{$path} = 1;
	pop @path_split;
	while (@path_split)
	{
	    # these paths are directories. should end in '/'
	    my $newpath = join('/', @path_split, '');
	    $paths{$newpath} = 1;
	    pop @path_split;
	}
    }
    return sort keys %paths;
} # extract_all_paths

=head2 build_lol

    my @lol = build_lol(
	paths=>\@paths,
	current_url=>$url,
	match_current_url=>0,
    );

Build a list of lists of directory/file paths, given
a simple list of paths.

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
	match_current_url=>0,
	hide=>undef,
	@_
    );
    my $paths_ref = $args{paths};
    my $depth = $args{depth};
    my $hide = $args{hide};
    my $current_url = $args{current_url};
    my @current_url = split('/', $current_url);
    my $current_url_depth = scalar @current_url;
    # the current-url dir is the current url without the filename
    my $current_url_dir = $current_url;
    $current_url_dir =~ s/\/\w+\.\w+$//;
    $current_url_dir =~ s/\/$//;

    my @list_of_lists = ();
    while (@{$paths_ref})
    {
	my $path = $paths_ref->[0];
	my @path = split('/', $path);
	my $path_depth = scalar @path;
	if ($args{match_current_url}
	    and $args{current_url}
	    and !(
	     ($path_depth <= $current_url_depth
	      and $args{current_url} =~ /^$path/)
	     or (
		 $path_depth == $current_url_depth
		 and $path eq $current_url_dir
		)
	     or (
		 $path_depth > $current_url_depth # child
		 and $path =~ /^$current_url_dir/
		)
	    )
	   )
	{
	    shift @{$paths_ref} # skip this one
	}
	elsif ($hide and $path =~ /$hide/)
	{
	    shift @{$paths_ref} # skip this one
	}
	elsif ($path_depth < $args{start_depth})
	{
	    shift @{$paths_ref} # skip this one
	}
	elsif ($args{end_depth}
	    and $path_depth > $args{end_depth})
	{
	    shift @{$paths_ref} # skip this one
	}
	elsif ($path_depth == $depth)
	{
	    shift @{$paths_ref}; # remove this path
	    push @list_of_lists, $path;
	}
	elsif ($path_depth > $depth)
	{
	    push @list_of_lists, [build_lol(
		paths=>$paths_ref,
		depth=>$path_depth,
		start_depth=>$args{start_depth},
		end_depth=>$args{end_depth},
		match_current_url=>$args{match_current_url},
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
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::LinkList
__END__
