annibot
=======

Anniversary, birthday, nameday etc. Gmail (Google Contacts) reminder script in Perl.
----

This script:

1. Logs into your Gmail account.
1. Grabs all your contacts.
1. Finds all anniversaries, birthdays etc. -- everything that is a date (`X-ABDate`).
1. Notifies you about all upcoming events in 0, 1, 2, 3, 7, 14, 21 and 28 days -- no chance to miss a thing!

How to install
----
1. Clone this repo: `$ git clone https://github.com/michalrus/annibot.git`.
1. Copy `config.cfg.sample` to `config.cfg` and modify it to suit your needs.
1. Test `./run`, install missing Perl modules if any.
1. Add `./run` to your crontab: `$ crontab -e` and append something like `2 * * * * /your/path/to/annibot/run` to it (no need to run it more than once a day -- output varies between subsequent days only).

Bugs/features
----

Pull request are welcome if you want to add a date field explicitly or something.

Licensing
----

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).


Screenshots
----

![annibot Gmail screenshot][1]


  [1]: http://i.imgur.com/JLp1tOG.png
