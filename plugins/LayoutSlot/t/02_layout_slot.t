use FindBin;
use lib "$FindBin::Bin";

use MTPath;
use Test::More;

use MT::Plugins::Test::Object;
use MT::Plugins::Test::Template;
use MT::Plugins::Test::Request::CMS;

test_common_website(
    as_superuser => 1,
    test => sub {
        my ( $website, $blog, $author, $password ) = @_;

        test_objects(
            template => 'module_template',
            model => 'template',
            values => {
                layout1 => {
                    name => 'Layout1',
                    blog_id => $blog->id,
                    text => q{
<html>
<head>
<title><mt:slot name="html_title" desc="HTML Title">HTML Title</mt:slot></title>
</head>
<body>
<mt:ifslotted name="html_body">
<p>HTML Body Slotted</p>
</mt:ifslotted>
<mt:slot name="html_body" desc="HTML Body">
HTML Body
</mt:slot>
</body>
</html>
},
                },
                layout2 => {
                    name => 'Layout2',
                    blog_id => $blog->id,
                    text => q{
<mt:layout module="Layout1">
<mt:slot name="html_body">
<header>
<mt:slot name="header" desc="Header in Body">
Header
</mt:slot>
</header>
<mt:ifslotted name="contents">
<p>Contents Slotted</p>
</mt:ifslotted>
<mt:slot name="contents" desc="Contents in Body">
<mt:slotheader><article></mt:slotheader>
Contents
<mt:slotfooter></article></mt:slotfooter>
</mt:slot>
</mt:slot>
</mt:layout>
},
                },
                layout3 => {
                    name => 'Layout3',
                    blog_id => $blog->id,
                    text => q{
<mt:slot name="html_title">Title In Nested Layout</mt:slot>
},
                },
                referrer => {
                    name => 'Referrer',
                    blog_id => $blog->id,
                    text => q{
<mt:layout module="Layout2"></mt:layout>
},
                }
            },
            test => sub {
                my $objects = shift;

                subtest 'Build Templates' => sub {
                    test_template(
                        stash => {
                            blog => $blog,
                        },
                        template => q{
<mt:layout module="Layout1">
</mt:layout>
},
                        test => sub {
                            my %args = @_;
                            is $args{result}, q{
<html>
<head>
<title>HTML Title</title>
</head>
<body>

HTML Body
</body>
</html>

}, 'No Slotted Layout1';
                        },
                    );

                    test_template(
                        stash => {
                            blog => $blog,
                        },
                        template => q{
<mt:layout module="Layout1">
<mt:slot name="html_title">New Title</mt:slot>
<mt:slot name="html_body">New Body</mt:slot>
</mt:layout>
},
                        test => sub {
                            my %args = @_;
                            is $args{result}, q{
<html>
<head>
<title>New Title</title>
</head>
<body>

<p>HTML Body Slotted</p>

New Body
</body>
</html>

}, 'Slotted Layout1';
                        },
                    );

                    test_template(
                        stash => {
                            blog => $blog,
                        },
                        template => q{
<mt:layout module="Layout2">
</mt:layout>
},
                        test => sub {
                            my %args = @_;
                            is $args{result}, q{
<html>
<head>
<title>HTML Title</title>
</head>
<body>

<p>HTML Body Slotted</p>

<header>
Header
</header>

<article>Contents</article>
</body>
</html>


}, 'No Slotted Layout2';
                        },
                    );

                    test_template(
                        stash => {
                            blog => $blog,
                        },
                        template => q{
<mt:layout module="Layout2">
<mt:slot name="html_title">Slotted HTML Title</mt:slot>
<mt:slot name="header">Slotted Header</mt:slot>
<mt:slot name="contents">Slotted Contents</mt:slot>
</mt:layout>
},
                        test => sub {
                            my %args = @_;
                            is $args{result}, q{
<html>
<head>
<title>Slotted HTML Title</title>
</head>
<body>

<p>HTML Body Slotted</p>

<header>
Slotted Header
</header>

<p>Contents Slotted</p>

<article>Slotted Contents</article>
</body>
</html>


}, 'Slotted Layout2';
                        },
                    );

                    test_template(
                        stash => {
                            blog => $blog,
                        },
                        template => q{
<mt:layout module="Layout2">
<mt:slot name="html_title"></mt:slot>
<mt:slot name="header"></mt:slot>
<mt:slot name="contents"></mt:slot>
</mt:layout>
},
                        test => sub {
                            my %args = @_;
                            is $args{result}, q{
<html>
<head>
<title></title>
</head>
<body>

<p>HTML Body Slotted</p>

<header>

</header>
</body>
</html>


}, 'Slotted Empty Layout2';
                        },
                    );

                    test_template(
                        stash => { blog => $blog },
                        template => q{
<mt:layout module="Layout1">
<mt:slot name="html_title">Global HTML Title</mt:slot>
<mt:slot name="html_body">
<mt:layout module="Layout3">
<mt:slot name="html_title">Local HTML Title</mt:slot>
</mt:layout>
</mt:slot>
</mt:layout>
},
                        test => sub {
                            my %args = @_;
                            is $args{result}, q{
<html>
<head>
<title>Global HTML Title</title>
</head>
<body>

<p>HTML Body Slotted</p>

Local HTML Title
</body>
</html>

}, 'Nested Layout3 in Layout1',

                        },
                    );
                };

                subtest 'Slot Reference' => sub {
                    my $cms = 'MT::Plugins::Test::Request::CMS';
                    $cms->test_user_mech(
                        as_superuser => 1,
                        via => 'bootstrap',
                        test => sub {
                            my $mech = shift;
                            my $res = $mech->get($cms->uri(
                                __mode => 'slot_refs',
                                blog_id => $blog->id,
                                template_id => $objects->{referrer}->id,
                            ));

                            my $base = $cms->uri;
                            my $html = $res->content;
                            $html =~ s!(?<=blog_id=)([0-9]+)!!sg;
                            $html =~ s!(?<=template_id=)([0-9]+)!!sg;
                            $html =~ s!"([^"]+?)mt.cgi!"mt.cgi!sg;
                            $html =~ s!\n\s+!\n!sg;
                            $html =~ s!\n\n+!\n!sg;
                            # $html =~ s!\s+\n!\n!g;

                            is $html, <<'HTML';

<ul class="slot-ref">
<li>
<a href="javascript:void(0)" class="slot-ref-name icon-left icon-minus">html_title</a>
@
<a class="" href="mt.cgi?__mode=view&amp;_type=template&amp;blog_id=&amp;id=2344">
<span class="slot-ref-tmpl-name">Layout1</span>
</a>
</li>
<li class="icon-left">
HTML Title
</li>
<li class="slot-ref-source icon-left" style="display:none"><textarea readonly="readonly">&lt;mt:Slot name="html_title"&gt;
HTML Title
&lt;/mt:Slot&gt;
</textarea></li>
</ul>
<ul class="slot-ref">
<li>
<a href="javascript:void(0)" class="slot-ref-name icon-left icon-minus">html_body</a>
@
<a class="" href="mt.cgi?__mode=view&amp;_type=template&amp;blog_id=&amp;id=2342">
<span class="slot-ref-tmpl-name">Layout2</span>
</a>
</li>
<li class="slot-ref-source icon-left" style="display:none"><textarea readonly="readonly">&lt;mt:Slot name="html_body"&gt;
&lt;header&gt;
&lt;mt:slot name=&quot;header&quot; desc=&quot;Header in Body&quot;&gt;
Header
&lt;/mt:slot&gt;
&lt;/header&gt;
&lt;mt:ifslotted name=&quot;contents&quot;&gt;
&lt;p&gt;Contents Slotted&lt;/p&gt;
&lt;/mt:ifslotted&gt;
&lt;mt:slot name=&quot;contents&quot; desc=&quot;Contents in Body&quot;&gt;
&lt;mt:slotheader&gt;&lt;article&gt;&lt;/mt:slotheader&gt;
Contents
&lt;mt:slotfooter&gt;&lt;/article&gt;&lt;/mt:slotfooter&gt;
&lt;/mt:slot&gt;
&lt;/mt:Slot&gt;
</textarea></li>
</ul>
<ul class="slot-ref">
<li>
<a href="javascript:void(0)" class="slot-ref-name icon-left icon-minus">header</a>
@
<a class="" href="mt.cgi?__mode=view&amp;_type=template&amp;blog_id=&amp;id=2342">
<span class="slot-ref-tmpl-name">Layout2</span>
</a>
</li>
<li class="icon-left">
Header in Body
</li>
<li class="slot-ref-source icon-left" style="display:none"><textarea readonly="readonly">&lt;mt:Slot name="header"&gt;
Header
&lt;/mt:Slot&gt;
</textarea></li>
</ul>
<ul class="slot-ref">
<li>
<a href="javascript:void(0)" class="slot-ref-name icon-left icon-minus">contents</a>
@
<a class="" href="mt.cgi?__mode=view&amp;_type=template&amp;blog_id=&amp;id=2342">
<span class="slot-ref-tmpl-name">Layout2</span>
</a>
</li>
<li class="icon-left">
Contents in Body
</li>
<li class="slot-ref-source icon-left" style="display:none"><textarea readonly="readonly">&lt;mt:Slot name="contents"&gt;
&lt;mt:slotheader&gt;&lt;article&gt;&lt;/mt:slotheader&gt;
Contents
&lt;mt:slotfooter&gt;&lt;/article&gt;&lt;/mt:slotfooter&gt;
&lt;/mt:Slot&gt;
</textarea></li>
</ul>
HTML
                        },
                    );
                };
            },
        );
    },
);

done_testing;