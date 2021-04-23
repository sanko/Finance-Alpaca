[![Build Status](https://travis-ci.com/sanko/Finance-Alpaca.svg?branch=master)](https://travis-ci.com/sanko/Finance-Alpaca) [![MetaCPAN Release](https://badge.fury.io/pl/Finance-Alpaca.svg)](https://metacpan.org/release/Finance-Alpaca)
# NAME

Finance::Alpaca - It's new $module

# SYNOPSIS

    use Finance::Alpaca;

# DESCRIPTION

Finance::Alpaca is ... still under construction.

# METHODS

## `new( ... )`

    my $camelid = Finance::Alpaca->new(
        keys => [ 'MDJOHHAE5BDE2FAYAEQT',
                  'Xq9p6ovxaa5XKihaEDRgpMapjeWYd5gIM63iq5BL'
                ] );

Creates a new Finance::Alpaca object.

This constructor accepts the following parameters:

- `keys` - `[ $APCA_API_KEY_ID, $APCA_API_SECRET_KEY ]`

    Every API call requires authentication. You must provide these keys which may
    be acquired in the developer web console and are only visible on creation.

- `paper` - Boolean value

    If you're attempting to use Alpaca's paper trading functionality, this **must**
    be a true value. Otherwise, you will be making live trades with actual assets.

    **Note**: This is a false value by default.

## `account( )`

Returns a Finance::Alpaca::Struct::Account object.

The account endpoint serves important information related to an account,
including account status, funds available for trade, funds available for
withdrawal, and various flags relevant to an account’s ability to trade.

## `clock( )`

    my $clock = $camelid->clock();
    say sprintf
        $clock->timestamp->strftime('It is %l:%M:%S %p on a %A and the market is %%sopen!'),
        $clock->is_open ? '' : 'not ';

Returns a Finance::Alpaca::Struct::Clock object.

The clock endpoint serves the current market timestamp, whether or not the
market is currently open, as well as the times of the next market open and
close.

## `calendar( [...] )`

Returns a list of Finance::Alpaca::Struct::Calendar objects.

The calendar endpoint serves the full list of market days from 1970 to 2029.

The following parameters are accepted:

- `start` - The first date to retrieve data for (inclusive); Time::Moment object or RFC3339 string
- `end` - The last date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

Both listed parameters are optional. If neither is provided, the calendar will
begin on January 1st, 1970.

## `assets( [...] )`

Returns a list of Finance::Alpaca::Struct::Asset objects.

The assets endpoint serves as the master list of assets available for trade and
data consumption from Alpaca.

The following parameters are accepted:

- `status` - e.g. `active`. By default, all statuses are included
- `asset_class` - Defaults to `us_equity`

## `asset( ... )`

    my $msft = $camelid->asset('MSFT');
    my $spy  = $camelid->asset('b28f4066-5c6d-479b-a2af-85dc1a8f16fb');

Returns a Finance::Alpaca::Struct::Asset object.

You may use either the asset's `id` (UUID) or `symbol`. If the asset is not
found, an empty list is retured.

## `bars( ... )`

    my $bars = $camelid->bars(
        symbol    => 'MSFT',
        timeframe => '1Min',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

Returns a list of Finance::Alpaca::Struct::Bar objects along with other data.

The bar endpoint serves aggregate historical data for the requested securities.

The following parameters are accepted:

- `symbol` - The symbol to query for; this is required
- `start` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `end` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `limit` - Number of data points to return. Must be in range `1-10000`, defaults to `1000`
- `page_token` - Pagination token to contine from
- `timeframe` - Timeframe for the aggregation. Available values are: `1Min`, `1Hour`, and `1Day`; this is required

The data returned includes the following data:

- `bars` - List of Finance::Alpaca::Struct::Bar objects
- `next_page_token` - Token that can be used to query the next page
- `symbol` - Symbol that was queried

## `quotes( ... )`

    my $quotes = $camelid->quotes(
        symbol    => 'MSFT',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

Returns a list of Finance::Alpaca::Struct::Quote objects along with other data.

The bar endpoint serves quote (NBBO) historical data for the requested
security.

The following parameters are accepted:

- `symbol` - The symbol to query for; this is required
- `start` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `end` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `limit` - Number of data points to return. Must be in range `1-10000`, defaults to `1000`
- `page_token` - Pagination token to contine from

The data returned includes the following data:

- `quotes` - List of Finance::Alpaca::Struct::Quote objects
- `next_page_token` - Token that can be used to query the next page
- `symbol` - Symbol that was queried

## `trades( ... )`

    my $trades = $camelid->trades(
        symbol    => 'MSFT',
        start     => Time::Moment->now->with_day_of_week(2),
        end       => Time::Moment->now->with_hour(12)->with_day_of_week(3)
    );

Returns a list of Finance::Alpaca::Struct::Trade objects along with other data.

The bar endpoint serves  historcial trade data for a given ticker symbol on a
specified date.

The following parameters are accepted:

- `symbol` - The symbol to query for; this is required
- `start` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `end` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `limit` - Number of data points to return. Must be in range `1-10000`, defaults to `1000`
- `page_token` - Pagination token to contine from

The data returned includes the following data:

- `trades` - List of Finance::Alpaca::Struct::Quote objects
- `next_page_token` - Token that can be used to query the next page
- `symbol` - Symbol that was queried

## `stream( ... )`

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

## `orders( [...] )`

    my $orders = $camelid->orders( status => 'open' );

Returns a list of Finance::Alpaca::Struct::Order objects.

The orders endpoint returns a list of orders for the account, filtered by the
supplied parameters.

The following parameters are accepted:

- `status` - Order status to be queried. `open`, `closed`, or `all`. Defaults to `open`.
- `limit` - The maximum number of orders in response. Defaults to `50` and max is `500`.
- `after` - The response will include only ones submitted after this timestamp (exclusive.)
- `until` - The response will include only ones submitted until this timestamp (exclusive.)
- `direction` - The chronological order of response based on the submission time. `asc` or `desc`. Defaults to `desc`.
- `nested` - Boolean value indicating whether the result will roll up multi-leg orders under the `legs( )` field of the primary order.
- `symbols` - A comma-separated list of symbols to filter by (ex. `AAPL,TSLA,MSFT`).

## `order_by_id( ..., [...] )`

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4');

Returns a Finance::Alpaca::Struct::Order object.

You must provide the order's `id` (UUID). If the order is not found, an empty
list is retured.

You may also provide a boolean value; if true, the result will roll up
multi-leg orders unter the `legs( )` field in primary order.

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4', 1);

## `order_by_client_id( ... )`

    my $order = $camelid->order_by_client_id('17ff6b86-d330-4ac1-808b-846555b75b6e');

Returns a Finance::Alpaca::Struct::Order object.

You must provide the order's `client_order_id` (UUID). If the order is not
found, an empty list is retured.

## `submit_order( ... )`

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

- `symbol` - symbol or asset ID to identify the asset to trade (Required)
- `qty` - number of shares to trade. Can be fractionable for only `market` and `day` order types (Required)
- `notional` -dollar amount to trade. Cannot work with qty. Can only work for `market` order types and `day` for time in force (Required)
- `side` - `buy` or `sell` (Required)
- `type` - `market`, `limit`, `stop`, `stop_limit`, or `trailing_stop` (Required)
- `time_in_force` - `day`, `gtc`, `opg`, `cls`, `ioc`, `fok`. Please see [Understand Orders](https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force) for more info (Required)
- `limit_price` - Required if `type` is `limit` or `stop_limit`
- `stop_price` - Required if `type` is `stop` or `stop_limit`
- `trail_price` - This or `trail_percent` is required if `type` is `trailing_stop`
- `trail_percent` - This or `trail_price` is required if `type` is `trailing_stop`
- `extended_hours` - If a `true` value, order will be eligible to execute in premarket/afterhours. Only works with `type` is `limit` and `time_in_force` is `day`
- `client_order_id` - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.
- `order_class` - `simple`, `bracket`, `oco` or `oto`. For details of non-simple order classes, please see [Bracket Order Overview](https://alpaca.markets/docs/trading-on-alpaca/orders#bracket-orders)
- `take_profit` - Additional parameters for `take_profit` leg of advanced orders
    - `limit_price` - Required for bracket orders
- `stop_loss` - Additional parameters for stop-loss leg of advanced orders
    - `stop_price` - Required for braket orders
    - `limit_price` - The stop-loss order becomes a stop-limit order if specified

## `replace_order( ..., ... )`

    my $new_order = $camelid->reaplace_order(
        $order->id,
        qty => 3,
        time_in_force => 'fok'
        limit_price => 120
    );

Replaces a single order with updated parameters. Each parameter overrides the
corresponding attribute of the existing order. The other attributes remain the
same as the existing order.

A success return code from a replaced order does NOT guarantee the existing
open order has been replaced. If the existing open order is filled before the
replacing (new) order reaches the execution venue, the replacing (new) order is
rejected, and these events are sent in the trade\_updates stream channel.

While an order is being replaced, buying power is reduced by the larger of the
two orders that have been placed (the old order being replaced, and the newly
placed order to replace it). If you are replacing a buy entry order with a
higher limit price than the original order, the buying power is calculated
based on the newly placed order. If you are replacing it with a lower limit
price, the buying power is calculated based on the old order.

In addition to the original order's ID, this method expects the following
parameters:

- `qty` - number of shares to trade
- `time_in_force` - `day`, `gtc`, `opg`, `cls`, `ioc`, `fok`. Please see [Understand Orders](https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force) for more info
- `limit_price` - required if `type` is `limit` or `stop_limit`
- `stop_price` - required if `type` is `stop` or `stop_limit`
- `trail` - the new value of the `trail_price` or `trail_percent` value (works only where `type` is `trailing_stop`)
- `client_order_id` - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
