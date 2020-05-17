#!/usr/bin/env perl

# Author: William B
# Email: toadwarrior@gmail.com
# Date: 2014-Nov-09
# Copyright (c) 2014-2020 All Rights Reserved https://github.com/wb-towa/ImgCrawl
#
# GPL v3 licence
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# TODO:
#
# - Coloured messages should be handled by functions
# - The Imgur Api call code needs attending to
# - Handle Imgur Albums
# - Handle Flickr links
# - Log pages to review for scraping / api calls
# - Log errors with possibly some being done in such
#   a way that I can query such errors to ignore retrying
#

package WallCrawl;

use 5.18.2;
use strict;
use warnings;
use LWP::Simple qw(get getstore);
use LWP::UserAgent;
use JSON;
use File::Path qw(make_path);
use Term::ANSIColor;

use Data::Dumper;

our $VERSION = 1.00;


sub new {
    # Expected params:
    # Reddit json url to query for images
    # Imgur Client ID
    # Imgage Save Folder
    my $class = shift;
    my $self = {
        _json_url => shift,
        _imgur_key => shift,
        _save_dir => shift,
        _user_agent => "WallCrawl/1.0"
    };

    bless $self, $class;

    return $self;

}

sub isImgur {

    my $self = shift;
    my $path = shift;

    if ($path =~ /imgur/) {
        return 1;
    } else {
        return 0;
    }
}

sub isImageLink {

    my $self = shift;
    my $path = shift;

    if ($path =~/\.(jpg|jpeg|gif|gif|bmp)$/i) {
        return 1;
    } else {
        return 0;
    }
}

sub getImgurlImageUrl {

    # API Info https://api.imgur.com/

    my $self = shift;
    my $path = shift;
    my @imgurId = split("/", $path);

    if (scalar(@imgurId) > 0) {

        my $ua = LWP::UserAgent->new;
        $ua->default_header("Authorization" => "Client-ID $self->{_imgur_key}");
        $ua->agent($self->{_user_agent});

        my $response = $ua->get("https://api.imgur.com/3/image/$imgurId[-1]");

        if ($response->is_success) {
            my $jsonDecoded = from_json($response->decoded_content);

            if ($jsonDecoded->{success}) {
                return $jsonDecoded->{data}->{link};
            } else {
                print Dumper($jsonDecoded);
                die "Imgur api call failed!";
            }
        } else {
            if ($response->{_rc} == 404) {
                print colored(":-( ", 'bold red'),  "File not found - maybe an album\n";
                return undef;
            } else {
                print Dumper($response);
                print "\n\n";
                die $response->status_line;
            }
        }
    } else {
        # TODO: handle bad string
        return undef;
    }
}

sub saveImage {

    my $self = shift;
    my $imageUrl = shift;
    my $imageName = $self->getFilename($imageUrl);

    if (defined($imageName)) {

        my $savePath = $self->{_save_dir}.$imageName;

        if (!$self->fileCheck($savePath)) {

            print colored(":-) ", 'bold green'), "Saving  $savePath\n";
            getstore($imageUrl, $savePath);

        } else {
            print colored(":-| ", 'bold yellow'), "Skipping -  $savePath already exists\n";
        }

    } else {
        # TODO: Log bad urls
        print colored(":-( ", 'bold red'), "Failed to get image filename from $imageUrl\n";
    }

}

sub dirCheck {

    my $self = shift;
    my $path = shift;

    if (-d $path) {
        return 1;
    } else {
        return 0;
    }
}

sub fileCheck {

    my $self = shift;
    my $path = shift;

    if (-f $path) {
        return 1;
    } else {
        return 0;
    }
}

sub getFilename {

    my $self = shift;
    my $path = shift;
    my @imgurId = split("/", $path);

    if (scalar(@imgurId) > 0) {
        return $imgurId[-1];
    } else {
        # TODO: handle bad string
        return undef;
    }
}

sub run {

    my $self = shift;

    print "\n[*] Crawling $self->{_json_url}\n\n";

    if (!$self->dirCheck($self->{_save_dir})) {
        mkdir $self->{_save_dir};
    }


    my $jsonStr = get($self->{_json_url});

    my $jsonDecoded = from_json($jsonStr);

    foreach my $item (@{$jsonDecoded->{data}->{children}}) {
        my $id =  $item->{data}->{id};
        my $url = $item->{data}->{url};

        if ($url =~/\.(jpg|jpeg|gif|gif|bmp|png)$/i) {

            $self->saveImage($url);

        } else {
            # TODO: Log page urls. Then inspect what I'm seeing and find ways to
            # get the image from that specific domain.

            print colored(":-( ", 'bold red'), "Page $url\n";

            if ($self->isImgur($url)) {

                print colored(":-) ", 'bold green'), "But it's an imgur link!\n";

                my $fromApiUrl = $self->getImgurlImageUrl($url);

                if (defined($fromApiUrl)) {
                    $self->saveImage($fromApiUrl);
                }

            }
        }

    }
    print "\n".scalar(@{$jsonDecoded->{data}->{children}})." submissions checked\n";
}

if (!caller) {
    print "[X] Quick test not implemented yet.\n";
}
1;
