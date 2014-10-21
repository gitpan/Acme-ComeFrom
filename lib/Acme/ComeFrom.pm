# $File: //member/autrijus/Acme-ComeFrom/lib/Acme/ComeFrom.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 8743 $ $DateTime: 2003/11/08 06:20:52 $

package Acme::ComeFrom;
$Acme::ComeFrom::VERSION = '0.07';

use strict;
use vars qw/$CacheEXPR/;
use Filter::Simple 0.70;

=head1 NAME

Acme::ComeFrom - Parallel goto-in-reverse

=head1 VERSION

This document describes version 0.07 of Acme::ComeFrom, released
November 8, 2002.

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

B<INTERCAL> programmers have for a long time monopolized the enormously
powerful construct C<COME FROM>, both as a flow-control replacement to
C<goto>, and as a simple way to mark parallel execution branches in
the multi-thread variant.

But now, with B<Acme::ComeFrom>, we perl hackers could finally be on par
with them in terms of wackiness, if not in obfuscation.

Just like C<goto>, C<comefrom> comes in three different flavors:

=over 4

=item comefrom LABEL

The C<comefrom-LABEL> form finds the statement labeled with LABEL and
jumps to the C<comefrom> each time just I<before> that statement's
execution.  The C<comefrom> may not be inside any construct that
requires initialization, such as a subroutine or a C<foreach> loop,
unless the targeting LABEL is also in the same construct.

=item comefrom EXPR

The C<comefrom-EXPR> form expects a label name, whose scope will be
resolved dynamically.  This allows for computed C<comefrom>s by
checking the C<EXPR> before every label (a.k.a. watchpoints), so
you could write ($i evaluates in the LABEL's scope):

    comefrom ("FOO", "BAR", "GLARCH")[$i];

Starting from version 0.05, the value of EXPR is evaluated each
time, instead of the old 'frozen at the first check' behaviour.  If
this breaks your code -- as if there's any code based on comefrom --
You may retain the original behaviour by assigning a true value
to C<$Acme::ComeFrom::CacheEXPR>.

=item comefrom &NAME

The C<comefrom-&NAME> form is quite different from the other forms of
C<comefrom>.  In fact, it isn't a comefrom in the normal sense at all,
and doesn't have the stigma associated with other C<comefrom>s.  Instead,
it installs a post-processing handler for the subroutine, and a jump
would be made just I<after> the subroutine's execution.

=back

If two or more C<comefrom> were applied to the same LABEL, EXPR or NAME,
they will be executed simultaneously via C<fork()>.  The forking are
ordered by their occurrances, with the parent process receiving
the last one.

=head1 BUGS

This module does not really parse perl; it guesses label names quite
accurately, but the regex matching the C<comefrom> itself could catch
many false-positives. I'm looking forward for ways to change that.

=cut

my $Mark  = '__COME_FROM';
my $count = '0000';

FILTER_ONLY code => sub {
    my (%subs, %labs, @tokens, @counts);
    my $source = $_;

    $_ = $source and return unless $source =~ /comefrom/;

    while ($source =~ s/\bcomefrom\b\s*\(?(&?)?([\w\:]+|[^\;]+)(?:\(\))?\)?/$Mark$count:/) {
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
	require Hook::LexWrap;
	$code .= "Hook::LexWrap::wrap($k, post => sub { $chunk });";
    }

    if (@tokens) {
	$source =~ s!\n[\s\t]*([a-zA-Z_]\w+):!
	    my $label = $1;
	    my $chunk = makechunk(
		[ @counts, exists $labs{$label} ? @{$labs{$label}} : ()],
		$label, \@tokens
	    ) unless substr($label, 0, length($Mark)) eq $Mark;

	    $chunk ? "\n$label: do { $chunk };" : "\n$label:";
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

    foreach my $iter (0 .. $#{$v}) {
	my $fork = ($iter != $#{$v});

	if (defined $cond->[$iter]) {
	    my $forktext = ($fork ? " or fork" : '');

	    $chunk .= "
		if (\$Acme::ComeFrom::CacheEXPR) {
		    $pkg\::CACHE[$v->[$iter]] = eval q;$cond->[$iter];
			unless exists $pkg\::CACHE[$v->[$iter]];

		    goto $Mark$v->[$iter] unless
			('$label' ne $pkg\::CACHE[$v->[$iter]])$forktext;
		}
		else {
		    goto $Mark$v->[$iter] unless
			('$label' ne eval q;$cond->[$iter];)$forktext;
		}
	    ";
	}
	else {
	    $chunk .= "goto $Mark$v->[$iter]"
		    . ($fork ? " unless fork;" : ';');
	}
    }

    return $chunk;
}

1;

=head1 ACKNOWLEDGEMENTS

To the B<INTERCAL> language, for its endless inspiration.

As its manual states:
"The earliest known description of the COME FROM statement in the computing
literature is in [R. L. Clark, "A linguistic contribution to GOTO-less
programming," Commun. ACM 27 (1984), pp. 349-350], part of the famous April
Fools issue of CACM. The subsequent rush by language designers to include
the statement in their languages was underwhelming, one might even say
nonexistent.  It was therefore decided that COME FROM would be an appropriate
addition to C-INTERCAL."

To Maestro Damian Conway, the source of all magic bits in B<Hook::LexWrap>
and B<Filter::Simple>, on which this module is based.

To Ton Hospel, for his tolerance on my semantic hackeries, and suggesting
the correct behaviour of C<comefrom-LABEL> and C<comefrom-EXPR>.

=head1 SEE ALSO

L<Hook::LexWrap>, L<Filter::Simple>, L<perlfunc/goto>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2002, 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
