#!/usr/bin/env perl

use 5.18.2;
use strict;
use warnings;

use WallCrawl;

use Test::Simple tests => 8;



my $urlString = "http://imgur.com/d3NpwB";
my $urlString2 = "http://i.imgur.com/d3NpwB.jpg";
my $urlString3 = "www.google.com";

my $crawler = WallCrawl->new("", "", "");

ok($crawler->isImgur($urlString) == 1, "isImgur() Sucess");

ok($crawler->isImgur($urlString3) == 0, "isImgur() Failure");

ok($crawler->isImageLink($urlString) == 0, "IsImageLink() Failure");

ok($crawler->isImageLink($urlString2) == 1, "IsImageLink() Success");

# XXX: Do not want to commit Client ID - put sensitive data in a config file
#ok($crawler->getImgurlImageUrl($urlString) eq 'https://api.imgur.com/3/image/d3NpwB/', "getImgurlImageUrl() Success");
#ok(defined($crawler->getImgurlImageUrl($urlString3)), "getImgurlImageUrl() Failure");

# XXX: Assumes run from project root
ok($crawler->dirCheck("./t") == 1, "dirCheck() Success");

ok($crawler->dirCheck("./cattle_hats") == 0, "dirCheck() Failure");

ok($crawler->fileCheck("./t/wallcrawl.t") == 1, "fileCheck() Success");

ok($crawler->fileCheck("./t/cattle_hats.txt") == 0, "fileCheck() Failure");

