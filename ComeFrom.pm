# $File: //member/autrijus/Acme-ComeFrom/ComeFrom.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 2402 $ $DateTime: 2001/11/23 12:01:54 $

package Acme::ComeFrom;
$Acme::ComeFrom::VERSION = '0.02';

use strict;
use Filter::Simple 0.70;

=head1 NAME

Acme::ComeFrom - Parallel goto-in-reverse

=head1 SYNOPSIS

    use Acme::ComeFrom;

    sub func { print "@_" }; func("start\n");
    print "won't happen\n";

    comefrom &func; print "branch 1\n"; exit;
    comefrom &func; print "branch 2\n";

    label: print "won't happen either\n";

    comefrom label; print "branch 2.1\n"; exit;
    comefrom label; print "branch 2.2\n";
    
    expr0: print "to be\n"; exit;
    comefrom "expr".int(rand(2)); print "not to be\n";

=head1 DESCRIPTION

INTERCAL programmers have been for a long time monopolized the enormously
powerful construct C<COME FROM>, both as a flow-control replacement to
C<goto>, as well as an obvious way to mark parallel execution branches.

But now, with B<Acme::ComeFrom>, perl hackers finally could match them on
the front of wackiness, if not of obfuscation.

Just like C<goto>, C<comefrom> comes in three different flavors:

=over 4

=item comefrom LABEL

The C<comefrom-LABEL> form finds the statement labeled with LABEL and
jumps to the C<comefrom> just I<before> that statement's execution.
The C<comefrom> may not be within any construct that requires
initialization, such as a subroutine or a C<foreach> loop.

=item comefrom EXPR

The C<comefrom-EXPR> form expects a label name, whose scope will be
resolved dynamically.  This allows for computed C<comefrom>s by
checking the C<EXPR> before every labels (a.k.a. watchpoints), so
you could write ($i evaluates in the LABEL's scope):

    goto ("FOO", "BAR", "GLARCH")[$i];

Please note that the value of EXPR is frozen the first time it is
checked. This behaviour might change in the future.

=item comefrom &NAME

The C<comefrom-&NAME> form is quite different from the other forms of
C<comefrom>.  In fact, it isn't a comefrom in the normal sense at all,
and doesn't have the stigma associated with other C<comefrom>s.  Instead,
it installs a post-processing handler for the subroutine, so a jump
is made just I<after> the subroutine's execution.

=back

If two or more C<comefrom> applies to the same LABEL, EXPR or NAME,
they will be executed simultaneously via C<fork()>. The parent process
will receive the latest installed C<comefrom>.

=head1 BUGS

To numerous to be counted. This is only a prototype version.

=head1 ACKNOWLEDGEMENTS

To the INTERCAL language, the endless inspiration. As its manual said:
"The earliest known description of the COME FROM statement in the computing
literature is in [R. L. Clark, "A linguistic contribution to GOTO-less
programming," Commun. ACM 27 (1984), pp. 349-350], part of the famous April
Fools issue of CACM. The subsequent rush by language designers to include
the statement in their languages was underwhelming, one might even say
nonexistent.  It was therefore decided that COME FROM would be an appropriate
addition to C-INTERCAL."

To Maestro Damian Conway, the source of all magic bits in the B<Hook::LexWrap>
and B<Filter::Simple> modules, on which this module is based.

To Ton Hospel, for his tolerance on my semantic hackeries, and suggesting the
correct semantic of C<comefrom-LABEL> and C<comefrom-EXPR>.

=cut

FILTER_ONLY code => sub {
    my (%subs, %labs, @tokens, @counts);
    my $source = $_;
    my $count = "0000";

    $_ = $source and return unless $source =~ /comefrom/;

    while ($source =~ s/\bcomefrom\b\s*(&?)?([\w\:]+|[^\;]+)(?:\(\))?/__COME_FROM$count:/) {
	my $token = $2;

	push @{$subs{$token}}, $count++ and next if $1;
	push @{$labs{$token}}, $count++ and next if $token =~ /^[\w\:]+$/;
	push @tokens, $token;
	push @counts, $count++;
    }

    $_ = $source and return unless %subs or %labs or @tokens;

    my $code;

    while (my ($k, $v) = each %subs) {
	my $chunk = makechunk($v);
	require Hook::LexWrap 0.20;
	$code .= "Hook::LexWrap::wrap($k, post => sub { $chunk });";
    }

    if (@tokens) {
	$source =~ s!\n\s*([a-zA-Z_][a-zA-Z]\w+):!
	    my $label = $1;
	    my $chunk = makechunk(
		[ @counts, exists $labs{$label} ? @{$labs{$label}} : ()],
		$label, \@tokens
	    );

	    "$label: do { $chunk };"
	!eg;
    }
    else {
	while (my ($k, $v) = each %labs) {
	    my $chunk = makechunk($v);
	    $source =~ s/\Q$k\E:/$k: do { $chunk };/g;
	}
    }

    $_ = ($code ? "CHECK { $code; 1 };\n" : '') . $source;
};

sub makechunk {
    my $pkg = '$'.__PACKAGE__;
    my ($v, $label, $cond) = @_;
    my $chunk = '';

    foreach my $iter (0..$#{$v}-1) {
	if (defined $cond->[$iter]) {
	    $chunk .= qq{
		$pkg\::CACHE[$v->[$iter]]
		    = eval q;$cond->[$iter]; unless exists $pkg\::CACHE[$v->[$iter]];

		goto __COME_FROM$v->[$iter] unless
		    ('$label' ne $pkg\::CACHE[$v->[$iter]]) or fork;
	    };
	}
	else {
	    $chunk .= "goto __COME_FROM$v->[$iter] unless fork;";
	}
    }

    if (defined $cond->[$#{$v}]) {
	$chunk .= qq{
	    $pkg\::CACHE[$v->[-1]]
		= eval q;$cond->[$#{$v}-1]; unless exists $pkg\::CACHE[$v->[-1]];

	    goto __COME_FROM$v->[-1] unless
		('$label' ne $pkg\::CACHE[$v->[-1]]);
	};
    }
    else {
	$chunk .= "goto __COME_FROM$v->[-1];";
    }

    return $chunk;
}

1;

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
