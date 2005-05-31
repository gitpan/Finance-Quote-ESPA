#! /usr/bin/perl -w
#*********************************************************************
#*** Finance::Quote::ESPA
#*** Copyright (c) 2004,2005 by Markus Winand <mws@fatalmind.com>
#*** $Id: ESPA.pm,v 1.2 2005/05/31 18:46:45 mws Exp $
#*********************************************************************
package Finance::Quote::ESPA;

use strict;
use LWP::UserAgent;
use vars qw/$VERSION $KEYURL $DATAURL/;

$VERSION = '1.00';
$KEYURL  = 'http://www.sparinvest.com/script/java/datadown$daten.asp';
$DATAURL = 'http://www.sparinvest.com/datenservices/ergebnis_datendownload.asp?format=EN&asids=IDS&beginn=STARTDATE&ende=ENDDATE';

sub methods { return (espa => \&espa); }
sub labels { return (espa => [qw/name date price last nav close p_change method/]); }

sub _getKeys($) {
	my ($quoter) = @_;
	my $ua = $quoter->user_agent;

	my $response = $ua->get($KEYURL);

	my $file = $response->content;
	$file =~ s///g; # dos2unix

	my %wkn;

	foreach my $line (split /\n/, $file) {
		my @record = split /;/, $line;
		if ($record[3] =~ /^(A?T?\d+)\s+(.*)\s+\((...)\)$/) {
			my $kn = _isin2wkn($1);
			my $variant = $2;
			my $currency = $3;
			$wkn{$kn} = $record[2];
		}
	}
	return \%wkn;
}

sub _isin2wkn($) {
	my ($isin) = @_;

	if ($isin =~ /^AT0000(.*).$/) {
		return $1;
	} else {
		return $isin;
	}
}

sub _nowDate($) {
	my ($offset) = @_;
	my @date = localtime(time() - (86400 * $offset));
	return sprintf("%04d%02d%02d", $date[5]+1900, $date[4]+1, $date[3]);
}

sub _getDataURL($@) {
	my ($quoter, @wkns) = @_;
	my $keys = Finance::Quote::ESPA::_getKeys($quoter);

	my @ids = map $keys->{Finance::Quote::ESPA::_isin2wkn($_)}, @wkns;;

	my $IDS = join(',', @ids);

	my $realurl = $DATAURL;
	$realurl =~ s/IDS/$IDS/;
	$realurl =~ s/STARTDATE/Finance::Quote::ESPA::_nowDate(7)/e;
	$realurl =~ s/ENDDATE/Finance::Quote::ESPA::_nowDate(0)/e;

	return $realurl;
}

sub _getData($$) {
	my ($quoter, $url) = @_;

	my $ua = $quoter->user_agent;
	my $response = $ua->get($url);
	my $file = $response->content;
	$file =~ s///g; # dos2unix
	my %result;

	foreach my $line (split /\n/, $file) {
		if ($line =~ /^AT/) {
			my @data = split /,/, $line;
			@data = map {s/^"(.*)"$/$1/; $_;} @data;
			my $wkn = Finance::Quote::ESPA::_isin2wkn($data[0]);
			my $newdata = {
				'name' => $data[1] . ' ' . $data[2] . ' ' . $data[5],
				'last' => $data[6],
				'date' => $data[4],
				'nav'  => $data[6],
				'price'=> $data[6],
				'success' => 1,
				'currency' => $data[5],
				'method' => 'espa'
			};
			if (defined $result{$wkn}) {
				$newdata->{'close'} = $result{$wkn}->{'last'};
				$newdata->{'net'}   = ($newdata->{'last'}*100 - $result{$wkn}->{'last'}*100)/100;
				if ($newdata->{'close'} > 0) {
					$newdata->{'p_change'} = $newdata->{'net'}/$newdata->{'close'}*100;
				}
			}
			$result{$wkn} = $newdata;
		}	
	}
	return \%result;
}

sub espa($@) {
	my ($quoter, @wkns) = @_;
	my $dataurl = Finance::Quote::ESPA::_getDataURL($quoter, @wkns);
	my $resultbywkn = Finance::Quote::ESPA::_getData($quoter, $dataurl);

	# now remap the result to match the query
	my %result;
	foreach my $request (@wkns) {
		my $wkn = Finance::Quote::ESPA::_isin2wkn($request);
		if (defined $resultbywkn->{$wkn}) {
			foreach my $key (keys %{$resultbywkn->{$wkn}}) {
				$result{$request, $key} = $resultbywkn->{$wkn}->{$key};
			}
		} else {
			$result{$request, 'success'} = undef;
		}
	}
	return wantarray() ? %result : \%result;
}

1;

=head1 NAME

Finance::Quote::ESPA - Obtain quotes from Erste-Sparinvest KAG. 

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new('ESPA');

    %stockinfo = $q->fetch("espa","AT0000813001");

=head1 DESCRIPTION

This module obtains information for ESPA funds directly from the issuer.
The quotes are taken from dataservices section of the international webpage
http://www.sparinvest.com/. 

=head1 LABELS RETURNED

The following labels may be returned by Finance::Quote::ESPA:
name date price last nav close p_change method.

=head1 SEE ALSO

Erste-Sparinvest KAG http://www.sparinvest.com/

=head1 AUTHOR

   Copyright (C) 2004,2005 by Markus Winand <mws@fatalmind.com>

   This program is free software; you can redistribute it and/or
   modify it under the same terms as Perl itself.

=cut
