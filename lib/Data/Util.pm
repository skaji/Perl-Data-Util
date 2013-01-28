package Data::Util;

use 5.008_001;
use strict;
#use warnings;

our $VERSION = '0.60';

use Exporter;
our @ISA = qw(Exporter);

our $TESTING_PERL_ONLY;
$TESTING_PERL_ONLY = $ENV{DATA_UTIL_PUREPERL} ? 1 : 0
	unless defined $TESTING_PERL_ONLY;

unless($TESTING_PERL_ONLY){
	local $@;

	$TESTING_PERL_ONLY = !eval{
		require XSLoader;
		XSLoader::load(__PACKAGE__, $VERSION);
	};

#	if($@ && $ENV{DATA_UTIL_DEBUG}){
#		warn $@;
#	}
}
require 'Data/Util/PurePerl.pm' # not to create the namespace
	if $TESTING_PERL_ONLY;

our @EXPORT_OK = qw(
	is_scalar_ref is_array_ref is_hash_ref is_code_ref is_glob_ref is_rx is_regex_ref
	is_instance is_invocant
	is_value is_string is_number is_integer

	scalar_ref array_ref hash_ref code_ref glob_ref rx regex_ref
	instance invocant

	anon_scalar neat

	get_stash

	install_subroutine
	uninstall_subroutine
	get_code_info
	get_code_ref

	curry
	modify_subroutine
	subroutine_modifier

	mkopt
	mkopt_hash
);

our %EXPORT_TAGS = (
	all => \@EXPORT_OK,

	check   => [qw(
		is_scalar_ref is_array_ref is_hash_ref is_code_ref
		is_glob_ref is_rx is_instance is_invocant
		is_value is_string is_number is_integer

		is_regex_ref
	)],
	validate  => [qw(
		scalar_ref array_ref hash_ref code_ref
		glob_ref rx instance invocant
		regex_ref
	)],
);

1;
__END__

=head1 NAME

Data::Util - A selection of utilities for data and data types

=head1 VERSION

This document describes Data::Util version 0.60

=head1 SYNOPSIS

	use Data::Util qw(:validate);

	sub foo{
		# they will die if invalid values are supplied
		my $sref = scalar_ref(shift);
		my $aref = array_ref(shift);
		my $href = hash_ref(shift);
		my $cref = code_ref(shift);
		my $gref = glob_ref(shift);
		my $rx   = rx(shift); # regular expression
		my $obj  = instance(shift, 'Foo');
		# ...
	}

	use Data::Util qw(:check);

	sub bar{
		my $x = shift;
		if(is_scalar_ref $x){
			# $x is an array reference
		}
		# ...
		elsif(is_instance $x, 'Foo'){
			# $x is an instance of Foo
		}
		# ...
	}

	# miscelaneous
	use Data::Util qw(:all);

	my $x = anon_scalar();
	$x = anon_scalar($x); # OK

	my $stash = get_stash('Foo');

	install_subroutine('Foo',
		hello  => sub{ "Hello!\n" },
		goodby => sub{ "Goodby!\n" },
	);

	print Foo::hello(); # Hello!

	my($pkg, $name) = get_code_info(\&Foo::hello); # => ('Foo', 'hello')
	my $fqn         = get_code_info(\&Foo::hello); # =>  'Foo::hello'
	my $code        = get_code_ref('Foo', 'hello');  # => \&Foo::hello

	uninstall_subroutine('Foo', qw(hello goodby));

    # simple format for errro messages (not the same as Data::Dumper)
	print neat("Hello!\n"); # => "Hello!\n"
	print neat(3.14);       # => 3.14
	print neat(undef);      # => undef

=head1 DESCRIPTION

This module provides utility functions for data and data types,
including functions for subroutines and symbol table hashes (stashes).

The implementation of this module is both Pure Perl and XS, so if you have a C
compiler, all the functions this module provides are really faster.

There are many benchmarks in the F<DIST-DIR/benchmark/> directory.

=head1 INTERFACE

=head2 Check functions

Check functions are introduced by the C<:check> import tag, which check
the argument type and return a bool.

These functions also checks overloading magic, e.g. C<${}> for a SCALAR reference.

=over 4

=item is_scalar_ref(value)

For a SCALAR reference.

=item is_array_ref(value)

For an ARRAY reference.

=item is_hash_ref(value)

For a HASH reference.

=item is_code_ref(value)

For a CODE reference.

=item is_glob_ref(value)

For a GLOB reference.

=item is_rx(value)

For a regular expression reference generated by the C<qr//> operator.

=item is_instance(value, class)

For an instance of I<class>.

It is equivalent to something like
C<< Scalar::Util::blessed($value) && $value->isa($class) >>.

=item is_invocant(value)

For an invocant, i.e. a blessed reference or existent package name.

If I<value> is a valid class name but does not exist, it will return false.

=item is_value(value)

Checks whether I<value> is a primitive value, i.e. a defined, non-ref, and
non-type-glob value.

This function has no counterpart for validation.

=item is_string(value)

Checks whether I<value> is a string with non-zero-length contents,
equivalent to C<< is_value($value) && length($value) > 0 >>.

This function has no counterpart for validation.

=item is_number(value)

Checks whether I<value> is a number.
Here, a B<number> means that the perl parser can understand it and that
the perl numeric converter (e.g. invoked by C<< sprintf '%g', $value >>)
doesn't complain about it.

It is similar to C<Scalar::Util::looks_like_number()>
but refuses C<infinity>, C<not a number> and C<"0 but true">.
Note that C<9**9**9> makes C<infinity> and C<9**9**9 - 9**9**9> makes
C<not a number>.

This function has no counterpart for validation.

=item is_integer(value)

Checks whether I<value> is an integer.
An B<integer> is also a B<number>, so this function
refuses C<infinity> and C<not a number>. See also C<is_number()>.

This function has no counterpart for validation.

=back

=head2 Validating functions

Validating functions are introduced by the C<:validate> tag which check the
argument and returns the first argument.
These are like the C<:check> functions but dies if the argument type
is invalid.

These functions also checks overloading magic, e.g. C<${}> for a SCALAR reference.

=over 4

=item scalar_ref(value)

For a SCALAR reference.

=item array_ref(value)

For an ARRAY reference.

=item hash_ref(value)

For a HASH reference.

=item code_ref(value)

For a CODE reference.

=item glob_ref(value)

For a GLOB reference.

=item rx(value)

For a regular expression reference.

=item instance(value, class)

For an instance of I<class>.

=item invocant(value)

For an invocant, i.e. a blessed reference or existent package name.

If I<value> is a valid class name and the class exists, then it returns
the canonical class name, which is logically cleaned up. That is, it does
C<< $value =~ s/^::(?:main::)*//; >> before returns it.

NOTE:
The canonization is because some versions of perl has an inconsistency
on package names:

	package ::Foo; # OK
	my $x = bless {}, '::Foo'; # OK
	ref($x)->isa('Foo'); # Fatal

The last sentence causes a fatal error:
C<Can't call method "isa" without package or object reference>.
However, C<< invocant(ref $x)->isa('Foo') >> is always OK.

=back

=head2 Miscellaneous utilities

There are some other utility functions you can import from this module.

=over 4

=item anon_scalar()

Generates an anonymous scalar reference to C<undef>.

=item anon_scalar(value)

Generates an anonymous scalar reference to the copy of I<value>.

It is equivalent to C<< do{ my $tmp = $value; \$tmp; } >>.

=item neat(value)

Returns a neat string that is suitable to display.

This is a smart version of C<<do{ defined($value) ? qq{"$value"} : 'undef' }>>.

=item get_stash(invocant)

Returns the symbol table hash (also known as B<stash>) of I<invocant>
if the stash exists.

=item install_subroutine(package, name => subr [, ...])

Installs I<subr> into I<package> as I<name>.

It is similar to
C<< do{ no strict 'refs'; *{$package.'::'.$name} = \&subr; } >>.
In addition, if I<subr> is an anonymous subroutine, it is located into
I<package> as a named subroutine I<&package::name>.

For example:

	install_subroutine($pkg,   say => sub{ print @_, "\n" });
	install_subroutine($pkg,
		one => \&_one,
		two => \&_two,
	);

	# accepts a HASH reference
	install_subroutine($pkg, { say => sub{ print @_, "\n" }); #

To re-install I<subr>, use C<< no warnings 'redefine' >> directive:

	no warnings 'redefine';
	install_subroutine($package, $name => $subr);

=item uninstall_subroutine(package, names...)

Uninstalls I<names> from I<package>.

It is similar to C<Sub::Delete::delete_sub()>, but uninstall multiple
subroutines at a time.

If you want to specify deleted subroutines, you can supply
C<< name => \&subr >> pairs.

For example:

	uninstall_subroutine('Foo', 'hello');

	uninstall_subroutine('Foo', hello => \&Bar::hello);

	uninstall_subroutine($pkg,
		one => \&_one,
		two => \&_two,
	);

	# accepts a HASH reference
	uninstall_subroutine(\$pkg, { hello => \&Bar::hello });

=item get_code_info(subr)

Returns a pair of elements, the package name and the subroutine name of I<subr>.

It is similar to C<Sub::Identify::get_code_info()>, but it returns the fully
qualified name in scalar context.

=item get_code_ref(package, name, flag?)

Returns I<&package::name> if it exists, not touching the symbol in the stash.

if I<flag> is a string C<-create>, it returns I<&package::name> regardless of
its existence. That is, it is equivalent to
C<< do{ no strict 'refs'; \&{package . '::' . $name} } >>.

For example:

	$code = get_code_ref($pkg, $name);          # like  *{$pkg.'::'.$name}{CODE}
	$code = get_code_ref($pkg, $name, -create); # like \&{$pkg.'::'.$name}

=item curry(subr, args and/or placeholders)

Makes I<subr> curried and returns the curried subroutine.

This is also considered as lightweight closures.

See also L<Data::Util::Curry>.

=item modify_subroutine(subr, ...)

Modifies I<subr> with subroutine modifiers and returns the modified subroutine.
This is also considered as lightweight closures.

I<subr> must be a code reference or callable object.

Optional arguments:
C<< before => [subroutine(s)] >> called before I<subr>.
C<< around => [subroutine(s)] >> called around I<subr>.
C<< after  => [subroutine(s)] >> called after  I<subr>.

This seems a constructor of modified subroutines and
C<subroutine_modifier()> is property accessors, but it does not bless the
modified subroutines.

=item subroutine_modifier(subr)

Returns whether I<subr> is a modified subroutine.

=item subroutine_modifier(modified_subr, property)

Gets I<property> from I<modified>.

Valid properties are: C<before>, C<around>, C<after>.

=item subroutine_modifier(modified_subr, modifier => [subroutine(s)])

Adds subroutine I<modifier> to I<modified_subr>.

Valid modifiers are: C<before>, C<around>, C<after>.

=item mkopt(input, moniker, require_unique, must_be)

Produces an array of an array reference from I<input>.

It is compatible with C<Data::OptList::mkopt()>. In addition to it,
I<must_be> can be a HASH reference with C<< name => type >> pairs.

For example:

	my $optlist = mkopt(['foo', bar => [42]], $moniker, $uniq, { bar => 'ARRAY' });
	# $optlist == [[foo => undef], [bar => [42]]

=item mkopt_hash(input, moniker, must_be)

Produces a hash reference from I<input>.

It is compatible with C<Data::OptList::mkopt_hash()>. In addition to it,
I<must_be> can be a HASH reference with C<< name => type >> pairs.

For example:

	my $optlist = mkopt(['foo', bar => [42]], $moniker, { bar => 'ARRAY' });
	# $optlist == {foo => undef, bar => [42]}

=back

=head1 ENVIRONMENT VARIABLES

=head2 DATA_UTIL_PUREPERL

If true, C<Data::Util> uses the Pure Perl implementation.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

If you have a C compiler, you can use the XS backend,
but the Pure Perl backend is also available if you have no C compilers.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Scalar::Util>.

L<overload>.

L<Params::Util>.

L<Sub::Install>.

L<Sub::Identify>.

L<Sub::Delete>.

L<Sub::Curry>.

L<Class::MOP>.

L<Class::Method::Modifiers>.

L<Data::OptList>.

L<Mouse>

=head1 AUTHOR

Goro Fuji(gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2010, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
