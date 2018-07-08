use v6.c;
use Test;
use Test::Output;

use P6Repl::Helper;

plan 9;

module MyModule {
    our $myvar = 123;
    our sub mysub(Int $i --> Int) { $i + 1 }

    class MyClass {
        our $classvar = 456;
        method my-method-a { ... }
        method my-method-b($a, *@args, *%opts) { ... }
        multi method my-multi($a) { ... }
        multi method my-multi($a, $b) { ... }
    }
}

is (output-from { ls MyModule::MyClass, :name(/b/) }).lines, "&my-method-b", "Filter by name works";

ok (ls MyModule::MyClass, :take(1..2)) eqv
   (MyModule::MyClass.^lookup('my-method-a'),
    MyModule::MyClass.^lookup('my-method-b')),
   "taking the objects via a range works";

ok (do .key for ls MyModule::MyClass, :name(/my\-method/), :gather) eqv
   ('my-method-a', 'my-method-b'),
   "gather the pairs works";

is (output-from { ls MyModule }).lines.sort.join("\n"),
   ('$myvar', '&mysub', 'MyClass').sort.join("\n"),
   "testing ls module";

is (output-from { ll MyModule }).lines.sort.join("\n"),
   ('Int $myvar', 'only sub mysub(Int $i --> Int)', 'MyClass').sort.join("\n"),
   "testing ll module";

is (output-from { ls MyModule::MyClass, :long }).lines.join("\n"),
   ('Int $classvar',
    'only method my-method-a' ~ MyModule::MyClass.^lookup("my-method-a").signature.gist,
    'only method my-method-b' ~ MyModule::MyClass.^lookup("my-method-b").signature.gist,
    'proto method my-multi' ~ MyModule::MyClass.^lookup("my-multi").signature.gist,
    | do ("multi method {.name}" ~ .signature.gist for MyModule::MyClass.^lookup("my-multi").candidates)
   ).join("\n"),
   "testing ll class";


is (output-from { ll &substr }).lines.join("\n") ~ "\n", q:to/END/, "testing ll a sub";
    proto sub substr($, $?, $?, *%)
    multi sub substr(\what)
    multi sub substr(\what, \from)
    multi sub substr(\what, \from, \chars)
    END

lives-ok { ll CORE };
lives-ok { ls CORE, :value(Class-ish) };

done-testing;
