package MT::Template::LayoutSlot::CMS;

use strict;
use warnings;

use MT::Builder;
use MT::Template::Context;

sub on_template_param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component('layoutslot') || die 'LayoutSlot plugin not found';

    # Ignore if mt:layout not used
    return 1 if $param->{text} !~ m!<\$?mt:?layout\s!is;

    my $template_id = $param->{id};
    my $blog_id = $param->{blog_id};

    $param->{layoutslot_refs_ajax_uri} = $app->uri( mode => 'slot_refs', args => {
        template_id => $template_id,
        defined $blog_id? ( blog_id => $blog_id): (),
    });

    my $target = $tmpl->getElementById('tag-list');
    my $el = $tmpl->createElement('app:widget', {
        id      => 'layoutslot-references',
        class   => 'hidden',
        label   => $plugin->translate('Slots Reference'),
    });
    $el->innerHTML(<<'MTML');
<style type="text/css">
    .slot-ref-source { margin-right: 16px; }
    .slot-ref textarea { height: 200px; padding: 4px; width: 100%; font-size: 90%; }
</style>
<div id="layoutslot-references-inner"></div>
<script type="text/javascript">
<!--
    jQuery(function($) {
        $.get(
            '<mt:var name="layoutslot_refs_ajax_uri" escape="js">',
            function(data) {
                var $refs = $(data);
                var switcher = function(e) {
                    $(this).toggleClass('icon-minus').toggleClass('icon-plus');
                    var $source = $(this).parents('.slot-ref').first().find('.slot-ref-source');
                    if ( $(this).hasClass('icon-plus') ) {
                        $source.show();
                    } else {
                        $source.hide();
                    }
                };
                $refs.find('.slot-ref-name').toggle(switcher, switcher);

                $('#layoutslot-references-inner').append($refs);
                $('#layoutslot-references').removeClass('hidden');
            }
        );
    });
-->
</script>
MTML

    $tmpl->insertBefore($el, $target);

    1;
}

sub slot_refs {
    my ( $app ) = @_;
    my $q = $app->param;
    my $plugin = MT->component('layoutslot') || die 'LayoutSlot plugin not found';
    my $fragment = $plugin->load_tmpl('slots_references.tmpl') || die 'Fragment template not found';
    my $template_id = $q->param('template_id') || 0;

    if ( my $tmpl = MT->model('template')->load($template_id) ) {

        # Scan template
        my $builder = MT::Builder->new;
        my $ctx = MT::Template::Context->new;
        my $tokens = $tmpl->compile($ctx);

        $ctx->stash('blog', $app->blog);
        $ctx->stash('_slots_refs', my $refs = {} );

        if ( defined ( my $res = $builder->build($ctx, $tokens) ) ) {

            # Make array
            my @slots = map {
                $_->{uri} = $app->uri( mode => 'view', args => {
                    _type   => 'template',
                    id      => $_->{template_id},
                    blog_id => $_->{blog_id} || 0,
                }) if $_->{template_id};

                $_;
            } sort {
                ($a->{order} || 0) <=> ($b->{order} || 0)
            } grep {
                ref $_ eq 'HASH'
            } values %$refs;

            $fragment->param('slots', \@slots);
        } else {

            # Build error
            $fragment->param('error', $plugin->translate('An error occured in scan layout template: [_1]', $ctx->errstr))
        }
    } else {

        # Lookup error
        $fragment->param('error', $plugin->translate('Template:[_1] is not found', $template_id));
    }

    # Output fragment
    $app->send_http_header('text/html');
    $app->{no_print_body} = 1;
    $app->print_encode($plugin->translate_templatized($fragment->output));
}

1;
__END__
