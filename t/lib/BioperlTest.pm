# $Id$
#
# BioPerl module for BioperlTest
#
# Cared for by Sendu Bala <bix@sendu.me.uk>
#
# Copyright Sendu Bala
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

BioperlTest - A common base for all Bioperl test scripts.

=head1 SYNOPSIS

  use lib 't/lib';
  use BioperlTest;
  
  test_begin(-requires_modules => [qw(IO::String)],
             -requires_networking => 1,
             -tests => 20);

  my $do_network_tests = test_network();
  my $output_debugging = test_debug();

  # carry out tests in Test::More syntax

=head1 DESCRIPTION

This provides a common base for all Bioperl test scripts. It presents an
interface to common needs such as skipping all tests if required modules aren't
present or if network tests haven't been enabled.

It currently has two methods that let you decide if network tests should be
run, and if debugging information should be printed.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Sendu Bala

Email bix@sendu.me.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package BioperlTest;

use strict;
use warnings;

use Exporter qw(import);

BEGIN {
    # For prototyping reasons, we have to load Test::More's methods now, even
    # though theoretically in future the user may use a different Test framework
    
    # We want to load Test::More. Preferably the users own version, but if they
    # don't have it, the one in t/lib. However, this module is in t/lib so
    # t/lib is already in @INC so Test::More in t/lib will be used first, which
    # we don't want: get rid of t/lib in @INC
    no lib 't/lib';
    eval { require Test::More; };
    if ($@) {
        eval "use lib 't/lib';";
    }
    eval "use Test::More;";
}

# re-export Test::More methods and export our own
our @EXPORT = qw(ok use_ok require_ok
                 is isnt like unlike is_deeply
                 cmp_ok
                 skip todo todo_skip
                 pass fail
                 eq_array eq_hash eq_set
                 $TODO
                 plan
                 can_ok  isa_ok
                 diag
                 BAIL_OUT
                 
                 test_begin
                 test_network
                 test_debug);


=head2 test_begin

 Title   : test_begin
 Usage   : test_begin();
 Function: Begin your test script, setting up the plan (skip all tests, or run
           them all)
 Returns : True if tests should be run.
 Args    : -tests               => int (REQUIRED, the number of tests that will
                                        be run)
           -requires_modules    => []  (array ref of module names that are
                                        required; if any don't load, all tests
                                        will be skipped)
           -requires_networking => 1|0 (default 0, if true all tests will be
                                        skipped if network tests haven't been
                                        enabled in Build.PL)
           -framework           => str (default 'Test::More', the Test module
                                        to load. NB: experimental, avoid using)

=cut

sub test_begin {
    my %args = @_;
    my $tests = $args{'-tests'} || die "-tests must be supplied and positive\n";
    my $framework = $args{'-framework'} || 'Test::More';
    my @req_mods = @{$args{'-requires_modules'} || []};
    my $req_net = $args{'-requires_networking'};
    
    my $skip_all = '';
    my $requires = '';
    foreach my $mod (@req_mods) {
        $requires .= "require $mod; ";
    }
    eval $requires;
    if ($@) {
        $skip_all = "One or more of the optional modules ".join(', ', @req_mods)." not installed";
    }
    elsif ($req_net && ! test_network()) {
        $skip_all = 'Network tests have not been requested';
    }
    
    if ($framework eq 'Test::More') {
        # ideally we'd delay loading Test::More until this point, but see BEGIN
        # block
        
        if ($skip_all) {
            eval "plan skip_all => '$skip_all';";
        }
        else {
            eval "plan tests => $tests;";
        }
        
        return 1;
    }
    # go ahead and add support for other frameworks here
    else {
        die "Only Test::More is supported at the current time\n";
    }
    
    return 0;
}

=head2 test_network

 Title   : test_network
 Usage   : my $do_network_tests = test_network();
 Function: Ask if network tests should be run.
 Returns : boolean
 Args    : none

=cut

sub test_network {
    require Module::Build;
    my $build = Module::Build->current();
    return $build->notes('network');
}

=head2 test_debug

 Title   : test_debug
 Usage   : my $output_debugging = test_debug();
 Function: Ask if debugging information should be output.
 Returns : boolean
 Args    : none

=cut

sub test_debug {
    return $ENV{'BIOPERLDEBUG'} || 0;
}

1;