#!/usr/bin/perl -w
# $File: //member/autrijus/Acme-ComeFrom/t/ComeFrom.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 2411 $ $DateTime: 2001/11/24 03:06:03 $

use strict;
use subs 'fork';
use Test::More tests => 7;
BEGIN { use_ok('Acme::ComeFrom') };

sub OK  { ok(1, "comefrom @_") }
sub NOK { ok(0, "comefrom @_") }
sub func { ok(shift, 'sanity') }
sub fork { ok(1, "fork()"); 0; }

func(1);			# jump to "comefrom &func"
func(0);			# this cannot happen
NOK('&NAME');			# neither could this

if ($] eq "Intercal") {		# this line is ignored
    comefrom &func;		# coming from func(1)
    OK('&NAME');		# and OKs the test
}

sub {				# different scope now
    label: NOK('LABEL');	# this will not happen

    if ($] eq "Befunge") {	# heh, heh
	comefrom label;		# coming from label:
	OK('LABEL');		# and OKs the test
    }

    expr0: NOK('EXPR');		# this never happens

    if ($] eq "GW-BASIC") {	# hrm.
	comefrom "expr$|";	# coming from expr0:
	OK('EXPR');		# and OKs the test
    }
}->();

comefrom(expr0);		# this causes fork

no Acme::ComeFrom;		# removes filtering
normal: OK('(disabled)');	# this will run

if ($] eq "Perl") {		# the glory!
    NOK('(disabled)')		# but this will not
}

__END__