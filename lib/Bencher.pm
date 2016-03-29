package Bencher;

# DATE
# VERSION

1;
#ABSTRACT: A benchmark framework

=head1 SYNOPSIS

See L<bencher> CLI.


=head1 DESCRIPTION

Bencher is a benchmark framework. It helps you:

=over

=item * specify what Perl code (functions/module names or coderefs) or external commands you want to benchmark

along with a set of data (function or command-line arguments).

=item * run the items

You can run all the items, only some of them, with some/all combinations of
arguments, with different module paths/versions, different perl paths, and so
on.

=item * save the result

=item * display the result(s) and graph them

=item * send the result to a server

=back


=head1 SCENARIO

The core data structure that you need to prepare is the B<scenario>. It is a
L<DefHash> (i.e. just a regular Perl hash), the two most important keys of this
hash are: B<participants> and B<datasets>.

An example scenario (from C<Bench::Scenario::Example>):

 package Bencher::Scenario::Example;
 our $scenario = {
     participants => [
         {fcall_template => q[Text::Wrap::wrap('', '', <text>)]},
     ],
     datasets => [
         { name=>"foobar x100",   args => {text=>"foobar " x 100} },
         { name=>"foobar x1000",  args => {text=>"foobar " x 1000} },
         { name=>"foobar x10000", args => {text=>"foobar " x 10000} },
     ],
 };
 1;

=head2 participants

B<participants> (array) lists Perl code (or external command) that we want to
benchmark.

=head3 Specifying participant's code

There are several kinds of code you can specify:

First, you can just specify C<module> (str, a Perl module name). This is useful
when running scenario in L<module_startup mode/"Running benchmark in module
startup mode">. Also useful to instruct Bencher to load the module. When not in
module startup mode, there is no code in this participant to run.

You can also specify C<modules> (an array of Perl module names) if you want to
benchmark several modules together. Similarly, this is only useful for running
in module startup mode.

You can specify C<code> (a coderef) which contains the code to benchmark.
However, the point of Bencher is to use C<fcall_template> or at least
C<code_template> to be able to easily permute the code with datasets (see
below). So you should only specify C<code> when you cannot specify
C<fcall_template> or C<code_template> or the other way.

You can specify C<fall_template>, and this is the recommended way whenever
possible. It is a string containing a function call code, in the form of:

 MODULENAME::FUNCTIONAME(ARG, ...)

or

 CLASSNAME->FUNCTIONAME(ARG, ...)

For example:

 Text::Levenshtein::fastdistance(<word1>, <word2>)

Another example:

 Module::CoreList->is_code(<module>)

It can be used to benchmark a function call or a method call. From this format,
Bencher can easily extract the module name so user can also run in module
startup mode.

By using a template, Bencher can generate actual codes from this template by
combining it with datasets. The words enclosed in C<< <...> >> will be replaced
with actual arguments specified in L</"datasets">.

Aside from C<fcall_template>, you can also use C<code_template> (a string
containing arbitrary code), in the cases where the code you want to benchmark
cannot be expressed as a simple function/method call, for example (taken from
L<Bencher::Scenario::ComparisonOps>):

 participants => [
     {name=>'1k-numeq'      , code_template=>'my $val =     1; for (1..1000) { if ($val ==     1) {} if ($val ==     2) {} }'},
     {name=>'1k-streq-len1' , code_template=>'my $val = "a"  ; for (1..1000) { if ($val eq "a"  ) {} if ($val eq "b"  ) {} }'},
     {name=>'1k-streq-len3' , code_template=>'my $val = "foo"; for (1..1000) { if ($val eq "foo") {} if ($val eq "bar") {} }'},
     {name=>'1k-streq-len10', code_template=>'my $val = "abcdefghij"; for (1..1000) { if ($val eq "abcdefghij") {} if ($val eq "klmnopqrst") {} }'},
 ],

Like in C<fcall_template>, words enclosed in C<< <...> >> will be replaced with
actual data. When generating actual code, Bencher will enclose the code template
with C<sub { .. }>.

Or, if you are benchmarking external commands, you specify C<cmdline> (array or
strings, or strings) or C<cmdline_template> (array/str) or C<perl_cmdline> or
C<perl_cmdline_template> instead. An array cmdline will not use shell, while the
string version will use shell. C<perl_cmdline*> are the same as C<cmdline*>
except the first implicit argument/prefix is perl.

=head3 Specifying participant's name

By default, Bencher will attempt to figure out the name for a participant (a
sequence number starting from 1, a module name or module name followed by
function name, etc). You can also specify name for a participant explicitly so
you can refer to it more easily later, e.g.:

 participants => [
     {name=>'pp', fcall_template=>'List::MoreUtils::PP::uniq(@{<array>})'},
     {name=>'xs', fcall_template=>'List::MoreUtils::XS::uniq(@{<array>})'},
 ],

=head3 List of properties for a participant

This is a reference section.

=over

=item * name (str)

From DefHash.

=item * summary (str)

From DefHash.

=item * description (str)

From DefHash.

=item * tags (array of str)

From DefHash. Define tag(s) for this participant. Can be used to include/exclude
groups of participants having the same tags.

=item * module (str)

=item * modules (array of str)

=item * function (str)

=item * fcall_template (str)

=item * code_template (str)

=item * code (code)

=item * cmdline (str|array of str)

=item * cmdline_template (str|array of str)

=item * perl_cmdline (str|array of str)

=item * perl_cmdline_template (str|array of str)

=item * result_is_list (bool, default 0)

This is useful when dumping item's codes, so Bencher will use a list context
when receiving result.

=item * include_by_default> (bool, default 1)

Can be set to false if you want to exclude participant by default when running
benchmark, unless the participant is explicitly included e.g. using
C<--include-participant> command-line option.

=back

=head2 datasets

B<datasets> (array) lists the function inputs (or command-line arguments). You
can C<name> each dataset too, to be able to refer to it more easily.

Other properties you can add to a dataset: C<include_by_default> (bool, default
true, can be set to false if you want to exclude dataset by default when running
benchmark, unless the dataset is explicitly included).

=over

=item * name (str)

From DefHash.

=item * summary (str)

From DefHash.

=item * description (str)

From DefHash.

=item * tags (array of str)

From DefHash. Define tag(s) for this dataset. Can be used to include/exclude
groups of datasets having the same tags.

=item * args (hash)

Example:

 {filename=>"ujang.txt", size=>10}

You can supply multiple argument values by adding C<@> suffix to the argument
name. You then supply an array for the values, example:

 {filename=>"ujang.txt", 'size@'=>[10, 100, 1000]}

This means, for each participant mentioning C<size>, three benchmark items will
be generated, one for each value of C<size>.

Aside from array, you can also use hash for the multiple values. This has a nice
effect of showing nicer names (in the hash keys) for the argument value, e.g.:

 {filename=>"ujang.txt", 'size@'=>{"1M"=>1024*2, "1G"=>1024**3, "1T"=>1024**4}}

=item * argv (array)

=item * include_by_default (bool, default 1)

=item * include_participant_tags (array of str)

Only include participants having all these tags.

=item * exclude_participant_tags (array of str)

Exclude participants having any of these tags.

=back

=head3 Other properties

Other known scenario properties (keys):

=over

=item * name

From DefHash, scenario name (usually short and one word).

=item * summary

From DefHash, a one-line plaintext summary.

=item * description (str)

From DefHash, longer description in Markdown.

=item * module_startup (bool)

=item * default_precision (float, between=>[0,1])

Precision to pass to Benchmark::Dumb. Default is 0. Can be overriden via
C<--precision> (CLI).

=item * include_result_size (bool)

=item * on_failure (str, "skip"|"die")

For a command participant, failure means non-zero exit code. For a Perl-code
participant, failure means Perl code dies or (if expected result is specified)
the result is not equal to the expected result.

The default is "die". When set to "skip", will first run the code of each item
before benchmarking and trap command failure/Perl exception and if that happens,
will "skip" the item.

Can be overriden in the CLI with C<--on-failure> option.

=item * on_result_failure (str, "skip"|"die"|"warn")

This is like C<on_failure> except that it specifically refer to the failure of
item's result not being equal to expected result.

The default is the value of C<on_failure>.

There is an extra choice of `warn` for this type of failure, which is to print a
warning to STDERR and continue.

Can be overriden in the CLI with C<--on-result-failure> option.

=item * before_parse_scenario (code)

If specified, then this code will be called before parsing scenario. Code will
be given hash argument with the following keys: C<hook_name> (str, set to
C<before_gen_items>), C<scenario> (hash, unparsed scenario), C<stash> (hash,
which you can use to pass data between hooks).

=item * after_parse_scenario (code)

If specified, then this code will be called after parsing scenario. Code will be
given hash argument with the following keys: C<hook_name>, C<scenario> (hash,
parsed scenario), C<stash>.

=item * before_list_datasets (code)

If specified, then this code will be called before enumerating datasets from
scenario. Code will be given hash argument with the following keys:
C<hook_name>, C<scenario>, C<stash>.

You can use this hook to, e.g.: generate datasets dynamically.

=item * before_list_participants (code)

If specified, then this code will be called before enumerating participants from
scenario. Code will be given hash argument with the following keys:
C<hook_name>, C<scenario>, C<stash>.

You can use this hook to, e.g.: generate participants dynamically.

=item * before_gen_items (code)

If specified, then this code will be called before generating items. Code will
be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>.

You can use this hook to, e.g.: modify datasets/participants before being
permuted into items.

=item * before_bench (code)

If specified, then this code will be called before starting the benchmark. Code
will be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>.

=item * after_bench (code)

If specified, then this code will be called after completing benchmark. Code
will be given hash argument with the following keys: C<hook_name>, C<scenario>,
C<stash>, C<result> (array, enveloped result).

You can use this hook to, e.g.: do some custom formatting/modification to the
result.

=item * before_return (code)

If specified, then this code will be called before displaying/returning the
result. Code will be given hash argument with the following keys: C<hook_name>,
C<scenario>, C<stash>, C<result>.

You can use this hook to, e.g.: modify the result in some way.

=back


=head1 USING THE BENCHER COMMAND-LINE TOOL

=head2 Running benchmark

=head2 Running benchmark in module startup mode

Module startup mode can be activated either by specifying C<--module-startup>
option from the command-line, or by setting C<module_startup> property to true
in the scenario.

In this mode, instead of running each participant's code, module name will be
extracted from each participant and this will be benchmarked instead:

 perl -MModule1 -e1
 perl -MModule2 -e1
 ...
 perl -e1 ;# the baseline, for comparison

Basically, this mode tries to measure the startup overhead of each module in
isolation.

Module name can be extracted from a participant if a participant specifies
C<module> or C<fcall_template> or C<modules>. When a participant does not
contain any module name, it will be skipped.


=head1 SEE ALSO

L<bencher>

B<BenchmarkAnything>. There are lot of overlaps of goals between Bencher and
this project. I hope to reuse or interoperate parts of BenchmarkAnything, e.g.
storing Bencher results in a BenchmarkAnything storage backend, sending Bencher
results to a BenchmarkAnything HTTP server, and so on.

L<Benchmark>, L<Benchmark::Dumb> (L<Dumbbench>)

C<Bencher::Scenario::*> for examples of scenarios.
