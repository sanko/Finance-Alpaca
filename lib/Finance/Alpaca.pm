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
    use Finance::Alpaca::Struct::Bar qw[Bar];
    use Finance::Alpaca::Struct::Clock qw[to_Clock];
    use Finance::Alpaca::Struct::Calendar qw[to_Calendar Calendar];
    use Finance::Alpaca::Struct::Quote qw[Quote];

    #
    has ua => ( is => 'lazy', isa => InstanceOf ['Mojo::UserAgent'] );

    sub _build_ua ($s) {
        my $ua = Mojo::UserAgent->new;
        $ua->on(
            start => sub ( $ua, $tx ) {
                $tx->req->headers->header( 'X-Bender'            => 'Bite my shiny metal ass!' );
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
};
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

If you're attempting to use Alpaca's paper trading functionality, this must be
a true value. Otherwise, you will be making live trades with actual assets.

This is an untrue value by default.

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


=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
