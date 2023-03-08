# pl-IPBoardBruteforce

# Description
This Perl script is designed for brute-forcing login credentials for a forum. It takes the URL of the login page and the number of threads as arguments. The script reads from text files containing login usernames, passwords, and user agents, and generates login combinations to be used in the brute-forcing process. The script then uses the LWP::UserAgent module to send HTTP GET and POST requests to the login page and attempts to login using the generated login combinations. If a successful login is made, the script outputs the login credentials to the console.

# Dependencies
* Perl 5
* LWP::UserAgent
* Coro
* Coro::Select
* File::Slurp

# Usage

```bash
perl bruteforce.pl http://site.com/ 10
```

* http://site.com/: the URL of the login page
* 10: the number of threads to use (optional)

## The script also requires the following text files in the same directory:

* logins.txt: contains a list of login usernames, one per line
* passwords.txt: contains a list of passwords, one per line
* user-agents.txt: contains a list of user agents, one per line

# Note
The use of this script for malicious purposes is strictly prohibited.
