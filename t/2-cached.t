#!/usr/bin/perl -w
# $File: //member/autrijus/Acme-ComeFrom/t/2-cached.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 2431 $ $DateTime: 2001/11/26 10:59:24 $

use strict;
use Test::More tests => 2;

BEGIN { use_ok('Acme::ComeFrom') };

sub OK  { ok(1, "comefrom @_") }
sub NOK { ok(0, "comefrom @_") }

$Acme::ComeFrom::CacheEXPR = 0;	# shuts off warnings

{
    my $i = 1;
    $Acme::ComeFrom::CacheEXPR = 1;

    dumm0: 0;			# increases $i
    expr1: NOK('cached EXPR');
    if ($] eq "Parrot") {	# yikes
	comefrom 'expr'.$i++;	# coming from expr1:
	OK('cached EXPR');	# and OKs the test
    }
}

__END__
