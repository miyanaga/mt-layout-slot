
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

    # Reference mode?
    if ( defined( my $refs = $ctx->stash('_slots_refs') ) ) {

        # Template name
        my $name = ( grep { $_ } map { $args->{$_} } qw/file module widget identifier/ )[0];
        $name ||= $plugin->translate('[Unknown Template]');

        # Gather slots
        local $ctx->{__stash}{_slots_ref} = { __order__ => 0 };
        my $result = $ctx->invoke_handler('include', $args, $cond);
        return $result unless defined $result;

        # Stash slots as for layout
        $ctx->stash('_slots_refs', $refs = {} ) if ref $refs ne 'HASH';
        $refs->{$name} = {
            name => $name,
            slots => $ctx->{__stash}{_slots_ref},
        };
        $refs->{__order__} ||= 0;
        $refs->{$name}{__order__} = $refs->{__order__}++;

        return '';
    }

    # Building mode

    # Layout stacking
    $ctx->{__stash}{_layout_stack} ||= 0;
    my $stack = ++$ctx->{__stash}{_layout_stack};
    $ctx->{__stash}{_slots} = {} if $stack == 1;

    # Build to override slots
    defined( $builder->build($ctx, $tokens, $cond) )
        || return $ctx->error($builder->errstr);

    # Build original layout
    my $res = $ctx->invoke_handler('include', $args, $cond);

    # Reset if stack over
    $ctx->{__stash}{_lsyout_stack} = --$stack;
    $ctx->{__stash}{_slots} = undef unless $stack;

    return $res;
}

sub _hdlr_Slot {
    my ( $ctx, $args, $cond ) = @_;
    my $name = $args->{name}
        || return $ctx->error($ctx->translate('[_1] tag requires [_2] modifier', 'mt:Slot', 'name'));

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');

    # Reference mode?
    if ( defined( my $ref = $ctx->{__stash}{_slots_ref} ) ) {

        # Stash reference
        $ref->{$name} = {
            name => $name,
            description => $args->{description} || $args->{desc} || '',
            __order__ => $ref->{__order__}++,
        };
        if ( my $template = $ctx->stash('template') ) {
            $ref->{$name}{template_id} = $template->id;
            $ref->{$name}{blog_id} = $template->blog_id;
        }
        return '';
    }

    # Arguments
    my $trim = $args->{trim};
    $trim = 1 unless defined $trim;
    my $prepend = $args->{prepend};
    my $append = $args->{append};
    my ( $body, $header, $footer );

    my $slots = $ctx->{__stash}{_slots};
    {

        # Build original
        local $ctx->{__stash}{_slot} = {};
        defined( $body = $builder->build($ctx, $tokens, $cond) )
            || return $ctx->error($builder->errstr);

        $body =~ s/(^\s+|\s+$)//g if $trim;
        $header = $ctx->{__stash}{_slot}{header};
        $footer = $ctx->{__stash}{_slot}{footer};

    }

    # Output: join header and footer if has body
    $body = join('', $header || '', $body, $footer || '') if $body;

    # In layout context?
    if ( defined( $slots ) && defined( my $slot = $slots->{$name} ) ) {

        # Join body
        $slot->{body} ||= '';
        if ( $slot->{body} ) {
            if ( defined $slot->{append} ) {
                $body = $body . $slot->{append} . $slot->{body}; # orig,append,override
            } elsif ( defined $slot->{prepend} ) {
                $body = $slot->{body} . $slot->{prepend} . $body; # override,prepend,orig
            } elsif ( defined $append ) {
                $body = $slot->{body} . $append . $body; # override,append,orig
            } elsif ( defined $prepend ) {
                $body = $body . $prepend . $slot->{body}; # orig,prepend,override
            } else {
                $body = $slot->{body}; # Replace
            }
        }

        # Override header and footer
        $header = $slot->{header} if defined $slot->{header};
        $footer = $slot->{footer} if defined $slot->{footer};
    } else {

        # Store results.
        $slots->{$name} = {
            header  => $header,
            footer  => $footer,
            body    => $body,
            prepend => $prepend,
            append  => $append,
        };
    }

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
