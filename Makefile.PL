#!/usr/bin/perl
# $File: //member/autrijus/Acme-ComeFrom/Makefile.PL $ $Author: autrijus $
# $Revision: #4 $ $Change: 8742 $ $DateTime: 2003/11/08 06:18:43 $

use 5.005;
use inc::Module::Install;

name		('Acme-ComeFrom');
author		('Autrijus Tang (autrijus@autrijus.org)');
abstract	('Parallel goto-in-reverse');
version_from	('lib/Acme/ComeFrom.pm');
license		('perl');
requires	(
    'Filter::Simple'	=> '0.70',
    'Hook::LexWrap'	=> '0.20',
);
sign		(1);
include_deps	('Test::More', 5.005);
build_requires	('Test::More', 0);

&Meta->write;
&Makefile->write;
