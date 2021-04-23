package Finance::Alpaca 1.00 {
    use strictures 2;
    use Moo;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use Mojo::UserAgent;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Str Int];
    #
    use lib './lib/';
    use Finance::Alpaca::Struct::Account qw[to_Account];
    use Finance::Alpaca::Struct::Asset qw[to_Asset Asset];
    use Finance::Alpaca::Struct::Bar qw[to_Bar Bar];
    use Finance::Alpaca::Struct::Calendar qw[to_Calendar Calendar];
    use Finance::Alpaca::Struct::Clock qw[to_Clock];
    use Finance::Alpaca::Struct::Order qw[to_Order Order];
    use Finance::Alpaca::Struct::Quote qw[to_Quote Quote];
    use Finance::Alpaca::Stream;
    use Finance::Alpaca::Struct::Trade qw[to_Trade Trade];
    #
    has ua => ( is => 'lazy', isa => InstanceOf ['Mojo::UserAgent'] );

    sub _build_ua ($s) {
        my $ua = Mojo::UserAgent->new;
        $ua->transactor->name(
            sprintf 'Finance::Alpaca %f (Perl %s)',
            $Finance::Alpaca::VERSION, $^V
        );
        $ua->on(
            start => sub ( $ua, $tx ) {
                $tx->req->headers->header( 'APCA-API-KEY-ID'     => $s->keys->[0] ) if $s->has_keys;
                $tx->req->headers->header( 'APCA-API-SECRET-KEY' => $s->keys->[1] ) if $s->has_keys;
            }
        );
        return $ua;
    }
    has api_version => ( is => 'ro', isa => Enum [ 1, 2 ], required => 1, default => 2 );
    has paper => ( is => 'rw', isa => Bool, required => 1, default => 0, coerce => 1 );

    sub endpoint ($s) {
        $s->paper ? 'https://paper-api.alpaca.markets' : '';
    }
    has keys => ( is => 'rwp', isa => ArrayRef [ Str, 2 ], predicate => 1 );
    #
    sub account ($s) {
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/account' );
        $tx = $s->ua->start($tx);
        return to_Account( $tx->result->json );
    }

    sub clock ($s) {
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/clock' );
        $tx = $s->ua->start($tx);
        return to_Clock( $tx->result->json );
    }

    sub calendar ( $s, %params ) {
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/calendar' . $params );
        $tx = $s->ua->start($tx);
        return ( ArrayRef [Calendar] )->assert_coerce( $tx->result->json );
    }

    sub assets ( $s, %params ) {
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        return ( ArrayRef [Asset] )
            ->assert_coerce( $s->ua->get( $s->endpoint . '/v2/assets' . $params )->result->json );
    }

    sub asset ( $s, $symbol_or_asset_id ) {
        my $res = $s->ua->get( $s->endpoint . '/v2/assets/' . $symbol_or_asset_id )->result;
        return $res->is_error ? () : to_Asset( $res->json );
    }

    sub bars ( $s, %params ) {
        my $symbol = delete $params{symbol};
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        return ( Dict [ bars => ArrayRef [Bar], symbol => Str, next_page_token => Maybe [Str] ] )
            ->assert_coerce(
            $s->ua->get(
                sprintf 'https://data.alpaca.markets/v%d/stocks/%s/bars%s',
                $s->api_version, $symbol, $params
            )->result->json
            );
    }

    sub quotes ( $s, %params ) {
        my $symbol = delete $params{symbol};
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        return (
            Dict [ quotes => ArrayRef [Quote], symbol => Str, next_page_token => Maybe [Str] ] )
            ->assert_coerce(
            $s->ua->get(
                sprintf 'https://data.alpaca.markets/v%d/stocks/%s/quotes%s',
                $s->api_version, $symbol, $params
            )->result->json
            );
    }

    sub trades ( $s, %params ) {
        my $symbol = delete $params{symbol};
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        return (
            Dict [ trades => ArrayRef [Trade], symbol => Str, next_page_token => Maybe [Str] ] )
            ->assert_coerce(
            $s->ua->get(
                sprintf 'https://data.alpaca.markets/v%d/stocks/%s/trades%s',
                $s->api_version, $symbol, $params
            )->result->json
            );
    }

    sub stream ( $s, $cb, %params ) {
        my $stream = Finance::Alpaca::Stream->new(
            cb     => $cb,
            source => delete $params{source} // 'iex'    # iex or sip
        );
        $stream->authorize( $s->ua, $s->keys )->catch(
            sub ($err) {
                $stream = ();
                warn "WebSocket error: $err";
            }
        )->wait;
        $stream;
    }

    sub orders ( $s, %params ) {
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        return ( ArrayRef [Order] )
            ->assert_coerce( $s->ua->get( $s->endpoint . '/v2/orders' . $params )->result->json );
    }

    sub order_by_id ( $s, $order_id, $nested = 0 ) {
        my $res = $s->ua->get(
            $s->endpoint . '/v2/orders/' . $order_id . ( $nested ? '?nested=1' : '' ) )->result;
        return $res->is_error ? () : to_Order( $res->json );
    }

    sub order_by_client_id ( $s, $order_id ) {
        my $res = $s->ua->get(
            $s->endpoint . '/v2/orders:by_client_order_id?client_order_id=' . $order_id )->result;
        return $res->is_error ? () : to_Order( $res->json );
    }

    sub submit_order ( $s, %params ) {
        $params{extended_hours} = ( !!$params{extended_hours} ) ? 'true' : 'false'
            if defined $params{extended_hours};
        my $res = $s->ua->post( $s->endpoint . '/v2/orders' => json => \%params )->result;
        return $res->is_error ? $res->json : to_Order( $res->json );
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca - It's new $module

=head1 SYNOPSIS

    use Finance::Alpaca;

=head1 DESCRIPTION

Finance::Alpaca is ... still under construction.

=head1 METHODS

=head2 C<new( ... )>

    my $camelid = Finance::Alpaca->new(
        keys => [ 'MDJOHHAE5BDE2FAYAEQT',
                  'Xq9p6ovxaa5XKihaEDRgpMapjeWYd5gIM63iq5BL'
                ] );

Creates a new Finance::Alpaca object.

This constructor accepts the following parameters:

=over

=item C<keys> - C<[ $APCA_API_KEY_ID, $APCA_API_SECRET_KEY ]>

Every API call requires authentication. You must provide these keys which may
be acquired in the developer web console and are only visible on creation.

=item C<paper> - Boolean value

If you're attempting to use Alpaca's paper trading functionality, this B<must>
be a true value. Otherwise, you will be making live trades with actual assets.

B<Note>: This is a false value by default.

=back

=head2 C<account( )>

Returns a Finance::Alpaca::Struct::Account object.

The account endpoint serves important information related to an account,
including account status, funds available for trade, funds available for
withdrawal, and various flags relevant to an account’s ability to trade.

=head2 C<clock( )>

    my $clock = $camelid->clock();
    say sprintf
        $clock->timestamp->strftime('It is %l:%M:%S %p on a %A and the market is %%sopen!'),
        $clock->is_open ? '' : 'not ';

Returns a Finance::Alpaca::Struct::Clock object.

The clock endpoint serves the current market timestamp, whether or not the
market is currently open, as well as the times of the next market open and
close.

=head2 C<calendar( [...] )>

Returns a list of Finance::Alpaca::Struct::Calendar objects.

The calendar endpoint serves the full list of market days from 1970 to 2029.

The following parameters are accepted:

=over

=item C<start> - The first date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

=item C<end> - The last date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

=back

Both listed parameters are optional. If neither is provided, the calendar will
begin on January 1st, 1970.

=head2 C<assets( [...] )>

Returns a list of Finance::Alpaca::Struct::Asset objects.

The assets endpoint serves as the master list of assets available for trade and
data consumption from Alpaca.

The following parameters are accepted:

=over

=item C<status> - e.g. C<active>. By default, all statuses are included

=item C<asset_class> - Defaults to C<us_equity>

=back

=head2 C<asset( ... )>

    my $msft = $camelid->asset('MSFT');
    my $spy  = $camelid->asset('b28f4066-5c6d-479b-a2af-85dc1a8f16fb');

Returns a Finance::Alpaca::Struct::Asset object.

You may use either the asset's C<id> (UUID) or C<symbol>. If the asset is not
found, an empty list is retured.

=head2 C<bars( ... )>

    my $bars = $camelid->bars(
        symbol    => 'MSFT',
        timeframe => '1Min',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

Returns a list of Finance::Alpaca::Struct::Bar objects along with other data.

The bar endpoint serves aggregate historical data for the requested securities.

The following parameters are accepted:

=over

=item C<symbol> - The symbol to query for; this is required

=item C<start> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<end> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<limit> - Number of data points to return. Must be in range C<1-10000>, defaults to C<1000>

=item C<page_token> - Pagination token to contine from

=item C<timeframe> - Timeframe for the aggregation. Available values are: C<1Min>, C<1Hour>, and C<1Day>; this is required

=back

The data returned includes the following data:

=over

=item C<bars> - List of Finance::Alpaca::Struct::Bar objects

=item C<next_page_token> - Token that can be used to query the next page

=item C<symbol> - Symbol that was queried

=back

=head2 C<quotes( ... )>

    my $quotes = $camelid->quotes(
        symbol    => 'MSFT',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

Returns a list of Finance::Alpaca::Struct::Quote objects along with other data.

The bar endpoint serves quote (NBBO) historical data for the requested
security.

The following parameters are accepted:

=over

=item C<symbol> - The symbol to query for; this is required

=item C<start> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<end> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<limit> - Number of data points to return. Must be in range C<1-10000>, defaults to C<1000>

=item C<page_token> - Pagination token to contine from

=back

The data returned includes the following data:

=over

=item C<quotes> - List of Finance::Alpaca::Struct::Quote objects

=item C<next_page_token> - Token that can be used to query the next page

=item C<symbol> - Symbol that was queried

=back

=head2 C<trades( ... )>

    my $trades = $camelid->trades(
        symbol    => 'MSFT',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

Returns a list of Finance::Alpaca::Struct::Trade objects along with other data.

The bar endpoint serves  historcial trade data for a given ticker symbol on a
specified date.

The following parameters are accepted:

=over

=item C<symbol> - The symbol to query for; this is required

=item C<start> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<end> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<limit> - Number of data points to return. Must be in range C<1-10000>, defaults to C<1000>

=item C<page_token> - Pagination token to contine from

=back

The data returned includes the following data:

=over

=item C<trades> - List of Finance::Alpaca::Struct::Quote objects

=item C<next_page_token> - Token that can be used to query the next page

=item C<symbol> - Symbol that was queried

=back

=head2 C<stream( ... )>

    my $stream = $camelid->stream( sub ($packet) {  ... } );
    $stream->subscribe(
        trades => ['MSFT']
    );

Returns a new Finance::Alpaca::Stream object.

You are ready to receive real-time market data!

You can send one or more subscription messages (described in
Finance::Alpaca::Stream) and after confirmation you will receive the
corresponding market data.

This method expects a code reference. This callback will recieve all incoming
data.

=head2 C<orders( [...] )>

    my $orders = $camelid->orders( status => 'open' );

Returns a list of Finance::Alpaca::Struct::Order objects.

The orders endpoint returns a list of orders for the account, filtered by the
supplied parameters.

The following parameters are accepted:

=over

=item C<status> - Order status to be queried. C<open>, C<closed>, or C<all>. Defaults to C<open>.

=item C<limit> - The maximum number of orders in response. Defaults to C<50> and max is C<500>.

=item C<after> - The response will include only ones submitted after this timestamp (exclusive.)

=item C<until> - The response will include only ones submitted until this timestamp (exclusive.)

=item C<direction> - The chronological order of response based on the submission time. C<asc> or C<desc>. Defaults to C<desc>.

=item C<nested> - Boolean value indicating whether the result will roll up multi-leg orders under the C<legs( )> field of the primary order.

=item C<symbols> - A comma-separated list of symbols to filter by (ex. C<AAPL,TSLA,MSFT>).

=back

=head2 C<order_by_id( ..., [...] )>

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4');

Returns a Finance::Alpaca::Struct::Order object.

You must provide the order's C<id> (UUID). If the order is not found, an empty
list is retured.

You may also provide a boolean value; if true, the result will roll up
multi-leg orders unter the C<legs( )> field in primary order.

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4', 1);

=head2 C<order_by_client_id( ... )>

    my $order = $camelid->order_by_client_id('17ff6b86-d330-4ac1-808b-846555b75b6e');

Returns a Finance::Alpaca::Struct::Order object.

You must provide the order's C<client_order_id> (UUID). If the order is not
found, an empty list is retured.

=head2 C<submit_order( ... )>

    my $order = $camelid->submit_order(
        symbol => 'MSFT',
        qty    => .1,
        side   => 'buy',
        type   => 'market',
        time_in_force => 'day'
    );

If the order is placed successfully, this method returns a
Finance::Alpaca::Struct::Order object. Failures result in hash references with
data from the API.

An order request may be rejected if the account is not authorized for trading,
or if the tradable balance is insufficient to fill the order.

The following parameters are accepted:

=over

=item C<symbol> - symbol or asset ID to identify the asset to trade (Required)

=item C<qty> - number of shares to trade. Can be fractionable for only C<market> and C<day> order types (Required)

=item C<notional> -dollar amount to trade. Cannot work with qty. Can only work for C<market> order types and C<day> for time in force (Required)

=item C<side> - C<buy> or C<sell> (Required)

=item C<type> - C<market>, C<limit>, C<stop>, C<stop_limit>, or C<trailing_stop> (Required)

=item C<time_in_force> - C<day>, C<gtc>, C<opg>, C<cls>, C<ioc>, C<fok>. Please see L<Understand Orders|https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force> for more info (Required)

=item C<limit_price> - Required if C<type> is C<limit> or C<stop_limit>

=item C<stop_price> - Required if C<type> is C<stop> or C<stop_limit>

=item C<trail_price> - This or C<trail_percent> is required if C<type> is C<trailing_stop>

=item C<trail_percent> - This or C<trail_price> is required if C<type> is C<trailing_stop>

=item C<extended_hours> - If a C<true> value, order will be eligible to execute in premarket/afterhours. Only works with C<type> is C<limit> and C<time_in_force> is C<day>

=item C<client_order_id> - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.

=item C<order_class> - C<simple>, C<bracket>, C<oco> or C<oto>. For details of non-simple order classes, please see L<Bracket Order Overview|https://alpaca.markets/docs/trading-on-alpaca/orders#bracket-orders>

=item C<take_profit> - Additional parameters for C<take_profit> leg of advanced orders

=over

=item C<limit_price> - Required for bracket orders

=back

=item C<stop_loss> - Additional parameters for stop-loss leg of advanced orders

=over

=item C<stop_price> - Required for braket orders

=item C<limit_price> - The stop-loss order becomes a stop-limit order if specified

=back

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
