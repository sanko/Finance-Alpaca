package Finance::Alpaca::Struct::Order 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Order];
    use Type::Utils;
    use Types::Standard qw[ArrayRef Bool Enum InstanceOf Int Maybe Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Order, { class => __PACKAGE__ };
    coerce( Order, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    has [qw[id asset_id]] => ( is => 'ro', isa => Uuid,      required => 1 );
    has client_order_id   => ( is => 'ro', isa => Str,       required => 1 );
    has created_at        => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );
    has [qw[updated_at submitted_at filled_at expired_at canceled_at failed_at replaced_at]] =>
        ( is => 'ro', isa => Maybe [Timestamp], predicate => 1, coerce => 1 );
    has [qw[replaced_by replaces]] => ( is => 'ro', isa => Maybe [Uuid], predicate => 1 );
    has [qw[symbol asset_class]]   => ( is => 'ro', isa => Str, required => 1 );    # If from stream
    has [qw[notional qty filled_avg_price limit_price stop_price trail_percent trail_price hwm]] =>
        ( is => 'ro', isa => Maybe [Num], predicate => 1 );
    has filled_qty  => ( is => 'ro', isa => Num, required => 1 );
    has order_class =>
        ( is => 'ro', isa => Enum [ '', qw[simple bracket oco oto] ], required => 1 );
    has type =>
        ( is => 'ro', isa => Enum [qw[market limit stop stop_limit trailing_stop]], required => 1 );
    has side          => ( is => 'ro', isa => Enum [qw[buy sell]],                required => 1 );
    has time_in_force => ( is => 'ro', isa => Enum [qw[day gtc opg cls ioc fok]], required => 1 );
    has status        => (
        is  => 'ro',
        isa => Enum [
            qw[new partially_filled filled done_for_day canceled expired replaced pending_cancel pending_replace accepted pending_new accepted_for_bidding stopped rejected suspended calculated held]
        ],
        required => 1
    );
    has extended_hours => ( is => 'ro', isa => Bool, required => 1, coerce => 1 );
    has legs => ( is => 'ro', isa => Maybe [ ArrayRef [Order] ], coerce => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Order - A Single Order Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @orders = Finance::Alpaca->new( ... )->orders( status => 'all' );

    say $orders[0]->id;

=head1 DESCRIPTION

The orders API allows a user to monitor, place and cancel their orders with
Alpaca. Each order has a unique identifier provided by the client. This
client-side unique order ID will be automatically generated by the system if
not provided by the client, and will be returned as part of the order object
along with the rest of the fields described below. Once an order is placed, it
can be queried using the client-side order ID to check the status. Updates on
open orders at Alpaca will also be sent over the streaming interface, which is
the recommended method of maintaining order state.

=head1 Properties

The following properties are contained in the object.

    $trade->id;

=over

=item C<id> - Order ID; UUID

=item C<client_order_id> - Client unique order ID

=item C<created_at> - Timestamp as Time::Moment object

=item C<updated_at> - Timestamp as Time::Moment object if available

=item C<submitted_at> - Timestamp as Time::Moment object if available

=item C<filled_at> - Timestamp as Time::Moment object if available

=item C<expired_at> - Timestamp as Time::Moment object if available

=item C<canceled_at> - Timestamp as Time::Moment object if available

=item C<failed_at> - Timestamp as Time::Moment object if available

=item C<replaced_at> - Timestamp as Time::Moment object if available

=item C<replaced_by> - The order ID that this order was replaced by if available; UUID

=item C<replaces> - The order ID that this order replaces if available; UUID

=item C<asset_id> - Asset ID; UUID

=item C<symbol> - Asset symbol

=item C<asset_class> - Asset class

=item C<notional> - Ordered notional amount. If entered, C<qty( )> will be undefined. Can take u pto C<9> decimal places.

=item C<qty> - Ordered quantity. If entered, C<notional( )> will be undefined. Can take up to C<9> decimal places.

=item C<filled_qty> - Filled quantity

=item C<filled_avg_price> - Filled average price

=item C<order_class> - C<simple>, C<bracket>, C<oco>, or C<oto>. For details of non-simple order classes, please see L<Bracket Order Overview|https://alpaca.markets/docs/trading-on-alpaca/orders#bracket-orders>.

=item C<type> - C<market>, C<limit>, C<stop>, C<stop_limit>, or C<trailing_stop>

=item C<side> - C<buy> or C<sell>

=item C<time_in_force> - C<day>, C<gtc>, C<opg>, C<cls>, C<ioc>, C<fok>. See L<Orders page|https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force>

=item C<limit_price> - Limit price if applicable

=item C<stop_price> - Stop price if applicable

=item C<status> - See L<Orders page|https://alpaca.markets/docs/trading-on-alpaca/orders/#order-lifecycle>

=item C<extended_hours> - Boolean value indicating whether the order is eligible for execution outside regular trading hours

=item C<legs> - List of Orders; When querying non-simple C<order_class> order in a nested style, an arry of Order objects associated with this order. Otherwise, undefined.

=item C<trail_percent> - The percent value away from the high water mark for trailing stop orders, if applicable.

=item C<trail_price> - The dollar value away from the hight water mark for trailing stop orders, if available.

=item C<hwm> - The highest (lowest) market price seen since the trailing stop order was submitted.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/orders/
