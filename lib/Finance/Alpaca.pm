package Finance::Alpaca 1.00 {
    use strictures 2;
    use Moo;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use Mojo::UserAgent;
    use Types::Standard qw[ArrayRef InstanceOf Str Int];
    #
    use lib './lib/';
    use Finance::Alpaca::Struct::Account qw[to_Account];
    use Finance::Alpaca::Struct::Clock qw[to_Clock];
    use Finance::Alpaca::Struct::Calendar qw[to_Calendar];
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
    has endpoint => ( is => 'rw', isa => Str, default => 'https://paper-api.alpaca.markets' );
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
            $_ . '=' .
                ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/calendar' . $params );
        $tx = $s->ua->start($tx);
        return to_Calendar( $tx->result->json );
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

=head2 C<new( keys => [...] )>

    my $camelid = Finance::Alpaca->new(
        keys => [ 'MDJOHHAE5BDE2FAYAEQT',
                  'Xq9p6ovxaa5XKihaEDRgpMapjeWYd5gIM63iq5BL'
                ] );

Creates a new Finance::Alpaca object.

Every API call requires authentication. API keys can be acquired in the
developer web console.

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

Returns a Finance::Robinhood::Struct::Calendar object.

The calendar endpoint serves the full list of market days from 1970 to 2029.

The following parameters are accepted:

=over

=item C<start> - The first date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

=item C<end> - The last date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

=back

Both listed parameters are optional. If neither is provided, the calendar will
begin on January 1st, 1970.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
