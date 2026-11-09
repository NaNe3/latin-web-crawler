# Overview

This software is a web crawler written in Erlang that collects author information from The Latin Library website. It demonstrates the use of concurrent processes, HTTP requests, and HTML parsing using the fantastic tools provided by the Erlang toolset!
  
The purpose of this software is to automate the process of collecting author information from The Latin Library website, which would otherwise be a super duper tedious. It serves as a practical exercise in learning Erlang's concurrency model and handling web data programmatically.

[Software Demo Video](https://youtu.be/eln7RtYBZVc)

# Development Environment

I used the basic runtime and compilation tools provided by the Erlang website.

Additionally, I utilized the `inets` and `ssl` applications for handling HTTP requests and secure connections. The `re` module was used for regular expressions in the parsing of all the HTML stuff I had to deal with. 

# Useful Websites

* [ErLang Main Website](https://www.erlang.org/)
* [An Introduction for Beginners. Super Helpful!](https://elixirforum.com/t/modern-erlang-for-beginners-pragprog/20839)
* [TutorialsPoint - Another intro and documentation site](https://www.tutorialspoint.com/erlang/index.htm)

# Future Work

* Improve error handling for HTTP requests. As of now it is very basic!
* Enhance HTML parsing to handle edge cases. There were a ton of edge cases which I didn't cover due to restraints of time!
* Add support for more complex author link structures