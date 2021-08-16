#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;

my $d = HTTP::Daemon->new('LocalPort' => 8080, 'ReusePort' => 1) || die;
my $conn_attempts;
my $html = '<!DOCTYPE HTML><html><head><title>RFC 2616 : 8.2.4 Test</title>';
# prevent favico request
$html = $html . '<link rel="shortcut icon" href="data:image/x-icon;," type="image/x-icon"></head>';
$html = $html . '<body>';
$html = $html . '<script>function doit() { var r=new XMLHttpRequest();r.open("POST", "http://localhost:8080",true);r.send();}</script>';
$html = $html . '<button onclick="javascript:doit()">do it!</button>';
$html = $html . '</body>';

my $resp = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/html; charset=UTF-8' ], $html );
print "Started up OK, waiting for connections...\n";
while ( my $c = $d->accept ) {
    $conn_attempts = 0;
    while ( my $r = $c->get_request ) {
        print "receiving request " . $r->method . " on path " . $r->uri->path . "\n";
	if ( $r->method eq 'GET' and $r->uri->path eq "/" ) {
            $c->send_response($resp);
        } elsif ( $r->method eq 'POST' and $r->uri->path eq "/" ) {
            if ( $conn_attempts == 1 ) { # Reset connection
                print "Simulating long-processing operation...\n";
                sleep(3);
                print "Resetting connection before the result is send back, to test for RFC 2616 : 8.2.4 compliance...\n";
                $c->close;
                $c = $d->accept;
            } else {
                $c->send_response($resp);
            }
        }
        else {
            $c->send_error(RC_FORBIDDEN)
        }
        $conn_attempts++;
    }
    $c->close;
    undef($c);
}
