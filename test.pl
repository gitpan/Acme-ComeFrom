#!/usr/bin/perl -w
# $File: //member/autrijus/Acme-ComeFrom/test.pl $ $Author: autrijus $
# $Revision: #1 $ $Change: 2400 $ $DateTime: 2001/11/23 11:55:52 $

use strict;
use Test;

BEGIN { plan tests => 5 }

use Acme::ComeFrom;

ok(1);

sub func { ok(@_) }; func(1); ok(0);
comefrom &func; ok(1);

label: ok(0);
comefrom label; ok(1);

expr0: ok(0);
comefrom "expr".int(rand(1)); ok(1);

