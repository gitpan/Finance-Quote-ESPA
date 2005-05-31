#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2004,2005 by Markus Winand <mws@fatalmind.com>
#*** $Id: Makefile.PL,v 1.2 2005/05/31 18:46:43 mws Exp $
#*********************************************************************

use ExtUtils::MakeMaker qw(prompt WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts;

$opts{NAME}      = 'Finance::Quote::ESPA',
$opts{VERSION}   = '1.01';
$opts{PREREQ_PM} = {'Finance::Quote'};

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT} = 'Erste Sparinvest KAG Funds Quotes';
    $opts{AUTHOR} = 'Markus Winand <mws@fatalmind.com>';
}

WriteMakefile(%opts);

