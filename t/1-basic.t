#!/usr/bin/perl -w
# $File: //member/autrijus/Acme-ComeFrom/t/1-basic.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 3587 $ $DateTime: 2002/03/29 13:59:48 $

use strict;
use subs 'fork';
use Test::More tests => $] >= 5.007 ? 6 : 8;

BEGIN { use_ok('Acme::ComeFrom') }

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

comefrom(expr0);		# this causes a fork

no Acme::ComeFrom;		# removes filtering
normal: OK('(disabled)');	# this will run

if ($] eq "Perl") {		# the glory!
    NOK('(disabled)')		# but this will not
}

use Acme::ComeFrom;		# instantialize it agian

{
    my $i = 0;

    dumm0: 0;			# increases $i
    expr1: NOK('uncached EXPR');
    if ($] eq "Parrot") {	# yikes
	comefrom 'expr'.$i++;	# coming from expr1:
	OK('uncached EXPR');	# and OKs the test
    }
}

__END__
