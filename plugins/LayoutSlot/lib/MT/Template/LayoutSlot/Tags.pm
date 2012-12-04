
package MT::Template::LayoutSlot::Tags;

use strict;
use warnings;

=head2 LayoutSlot

=cut

sub _hdlr_Layout {
    my ( $ctx, $args, $cond ) = @_;
    my $plugin = MT->component('layoutslot') || die 'LayoutSlot plugin not found';

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');

    # Reference mode
    if ( defined( my $refs = $ctx->stash('_slots_refs') ) ) {

        # Template name
        my $name = ( grep { $_ } map { $args->{$_} } qw/file module widget identifier/ )[0];
        $name ||= $plugin->translate('[Unknown Template]');

        # Gather slots
        local $ctx->{__stash}{_slots_refs_order}
            = $ctx->{__stash}{_slots_refs_order} || 0;
        if ( my $template = $ctx->stash('template') ) {
            $template->name($name) unless $template->name;
        }

        my $result = $ctx->invoke_handler('includeblock', $args, $cond);
        return $result unless defined $result;

        defined( $builder->build($ctx, $tokens, $cond) )
            or return $ctx->error($builder->errstr);

        return '';
    }

    # Building mode

    # Inherit or initialize slots
    local $ctx->{__stash}{_slots} = $ctx->{__stash}{_inside_slot}
        ? {}
        : $ctx->{__stash}{_slots} || {};

    # Gather slots
    defined( $builder->build($ctx, $tokens, $cond) )
        or return $ctx->error($builder->errstr);

    # Delegate to mt:include
    $ctx->invoke_handler('includeblock', $args, $cond);
}

sub _hdlr_IfSlotted {
    my ( $ctx, $args, $cond ) = @_;
    my $name = $args->{name}
        || return $ctx->error($ctx->translate('[_1] tag requires [_2] modifier', 'mt:IfSlotted', 'name'));

    my $slots = $ctx->{__stash}{_slots};
    $slots && $slots->{$name} ? 1 : 0;
}

sub _hdlr_Slot {
    my ( $ctx, $args, $cond ) = @_;
    my $name = $args->{name}
        || return $ctx->error($ctx->translate('[_1] tag requires [_2] modifier', 'mt:Slot', 'name'));

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');

    # Reference mode?
    if ( defined( my $refs = $ctx->{__stash}{_slots_refs} ) ) {

        # Stash reference
        $refs->{$name} = {
            name        => $name,
            order       => $ctx->{__stash}{_slots_refs_order}++,
            source      => $ctx->{__stash}{uncompiled},
            description => $args->{description} || $args->{desc} || '',
        };

        if ( my $template = $ctx->stash('template') ) {
            $refs->{$name}{template} = $template->name;
            $refs->{$name}{template_id} = $template->id;
            $refs->{$name}{blog_id} = $template->blog_id;
        }

        # Gether inside
        defined( $builder->build($ctx, $tokens, $cond) )
            || return $ctx->error($builder->errstr);

        return '';
    }

    # Building mode
    my $slots = $ctx->{__stash}{_slots};

    # Arguments
    my $trim = $args->{trim};
    $trim = 1 unless defined $trim;

    # Build inside
    local $ctx->{__stash}{_inside_slot} = 1;
    local $ctx->{__stash}{_slot} = {};
    defined( my $body = $builder->build($ctx, $tokens, $cond) )
        || return $ctx->error($builder->errstr);

    $body =~ s/(^\s+|\s+$)//g if $trim;
    $body = $slots->{$name} if $slots && defined $slots->{$name};

    # Output: join header and footer if has body
    $body = join('',
        $ctx->{__stash}{_slot}{header} || '',
        $body,
        $ctx->{__stash}{_slot}{footer} || ''
    ) if $body;

    return $body unless $slots;
    $slots->{$name} = $body;

    $body;
}

sub _hdlr_SlotPartial {
    my $type = shift;
    my ( $ctx, $args, $cond ) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');

    # Build and stash partial
    defined( $ctx->{__stash}{_slot}{$type} = $builder->build($ctx, $tokens, $cond) )
        || return $ctx->error($builder->errstr);

    # Just store, no output
    return '';
}

sub _hdlr_SlotHeader { _hdlr_SlotPartial('header', @_) }

sub _hdlr_SlotFooter  { _hdlr_SlotPartial('footer', @_) }

1;
