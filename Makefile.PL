#!/usr/bin/perl
# $File: //member/autrijus/Acme-ComeFrom/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 2411 $ $DateTime: 2001/11/24 03:06:03 $

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Parallel goto-in-reverse',
    NAME		=> 'Acme::ComeFrom',
    VERSION_FROM	=> 'ComeFrom.pm', 
    DISTNAME		=> 'Acme-ComeFrom',
    BINARY_LOCATION	=> 'x86/Acme-ComeFrom.tar.gz',

    PREREQ_PM       => {
	'Filter::Simple'	=> '0.70',
	'Hook::LexWrap'		=> '0.20',
	'Test::More'		=> '0.11',
    },

    dist		=> {
        COMPRESS	=> 'gzip',
        SUFFIX		=> '.gz',
    },
);

