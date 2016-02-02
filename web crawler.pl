#!/usr/bin/perl -w
use strict;

use LWP::UserAgent;
use HTTP::Request;
use JSON;
#use MediaWiki::API;
#use XML::Simple;
 
#create useragent and mediawiki objects - mediawiki linked to the edegan wiki
my $ua = new LWP::UserAgent;
#my $mwobject = MediaWiki::API->new({api_url=>'http://www.edegan.com/wiki/index.php'});
#set parameters by which the govtrack api will be searched
my $queryName = "Entrepreneurship";
my $congressNo = "114";
my $limit = "107";


my %termIDs = ('5914'=>1, '5918'=>1, '5935'=>1, '6769'=>1);
#create url using parameters and get data from url
my $genUrl = "https://www.govtrack.us/api/v2/bill?order_by=-current_status_date&congress=". $congressNo."&q=".$queryName."&limit=".$limit;
my $genResponse = $ua->get($genUrl);
my $response = $genResponse->decoded_content;
my $JSONcontent = decode_json($response); 

#open a text file in which to dump out results and convert text style from ASCII to utf8
open (LINK,">Links.txt"); # CREATE a text file 
open(SPONSOR,">Sponsors.txt");
#binmode(LINK, ":encoding(cp1252)");
print LINK "Bill Title\tLink\n";
print SPONSOR "Bill Title\tSponsor\tCosponsors\n";
foreach my $bill (@{$JSONcontent->{objects}}){
    #find out if bill is relevant
    my $billurl = "https://www.govtrack.us/api/v2/bill/" . $bill->{id};
    my $billresponse = $ua->get($billurl);
    my $decode = $billresponse->decoded_content;
    my $billcontent = decode_json($decode);
    my $count;
    foreach my $term (@{$billcontent->{terms}}){
        if(exists($termIDs{$term->{id}})){
            $count++;
        }
    }
    #if relevant add it to the text file
    if ($count>1) {
        #print STDOUT ($billcontent->{title}."\t".$billcontent->{link}."\n");
        my $billstring = clean_string($billcontent->{title}."\t".$billcontent->{link}). "\n";
        print LINK $billstring; # print to LINK 
        #print STDOUT $billcontent->{sponsor}->{firstname};
        $billstring = $billcontent->{title}."\t".$billcontent->{sponsor}->{firstname}." ".$billcontent->{sponsor}->{lastname}."\t";
        foreach my $cosponsor (@{$billcontent->{cosponsors}}){
            $billstring .= $cosponsor->{firstname}." ".$cosponsor->{lastname}."\t";
        }
        chop($billstring);
        print SPONSOR clean_string($billstring)."\n";
        #my %billoutput = ()
        #print DUMP (XMLout($billcontent)."\n===========\n");
    }
    
}
close LINK;
print "done";
sub clean_string{
    my $istring = shift @_;
    while ($istring =~/[^A-z0-9\s.:\/,]/){
        $istring=~ s/[^A-z0-9\s.:\/,]//;
    }
    return $istring
}
