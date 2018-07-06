NAME
====

P6Repl::Helpers - Convenience functions to help with introspecting objects from Perl6 REPL.

SYNOPSIS
========

    # Install it
    $ zef install P6Repl::Helpers

    # Run the Perl6 REPL with it
    $ perl6 -M P6Repl::Helpers

    # Or, load it from the REPL
    $ perl6
    > use P6Repl::Helpers;

DESCRIPTION
===========

P6Repl::Helpers provides functions to help you explore Perl6 packages (package/module/class/role/grammar) from the REPL.

EXAMPLES
========

    # Show the GLOBAL package
    > our sub mysub { 123 }; ls GLOBAL

    # Show only names in the CORE module that have "str" in them
    > ls CORE, :name(/str/)

    # Show all s* subs and their multi candidates if any.
    > ls CORE, :name(/^\&s/), :long

    # You can also filter on the objects themselves.
    # E.g., show only CORE types(class, role, or grammar)
    #
    > ls CORE, :value(Class-ish)

    # Show only non-sub instances in CORE
    > ls CORE, :name({$^k !~~ /^\&/}), :value({$^obj.DEFINITE})

    # Show Str's methods that begins with 'ch'. 'll' is like 'ls' but with :long.
    > ll Str, :name(/^ch/)

    # By default only local methods are matched against; specify :all to match
    # against inherited methods as well.
    #
    > ll Str, :name(/fmt/), :all

    # Specifying :gather returns a Seq of Pairs
    > ls CORE, :name(/^\&sp/), :gather ==> { .value.&ls for $_ }()


    # Once you get a hold of a sub or a method, you can use &doc to open its
    # documentation in a browser.
    > doc &substr

    > ls CORE, :name(/^\&s/), :numbered
    > doc (ls CORE, :name(/^\&s/), :take(21))

AUTHOR
======

Jack Kuan <kjkuan@gmail.com>

CONTRIBUTING
============

GitHub repo is at: https://github.com/kjkuan/P6Repl-Helpers

This is my first Perl6 module, written mainly to learn Perl6.
Therefore, any corrections/suggestions or help is highly apprecicated!

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Jack Kuan

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

