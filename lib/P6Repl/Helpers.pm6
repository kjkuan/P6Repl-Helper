use v6.c;
unit module P6Repl::Helpers:ver<0.0.1>;

=begin pod

=head1 NAME

P6Repl::Helpers - Convenience functions to help with introspecting objects from Perl6 REPL.

=head1 SYNOPSIS

=begin code

# Install it
$ zef install P6Repl::Helpers

# Run the Perl6 REPL with it
$ perl6 -M P6Repl::Helpers

# Or, load it from the REPL
$ perl6
> use P6Repl::Helpers;

=end code

=head1 DESCRIPTION

P6Repl::Helpers provides functions to help you explore Perl6 packages
(package/module/class/role/grammar) from the REPL.

=head1 EXAMPLES
=begin code
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
=end code

=head1 AUTHOR

Jack Kuan <kjkuan@gmail.com>

=head1 CONTRIBUTING

This is my first Perl6 module, written mainly to learn Perl6;
therefore, any corrections/suggestions or help is highly apprecicated!

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Jack Kuan

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod


use Browser::Open;

%*ENV<P6_REPL_HELPERS_DOC_BASE_URL> //= "https://docs.perl6.org";


our subset Package is export where !.DEFINITE && .HOW ~~ Metamodel::PackageHOW;
our subset Module is export where !.DEFINITE && .HOW ~~ Metamodel::ModuleHOW;

# Package-ish things that can have methods
my @class-ish = do given Metamodel { $_.WHO<
    ClassHOW
    GrammarHOW
    CurriedRoleHOW
    ConcreteRoleHOW
    ParametricRoleHOW
    ParametricRoleGroupHOW
> }


our subset Class-ish is export where {
    !.DEFINITE && (
        (try .HOW ~~ any @class-ish) // False ||
        # (because some .HOW's in CORE has no matching ACCEPT's!)
        (.HOW.^name ~~ /^('Perl6::Metamodel::' | NQP) ClassHOW/)
    )
}


multi sub ns-iterator($obj where $_ ~~ Package|Module, *%opts --> Seq) {
    # .pairs works even when iterating CORE, which contains IterationEnd.
    gather given $obj { .take for .WHO.pairs }
}

multi sub ns-iterator(Class-ish $obj, *%opts --> Seq) {
    my $long = %opts<long>:delete;

    gather {
        given $obj { .take for .WHO.pairs }
        given $obj {
            for .^methods(|%opts) {
                next if $_ ~~ ForeignCode;
                take .name => $_;
                if $long  && .?is_dispatcher {
                    take (.name => $_) for .candidates;
                }
            }
            .take for .&anonymous-methods(:local(%opts<local>));
        }
    }
}

multi sub ns-iterator($obj, *%opts --> Seq) {
    gather take $obj.?name // '' => $obj;
}

sub anonymous-methods(Class-ish $obj, :$local=True) {
    my @pairs := do .HOW.method_table(Nil) for $obj.^mro[$local ?? 0 !! 0..^*-1];

    gather for flat @pairs {
        # skip private methods
        next if .key.starts-with('!');
        take $_ if .value ~~ ForeignCode;
    }
}



multi sub ls(
  $obj = GLOBAL,
  Mu :$name  = True,
  Mu :$value = Mu,
  #  Capture \cando,
  Bool:D :$all    = False,
  Bool:D :$local  = !$all,
  Bool:D :$long   = False,
  Mu :$take is raw,
  Bool:D :$gather = $take.DEFINITE,
  Bool:D :$numbered = False,

) is export
{
    gather for ns-iterator($obj, :$local, :$all, :$long) -> (Str :$key, :value($_)) {
        next if $key !~~ $name;

        # skip some NQP objects
        next if .WHAT !~~ Mu;

        # skip IterationEnd since it doesn't smartmatch.
        # (https://github.com/rakudo/rakudo/issues/1940)
        next if $_.WHICH === IterationEnd.WHICH;

        next if $_ !~~ $value;

        take $key => $_;
    } \
    ==> sort(*.key cmp *.key)
    ==> {
        if $gather {
            my \seq = gather .take for $_;
            if ! $take.DEFINITE {
                return seq;
            } else {
                given $take {
                    when Int { return seq[$take].value  }
                    default  { return seq[$take]».value }
                }
            }
        } else {
            for $_ {
                put $numbered ?? (+$++).fmt('%-2d ') !! '',
                    stringify-package-entry($obj, .key, .value, :$long);
            }
        }
    }();

}

multi sub stringify-package-entry(
    $package, $name is copy, Mu $obj,
    :$long
) {
    if $long {
        my $value-name = $obj.^name.subst(/^ $($package.^name) '::' /, '');
        $name = $value-name ~ " $name" if $name ne $value-name;
    }
    $name;
}

multi sub stringify-package-entry(
    $package, $name, Code:D $obj,
    :$long
) {
    my $entry = '';
    given $obj {
        if $long {
            given  $_ {
                when .?is_dispatcher { $entry ~= "proto " }
                when .?multi         { $entry ~= "multi " }
                default              { $entry ~= "only "  }
            }
            $entry ~= "{.^name.lc.subst(/\+.+$/, '')} "
        }
        $entry ~= $long ?? $name.subst(/^\&/, '') !! $name;
        try $entry ~= .signature.gist if $long;
    }
    return $entry;
}


multi sub ls(Mu:D \object, |c) { ls object.WHAT, |c }


# https://github.com/rakudo/rakudo/issues/1918
#our &ll is export = &ls.assuming(:long);
sub ll(|c) is export { ls(|c, :long) }


sub doc($object) is export {
    my $uri = do given $object {
        when Sub    { "routine/{.name}" }
        when Method {
            my $type-name = .package.^name;
            my $doc-type = &CORE::(.name) ?? 'routine' !! 'method';
            "type/$type-name#{$doc-type}_{.name}";
            #
            # NOTE: This is not always accurate. For example,
            #       Proc::Async has a 'say' method, but a different 'say' is a CORE sub.
        }
        default { "" }
    }
    #FIXME: add option show doc in a PAGER in the terminal?
    open-browser("%*ENV<P6_REPL_HELPERS_DOC_BASE_URL>/$uri");
}

sub src(Code $c) is export {
  my $srcpath = $*EXECUTABLE.parent.parent.parent.add($c.file.subst(/^SETTING '::'/, ''));
  run «view "+{$c.line}" "$srcpath"»;
}
