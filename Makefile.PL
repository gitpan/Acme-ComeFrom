#!/usr/bin/perl
# $File: //member/autrijus/Acme-ComeFrom/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 2402 $ $DateTime: 2001/11/23 12:01:54 $

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
    },

    dist		=> {
        COMPRESS	=> 'gzip',
        SUFFIX		=> '.gz',
    },
);

