#!/usr/bin/perl

use strict;
use warnings;

use PDF::API2::Lite;
use Sort::Naturally;

for my $argv ( @ARGV ) {
my $dir = $argv;

opendir my $dh, $dir
    or next; # die "Can't opendir '$dir': $!";
my @img = grep -f "$dir/$_" && /\.([Jj][Pp][Ee]?[Gg]|[Pp][Nn][Gg]|[Tt][Ii][Ff][Ff]?)$/i, readdir $dh;
closedir $dh
    or die "Can't closedir '$dir': $!";

my $pdf = PDF::API2::Lite->new;
my @_img = nsort @img;

for my $img ( @_img ) {
print "$img\n";
    my $image;
    if ($img =~ /\.[Jj][Pp][Ee]?[Gg]$/) {
	$image = $pdf->image_jpeg( "$dir/$img" );
    } elsif ($img =~ /\.[Pp][Nn][Gg]$/) {
	$image = $pdf->image_png( "$dir/$img" );
    } elsif ($img =~ /\.[Tt][Ii][Ff][Ff]?$/) {
	$image = $pdf->image_tiff( "$dir/$img" );
    }
    $pdf->page( $image->width, $image->height );
    $pdf->image( $image, 0, 0 );
}
print "@_img => $dir\n";
$pdf->saveas( "$dir.pdf" );
}
