[![Build Status](https://travis-ci.com/sanko/Finance-Alpaca.svg?branch=master)](https://travis-ci.com/sanko/Finance-Alpaca) [![MetaCPAN Release](https://badge.fury.io/pl/Finance-Alpaca.svg)](https://metacpan.org/release/Finance-Alpaca)
# NAME

Finance::Alpaca - It's new $module

# SYNOPSIS

    use Finance::Alpaca;

# DESCRIPTION

Finance::Alpaca is ... still under construction.

# METHODS

## `new( keys =` \[...\] )>

    my $camelid = Finance::Alpaca->new(
        keys => [ 'MDJOHHAE5BDE2FAYAEQT',
                  'Xq9p6ovxaa5XKihaEDRgpMapjeWYd5gIM63iq5BL'
                ] );

Creates a new Finance::Alpaca object.

Every API call requires authentication. API keys can be acquired in the
developer web console.

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

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
